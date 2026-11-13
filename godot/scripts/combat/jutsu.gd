extends Node
## Jutsu motoru (autoload "Jutsu"): her tekniğin oynanışı + görsel efekti. Oyuncu ve düşmanlar aynı kodu kullanır.
## caster: Player veya Enemy (team, global_position, face_dir(), model, height, radius)


func _mult(caster: Node3D) -> float:
	if caster is Player:
		# az önce yapılan tekniğin dalı (ör. genjutsu ise genjutsu ustalığı) gücü belirler
		var br = "ninjutsu"
		if caster.has_meta("jid") and Time.get_ticks_msec() / 1000.0 - float(caster.get_meta("jid_t", 0.0)) < 12.0:
			br = Mastery.branch_of(Data.jutsu.get(String(caster.get_meta("jid")), {}))
		return Stats.jutsu_mult(Game.profile, br)
	var pw = float(caster.get("power")) if caster.get("power") != null else 1.0
	return pw * (caster.buff_mod("jutsu") if caster.has_method("buff_mod") else 1.0)   # AI'nın kendi buff'ları


func _elem_bonus(caster: Node3D, el: String) -> float:
	if caster is Player:
		var els: Array = Game.profile.get("elements", [])
		# element buff'ları (ör. Sanmai no Shinka "katon": 1.3) hasara gerçekten yansır
		var wboost = Gear.elem_boost(caster, el)   # silah + kıyafet seti element güçlendirmesi
		return ((1.2 if not els.is_empty() and els[0] == el else 1.0) + Stats.element_bonus(Game.profile, el) + (Stats.skill(Game.profile, "kg") if el in Stats.KG_NATURES else 0.0)) * Buffs.mod(el) * (1.0 + wboost)
	return (1.0 + Gear.elem_boost(caster, el)) * (caster.buff_mod(el) if caster.has_method("buff_mod") else 1.0)   # AI: silah + set + kendi element buff'ı


func _aim(caster: Node3D, target: Node3D) -> Vector3:
	var s = caster.global_position + Vector3.UP * 1.4
	# oyuncu: kilitli hedef yoksa nişangâha (baktığı yere) serbest nişan
	if caster is Player:
		var lt = caster.combat.lock_target if caster.combat else null
		if lt != null and is_instance_valid(lt) and target == lt:
			return (lt.global_position + Vector3.UP * lt.height * 0.5 - s).normalized()
		# nişangâh düşmanın üstündeyse (HUD'da kırmızı) göğsüne kilitlenir; değilse tam nişangâhın gösterdiği noktaya
		var soft = soft_target(caster)
		if soft:
			return (soft.global_position + Vector3.UP * soft.height * 0.55 - s).normalized()
		return (caster.aim_point() - s).normalized()
	if target and is_instance_valid(target):
		return (target.global_position + Vector3.UP * target.height * 0.5 - s).normalized()
	return caster.face_dir()


## Nişangâhın (ekran ortası) üstündeki düşman: kamera ışınına ~6° içinde, 45 m'ye kadar. HUD nişangâhı bununla kırmızı olur
func soft_target(caster: Node3D) -> Node3D:
	if not (caster is Player) or caster.cam == null:
		return null
	var ar: Array = caster.aim_ray()
	var from: Vector3 = ar[0]
	var dir: Vector3 = ar[1]
	# nişan yardımı: nişangâhın ~25° çevresindeki düşman (eskiden ~8°: biraz kayık nişanda jutsu boş noktaya gidiyordu,
	# "adam menzilde ama tutmuyor"); o da yoksa karakterin önündeki 60° koni içinde 25 m'ye kadar en yakın düşman
	var best: Node3D = null
	var bd := 0.906
	var near: Node3D = null
	var nd := 25.0
	var fd: Vector3 = caster.face_dir()
	for f in caster.get_tree().get_nodes_in_group("fighters"):
		if f == caster or not Combat.hostile(caster, f) or f.is_dead():
			continue
		var c: Vector3 = f.global_position + Vector3.UP * f.height * 0.55
		var v = c - from
		var L = v.length()
		if L > 45.0 + 8.0 or L < 1.0:
			continue
		var dt = v.normalized().dot(dir)
		if dt > bd:
			bd = dt
			best = f
		var hv: Vector3 = f.global_position - caster.global_position
		hv.y = 0.0
		var hd = hv.length()
		if hd < nd and hd > 0.3 and hv.normalized().dot(fd) > 0.5:
			nd = hd
			near = f
	return best if best != null else near


## Yatay nişan yönü (duvar, yer jutsuları, atılmalar)
func _aim_flat(caster: Node3D, target: Node3D) -> Vector3:
	var d = _aim(caster, target)
	d.y = 0.0
	return d.normalized() if d.length() > 0.01 else caster.face_dir()


## Yere hedefli jutsular için nokta: oyuncu kilitsizse nişangâh noktası (menzil sınırlı), değilse hedef
func _aim_ground(caster: Node3D, target: Node3D, dist: float, max_d := 30.0) -> Vector3:
	if caster is Player:
		var lt = caster.combat.lock_target if caster.combat else null
		if not (lt != null and is_instance_valid(lt) and target == lt):
			var p: Vector3 = caster.aim_point()
			var off = p - caster.global_position
			off.y = 0.0
			if off.length() > max_d:
				p = caster.global_position + off.normalized() * max_d
			return p
	if target and is_instance_valid(target):
		return target.global_position
	return caster.global_position + caster.face_dir() * dist


func _hand(caster: Node3D) -> Vector3:
	return caster.global_position + Vector3.UP * 1.35 + caster.face_dir() * 0.55


## Ağız: kafa kemiğinin dünya konumu + ileri (Katon gibi üfleme jutsuları buradan çıkar)
func _mouth(caster: Node3D) -> Vector3:
	var m = caster.get("model")
	if m and is_instance_valid(m) and m.skel:
		var hb = m.skel.find_bone("Head")
		if hb >= 0:
			var hp: Vector3 = (m.skel.global_transform * m.skel.get_bone_global_pose(hb)).origin
			return hp + Vector3.UP * 0.04 + caster.face_dir() * 0.28
	return caster.global_position + Vector3.UP * 1.6 * (m.age_scale if m else 1.0) + caster.face_dir() * 0.35


## Jutsunun çıkış noktası: CastAnim stili "breath" ise ağız, değilse el
func _cast_origin(caster: Node3D, jid: String) -> Vector3:
	if CastAnim.style_for(jid, Data.jutsu.get(jid, {})) == "breath":
		return _mouth(caster)
	return _hand(caster)


## Her jutsu kullanımında yayılır (ör. Sharingan kopyalama)
signal jutsu_cast(caster: Node, id: String)


func execute(caster: Node3D, id: String, target: Node3D) -> void:
	jutsu_cast.emit(caster, id)
	caster.set_meta("jid", id)   # hasar dengesi: bu jutsunun isabetleri ölçülmüş çarpanla
	if String(Data.jutsu.get(id, {}).get("element", "")) == "katon":
		caster.set_meta("katon_t", Game.now())   # Kirin: Katon ile ısınan gök fırtına bulutu toplar
	caster.set_meta("jid_t", Time.get_ticks_msec() / 1000.0)
	# Kurama kekkei genkai (kanon, Yakumo): genjutsusu bedeni gerçekten yaralar — yakalanan (sersem/korku/bağ/uyku) düşman gerçek hasar alır.
	# Oyuncu ve düşman Kurama aynı kural.
	var kurama = (caster == Game.player and String(Game.profile.get("clan", "")) == "kurama") or (caster.get("arch") is Dictionary and String(caster.arch.get("clan", "")) == "kurama")
	if kurama and String(Data.jutsu.get(id, {}).get("category", "")) == "genjutsu":
		get_tree().create_timer(0.7).timeout.connect(func():
			if not is_instance_valid(caster):
				return
			for f in get_tree().get_nodes_in_group("fighters"):
				if Combat.hostile(caster, f) and not f.is_dead() and f.global_position.distance_to(caster.global_position) < 24.0 and f.has_method("has_status") and (f.has_status("stun") or f.has_status("fear") or f.has_status("bind") or f.has_status("sleep")):
					f.take_hit({"dmg": 22.0 * _mult(caster), "knock": 0.0, "launch": 0.0, "kind": "light", "pierce_guard": true, "attacker": caster})
					Combat.popup_text(f.global_position + Vector3.UP * 2.4, "Genjutsu gerçeğe döndü", Color(0.85, 0.4, 0.7)))
	# taijutsu: mühür yok, ninjutsu atma sesi de yok
	if not String(Data.jutsu.get(id, {}).get("virtual", "")).begins_with("eye:") and String(Data.jutsu.get(id, {}).get("category", "")) != "taijutsu":
		if caster == Game.player:
			Sfx.play("jutsu_cast", null, 1.0, 0.8)
		else:
			Sfx.play("jutsu_cast", caster.global_position, 1.0, 0.45)
	Sfx.play_jutsu_theme(id, caster.global_position)   # klan / doğa / jutsu temasına özel ses (Aburame böcek, Sabaku kum, Kaguya kemik...)
	var own_id = id   # klan/kekkei genkai jutsularının kendi uygulaması (ClanJutsu) önceliklidir
	id = String(Data.jutsu.get(id, {}).get("impl", id))  # klan jutsuları ortak uygulamayı kullanabilir
	var jd: Dictionary = Data.jutsu.get(id, {})
	if not has_method("j_" + id) and jd.is_empty() and not ClanJutsu.handles(own_id) and not PathJutsu.handles_path(own_id) and not MsArts.handles(own_id):
		Hud.msg("%s henüz uygulanmadı" % id, Color(1, 0.6, 0.4))
		return
	# destan ölçeği: rütbe × ustalık; bırakış anı (flaş, şok halkası, toz, B+ yavaş çekim + kamera)
	var g = JutsuEngine.grand(caster, jd.merged({"id": id}))
	var tier = int(jd.get("tier", 2))
	var shp = String(jd.get("shape", ""))
	if tier < 3 and JutsuEngine.SIGNATURE_SCALE.has(id):
		tier = 3   # imza element jutsuları B gibi sahnelenir
	var calm = shp in ["transform", "stealth", "sensor", "utility", "heal", "revive", "teleport", "clone", "counter"] or String(jd.get("category", "")) == "medical" or String(jd.get("learn", "")) == "path:kagit"   # kâğıt sanatı da sessiz; tıbbi teknikler sessiz: ayakta toz/şok yok
	VFX.release(caster, _cast_origin(caster, id), JutsuEngine.color_of(jd), g, tier if not calm else mini(tier, 2), not calm)
	var prev = VFX.epic
	# rütbeye/seviyeye göre büyütme kaldırıldı (kullanıcı: bazı jutsular anlamsız büyüyordu) — her jutsu kendi anime boyutunda;
	# animede zaten dev olan imza teknikleri (Gōkakyū, Daitoppa, Suikōdan...) kendi ölçeğini korur
	VFX.epic = float(JutsuEngine.SIGNATURE_SCALE.get(id, 1.0))
	var prev_caster = Buffs.caster
	Buffs.caster = caster   # buff'lar atana gitsin (düşmanın buff'ı oyuncuya değil düşmana)
	if MsArts.handles(own_id):   # Mangekyō tarzlarının kendi teknikleri
		MsArts.cast(caster, own_id, target)
	elif PathJutsu.handles_path(own_id):   # Efsane Yolları teknikleri
		PathJutsu.cast_path(caster, own_id, target)
	elif ClanJutsu.handles(own_id):
		ClanJutsu.cast(caster, own_id, target)
	elif has_method("j_" + id):
		call("j_" + id, caster, target)
	else:
		JutsuEngine.cast(caster, id, target)  # veri güdümlü: şekil × element × kademe
	Buffs.caster = prev_caster
	VFX.epic = prev


# ================================================================== KATON
func j_katon_goukakyuu(c: Node3D, t: Node3D) -> void:
	var m = _mult(c) * _elem_bonus(c, "katon")
	var dir = _aim(c, t)
	var start = _mouth(c) + dir * 0.9
	var g = VFX.epic
	var fcols = [Color(1, 0.82, 0.22, 1), Color(1, 0.55, 0.08, 1), Color(0.95, 0.3, 0.04, 0.9), Color(0.7, 0.1, 0.03, 0)]
	# ısı dalgası halkası + ağızdan püsküren alev
	VFX.embers(start, Color(1, 0.55, 0.1), 18, 12.0)
	Sfx.play("fire", start, 0.8, 1.4)
	var pr = Projectile.new()
	pr.shooter = c
	pr.vel = dir * 5.0
	pr.radius = 1.7
	pr.life = 3.6
	pr.info = {"dmg": 26.0 * m, "element": "katon", "knock": 14.0, "launch": 6.0, "kind": "heavy", "hitstop": 0.09, "burn": 3.0}
	# 1) nefesle ağzın önünde şişen dev ateş topu (8–12 m), 2) yuvarlanarak ilerler, altında yanık izi bırakır
	var ball = VFX.fireball(3.3)   # anime boyu (~6 m çap); 5.0 fazla büyüktü
	ball.scale = Vector3.ONE * 0.12
	pr.add_child(ball)
	var gt = ball.create_tween()
	gt.tween_property(ball, "scale", Vector3.ONE, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var rt = ball.create_tween().set_loops()
	rt.tween_property(ball, "rotation:x", -TAU, 1.1).from(0.0)
	var light = OmniLight3D.new()
	light.light_color = Color(1, 0.6, 0.2); light.light_energy = 3.0; light.omni_range = 18.0 * g
	pr.add_child(light)
	# sürekli nefes akışı (~1 sn): ağızdan topa doğru büyüyen alev dili
	_ticks(9, 0.1, func(k):
		if not is_instance_valid(c) or not is_instance_valid(pr):
			return
		var mo = _mouth(c) + dir * 0.6
		var to_ball = (pr.global_position - mo)
		VFX.puffs(mo, {"amount": 10, "life": 0.35, "size": 0.9 + k * 0.12, "vmin": 6, "vmax": maxf(8.0, to_ball.length() * 2.2), "dir": to_ball.normalized(),
			"spread": 14.0, "damp": 2.0, "glow": 1.1, "hot": 0.3, "stretch": 1.4, "outline_col": Color(0.3, 0.04, 0.02), "colors": fcols}))
	var st = {"age": 0.0, "scar": 0.0}
	pr.on_tick = func(p: Projectile, dt: float) -> void:
		st["age"] += dt
		if st["age"] < 0.75:
			p.vel = dir * 5.0
		else:
			p.vel = p.vel.move_toward(dir * 24.0, dt * 40.0)
		# top yerin üstünde yuvarlansın (merkez görsel yarıçapın yarısı kadar yukarıda)
		var gy = Game.jutsu_floor(p.global_position.x, p.global_position.z)
		p.global_position.y = lerpf(p.global_position.y, gy + 1.6 * g, minf(1.0, dt * 3.0))
		st["scar"] -= dt
		if st["scar"] <= 0.0 and st["age"] > 0.3:
			st["scar"] = 0.12
			VFX.cracks(Vector3(p.global_position.x, gy, p.global_position.z), 2.6, Color(0.1, 0.05, 0.02, 0.9), 6.0)
			VFX.puffs(Vector3(p.global_position.x, gy + 0.3, p.global_position.z), {"amount": 4, "life": 0.5, "size": 1.2, "radius": 1.5, "vmin": 1, "vmax": 3,
				"dir": Vector3.UP, "spread": 30.0, "glow": 1.1, "hot": 0.2, "outline_col": Color(0.3, 0.04, 0.02), "colors": fcols})
	pr.on_hit = func(pos: Vector3, _tg: Node3D) -> void:
		var ge = VFX.epic
		VFX.explosion(pos, 1.3, Color(1.0, 0.5, 0.1))
		# Storm Gōkakyū çarpması: geometrik ateş sütunu yerine her yöne kabaran ışıyan alev kütlesi -> kara duman + toprak/moloz
		var gp = Vector3(pos.x, Game.jutsu_floor(pos.x, pos.z), pos.z)
		var fire_ramp = [Color(1, 0.88, 0.35, 1), Color(1, 0.55, 0.1, 1), Color(0.9, 0.25, 0.05, 0.85), Color(0.35, 0.12, 0.06, 0.0)]
		FX.puff3d(pos, {"amount": 20, "life": 0.7, "size": 1.7 * ge, "radius": 1.2 * ge, "vmin": 3.0, "vmax": 9.0 * ge, "dir": Vector3.UP, "spread": 120.0,
			"damp": 3.5, "gravity": Vector3(0, 2.5, 0), "colors": fire_ramp, "emit": true, "grow": 1.9})
		get_tree().create_timer(0.22).timeout.connect(func():
			FX.puff3d(pos + Vector3.UP * 0.6, {"amount": 10, "life": 1.3, "size": 1.4 * ge, "radius": 1.5 * ge, "vmin": 1.0, "vmax": 3.5, "dir": Vector3.UP, "spread": 70.0,
				"damp": 1.5, "gravity": Vector3(0, 2.0, 0), "colors": [Color(0.32, 0.28, 0.26, 0.85), Color(0.25, 0.23, 0.22, 0.6), Color(0.2, 0.19, 0.19, 0.0)], "grow": 1.8}))
		VFX.debris(gp + Vector3.UP * 0.3, Color(0.42, 0.35, 0.28), 18, 9.0 * ge, 0.35)
		VFX.cracks(gp, 3.0 * ge)
		VFX.linger(pos, "katon", Color(1, 0.5, 0.1), ge * 1.2, 4.0)
		VFX.screen_lines(0.5, 0.8, Color(1, 0.85, 0.6))
		if Game.world:
			Game.world.env.add_shake(1.2)
			Game.world.env.screen_flash(0.15)
		Combat.hit_sphere(c, pos, 4.0, {"dmg": 14.0 * m, "element": "katon", "knock": 16.0, "launch": 7.0, "kind": "heavy", "burn": 3.0}, pr.hit_list)
	get_tree().current_scene.add_child(pr)
	pr.global_position = start + dir * 2.0
	VFX.element_trail(pr, "katon", Color(1, 0.5, 0.1), 2.0)


func j_katon_housenka(c: Node3D, t: Node3D) -> void:
	var m = _mult(c) * _elem_bonus(c, "katon")
	var dir = _aim(c, t)
	Sfx.play("fire", c.global_position, 1.3)
	for i in 5:
		var d = dir.rotated(Vector3.UP, deg_to_rad(-24 + i * 12)) + Vector3.UP * randf_range(0.0, 0.15)
		var pr = Projectile.new()
		pr.shooter = c
		pr.vel = d.normalized() * 22.0
		pr.radius = 0.6
		pr.life = 2.2
		pr.homing = t
		pr.homing_turn = 2.5
		pr.info = {"dmg": 8.0 * m, "element": "katon", "knock": 3.0, "kind": "light", "hitstop": 0.02, "burn": 1.5}
		pr.add_child(VFX.fireball(0.95))
		Projectile.trail(pr, [Color(1, 0.9, 0.5, 1), Color(1, 0.45, 0.06, 0.9), Color(0.7, 0.12, 0.03, 0)], 0.7, 24, 0.3, FX.tex_smoke, false)
		pr.on_hit = func(pos: Vector3, _tg: Node3D) -> void:
			VFX.explosion(pos, 0.45)
		get_tree().current_scene.add_child(pr)
		pr.global_position = _mouth(c) + d * 0.6
		VFX.element_trail(pr, "katon", Color(1, 0.5, 0.1), 0.8)


## Karyū Endan: ağızdan fışkıran alev, ejder biçimini alıp kıvrılarak hedefe dalar; yol boyu alev dilleri, çarpınca patlar
func j_katon_karyuu(c: Node3D, t: Node3D) -> void:
	var m = _mult(c) * _elem_bonus(c, "katon")
	Sfx.play("fire", c.global_position, 0.8)
	var mo = _mouth(c)
	var d = _aim(c, t)
	VFX.embers(mo, Color(1.0, 0.6, 0.15), 20, 8.0, 0.5)
	var pr = Projectile.new()
	pr.shooter = c
	pr.vel = (d + Vector3.UP * 0.35).normalized() * 14.0   # önce yükselip süzülür, gövdesi görünsün
	pr.radius = 1.4
	pr.life = 3.5
	pr.homing = t
	pr.homing_turn = 1.6
	pr.info = {"dmg": 28.0 * m, "element": "katon", "knock": 14.0, "launch": 5.0, "kind": "heavy", "hitstop": 0.08}
	var fm = VFX.mat_fire("fire", 2.6, 2.2, 0.36, 1.4, 0.1, Vector3(0, 0, 1))
	pr.add_child(VfxSerpent.dragon_head(fm, 2.6, Color(1, 1, 0.6)))
	var body = VfxSerpent.new()
	body.style = "fire"
	body.seed_id = "katon_karyuu"
	body.head = pr
	body.count = 18
	body.spacing = 1.4
	body.radius = 1.9
	body.mat = fm
	get_tree().current_scene.add_child(body)
	var t0 = randf() * TAU
	pr.on_tick = func(p: Projectile, dt: float) -> void:
		var side = p.vel.cross(Vector3.UP).normalized()
		p.global_position += side * sin(Time.get_ticks_msec() * 0.007 + t0) * dt * 6.0 + Vector3.UP * cos(Time.get_ticks_msec() * 0.005 + t0) * dt * 2.0
	pr.on_hit = func(pos: Vector3, _tg: Node3D) -> void:
		VFX.explosion(pos, 1.0, Color(1.0, 0.55, 0.15))
		VFX.embers(pos, Color(1.0, 0.6, 0.15), 30, 12.0)
		VFX.cracks(_ground(pos), 4.0, Color(0.08, 0.04, 0.02, 0.9), 6.0)
		Combat.hit_sphere(c, pos, 4.0, {"dmg": 10.0 * m, "element": "katon", "knock": 12.0, "launch": 4.0, "kind": "heavy"}, pr.hit_list)
		if Game.world: Game.world.env.add_shake(0.6)
	get_tree().current_scene.add_child(pr)
	pr.global_position = mo + d * 1.5


## Duvarı element çarpışmasına kaydet (mermi duvara girince elementlere göre çözülür)
func _element_wall(w: Node3D, el: String, owner_: Node3D, center: Vector3, half: Vector3, pow_: float) -> void:
	w.add_to_group("element_walls")
	w.set_meta("element", el)
	w.set_meta("owner", owner_)
	w.set_meta("center", center)
	w.set_meta("half", half)
	w.set_meta("power", pow_)


## Koni şeklinde sürekli akış (alev/su/rüzgar)
func _stream(c: Node3D, t: Node3D, dur: float, col: Color, el: String, tick_dmg: float, snd: String) -> void:
	Sfx.play(snd, c.global_position)
	var e = GPUParticles3D.new()
	e.amount = 130
	e.lifetime = 0.55
	var pm = ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0, -1)
	pm.spread = 14.0
	pm.initial_velocity_min = 22.0; pm.initial_velocity_max = 30.0
	pm.scale_min = 1.0; pm.scale_max = 2.4
	pm.damping_min = 4.0; pm.damping_max = 8.0
	var q = QuadMesh.new()
	var sg = minf(VFX.epic, 2.0)
	q.size = Vector2(1.6, 1.6) * sg
	pm.spread = 14.0 + sg * 5.0
	pm.initial_velocity_min *= sqrt(sg); pm.initial_velocity_max *= sqrt(sg)
	match el:
		"katon", "yoton":
			var pr: Array = VFX.FIRE_PRESETS[VFX.fire_preset_for(col)]
			pm.color_ramp = FX._gradient([pr[1], pr[2], pr[3], Color(pr[4].r, pr[4].g, pr[4].b, 0)])
			q.material = VFX.mat_puff(1.08, 0.3, pr[4], 0.36, 0.25, 1.2)
		"shakuton":   # kızıl-pembe sıcak ışık
			pm.color_ramp = FX._gradient([Color(1, 1, 1, 1), Color(1.0, 0.6, 0.62, 0.9), Color(1.0, 0.4, 0.45, 0.0)])
			q.material = FX._draw_mat(FX.tex_soft, true)
		"bakuton":    # beyaz kil tozu
			pm.color_ramp = FX._gradient([Color(1, 1, 0.97, 1), Color(0.93, 0.91, 0.86, 0.8), Color(0.9, 0.88, 0.84, 0)])
			q.material = VFX.mat_puff(1.0, 0.0, Color(0.6, 0.58, 0.55), 0.3, 0.25, 1.1)
		"suiton":
			pm.color_ramp = FX._gradient([Color(0.95, 0.99, 1, 1), Color(0.5, 0.8, 1.0, 1), Color(0.18, 0.48, 0.98, 0.8), Color(0.1, 0.3, 0.85, 0)])
			q.material = VFX.mat_puff(1.05, 0.0, Color(0.05, 0.18, 0.5), 0.3, 0.25, 1.3)
		"futton":     # kaynar buhar / asit sisi
			pm.color_ramp = FX._gradient([Color(1, 1, 1, 0.95), Color(0.9, 0.86, 0.93, 0.8), Color(0.82, 0.78, 0.86, 0)])
			q.material = VFX.mat_puff(1.0, 0.0, Color(0.55, 0.5, 0.6), 0.3, 0.25, 1.2)
		"hyoton":     # buz kristali kıvılcımları
			pm.color_ramp = FX._gradient([Color(1, 1, 1, 1), Color(0.8, 0.93, 1.0, 0.9), Color(0.7, 0.88, 1.0, 0)])
			q.material = FX._draw_mat(FX.tex_spark, true)
		"jinton":     # beyaz ışık zerreleri
			pm.color_ramp = FX._gradient([Color(1, 1, 1, 1), Color(0.95, 0.97, 1.0, 0.7), Color(0.9, 0.95, 1.0, 0)])
			q.material = FX._draw_mat(FX.tex_soft, true)
		"fuuton":
			pm.color_ramp = FX._gradient([Color(1, 1, 1, 0.9), Color(0.85, 1.0, 0.92, 0.5), Color(0.7, 1, 0.9, 0)])
			pm.particle_flag_align_y = true
			q.size = Vector2(0.25, 2.6)
			q.material = FX._draw_mat(FX.tex_spark, true, BaseMaterial3D.BILLBOARD_DISABLED)
		_:
			pm.color_ramp = FX._gradient([Color(1, 1, 0.8, 1), col, Color(col.r * 0.5, col.g * 0.3, col.b * 0.3, 0)])
			q.material = VFX.mat_puff(1.25, 0.3, col.darkened(0.7))
	pm.scale_curve = FX._curve([[0.0, 0.3], [0.5, 1.2], [1.0, 1.8]])
	pm.angle_min = 0; pm.angle_max = 360
	e.process_material = pm
	e.draw_pass_1 = q
	e.local_coords = false
	c.add_child(e)
	e.position = Vector3(0, 1.4, 0)
	var tw = create_tween()
	var ticks = int(dur / 0.15)
	for i in ticks:
		tw.tween_callback(func():
			if not is_instance_valid(c):
				return
			if e.get_meta("stopped", false):
				return
			var d = _aim(c, t)
			e.global_transform = Transform3D(Basis.looking_at(d, Vector3.UP), _mouth(c) + d * 0.4)
			for pr in get_tree().get_nodes_in_group("projectiles"):
				if pr.dead or pr.element() == "" or pr.shooter == null or not is_instance_valid(pr.shooter) or not Combat.hostile(c, pr.shooter):
					continue
				var rel: Vector3 = pr.global_position - (c.global_position + Vector3.UP * 1.2)
				var along = rel.dot(d)
				if along < 0.5 or along > 10.0 or (rel - d * along).length() > 1.2 + along * 0.2 + pr.radius:
					continue
				var r = Elements.clash({"el": el, "pow": tick_dmg * 6.0}, {"el": pr.element(), "pow": pr.power()})
				Elements.clash_fx(pr.global_position, r["effect"], el, pr.element(), pr.radius)
				pr.apply_clash(r["b_alive"], r["b_scale"])
				if not r["a_alive"]:
					e.set_meta("stopped", true)
					e.emitting = false
					return
			for k in 4:
				Combat.hit_sphere(c, c.global_position + Vector3.UP * 1.2 + d * (2.0 + k * 2.2), 1.2 + k * 0.4,
					{"dmg": tick_dmg, "element": el, "knock": 3.0, "kind": "light", "burn": 1.0 if el == "katon" else 0.0}))
		tw.tween_interval(0.15)
	tw.tween_callback(func():
		e.emitting = false
		get_tree().create_timer(1.0).timeout.connect(e.queue_free))


# ================================================================== SUITON
func j_suiton_suiryuudan(c: Node3D, t: Node3D) -> void:
	var m = _mult(c) * _elem_bonus(c, "suiton")
	Sfx.play("water", c.global_position)
	var fd = _aim_flat(c, t)
	var start = _ground(c.global_position + fd * 2.5) + Vector3.UP * 2.6
	# yerden fışkıran su sütunu
	VFX.splash(start - Vector3.UP * 2.4, 2.4)
	var pr = Projectile.new()
	pr.shooter = c
	pr.vel = Vector3.UP * 12.0 + fd * 8.0
	pr.radius = 1.8
	pr.life = 3.5
	pr.homing = t
	pr.homing_turn = 3.0
	pr.info = {"dmg": 30.0 * m, "element": "suiton", "knock": 16.0, "launch": 9.0, "kind": "heavy", "hitstop": 0.08}
	var wm = VFX.mat_water(Color(0.3, 0.62, 0.86), Color(0.52, 0.8, 0.95), Color(0.85, 0.96, 1.0), Vector3(0, 0, 1), 0.92, 0.9, 0.1)   # Storm su ejderi: açık camgöbeği
	var head = VfxSerpent.dragon_head(wm, 4.0)
	pr.add_child(head)
	# ejderha gövdesi: başın izini takip eden kıvrılan su halkaları + sırt yüzgeçleri
	var body = VfxSerpent.new()
	body.style = "water"
	body.seed_id = "suiton_suiryuudan"
	body.head = pr
	body.count = 22
	body.spacing = 1.9
	body.radius = 2.6
	body.mat = wm
	body.thin = 0.62   # Storm: kalın, akışkan tek parça gövde (ince tüp + sert yüzgeç kartları kaba/buz gibi duruyordu)
	get_tree().current_scene.add_child(body)
	var age = {"t": 0.0}
	pr.on_tick = func(p: Projectile, dt: float) -> void:
		age["t"] += dt
		if age["t"] < 0.55:   # kullanıcının önünde kıvrılarak yükselir (~8 m; ekrandan kaçıp kaybolmasın), sonra hedefe dalar
			p.vel = (Vector3.UP * 14.0 + fd.cross(Vector3.UP) * cos(age["t"] * 8.0) * 12.0 + fd * 6.0)
			return
		p.homing_turn = 6.0   # sonra hedefe dal
		if not t and p.life < 2.8:
			p.vel = p.vel.lerp(_aim(c, null) * 26.0, 0.05)
		p.vel = p.vel.normalized() * minf(30.0, p.vel.length() + 0.6)
	# gövdeden saçılan köpük
	WaterArt.ptrail(pr, [Color(0.97, 0.99, 1, 1), Color(0.55, 0.82, 1, 0.9), Color(0.15, 0.4, 0.95, 0)], 1.4, 50, 0.6, FX.tex_smoke, false)
	pr.on_hit = func(pos: Vector3, _tg: Node3D) -> void:
		VFX.splash(pos, 3.2)
		WaterArt.drops(pos, 18, 2.5, 12.0)
		Combat.hit_sphere(c, pos, 4.5, {"dmg": 12.0 * m, "element": "suiton", "knock": 14.0, "launch": 6.0, "kind": "heavy"}, pr.hit_list)
		Sfx.play("water", pos, 0.8)
		if Game.world: Game.world.env.add_shake(0.6)
	get_tree().current_scene.add_child(pr)
	pr.global_position = start


func j_suiton_suijinheki(c: Node3D, _t: Node3D) -> void:
	Sfx.play("water", c.global_position, 0.9)
	# su duvarı (anime Kisame/Tobirama): yerden fışkıran su, kullanıcının çevresinde dönerek yükselen kalın su kollarına dönüşür
	# (saydam küre yok) — dört su kolu sarmal çizip tepede birleşir, köpük ve damla saçar
	var wm = VFX.mat_water(Color(0.04, 0.27, 0.78), Color(0.2, 0.55, 1.0), Color(0.65, 0.9, 1.0), Vector3(0, 0, 1), 0.92, 0.8, 0.08)
	var dur = 2.4
	# (ref suiton.png / suiton3.png) ağızdan yere püsküren su, kullanıcının çevresinde dönen kalın halka bir su duvarına
	# dönüşüp yükselir; yüzeyinde dikey beyaz akış çizgileri. Halka: kapaksız silindir, yere oturur
	var ringm = VFX.mat_water(Color(0.04, 0.27, 0.78), Color(0.2, 0.55, 1.0), Color(0.65, 0.9, 1.0), Vector3(0, 1, 0), 0.9, 0.7, 0.05)
	var cm = CylinderMesh.new()
	cm.top_radius = 3.0; cm.bottom_radius = 3.4; cm.height = 1.0; cm.radial_segments = 40; cm.rings = 6
	cm.cap_top = false; cm.cap_bottom = false
	var ring = MeshInstance3D.new()
	ring.mesh = cm
	ring.material_override = ringm
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(ring)
	var gy0 = Game.jutsu_floor(c.global_position.x, c.global_position.z)
	ring.global_position = Vector3(c.global_position.x, gy0, c.global_position.z)
	ring.scale = Vector3(1, 0.05, 1)
	var rt = ring.create_tween()
	rt.tween_method(func(h: float):
		if is_instance_valid(ring) and is_instance_valid(c):
			ring.global_position = Vector3(c.global_position.x, gy0 + h * 0.5, c.global_position.z)
			ring.scale = Vector3(1, h, 1)
			ring.rotation.y += 0.08, 0.05, 6.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	rt.tween_interval(dur - 0.9)
	rt.tween_method(func(h: float):
		if is_instance_valid(ring):
			ring.global_position.y = gy0 + h * 0.5
			ring.scale = Vector3(1, h, 1), 6.0, 0.05, 0.45).set_ease(Tween.EASE_IN)
	rt.tween_callback(ring.queue_free)
	for k in 2:
		var head = Node3D.new()
		get_tree().current_scene.add_child(head)
		var a0 = k * TAU / 4.0
		head.global_position = c.global_position + Vector3(cos(a0), 0.1, sin(a0)) * 2.6
		var body = VfxSerpent.new()
		body.style = "water"
		body.thin = 1.0
		body.seed_id = "suijinheki%d" % k
		body.head = head
		body.count = 16
		body.spacing = 0.6
		body.radius = 0.9
		body.mat = wm
		get_tree().current_scene.add_child(body)
		var tw0 = head.create_tween()
		tw0.tween_method(func(u: float):
			if is_instance_valid(head) and is_instance_valid(c):
				var a = a0 + u * TAU * 3.0
				var h = 0.2 + 5.0 * minf(1.0, u * 2.2)
				var r = 2.6 - 0.6 * minf(1.0, u * 2.2)
				head.global_position = c.global_position + Vector3(cos(a) * r, h, sin(a) * r), 0.0, 1.0, dur)
		tw0.tween_callback(head.queue_free)
	for q in 8:
		get_tree().create_timer(q * 0.28).timeout.connect(func():
			if is_instance_valid(c):
				WaterArt.puffs(c.global_position + Vector3.UP * randf_range(0.5, 5.0), {"amount": 10, "life": 0.6, "size": 0.6, "radius": 2.4, "vmin": 2.0, "vmax": 5.0, "dir": Vector3.UP, "spread": 70.0,
					"gravity": Vector3(0, -14, 0), "glow": 1.05, "water": true, "outline_col": Color(0.05, 0.25, 0.7), "outline": 0.045, "rough": 0.12,
					"colors": [Color(0.7, 0.9, 1.0, 1), Color(0.3, 0.62, 1.0, 1), Color(0.2, 0.5, 0.95, 0.0)]}))
	var dome = Node3D.new()
	c.add_child(dome)
	VFX.splash(c.global_position, 2.5)
	var e = FX.aura(c, Color(0.6, 0.85, 1.0), 2.5, Vector3(0, 0.5, 0), 0.0)
	var tw = create_tween()
	for i in 16:
		tw.tween_callback(func():
			if not is_instance_valid(c):
				return
			for pr in get_tree().get_nodes_in_group("projectiles"):
				if pr.shooter != c and not pr.dead and pr.global_position.distance_to(c.global_position + Vector3.UP) < 4.0:
					if pr.element() == "":
						pr.block()
						continue
					# su kalkanı: ateşi söndürür; toprak/ağaç/yıldırım gibi üstün elementler geçebilir
					var r = Elements.clash({"el": "suiton", "pow": 30.0 * _mult(c)}, {"el": pr.element(), "pow": pr.power()})
					Elements.clash_fx(pr.global_position, r["effect"], "suiton", pr.element(), pr.radius)
					pr.apply_clash(r["b_alive"], r["b_scale"])
			Combat.hit_sphere(c, c.global_position + Vector3.UP, 3.6, {"dmg": 2.0, "element": "suiton", "knock": 10.0, "kind": "light"}))
		tw.tween_interval(0.15)
	tw.tween_callback(func():
		if is_instance_valid(e):
			e.emitting = false
		if is_instance_valid(dome):
			dome.queue_free()
		get_tree().create_timer(1.0).timeout.connect(e.queue_free))
	if c is Player:
		c.combat.invuln = 0.6


func j_suiton_suikoudan(c: Node3D, t: Node3D) -> void:
	var m = _mult(c) * _elem_bonus(c, "suiton")
	var pr = Projectile.new()
	pr.shooter = c
	pr.vel = _aim(c, t) * 15.0   # anime Kisame: köpekbalığı görünür hızla yüzerek gelir (eskiden 26 m/sn: 0.27 sn'de çarpıyordu)
	pr.radius = 1.2
	pr.life = 3.0
	pr.homing = t
	pr.homing_turn = 5.0
	pr.info = {"dmg": 34.0 * m, "element": "suiton", "knock": 14.0, "launch": 5.0, "kind": "heavy", "hitstop": 0.07}
	# gerçek su köpekbalığı modeli (SharkArt: dişli açık ağız, sırt/göğüs yüzgeci, sallanan hilal kuyruk) — genel "şekil" değil
	var sk = SharkArt.shark(2.3)   # ref: insan boyunun ~iki katı
	pr.add_child(sk)
	# su izi: 2D duman/sprite değil, arkasından saçılan 3B su damlaları
	var tr_t = {"t": 0.0}
	pr.on_tick = func(p: Projectile, dt: float) -> void:
		tr_t["t"] += dt
		if tr_t["t"] > 0.08:
			tr_t["t"] = 0.0
			WaterArt.spray(p.global_position - p.vel.normalized() * 2.4, 0.35, -p.vel.normalized() + Vector3.UP * 0.5, 45.0, 0.45)
	pr.on_hit = func(pos: Vector3, _tg: Node3D) -> void:
		VFX.splash(pos, 2.4)
		Sfx.play("water", pos)
	get_tree().current_scene.add_child(pr)
	pr.global_position = _hand(c)


# ================================================================== FUUTON
func j_fuuton_daitoppa(c: Node3D, t: Node3D) -> void:
	var m = _mult(c) * _elem_bonus(c, "fuuton")
	var d = _aim(c, t)
	d.y = clampf(d.y, -0.2, 0.3)
	Sfx.play("wind", c.global_position)
	var mo = _mouth(c)
	# Daitoppa: ağızdan patlayan geniş fırtına — iki dalga akım çizgisi, yerde kalkan toz seli, savrulan yaprak/çakıl
	WindFX.gust(mo + d * 0.4, d, 16.0, 9.0, {"n": 26, "speed": 38.0, "lift": 0.4})
	_wind_mass(c, mo, d, 20.0, 10.0, 6.5, 1.1)   # ref fuuton2 (Temari): kıvrılan beyaz çizgili yoğun rüzgâr kütlesi
	get_tree().create_timer(0.14).timeout.connect(func(): WindFX.gust(mo + d * 0.4, d, 18.0, 11.0, {"n": 18, "speed": 34.0, "leaves": false}))
	if c is Player:
		VFX.screen_lines(0.35, 0.7, Color(0.92, 1.0, 0.96))
	for k in 5:
		var pos = c.global_position + Vector3.UP * 1.2 + d * (2.0 + k * 2.4)
		Combat.hit_sphere(c, pos, 1.5 + k * 0.5, {"dmg": 12.0 * m, "element": "fuuton", "knock": 22.0, "launch": 3.0, "kind": "heavy", "dir": d, "hitstop": 0.05})


## Rüzgâr kütlesi: ağızdan ileri genişleyen yarı saydam soluk gövde + akışla kıvrılan yoğun beyaz çizgiler (kabuk değil: kenarları söner)
func _wind_mass(c: Node3D, mo: Vector3, d: Vector3, reach: float, width: float, height: float, dur: float) -> void:
	var gy = Game.jutsu_floor(mo.x, mo.z)
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_transform = Transform3D(Basis.looking_at(-d, Vector3.UP), Vector3(mo.x, gy, mo.z))
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/vfx_windmass.gdshader")
	m.set_shader_parameter("reach", reach)
	var mi = MeshInstance3D.new()
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	var mh = mo.y - gy
	var tw = root.create_tween()
	tw.tween_method(func(k: float):
		if is_instance_valid(mi):
			mi.mesh = FireArt.sheet_mesh(maxf(1.0, reach * k), lerpf(1.5, width, k), lerpf(1.2, height, k), mh, k * 1.5)
			m.set_shader_parameter("reach", maxf(1.0, reach * k)), 0.05, 1.0, dur * 0.45).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(a: float): m.set_shader_parameter("alpha", a), 1.0, 0.0, dur * 0.55)
	tw.tween_callback(root.queue_free)


## Ağızdan/elden ileri fırlayan saydam, kırılan hava konisi
func _wind_cone(from: Vector3, d: Vector3, length: float, width: float, dur: float) -> void:
	# görünür koni yapay duruyordu: organik rüzgâr hamlesi (akım çizgileri + toz + yaprak)
	WindFX.gust(from, d, length, width, {"n": int(clampf(10 + width * 1.5, 12, 28)), "speed": maxf(30.0, length / maxf(0.3, dur))})
	return
	length *= VFX.epic
	width *= VFX.epic
	var cm = CylinderMesh.new()
	cm.top_radius = 0.3; cm.bottom_radius = 0.5; cm.height = 1.0; cm.radial_segments = 20; cm.rings = 2
	cm.cap_top = false; cm.cap_bottom = false
	var mi = VFX._mi(cm, VFX.mat_wind(Color(0.82, 1.0, 0.92), 10.0, 7.0, Vector3.UP, 0.9))
	get_tree().current_scene.add_child(mi)
	var b = Basis(Quaternion(Vector3.UP, -d))
	mi.global_transform = Transform3D(b * Basis.from_scale(Vector3(0.3, 0.2, 0.3)), from)
	var tw = mi.create_tween()
	tw.tween_method(func(k: float):
		if not is_instance_valid(mi):
			return
		var L = length * k
		var w = lerpf(0.4, width, k)
		mi.global_transform = Transform3D(b * Basis.from_scale(Vector3(w, L, w)), from + d * L * 0.5), 0.05, 1.0, dur * 0.55).set_ease(Tween.EASE_OUT)
	tw.tween_property(mi, "scale", Vector3(0.01, 0.01, 0.01), dur * 0.45)
	tw.tween_callback(mi.queue_free)


func j_fuuton_shinkuu(c: Node3D, t: Node3D) -> void:
	var m = _mult(c) * _elem_bonus(c, "fuuton")
	for i in 4:
		get_tree().create_timer(i * 0.12).timeout.connect(func():
			if not is_instance_valid(c):
				return
			Sfx.play("wind", c.global_position, 1.6, 0.6)
			var pr = Projectile.new()
			pr.shooter = c
			pr.vel = _aim(c, t).rotated(Vector3.UP, randf_range(-0.05, 0.05)) * 45.0
			pr.radius = 0.5
			pr.info = {"dmg": 7.0 * m, "element": "fuuton", "knock": 4.0, "kind": "light", "hitstop": 0.02}
			pr.add_child(VFX.wind_ball(1.1))
			pr.on_hit = func(pos: Vector3, _tg: Node3D) -> void:
				WindFX.blast(pos, 2.2, 10, WindFX.LINE, false)
			get_tree().current_scene.add_child(pr)
			pr.global_position = _mouth(c)
			VFX.element_trail(pr, "fuuton", Color(0.8, 1, 0.9), 0.9))


## Rasenshuriken gövdesi (anime ref refs/rasenshuriken): mavi Rasengan çekirdek + dört kıvrık beyaz rüzgâr bıçağı (iki
## katmanlı düz disk, farklı hızda dönen). size = disk çapı (m).
func rasenshuriken_body(size := 2.8, tint := Color(0.78, 0.9, 1.0)) -> Node3D:
	var root = Node3D.new()
	root.add_child(VFX.rasengan(size * 0.22))   # animede çekirdek: bıçaklardan küçük mavi top
	var sh: Shader = load("res://shaders/vfx_rasenshuriken.gdshader")
	var discs: Array = []
	for k in 2:
		var pm = PlaneMesh.new()
		pm.size = Vector2.ONE
		var mi = MeshInstance3D.new()
		mi.mesh = pm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mt = ShaderMaterial.new()
		mt.shader = sh
		mt.set_shader_parameter("alpha", 1.0 if k == 0 else 0.55)
		mt.set_shader_parameter("tint", tint)
		mi.material_override = mt
		mi.scale = Vector3.ONE * size * (1.0 if k == 0 else 1.12)
		mi.position.y = -0.03 * k
		mi.rotation.x = 0.05 * k
		root.add_child(mi)
		discs.append(mt)
	root.set_meta("discs", discs)
	# anime fırıldağı hızlı döner (ikinci katman biraz yavaş = derinlik)
	var tw = root.create_tween().set_loops()
	tw.tween_method(func(v: float):
		for q in discs.size():
			(discs[q] as ShaderMaterial).set_shader_parameter("spin", v * (1.0 if q == 0 else 0.8)), 0.0, TAU * 4.0, 1.0)
	return root


## Hazırlık (CastAnim çağırır): kol başın üstünde; avuçta önce Rasengan, sonra rüzgâr bıçakları dışa açılarak büyür.
func form_fuuton_rasenshuriken(c: Node3D, dur: float) -> void:
	var md = c.get("model")
	if md == null or md.skel == null or md.skel.find_bone("RightHand") < 0:
		return
	var ba = BoneAttachment3D.new()
	ba.bone_name = "RightHand"
	md.skel.add_child(ba)
	var holder = Node3D.new()
	ba.add_child(holder)
	holder.top_level = true   # kemik dönüşünü almasın: disk dünyada yatay kalır
	var body = rasenshuriken_body(2.8 * VFX.epic)
	holder.add_child(body)
	body.scale = Vector3.ONE * 0.05
	var discs: Array = body.get_meta("discs")
	for d in discs:
		(d as ShaderMaterial).set_shader_parameter("grow", 0.0)
	c.set_meta("rs_form", holder)
	var tw = body.create_tween()
	tw.tween_property(body, "scale", Vector3.ONE, maxf(0.2, dur * 0.45)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float):
		for d in discs:
			(d as ShaderMaterial).set_shader_parameter("grow", v), 0.0, 1.0, maxf(0.2, dur * 0.5))
	Sfx.play("rasengan", c.global_position, 0.8)
	var stt = {"t": 0.0}
	var timer = Timer.new()
	timer.wait_time = 1.0 / 60.0
	holder.add_child(timer)
	timer.timeout.connect(func():
		stt["t"] += 1.0 / 60.0
		if not is_instance_valid(ba) or not ba.is_inside_tree():
			return
		holder.global_position = ba.global_position + Vector3.UP * 0.55
		var fdv: Vector3 = c.face_dir() if is_instance_valid(c) and c.has_method("face_dir") else Vector3.FORWARD
		holder.global_basis = Basis(fdv.cross(Vector3.UP).normalized(), 0.6)   # disk arkaya (kameraya) eğik: bıçaklar görünür (ref: geniş elips)
		if int(stt["t"] * 60.0) % 6 == 0:
			FX.burst(holder.global_position, {"amount": 6, "life": 0.35, "tex": FX.tex_spark, "size": 0.7, "vmin": 4.0, "vmax": 9.0, "spread": 180.0, "gravity": Vector3.ZERO,
				"colors": [Color(1, 1, 1, 0.0), Color(0.9, 0.97, 1.0, 0.7), Color(1, 1, 1, 0.0)]})
		if stt["t"] > 0.25 and int(stt["t"] * 60.0) % 20 == 0:
			Sfx.play("wind", holder.global_position, 1.8, 0.35)   # ince çınlama/uğultu
		if stt["t"] > dur + 0.6:   # atış kesildiyse kendini temizler
			ba.queue_free())
	timer.start()
	holder.global_position = ba.global_position + Vector3.UP * 0.55


func j_fuuton_rasenshuriken(c: Node3D, t: Node3D) -> void:
	var m = _mult(c) * _elem_bonus(c, "fuuton")
	var start = _hand(c) + Vector3.UP * 0.5
	if c.has_meta("rs_form"):
		var held = c.get_meta("rs_form")
		c.remove_meta("rs_form")
		if is_instance_valid(held):
			start = held.global_position
			var hb = held.get_parent()
			if is_instance_valid(hb):
				hb.queue_free()
	var pr = Projectile.new()
	pr.shooter = c
	pr.vel = _aim(c, t) * 26.0
	pr.radius = 1.6
	pr.life = 3.0
	pr.homing = t
	pr.homing_turn = 2.0
	# ortak hasar (rütbe + efsane kademe + ustalık): %25 çarpma, %75 genişleyen kürenin 9 hücre kesiği (eskiden sabit 20+9x8: S-rank'ın yarısı)
	var total = JutsuEngine.base_dmg(c, Data.jutsu.get("fuuton_rasenshuriken", {})) * _elem_bonus(c, "fuuton")
	pr.info = {"dmg": total * 0.2, "element": "fuuton", "knock": 4.0, "kind": "heavy", "hitstop": 0.05}
	var mb = total * 1.6 / 72.0   # _rasen_burst: 9 x 8 x m — kesiklerin ~yarısı tutuyor (ölçüldü), asıl hasar kürede
	var rb = rasenshuriken_body(2.8 * VFX.epic)
	rb.rotation.x = 0.5   # uçuşta disk hafif eğik (yandan bakınca bıçaklar görünür)
	pr.add_child(rb)
	WindFX.bullet(pr, 2.2)   # çevresinde çığlık atan akım çizgileri
	Sfx.play("rasengan", c.global_position, 1.4)
	pr.on_hit = func(pos: Vector3, _tg: Node3D) -> void:
		_rasen_burst(c, pos, mb)
	get_tree().current_scene.add_child(pr)
	pr.global_position = start
	VFX.element_trail(pr, "fuuton", Color(0.7, 0.9, 1), 2.0)


## Genişleme (anime): hedefi içine alan dev beyaz küre; yüzeyinde fırça gibi kıvrılan şeritler (mikro rüzgâr bıçakları),
## tabanda halka hâlinde savrulan toz, yerde krater. İçerideki hedef çok sayıda küçük darbeyle tutulur.
func _rasen_burst(c: Node3D, pos: Vector3, m: float, rad := 6.0, hits := true, hold := 1.0) -> void:
	rad *= VFX.epic
	var sp = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 40
	sm.rings = 20
	sp.mesh = sm
	sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/vfx_rasen_burst.gdshader")
	sp.material_override = mat
	get_tree().current_scene.add_child(sp)
	sp.global_position = pos
	sp.scale = Vector3.ONE * 0.3
	var tw = sp.create_tween()
	tw.tween_property(sp, "scale", Vector3.ONE * rad, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold)
	tw.tween_method(func(v: float): mat.set_shader_parameter("alpha", v), 1.0, 0.0, 0.45)
	tw.parallel().tween_property(sp, "scale", Vector3.ONE * rad * 1.15, 0.45)
	tw.tween_callback(sp.queue_free)
	sp.create_tween().tween_method(func(v: float): mat.set_shader_parameter("t", v), 0.0, 3.0, 0.3 + hold + 0.45)
	# içte soluk mavi çekirdek (ref: ortada Rasengan)
	var core = VFX.rasengan(clampf(rad * 0.2, 0.5, 3.0))
	get_tree().current_scene.add_child(core)
	core.global_position = pos
	var ct = core.create_tween()
	ct.tween_interval(0.3 + hold)
	ct.tween_property(core, "scale", Vector3.ONE * 0.05, 0.3)
	ct.tween_callback(core.queue_free)
	# tabanda dışa savrulan toz halkası + yerde krater
	var gy = Game.jutsu_floor(pos.x, pos.z)
	var base = Vector3(pos.x, gy, pos.z)
	var npuff = clampi(int(rad * 2.3), 6, 22)   # toz halkası küre boyuna göre (Mini'de küreyi örtmesin)
	for k in npuff:
		var a = TAU * k / float(npuff)
		FX.smoke_puff(base + Vector3(cos(a) * rad * 1.08, 0.2, sin(a) * rad * 1.08), clampf(rad / 6.0, 0.4, 1.4) * 0.9, 3)   # küre tabanında savrulan toz (küreyi örtmesin)
	WindFX.blast(base + Vector3.UP * 0.5, rad * 1.8, 30, Color(0.92, 0.97, 1.0, 0.9))
	VFX.cracks(base, rad * 1.3)
	VFX.debris(base, Color(0.5, 0.42, 0.32), 14, 16.0, 0.4)
	VFX.screen_lines(0.6, 1.0)
	FX.light(pos, Color(0.85, 0.93, 1.0), 12.0, rad * 5.0, 1.6)
	Sfx.play("wind", pos, 0.6)
	Sfx.play("rasengan", pos, 0.7)
	if Game.world:
		Game.world.env.add_shake(1.0)
		Game.world.env.screen_flash(0.35)
	# içeridekiler çok sayıda küçük darbeyle tutulur (hücre düzeyinde kesik)
	if not hits:
		return
	var ht = sp.create_tween()
	ht.tween_interval(0.15)
	for i in 9:
		ht.tween_callback(func():
			Combat.hit_sphere(c, pos, rad, {"dmg": 8.0 * m, "element": "fuuton", "knock": 0.5, "kind": "light", "hitstop": 0.02}))
		ht.tween_interval(0.12)


# ================================================================== DOTON
func j_doton_doryuheki(c: Node3D, _t: Node3D) -> void:
	var d = _aim_flat(c, _t)
	var pos = c.global_position + d * 3.5
	pos.y = Game.jutsu_floor(pos.x, pos.z)
	var wall = StaticBody3D.new()
	var cs = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	var wk = clampf(VFX.epic, 1.0, 1.4)
	sh.size = Vector3(12, 7, 2) * wk
	cs.shape = sh
	cs.position.y = 3.5 * wk
	wall.add_child(cs)
	var b = MB.new()
	# kaya katmanları: her biri biraz farklı kalınlık/renk/çıkıntı
	var strata = [Color(0.58, 0.47, 0.34), Color(0.5, 0.4, 0.29), Color(0.63, 0.52, 0.38), Color(0.46, 0.36, 0.26), Color(0.56, 0.45, 0.32), Color(0.52, 0.41, 0.3)]
	for k in 6:
		var hh = 7.0 / 6.0
		b.add("box", Vector3(randf_range(-0.15, 0.15), hh * (k + 0.5), 0), Vector3(12.0 - absf(k - 2.5) * 0.15, hh * 1.02, 2.0 + randf_range(-0.1, 0.25)), strata[k])
	# sivri kırık tepe
	for k in 9:
		var tx = -5.4 + k * 1.35
		b.add("cone", Vector3(tx, 7.4, randf_range(-0.2, 0.2)), Vector3(1.3, randf_range(0.8, 1.8), 1.6), strata[k % 3], Vector3(randf_range(-12, 12), 0, randf_range(-14, 14)), 5)
	# iki yüzde dikey çatlaklar
	for side in [-1.0, 1.0]:
		for k in 5:
			var cx = randf_range(-5.2, 5.2)
			var cy = randf_range(0.8, 5.5)
			for seg in 3:
				b.add("box", Vector3(cx + randf_range(-0.25, 0.25), cy + seg * 0.55, side * 1.08), Vector3(0.09, 0.62, 0.06), Color(0.16, 0.11, 0.08), Vector3(0, 0, randf_range(-35, 35)))
	# düz toprak duvar yüzeyi: düzensiz kaya levhaları, katman oyukları, taban molozu (iki yüz)
	for side in [-1.0, 1.0]:
		for k in 22:
			var lx = randf_range(-5.6, 5.6)
			var ly = randf_range(0.5, 6.5)
			var lc = strata[randi() % strata.size()].lerp(Color(0.4, 0.31, 0.22), randf() * 0.4)
			b.add("box", Vector3(lx, ly, side * (1.0 + randf_range(0.02, 0.12))), Vector3(randf_range(0.8, 2.2), randf_range(0.5, 1.2), 0.25), lc, Vector3(randf_range(-6, 6), randf_range(-8, 8), randf_range(-12, 12)))
		for k in 5:
			b.add("box", Vector3(randf_range(-0.3, 0.3), 1.0 + k * 1.2 + randf_range(-0.1, 0.1), side * 1.06), Vector3(11.4, 0.07, 0.06), Color(0.2, 0.14, 0.1), Vector3(0, 0, randf_range(-2, 2)))
		for k in 10:
			b.add("sphere", Vector3(randf_range(-5.8, 5.8), randf_range(0.1, 0.4), side * randf_range(1.0, 1.7)), Vector3(randf_range(0.4, 0.9), randf_range(0.3, 0.6), randf_range(0.4, 0.8)), strata[k % strata.size()].darkened(0.1))
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(Props.rock_toon())
	mi.scale = Vector3.ONE * wk
	wall.add_child(mi)
	get_tree().current_scene.add_child(wall)
	_element_wall(wall, "doton", c, Vector3(0, 3.5, 0) * wk, Vector3(6, 3.5, 1) * wk, 45.0 * _mult(c))
	wall.global_transform = Transform3D(Basis.looking_at(d, Vector3.UP), pos - Vector3(0, 7.5 * wk, 0))
	var tw = wall.create_tween()
	tw.tween_property(wall, "global_position:y", pos.y, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# yükselirken taban boyunca toz perdesi ve tepeden dökülen taşlar
	var side_v = d.cross(Vector3.UP).normalized()
	_ticks(4, 0.12, func(i):
		for k in 4:
			var bp = pos + side_v * (-5.0 + k * 3.3) + Vector3.UP * 0.3
			VFX.puffs(bp, {"amount": 6, "life": 0.9, "size": 1.6, "radius": 1.0, "vmin": 2, "vmax": 5, "dir": Vector3.UP, "spread": 40.0, "damp": 3.0,
				"outline_col": Color(0.3, 0.22, 0.14), "shade": 0.3, "colors": [Color(0.72, 0.6, 0.45, 1), Color(0.62, 0.5, 0.36, 1), Color(0.55, 0.45, 0.33, 0)]})
		VFX.debris(pos + Vector3.UP * (2.0 + i * 1.6) + side_v * randf_range(-5, 5), Color(0.52, 0.42, 0.3), 6, 7.0, 0.45))
	tw.tween_interval(14.0)
	tw.tween_property(wall, "global_position:y", pos.y - 7.5 * wk, 0.6)
	tw.tween_callback(wall.queue_free)
	FX.dust(pos, 3.0)
	VFX.debris(pos + Vector3.UP * 0.5, Color(0.5, 0.4, 0.3), 26, 14.0, 0.6)
	VFX.cracks(pos, 10.0)
	VFX.shockwave(pos + Vector3.UP * 0.1, Color(0.75, 0.62, 0.45), 14.0, 0.45)
	Sfx.play("earth", pos)
	if Game.world: Game.world.env.add_shake(0.4)
	# duvar mermileri durdurur (fizik ışını zaten çarpar)


func j_doton_doryuusou(c: Node3D, t: Node3D) -> void:
	var m = _mult(c) * _elem_bonus(c, "doton")
	var d = _aim(c, t)
	d.y = 0
	d = d.normalized()
	Sfx.play("earth", c.global_position, 1.2)
	for k in 8:
		get_tree().create_timer(k * 0.06).timeout.connect(func():
			if not is_instance_valid(c):
				return
			var p = c.global_position + d * (2.0 + k * 1.8)
			p.y = Game.jutsu_floor(p.x, p.z)
			var sp = MeshInstance3D.new()
			var b = MB.new()
			for s in 3:
				b.add("cone", Vector3(randf_range(-0.6, 0.6), 1.2, randf_range(-0.6, 0.6)), Vector3(0.9, 2.6 + randf() * 1.2, 0.9), Color(0.5, 0.42, 0.32), Vector3(randf_range(-15, 15), 0, randf_range(-15, 15)), 6)
			sp.mesh = b.build(Props.rock_toon())
			get_tree().current_scene.add_child(sp)
			sp.global_position = p - Vector3(0, 3, 0)
			var tw = sp.create_tween()
			tw.tween_property(sp, "global_position:y", p.y, 0.1)
			tw.tween_interval(1.2)
			tw.tween_property(sp, "global_position:y", p.y - 3.5, 0.4)
			tw.tween_callback(sp.queue_free)
			FX.dust(p, 0.8)
			VFX.debris(p + Vector3.UP * 0.3, Color(0.5, 0.42, 0.32), 5, 9.0, 0.35)
			VFX.cracks(p, 3.0)
			Combat.hit_sphere(c, p + Vector3.UP, 1.6, {"dmg": 9.0 * m, "element": "doton", "knock": 4.0, "launch": 9.0, "kind": "heavy", "hitstop": 0.03}))


func j_doton_yomi(c: Node3D, t: Node3D) -> void:
	var pos = _aim_ground(c, t, 8.0)
	pos.y = Game.jutsu_floor(pos.x, pos.z) + 0.05
	var mi = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 6.0; cm.bottom_radius = 6.0; cm.height = 0.1; cm.radial_segments = 24
	cm.material = Props.toon_color(Color(0.3, 0.24, 0.16))
	mi.mesh = cm
	get_tree().current_scene.add_child(mi)
	mi.global_position = pos
	FX.dust(pos, 2.0)
	Sfx.play("earth", pos, 0.7)
	var tw = mi.create_tween()
	for i in 20:
		tw.tween_callback(func():
			for f in get_tree().get_nodes_in_group("fighters"):
				if Combat.hostile(c, f) and f.global_position.distance_to(pos) < 6.0 and f.has_method("apply_status"):
					f.apply_status("slow", 0.6))
		tw.tween_interval(0.3)
	tw.tween_callback(mi.queue_free)


# ================================================================== RAITON
func _lightning_ball(c: Node3D, col_core: Color, col_edge: Color, snd: String) -> Node3D:
	var hand: Node3D = Node3D.new()
	_palm(c, hand)
	hand.add_child(VFX.lightning_ball(0.55, col_edge))   # animede eli saran göz alıcı şimşek kütlesi, arklar kola ve yere uzanır
	var arcs = Arcs.new()
	arcs.color = col_edge
	arcs.radius = 1.3
	arcs.count = 9
	arcs.width = 0.04
	hand.add_child(arcs)
	var l = OmniLight3D.new()
	l.light_color = col_edge; l.light_energy = 2.6; l.omni_range = 7.0
	hand.add_child(l)
	Sfx.play(snd, c.global_position)
	return hand


func j_raiton_chidori(c: Node3D, t: Node3D) -> void:
	var m = _mult(c) * _elem_bonus(c, "raiton")
	var hand = _lightning_ball(c, Color(0.9, 0.95, 1.0), Color(0.45, 0.7, 1.0), "chidori")
	# anime hazırlık: çömelir, sağ el yere yakın önde (şimşek yeri dağlar), sol el çaprazdan sağ bileği tutar
	_pose_chidori_charge(c)
	_hand_dash(c, t, hand, 0.55, 30.0, {"dmg": 34.0 * m, "element": "raiton", "knock": 14.0, "launch": 3.0, "kind": "heavy", "hitstop": 0.12, "stun": 1.0},
		Color(0.5, 0.75, 1.0), false, true)


## Chidori/Raikiri hazırlık pozu (overlay cast pozu): çömelme, sağ el yere yakın, sol el sağ bileği kavrar
func _pose_chidori_charge(c: Node3D) -> void:
	var md = c.get("model")
	if md == null or md.get("overlay") == null:
		return
	var rig = md.get("rig")
	if rig:
		rig.reach_arms = []   # avuç uzatma IK'si (kolu öne çeker) bu pozla çakışmasın; el açık kalır
	md.overlay.cast_pose = {"arms": [["RightUpperArm", Vector3(-0.3, -0.72, 0.62)], ["RightLowerArm", Vector3(-0.12, -0.88, 0.45)], ["RightHand", Vector3(-0.05, -0.6, 0.8)],
		["LeftUpperArm", Vector3(-0.2, -0.62, 0.75)], ["LeftLowerArm", Vector3(-0.92, -0.32, 0.2)], ["LeftHand", Vector3(-0.85, -0.45, 0.25)]],
		"fL": [0.9, 0.9, 1.3, 1.3, 0.8], "fR": [0.0, 0.0, 0.2, 0.2, 0.0], "spine": 28.0, "neck": -10.0, "crouch": 0.55}
	md.overlay.set_pose("cast", 1.0)


## Chidori/Raikiri hücum pozu: sağ kol şimşekle geride ve aşağıda sürünür, bacaklar koşu animasyonunda
func _pose_chidori_run(c: Node3D) -> void:
	var md = c.get("model")
	if md == null or md.get("overlay") == null:
		return
	md.overlay.cast_pose = {"arms": [["RightUpperArm", Vector3(-0.35, -0.6, -0.72)], ["RightLowerArm", Vector3(-0.2, -0.78, -0.6)], ["RightHand", Vector3(-0.1, -0.7, -0.7)]],
		"fR": [0.0, 0.0, 0.2, 0.2, 0.0], "spine": 30.0, "neck": -18.0, "crouch": 0.15}
	md.overlay.set_pose("cast", 1.0)


func j_rasengan(c: Node3D, t: Node3D) -> void:
	var m = _mult(c)
	var hand: Node3D = Node3D.new()
	_palm(c, hand)
	var ras = VFX.rasengan(0.34)   # animede avuç büyüklüğü (~30 cm)
	hand.add_child(ras)
	ras.scale = Vector3.ONE * 0.1
	ras.create_tween().tween_property(ras, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	FX.aura(hand, Color(0.5, 0.8, 1.0), 0.4, Vector3.ZERO, 0.0)
	Sfx.play("rasengan", c.global_position)
	# anime: Rasengan elde, hedefe KOŞARAK gidilir (kayarak değil) ve avuçla vurup öğütür
	_hand_dash(c, t, hand, 0.6, 22.0, {"dmg": 42.0 * m, "knock": 32.0, "launch": 9.0, "kind": "heavy", "hitstop": 0.16},
		Color(0.4, 0.7, 1.0), true, true, false)


## El tekniği: hazırlan, hedefe hücum et, çarpınca büyük patlama
## Avuç efekti: efekt sağ el kemiğine bağlanır, kol öne uzanır (avuç hedefe dönük, el açık) — animedeki Rasengan / Chidori tutuşu.
## Model yoksa eski sabit konum. Dönüş: true = ele bağlandı
func _palm(c: Node3D, hand: Node3D) -> bool:
	var m = c.get("model")
	if m == null or m.get("rig") == null or m.skel == null or m.skel.find_bone("RightHand") < 0:
		c.model.add_child(hand)
		hand.position = Vector3(0.35, 1.15, -0.55)
		return false
	var ba = BoneAttachment3D.new()
	ba.bone_name = "RightHand"
	m.skel.add_child(ba)
	ba.add_child(hand)
	hand.position = Vector3(0, 0.1, 0.06)   # avuç ortası, avucun önünde
	hand.tree_exited.connect(func(): if is_instance_valid(ba): ba.queue_free())
	var rig: WeaponRig = m.rig
	rig.reach_side = "Right"
	rig.reach_open = true
	rig.reach_arms = [["RightUpperArm", Vector3(-0.2, -0.15, 1.0)], ["RightLowerArm", Vector3(-0.08, -0.05, 1.0)]]
	m.create_tween().tween_property(rig, "reach_w", 1.0, 0.2)
	return true


func _palm_release(c: Node3D) -> void:
	var m = c.get("model") if is_instance_valid(c) else null
	if m and m.get("rig"):
		var rig: WeaponRig = m.rig
		var tw = m.create_tween()
		tw.tween_property(rig, "reach_w", 0.0, 0.25)
		tw.tween_callback(func(): rig.reach_open = false)


func _hand_dash(c: Node3D, t: Node3D, hand: Node3D, charge: float, speed: float, info: Dictionary, col: Color, grind := false, run := false, chidori_pose := true) -> void:
	var tw = create_tween()
	tw.tween_interval(charge)
	var state = {"t": 0.0, "done": false}
	tw.tween_callback(func():
		if not is_instance_valid(c):
			return
		var timer = Timer.new()
		timer.wait_time = 1.0 / 60.0
		c.add_child(timer)
		timer.timeout.connect(func():
			state["t"] += 1.0 / 60.0
			if state["done"] or not is_instance_valid(c):
				timer.queue_free()
				return
			var d: Vector3
			if c is Player:
				d = _aim_flat(c, t)
				c.facing = atan2(-d.x, -d.z)
			elif t and is_instance_valid(t) and not t.is_dead():
				d = (t.global_position - c.global_position)
				d.y = 0
				d = d.normalized()
				c.facing = atan2(-d.x, -d.z) if c is Player else c.facing
			else:
				d = c.face_dir()
			c.velocity = d * speed
			if c is Player:
				c.combat.action = "cast"
				c.combat.t = -10.0
			if run and c.get("model"):
				# kaymadan koşar: bacaklar koşu animasyonunda, sağ kol geride aşağıda
				if not state.has("ran"):
					state["ran"] = true
					if chidori_pose:
						_pose_chidori_run(c)   # Chidori: kol geride aşağıda; Rasengan: kol önde (avuç tutuşu kalır)
				c.model.play("run", 0.08, 1.9)
			if not state.has("trail") and is_instance_valid(hand):
				state["trail"] = VFX.trail(hand, 0.22, Color(1, 1, 1), col.lightened(0.3), col, 12, 0.6)
				state["last"] = hand.global_position
				if c is Player:
					VFX.screen_lines(0.5, 0.6, col.lightened(0.5))
			FX.burst(c.global_position + Vector3.UP, {"amount": 4, "life": 0.3, "tex": FX.tex_spark, "size": 1.2, "vmin": 1, "vmax": 3, "colors": [Color(1, 1, 1, 0.8), Color(col.r, col.g, col.b, 0)]})
			# arkada çatırdayan şimşek izi (sert bant yerine)
			if String(info.get("element", "")) == "raiton" and is_instance_valid(hand) and state.has("last") and int(state["t"] * 60.0) % 3 == 0:
				var hp = hand.global_position
				VFX.bolt(hp, state["last"] + Vector3(randf_range(-0.4, 0.4), randf_range(-0.6, 0.3), randf_range(-0.4, 0.4)), col.lightened(0.3), 0.07, 0.15, 1)
				state["last"] = hp
			var pt = c.global_position + Vector3.UP * 1.1 + d * 1.0
			var hits = Combat.hit_sphere(c, pt, 1.0, info)
			if not hits.is_empty() or state["t"] > 0.6:
				state["done"] = true
				_palm_release(c)
				if run and is_instance_valid(c) and c.get("model") and c.model.get("overlay"):
					c.model.overlay.set_pose("cast", 0.0)
				if c is Player:
					c.combat.action = ""
				c.velocity = Vector3.ZERO
				if not hits.is_empty():
					VFX.cracks(pt, 5.0)
					VFX.debris(pt, Color(0.5, 0.42, 0.32), 8, 11.0, 0.35)
					VFX.screen_lines(0.5, 1.0)
					if grind:
						var sp = VFX.rasengan(1.0)
						get_tree().current_scene.add_child(sp)
						sp.global_position = pt
						var tws = sp.create_tween()
						tws.tween_property(sp, "scale", Vector3.ONE * 5.0, 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
						tws.tween_property(sp, "scale", Vector3.ONE * 0.05, 0.2)
						tws.tween_callback(sp.queue_free)
					else:
						for k in 6:
							var dd = Vector3(randf_range(-1, 1), randf_range(-0.2, 1), randf_range(-1, 1)).normalized()
							VFX.bolt(pt, pt + dd * randf_range(4, 8), col, 0.18, 0.25, 1)
					FX.burst(pt, {"amount": 60, "life": 0.6, "tex": FX.tex_spark, "size": 2.0, "vmin": 10, "vmax": 30, "colors": [Color(1, 1, 1, 1), col, Color(col.r, col.g, col.b, 0)]})
					FX.light(pt, col, 12.0, 20.0, 0.5)
					if Game.world:
						Game.world.env.add_shake(1.0)
						Game.world.env.screen_flash(0.35)
					Sfx.play("boom", pt, 1.2)
				var h = hand
				var tw2 = h.create_tween()
				tw2.tween_property(h, "scale", Vector3.ONE * 0.01, 0.2)
				tw2.tween_callback(h.queue_free)
				timer.queue_free())
		timer.start())


func j_raiton_nagashi(c: Node3D, _t: Node3D) -> void:
	var m = _mult(c) * _elem_bonus(c, "raiton")
	var arcs = Arcs.new()
	arcs.color = Color(0.55, 0.8, 1.0)
	arcs.radius = 4.0
	arcs.count = 16
	arcs.width = 0.08
	c.add_child(arcs)
	arcs.position = Vector3(0, 1, 0)
	Sfx.play("chidori", c.global_position, 1.3)
	VFX.shockwave(c.global_position + Vector3.UP * 0.2, Color(0.6, 0.85, 1), 10.0, 0.35)
	VFX.star(c.global_position + Vector3.UP, Color(0.6, 0.85, 1.0), 4.5, 0.18)
	FX.light(c.global_position + Vector3.UP, Color(0.5, 0.75, 1), 8.0, 12.0, 0.6)
	Combat.hit_sphere(c, c.global_position + Vector3.UP, 4.0, {"dmg": 16.0 * m, "element": "raiton", "knock": 8.0, "kind": "heavy", "stun": 1.5, "hitstop": 0.06})
	get_tree().create_timer(0.6).timeout.connect(arcs.queue_free)


func j_raiton_armor(c: Node3D, _t: Node3D) -> void:
	var a = FX.aura(c, Color(0.6, 0.85, 1.0), 1.4, Vector3(0, 0.9, 0), 0.0)
	var arcs = Arcs.new()
	arcs.color = Color(0.6, 0.85, 1.0)
	arcs.radius = 1.1
	c.add_child(arcs)
	arcs.position = Vector3(0, 1, 0)
	if c is Player:
		Buffs.add("raiton_armor", 20.0, {"speed": 1.18, "melee": 1.2, "armor": 0.8})
	get_tree().create_timer(20.0).timeout.connect(func():
		a.emitting = false
		arcs.queue_free())
	Sfx.play("chidori", c.global_position, 0.8)


# ================================================================== GENEL / AKADEMİ
func j_bunshin(c: Node3D, _t: Node3D) -> void:
	for i in 2:
		var off = c.global_transform.basis.x * (2.5 if i == 0 else -2.5)
		var cl = ShadowClone.new()
		cl.team = c.team
		cl.look = c.model.look.duplicate()
		get_tree().current_scene.add_child(cl)
		cl.global_position = c.global_position + off
		FX.smoke_puff(cl.global_position + Vector3.UP, 1.0, 14)
	Hud.msg("Kage Bunshin no Jutsu!", Color(1, 1, 1))


## Kılık modeli: gizlenen asıl modelin konumunu, yönünü ve animasyonunu her karede kopyalar
class HengeSync extends Node:
	var owner_body: Node3D
	var disguise: CharacterModel
	func _process(_dt: float) -> void:
		if not is_instance_valid(owner_body) or not is_instance_valid(disguise):
			queue_free()
			return
		var m: CharacterModel = owner_body.model
		if m.visible:
			m.visible = false  # model yeniden kurulduysa tekrar gizle
		disguise.position = m.position
		disguise.rotation = m.rotation
		if m.current != "" and (m.current != disguise.current or not disguise.anim.is_playing()):
			disguise.play(m.current, 0.12)
		disguise.anim.speed_scale = m.anim.speed_scale


func j_henge(c: Node3D, _t: Node3D) -> void:
	if not c is Player:
		FX.smoke_puff(c.global_position + Vector3.UP, 1.0, 16)
		return
	if c.get_node_or_null("Disguise"):
		end_henge(c)
	FX.smoke_puff(c.global_position + Vector3.UP, 1.2, 22)
	FX.ring(c.global_position + Vector3.UP, Color(1, 1, 1, 0.8), 3.0, 0.3, false)
	Buffs.add("henge", 25.0, {"stealth": 1.0})
	c.model.visible = false
	var disguise = CharacterModel.new()
	disguise.name = "Disguise"
	c.add_child(disguise)
	var tops = [Color(0.5, 0.6, 0.45), Color(0.6, 0.35, 0.3), Color(0.8, 0.75, 0.55), Color(0.4, 0.45, 0.6)]
	var t0: Color = tops.pick_random()
	disguise.setup({"gender": ["m", "f"].pick_random(), "top": t0, "top2": t0.darkened(0.15), "top_style": "uzun", "pants_style": "sivil",
		"pants": Color(0.35, 0.3, 0.28), "sandal": Color(0.3, 0.22, 0.15), "band": null, "vest": null, "hair_style": ["kısa", "uzun", "kase"].pick_random(),
		"hair": Color(0.25, 0.18, 0.1), "age": "adult"})
	disguise.position = c.model.position
	disguise.rotation = c.model.rotation
	var sync = HengeSync.new()
	sync.name = "HengeSync"
	sync.owner_body = c
	sync.disguise = disguise
	c.add_child(sync)
	Hud.msg("Henge: köylü kılığındasın. Saldırırsan bozulur.", Color(0.9, 0.9, 0.7))


func end_henge(c: Node3D) -> void:
	var s = c.get_node_or_null("HengeSync")
	if s:
		s.free()
	var d = c.get_node_or_null("Disguise")
	if d:
		d.name = "DisguiseOld"
		d.queue_free()
		FX.smoke_puff(c.global_position + Vector3.UP, 1.0, 14)
	if c.get("model") and is_instance_valid(c.model):
		c.model.visible = true
	Buffs.remove("henge")


func j_shunshin(c: Node3D, t: Node3D) -> void:
	var d = _aim(c, t)
	d.y = 0
	d = d.normalized()
	var from = c.global_position
	var to = from + d * 14.0
	if t:
		to = t.global_position - d * 2.0
	var space = c.get_world_3d().direct_space_state
	var hit = space.intersect_ray(PhysicsRayQueryParameters3D.create(from + Vector3.UP, to + Vector3.UP, 1))
	if not hit.is_empty():
		to = hit["position"] - d * 0.8
	to.y = Game.jutsu_floor(to.x, to.z)
	FX.burst(from + Vector3.UP, {"amount": 26, "life": 0.9, "tex": FX.tex_leaf, "add": false, "size": 0.35, "vmin": 2, "vmax": 6,
		"tangent": 8.0, "spin": 360.0, "colors": [Color(0.4, 0.7, 0.3, 1), Color(0.35, 0.6, 0.25, 0)]})
	c.global_position = to
	FX.burst(to + Vector3.UP, {"amount": 26, "life": 0.9, "tex": FX.tex_leaf, "add": false, "size": 0.35, "vmin": 2, "vmax": 6,
		"tangent": 8.0, "spin": 360.0, "colors": [Color(0.4, 0.7, 0.3, 1), Color(0.35, 0.6, 0.25, 0)]})
	Sfx.play("whoosh", to, 1.4)


func j_shousen(c: Node3D, _t: Node3D) -> void:
	var a = FX.aura(c, Color(0.4, 1.0, 0.5), 1.0, Vector3(0, 0.9, 0), 0.0)
	Sfx.play("heal", c.global_position)
	var tw = create_tween()
	for i in 10:
		tw.tween_callback(func():
			if c is Player:
				c.hp = minf(c.max_hp, c.hp + 4.0 * Stats.jutsu_mult(Game.profile, "iryo"))
			for f in get_tree().get_nodes_in_group("fighters"):
				if f != c and not Combat.hostile(c, f) and f.global_position.distance_to(c.global_position) < 5 and f.get("hp") != null:
					f.hp = minf(f.max_hp, f.hp + 4.0))
		tw.tween_interval(0.2)
	tw.tween_callback(func():
		a.emitting = false
		get_tree().create_timer(1.0).timeout.connect(a.queue_free))


func j_narakumi(c: Node3D, t: Node3D) -> void:
	if t == null:
		return
	Sfx.play("genjutsu", t.global_position)
	FX.burst(t.global_position + Vector3.UP * 1.5, {"amount": 40, "life": 1.5, "tex": FX.tex_leaf, "add": false, "size": 0.3, "radius": 2.0,
		"vmin": 0.5, "vmax": 2.0, "gravity": Vector3(0, -1, 0), "spin": 200.0, "colors": [Color(0.75, 0.3, 0.9, 1), Color(0.5, 0.2, 0.7, 0)]})
	if t.has_method("apply_status"):
		t.apply_status("stun", 3.0)
		t.apply_status("fear", 3.0)
	if Game.world:
		Game.world.env.set_tint(Color(0.6, 0.3, 0.8, 0.25))
		get_tree().create_timer(0.8).timeout.connect(func(): Game.world.env.set_tint(Color(0, 0, 0, 0)))


func j_kokuangyo(c: Node3D, _t: Node3D) -> void:
	Sfx.play("genjutsu", c.global_position, 0.7)
	for f in get_tree().get_nodes_in_group("fighters"):
		if Combat.hostile(c, f) and f.global_position.distance_to(c.global_position) < 25 and f.has_method("lose_target"):
			f.lose_target(6.0)
	if Game.world:
		Game.world.env.set_tint(Color(0.05, 0.05, 0.1, 0.6))
		get_tree().create_timer(1.2).timeout.connect(func(): Game.world.env.set_tint(Color(0, 0, 0, 0)))


func j_kuchiyose(c: Node3D, _t: Node3D) -> void:
	Contracts.summon(c, Data.jutsu.get("kuchiyose", {"id": "kuchiyose"}))


func j_zofuku_kuchiyose_no_jutsu(c: Node3D, _t: Node3D) -> void:
	Contracts.summon(c, Data.jutsu.get("zofuku_kuchiyose_no_jutsu", {"id": "zofuku_kuchiyose_no_jutsu"}))


func j_reverse_summoning_technique(c: Node3D, _t: Node3D) -> void:
	Contracts.reverse_summon(c)


# ================================================================== KLAN TEKNİKLERİ
## Belirli aralıklarla n kez fn(i) çağır, sonunda done()
func _ticks(n: int, interval: float, fn: Callable, done := Callable()) -> void:
	var tw = create_tween()
	var ep = VFX.epic   # gecikmeli adımlar da yayının ölçeğiyle çizilsin
	var run = func(f: Callable, i):
		var o = VFX.epic
		VFX.epic = ep
		if i == null:
			f.call()
		else:
			f.call(i)
		VFX.epic = o
	for i in n:
		tw.tween_callback(run.bind(fn, i))
		tw.tween_interval(interval)
	if done.is_valid():
		tw.tween_callback(run.bind(done, null))


## Genel hücum: dur saniye boyunca hedefe/ileri koş, her karede on_tick(nokta) çağır
func _dash(c: Node3D, t: Node3D, dur: float, speed: float, on_tick: Callable, on_end := Callable()) -> void:
	var st = {"t": 0.0}
	var timer = Timer.new()
	timer.wait_time = 1.0 / 60.0
	c.add_child(timer)
	timer.timeout.connect(func():
		st["t"] += 1.0 / 60.0
		if not is_instance_valid(c):
			timer.queue_free()
			return
		var d: Vector3 = c.face_dir()
		if c is Player:
			d = _aim_flat(c, t)
		elif t and is_instance_valid(t) and not t.is_dead():
			d = t.global_position - c.global_position
			d.y = 0
			d = d.normalized()
			if c is Player:
				c.facing = atan2(-d.x, -d.z)
		c.velocity = Vector3(d.x * speed, c.velocity.y, d.z * speed)
		if c is Player:
			c.combat.action = "cast"
			c.combat.t = -10.0
		on_tick.call(c.global_position + Vector3.UP * 1.0 + d * 1.0)
		if st["t"] >= dur:
			if c is Player:
				c.combat.action = ""
			c.velocity = Vector3.ZERO
			if on_end.is_valid():
				on_end.call()
			timer.queue_free())
	timer.start()


func _ground(p: Vector3) -> Vector3:
	return Vector3(p.x, Game.jutsu_floor(p.x, p.z), p.z)


# ---------------------------------------------------------------- Hyuga
func j_juuken_64(c: Node3D, t: Node3D) -> void:
	var m = _mult(c)
	if t == null or c.global_position.distance_to(t.global_position) > 9.0:
		Hud.msg("Hakke 64: hedef çok uzak (en fazla 9 metre)", Color(0.8, 0.9, 1))
		return
	var to = t.global_position - (t.global_position - c.global_position).normalized() * (t.radius + 1.0)
	c.global_position = _ground(to)
	if c is Player:
		c.combat.face_to(t)
		c.combat.action = "cast"
		c.combat.t = -10.0
		c.combat.invuln = 1.6
	Combat.popup_text(t.global_position + Vector3.UP * 2.6, "Hakke Rokujuuyon Shou!", Color(0.85, 0.9, 1))
	var counts = [2, 4, 8, 16, 32, 64]
	if t.has_method("apply_status"):
		t.apply_status("stun", 1.6)
	_ticks(16, 0.08, func(i):
		if not is_instance_valid(t) or t.is_dead():
			return
		c.model.play(["jab", "cross"][i % 2], 0.02, 3.0, true)
		var pt = t.global_position + Vector3.UP * randf_range(0.8, 1.6)
		FX.burst(pt, {"amount": 6, "life": 0.25, "tex": FX.tex_spark, "size": 0.8, "vmin": 3, "vmax": 7, "colors": [Color(1, 1, 1, 1), Color(0.6, 0.8, 1, 0)]})
		Combat.hit_sphere(c, pt, 1.2, {"dmg": 2.6 * m, "knock": 0.3, "kind": "light", "hitstop": 0.0})
		if i % 3 == 0:
			Combat.popup_text(pt + Vector3.UP * 0.8, "%d" % counts[mini(5, i / 3)], Color(0.8, 0.9, 1))
			Sfx.play("punch", pt, 1.3), func():
		if c is Player:
			c.combat.action = ""
		if is_instance_valid(t) and not t.is_dead():
			Combat.hit_sphere(c, t.global_position + Vector3.UP, 1.6, {"dmg": 14.0 * m, "knock": 18.0, "launch": 4.0, "kind": "heavy", "hitstop": 0.12})
			FX.ring(t.global_position + Vector3.UP, Color(0.7, 0.85, 1), 6.0, 0.3, false))


func j_kaiten(c: Node3D, _t: Node3D) -> void:
	var m = _mult(c)
	# referans (Kaiten karesi): yarı saydam MAVİ kubbe (içinde açık çizgiler) + çevresinde dönen kahverengi toz kuşakları
	var R = 3.2
	var kcol = Color(0.62, 0.52, 0.4)   # toz kuşağı
	var dome = MeshInstance3D.new()
	var dsm = SphereMesh.new()
	dsm.radius = 1.0
	dsm.height = 1.0
	dsm.is_hemisphere = true
	dsm.radial_segments = 36
	dsm.rings = 14
	dome.mesh = dsm
	dome.material_override = VFX.mat_spiral(Color(0.78, 0.9, 1.0), Color(0.3, 0.55, 0.95), 5.0, 2.0, 14.0, 1.25, Vector3.UP)
	dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(dome)
	dome.global_position = c.global_position
	dome.scale = Vector3(0.3, 0.3, 0.3)
	var dtw = dome.create_tween()
	dtw.tween_property(dome, "scale", Vector3(R, R * 0.85, R), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	dtw.parallel().tween_property(dome, "rotation:y", TAU * 3.0, 1.15)
	dtw.tween_property(dome, "scale", Vector3(R * 1.05, 0.05, R * 1.05), 0.2)
	dtw.tween_callback(dome.queue_free)
	var swirl = func():
		if not is_instance_valid(c):
			return
		var o = c.global_position + Vector3.UP * 0.05
		for n in 6:   # toz kuşakları: kubbenin dışında, alçak, yatay dönen kahverengi şeritler
			var a0 = randf() * TAU
			var ph = randf_range(0.05, 0.7)
			var rr = R * randf_range(1.02, 1.15)
			WindFX.streak(func(u: float) -> Vector3:
				var a = a0 + u * 2.4
				var p2 = ph + u * 0.12
				return o + Vector3(cos(a) * cos(p2), sin(p2) * 0.8, sin(a) * cos(p2)) * rr, 0.35, 0.22, kcol, randf() * 0.05, 12)
	swirl.call()
	# anime: Neji kollarını iki yana açar (avuçlar açık, hafif çömelik), topuğu üstünde hızla döner — kubbe dönüşten doğar
	var mdl = c.get("model")
	if mdl and mdl.get("overlay"):
		var S = preload("res://scripts/combat/samehada_anim.gd")
		var F = preload("res://scripts/combat/style_legs.gd")
		var R_OUT = {"RightUpperArm": Vector3(-0.97, 0.12, 0.2), "RightLowerArm": Vector3(-0.95, 0.15, 0.25)}
		var L_OUT = {"LeftUpperArm": Vector3(0.97, 0.12, 0.2), "LeftLowerArm": Vector3(0.95, 0.15, 0.25)}
		var R_IN = {"RightUpperArm": Vector3(-0.35, -0.85, 0.35), "RightLowerArm": Vector3(0.1, 0.3, 0.95)}
		var L_IN = {"LeftUpperArm": Vector3(0.35, -0.85, 0.35), "LeftLowerArm": Vector3(-0.1, 0.3, 0.95)}
		mdl.overlay.fist = {"Right": -1.0, "Left": -1.0}
		mdl.overlay.play_keys({"len": 1.35, "hit": 0.1, "keys": [
			S._k(0.0, 0.35, 0, 4, Vector3(0, 0, 1), S._a(R_IN, L_IN), F.FIGHT),
			S._k(0.1, 0.45, 0, 2, Vector3(0, 0, 1), S._a(R_OUT, L_OUT), F.LOW),
			S._k(1.1, 0.45, 0, 2, Vector3(0, 0, 1), S._a(R_OUT, L_OUT), F.LOW),
			S._k(1.35, 0.35, 0, 4, Vector3(0, 0, 1), S._a(R_IN, L_IN), F.FIGHT)]}, 1.0)
	var f0 = float(c.get("facing")) if c.get("facing") != null else 0.0
	_ticks(44, 0.025, func(i):
		if is_instance_valid(c) and c.get("facing") != null:
			c.facing = f0 + TAU * 3.0 * float(i + 1) / 44.0
			if c.get("model") and not c is Player:
				c.model.rotation.y = c.facing)
	VFX.shockwave(c.global_position + Vector3.UP * 0.1, Color(0.7, 0.85, 1.0), 12.0, 0.5)
	FX.dust(c.global_position, 1.5)
	if c is Player:
		c.combat.invuln = 1.1
		c.combat.action = "cast"
		c.combat.t = -10.0
	Sfx.play("wind", c.global_position, 1.2)
	_ticks(10, 0.1, func(_i):
		if not is_instance_valid(c):
			return
		c.model.rotation.y += 1.4
		swirl.call()
		if _i % 3 == 0:
			VFX.puffs(c.global_position, {"amount": 10, "life": 0.5, "size": 1.0, "radius": 3.2, "vmin": 3, "vmax": 6, "dir": Vector3.UP, "spread": 30.0, "tangent": 20.0,
				"colors": [Color(0.85, 0.78, 0.62, 1), Color(0.75, 0.68, 0.52, 1), Color(0.7, 0.62, 0.48, 0)]})
		for pr in get_tree().get_nodes_in_group("projectiles"):
			if pr.shooter != c and not pr.dead and pr.global_position.distance_to(c.global_position + Vector3.UP) < 4.0:
				# mermiyi geri savur (sahibine döner)
				var out = (pr.global_position - c.global_position - Vector3.UP).normalized()
				pr.vel = out * maxf(14.0, pr.vel.length())
				pr.shooter = c
				pr.homing = null
				VFX.star(pr.global_position, Color(0.8, 0.9, 1.0), 2.0, 0.12)
		Combat.hit_sphere(c, c.global_position + Vector3.UP, 3.4, {"dmg": 3.0 * m, "knock": 22.0, "launch": 4.0, "kind": "heavy"}), func():
		if c is Player:
			c.combat.action = "")


# ---------------------------------------------------------------- Nara
func _shadow_line(c: Node3D, t: Node3D, dur: float) -> void:
	# referans (Kagemane / Kagemane Kage Shibari anime kareleri): yere yapışık, KENARSIZ ve PARLAMASIZ düz gölge şeridi —
	# doğal gölge tonunda, eni sabit (omuz genişliği), yumuşak S kıvrımı atışta bir kez seçilir (zamanla dalgalanmaz);
	# kullanıcının ayağından akıp hedefin altındaki yuvarlak gölge göletine bağlanır
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.045, 0.06, 0.86)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var im = ImmediateMesh.new()
	var mi = MeshInstance3D.new()
	mi.mesh = im
	mi.top_level = true
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(mi)
	var pool = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 1.0; cm.bottom_radius = 1.0; cm.height = 0.02; cm.radial_segments = 32
	pool.mesh = cm
	pool.material_override = mat
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(pool)
	var bend = randf_range(0.5, 1.0) * (1.0 if randf() < 0.5 else -1.0)   # S kıvrımının yönü/genliği (sabit)
	var half_w = 0.38
	var upd = func(_i):
		if not is_instance_valid(c) or not is_instance_valid(t):
			return
		var a = _ground(c.global_position)
		var b = _ground(t.global_position)
		var grow = ease(clampf(_i * 0.05 / 0.45, 0.0, 1.0), 0.5)
		var full = maxf(0.2, Vector2(b.x - a.x, b.z - a.z).length())
		var fwd = Vector3(b.x - a.x, 0, b.z - a.z).normalized() if full > 0.3 else Vector3.FORWARD
		var side = fwd.cross(Vector3.UP)
		var amp = bend * minf(1.2, full * 0.08)
		im.clear_surfaces()
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, mat)
		var n = 40
		var prev = a
		for k in n + 1:
			var u = float(k) / n * grow
			var p = a + fwd * full * u + side * amp * sin(u * TAU)   # yumuşak S (iki uç merkez hatta)
			p.y = Game.jutsu_floor(p.x, p.z) + 0.05
			var dir = (p - prev)
			dir.y = 0.0
			var sd = dir.normalized().cross(Vector3.UP) if dir.length() > 0.001 else side
			prev = p
			im.surface_add_vertex(p + sd * half_w)
			im.surface_add_vertex(p - sd * half_w)
		im.surface_end()
		pool.visible = grow > 0.95
		pool.global_position = b + Vector3.UP * 0.05
		pool.scale = Vector3(0.75, 1, 0.75)
	upd.call(0)
	_ticks(int(dur / 0.05), 0.05, upd, func():
		mi.queue_free()
		pool.queue_free())


## Yerde serbest gölge şeridi (uçlar fonksiyonla): _shadow_line ile aynı görünüş — kenarsız, parlamasız, sabit en, sabit S kıvrımı
func _shadow_path(a_fn: Callable, b_fn: Callable, dur: float, half_w := 0.38, pool := true) -> void:
	var mat = _shadow_mat(0.86)
	var im = ImmediateMesh.new()
	var mi = MeshInstance3D.new()
	mi.mesh = im
	mi.top_level = true
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(mi)
	var pm = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 1.0; cm.bottom_radius = 1.0; cm.height = 0.02; cm.radial_segments = 32
	pm.mesh = cm
	pm.material_override = mat
	pm.visible = false
	get_tree().current_scene.add_child(pm)
	var bend = randf_range(0.5, 1.0) * (1.0 if randf() < 0.5 else -1.0)
	var upd = func(_i):
		var a: Vector3 = a_fn.call()
		var b: Vector3 = b_fn.call()
		if a == Vector3.ZERO or b == Vector3.ZERO:
			return
		a = _ground(a)
		b = _ground(b)
		var grow = ease(clampf(_i * 0.05 / 0.45, 0.0, 1.0), 0.5)
		var full = maxf(0.2, Vector2(b.x - a.x, b.z - a.z).length())
		var fwd = Vector3(b.x - a.x, 0, b.z - a.z).normalized() if full > 0.3 else Vector3.FORWARD
		var side = fwd.cross(Vector3.UP)
		var amp = bend * minf(1.2, full * 0.08)
		im.clear_surfaces()
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, mat)
		var n = 40
		var prev = a
		for k in n + 1:
			var u = float(k) / n * grow
			var p = a + fwd * full * u + side * amp * sin(u * TAU)
			p.y = Game.jutsu_floor(p.x, p.z) + 0.05
			var dir = p - prev
			dir.y = 0.0
			var sd = dir.normalized().cross(Vector3.UP) if dir.length() > 0.001 else side
			prev = p
			im.surface_add_vertex(p + sd * half_w)
			im.surface_add_vertex(p - sd * half_w)
		im.surface_end()
		pm.visible = pool and grow > 0.95
		pm.global_position = b + Vector3.UP * 0.05
		pm.scale = Vector3(0.75, 1, 0.75)
	upd.call(0)
	_ticks(int(dur / 0.05), 0.05, upd, func():
		mi.queue_free()
		pm.queue_free())


## Gölge malzemesi (referans: doğal gölge tonu, parlamasız)
func _shadow_mat(alpha := 0.86) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.045, 0.06, alpha)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if alpha < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


## Gölge kamçısı (referans: Kagezukami / Kageyose kareleri): hedefin altındaki gölgeden kalkan, pürüzsüz, kapkara, sabit enli
## tek parça kol; hedefin bedenine sarmal dolanıp yükselir, ucu sivrilir. hand=true: ucu boğazı kavrayan kara el (Kubishibari).
func _shadow_coil(t: Node3D, dur: float, turns := 1.2, top := 0.8, hand := false, a0 := -1.0, col := Color(0.03, 0.025, 0.04)) -> void:
	if t == null or not is_instance_valid(t):
		return
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mi = MeshInstance3D.new()
	mi.top_level = true
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(mi)
	var start = a0 if a0 >= 0.0 else randf() * TAU
	var spin = 1.0 if randf() < 0.5 else -1.0
	var upd = func(_i):
		if not is_instance_valid(t):
			return
		var grow = ease(clampf(_i * 0.05 / 0.5, 0.02, 1.0), 0.6)
		var o = t.global_position
		var R = 0.3   # bedene yapışık (kapsül yarıçapı geniş kalıyordu: kol bedenden uzakta yay gibi duruyordu)
		var H = minf(float(t.get("height") if t.get("height") != null else 1.7), 1.75) * top   # kapsül boyu büyük olabiliyor: insan boyuyla sınırla
		if hand:
			# kol tam hedefin önünde (boğazda) bitsin: başlangıç açısını bitişe göre seç
			var fr = t.face_dir() if t.has_method("face_dir") else Vector3.FORWARD
			start = atan2(fr.z, fr.x) - spin * turns * TAU
		var pts = []
		var rad = []
		var N = 22
		for k in N + 1:
			var u = float(k) / N * grow
			var ang = start + spin * u * turns * TAU
			var r = lerpf(R + 0.35, R, clampf(u * 4.0, 0.0, 1.0))
			pts.append(o + Vector3(cos(ang) * r, maxf(0.02, u * H), sin(ang) * r))
			var w = lerpf(0.085, 0.05 if hand else 0.012, u / maxf(grow, 0.01))
			rad.append(Vector2(w, w * 0.8))
		var b = MB.new()
		Loft.tube(b, pts, rad, Color.WHITE, 8, 2, true, true)
		if hand and grow >= 0.99:
			# kara el (referans: Kubishibari karesi): iri yassı avuç boğazın önüne yapışık, parmaklar boynun iki yanına sarılır
			var fr2 = t.face_dir() if t.has_method("face_dir") else Vector3.FORWARD
			fr2.y = 0.0
			fr2 = fr2.normalized()
			var palm = o + Vector3.UP * (H - 0.06) + fr2 * 0.15
			var fwd = -fr2   # avuçtan boyna doğru
			var sd = fwd.cross(Vector3.UP)
			# avuç boğazın yanına yapışık, parmaklar boynun önünden öbür yana sarılır
			b.add_xf("sphere", Transform3D(Basis(fwd, Vector3.UP, -sd) * Basis.from_scale(Vector3(0.05, 0.24, 0.2)), palm), Color.WHITE, 10)   # referans: boğazı kaplayan iri yassı el
			for f in 4:
				var fy = (f - 1.5) * 0.07
				var base = palm + Vector3.UP * (0.06 + fy)
				var fp = [base, base + sd * 0.1 + fwd * 0.02, base + sd * 0.17 + fwd * 0.1, base + sd * 0.17 + fwd * 0.2]
				Loft.tube(b, fp, [Vector2(0.042, 0.03), Vector2(0.04, 0.028), Vector2(0.034, 0.024), Vector2(0.016, 0.012)], Color.WHITE, 6, 2, true, true)
			Loft.tube(b, [palm - Vector3.UP * 0.06, palm - Vector3.UP * 0.04 - sd * 0.12 + fwd * 0.04, palm - Vector3.UP * 0.02 - sd * 0.17 + fwd * 0.14], [Vector2(0.04, 0.03), Vector2(0.034, 0.026), Vector2(0.016, 0.012)], Color.WHITE, 6, 2, true, true)   # başparmak öbür yandan
		mi.mesh = b.build(null)
	upd.call(0)
	_ticks(int(dur / 0.05), 0.05, upd, func():
		mi.queue_free())


func after_t(t: float, fn: Callable) -> void:
	get_tree().create_timer(t).timeout.connect(fn)


## Kurama kekkei genkai (kanon, anime Yakumo): kullanıcı hedefin sahnesini çizer (1.5 sn savunmasız — vurulursa çizim bozulur,
## animedeki karşı oyun). Tamamlanırsa hedef resmin içine çekilir: genjutsu kilidi + kan gücüyle gerçek hasar. Boss kısa etkilenir.
## Oyuncu ve düşman Kurama aynı fonksiyonu kullanır.
func kurama_painting(c: Node3D, t: Node3D) -> void:
	if t == null or not is_instance_valid(t) or t.is_dead() or c.global_position.distance_to(t.global_position) > 26.0:
		if c is Player:
			Hud.msg("Resim genjutsusu: görebildiğin bir hedef seç (26 m).", Color(0.85, 0.6, 0.8))
		return
	var fd = c.face_dir() if c.has_method("face_dir") else Vector3.FORWARD
	var INKS = [Color(0.08, 0.06, 0.07), Color(0.62, 0.08, 0.14), Color(0.14, 0.24, 0.52), Color(0.1, 0.36, 0.22)]
	# tuval: elde tutulan kâğıt
	var canvas = MeshInstance3D.new()
	var qm = QuadMesh.new()
	qm.size = Vector2(0.7, 0.5)
	canvas.mesh = qm
	var cm = StandardMaterial3D.new()
	cm.albedo_color = Color(0.96, 0.94, 0.88)
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cm.cull_mode = BaseMaterial3D.CULL_DISABLED
	canvas.material_override = cm
	get_tree().current_scene.add_child(canvas)
	canvas.global_position = c.global_position + Vector3.UP * 1.12 + fd * 0.42
	canvas.look_at(canvas.global_position + fd, Vector3.UP)
	# fırça darbeleri: kavisli, uçları incelen mürekkep şeritleri (tuval düzleminde), sırayla belirir
	var strokes = []
	for k in 8:
		var sb = MB.new()
		var x0 = randf_range(-0.26, 0.1)
		var y0 = randf_range(-0.18, 0.18)
		var L = randf_range(0.18, 0.36)
		var bend = randf_range(-0.12, 0.12)
		var ang = randf_range(-0.9, 0.9)
		var pts = []
		var rad = []
		for q in 9:
			var u = q / 8.0
			var lx = u * L
			var ly = sin(u * PI) * bend
			pts.append(Vector3(x0 + cos(ang) * lx - sin(ang) * ly, y0 + sin(ang) * lx + cos(ang) * ly, -0.004))
			var w = 0.022 * sin(clampf(u, 0.08, 0.92) * PI) + 0.003
			rad.append(Vector2(w, 0.0015))
		Loft.tube(sb, pts, rad, INKS[k % 4], 6, 2, true, true)
		var sm = StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.cull_mode = BaseMaterial3D.CULL_DISABLED
		sm.vertex_color_use_as_albedo = true
		var st = MeshInstance3D.new()
		st.mesh = sb.build(null)
		st.material_override = sm
		canvas.add_child(st)
		st.visible = false
		strokes.append(st)
	# elde fırça
	var brush: Node3D = null
	var m = c.get("model")
	if m and m.skel and m.skel.find_bone("RightHand") >= 0:
		var ba = BoneAttachment3D.new()
		ba.bone_name = "RightHand"
		m.skel.add_child(ba)
		var bb = MB.new()
		bb.add("cyl", Vector3(0, 0.12, 0), Vector3(0.022, 0.24, 0.022), Color(0.55, 0.4, 0.22), Vector3.ZERO, 6)
		bb.add("cone", Vector3(0, 0.27, 0), Vector3(0.03, 0.07, 0.03), Color(0.05, 0.04, 0.05), Vector3.ZERO, 6)
		var bmi = MeshInstance3D.new()
		bmi.mesh = bb.build(null)
		var bm = StandardMaterial3D.new()
		bm.vertex_color_use_as_albedo = true
		bmi.material_override = bm
		ba.add_child(bmi)
		brush = ba
	if c.get("model"):
		c.model.play("cast", 0.1, 0.6, true)
	if c is Player:
		c.input_locked = 1.5
	var hp0 = float(c.get("hp"))
	var broke = [false]
	var cleanup = func():
		if is_instance_valid(brush):
			brush.queue_free()
	for k in 8:
		get_tree().create_timer(0.18 * k).timeout.connect(func():
			if broke[0] or not is_instance_valid(canvas):
				return
			if is_instance_valid(c) and float(c.get("hp")) < hp0 - 0.5:   # çizerken vuruldu: çizim bozulur (animedeki karşı oyun)
				broke[0] = true
				Combat.popup_text(c.global_position + Vector3.UP * 2.4, "Çizim bozuldu!", Color(1, 0.6, 0.5))
				if c is Player:
					c.input_locked = 0.0
				VFX.puffs(canvas.global_position, {"amount": 10, "life": 0.5, "size": 0.12, "radius": 0.2, "vmin": 1, "vmax": 3, "dir": Vector3.DOWN, "spread": 120.0, "add": false,
					"colors": [Color(0.9, 0.88, 0.82, 1), Color(0.9, 0.88, 0.82, 0)]})
				canvas.queue_free()
				cleanup.call()
				return
			var stv = strokes[k]
			stv.visible = true
			stv.scale = Vector3(0.05, 1, 1)
			stv.create_tween().tween_property(stv, "scale", Vector3.ONE, 0.14))
	get_tree().create_timer(1.5).timeout.connect(func():
		cleanup.call()
		if broke[0] or not is_instance_valid(c) or not is_instance_valid(t) or t.is_dead():
			if is_instance_valid(canvas):
				canvas.queue_free()
			return
		if is_instance_valid(canvas):
			var tw = canvas.create_tween()
			tw.tween_property(canvas, "global_position", t.global_position + Vector3.UP * 1.3, 0.22)
			tw.parallel().tween_property(canvas, "scale", Vector3.ONE * 3.0, 0.22)
			tw.tween_property(canvas, "scale", Vector3.ONE * 0.01, 0.12)
			tw.tween_callback(canvas.queue_free)
		get_tree().create_timer(0.22).timeout.connect(func():
			if not is_instance_valid(t) or not is_instance_valid(c):
				return
			var gm = Eyes.genjutsu_land(c, t, false)   # Yakumo'nun resmi göz teması istemez; direnç/ayna yine işler
			if gm <= 0.0:
				return
			var boss = t.has_meta("boss")
			var hold = (2.0 if boss else 4.0) * gm
			# resim gerçeğe dönüşür: hedefin çevresinde dönen renkli fırça darbeleri, yerden kalkıp bedeni saran mürekkep dalları
			var o = t.global_position
			for n in 14:
				var col = INKS[n % 4]
				var a0 = randf() * TAU
				var h0 = randf_range(0.2, 1.9)
				var rr = randf_range(0.7, 1.3)
				WindFX.streak(func(u: float) -> Vector3:
					var aa = a0 + u * TAU * 0.8
					return o + Vector3(cos(aa) * rr * (1.0 - u * 0.4), h0 + sin(u * PI) * 0.3, sin(aa) * rr * (1.0 - u * 0.4)), 0.5, 0.09, col, n * 0.025, 12)
			for k in 3:
				_shadow_coil(t, hold, 1.0 + k * 0.3, 0.75 + k * 0.08, false, k * TAU / 3.0, [Color(0.06, 0.05, 0.06), Color(0.55, 0.07, 0.12), Color(0.06, 0.05, 0.06)][k])
			VFX.puffs(o + Vector3.UP * 1.0, {"amount": 18, "life": 0.5, "size": 0.18, "radius": 0.5, "vmin": 2, "vmax": 5, "dir": Vector3.UP, "spread": 160.0, "add": false,
				"colors": [Color(0.08, 0.06, 0.07, 1), Color(0.55, 0.07, 0.12, 0.0)]})
			if t is Player and Game.world and Game.world.env:
				Game.world.env.flash_tint(Color(0.85, 0.78, 0.6, 0.35), hold)   # kurban resmin dünyasında: kâğıt tonu
			t.apply_status("bind", hold)
			t.take_hit({"dmg": (18.0 if boss else 32.0) * _mult(c) * gm, "knock": 0.0, "launch": 0.0, "kind": "light", "pierce_guard": true, "attacker": c})
			Combat.popup_text(t.global_position + Vector3.UP * 2.6, "Resmin içine çekildi", Color(0.9, 0.5, 0.8))
			Sfx.play("genjutsu", t.global_position, 0.8)))


## Kurama kusuru (kanon): bastırılmış ikinci kişilik (Ido) gücü kontrol eder — can %25 altına düşünce 60 sn'de bir uyanır:
## 6 sn genjutsu/jutsu gücü artar ama kontrol tamamen sende değildir (hareketlerin yavaşlar).
func kurama_ido_check(c: Node3D) -> void:
	if not (c is Player) or String(Game.profile.get("clan", "")) != "kurama":
		return
	if float(c.hp) > float(c.max_hp) * 0.25:
		return
	var now = Time.get_ticks_msec()
	if c.has_meta("ido_t") and now - int(c.get_meta("ido_t")) < 60000:
		return
	c.set_meta("ido_t", now)
	Buffs.add("ido", 6.0, {"jutsu": 1.5, "speed": 0.75, "_name": "Ido", "_desc": "bastırılmış kişilik uyandı: güç artar, kontrol azalır"})
	Combat.popup_text(c.global_position + Vector3.UP * 2.6, "Ido uyandı...", Color(0.75, 0.2, 0.4))
	if Game.world and Game.world.env:
		Game.world.env.flash_tint(Color(0.45, 0.05, 0.2, 0.3), 6.0)


## Nara gölgesi ışığa bağlı (anime: gün batımında gölge uzar, öğlen kısalır, karanlıkta gölge zayıf)
func shadow_k() -> float:
	var tod = float(Game.world.env.time_of_day) if Game.world and Game.world.get("env") else 0.5
	if (tod > 0.22 and tod < 0.32) or (tod > 0.68 and tod < 0.8):
		return 1.5   # şafak / gün batımı: uzun gölgeler
	if tod >= 0.4 and tod <= 0.6:
		return 0.85  # öğle: kısa gölge
	if tod < 0.2 or tod > 0.84:
		return 0.7   # gece: yalnız ay ve fener ışığı
	return 1.0


func shadow_reach() -> float:
	return 22.0 * shadow_k()


func j_kagemane(c: Node3D, t: Node3D) -> void:
	var reach = shadow_reach()
	if t == null or c.global_position.distance_to(t.global_position) > reach:
		Hud.msg("Kagemane: gölgen şu ışıkta en fazla %d metreye uzanır" % int(reach), Color(0.8, 0.8, 0.9))
		return
	Sfx.play("genjutsu", c.global_position, 0.6)
	_shadow_line(c, t, 4.0 * shadow_k())
	if t.has_method("apply_status"):
		t.apply_status("bind", 4.0 * shadow_k())
	Combat.popup_text(t.global_position + Vector3.UP * 2.4, "Kagemane: başarılı!", Color(0.7, 0.7, 0.9))


func j_kage_kubi(c: Node3D, t: Node3D) -> void:
	var m = _mult(c)
	if t == null or c.global_position.distance_to(t.global_position) > shadow_reach():
		Hud.msg("Kage Kubi Shibari: gölgen şu ışıkta oraya uzanmıyor", Color(0.8, 0.8, 0.9))
		return
	_shadow_line(c, t, 4.0 * shadow_k())
	if t.has_method("apply_status"):
		t.apply_status("bind", 4.0 * shadow_k())
	Sfx.play("genjutsu", c.global_position, 0.5)
	# referans (Kubishibari karesi): gölgeden kalkan kara kol bedene dolanıp tırmanır, ucundaki kara el boğazı kavrar
	var hold = 4.0 * shadow_k()
	after_t(0.45, func():
		if is_instance_valid(t):
			_shadow_coil(t, hold - 0.45, 1.1, 0.8, true, 0.0)
			_shadow_coil(t, hold - 0.45, 0.8, 0.6, false, PI))
	_ticks(8, 0.5, func(_i):
		if is_instance_valid(t) and not t.is_dead():
			Combat.hit_sphere(c, t.global_position + Vector3.UP, 1.0, {"dmg": 6.0 * m, "knock": 0.0, "kind": "light"}))


# ---------------------------------------------------------------- Akimichi
func j_baika(c: Node3D, _t: Node3D) -> void:
	if not c is Player:
		return
	c.combat.modes.set_size(3.0, 20.0)
	FX.smoke_puff(c.global_position + Vector3.UP * 2.0, 2.2, 24)
	Buffs.add("baika", 20.0, {"melee": 1.45, "speed": 0.85, "armor": 0.85, "reach": 2.2})
	Hud.msg("Baika no Jutsu! (20 sn dev)", Color(1, 0.8, 0.5))


func j_nikudan(c: Node3D, t: Node3D) -> void:
	var m = _mult(c)
	var ball = PathJutsu.get_pinst()._aki_ball(c, 1.6)   # kanon: kıyafet renginde, saç tutamlı top
	c.add_child(ball)
	ball.position = Vector3(0, 1.6, 0)
	c.model.visible = false
	Sfx.play("earth", c.global_position, 0.8)
	var hit = []
	_dash(c, t, 1.3, 22.0, func(pt):
		ball.rotation.x -= 0.35
		FX.dust(_ground(c.global_position), 0.5)
		for h in Combat.hit_sphere(c, pt, 2.2, {"dmg": 18.0 * m, "knock": 16.0, "launch": 5.0, "kind": "heavy", "hitstop": 0.06}, hit):
			hit.append(h), func():
		ball.queue_free()
		if is_instance_valid(c):
			c.model.visible = true
			FX.smoke_puff(c.global_position + Vector3.UP, 1.2, 12))


# ---------------------------------------------------------------- Aburame
func j_mushi_swarm(c: Node3D, t: Node3D) -> void:
	var m = _mult(c)
	var st = {"pos": _aim_ground(c, t, 10.0)}
	var cloud = GPUParticles3D.new()
	cloud.amount = 520
	cloud.lifetime = 1.1
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 2.4
	pm.spread = 180.0
	pm.initial_velocity_min = 1.0; pm.initial_velocity_max = 3.0
	pm.gravity = Vector3.ZERO
	pm.orbit_velocity_min = 0.5; pm.orbit_velocity_max = 1.2
	pm.scale_min = 0.8; pm.scale_max = 1.6
	pm.color_ramp = FX._gradient([Color(0.05, 0.05, 0.05, 0.0), Color(0.08, 0.08, 0.06, 1.0), Color(0.05, 0.05, 0.05, 0.0)])
	cloud.process_material = pm
	var q = QuadMesh.new()
	q.size = Vector2(0.22, 0.22)
	q.material = FX._draw_mat(FX.tex_soft, false)
	q.material.albedo_color = Color(0.0, 0.0, 0.0, 1.0)
	cloud.draw_pass_1 = q
	cloud.local_coords = false
	get_tree().current_scene.add_child(cloud)
	cloud.global_position = c.global_position + Vector3.UP * 1.3
	cloud.emitting = true
	# sürünün koyu pusu: içi görünmeyen kara bulut çekirdeği
	var haze = MeshInstance3D.new()
	haze.mesh = VFX._sphere(0.5, 16, 8)
	var hm = StandardMaterial3D.new()
	hm.albedo_color = Color(0.01, 0.01, 0.01, 0.82)
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.disable_fog = true
	haze.material_override = hm
	haze.scale = Vector3.ONE * 3.2
	cloud.add_child(haze)
	var hw = haze.create_tween().set_loops()
	hw.tween_property(haze, "scale", Vector3(3.6, 2.8, 3.4), 0.3)
	hw.tween_property(haze, "scale", Vector3(3.0, 3.4, 3.1), 0.3)
	Sfx.play("wind", c.global_position, 2.0, 0.5)
	_ticks(30, 0.15, func(i):
		if t and is_instance_valid(t) and not t.is_dead():
			st["pos"] = t.global_position
		cloud.global_position = cloud.global_position.lerp(st["pos"] + Vector3.UP * 1.2, 0.25)
		if i > 3 and i % 2 == 0:
			for h in Combat.hit_sphere(c, cloud.global_position, 2.0, {"dmg": 2.4 * m, "knock": 0.0, "kind": "light"}):
				if h.has_method("apply_status"):
					h.apply_status("slow", 1.0), func():
		cloud.emitting = false
		get_tree().create_timer(1.0).timeout.connect(cloud.queue_free))


# ---------------------------------------------------------------- Inuzuka
func j_ninken(c: Node3D, _t: Node3D) -> void:
	for n in get_tree().get_nodes_in_group("ninken"):
		n.queue_free()
	var d = Ninken.new()
	d.owner_f = c
	get_tree().current_scene.add_child(d)
	d.global_position = _ground(c.global_position + c.global_transform.basis.x * 2.0)
	FX.smoke_puff(d.global_position + Vector3.UP * 0.5, 0.8, 10)
	Hud.msg("Ninken yanında! Düşmanlara birlikte saldırırsınız.", Color(0.9, 0.8, 0.6))


## Gatsūga (kanon, referans karesi): Inuzuka ve ninkeni bedenlerini döndürerek İLERİ DOĞRU dönen iki gri matkaba dönüşür
## (bedenler görünmez; matkap ekseni gidiş yönünde — topaç gibi kendi etrafında değil). Hedefin içinden çaprazlama geçip
## geri dönerek defalarca geçerler; ninken öbür yandan aynı yolu ters kesişerek izler. Yerde oyuklar açılır.
func j_gatsuga(c: Node3D, t: Node3D) -> void:
	var tt = _tg(c, t, 22.0)
	var aim = _aim_flat(c, t)
	var p: Vector3 = tt.global_position if tt else c.global_position + aim * 12.0
	gatsuga_run(c, p, 1.0, 1.35, "gatsuga", 1.0)
	for n in get_tree().get_nodes_in_group("ninken"):
		if n.get("owner_f") == c and not n.dead:
			gatsuga_run(n, p, -1.0, 1.2, "gatsuga", 0.6, c)
	Sfx.play("wind", c.global_position, 1.6)


## Matkap koşusu: node -> P'den 3 kez çapraz geçiş (her geçiş ~0.3 sn). side: geçiş açısının yönü (sahip +1, ninken -1)
func gatsuga_run(node: Node3D, p: Vector3, side: float, size: float, jid: String, mul: float, owner_c: Node3D = null) -> void:
	var c: Node3D = owner_c if owner_c else node
	var drill = gatsuga_drill(size)
	drill.top_level = true
	node.add_child(drill)
	var vis: Node3D = node.get("model") if node.get("model") else node.get("vis")
	var dm: ShaderMaterial = drill.get_meta("drill_mat")
	dm.set_shader_parameter("fade", 0.0)
	var start: Vector3 = node.global_position
	drill.global_position = start + Vector3.UP * 1.0 * size
	drill.look_at(drill.global_position + Vector3(p.x - start.x, 0, p.z - start.z).normalized() if Vector2(p.x - start.x, p.z - start.z).length() > 0.1 else drill.global_position + Vector3.FORWARD, Vector3.UP)
	# kanon: beden yerinde fırıl fırıl döner, etrafında matkap oluşur; matkap tamamlanınca beden onun içinde kaybolur
	var form = 0.22
	var tw0 = node.create_tween()
	tw0.tween_method(func(u: float):
		if is_instance_valid(drill):
			dm.set_shader_parameter("fade", u)
		if is_instance_valid(vis):
			vis.rotation.y += 0.9, 0.0, 1.0, form)
	tw0.tween_callback(func():
		if is_instance_valid(vis):
			vis.visible = false)
	var d0: Vector3 = (p - start)
	d0.y = 0
	d0 = d0.normalized() if d0.length() > 0.1 else Vector3.FORWARD
	# yol: başlangıç -> hedefin 5 m ötesi -> çapraz geri dönüş -> yeniden geçiş
	var pts = [start, p + d0 * 5.0, p + d0.rotated(Vector3.UP, side * 2.5) * 5.0, p + d0.rotated(Vector3.UP, -side * 0.6) * 5.5]
	var lens = []
	var total = 0.0
	for i in pts.size() - 1:
		var L = (pts[i + 1] as Vector3).distance_to(pts[i])
		lens.append(L)
		total += L
	var hitd = {}
	var dur = 0.95
	var tw = node.create_tween()
	tw.tween_interval(form)
	tw.tween_method(func(u: float):
		if not is_instance_valid(node) or not is_instance_valid(drill):
			return
		var dist = u * total
		var i = 0
		while i < lens.size() - 1 and dist > lens[i]:
			dist -= lens[i]
			i += 1
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var q = a.lerp(b, clampf(dist / maxf(0.01, lens[i]), 0.0, 1.0))
		q.y = _ground(q).y
		node.global_position = q
		var dv = (b - a)
		dv.y = 0
		drill.global_position = q + Vector3.UP * 1.0 * size
		if dv.length() > 0.01:
			drill.look_at(drill.global_position + dv.normalized(), Vector3.UP)   # matkabın sivri ucu gidiş yönünde
		if randf() < 0.35:
			FX.dust(q, 0.6 * size)
			VFX.cracks(q, 1.2 * size, Color(0.12, 0.09, 0.07, 0.8), 3.0)
		for f in get_tree().get_nodes_in_group("fighters"):
			if Combat.hostile(c, f) and not f.is_dead() and f.global_position.distance_to(q) < 1.6 * size + f.radius:
				var key = "%d_%d" % [f.get_instance_id(), i]   # her geçişte bir kez çarpar
				if not hitd.has(key):
					hitd[key] = true
					f.take_hit(_inf(c, jid, 0.55 * mul, {"knock": 8.0, "launch": 3.0, "kind": "heavy", "hitstop": 0.04, "dir": dv.normalized() if dv.length() > 0.01 else Vector3.FORWARD, "attacker": c})), 0.0, 1.0, dur)
	tw.tween_callback(func():
		if is_instance_valid(drill):
			drill.queue_free()
		if is_instance_valid(vis):
			vis.visible = true
		if node is Player:
			node.combat.action = "")
	if node is Player:
		node.combat.action = "cast"
		node.combat.t = -10.0


## Gatsūga matkabı (referans Fang Passing Fang): küt burunlu opak gri-lavanta tüp; sık siyah spiral taramalar shader'da akar,
## önde krem renkli tırtıklı çakra halkası titrer. Beden içinde görünmez (çağıran gizler). -Z ileri. fade: 0..1 oluşum.
func gatsuga_drill(size: float) -> Node3D:
	var root = Node3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# torna profili (z, yarıçap): arka ince kuyruk -> gövde -> küt yuvarlak burun
	var prof = [[1.5, 0.35], [1.1, 0.62], [0.6, 0.86], [0.0, 0.98], [-0.6, 1.0], [-0.95, 0.94], [-1.15, 0.78], [-1.28, 0.52], [-1.34, 0.2], [-1.35, 0.0]]
	var SEG = 24
	var L = 0.0
	var acc = [0.0]
	for i in range(1, prof.size()):
		L += Vector2(prof[i][0] - prof[i - 1][0], prof[i][1] - prof[i - 1][1]).length()
		acc.append(L)
	for i in prof.size() - 1:
		for k in SEG:
			var quad = []
			for d in [[0, 0], [1, 0], [1, 1], [0, 1]]:
				var ii = i + d[0]
				var kk = k + d[1]
				var ang = TAU * kk / SEG
				var r: float = prof[ii][1]
				quad.append([Vector3(cos(ang) * r, sin(ang) * r, prof[ii][0]), Vector2(float(kk) / SEG, acc[ii] / L)])
			for t in [0, 1, 2, 0, 2, 3]:
				st.set_uv(quad[t][1])
				st.add_vertex(quad[t][0])
	st.generate_normals()
	var mi = MeshInstance3D.new()
	mi.mesh = st.commit()
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/vfx_drill.gdshader")
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(mi)
	root.set_meta("drill_mat", m)
	# önde tırtıklı krem çakra halkası: dışa sivrilen düzensiz dikenler (her an yeniden titrer)
	var ring = Node3D.new()
	ring.position = Vector3(0, 0, -1.05)   # referans: patlama halkası tam burun kenarında
	root.add_child(ring)
	var rm = StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color(0.98, 0.95, 0.74)
	rm.cull_mode = BaseMaterial3D.CULL_DISABLED
	var rmi = MeshInstance3D.new()
	rmi.material_override = rm
	rmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.add_child(rmi)
	var rebuild = func():
		var rs = SurfaceTool.new()
		rs.begin(Mesh.PRIMITIVE_TRIANGLES)
		# kalın krem bant (burun kenarını saran) + dışa düzensiz geniş sivri patlamalar
		var n = 11
		var BAND = 24
		for k in BAND:
			var a0 = TAU * k / BAND
			var a1 = TAU * (k + 1) / BAND
			var r0 = 0.88
			var r1 = 1.12 + randf_range(-0.03, 0.06)
			var q = [Vector3(cos(a0) * r0, sin(a0) * r0, -0.05), Vector3(cos(a1) * r0, sin(a1) * r0, -0.05), Vector3(cos(a1) * r1, sin(a1) * r1, 0.3), Vector3(cos(a0) * r1, sin(a0) * r1, 0.3)]   # burun kenarını saran huni bant
			for t in [0, 1, 2, 0, 2, 3]:
				rs.add_vertex(q[t])
		for k in n:
			var am = TAU * (k + randf_range(-0.3, 0.3)) / n
			var w = TAU / n * randf_range(0.28, 0.45)
			var ro = randf_range(1.35, 1.8)
			var p0 = Vector3(cos(am - w) * 1.05, sin(am - w) * 1.05, 0.2)
			var p1 = Vector3(cos(am + w) * 1.05, sin(am + w) * 1.05, 0.2)
			var tip = Vector3(cos(am) * ro, sin(am) * ro, randf_range(0.45, 0.9))   # dışa ve geriye savrulur (yandan da görünür)
			for v in [p0, p1, tip]:
				rs.add_vertex(v)
		rmi.mesh = rs.commit()
	rebuild.call()
	var tw = ring.create_tween().set_loops()
	tw.tween_callback(rebuild)
	tw.tween_interval(0.06)
	root.scale = Vector3.ONE * size * 1.1
	return root


# ---------------------------------------------------------------- Yamanaka
func j_shintenshin(c: Node3D, t: Node3D) -> void:
	if t == null or not t is Enemy or t is Boss:
		Hud.msg("Shintenshin: sıradan bir düşmanı hedefle (boss'lar dirençli)", Color(0.8, 0.7, 1))
		return
	Sfx.play("genjutsu", t.global_position, 1.2)
	pass   # referans: görünür halka/ışın/aura yok
	# ruh bedenden çıkar: mor top hedefe uçar, oyuncunun bedeni yere çöker (anime Shintenshin)
	var cj = ClanJutsu.get_inst()
	cj._mind_orb(c, t, func(): if is_instance_valid(t): cj._mind_halo(t, 12.0))
	if c.get("model"):
		c.model.play("sit", 0.2)
	# ruh bedenden çıktı: Yamanaka'nın bedeni yerde savunmasız (hareket edemez); bedene darbe gelirse ruh geri çekilir
	var dur = 12.0
	if c is Player:
		c.input_locked = dur
		c.set_meta("shintenshin_t", t)
		t.set_meta("possessed_by", c)
	t.team = "player"
	t.target = null
	t.state = "chase"
	var a = null   # referans: ele geçirilen bedende görünür aura yok (yalnız isim etiketi mora döner)
	t.nameplate.modulate = Color(0.75, 0.6, 1.0)
	Combat.popup_text(t.global_position + Vector3.UP * 2.6, "Zihin ele geçirildi!", Color(0.8, 0.65, 1))
	get_tree().create_timer(dur).timeout.connect(func(): shintenshin_release(c, t, a))


## Ruh bedene döner (süre bitti ya da Yamanaka'nın bedenine darbe geldi)
func shintenshin_release(c: Node3D, t: Node3D, a = null) -> void:
	if a == null and is_instance_valid(t) and t.has_meta("possess_aura"):
		a = t.get_meta("possess_aura")
	if is_instance_valid(c) and c.has_meta("shintenshin_t"):
		c.remove_meta("shintenshin_t")
		if c is Player:
			c.input_locked = 0.0
			if c.get("model"):
				c.model.play("idle", 0.2)
	if is_instance_valid(t) and t.has_meta("possessed_by"):
		t.remove_meta("possessed_by")
		if not t.dead:
			t.team = "enemy"
			t.target = null
			t.nameplate.modulate = Color(1, 0.6, 0.55)
			Combat.popup_text(t.global_position + Vector3.UP * 2.6, "Kendine geldi", Color(1, 0.7, 0.6))
		if is_instance_valid(a):
			a.emitting = false
			get_tree().create_timer(1.0).timeout.connect(a.queue_free)


# ---------------------------------------------------------------- Senju (Mokuton)
func j_mokuton_spikes(c: Node3D, t: Node3D) -> void:
	var m = _mult(c)
	var d = _aim(c, t)
	d.y = 0
	d = d.normalized()
	var origin = c.global_position
	Sfx.play("earth", c.global_position, 0.9)
	_ticks(9, 0.05, func(k):
		var p = _ground(origin + d * (2.0 + k * 1.9))
		var sp = MeshInstance3D.new()
		var b = MB.new()
		for s in 4:
			b.add("cone", Vector3(randf_range(-0.7, 0.7), 1.6, randf_range(-0.7, 0.7)), Vector3(0.7, 3.2 + randf() * 1.6, 0.7), Color(0.55, 0.4, 0.24), Vector3(randf_range(-20, 20), 0, randf_range(-20, 20)), 6)
		sp.mesh = b.build(Props.toon())
		get_tree().current_scene.add_child(sp)
		sp.global_position = p - Vector3(0, 4, 0)
		var tw = sp.create_tween()
		tw.tween_property(sp, "global_position:y", p.y, 0.12)
		tw.tween_interval(1.6)
		tw.tween_property(sp, "global_position:y", p.y - 4.5, 0.5)
		tw.tween_callback(sp.queue_free)
		FX.dust(p, 0.8)
		for h in Combat.hit_sphere(c, p + Vector3.UP, 1.7, {"dmg": 10.0 * m, "element": "mokuton", "knock": 3.0, "launch": 8.0, "kind": "heavy", "hitstop": 0.03}):
			if h.has_method("apply_status"):
				h.apply_status("bind", 1.0))


func j_mokuton_wall(c: Node3D, _t: Node3D) -> void:
	var center = _ground(c.global_position)
	var wall = StaticBody3D.new()
	var b = MB.new()
	for k in 12:
		var a = k * TAU / 12.0
		var off = Vector3(cos(a), 0, sin(a)) * 4.2
		b.add("box", off + Vector3(0, 2.6, 0), Vector3(1.3, 5.2, 1.0), Color(0.5, 0.36, 0.22).darkened(randf() * 0.15), Vector3(0, -rad_to_deg(a), 0))
		var cs = CollisionShape3D.new()
		var sh = BoxShape3D.new()
		sh.size = Vector3(1.6, 5.2, 1.0)
		cs.shape = sh
		cs.transform = Transform3D(Basis(Vector3.UP, -a), off + Vector3(0, 2.6, 0))
		wall.add_child(cs)
	b.add("hemi", Vector3(0, 5.0, 0), Vector3(9.5, 4.0, 9.5), Color(0.47, 0.33, 0.2), Vector3.ZERO, 14)
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(Props.toon())
	wall.add_child(mi)
	get_tree().current_scene.add_child(wall)
	_element_wall(wall, "mokuton", c, Vector3(0, 2.6, 0), Vector3(5, 2.6, 5), 60.0 * _mult(c))
	wall.global_position = center - Vector3(0, 7.5, 0)
	var tw = wall.create_tween()
	tw.tween_property(wall, "global_position:y", center.y, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(9.0)
	tw.tween_property(wall, "global_position:y", center.y - 7.5, 0.6)
	tw.tween_callback(wall.queue_free)
	FX.dust(center, 2.5)
	Sfx.play("earth", center, 0.7)
	if Game.world:
		Game.world.env.add_shake(0.5)


# ---------------------------------------------------------------- Yuki (Hyoton)
func j_hyoton_senbon(c: Node3D, t: Node3D) -> void:
	var m = _mult(c)
	var dir = _aim(c, t)
	Sfx.play("kunai", c.global_position, 1.6)
	VFX.star(_hand(c), Color(0.8, 0.95, 1.0), 2.0, 0.15)
	FX.burst(_hand(c), {"amount": 24, "life": 0.5, "size": 0.25, "vmin": 2, "vmax": 6, "colors": [Color(0.95, 1, 1), Color(0.6, 0.85, 1, 0)]})
	for i in 16:
		var d = dir.rotated(Vector3.UP, deg_to_rad(-30 + i * 4)) + Vector3.UP * randf_range(-0.05, 0.1)
		var pr = Projectile.new()
		pr.shooter = c
		pr.vel = d.normalized() * 50.0
		pr.radius = 0.25
		pr.life = 1.4
		pr.info = {"dmg": 4.0 * m, "knock": 1.0, "kind": "light", "hitstop": 0.01, "element": "hyoton"}
		var mi = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 0.0; cm.bottom_radius = 0.09; cm.height = 1.3
		cm.material = JutsuEngine.glow_mat(Color(0.75, 0.93, 1.0), 1.0)
		mi.mesh = cm
		mi.rotation.x = -PI * 0.5
		pr.add_child(mi)
		VFX.trail(pr, 0.18, Color(1, 1, 1), Color(0.7, 0.9, 1.0), Color(0.5, 0.8, 1.0, 0.0), 10, 0.5)
		pr.on_hit = func(pos: Vector3, tg: Node3D) -> void:
			if tg and tg.has_method("apply_status"):
				tg.apply_status("slow", 2.0)
				tg.apply_status("chilled", 3.0)
			VFX.star(pos, Color(0.8, 0.95, 1.0), 1.0, 0.12)
			FX.burst(pos, {"amount": 5, "life": 0.3, "size": 0.4, "vmin": 2, "vmax": 4, "colors": [Color(0.9, 0.97, 1, 1), Color(0.7, 0.9, 1, 0)]})
		get_tree().current_scene.add_child(pr)
		pr.global_position = _hand(c)


func j_hyoton_spears(c: Node3D, t: Node3D) -> void:
	if not (c is Player) and not ClanMech.water_near(c.global_position):   # oyuncuyla aynı: yakında su şart
		return
	var m = _mult(c)
	var center = _ground(_aim_ground(c, t, 8.0))
	Sfx.play("clink", center, 0.6)
	# önce zemin donar (düzensiz buz lekesi yayılır), sonra hedefin çevresinden içe eğik dev kristaller fışkırıp onu içine hapseder
	var fr = IceArt.frost(4.2)
	get_tree().current_scene.add_child(fr)
	fr.global_position = center + Vector3.UP * 0.04
	fr.scale = Vector3.ONE * 0.1
	var tf = fr.create_tween()
	tf.tween_property(fr, "scale", Vector3.ONE, 0.2).set_ease(Tween.EASE_OUT)
	tf.tween_interval(2.7)
	tf.tween_property(fr, "transparency", 1.0, 0.6)
	tf.tween_callback(fr.queue_free)
	var ice = IceArt.encase(1.6, 3.4)
	get_tree().current_scene.add_child(ice)
	ice.global_position = center
	ice.rotation.y = randf() * TAU
	ice.scale = Vector3(0.7, 0.02, 0.7)
	var tw = ice.create_tween()
	tw.tween_interval(0.12)
	tw.tween_property(ice, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.4)
	tw.tween_callback(func(): IceArt.shatter(get_tree(), center, 1.6, 18))
	tw.tween_callback(ice.queue_free)
	VFX.fog(center + Vector3.UP * 0.4, {"amount": 14, "life": 1.6, "size": 1.8, "radius": 2.2, "vmin": 0.3, "vmax": 1.2, "dir": Vector3.UP, "spread": 80.0,
		"colors": [Color(0.95, 0.98, 1.0, 0.0), Color(0.9, 0.96, 1.0, 0.5), Color(0.88, 0.95, 1.0, 0.0)]})
	# önce dondur (donmuş hedef blok yapamaz), sonra hasar
	for f in get_tree().get_nodes_in_group("fighters"):
		if Combat.hostile(c, f) and not f.is_dead() and Combat.capsule_hit(center + Vector3.UP, f, 2.6) and f.has_method("apply_status"):
			f.apply_status("stun", 2.5)
	for h in Combat.hit_sphere(c, center + Vector3.UP, 2.6, {"dmg": 22.0 * m, "knock": 0.0, "kind": "light", "element": "hyoton", "hitstop": 0.06}):
		Combat.popup_text(h.global_position + Vector3.UP * 2.4, "DONDU!", Color(0.7, 0.9, 1))
	FX.burst(center + Vector3.UP, {"amount": 30, "life": 0.6, "tex": FX.tex_spark, "size": 0.5, "vmin": 5, "vmax": 12, "colors": [Color(1, 1, 1, 1), Color(0.7, 0.9, 1, 0)]})


func j_bone_bullets(c: Node3D, t: Node3D) -> void:
	var m = _mult(c)
	_ticks(8, 0.07, func(_i):
		if not is_instance_valid(c):
			return
		var pr = Projectile.new()
		pr.shooter = c
		pr.vel = _aim(c, t).rotated(Vector3.UP, randf_range(-0.04, 0.04)) * 48.0
		pr.radius = 0.25
		pr.homing = t
		pr.homing_turn = 1.5
		pr.info = {"dmg": 6.0 * m, "knock": 2.0, "kind": "light", "hitstop": 0.02}
		var mi = MeshInstance3D.new()
		var b = MB.new()
		# referans (Teshi Sendan karesi): iki ucu şişkin, yuvarlak beyaz parmak kemiği boğumu
		b.add("cyl", Vector3.ZERO, Vector3(0.2, 0.42, 0.2), Color(0.98, 0.97, 0.94), Vector3(90, 0, 0), 10)
		b.add("sphere", Vector3(0, 0, -0.24), Vector3(0.3, 0.3, 0.26), Color(0.98, 0.97, 0.94), Vector3.ZERO, 10)
		b.add("sphere", Vector3(0, 0, 0.24), Vector3(0.3, 0.3, 0.26), Color(0.95, 0.94, 0.9), Vector3.ZERO, 10)
		mi.mesh = b.build(Props.toon())
		pr.add_child(mi)
		pr.spin = Vector3(0, 0, 25)
		VFX.trail(pr, 0.22, Color(1, 1, 1), Color(0.95, 0.92, 0.8), Color(0.8, 0.75, 0.6, 0.0), 10)
		pr.on_hit = func(pos: Vector3, _tg: Node3D) -> void:
			FX.hit_spark(pos, Color(0.95, 0.93, 0.85), 1.2)
			FX.burst(pos, {"amount": 10, "life": 0.5, "size": 0.25, "vmin": 3, "vmax": 7, "add": false, "gravity": Vector3(0, -12, 0), "colors": [Color(0.97, 0.95, 0.88), Color(0.9, 0.88, 0.8, 0)]})
		get_tree().current_scene.add_child(pr)
		pr.global_position = _hand(c)
		FX.burst(_hand(c), {"amount": 6, "life": 0.25, "size": 0.3, "vmin": 1, "vmax": 3, "colors": [Color(1, 1, 1), Color(0.9, 0.85, 0.7, 0)]})
		Sfx.play("kunai", c.global_position, 0.8, 0.6))


func j_bone_armor(c: Node3D, _t: Node3D) -> void:
	var b = MB.new()
	for i in 14:
		var a = randf() * TAU
		var y = randf_range(0.4, 1.6)
		var dir = Vector3(cos(a), 0, sin(a))
		b.add_xf("cone", Transform3D(Basis(Quaternion(Vector3.UP, (dir + Vector3.UP * 0.4).normalized())).scaled(Vector3(0.12, 0.45, 0.12)), dir * 0.32 + Vector3(0, y, 0)), Color(0.96, 0.94, 0.86), 5)
	var spikes = MeshInstance3D.new()
	spikes.mesh = b.build(Props.toon())
	c.add_child(spikes)
	Sfx.play("clink", c.global_position, 0.5)
	if c is Player:
		Buffs.add("bone_armor", 20.0, {"armor": 0.75, "melee": 1.07})
	get_tree().create_timer(20.0).timeout.connect(func():
		if is_instance_valid(spikes):
			spikes.queue_free())


# ---------------------------------------------------------------- Uzumaki
## Uzumaki chakra zinciri (referans: Kongō Fūsa / Kinbaku kareleri): birbirine GEÇMİŞ oval halkalar — her halka bir öncekine
## 90° dönük ve üstüne biner (aralarında boşluk yok); soluk sarı-altın, hafif ışıldayan chakra. a'dan b'ye, ortası sag kadar sarkar.
func _chain_mat() -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(0.84, 0.85, 0.6)    # referans: soluk zeytin-sarısı chakra
	m.emission_enabled = true
	m.emission = Color(0.78, 0.84, 0.5)
	m.emission_energy_multiplier = 0.45
	m.roughness = 0.5
	return m


func _chain_line(parent: Node3D, a: Vector3, b: Vector3, sag := 0.4, grow := 0.25, mat: Material = null, spiky := false) -> void:
	var mt = mat if mat else _chain_mat()
	var link_len = 0.27  # oval halkanın boyu (referans: el büyüklüğü)
	var step = 0.18      # adım < boy: halkalar birbirine geçer
	var L = a.distance_to(b)
	var n = maxi(2, int(L / step))
	var tm = TorusMesh.new()
	tm.inner_radius = 0.055
	tm.outer_radius = 0.092
	tm.rings = 12
	tm.ring_segments = 8
	var prev = a
	for j in n + 1:
		var u = float(j) / n
		var p = a.lerp(b, u) + Vector3.DOWN * sin(u * PI) * sag
		var u2 = minf(1.0, u + 0.01)
		var d = (a.lerp(b, u2) + Vector3.DOWN * sin(u2 * PI) * sag) - p
		if d.length() < 0.0001:
			d = b - a
		d = d.normalized()
		var n1 = d.cross(Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT).normalized()
		var axis = n1 if j % 2 == 0 else d.cross(n1).normalized()   # halka ekseni sırayla 90° döner
		var xb = axis.cross(d).normalized()
		var link = MeshInstance3D.new()
		link.mesh = tm
		link.material_override = mt
		link.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(link)
		var basis = Basis(xb, axis, d) * Basis.from_scale(Vector3(1.0, 1.0, link_len / 0.184))   # yerel Z boyunca uzun oval
		if spiky and j % 2 == 0:   # Karin'in zincirleri: halkada iki yana sivri diken
			for sgn in [-1.0, 1.0]:
				var sp = MeshInstance3D.new()
				var scm = CylinderMesh.new()
				scm.top_radius = 0.0; scm.bottom_radius = 0.03; scm.height = 0.12; scm.radial_segments = 5
				sp.mesh = scm
				sp.material_override = mt
				link.add_child(sp)
				sp.position = Vector3(sgn * 0.11, 0, 0)
				sp.rotation = Vector3(0, 0, -sgn * PI * 0.5)
		link.global_transform = Transform3D(basis * Basis.from_scale(Vector3.ONE * 0.01), p)
		var tw = link.create_tween()
		tw.tween_interval(u * grow)
		tw.tween_method(func(x: float):
			if is_instance_valid(link):
				link.global_transform = Transform3D(basis * Basis.from_scale(Vector3.ONE * x), p), 0.01, 1.0, 0.06)


func j_chakra_chains(c: Node3D, t: Node3D) -> void:
	var m = _mult(c)
	if t == null or c.global_position.distance_to(t.global_position) > 28.0:
		Hud.msg("Chakra zincirleri: hedef çok uzak", Color(1, 0.85, 0.4))
		return
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	var center = _ground(t.global_position)
	var back = c.global_position + Vector3.UP * 1.3 - (c.face_dir() if c.has_method("face_dir") else Vector3.FORWARD) * 0.3
	var cm = _chain_mat()
	# kanon: birkaç zincir kullanıcının sırtından çıkar, ötekiler yere dalıp hedefin çevresinden fışkırır; hepsi hedefe dolanır
	for k in 5:
		var a = k * TAU / 5.0 + 0.4
		var base = back + Vector3(cos(a), sin(a) * 0.6, 0) * 0.3 if k < 3 else center + Vector3(cos(a), 0, sin(a)) * 3.5
		var top = t.global_position + Vector3.UP * (0.8 + k * 0.25)
		_chain_line(root, base, top, -0.35 if k < 3 else 0.2, 0.25, cm)
	# gövdeye dolanan zincir halkaları (referans: Dokuz Kuyruk'u saran zincirler)
	for wv in 3:
		var hy = 0.7 + wv * 0.35
		var R = 0.42
		var a0 = wv * 1.3
		for seg in 6:
			var p1 = t.global_position + Vector3(cos(a0 + seg * TAU / 6.0) * R, hy + seg * 0.02, sin(a0 + seg * TAU / 6.0) * R)
			var p2 = t.global_position + Vector3(cos(a0 + (seg + 1) * TAU / 6.0) * R, hy + (seg + 1) * 0.02, sin(a0 + (seg + 1) * TAU / 6.0) * R)
			_chain_line(root, p1, p2, 0.0, 0.0, cm)
	VFX.shockwave(t.global_position + Vector3.UP * 1.2, Color(1, 0.8, 0.3), 3.0, 0.3, false)
	FX.aura(t, Color(1.0, 0.8, 0.3), 0.9, Vector3(0, 1.0, 0), 5.0)
	Sfx.play("clink", center, 0.7)
	if t.has_method("apply_status"):
		t.apply_status("bind", 5.0)
	Combat.hit_sphere(c, t.global_position + Vector3.UP, 1.4, {"dmg": 12.0 * m, "knock": 0.0, "kind": "light"})
	Combat.popup_text(t.global_position + Vector3.UP * 2.6, "Mühürlendi!", Color(1, 0.85, 0.4))
	get_tree().create_timer(5.0).timeout.connect(root.queue_free)


# ---------------------------------------------------------------- Hozuki
## Hōzuki su bedeni görünüşü: tenin üstünde yarı saydam akan su (kapsül değil) + süzülen damlalar. dur sn sonra çözülür.
## Kendiliğinden sıvılaşmada kısa (darbe yeri suya döner), Suika no Jutsu'da uzun. Oyuncu ve düşman aynı.
func water_body(c: Node3D, dur: float, drops := true) -> void:
	var mm = c.get("model")
	if mm == null or not is_instance_valid(mm):
		return
	var wm = VFX.mat_water(Color(0.45, 0.68, 0.92), Color(0.72, 0.88, 1.0), Color(0.97, 1.0, 1.0), Vector3.DOWN, 0.78, 0.9, 0.03)
	var meshes = mm.find_children("*", "MeshInstance3D", true, false)
	for mi in meshes:
		(mi as MeshInstance3D).material_overlay = wm
	var n = maxi(1, int(dur / 0.5))
	_ticks(n, minf(0.5, dur), func(_i):
		if drops and is_instance_valid(c):
			WaterArt.drops(c.global_position + Vector3(randf_range(-0.25, 0.25), randf_range(0.8, 1.7), randf_range(-0.25, 0.25)), 2, 0.4, 1.0, Vector3.DOWN, 0.3), func():
		for mi in meshes:
			if is_instance_valid(mi) and (mi as MeshInstance3D).material_overlay == wm:
				(mi as MeshInstance3D).material_overlay = null)


func j_suika(c: Node3D, _t: Node3D) -> void:
	# referans (Suika karesi): bedenin KENDİSİ suya döner. Oyuncu: Buff; düşman: aynı kural meta "suika_until" (Enemy.take_hit)
	if c is Player:
		Buffs.add("suika", 15.0, {"_desc": "Hafif darbeler içinden geçer (chakra yer), ağır darbe yarı hasar; Raiton 2x hasar ve bedeni dağıtır"})
		Hud.msg("Suika no Jutsu: 15 sn hafif darbeler içinden geçer (chakra harcar). Raiton'a karşı çok zayıf!", Color(0.5, 0.75, 1))
	else:
		c.set_meta("suika_until", Time.get_ticks_msec() / 1000.0 + 15.0)
	var a = FX.aura(c, Color(0.35, 0.65, 1.0), 1.0, Vector3(0, 0.9, 0), 0.0)
	water_body(c, 15.0)
	get_tree().create_timer(15.0).timeout.connect(func():
		if is_instance_valid(a):
			a.emitting = false
			get_tree().create_timer(1.0).timeout.connect(a.queue_free))
	Sfx.play("water", c.global_position, 1.2)


func j_water_gun(c: Node3D, t: Node3D) -> void:
	var m = _mult(c)
	var pr = Projectile.new()
	pr.shooter = c
	pr.vel = _aim(c, t) * 42.0   # 70 m/s'de mermi görünmüyordu
	pr.radius = 0.5
	pr.info = {"dmg": 14.0 * m, "knock": 5.0, "kind": "light", "element": "suiton", "hitstop": 0.03}
	pr.add_child(VFX.water_ball(1.3))
	# parmaktan fışkıran mavi su + mermiden kopan mavi damlalar
	VFX.puffs(_hand(c), {"amount": 10, "life": 0.35, "size": 0.35, "radius": 0.2, "vmin": 4.0, "vmax": 9.0, "dir": _aim(c, t), "spread": 20.0, "gravity": Vector3(0, -14, 0),
		"glow": 1.05, "water": true, "outline_col": Color(0.05, 0.25, 0.7), "outline": 0.045, "colors": [Color(0.75, 0.92, 1.0, 1), Color(0.3, 0.62, 1.0, 1), Color(0.2, 0.5, 0.95, 0.0)]})
	pr.on_tick = func(p: Projectile, _dt: float) -> void:
		if randf() < 0.6:
			VFX.puffs(p.global_position, {"amount": 2, "life": 0.4, "size": 0.22, "radius": 0.15, "vmin": 0.5, "vmax": 2.0, "dir": Vector3.UP, "spread": 70.0, "gravity": Vector3(0, -16, 0),
				"glow": 1.05, "water": true, "outline_col": Color(0.05, 0.25, 0.7), "outline": 0.045, "colors": [Color(0.75, 0.92, 1.0, 1), Color(0.3, 0.62, 1.0, 1), Color(0.2, 0.5, 0.95, 0.0)]})
	VFX.trail(pr, 0.6, Color(0.9, 0.97, 1.0), Color(0.3, 0.6, 1.0), Color(0.1, 0.35, 0.9, 0.0), 14)
	VFX.shockwave(_hand(c), Color(0.6, 0.85, 1.0), 2.5, 0.25, false, _aim(c, t))
	Projectile.trail(pr, [Color(0.85, 0.95, 1, 0.9), Color(0.3, 0.6, 1, 0)], 0.35, 30, 0.25, FX.tex_smoke, false)
	pr.on_hit = func(pos: Vector3, _tg: Node3D) -> void:
		VFX.splash(pos, 1.2)
	get_tree().current_scene.add_child(pr)
	pr.global_position = _hand(c)
	Sfx.play("water", c.global_position, 1.8, 0.6)


# ---------------------------------------------------------------- Jinchuriki: kuyruklu canavar bombası
func beast_bomb(c: Node3D, t: Node3D) -> void:
	var m = _mult(c)
	var pr = Projectile.new()
	pr.shooter = c
	pr.vel = _aim(c, t) * 30.0
	pr.radius = 1.8
	pr.life = 3.0
	pr.homing = t
	pr.homing_turn = 1.0
	pr.info = {"dmg": 60.0 * m, "knock": 25.0, "launch": 10.0, "kind": "heavy", "hitstop": 0.15, "element": "raiton"}
	pr.add_child(Projectile.energy_mesh(Color(0.35, 0.3, 0.9), Color(0.05, 0.05, 0.25), 3.2, 12.0, 0.0, 2.0))
	var l = OmniLight3D.new()
	l.light_color = Color(0.5, 0.5, 1.0); l.light_energy = 1.8; l.omni_range = 12.0
	pr.add_child(l)
	pr.on_hit = func(pos: Vector3, _tg: Node3D) -> void:
		FX.explosion(pos, 2.4, Color(0.45, 0.45, 1.0))
		Combat.hit_sphere(c, pos, 8.0, {"dmg": 30.0 * m, "knock": 22.0, "launch": 8.0, "kind": "heavy"}, pr.hit_list)
	get_tree().current_scene.add_child(pr)
	pr.global_position = c.global_position + Vector3.UP * 2.0 + c.face_dir() * 1.5
	Sfx.play("roar", c.global_position, 1.2)


# ================================================================== İMZA JUTSULAR (animedeki koreografiyle)
func _jd(id: String) -> Dictionary:
	var d: Dictionary = Data.jutsu.get(id, {"tier": 3})
	if not d.has("id"):
		d = d.duplicate()
		d["id"] = id
	return d


func _inf(c: Node3D, id: String, mul: float, extra := {}) -> Dictionary:
	return JutsuEngine.info(c, _jd(id), mul, extra)


func _tg(c: Node3D, t: Node3D, rng: float) -> Node3D:
	return JutsuEngine._target_in_range(c, t, rng)


## Kirin: gökte fırtına bulutu toplanır, sonra şimşek ejderhası kilitli hedefe iner
func j_kirin(c: Node3D, t: Node3D) -> void:
	var tg = _tg(c, t, 45.0)
	var pos: Vector3 = tg.global_position if tg else _ground(_aim_ground(c, t, 20.0, 40.0))
	var sky = pos + Vector3.UP * 70.0 - _aim_flat(c, t) * 10.0   # animede fırtına bulutları gökyüzünde; ejder oradan iner
	var col = Color(0.55, 0.75, 1.0)
	Sfx.play("thunder", sky, 0.6)
	if Game.world:
		Game.world.env.set_tint(Color(0.05, 0.05, 0.15, 0.35))
	# 1) bulut toplanması: dönen koyu topaklar + içinde çakan şimşekler
	VFX.puffs(sky, {"amount": 70, "life": 3.2, "size": 16.0, "radius": 30.0, "vmin": 0.5, "vmax": 3.0, "gravity": Vector3.ZERO, "spin": 10.0, "tangent": 6.0,
		"outline_col": Color(0.1, 0.1, 0.16), "shade": 0.4, "explosive": 0.4, "outline": 0.03, "rough": 0.18,
		"colors": [Color(0.15, 0.15, 0.22, 0), Color(0.16, 0.16, 0.24, 1), Color(0.22, 0.22, 0.32, 1), Color(0.25, 0.25, 0.35, 0)]})
	for k in 6:
		get_tree().create_timer(0.2 + k * 0.18).timeout.connect(func():
			var a = sky + Vector3(randf_range(-25, 25), randf_range(-3, 3), randf_range(-25, 25))
			VFX.bolt(a, a + Vector3(randf_range(-18, 18), randf_range(-8, 0), randf_range(-18, 18)), col, 0.5, 0.18, 3)
			if Game.world: Game.world.env.screen_flash(0.04))
	# 2) şimşek ejderhası iner
	get_tree().create_timer(1.4).timeout.connect(func():
		if tg and is_instance_valid(tg):
			pos = tg.global_position
		var head = Node3D.new()
		get_tree().current_scene.add_child(head)
		head.global_position = sky
		var hm = VFX.mat_spiral(Color(1, 1, 1), col, 8.0, 4.0, 16.0, 2.4, Vector3(0, 0, 1))
		var dh = VfxSerpent.dragon_head(hm, 5.5, Color(1, 1, 1))
		head.add_child(dh)
		var body = VfxSerpent.new()
		body.style = "lightning"
		body.col = col
		body.seed_id = "kirin"
		body.head = head
		body.count = 26
		body.spacing = 2.6
		body.radius = 3.4
		body.mat = hm
		get_tree().current_scene.add_child(body)
		var arcs = Arcs.new()
		arcs.color = col
		arcs.radius = 8.0
		arcs.count = 14
		arcs.width = 0.12
		head.add_child(arcs)
		var tw = head.create_tween()
		var mid = sky.lerp(pos, 0.5) + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
		tw.tween_method(func(k: float):
			var a = sky.lerp(mid, k); var b2 = mid.lerp(pos, k)
			var p = a.lerp(b2, k)
			var nxt = sky.lerp(mid, minf(1.0, k + 0.02)).lerp(mid.lerp(pos, minf(1.0, k + 0.02)), minf(1.0, k + 0.02))
			head.global_position = p
			if nxt.distance_to(p) > 0.01:
				head.look_at(nxt, Vector3.UP if absf((nxt - p).normalized().y) < 0.98 else Vector3.RIGHT), 0.0, 1.0, 0.8)
		tw.tween_callback(func():
			VFX.bolt(sky, pos, Color(0.85, 0.95, 1.0), 1.4, 0.4, 6)
			VFX.star(pos + Vector3.UP * 2.0, Color(0.75, 0.9, 1.0), 16.0, 0.35)
			# halka yok: göz alan çakma, her yöne saçılan kıvılcım, yerden kalkan toz
			FX.burst(pos + Vector3.UP * 2.0, {"amount": 160, "life": 0.7, "tex": FX.tex_spark, "size": 3.0, "vmin": 20.0, "vmax": 45.0, "spread": 180.0, "damp": 2.5,
				"colors": [Color(1, 1, 1, 1), col.lightened(0.4), Color(col.r, col.g, col.b, 0)]})
			WindFX.blast(pos + Vector3.UP * 0.5, 16.0, 20, Color(0.85, 0.95, 1.0, 0.9))
			VFX.cracks(pos, 14.0)
			VFX.debris(pos, Color(0.45, 0.38, 0.3), 30, 22.0, 0.6)
			VFX.smoke_ring(pos, 6.0, Color(0.32, 0.3, 0.32))
			VFX.screen_lines(0.8, 1.0, Color(0.85, 0.95, 1.0))
			FX.light(pos, col, 14.0, 40.0, 0.8)
			Combat.hit_sphere(c, pos + Vector3.UP, 7.0, _inf(c, "kirin", 3.0, {"stun": 2.0, "knock": 18.0, "launch": 8.0}))
			Sfx.play("thunder", pos, 1.0)
			Sfx.play("boom", pos, 0.6)
			if Game.world:
				Game.world.env.add_shake(2.0)
				Game.world.env.screen_flash(0.6)
				Game.world.env.set_tint(Color(0, 0, 0, 0))
			head.queue_free()))


## Gōryūka: bulutlar arasından süzülen birden çok ateş ejderhası başı
func j_katon_goryuka_no_jutsu(c: Node3D, t: Node3D) -> void:
	var d = _jd("katon_goryuka_no_jutsu")
	var dir = _aim(c, t)
	Sfx.play("fire", c.global_position, 0.8)
	VFX.puffs(_mouth(c) + dir, {"amount": 30, "life": 0.5, "size": 1.6, "vmin": 8, "vmax": 16, "dir": dir, "spread": 30.0, "glow": 1.1, "hot": 0.3,
		"outline_col": Color(0.3, 0.04, 0.02), "colors": [Color(1, 0.82, 0.22, 1), Color(1, 0.55, 0.08, 1), Color(0.95, 0.3, 0.04, 0.9), Color(0.7, 0.1, 0.03, 0)]})
	for i in 4:
		get_tree().create_timer(i * 0.22).timeout.connect(func():
			if not is_instance_valid(c):
				return
			var dd = (dir + Vector3(randf_range(-0.25, 0.25), 0.35 + randf_range(0, 0.3), randf_range(-0.25, 0.25))).normalized()
			JutsuEngine.spawn_projectile(c, d, _mouth(c) + dir, dd, "dragon", 2.2, 20.0, _inf(c, "katon_goryuka_no_jutsu", 0.45), t))
	if c is Player:
		VFX.screen_lines(0.5, 0.5, Color(1, 0.8, 0.5))


## Suirō: hedefi su küresine hapseder (iç basınç hasarı)
func j_suiro_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tg = _tg(c, t, 18.0)
	if tg == null:
		if c is Player: Hud.msg("Hapsedilecek hedef yakında değil.", Color(0.8, 0.8, 0.8))
		return
	Sfx.play("water", tg.global_position)
	VFX.splash(tg.global_position, 1.6)
	var sph = VFX._mi(VFX._sphere(0.5, 28, 14), VFX.mat_water(Color(0.05, 0.3, 0.8), Color(0.25, 0.6, 1.0), Color(0.75, 0.93, 1.0), Vector3.UP, 0.6, 0.7, 0.14))
	tg.add_child(sph)
	sph.position = Vector3(0, tg.height * 0.5, 0)
	sph.scale = Vector3.ONE * 0.2
	var r = maxf(3.4, tg.height * 1.9)
	sph.create_tween().tween_property(sph, "scale", Vector3.ONE * r, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var dur = 5.0
	tg.apply_status("bind", dur)
	var inf = _inf(c, "suiro_no_jutsu", 0.12, {"knock": 0.0, "launch": 0.0, "kind": "light", "hitstop": 0.0, "element": "suiton"})
	_ticks(int(dur / 0.5), 0.5, func(_i):
		if is_instance_valid(tg) and not tg.is_dead():
			tg.take_hit(inf.merged({"attacker": c, "dir": Vector3.ZERO}, true))
			FX.burst(tg.global_position + Vector3.UP * tg.height * 0.6, {"amount": 4, "life": 0.6, "tex": FX.tex_soft, "add": true, "size": 0.25, "vmin": 0.5, "vmax": 1.5,
				"dir": Vector3.UP, "spread": 20.0, "colors": [Color(1, 1, 1, 0.9), Color(0.8, 0.95, 1, 0)]}), func():
		if is_instance_valid(sph):
			VFX.splash(sph.global_position, 2.0)
			sph.queue_free())


## Daibakufu: dev şelale dalgası — çevreyi su basar, önündeki her şeyi süpürür
func j_suiton_daibakufu_no_jutsu(c: Node3D, t: Node3D) -> void:
	var dir = _aim_flat(c, t)
	var start = _ground(c.global_position + dir * 14.0)   # sütun oyuncu kamerasını yutmasın
	Sfx.play("water", start, 0.6)
	VFX.splash(start, 4.0)
	var wm = VFX.mat_water(Color(0.04, 0.25, 0.75), Color(0.18, 0.52, 0.98), Color(0.65, 0.9, 1.0), Vector3.UP, 0.92, 0.9, 0.15)
	# yükselen dev su sütunu (silindir mesh yok): yerden fışkıran mavi su topakları + tepede beyaz köpük, sonra çöker
	_ticks(12, 0.06, func(i):
		WaterArt.puffs(start + Vector3.UP * (1.0 + i * 1.6), {"amount": 14, "life": 0.7, "size": 3.0, "radius": 4.5, "vmin": 10.0, "vmax": 18.0, "dir": Vector3.UP, "spread": 18.0,
			"gravity": Vector3(0, -16, 0), "damp": 0.8, "glow": 1.06, "hot": 0.3, "water": true, "outline_col": Color(0.04, 0.2, 0.62), "outline": 0.045, "rough": 0.14, "shade": 0.3,
			"colors": [Color(0.55, 0.82, 1.0, 1), Color(0.22, 0.55, 0.98, 1), Color(0.14, 0.42, 0.9, 0.9), Color(0.1, 0.35, 0.85, 0.0)]})
		if i > 8:
			WaterArt.puffs(start + Vector3.UP * 20.0, {"amount": 10, "life": 0.6, "size": 2.0, "radius": 5.0, "vmin": 3.0, "vmax": 7.0, "spread": 120.0, "gravity": Vector3(0, -16, 0),
				"glow": 1.05, "water": true, "outline_col": Color(0.3, 0.55, 0.9), "outline": 0.03, "colors": [Color(0.95, 0.99, 1, 1), Color(0.75, 0.9, 1, 0.9), Color(0.6, 0.82, 1, 0)]}), Callable())
	# ardından yıkıcı dev dalga
	get_tree().create_timer(0.8).timeout.connect(func():
		if not is_instance_valid(c):
			return
		var d = _jd("suiton_daibakufu_no_jutsu").duplicate()
		d["tier"] = 5
		JutsuEngine._wave(c, d, t)
		JutsuEngine._wave_ring(start, 70.0, wm, 1.4)
		Combat.hit_sphere(c, start + dir * 10.0 + Vector3.UP, 20.0, _inf(c, "suiton_daibakufu_no_jutsu", 1.4, {"knock": 22.0, "launch": 6.0}))
		if Game.world: Game.world.env.add_shake(1.2))
	if c is Player:
		VFX.screen_lines(0.6, 0.5, Color(0.7, 0.9, 1.0))


## Kirigakure: yoğun sis — görüş düşer, düşmanlar seni kaybeder
func j_kirigakure_no_jutsu(c: Node3D, _t: Node3D) -> void:
	var pos = c.global_position
	var r = 20.0
	var dur = 12.0
	Sfx.play("water", pos, 0.5)
	for k in 5:
		get_tree().create_timer(k * 0.25).timeout.connect(func():
			FX.burst(pos + Vector3.UP * 1.5, {"amount": 22, "life": dur * 0.7, "size": 9.0, "radius": r, "vmin": 0.2, "vmax": 1.0, "gravity": Vector3.ZERO, "spin": 6.0,
				"explosive": 0.2, "tex": FX.tex_soft, "cel": false,
				"colors": [Color(0.9, 0.93, 0.97, 0), Color(0.88, 0.91, 0.96, 0.45), Color(0.88, 0.91, 0.96, 0.45), Color(0.9, 0.93, 0.97, 0)],
				"scale_curve": [[0.0, 0.3], [0.2, 1.0], [1.0, 1.1]]}))
	VFX.puffs(pos, {"amount": 26, "life": 1.2, "size": 2.2, "radius": 3.0, "vmin": 6, "vmax": 12, "gravity": Vector3.ZERO, "damp": 6.0,
		"outline_col": Color(0.55, 0.6, 0.7), "shade": 0.2, "colors": [Color(0.95, 0.97, 1, 1), Color(0.86, 0.9, 0.96, 1), Color(0.86, 0.9, 0.96, 0)]})
	if Game.world:
		Game.world.env.set_tint(Color(0.85, 0.88, 0.95, 0.35))
		get_tree().create_timer(dur).timeout.connect(func(): Game.world.env.set_tint(Color(0, 0, 0, 0)))
	for f in get_tree().get_nodes_in_group("fighters"):
		if Combat.hostile(c, f) and f.global_position.distance_to(pos) < r * 1.5 and f.has_method("lose_target"):
			f.lose_target(dur * 0.7)
	if c is Player:
		Buffs.add("kirigakure", dur, {"stealth": 1.0})


## Doryūdan: arkada yerden toprak ejderhası yükselir, ağzından çamur mermileri tükürür
func j_doton_doryudan(c: Node3D, t: Node3D) -> void:
	var d = _jd("doton_doryudan")
	var fd = _aim_flat(c, t)
	var base = _ground(c.global_position - fd * 3.0 + fd.cross(Vector3.UP) * 1.5)
	var mud = Props.toon_color(Color(0.42, 0.32, 0.22))
	var head = Node3D.new()
	get_tree().current_scene.add_child(head)
	head.global_position = base - Vector3.UP * 3.0
	head.add_child(VfxSerpent.dragon_head(mud, 2.4, Color(1, 0.85, 0.3)))
	var body = VfxSerpent.new()
	body.style = "earth"
	body.seed_id = "doton_doryudan"
	body.head = head
	body.count = 10
	body.spacing = 1.3
	body.radius = 1.6
	body.mat = mud
	body.fin_mat = Props.toon_color(Color(0.35, 0.27, 0.19))
	get_tree().current_scene.add_child(body)
	VFX.cracks(base, 6.0)
	VFX.debris(base, Color(0.45, 0.35, 0.25), 20, 14.0, 0.5)
	FX.dust(base, 2.5)
	Sfx.play("earth", base)
	var top = base + Vector3.UP * 7.0 + fd * 1.5
	var tw = head.create_tween()
	tw.tween_method(func(k: float):
		var p = (base - Vector3.UP * 3.0).lerp(top, k) + fd.cross(Vector3.UP) * sin(k * PI) * 2.0
		head.global_position = p
		var aim = (t.global_position if t and is_instance_valid(t) else c.global_position + fd * 15.0) - p
		if aim.length() > 0.1:
			head.look_at(p + aim, Vector3.UP), 0.0, 1.0, 0.7).set_ease(Tween.EASE_OUT)
	for i in 5:
		tw.tween_callback(func():
			var aimp = (t.global_position + Vector3.UP if t and is_instance_valid(t) else c.global_position + fd * 18.0)
			var dd = (aimp - head.global_position).normalized()
			VFX.puffs(head.global_position + dd, {"amount": 8, "life": 0.3, "size": 0.9, "vmin": 4, "vmax": 8, "dir": dd, "spread": 25.0,
				"colors": [Color(0.55, 0.45, 0.32, 1), Color(0.45, 0.35, 0.25, 1), Color(0.4, 0.3, 0.2, 0)]})
			var pr = JutsuEngine.spawn_projectile(c, d, head.global_position + dd * 1.5, dd, "", 0.9, 26.0, _inf(c, "doton_doryudan", 0.35))
			pr.gravity = 4.0)
		tw.tween_interval(0.25)
	tw.tween_property(head, "global_position:y", base.y - 5.0, 0.5).set_ease(Tween.EASE_IN)
	tw.tween_callback(head.queue_free)


## ================================================================ Tendō (kanon, Rinnegan)
## İtme ve çekme peş peşe yapılamaz: her kullanımdan sonra dolum gerekir — en az 5 sn, teknik büyüdükçe uzar; çok büyük
## kullanım ömrü kısaltır (can bedeli). Oyuncu (jutsu + göz yeteneği) ve düşman (EnemyArts, AI) aynı sayaç: meta tendo_until.
func tendo_wait(c: Node) -> float:
	return maxf(0.0, float(c.get_meta("tendo_until", 0.0)) - Time.get_ticks_msec() / 1000.0)


func tendo_gate(c: Node) -> bool:
	var w = tendo_wait(c)
	if w > 0.0:
		if c is Player:
			Hud.msg("Tendō dolmadı — itme ve çekme peş peşe yapılamaz (%.1f sn)" % w, Color(0.75, 0.9, 0.8))
		return false
	return true


func tendo_spend(c: Node, interval: float) -> void:
	c.set_meta("tendo_until", Time.get_ticks_msec() / 1000.0 + interval)


static var _shinra_shader: Shader
## Saydam bükülme küresi (referans: Tendō'yu saran neredeyse görünmez yeşilimsi küre); büyür, söner
func shinra_orb(center: Vector3, r0: float, r1: float, dur: float) -> MeshInstance3D:
	if _shinra_shader == null:
		_shinra_shader = load("res://shaders/vfx_shinra.gdshader")
	var mi = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 32
	sm.rings = 16
	mi.mesh = sm
	var m = ShaderMaterial.new()
	m.shader = _shinra_shader
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(mi)
	mi.global_position = center
	mi.scale = Vector3.ONE * maxf(0.05, r0)
	var tw = mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE * r1, dur * 0.45).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(f: float): m.set_shader_parameter("fade", f), 1.0, 0.0, dur * 0.55)
	tw.tween_callback(mi.queue_free)
	return mi


## Shinra Tensei çekirdeği: center çevresinde r yarıçaplı itme. Düşmanlar (yalnız düşmanlar: yön daraltılabilir, dostlar
## etkilenmez) dışa savrulur, ninjutsu mermileri geri çevrilir, kullanıcının üstündeki kara alevler (Amaterasu) savrulur,
## ağaç/ev yıkılır, zeminde ışınsal krater. Yere tutunan dev/ağır rakipler (boss, kuyruklu canavar) daha az savrulur.
func shinra_core(c: Node3D, center: Vector3, r: float, power: float) -> void:
	var g = _ground(center)
	shinra_orb(center, 0.3, r, 0.7 + r * 0.01)
	VFX.cracks(g, r * 0.85, Color(0.12, 0.09, 0.07, 0.9), 10.0)
	VFX.smoke_ring(g, r * 0.55, Color(0.62, 0.55, 0.46))
	VFX.debris(center, Color(0.5, 0.42, 0.32), int(20 + r * 2.0), r * 1.6, 0.4 + r * 0.02)
	for k in 16:   # dışa savrulan toz (ışınsal krater çizgileri)
		var ang = TAU * k / 16.0 + randf() * 0.2
		var dv = Vector3(cos(ang), 0.15, sin(ang))
		VFX.puffs(g + dv * r * 0.35 + Vector3.UP * 0.5, {"amount": 4, "life": 0.9, "size": 0.6 + r * 0.06, "radius": 0.5, "vmin": r * 0.9, "vmax": r * 1.6, "dir": dv, "spread": 12.0, "add": false,
			"colors": [Color(0.66, 0.58, 0.48, 0.9), Color(0.6, 0.53, 0.44, 0)]})
	VFX.screen_lines(0.45, 0.8)
	Sfx.play("boom", center, clampf(0.7 - r * 0.004, 0.35, 0.7))
	if Game.world:
		Game.world.env.add_shake(clampf(0.6 + r * 0.04, 0.6, 2.4))
	WorldDamage.impact(g, r * 0.8, {"dmg": 40.0 * power, "knock": 30.0, "kind": "heavy"})
	if r >= 20.0:
		shinra_crater(g, r)
	for pr in get_tree().get_nodes_in_group("projectiles"):
		if pr.shooter != c and not pr.dead and pr.global_position.distance_to(center) < r + 2.0:
			pr.apply_clash(false, 0.0)
	if center.distance_to(c.global_position + Vector3.UP) < r:
		for sp in Amaterasu.spots.duplicate():
			if sp["target"] == c:
				Amaterasu._drop(sp, 2.0)
				Combat.popup_text(c.global_position + Vector3.UP * 2.6, "Kara alevler savruldu", Color(0.8, 0.9, 0.85))
	for f in get_tree().get_nodes_in_group("fighters"):
		if Combat.hostile(c, f) and not f.is_dead() and f.global_position.distance_to(center) < r + f.radius:
			var dd = f.global_position - center
			dd.y = 0
			if dd.length() < 0.1:
				dd = f.global_position - c.global_position
				dd.y = 0
			var heavy = f is TailedBeast or f.has_meta("boss")
			var k = (0.4 if heavy else 1.0) * power
			f.take_hit(_inf(c, "shinra_tensei", 1.1 * power, {"knock": 30.0 * k, "launch": 7.0 * k, "kind": "heavy", "dir": dd.normalized(), "attacker": c}))


## ================================================================ Gakidō (kanon, Rinnegan)
## Fūjutsu Kyūin: bedenin her yanını saran saydam bariyer; çakraya dayalı her ninjutsuyu (biçim/doğa farketmez) emer ve
## etkisiz kılar — fiziksel saldırı (yakın dövüş, silah) emilmez. Senjutsu çakrası emilirse kullanıcı taşlaşır (Gakidō'nun
## Naruto'ya yenilişi). Oyuncu: buff fujutsu_kyuin; düşman: meta kyuin_until. Oyuncu ve düşman aynı kural (preta_absorbs).
func kyuin_on(n: Node) -> bool:
	if n is Player:
		return Buffs.has("fujutsu_kyuin")
	return float(n.get_meta("kyuin_until", 0.0)) > Time.get_ticks_msec() / 1000.0


func preta_absorbs(def: Node3D, info: Dictionary) -> bool:
	if not kyuin_on(def):
		return false
	var physical = info.get("melee", false) or info.get("blade", false) or info.get("weapon", false) or not info.has("tier")
	if physical:
		return false
	var atk = info.get("attacker")
	var sage = info.get("senjutsu", false) or (atk is Player and Buffs.has("sage")) or (atk is Node and atk.has_meta("sage"))
	var amt = float(info.get("dmg", 0.0))
	if sage:
		# doğa enerjisi bedene akar: taşlaşma
		def.apply_status("stun", 3.0)
		info["dmg"] = amt * 1.5 + 20.0
		info["pierce_guard"] = true
		Combat.popup_text(def.global_position + Vector3.UP * 2.6, "Doğa enerjisi! Taşlaşıyor...", Color(0.75, 0.7, 0.6))
		VFX.debris(def.global_position + Vector3.UP, Color(0.6, 0.58, 0.55), 10, 3.0, 0.3)
		if def is Player:
			Buffs.remove("fujutsu_kyuin")
		else:
			def.remove_meta("kyuin_until")
		return false
	Combat.popup_text(def.global_position + Vector3.UP * 2.4, "Emildi", Color(0.75, 0.9, 1.0))
	var fl = shinra_orb(def.global_position + Vector3.UP * 1.0, 1.0, 1.25, 0.35)
	fl.material_override.set_shader_parameter("tint", Vector3(0.75, 0.85, 1.0))
	fl.material_override.set_shader_parameter("rim", Vector3(0.65, 0.8, 1.0))
	if def is Player:
		def.chakra = minf(def.max_chakra, def.chakra + amt * 0.6)
	else:
		def.hp = minf(def.max_hp, def.hp + amt * 0.3)
	return true


## Büyük itmenin kraterı (referans: Konoha — yuvarlak koyu çukur, çevresinde dışa savrulmuş ışınsal açık toprak dilleri)
func shinra_crater(g: Vector3, r: float) -> void:
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = g + Vector3.UP * 0.06
	var disc = MeshInstance3D.new()
	var qm = QuadMesh.new()
	qm.size = Vector2(r * 1.1, r * 1.1)
	qm.orientation = PlaneMesh.FACE_Y
	disc.mesh = qm
	var gt = GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	var gr = Gradient.new()
	gr.set_color(0, Color(0.36, 0.25, 0.16, 0.95))
	gr.set_color(1, Color(0.5, 0.38, 0.26, 0.0))
	gr.add_point(0.8, Color(0.42, 0.3, 0.2, 0.9))
	gt.gradient = gr
	var dm = StandardMaterial3D.new()
	dm.albedo_texture = gt
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.roughness = 1.0
	disc.material_override = dm
	root.add_child(disc)
	var mb = MB.new()
	for k in 56:   # dışa savrulmuş toprak dilleri (krater kenarından ışınsal, uca doğru sivrilen)
		var ang = TAU * k / 56.0 + randf_range(-0.04, 0.04)
		var L = r * randf_range(0.35, 0.75)
		var w = r * randf_range(0.03, 0.06)
		var dv = Vector3(cos(ang), 0, sin(ang))
		var a0 = dv * r * 0.5
		var pts = [a0, a0 + dv * L * 0.5, a0 + dv * L]
		Loft.tube(mb, pts, [Vector2(w, 0.05), Vector2(w * 0.7, 0.04), Vector2(0.02, 0.02)], Color(0.68, 0.56, 0.4).darkened(randf() * 0.12), 4, 2, true, true, Callable(), Vector3.UP)
	var rays = MeshInstance3D.new()
	rays.mesh = mb.build(Props.toon())
	root.add_child(rays)
	var tw = root.create_tween()
	tw.tween_interval(25.0)
	tw.tween_property(root, "scale", Vector3(1, 0.01, 1), 2.0)
	tw.tween_callback(root.queue_free)


## Shinra Tensei (kanon): kullanıcının çevresinde itme; kilitli hedef uzaktaysa (14-30 m) itme orada doğar.
func j_shinra_tensei(c: Node3D, t: Node3D) -> void:
	if not tendo_gate(c):
		return
	tendo_spend(c, 5.0)
	var far = t != null and is_instance_valid(t) and t != c and c.global_position.distance_to(t.global_position) > 14.0 and c.global_position.distance_to(t.global_position) < 30.0
	if c.get("model"):
		c.model.play("push", 0.05, 1.6, true)
	if far:
		shinra_core(c, t.global_position + Vector3.UP, 8.0, 0.9)
	else:
		shinra_core(c, c.global_position + Vector3.UP, 11.0, 1.0)


## Banshō Ten'in (kanon): hedefi kendine çeker; yakınındaki başka hedefleri de çekip birbirine çarpıştırır. Aynı 5 sn dolum.
## Yere tutunan dev/ağır rakipler kısmen gelir.
func bansho_core(c: Node3D, t: Node3D, rng := 26.0) -> void:
	var tt = _tg(c, t, rng)
	if tt == null:
		if c is Player:
			Hud.msg("Banshō Ten'in: menzilde hedef yok.", Color(0.75, 0.9, 0.8))
		return
	if not tendo_gate(c):
		return
	tendo_spend(c, 5.0)
	if c.get("model"):
		c.model.play("cast", 0.05, 1.4, true)
	var group = [tt]
	for f in get_tree().get_nodes_in_group("fighters"):
		if group.size() >= 3:
			break
		if f != tt and Combat.hostile(c, f) and not f.is_dead() and not (f is TailedBeast) and f.global_position.distance_to(tt.global_position) < 7.0:
			group.append(f)
	var fd: Vector3 = c.face_dir() if c.has_method("face_dir") else Vector3.FORWARD
	var dest = _ground(c.global_position + fd * 1.6)
	var col = Color(0.85, 0.97, 0.9, 0.7)
	for f in group:
		var start: Vector3 = f.global_position + Vector3.UP
		for q in 5:   # çekim çizgileri: hedeften kullanıcıya akan hız çizgileri
			var off = Vector3(randf_range(-0.8, 0.8), randf_range(-0.6, 0.9), randf_range(-0.8, 0.8))
			WindFX.streak(func(u: float) -> Vector3: return (start + off).lerp(c.global_position + Vector3.UP + off * 0.3, u), 0.35, 0.05, col, q * 0.03, 10)
		shinra_orb(start, 2.2, 0.3, 0.5)
		var heavy = f is TailedBeast or f.has_meta("boss")
		var to = dest + (f.global_position - dest).normalized() * (0.4 if f != tt else 0.0)
		if heavy:
			to = f.global_position.lerp(dest, 0.4)
		f.apply_status("stun", 0.9)
		var tw = f.create_tween()
		tw.tween_property(f, "global_position", to + Vector3.UP * 0.3, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			if not is_instance_valid(f) or f.is_dead():
				return
			if group.size() > 1:   # çekilenler birbirine çarpar
				VFX.star(f.global_position + Vector3.UP, Color(1, 1, 0.95), 2.5, 0.15)
				f.take_hit(_inf(c, "bansho_ten_in", 0.9, {"knock": 4.0, "launch": 0.0, "kind": "heavy", "attacker": c}))
			else:
				f.take_hit(_inf(c, "bansho_ten_in", 0.5, {"knock": 0.0, "launch": 0.0, "kind": "light", "attacker": c})))
	Sfx.play("wind", c.global_position, 1.4, 0.5)


## Raikiri: Chidori'nin keskin, beyaz-mavi hali — daha hızlı hücum
func j_raikiri(c: Node3D, t: Node3D) -> void:
	var m = _mult(c) * _elem_bonus(c, "raiton")
	# kanon: Sharingan olmadan güvenle kullanılamaz (tünel görüşü). Sharingan yoksa: hasar düşük ve karşı darbeye açık
	var has_sh = false
	if c is Player and c.combat and c.combat.modes and c.combat.modes.get("eyes"):
		var ey = c.combat.modes.eyes
		has_sh = ey.active and (ey._kind("sag") in [1, 4, 5] or ey._kind("sol") in [1, 4, 5])
	elif c.has_meta("eyes"):
		has_sh = int(c.get_meta("eyes").get("kind", 0)) in [1, 4, 5]
	if not has_sh:
		m *= 0.75
		if c is Player:
			Hud.msg("Sharingan olmadan Raikiri: tünel görüşü — karşı saldırıya açıksın!", Color(1, 0.7, 0.4), 2.0)
			Buffs.add("tunel_gorus", 2.5, {"armor": 1.4, "_name": "Tünel Görüşü"})
	var hand = _lightning_ball(c, Color(1, 1, 1), Color(0.75, 0.88, 1.0), "chidori")
	hand.scale = Vector3.ONE * 1.25
	_pose_chidori_charge(c)
	_hand_dash(c, t, hand, 0.5, 36.0, {"dmg": 40.0 * m, "element": "raiton", "knock": 16.0, "launch": 3.0, "kind": "heavy", "hitstop": 0.14, "stun": 1.2},
		Color(0.8, 0.9, 1.0), false, true)


## Ōdama Rasengan: devasa spiral küre, ezici öğütme
func j_odama_rasengan(c: Node3D, t: Node3D) -> void:
	var m = _mult(c)
	var hand: Node3D = Node3D.new()
	c.model.add_child(hand)
	hand.position = Vector3(0.35, 1.9, -1.2)
	var ras = VFX.rasengan(2.4)
	hand.add_child(ras)
	ras.scale = Vector3.ONE * 0.1
	ras.create_tween().tween_property(ras, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	FX.aura(c, Color(0.5, 0.8, 1.0), 1.2, Vector3(0, 0.9, 0), 1.6)
	Sfx.play("rasengan", c.global_position, 0.7)
	_hand_dash(c, t, hand, 0.75, 24.0, {"dmg": 60.0 * m, "knock": 44.0, "launch": 12.0, "kind": "heavy", "hitstop": 0.2}, Color(0.4, 0.7, 1.0), true)


## Amaterasu (kanon): bakılan odak noktasında ANINDA kara alev — kaçılamaz (yalnız yer değiştirme / ani hızla sıyrılınır),
## su söndürmez, hedef ölünce alev yerde yanmaya devam eder. Ortak sistem: Amaterasu.ignite.
func j_amaterasu(c: Node3D, t: Node3D) -> void:
	var tg = _tg(c, t, 40.0)
	var pos: Vector3 = (tg.global_position if tg else _ground(_aim_ground(c, t, 15.0, 40.0)))
	Amaterasu.focus_flash(c)
	var inf = _inf(c, "amaterasu", 0.12, {"knock": 0.0, "launch": 0.0, "kind": "light", "hitstop": 0.0, "element": "katon"})
	Amaterasu.ignite(c, tg, pos, 12.0, inf)


## Kara alevden bir şekil (mızrak/kılıç/magatama): kara alev malzemesiyle yanan geometri
func _black_mat() -> ShaderMaterial:
	var m = VFX.mat_fire("black", 3.0, 2.6, 0.55, 1.0, 0.2, Vector3.UP, true)
	m.set_shader_parameter("tongue", 0.5)
	return m


func _ignite(tg: Node3D, dur: float) -> void:
	if tg == null or not is_instance_valid(tg) or tg.is_dead():
		return
	tg.apply_status("burn", dur)
	tg.set_meta("black_flame", true)
	var fl = VFX.black_flames(maxf(1.0, float(tg.height) * 0.6) if "height" in tg else 1.2)
	tg.add_child(fl)
	fl.position = Vector3(0, 0.1, 0)
	get_tree().create_timer(dur).timeout.connect(func(): if is_instance_valid(fl): fl.queue_free())


## Enton: Kagutsuchi (kanon, Sasuke): Amaterasu'nun kara alevlerine şekil verme (sol göz yakar, sağ göz şekillendirir).
## Sahada yanan kendi Amaterasu alevlerin varsa onlar mızraklara dönüşüp en yakın düşmanlara fırlar (alev böylece söner:
## yalnız sahibi söndürebilir). Yoksa önünde kara alevden dikenli bariyer biçimlenir: mermileri yakar, değeni deler ve tutuşturur.
func j_enton_kagutsuchi(c: Node3D, t: Node3D) -> void:
	var tg = _tg(c, t, 45.0)
	Sfx.play("genjutsu", c.global_position, 0.5)
	var inf = _inf(c, "enton_kagutsuchi", 0.45, {"knock": 10.0, "launch": 2.0, "kind": "heavy", "hitstop": 0.05, "element": "katon"})
	var tick_inf = _inf(c, "enton_kagutsuchi", 0.08, {"knock": 0.0, "kind": "light", "hitstop": 0.0, "element": "katon"})
	var own = Amaterasu.spots_of(c, c.global_position, 45.0)
	if not own.is_empty():
		var n = 0
		for s in own:
			if n >= 6:
				break
			n += 1
			var from: Vector3 = (s["pos"] as Vector3) + Vector3.UP * 1.0
			var foe = tg if tg else Combat.nearest_enemy(c, 40.0)
			Amaterasu.extinguish(s)
			for k in 3:
				var tgt = foe
				if k > 0:
					var near = Combat.nearest_enemy(c, 40.0)
					tgt = near if near else foe
				var aim: Vector3 = (tgt.global_position + Vector3.UP * float(tgt.height) * 0.5) if tgt and is_instance_valid(tgt) else from + c.face_dir() * 10.0
				_kagutsuchi_spear(c, from + Vector3(randf_range(-0.6, 0.6), randf_range(0.0, 0.8), randf_range(-0.6, 0.6)), aim, 0.25 + k * 0.12, inf, tick_inf)
		if c is Player:
			Hud.msg("Kagutsuchi: kara alevler şekil aldı", Color(0.75, 0.5, 0.9), 1.2)
		return
	# sahada alev yok: önde dikenli kara alev bariyeri (kanon: değeni deler ve yakar)
	var d = _aim_flat(c, t)
	var center = _ground(c.global_position + d * 2.2)
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_transform = Transform3D(Basis.looking_at(-d, Vector3.UP), center)
	var base = VFX.black_flames(1.4)
	root.add_child(base)
	base.scale = Vector3(1.6, 1.1, 0.7)
	for k in 16:
		var mb = MB.new()
		mb.add("cone", Vector3(0, 0.0, 0), Vector3(0.22, 1.0, 0.22), Color.WHITE, Vector3.ZERO, 6)
		var sp = MeshInstance3D.new()
		sp.mesh = mb.build(null)
		sp.material_override = _black_mat()
		sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(sp)
		var a = lerpf(-1.1, 1.1, (k % 8) / 7.0)
		var row = k / 8
		var dirl = Vector3(sin(a) * 0.9, 0.35 + row * 0.45 + randf_range(-0.1, 0.1), 0.0)
		dirl.z = -1.0   # öne (bariyerin dışına) doğru
		dirl = dirl.normalized()
		sp.position = Vector3(sin(a) * 1.4, 0.6 + row * 0.9, 0)
		sp.basis = Basis(Quaternion(Vector3.UP, dirl)) * Basis.from_scale(Vector3.ONE * 0.05)
		var L = randf_range(1.6, 2.6)
		var tw = sp.create_tween()
		tw.tween_interval(k * 0.02)
		tw.tween_property(sp, "basis", Basis(Quaternion(Vector3.UP, dirl)) * Basis.from_scale(Vector3(1.0, L, 1.0)), 0.18).set_trans(Tween.TRANS_BACK)
	var DUR = 4.0
	_ticks(int(DUR / 0.1), 0.1, func(i):
		if not is_instance_valid(root):
			return
		for n in get_tree().current_scene.get_children():
			if n is Projectile and not n.dead and n.shooter != c and Combat.hostile(c, n.shooter) and n.global_position.distance_to(center + Vector3.UP * 1.2) < 3.0:
				VFX.embers(n.global_position, Color(0.6, 0.15, 0.7), 10, 4.0, 0.6)
				n.block()
		if i % 3 == 0:
			for h in Combat.hit_sphere(c, center + Vector3.UP * 1.0 + d * 0.8, 2.6, inf):
				Amaterasu.ignite(c, h, h.global_position, 6.0, tick_inf), func():
		if is_instance_valid(root):
			var tw = root.create_tween()
			tw.tween_property(root, "scale", Vector3(1, 0.05, 1), 0.35)
			tw.tween_callback(root.queue_free))


## Kara alev mızrağı: alevden biçimlenir, kısa bekler, hedefe fırlar; değdiği yerde Amaterasu tutuşur
func _kagutsuchi_spear(c: Node3D, from: Vector3, aim: Vector3, delay: float, inf: Dictionary, tick_inf: Dictionary) -> void:
	var mb = MB.new()
	mb.add("cone", Vector3(0, 0, -1.1), Vector3(0.16, 1.6, 0.16), Color.WHITE, Vector3(-90, 0, 0), 8)
	mb.add("cyl", Vector3(0, 0, 0.6), Vector3(0.09, 2.2, 0.09), Color.WHITE, Vector3(90, 0, 0), 8)
	for sx in [-1.0, 1.0]:
		mb.add("cone", Vector3(0.18 * sx, 0, -0.35), Vector3(0.07, 0.6, 0.05), Color.WHITE, Vector3(-90, 0, 35 * sx), 5)
	var sp = MeshInstance3D.new()
	sp.mesh = mb.build(null)
	sp.material_override = _black_mat()
	sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(sp)
	sp.global_position = from
	sp.scale = Vector3.ONE * 0.05
	if from.distance_to(aim) > 0.1:
		sp.look_at(aim, Vector3.UP if absf((aim - from).normalized().y) < 0.95 else Vector3.RIGHT)
	var end = aim + Vector3(randf_range(-0.5, 0.5), randf_range(-0.3, 0.3), randf_range(-0.5, 0.5))
	var tw = sp.create_tween()
	tw.tween_property(sp, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(delay)
	tw.tween_property(sp, "global_position", end, clampf(from.distance_to(end) / 55.0, 0.08, 0.9))
	tw.tween_callback(func():
		if is_instance_valid(c):
			for h in Combat.hit_sphere(c, end, 1.5, inf):
				Amaterasu.ignite(c, h, h.global_position, 6.0, tick_inf)
		VFX.embers(end, Color(0.6, 0.15, 0.7), 10, 4.0, 0.8))
	tw.tween_property(sp, "scale", Vector3.ONE * 0.01, 0.25)
	tw.tween_callback(sp.queue_free)


## Enton: Yasaka no Magatama — üç dönen kara alev magatamasi kullanıcının çevresinde tur atar, sonra arka arkaya
## farklı kavislerle hedefe dalar; patladıkları yerde kara alev halkası açılır
func j_enton_yasaka_no_magatama(c: Node3D, t: Node3D) -> void:
	var tg = _tg(c, t, 50.0)
	Sfx.play("genjutsu", c.global_position, 0.6)
	var inf = _inf(c, "enton_yasaka_no_magatama", 0.4, {"knock": 14.0, "launch": 4.0, "kind": "heavy", "hitstop": 0.06, "element": "katon"})
	var fallback = _aim_ground(c, t, 22.0, 50.0) + Vector3.UP
	var holder = Node3D.new()
	get_tree().current_scene.add_child(holder)
	holder.global_position = c.global_position + Vector3.UP * 1.6
	var mags = []
	for k in 3:
		var mb = MB.new()
		mb.add("sphere", Vector3.ZERO, Vector3(0.7, 0.7, 0.7), Color.WHITE, Vector3.ZERO, 12)
		mb.add("cone", Vector3(0.35, 0, 0.35), Vector3(0.3, 0.9, 0.22), Color.WHITE, Vector3(90, -45, 0), 8)   # virgül kuyruğu
		var mi = MeshInstance3D.new()
		mi.mesh = mb.build(null)
		mi.material_override = _black_mat()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(mi)
		var a = TAU * k / 3.0
		mi.position = Vector3(cos(a), 0, sin(a)) * 1.6
		mi.scale = Vector3.ONE * 0.05
		mi.create_tween().tween_property(mi, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK)
		mags.append(mi)
	holder.create_tween().tween_property(holder, "rotation:y", TAU * 1.5, 0.9)
	for k in 3:
		get_tree().create_timer(0.9 + k * 0.22).timeout.connect(func():
			var mi: MeshInstance3D = mags[k]
			if not is_instance_valid(mi):
				return
			var from = mi.global_position
			mi.reparent(get_tree().current_scene)
			var tgt: Vector3 = (tg.global_position + Vector3.UP * float(tg.height) * 0.5) if tg and is_instance_valid(tg) and not tg.is_dead() else fallback
			var mid = (from + tgt) * 0.5 + Vector3.UP * (3.0 + k) + (from - tgt).cross(Vector3.UP).normalized() * (k - 1) * 4.0
			var dur = clampf(from.distance_to(tgt) / 40.0, 0.25, 1.2)
			var tw = mi.create_tween()
			tw.tween_method(func(x: float):
				if is_instance_valid(mi):
					mi.global_position = from.lerp(mid, x).lerp(mid.lerp(tgt, x), x)
					mi.rotation.y += 0.5, 0.0, 1.0, dur)
			tw.tween_callback(func():
				for h in Combat.hit_sphere(c, tgt, 2.6, inf):
					_ignite(h, 7.0)
				VFX.shockwave(tgt, Color(0.2, 0.0, 0.25), 4.0, 0.5, false)
				VFX.black_smolder(_ground(tgt), 2.0, 6.0)
				VFX.embers(tgt, Color(0.6, 0.15, 0.7), 14, 5.0, 0.9)
				mi.queue_free()))
	get_tree().create_timer(2.0).timeout.connect(holder.queue_free)


## Amaterasu: Entenka (kanon, Sasuke): Kagutsuchi ile Amaterasu'nun kara alevleri GERÇEK Susanoo'nun kaburgalarına ve
## kollarına sarılır — kara alev kalkanı. Yakın dövüşe gelen tutuşup geri savrulur (kanonda yakın saldırganı caydırır),
## gelen hasar azalır. Susanoo olmadan yapılamaz (Susanoo.of).
func j_amaterasu_entenka(c: Node3D, t: Node3D) -> void:
	var sn = Susanoo.of(c, "amaterasu_entenka")
	if sn == null:
		return
	var DUR = 8.0
	Sfx.play("genjutsu", c.global_position, 0.7)
	var flames = []
	for b in ["Spine", "Chest", "UpperChest", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "Neck"]:
		var ba = sn.attach(b)
		if ba == null:
			continue
		var fl = VFX.black_flames(0.32 if b.contains("Arm") else 0.42)
		ba.add_child(fl)
		fl.scale = Vector3.ONE * 0.05
		fl.create_tween().tween_property(fl, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK)
		flames.append(fl)
	VFX.puffs(c.global_position + Vector3.UP * sn.h() * 0.4, {"amount": 30, "life": 0.7, "size": 1.0 + sn.h() * 0.05, "radius": sn.h() * 0.2, "vmin": 1, "vmax": 4,
		"gravity": Vector3(0, 3, 0), "glow": 1.0, "outline_col": Color(0.4, 0.05, 0.45), "colors": [Color(0.12, 0.02, 0.15, 1), Color(0.05, 0.0, 0.08, 1), Color(0.02, 0.0, 0.03, 0)]})
	if c is Player:
		Buffs.add("entenka", DUR, {"armor": 0.6, "_name": "Amaterasu: Entenka", "_desc": "Susanoo kara alevle kaplı: hasar azalır, yaklaşan tutuşur"})
	else:
		c.set_meta("entenka_until", Time.get_ticks_msec() + int(DUR * 1000.0))
	var inf = _inf(c, "amaterasu_entenka", 0.12, {"knock": 16.0, "launch": 2.0, "kind": "heavy", "hitstop": 0.0, "element": "katon"})
	var tick_inf = _inf(c, "amaterasu_entenka", 0.08, {"knock": 0.0, "kind": "light", "hitstop": 0.0, "element": "katon"})
	var reach = 2.2 + sn.h() * 0.12
	_ticks(int(DUR / 0.4), 0.4, func(_i):
		if not is_instance_valid(c):
			return
		for h in Combat.hit_sphere(c, c.global_position + Vector3.UP, reach, inf):
			Amaterasu.ignite(c, h, h.global_position, 5.0, tick_inf), func():
		for fl in flames:
			if is_instance_valid(fl):
				var tw = fl.create_tween()
				tw.tween_property(fl, "scale", Vector3(1, 0.05, 1), 0.3)
				tw.tween_callback(fl.queue_free))


## Tensha Fūin: Amaterasu (kanon, Itachi): Amaterasu göze mühürlenir ve ÖNCEDEN BELİRLENEN hedef görüldüğü an kendiliğinden
## tetiklenir. Oyunda: atarken kilitli/en yakın hedef işaretlenir; 3 sn sonra kurulur, 90 sn içinde o hedef 30 m içinde
## görüş alanına girdiği anda Amaterasu yanar (bir kez).
func j_tensha_fuin_amaterasu(c: Node3D, t: Node3D) -> void:
	var mark = _tg(c, t, 60.0)
	if mark == null:
		if c is Player:
			Hud.msg("Tensha Fūin: mühürlenecek hedef yok (kilitle ya da yakına gel).", Color(0.8, 0.8, 0.8))
		return
	Sfx.play("seal", c.global_position, 0.8)
	VFX.star(c.global_position + Vector3.UP * 1.65, Color(0.85, 0.2, 0.9), 2.0)
	if c is Player:
		Hud.msg("Tensha Fūin: %s gözüne girdiği an Amaterasu kendiliğinden yanacak." % String(mark.get("display_name") if mark.get("display_name") != null else "hedef"), Color(0.8, 0.5, 1.0))
	var st = {"fired": false, "armed": false, "seen": false}
	var wr = weakref(mark)
	_ticks(int(90.0 / 0.25), 0.25, func(i):
		if st["fired"] or not is_instance_valid(c):
			return
		var m = wr.get_ref()
		if m == null or m.is_dead():
			st["fired"] = true
			return
		var v: Vector3 = m.global_position - c.global_position
		var seen = v.length() < 30.0 and c.face_dir().dot(Vector3(v.x, 0, v.z).normalized()) > 0.45
		if not st["armed"]:
			# kurulma: 3 sn geçince ya da hedef bir kez görüşten çıkınca
			if i >= 12 or not seen:
				st["armed"] = true
			return
		if seen:
			st["fired"] = true
			Combat.popup_text(c.global_position + Vector3.UP * 2.4, "Amaterasu!", Color(0.85, 0.35, 0.95))
			VFX.star(c.global_position + Vector3.UP * 1.65, Color(0.85, 0.2, 0.9), 2.4, 0.2)
			j_amaterasu(c, m))

## Tsukuyomi (kanon, Itachi): GÖZ TEMASI — kurban, zamanı kullanıcının yönettiği kızıl-kara bir dünyaya çekilir:
## çarmıha gerilir, 72 saat boyunca kılıçlanır; dışarıda yalnız bir an geçer. Kurban çöker, uzun süre kendine gelemez.
## Sharingan sahibi direnir, Kyō Tenchi-ten yansıtır (Eyes.genjutsu_land).
func j_tsukuyomi(c: Node3D, t: Node3D) -> void:
	var tg = _tg(c, t, 20.0)
	if tg == null:
		if c is Player: Hud.msg("Göz göze gelecek hedef yok.", Color(0.8, 0.8, 0.8))
		return
	var gm = Eyes.genjutsu_land(c, tg, true)
	if gm <= 0.0:
		return
	Sfx.play("genjutsu", c.global_position, 0.5)
	# 1) Tsukuyomi dünyası: ekran negatif kızıl-kara, kara ay (oyuncu kullanan ya da kurbansa)
	if c == Game.player or tg == Game.player:
		var cl = CanvasLayer.new()
		cl.layer = 6
		var rect = ColorRect.new()
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sm = ShaderMaterial.new()
		sm.shader = load("res://shaders/vfx_tsukuyomi.gdshader")
		sm.set_shader_parameter("amount", 0.0)
		rect.material = sm
		cl.add_child(rect)
		get_tree().current_scene.add_child(cl)
		var tw = rect.create_tween()
		tw.tween_method(func(x: float): sm.set_shader_parameter("amount", x), 0.0, 1.0, 0.12)
		tw.tween_interval(1.5)
		tw.tween_method(func(x: float): sm.set_shader_parameter("amount", x), 1.0, 0.0, 0.3)
		tw.tween_callback(cl.queue_free)
	tg.apply_status("stun", 1.9)
	# 2) çarmıh: kurbanın arkasında kara haç, kurban üstüne gerilir
	var base: Vector3 = tg.global_position
	var back: Vector3 = (base - c.global_position)
	back.y = 0.0
	back = back.normalized() if back.length() > 0.1 else Vector3.FORWARD
	var cross = Node3D.new()
	var mb = MB.new()
	mb.add("box", Vector3(0, 1.6, 0), Vector3(0.28, 3.4, 0.22), Color(0.02, 0.0, 0.0))
	mb.add("box", Vector3(0, 2.45, 0), Vector3(2.3, 0.26, 0.22), Color(0.02, 0.0, 0.0))
	var cmi = MeshInstance3D.new()
	cmi.mesh = mb.build(null)
	var cm = StandardMaterial3D.new()
	cm.albedo_color = Color(0.02, 0.0, 0.0)
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cmi.material_override = cm
	cross.add_child(cmi)
	get_tree().current_scene.add_child(cross)
	cross.global_position = base + back * 0.35
	cross.look_at(cross.global_position + back, Vector3.UP)
	cross.scale = Vector3(1, 0.02, 1)
	cross.create_tween().tween_property(cross, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_BACK)
	if tg.get("model"):
		tg.model.play("hit", 0.05, 0.4, true)
	# 3) 72 saat: kara kılıçlar art arda saplanır (dışarıda yalnız bir an)
	var wr = weakref(tg)
	for k in 8:
		get_tree().create_timer(0.15 + k * 0.14).timeout.connect(func():
			var n = wr.get_ref()
			if n == null or not is_instance_valid(n):
				return
			var a = (k * 2.3) + randf_range(-0.3, 0.3)
			var side = back.cross(Vector3.UP).normalized()
			var dir = (-back * 0.8 + side * cos(a) * 0.7 + Vector3.UP * sin(a) * 0.4).normalized()   # önden ve yanlardan
			var hitp = n.global_position + Vector3.UP * randf_range(0.9, 1.6)
			var bm = MB.new()
			bm.add("box", Vector3(0, 0, -0.75), Vector3(0.05, 0.12, 1.5), Color(0.02, 0.0, 0.0))
			bm.add("box", Vector3(0, 0, 0.1), Vector3(0.22, 0.05, 0.05), Color(0.02, 0.0, 0.0))
			var sw = MeshInstance3D.new()
			sw.mesh = bm.build(null)
			sw.material_override = cm
			get_tree().current_scene.add_child(sw)
			var from = hitp - dir * 2.6
			sw.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), from)
			var tw2 = sw.create_tween()
			tw2.tween_property(sw, "global_position", hitp - dir * 0.6, 0.06).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
			tw2.tween_callback(func():
				FX.burst(hitp, {"amount": 8, "life": 0.4, "size": 0.15, "vmin": 2.0, "vmax": 4.0, "gravity": Vector3(0, -6, 0), "colors": [Color(0.9, 0.9, 0.9), Color(0.5, 0.0, 0.0, 0)]})
				Sfx.play("kunai", hitp, 0.7))
			tw2.tween_interval(1.5 - k * 0.12)
			tw2.tween_callback(sw.queue_free))
	Combat.popup_text(base + Vector3.UP * 2.8, "72 saat...", Color(0.95, 0.2, 0.2))
	# 4) gerçek dünyada bir an geçti: kurban çöker
	get_tree().create_timer(1.75).timeout.connect(func():
		if is_instance_valid(cross):
			var tw3 = cross.create_tween()
			tw3.tween_property(cross, "scale", Vector3(1, 0.02, 1), 0.2)
			tw3.tween_callback(cross.queue_free)
		var n = wr.get_ref()
		if n == null or not is_instance_valid(n) or n.is_dead():
			return
		n.apply_status("stun", 5.0 * gm)
		n.apply_status("fear", 7.0 * gm)
		n.take_hit(_inf(c, "tsukuyomi", 2.2 * gm, {"knock": 0.0, "attacker": c, "dir": Vector3.ZERO}))
		if n.get("model"):
			n.model.play("crouch", 0.1, 0.8)
		Combat.popup_text(n.global_position + Vector3.UP * 2.4, "Zihni çöktü", Color(0.9, 0.3, 0.35)))


## Kamui (kanon, Kakashi'nin uzak menzili): bakılan odak noktasında uzay bükülür ve oradaki şey boyuta çekilir. Odaklanma
## zaman ister: girdap ~1.1 sn büyür; hedef bu sürede noktadan çıkarsa kurtulur (Deidara kolunu böyle kaybetti). Yakalanırsa
## Kamui çekişi (MsArts.kamui_warp): zayıflamış hedef bütünüyle, güçlüsünün bir parçası boyuta gider.
func j_kamui(c: Node3D, t: Node3D) -> void:
	var tg = _tg(c, t, 35.0)
	var pos: Vector3 = (tg.global_position + Vector3.UP * float(tg.height) * 0.5) if tg else _aim_ground(c, t, 12.0, 35.0) + Vector3.UP
	var FOCUS = 1.1
	MsArts.kamui_vortex(pos, 2.4, FOCUS + 0.5)
	Sfx.play("genjutsu", pos, 0.7)
	if c is Player:
		Hud.msg("Kamui: odaklanıyor...", Color(0.75, 0.6, 0.95), 0.9)
	if tg:
		tg.apply_status("slow", FOCUS)
	var wr = weakref(tg) if tg else null
	get_tree().create_timer(FOCUS).timeout.connect(func():
		if not is_instance_valid(c):
			return
		var n = wr.get_ref() if wr else null
		var caught = []
		for h in MsArts._foes(c, pos, 2.2):
			caught.append(h)
		if n != null and is_instance_valid(n) and not n in caught:
			Combat.popup_text(n.global_position + Vector3.UP * 2.4, "Kamui'den kaçtı!", Color(0.8, 0.8, 0.8))
		var inf = _inf(c, "kamui", 2.2, {"knock": 0.0, "kind": "heavy", "attacker": c, "dir": Vector3.ZERO})
		for h in caught:
			MsArts.kamui_warp(c, h, inf, pos)
		if Game.world:
			Game.world.env.add_shake(0.3))


## Hiraishin: sarı flaşla hedefin arkasına ışınlan ve kes
func j_hiraishin_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tg = _tg(c, t, 40.0)
	var from = c.global_position
	VFX.star(from + Vector3.UP, Color(1.0, 0.85, 0.2), 5.0, 0.2)
	if tg:
		var behind = tg.global_position - (tg.global_position - from).normalized() * -1.6
		c.global_position = _ground(behind)
		if c.has_method("reset_physics_interpolation"):
			c.reset_physics_interpolation()
		var dd = (tg.global_position - c.global_position)
		dd.y = 0
		if c is Player:
			c.facing = atan2(-dd.x, -dd.z)
		tg.take_hit(_inf(c, "hiraishin_no_jutsu", 1.6, {"knock": 10.0, "dir": dd.normalized(), "attacker": c, "hitstop": 0.12}))
		VFX.star(tg.global_position + Vector3.UP, Color(1, 0.9, 0.3), 5.0, 0.2)
		VFX.bolt(from + Vector3.UP, c.global_position + Vector3.UP, Color(1.0, 0.8, 0.2), 0.3, 0.15, 0)
		VFX.screen_lines(0.4, 0.8, Color(1, 0.9, 0.5))
	else:
		_teleport_fallback(c, t)
	Sfx.play("whoosh", c.global_position, 1.8)


func _teleport_fallback(c: Node3D, t: Node3D) -> void:
	var dir: Vector3 = _aim_flat(c, t)
	c.global_position = _ground(c.global_position + dir * 18.0)
	VFX.star(c.global_position + Vector3.UP, Color(1.0, 0.85, 0.2), 4.0, 0.2)


## Sabaku Kyū: kum hedefi sarar, sıkıştırır ve ezer
func j_sabaku_kyu(c: Node3D, t: Node3D) -> void:
	var tg = _tg(c, t, 22.0)
	if tg == null:
		if c is Player: Hud.msg("Hedef yok.", Color(0.8, 0.8, 0.8))
		return
	var sand = Color(0.82, 0.68, 0.45)
	Sfx.play("earth", tg.global_position, 1.3)
	tg.apply_status("bind", 2.4)
	var shell = VFX._mi(VFX._sphere(0.5, 20, 10), Props.toon_color(sand))
	tg.add_child(shell)
	shell.position = Vector3(0, tg.height * 0.5, 0)
	shell.scale = Vector3(3.5, 0.1, 3.5)
	_ticks(8, 0.15, func(_i):
		if is_instance_valid(tg):
			VFX.puffs(tg.global_position, {"amount": 10, "life": 0.6, "size": 1.0, "radius": 2.0, "vmin": 3, "vmax": 6, "dir": Vector3.UP, "spread": 20.0, "tangent": 8.0,
				"outline_col": Color(0.4, 0.3, 0.18), "colors": [Color(0.9, 0.78, 0.55, 1), sand, Color(sand.r, sand.g, sand.b, 0)]}))
	var tw = shell.create_tween()
	tw.tween_property(shell, "scale", Vector3(2.4, tg.height * 1.3, 2.4), 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_property(shell, "scale", Vector3(1.6, tg.height * 1.15, 1.6), 0.25)  # sıkıştır
	tw.tween_callback(func():
		if is_instance_valid(tg):
			VFX.puffs(tg.global_position + Vector3.UP, {"amount": 40, "life": 0.9, "size": 1.6, "radius": 1.2, "vmin": 6, "vmax": 14,
				"outline_col": Color(0.4, 0.3, 0.18), "colors": [Color(0.92, 0.8, 0.58, 1), sand, Color(sand.r, sand.g, sand.b, 0)]})
			VFX.star(tg.global_position + Vector3.UP, sand.lightened(0.3), 4.0, 0.2)
			tg.take_hit(_inf(c, "sabaku_kyu", 2.0, {"knock": 4.0, "attacker": c, "dir": Vector3.ZERO, "hitstop": 0.15}))
			if Game.world: Game.world.env.add_shake(0.8)
		shell.queue_free())


## Kibaku Nendo: beyaz kil kuşları hedefe uçar ve patlar
func j_kibaku_nendo(c: Node3D, t: Node3D) -> void:
	var d = _jd("kibaku_nendo").duplicate()
	d["element"] = "bakuton"
	var dir = _aim(c, t)
	for i in 3:
		get_tree().create_timer(i * 0.18).timeout.connect(func():
			if not is_instance_valid(c):
				return
			var dd = (dir + Vector3(randf_range(-0.3, 0.3), 0.25, randf_range(-0.3, 0.3))).normalized()
			var pr = Projectile.new()
			pr.shooter = c
			pr.vel = dd * 18.0
			pr.radius = 0.8
			pr.life = 3.0
			pr.homing = t
			pr.homing_turn = 2.5
			pr.info = _inf(c, "kibaku_nendo", 0.4, {"element": "bakuton"})
			var bird = ClayArt.bird(1.4)
			pr.add_child(bird)
			pr.on_hit = func(pos: Vector3, _tg: Node3D) -> void:
				VFX.clay_blast(pos, 1.0)
				Combat.hit_sphere(c, pos, 4.0, _inf(c, "kibaku_nendo", 0.6, {"element": "bakuton"}), pr.hit_list)
			get_tree().current_scene.add_child(pr)
			pr.global_position = _hand(c) + Vector3.UP * 0.5
			FX.smoke_puff(pr.global_position, 0.5, 6))


## Jinton: hedefi saran beyaz küp — içindekini molekül düzeyinde parçalar
func j_jinton_genkai_hakuri_no_jutsu(c: Node3D, t: Node3D) -> void:
	var tg = _tg(c, t, 40.0)
	var pos: Vector3 = (tg.global_position + Vector3.UP) if tg else _aim_ground(c, t, 18.0, 40.0) + Vector3.UP
	# elde parlayan küçük küp
	var hand = VFX._mi(BoxMesh.new(), VFX.mat_spiral(Color(1, 1, 1), Color(0.75, 0.85, 1.0), 4.0, 1.0, 6.0, 2.0))
	get_tree().current_scene.add_child(hand)
	hand.global_position = _hand(c)
	hand.scale = Vector3.ONE * 0.4
	var tw = hand.create_tween()
	tw.tween_property(hand, "rotation", Vector3(TAU, TAU, 0), 0.6)
	tw.tween_property(hand, "global_position", pos, 0.25)
	tw.tween_property(hand, "scale", Vector3.ONE * 8.0, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.35)
	tw.tween_callback(func():
		VFX.star(pos, Color(1, 1, 1), 10.0, 0.25)
		VFX.shockwave(pos, Color(0.85, 0.92, 1.0), 14.0, 0.4, false)
		Combat.hit_sphere(c, pos, 5.0, _inf(c, "jinton_genkai_hakuri_no_jutsu", 3.0, {"knock": 2.0}))
		if Game.world:
			Game.world.env.screen_flash(0.5)
			Game.world.env.add_shake(1.0))
	tw.tween_property(hand, "scale", Vector3.ONE * 0.01, 0.2).set_ease(Tween.EASE_IN)
	tw.tween_callback(hand.queue_free)
	Sfx.play("genjutsu", c.global_position, 1.6)
	if c is Player:
		VFX.screen_lines(0.9, 0.5)


## Mokuryū: yerden yükselen tahta ejderha hedefe atılır, sarılıp sıkar
func j_mokuton_mokuryu_no_jutsu(c: Node3D, t: Node3D) -> void:
	# kanon (Hashirama): dev yılansı tahta ejder topraktan çıkar, rakibe dalar, onu sarmal sarıp bağlar ve ısırarak chakrasını
	# emer (vampir gibi). Baş: Mokuryu.head (ref: uzun burun, tırtıklı dişli açık çene, parlayan gözler, kabuk yele, ön pençeler)
	var fd = _aim_flat(c, t)
	var base = _ground(c.global_position + fd * 4.0)
	var wood = Props.toon_color(Mokuryu.WOOD)
	var head = Node3D.new()
	get_tree().current_scene.add_child(head)
	head.global_position = base - Vector3.UP * 4.0
	var hn = Mokuryu.head(3.4)
	head.add_child(hn)
	var jaw: Node3D = hn.get_node("jaw")
	var body = VfxSerpent.new()
	body.style = "wood"
	body.seed_id = "mokuton_mokuryu_no_jutsu"
	body.head = head
	body.count = 26
	body.spacing = 2.0
	body.radius = 2.2
	body.mat = wood
	body.ring_mat = Props.toon_color(Mokuryu.DARK)   # kabuk boğumları
	body.fin_mat = Props.toon_color(Mokuryu.DARK.lightened(0.1))   # sırt dikenleri
	get_tree().current_scene.add_child(body)
	VFX.cracks(base, 9.0)
	VFX.debris(base, Color(0.45, 0.35, 0.25), 24, 16.0, 0.6)
	Sfx.play("earth", base)
	var tg = _tg(c, t, 40.0)
	var tw = head.create_tween()
	var top = base + Vector3.UP * 9.0 + fd * 4.0
	var side = fd.cross(Vector3.UP)
	tw.tween_method(func(k: float):   # yükseliş: kıvrılarak gökyüzüne
		var p = (base - Vector3.UP * 4.0).lerp(top, k) + side * sin(k * TAU) * 4.0
		var nx = (base - Vector3.UP * 4.0).lerp(top, minf(1.0, k + 0.03)) + side * sin(minf(1.0, k + 0.03) * TAU) * 4.0
		head.global_position = p
		head.look_at(nx, Vector3.RIGHT if absf((nx - p).normalized().y) > 0.98 else Vector3.UP), 0.0, 1.0, 0.7)
	tw.tween_method(func(k: float):   # dalış
		var goal = (tg.global_position + Vector3.UP * 1.5 if tg and is_instance_valid(tg) else c.global_position + fd * 26.0)
		var p = top.lerp(goal, k * k)
		if p.distance_to(head.global_position) > 0.01:
			head.look_at(p, Vector3.UP)
		head.global_position = p, 0.0, 1.0, 0.45)
	tw.tween_callback(func():
		var p = head.global_position
		VFX.debris(p, Color(0.5, 0.4, 0.3), 18, 12.0, 0.5)
		FX.dust(_ground(p), 2.0)
		Combat.hit_sphere(c, p, 4.5, _inf(c, "mokuton_mokuryu_no_jutsu", 0.6, {"knock": 0.0}))
		if tg and is_instance_valid(tg):
			tg.apply_status("bind", 3.6)
			Combat.popup_text(tg.global_position + Vector3.UP * 2.6, "Mokuryū sardı!", Color(0.8, 0.75, 0.5))
		if Game.world: Game.world.env.add_shake(0.8))
	# sarma: baş rakibin çevresinde iki tur yükselerek döner, gövde sarmal halka olur; sonra ısırır
	var ctr = {"p": Vector3.ZERO}
	tw.tween_method(func(k: float):
		var cp = tg.global_position if tg and is_instance_valid(tg) else ctr["p"]
		if ctr["p"] == Vector3.ZERO:
			ctr["p"] = cp
		var a = k * TAU * 2.0
		var r = 3.6
		var p = cp + Vector3(cos(a) * r, 0.6 + k * 4.0, sin(a) * r)
		var nx = cp + Vector3(cos(a + 0.3) * r, 0.6 + k * 4.0 + 0.1, sin(a + 0.3) * r)
		head.global_position = p
		head.look_at(nx, Vector3.UP), 0.0, 1.0, 1.1)
	tw.tween_callback(func():
		if tg and is_instance_valid(tg):
			head.look_at(tg.global_position + Vector3.UP * 1.2, Vector3.UP)
			var jt = jaw.create_tween()
			jt.tween_property(jaw, "rotation:x", 0.0, 0.12)
			Sfx.play("bite", tg.global_position, 0.8))
	# ısırık (kanon, Naruto 608/656): ejder ısırarak chakrayı vampir gibi emer, rakip yavaş yavaş jutsu yapamaz hale gelir.
	# Karşı koyma (kanon: başı yok etmek emmeyi bitirir): bağdan kurtulan (Kawarimi/kaçış) rakipte emme kesilir.
	var drain = func():
		for k in 6:
			get_tree().create_timer(k * 0.35).timeout.connect(func():
				if not (tg and is_instance_valid(tg)) or tg.is_dead():
					return
				if tg.has_method("has_status") and not tg.has_status("bind"):
					return   # kurtuldu: ejderin dişleri boşa kapandı
				var before = float(tg.get("chakra")) if tg.get("chakra") != null else 0.0
				tg.take_hit(_inf(c, "mokuton_mokuryu_no_jutsu", 0.12, {"knock": 0.0, "kind": "light", "chakra_drain": 12.0}))
				if c.get("chakra") != null and c.get("max_chakra") != null:
					c.chakra = minf(float(c.max_chakra), float(c.chakra) + 6.0)
				var mx = float(tg.get("max_chakra")) if tg.get("max_chakra") != null else 100.0
				var now = float(tg.get("chakra")) if tg.get("chakra") != null else 0.0
				FX.hit_spark(tg.global_position + Vector3.UP * 1.2, Color(0.55, 0.85, 0.5), 0.6)   # emilen chakra
				if k == 5 or now <= mx * 0.15:
					tg.apply_status("sealed", 3.0)   # chakrası çekildi: jutsu yapamaz
					Combat.popup_text(tg.global_position + Vector3.UP * 2.8, "Chakra emildi — jutsu yapamaz!", Color(0.6, 0.9, 0.5))
				elif before > now:
					Combat.popup_text(tg.global_position + Vector3.UP * 2.4, "-%d chakra" % int(before - now), Color(0.55, 0.85, 0.5)))
	tw.tween_callback(drain)
	tw.tween_interval(2.3)
	tw.tween_callback(func():
		VFX.debris(head.global_position, Color(0.5, 0.4, 0.3), 20, 10.0, 0.5)
		head.queue_free())
