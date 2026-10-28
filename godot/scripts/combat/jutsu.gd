extends Node
## Jutsu motoru (autoload "Jutsu"): her tekniğin oynanışı + görsel efekti. Oyuncu ve düşmanlar aynı kodu kullanır.
## caster: Player veya Enemy (team, global_position, face_dir(), model, height, radius)


func _mult(caster: Node3D) -> float:
	return Stats.jutsu_mult(Game.profile) if caster is Player else caster.get("power") if caster.get("power") != null else 1.0


func _elem_bonus(caster: Node3D, el: String) -> float:
	if caster is Player:
		var els: Array = Game.profile.get("elements", [])
		return (1.2 if not els.is_empty() and els[0] == el else 1.0) + Stats.element_bonus(Game.profile, el) + (Stats.skill(Game.profile, "kg") if el in Stats.KG_NATURES else 0.0)
	return 1.0


func _aim(caster: Node3D, target: Node3D) -> Vector3:
	var s = caster.global_position + Vector3.UP * 1.4
	# oyuncu: kilitli hedef yoksa nişangâha (baktığı yere) serbest nişan
	if caster is Player:
		var lt = caster.combat.lock_target if caster.combat else null
		if lt != null and is_instance_valid(lt) and target == lt:
			return (lt.global_position + Vector3.UP * lt.height * 0.5 - s).normalized()
		return (caster.aim_point() - s).normalized()
	if target and is_instance_valid(target):
		return (target.global_position + Vector3.UP * target.height * 0.5 - s).normalized()
	return caster.face_dir()


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
	if not String(Data.jutsu.get(id, {}).get("virtual", "")).begins_with("eye:"):
		Sfx.play("jutsu_cast", caster.global_position, 1.0, 0.75 if caster == Game.player else 0.4)
	var own_id = id   # klan/kekkei genkai jutsularının kendi uygulaması (ClanJutsu) önceliklidir
	id = String(Data.jutsu.get(id, {}).get("impl", id))  # klan jutsuları ortak uygulamayı kullanabilir
	var jd: Dictionary = Data.jutsu.get(id, {})
	if not has_method("j_" + id) and jd.is_empty() and not ClanJutsu.handles(own_id) and not PathJutsu.handles_path(own_id):
		Hud.msg("%s henüz uygulanmadı" % id, Color(1, 0.6, 0.4))
		return
	# destan ölçeği: rütbe × ustalık; bırakış anı (flaş, şok halkası, toz, B+ yavaş çekim + kamera)
	var g = JutsuEngine.grand(caster, jd.merged({"id": id}))
	var tier = int(jd.get("tier", 2))
	var shp = String(jd.get("shape", ""))
	if tier < 3 and JutsuEngine.SIGNATURE_SCALE.has(id):
		tier = 3   # imza element jutsuları B gibi sahnelenir
	var calm = shp in ["transform", "stealth", "sensor", "utility", "heal", "revive", "teleport", "clone", "counter"]
	VFX.release(caster, _cast_origin(caster, id), JutsuEngine.color_of(jd), g, tier if not calm else mini(tier, 2), not calm)
	var prev = VFX.epic
	VFX.epic = g
	if PathJutsu.handles_path(own_id):   # Efsane Yolları teknikleri
		PathJutsu.cast_path(caster, own_id, target)
	elif ClanJutsu.handles(own_id):
		ClanJutsu.cast(caster, own_id, target)
	elif has_method("j_" + id):
		call("j_" + id, caster, target)
	else:
		JutsuEngine.cast(caster, id, target)  # veri güdümlü: şekil × element × kademe
	VFX.epic = prev


# ================================================================== KATON
func j_katon_goukakyuu(c: Node3D, t: Node3D) -> void:
	var m = _mult(c) * _elem_bonus(c, "katon")
	var dir = _aim(c, t)
	var start = _mouth(c) + dir * 0.9
	var g = VFX.epic
	var fcols = [Color(1, 0.82, 0.22, 1), Color(1, 0.55, 0.08, 1), Color(0.95, 0.3, 0.04, 0.9), Color(0.7, 0.1, 0.03, 0)]
	# ısı dalgası halkası + ağızdan püsküren alev
	VFX.shockwave(start, Color(1, 0.7, 0.3), 5.0, 0.35, false)
	VFX.embers(start, Color(1, 0.55, 0.1), 18, 12.0)
	Sfx.play("fire", start, 0.8, 1.4)
	var pr = Projectile.new()
	pr.shooter = c
	pr.vel = dir * 5.0
	pr.radius = 2.4
	pr.life = 3.6
	pr.info = {"dmg": 26.0 * m, "element": "katon", "knock": 14.0, "launch": 6.0, "kind": "heavy", "hitstop": 0.09, "burn": 3.0}
	# 1) nefesle ağzın önünde şişen dev ateş topu (8–12 m), 2) yuvarlanarak ilerler, altında yanık izi bırakır
	var ball = VFX.fireball(5.0)
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
		var gy = Game.ground_height(p.global_position.x, p.global_position.z)
		p.global_position.y = lerpf(p.global_position.y, gy + 2.2 * g, minf(1.0, dt * 3.0))
		st["scar"] -= dt
		if st["scar"] <= 0.0 and st["age"] > 0.3:
			st["scar"] = 0.12
			VFX.cracks(Vector3(p.global_position.x, gy, p.global_position.z), 2.6, Color(0.1, 0.05, 0.02, 0.9), 6.0)
			VFX.puffs(Vector3(p.global_position.x, gy + 0.3, p.global_position.z), {"amount": 4, "life": 0.5, "size": 1.2, "radius": 1.5, "vmin": 1, "vmax": 3,
				"dir": Vector3.UP, "spread": 30.0, "glow": 1.1, "hot": 0.2, "outline_col": Color(0.3, 0.04, 0.02), "colors": fcols})
	pr.on_hit = func(pos: Vector3, _tg: Node3D) -> void:
		var ge = VFX.epic
		VFX.explosion(pos, 1.3, Color(1.0, 0.5, 0.1))
		# göğe yükselen ateş sütunu + kalıcı alevler
		var gp = Vector3(pos.x, Game.ground_height(pos.x, pos.z), pos.z)
		var cm = CylinderMesh.new()
		cm.top_radius = 0.35; cm.bottom_radius = 0.5; cm.height = 1.0; cm.radial_segments = 20; cm.rings = 6
		cm.cap_top = false; cm.cap_bottom = false
		var fm = VFX.mat_fire("fire", 4.0, 1.6, 0.45, 1.15, 0.2, Vector3.UP, true)
		var colm = VFX._mi(cm, fm)
		get_tree().current_scene.add_child(colm)
		colm.global_position = gp
		colm.scale = Vector3(3.5 * ge, 0.5, 3.5 * ge)
		var ct = colm.create_tween()
		ct.tween_property(colm, "scale", Vector3(3.0 * ge, 9.0 * ge, 3.0 * ge), 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		ct.parallel().tween_property(colm, "global_position:y", gp.y + 4.5 * ge, 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		ct.tween_method(func(x: float): fm.set_shader_parameter("alpha_cut", x), 0.0, 1.1, 1.1)
		ct.tween_callback(colm.queue_free)
		VFX.linger(pos, "katon", Color(1, 0.5, 0.1), ge * 1.2, 4.0)
		VFX.shockwave(gp + Vector3.UP * 0.15, Color(1, 0.6, 0.2), 22.0, 0.6)
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


func j_katon_karyuu(c: Node3D, t: Node3D) -> void:
	var m = _mult(c) * _elem_bonus(c, "katon")
	_stream(c, t, 1.6, Color(1, 0.55, 0.1), "katon", 5.0 * m, "fire")


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
		"katon", "yoton", "shakuton", "bakuton":
			var pr: Array = VFX.FIRE_PRESETS[VFX.fire_preset_for(col)]
			pm.color_ramp = FX._gradient([pr[1], pr[2], pr[3], Color(pr[4].r, pr[4].g, pr[4].b, 0)])
			q.material = VFX.mat_puff(1.08, 0.3, pr[4], 0.36, 0.25, 1.2)
		"suiton", "futton", "hyoton":
			pm.color_ramp = FX._gradient([Color(0.95, 0.99, 1, 1), Color(0.5, 0.8, 1.0, 1), Color(0.18, 0.48, 0.98, 0.8), Color(0.1, 0.3, 0.85, 0)])
			q.material = VFX.mat_puff(1.05, 0.0, Color(0.05, 0.18, 0.5), 0.3, 0.25, 1.3)
		"fuuton", "jinton":
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
	pr.vel = Vector3.UP * 14.0 + fd * 6.0
	pr.radius = 1.8
	pr.life = 3.5
	pr.homing = t
	pr.homing_turn = 3.0
	pr.info = {"dmg": 30.0 * m, "element": "suiton", "knock": 16.0, "launch": 9.0, "kind": "heavy", "hitstop": 0.08}
	var wm = VFX.mat_water(Color(0.04, 0.25, 0.75), Color(0.18, 0.52, 0.98), Color(0.6, 0.87, 1.0), Vector3(0, 0, 1), 0.92, 0.7, 0.08)
	var head = VfxSerpent.dragon_head(wm, 4.0)
	pr.add_child(head)
	# ejderha gövdesi: başın izini takip eden kıvrılan su halkaları + sırt yüzgeçleri
	var body = VfxSerpent.new()
	body.head = pr
	body.count = 22
	body.spacing = 1.9
	body.radius = 2.6
	body.mat = wm
	body.fin_mat = VFX.mat_water(Color(0.5, 0.8, 1.0), Color(0.75, 0.93, 1.0), Color(0.95, 1.0, 1.0), Vector3.UP, 0.95, 0.2, 0.0)
	get_tree().current_scene.add_child(body)
	var age = {"t": 0.0}
	pr.on_tick = func(p: Projectile, dt: float) -> void:
		age["t"] += dt
		if age["t"] < 0.85:   # yüksel ve kıvrıl (15–20 m)
			p.vel = (Vector3.UP * 28.0 + fd.cross(Vector3.UP) * cos(age["t"] * 7.0) * 14.0 + fd * 3.0)
			return
		p.homing_turn = 6.0   # sonra hedefe dal
		if not t and p.life < 2.8:
			p.vel = p.vel.lerp(_aim(c, null) * 26.0, 0.05)
		p.vel = p.vel.normalized() * minf(30.0, p.vel.length() + 0.6)
	# gövdeden saçılan köpük
	Projectile.trail(pr, [Color(0.97, 0.99, 1, 1), Color(0.55, 0.82, 1, 0.9), Color(0.15, 0.4, 0.95, 0)], 1.4, 50, 0.6, FX.tex_smoke, false)
	pr.on_hit = func(pos: Vector3, _tg: Node3D) -> void:
		VFX.splash(pos, 3.2)
		VFX.puffs(pos, {"amount": 40, "life": 1.0, "size": 1.6, "radius": 1.5, "vmin": 6, "vmax": 18, "gravity": Vector3(0, -18, 0), "glow": 1.05,
			"outline_col": Color(0.05, 0.18, 0.5), "colors": [Color(0.97, 0.99, 1, 1), Color(0.45, 0.75, 1, 1), Color(0.12, 0.38, 0.9, 0)]})
		VFX.star(pos, Color(0.6, 0.85, 1.0), 4.0, 0.18)
		Combat.hit_sphere(c, pos, 4.5, {"dmg": 12.0 * m, "element": "suiton", "knock": 14.0, "launch": 6.0, "kind": "heavy"}, pr.hit_list)
		Sfx.play("water", pos, 0.8)
		if Game.world: Game.world.env.add_shake(0.6)
	get_tree().current_scene.add_child(pr)
	pr.global_position = start


func j_suiton_suijinheki(c: Node3D, _t: Node3D) -> void:
	Sfx.play("water", c.global_position, 0.9)
	var dome = VFX._mi(VFX._sphere(0.5, 28, 14), VFX.mat_water(Color(0.05, 0.3, 0.8), Color(0.25, 0.6, 1.0), Color(0.7, 0.92, 1.0), Vector3.UP, 0.62, 0.8, 0.1))
	c.add_child(dome)
	dome.position = Vector3(0, 1.0, 0)
	dome.scale = Vector3(1, 0.2, 1)
	dome.create_tween().tween_property(dome, "scale", Vector3(7.5, 6.0, 7.5), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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
		e.emitting = false
		dome.queue_free()
		get_tree().create_timer(1.0).timeout.connect(e.queue_free))
	if c is Player:
		c.combat.invuln = 0.6


func j_suiton_suikoudan(c: Node3D, t: Node3D) -> void:
	var m = _mult(c) * _elem_bonus(c, "suiton")
	var pr = Projectile.new()
	pr.shooter = c
	pr.vel = _aim(c, t) * 26.0
	pr.radius = 1.2
	pr.life = 3.0
	pr.homing = t
	pr.homing_turn = 5.0
	pr.info = {"dmg": 34.0 * m, "element": "suiton", "knock": 14.0, "launch": 5.0, "kind": "heavy", "hitstop": 0.07}
	pr.add_child(JutsuEngine.shape_mesh("shark", Color(0.2, 0.55, 1.0), 1.6, "suiton"))
	Projectile.trail(pr, [Color(0.97, 0.99, 1, 1), Color(0.5, 0.8, 1, 0.9), Color(0.15, 0.4, 0.95, 0)], 1.1, 40, 0.5, FX.tex_smoke, false)
	pr.on_hit = func(pos: Vector3, _tg: Node3D) -> void:
		VFX.splash(pos, 2.4)
		VFX.star(pos, Color(0.6, 0.85, 1.0), 3.0, 0.16)
		Sfx.play("water", pos)
	get_tree().current_scene.add_child(pr)
	pr.global_position = _hand(c)
	VFX.element_trail(pr, "suiton", Color(0.3, 0.6, 1), 1.6)


# ================================================================== FUUTON
func j_fuuton_daitoppa(c: Node3D, t: Node3D) -> void:
	var m = _mult(c) * _elem_bonus(c, "fuuton")
	var d = _aim(c, t)
	d.y = clampf(d.y, -0.2, 0.3)
	Sfx.play("wind", c.global_position)
	var mo = _mouth(c)
	FX.burst(mo + d, {"amount": 70, "life": 0.5, "tex": FX.tex_spark, "size": 3.0, "vmin": 25, "vmax": 40,
		"dir": d, "spread": 18.0, "radius": 0.8, "damp": 2.0, "colors": [Color(1, 1, 1, 0.9), Color(0.75, 1.0, 0.85, 0.5), Color(0.7, 1, 0.9, 0)]})
	_wind_cone(mo + d * 0.5, d, 14.0, 4.5, 0.45)
	VFX.puffs(mo + d * 9.0, {"amount": 14, "life": 0.6, "size": 2.2, "radius": 2.0, "vmin": 10, "vmax": 18, "dir": d, "spread": 25.0, "damp": 3.0,
		"outline_col": Color(0.4, 0.55, 0.5), "colors": [Color(0.95, 1, 0.97, 1), Color(0.85, 0.98, 0.92, 0.6), Color(0.8, 0.95, 0.9, 0)]})
	if c is Player:
		VFX.screen_lines(0.35, 0.7, Color(0.92, 1.0, 0.96))
	for k in 5:
		var pos = c.global_position + Vector3.UP * 1.2 + d * (2.0 + k * 2.4)
		FX.ring(pos, Color(0.8, 1.0, 0.9), 3.0 + k * 1.2, 0.3, true, d)
		Combat.hit_sphere(c, pos, 1.5 + k * 0.5, {"dmg": 12.0 * m, "element": "fuuton", "knock": 22.0, "launch": 3.0, "kind": "heavy", "dir": d, "hitstop": 0.05})


## Ağızdan/elden ileri fırlayan saydam, kırılan hava konisi
func _wind_cone(from: Vector3, d: Vector3, length: float, width: float, dur: float) -> void:
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
				VFX.shockwave(pos, Color(0.9, 1, 0.95), 3.5, 0.22, false)
				VFX.star(pos, Color(0.85, 1.0, 0.92), 1.6, 0.12)
			get_tree().current_scene.add_child(pr)
			pr.global_position = _mouth(c)
			VFX.element_trail(pr, "fuuton", Color(0.8, 1, 0.9), 0.9))


func j_fuuton_rasenshuriken(c: Node3D, t: Node3D) -> void:
	var m = _mult(c) * _elem_bonus(c, "fuuton")
	var pr = Projectile.new()
	pr.shooter = c
	pr.vel = _aim(c, t) * 26.0
	pr.radius = 1.6
	pr.life = 3.0
	pr.homing = t
	pr.homing_turn = 2.0
	pr.info = {"dmg": 20.0 * m, "element": "fuuton", "knock": 4.0, "kind": "heavy", "hitstop": 0.05}
	pr.add_child(VFX.rasengan(1.5))
	# dört kollu rüzgar bıçağı diski (kırılan hava + beyaz çizgiler)
	var disc = VFX._mi(VFX._sphere(0.5, 32, 8), VFX.mat_wind(Color(0.85, 0.97, 1.0), 14.0, 4.0, Vector3.UP, 0.95))
	disc.scale = Vector3(6.0, 0.22, 6.0)
	pr.add_child(disc)
	for k in 4:
		var bl = VFX._mi(VFX._sphere(0.5, 12, 6), VFX.mat_spiral(Color(1, 1, 1), Color(0.55, 0.85, 1.0), 2.0, 1.0, 10.0, 1.4))
		bl.scale = Vector3(0.7, 0.12, 3.0)
		bl.position = Vector3(cos(k * PI * 0.5), 0, sin(k * PI * 0.5)) * 2.1
		bl.rotation.y = -k * PI * 0.5 + 0.5
		pr.add_child(bl)
	pr.spin = Vector3(0, 25, 0)
	Sfx.play("rasengan", c.global_position, 1.4)
	pr.on_hit = func(pos: Vector3, _tg: Node3D) -> void:
		var dome = Node3D.new()
		dome.add_child(VFX.wind_ball(1.0))
		var core2 = VFX._mi(VFX._sphere(0.5, 28, 14), VFX.mat_spiral(Color(1, 1, 1), Color(0.3, 0.6, 1.0), 8.0, 4.0, 12.0, 1.3))
		core2.scale = Vector3.ONE * 0.75
		dome.add_child(core2)
		get_tree().current_scene.add_child(dome)
		dome.global_position = pos
		dome.scale = Vector3.ONE * 2.0
		VFX.star(pos, Color(0.7, 0.9, 1.0), 9.0, 0.25)
		VFX.shockwave(Vector3(pos.x, Game.ground_height(pos.x, pos.z) + 0.1, pos.z), Color(0.8, 0.95, 1.0), 26.0, 0.6)
		VFX.cracks(pos, 8.0)
		VFX.debris(pos, Color(0.5, 0.42, 0.32), 20, 16.0, 0.5)
		VFX.screen_lines(0.6, 1.0)
		var tw = dome.create_tween()
		tw.tween_property(dome, "scale", Vector3.ONE * 12.0, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		for i in 8:
			tw.tween_callback(func():
				Combat.hit_sphere(c, pos, 6.0, {"dmg": 9.0 * m, "element": "fuuton", "knock": 1.0, "kind": "light", "hitstop": 0.02}))
			tw.tween_interval(0.12)
		tw.tween_property(dome, "scale", Vector3.ONE * 0.1, 0.25)
		tw.tween_callback(dome.queue_free)
		FX.light(pos, Color(0.5, 0.8, 1.0), 10.0, 30.0, 1.4)
		Sfx.play("wind", pos, 0.7)
		if Game.world:
			Game.world.env.add_shake(1.0)
			Game.world.env.screen_flash(0.3)
	get_tree().current_scene.add_child(pr)
	pr.global_position = _hand(c) + Vector3.UP * 0.5
	VFX.element_trail(pr, "fuuton", Color(0.7, 0.9, 1), 2.0)


# ================================================================== DOTON
func j_doton_doryuheki(c: Node3D, _t: Node3D) -> void:
	var d = _aim_flat(c, _t)
	var pos = c.global_position + d * 3.5
	pos.y = Game.ground_height(pos.x, pos.z)
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
	# köpek başı kabartmaları (düşman tarafı -Z ve arka yüz)
	for side in [-1.0, 1.0]:
		for fx in [-3.8, 0.0, 3.8]:
			var fc = Color(0.5, 0.39, 0.28)
			var z = side * 1.05
			b.add("sphere", Vector3(fx, 4.3, z), Vector3(2.6, 2.4, 1.0), fc)                       # kafa
			b.add("box", Vector3(fx, 3.5, z + side * 0.55), Vector3(1.5, 0.9, 1.1), fc.darkened(0.06))   # burun-ağız
			b.add("sphere", Vector3(fx, 3.85, z + side * 1.1), Vector3(0.45, 0.32, 0.3), Color(0.12, 0.08, 0.06))   # burun ucu
			b.add("box", Vector3(fx, 3.05, z + side * 0.75), Vector3(1.3, 0.12, 0.8), Color(0.14, 0.09, 0.07))     # ağız çizgisi
			for ex in [-0.6, 0.6]:
				b.add("box", Vector3(fx + ex, 4.75, z + side * 0.42), Vector3(0.45, 0.16, 0.2), Color(0.1, 0.07, 0.05), Vector3(0, 0, ex * 25))   # kaş-göz
				b.add("cone", Vector3(fx + ex * 1.5, 5.55, z), Vector3(0.5, 1.1, 0.45), fc, Vector3(0, 0, -ex * 45), 5)   # kulak
			for tx in [-0.45, -0.15, 0.15, 0.45]:
				b.add("cone", Vector3(fx + tx, 2.85, z + side * 0.9), Vector3(0.16, 0.42, 0.16), Color(0.9, 0.86, 0.76), Vector3(180, 0, 0), 4)
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(Props.toon())
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
			p.y = Game.ground_height(p.x, p.z)
			var sp = MeshInstance3D.new()
			var b = MB.new()
			for s in 3:
				b.add("cone", Vector3(randf_range(-0.6, 0.6), 1.2, randf_range(-0.6, 0.6)), Vector3(0.9, 2.6 + randf() * 1.2, 0.9), Color(0.5, 0.42, 0.32), Vector3(randf_range(-15, 15), 0, randf_range(-15, 15)), 6)
			sp.mesh = b.build(Props.toon())
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
	pos.y = Game.ground_height(pos.x, pos.z) + 0.05
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
	c.model.add_child(hand)
	hand.position = Vector3(0.35, 1.15, -0.55)
	hand.add_child(VFX.lightning_ball(0.75, col_edge))
	var arcs = Arcs.new()
	arcs.color = col_edge
	arcs.radius = 1.8
	arcs.count = 4
	arcs.width = 0.035
	hand.add_child(arcs)
	var l = OmniLight3D.new()
	l.light_color = col_edge; l.light_energy = 1.2; l.omni_range = 5.0
	hand.add_child(l)
	Sfx.play(snd, c.global_position)
	return hand


func j_raiton_chidori(c: Node3D, t: Node3D) -> void:
	var m = _mult(c) * _elem_bonus(c, "raiton")
	var hand = _lightning_ball(c, Color(0.9, 0.95, 1.0), Color(0.45, 0.7, 1.0), "chidori")
	_hand_dash(c, t, hand, 0.55, 30.0, {"dmg": 34.0 * m, "element": "raiton", "knock": 14.0, "launch": 3.0, "kind": "heavy", "hitstop": 0.12, "stun": 1.0},
		Color(0.5, 0.75, 1.0))


func j_rasengan(c: Node3D, t: Node3D) -> void:
	var m = _mult(c)
	var hand: Node3D = Node3D.new()
	c.model.add_child(hand)
	hand.position = Vector3(0.35, 1.15, -0.55)
	var ras = VFX.rasengan(0.95)
	hand.add_child(ras)
	ras.scale = Vector3.ONE * 0.1
	ras.create_tween().tween_property(ras, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	FX.aura(hand, Color(0.5, 0.8, 1.0), 0.4, Vector3.ZERO, 0.0)
	Sfx.play("rasengan", c.global_position)
	_hand_dash(c, t, hand, 0.6, 26.0, {"dmg": 42.0 * m, "knock": 32.0, "launch": 9.0, "kind": "heavy", "hitstop": 0.16},
		Color(0.4, 0.7, 1.0), true)


## El tekniği: hazırlan, hedefe hücum et, çarpınca büyük patlama
func _hand_dash(c: Node3D, t: Node3D, hand: Node3D, charge: float, speed: float, info: Dictionary, col: Color, grind := false) -> void:
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
			if not state.has("trail") and is_instance_valid(hand):
				state["trail"] = VFX.trail(hand, 0.7, Color(1, 1, 1), col.lightened(0.3), col, 16, 0.6)
				if c is Player:
					VFX.screen_lines(0.5, 0.6, col.lightened(0.5))
			FX.burst(c.global_position + Vector3.UP, {"amount": 4, "life": 0.3, "tex": FX.tex_spark, "size": 1.2, "vmin": 1, "vmax": 3, "colors": [Color(1, 1, 1, 0.8), Color(col.r, col.g, col.b, 0)]})
			var pt = c.global_position + Vector3.UP * 1.1 + d * 1.0
			var hits = Combat.hit_sphere(c, pt, 1.0, info)
			if not hits.is_empty() or state["t"] > 0.6:
				state["done"] = true
				if c is Player:
					c.combat.action = ""
				c.velocity = Vector3.ZERO
				if not hits.is_empty():
					VFX.star(pt, col.lightened(0.2), 7.0, 0.25)
					VFX.shockwave(pt, col.lightened(0.3), 11.0, 0.4, false)
					VFX.shockwave(Vector3(pt.x, Game.ground_height(pt.x, pt.z) + 0.1, pt.z), col, 14.0, 0.5)
					VFX.cracks(pt, 5.0)
					VFX.debris(pt, Color(0.5, 0.42, 0.32), 12, 12.0, 0.4)
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
		Buffs.add("raiton_armor", 20.0, {"speed": 1.35, "melee": 1.4, "armor": 0.6})
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
	to.y = Game.ground_height(to.x, to.z)
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
				c.hp = minf(c.max_hp, c.hp + 4.0 * Stats.jutsu_mult(Game.profile))
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
	return Vector3(p.x, Game.ground_height(p.x, p.z), p.z)


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
	# dönen chakra kubbesi: beyaz-mavi spiral kabuk + iç çekirdek + yerde şok dalgası ve toz halkası
	var dome = Node3D.new()
	c.add_child(dome)
	dome.position = Vector3(0, 0.8, 0)
	dome.add_child(VFX._mi(VFX._sphere(0.5, 28, 14), VFX.mat_spiral(Color(1, 1, 1), Color(0.55, 0.75, 1.0), 6.0, 3.0, 16.0, 1.7, Vector3.UP)))
	var inner = VFX._mi(VFX._sphere(0.5, 20, 10), VFX.mat_wind(Color(0.85, 0.92, 1.0), 6.0, 10.0, Vector3.UP))
	inner.scale = Vector3.ONE * 0.85
	dome.add_child(inner)
	dome.scale = Vector3.ONE * 0.3
	var tw = dome.create_tween()
	tw.tween_property(dome, "scale", Vector3(6.5, 5.0, 6.5), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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
		dome.rotation.y += 1.9
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
			c.combat.action = ""
		var tw2 = dome.create_tween()
		tw2.tween_property(dome, "scale", Vector3.ONE * 0.1, 0.2)
		tw2.tween_callback(dome.queue_free))


# ---------------------------------------------------------------- Nara
func _shadow_line(c: Node3D, t: Node3D, dur: float) -> void:
	# yerde sürünerek uzanan, kenarları dalgalanan kalın gölge şeridi (araziye yapışık); iki uçta gölge göleti
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.02, 0.01, 0.04, 0.95)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var rim = StandardMaterial3D.new()
	rim.albedo_color = Color(0.45, 0.25, 0.75, 0.55)
	rim.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rim.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	rim.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rim.cull_mode = BaseMaterial3D.CULL_DISABLED
	var im = ImmediateMesh.new()
	var mi = MeshInstance3D.new()
	mi.mesh = im
	mi.top_level = true
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(mi)
	var pools = []
	for k in 2:
		var pm = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 1.0; cm.bottom_radius = 1.0; cm.height = 0.02; cm.radial_segments = 24
		pm.mesh = cm
		pm.material_override = mat
		get_tree().current_scene.add_child(pm)
		pools.append(pm)
	var upd = func(_i):
		if not is_instance_valid(c) or not is_instance_valid(t):
			return
		var a = _ground(c.global_position)
		var b = _ground(t.global_position)
		var grow = clampf(_i * 0.05 / 0.45, 0.05, 1.0)
		var full = maxf(0.2, Vector2(b.x - a.x, b.z - a.z).length())
		var fwd = Vector3(b.x - a.x, 0, b.z - a.z).normalized() if full > 0.3 else Vector3.FORWARD
		var side = fwd.cross(Vector3.UP)
		im.clear_surfaces()
		for pass_i in 2:
			im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, mat if pass_i == 0 else rim)
			var n = 28
			for k in n + 1:
				var u = float(k) / n
				var p = a + fwd * full * grow * u
				p.y = Game.ground_height(p.x, p.z) + 0.06 + pass_i * 0.005
				var w = (0.55 + 0.25 * sin(u * 18.0 - _i * 0.6) + 0.35 * (1.0 - u)) * (1.3 if pass_i == 1 else 1.0)
				im.surface_add_vertex(p + side * w)
				im.surface_add_vertex(p - side * w)
			im.surface_end()
		pools[0].global_position = a + Vector3.UP * 0.05
		pools[0].scale = Vector3(1.3, 1, 1.3)
		pools[1].global_position = a + fwd * full * grow + Vector3.UP * 0.05
		pools[1].scale = Vector3.ONE * (1.6 * grow) + Vector3(0, 1.0 - 1.6 * grow, 0)
	upd.call(0)
	_ticks(int(dur / 0.05), 0.05, upd, func():
		mi.queue_free()
		for pm in pools:
			pm.queue_free())


func j_kagemane(c: Node3D, t: Node3D) -> void:
	if t == null or c.global_position.distance_to(t.global_position) > 22.0:
		Hud.msg("Kagemane: gölgen en fazla 22 metreye uzanır", Color(0.8, 0.8, 0.9))
		return
	Sfx.play("genjutsu", c.global_position, 0.6)
	_shadow_line(c, t, 4.0)
	if t.has_method("apply_status"):
		t.apply_status("bind", 4.0)
	Combat.popup_text(t.global_position + Vector3.UP * 2.4, "Kagemane: başarılı!", Color(0.7, 0.7, 0.9))


func j_kage_kubi(c: Node3D, t: Node3D) -> void:
	var m = _mult(c)
	if t == null or c.global_position.distance_to(t.global_position) > 22.0:
		Hud.msg("Kage Kubi Shibari: hedef çok uzak", Color(0.8, 0.8, 0.9))
		return
	_shadow_line(c, t, 4.0)
	if t.has_method("apply_status"):
		t.apply_status("bind", 4.0)
	Sfx.play("genjutsu", c.global_position, 0.5)
	# gölge elleri hedefin bedenine tırmanıp boynunu sarar
	for k in 4:
		var hand = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 0.06; cm.bottom_radius = 0.16; cm.height = 1.0; cm.radial_segments = 8
		hand.mesh = cm
		var hm = StandardMaterial3D.new()
		hm.albedo_color = Color(0.02, 0.01, 0.04)
		hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		hand.material_override = hm
		t.add_child(hand)
		var a2 = k * TAU / 4.0
		var off = Vector3(cos(a2), 0, sin(a2)) * (t.radius + 0.12)
		hand.position = off + Vector3.UP * 0.1
		hand.scale = Vector3(1, 0.05, 1)
		var tw = hand.create_tween()
		tw.tween_interval(0.3 + k * 0.08)
		tw.tween_property(hand, "scale", Vector3(1, t.height * 0.85, 1), 0.6).set_trans(Tween.TRANS_CUBIC)
		tw.parallel().tween_property(hand, "position:y", t.height * 0.45, 0.6)
		tw.parallel().tween_property(hand, "rotation:z", 0.25 * (1 if k % 2 else -1), 0.6)
		tw.tween_interval(2.8)
		tw.tween_callback(hand.queue_free)
	_ticks(8, 0.5, func(_i):
		if is_instance_valid(t) and not t.is_dead():
			FX.burst(t.global_position + Vector3.UP * 1.5, {"amount": 8, "life": 0.5, "tex": FX.tex_smoke, "add": false, "size": 0.6, "vmin": 0.5, "vmax": 1.5, "colors": [Color(0.05, 0.03, 0.08, 0.9), Color(0.05, 0.03, 0.08, 0)]})
			Combat.hit_sphere(c, t.global_position + Vector3.UP, 1.0, {"dmg": 6.0 * m, "knock": 0.0, "kind": "light"}))


# ---------------------------------------------------------------- Akimichi
func j_baika(c: Node3D, _t: Node3D) -> void:
	if not c is Player:
		return
	c.combat.modes.set_size(3.0, 20.0)
	FX.smoke_puff(c.global_position + Vector3.UP * 2.0, 2.2, 24)
	Buffs.add("baika", 20.0, {"melee": 1.9, "speed": 0.85, "armor": 0.7, "reach": 2.2})
	Hud.msg("Baika no Jutsu! (20 sn dev)", Color(1, 0.8, 0.5))


func j_nikudan(c: Node3D, t: Node3D) -> void:
	var m = _mult(c)
	var ball = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 1.6; sm.height = 3.2
	sm.material = Props.toon_color(Color(0.85, 0.62, 0.45), 0.4)
	ball.mesh = sm
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


func j_gatsuga(c: Node3D, t: Node3D) -> void:
	var m = _mult(c)
	var drill = gatsuga_drill(1.0)
	c.add_child(drill)
	drill.position = Vector3(0, 1.0, 0)
	Sfx.play("wind", c.global_position, 1.6)
	var hit = []
	for n in get_tree().get_nodes_in_group("ninken"):
		n.gatsuga(t)
	_dash(c, t, 0.9, 26.0, func(pt):
		c.model.rotation.y += 1.2
		for h in Combat.hit_sphere(c, pt, 1.7, {"dmg": 20.0 * m, "knock": 14.0, "launch": 6.0, "kind": "heavy", "hitstop": 0.05}, hit):
			hit.append(h), func(): drill.queue_free())


## Gatsūga matkabı: yatay dönen gri-beyaz rüzgâr hortumu (iki kat koni) + uç kıvılcımı; karakteri içine alır
func gatsuga_drill(size: float) -> Node3D:
	var root = Node3D.new()
	for k in 2:
		var cm = CylinderMesh.new()
		cm.top_radius = 0.12; cm.bottom_radius = 1.15 - k * 0.3; cm.height = 3.2 - k * 0.6; cm.radial_segments = 20; cm.rings = 6
		cm.cap_top = false; cm.cap_bottom = false
		var mi = VFX._mi(cm, Props.toon_color(Color(0.58, 0.54, 0.5), 0.5) if k == 1 else VFX.mat_wind(Color(1, 1, 1), 16.0, 6.0, Vector3.UP, 1.0))   # içte opak gri dönen gövde, dışta beyaz rüzgâr çizgileri
		mi.rotation_degrees = Vector3(-90, 0, 0)   # sivri uç ileri (-Z)
		mi.position = Vector3(0, 0, -0.4)
		root.add_child(mi)
		var sp = mi.create_tween().set_loops()
		sp.tween_property(mi, "rotation:y", TAU * (1 if k == 0 else -1), 0.25 - k * 0.08).from(0.0)
	root.scale = Vector3.ONE * size * 1.3
	return root


# ---------------------------------------------------------------- Yamanaka
func j_shintenshin(c: Node3D, t: Node3D) -> void:
	if t == null or not t is Enemy or t is Boss:
		Hud.msg("Shintenshin: sıradan bir düşmanı hedefle (boss'lar dirençli)", Color(0.8, 0.7, 1))
		return
	Sfx.play("genjutsu", t.global_position, 1.2)
	FX.ring(t.global_position + Vector3.UP, Color(0.75, 0.5, 1.0), 4.0, 0.4, false)
	# ruh bedenden çıkar: mor top hedefe uçar, oyuncunun bedeni yere çöker (anime Shintenshin)
	var cj = ClanJutsu.get_inst()
	cj._mind_orb(c, t, func(): if is_instance_valid(t): cj._mind_halo(t, 12.0))
	if c.get("model"):
		c.model.play("sit", 0.2)
	t.team = "player"
	t.target = null
	t.state = "chase"
	var a = FX.aura(t, Color(0.7, 0.45, 1.0), 0.9, Vector3(0, 0.9, 0), 0.0)
	t.nameplate.modulate = Color(0.75, 0.6, 1.0)
	Combat.popup_text(t.global_position + Vector3.UP * 2.6, "Zihin ele geçirildi!", Color(0.8, 0.65, 1))
	get_tree().create_timer(12.0).timeout.connect(func():
		if is_instance_valid(t) and not t.dead:
			t.team = "enemy"
			t.target = null
			t.nameplate.modulate = Color(1, 0.6, 0.55)
			Combat.popup_text(t.global_position + Vector3.UP * 2.6, "Kendine geldi", Color(1, 0.7, 0.6))
		if is_instance_valid(a):
			a.emitting = false
			get_tree().create_timer(1.0).timeout.connect(a.queue_free))


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
	var m = _mult(c)
	var center = _ground(_aim_ground(c, t, 8.0))
	Sfx.play("clink", center, 0.6)
	var b = MB.new()
	for k in 10:
		var a = k * TAU / 10.0
		b.add("cone", Vector3(cos(a), 0, sin(a)) * 1.6 + Vector3(0, 1.4, 0), Vector3(0.7, 3.0 + randf(), 0.7), Color(0.75, 0.92, 1.0), Vector3(cos(a) * 25, 0, -sin(a) * 25), 5)
	b.add("sphere", Vector3(0, 1.0, 0), Vector3(2.0, 2.6, 2.0), Color(0.82, 0.95, 1.0), Vector3.ZERO, 8)
	var ice = MeshInstance3D.new()
	ice.mesh = b.build(Props.toon())
	get_tree().current_scene.add_child(ice)
	ice.global_position = center - Vector3(0, 3, 0)
	var tw = ice.create_tween()
	tw.tween_property(ice, "global_position:y", center.y, 0.15)
	tw.tween_interval(2.4)
	tw.tween_property(ice, "scale", Vector3.ONE * 0.05, 0.4)
	tw.tween_callback(ice.queue_free)
	# önce dondur (donmuş hedef blok yapamaz), sonra hasar
	for f in get_tree().get_nodes_in_group("fighters"):
		if Combat.hostile(c, f) and not f.is_dead() and Combat.capsule_hit(center + Vector3.UP, f, 2.6) and f.has_method("apply_status"):
			f.apply_status("stun", 2.5)
	for h in Combat.hit_sphere(c, center + Vector3.UP, 2.6, {"dmg": 22.0 * m, "knock": 0.0, "kind": "light", "element": "hyoton", "hitstop": 0.06}):
		Combat.popup_text(h.global_position + Vector3.UP * 2.4, "DONDU!", Color(0.7, 0.9, 1))
	FX.burst(center + Vector3.UP, {"amount": 30, "life": 0.6, "tex": FX.tex_spark, "size": 1.0, "vmin": 5, "vmax": 12, "colors": [Color(1, 1, 1, 1), Color(0.7, 0.9, 1, 0)]})


# ---------------------------------------------------------------- Kaguya
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
		b.add("cyl", Vector3.ZERO, Vector3(0.2, 0.7, 0.2), Color(0.97, 0.95, 0.86), Vector3(90, 0, 0), 8)
		b.add("cone", Vector3(0, 0, -0.5), Vector3(0.2, 0.35, 0.2), Color(0.97, 0.95, 0.86), Vector3(-90, 0, 0), 8)
		b.add("sphere", Vector3(0, 0, 0.36), Vector3(0.28, 0.28, 0.24), Color(0.92, 0.9, 0.8), Vector3.ZERO, 8)
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
		Buffs.add("bone_armor", 20.0, {"armor": 0.5, "melee": 1.15})
	get_tree().create_timer(20.0).timeout.connect(func():
		if is_instance_valid(spikes):
			spikes.queue_free())


# ---------------------------------------------------------------- Uzumaki
func j_chakra_chains(c: Node3D, t: Node3D) -> void:
	var m = _mult(c)
	if t == null or c.global_position.distance_to(t.global_position) > 28.0:
		Hud.msg("Chakra zincirleri: hedef çok uzak", Color(1, 0.85, 0.4))
		return
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	var center = _ground(t.global_position)
	var gold = JutsuEngine.glow_mat(Color(1.0, 0.82, 0.3), 1.0)
	var back = c.global_position + Vector3.UP * 1.3 - (c.face_dir() if c.has_method("face_dir") else Vector3.FORWARD) * 0.3
	for k in 5:
		var a = k * TAU / 5.0 + 0.4
		var base = back + Vector3(cos(a), sin(a) * 0.6, 0) * 0.3 if k < 3 else center + Vector3(cos(a), 0, sin(a)) * 3.5
		var top = t.global_position + Vector3.UP * (0.8 + k * 0.25)
		var L = base.distance_to(top)
		var n = int(L / 0.38)
		var ch = Node3D.new()
		root.add_child(ch)
		for j in n:
			var link = MeshInstance3D.new()
			var tm = TorusMesh.new()
			tm.inner_radius = 0.11; tm.outer_radius = 0.19; tm.rings = 10; tm.ring_segments = 6
			link.mesh = tm
			link.material_override = gold
			ch.add_child(link)
			var u = float(j) / n
			var dir = (top - base).normalized()
			link.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT) * Basis(Vector3.BACK, PI * 0.5 * (j % 2)) * Basis(Vector3.RIGHT, PI * 0.5), base.lerp(top, u) + Vector3.UP * sin(u * PI) * 0.4)
			link.scale = Vector3.ONE * 0.01
			var tw = link.create_tween()
			tw.tween_interval(u * 0.25)
			tw.tween_property(link, "scale", Vector3.ONE, 0.08)
	VFX.shockwave(t.global_position + Vector3.UP * 1.2, Color(1, 0.8, 0.3), 3.0, 0.3, false)
	FX.aura(t, Color(1.0, 0.8, 0.3), 0.9, Vector3(0, 1.0, 0), 5.0)
	Sfx.play("clink", center, 0.7)
	if t.has_method("apply_status"):
		t.apply_status("bind", 5.0)
	Combat.hit_sphere(c, t.global_position + Vector3.UP, 1.4, {"dmg": 12.0 * m, "knock": 0.0, "kind": "light"})
	Combat.popup_text(t.global_position + Vector3.UP * 2.6, "Mühürlendi!", Color(1, 0.85, 0.4))
	get_tree().create_timer(5.0).timeout.connect(root.queue_free)


# ---------------------------------------------------------------- Hozuki
func j_suika(c: Node3D, _t: Node3D) -> void:
	if c is Player:
		Buffs.add("suika", 15.0, {})
		var a = FX.aura(c, Color(0.35, 0.65, 1.0), 1.0, Vector3(0, 0.9, 0), 0.0)
		var shell = MeshInstance3D.new()
		shell.mesh = VFX._sphere(0.5, 20, 10)
		shell.material_override = VFX.mat_water(Color(0.1, 0.35, 0.85), Color(0.3, 0.6, 1.0), Color(0.75, 0.92, 1.0), Vector3.UP, 0.45, 0.6, 0.12)
		shell.scale = Vector3(0.9, 2.0, 0.9)
		c.add_child(shell)
		shell.position = Vector3(0, 0.95, 0)
		FX.burst(c.global_position + Vector3.UP, {"amount": 40, "life": 0.7, "tex": FX.tex_smoke, "add": false, "size": 0.5, "vmin": 2, "vmax": 5, "gravity": Vector3(0, -10, 0), "colors": [Color(0.85, 0.95, 1, 1), Color(0.3, 0.6, 1, 0)]})
		get_tree().create_timer(15.0).timeout.connect(func(): if is_instance_valid(shell): shell.queue_free())
		get_tree().create_timer(15.0).timeout.connect(func():
			if is_instance_valid(a):
				a.emitting = false
				get_tree().create_timer(1.0).timeout.connect(a.queue_free))
	Sfx.play("water", c.global_position, 1.2)
	Hud.msg("Suika no Jutsu: 15 sn boyunca darbeler içinden geçer (chakra harcar)", Color(0.5, 0.75, 1))


func j_water_gun(c: Node3D, t: Node3D) -> void:
	var m = _mult(c)
	var pr = Projectile.new()
	pr.shooter = c
	pr.vel = _aim(c, t) * 70.0
	pr.radius = 0.5
	pr.info = {"dmg": 14.0 * m, "knock": 5.0, "kind": "light", "element": "suiton", "hitstop": 0.03}
	pr.add_child(VFX.water_ball(1.0))
	VFX.trail(pr, 0.6, Color(0.9, 0.97, 1.0), Color(0.3, 0.6, 1.0), Color(0.1, 0.35, 0.9, 0.0), 14)
	VFX.shockwave(_hand(c), Color(0.6, 0.85, 1.0), 2.5, 0.25, false, _aim(c, t))
	Projectile.trail(pr, [Color(0.85, 0.95, 1, 0.9), Color(0.3, 0.6, 1, 0)], 0.35, 30, 0.25, FX.tex_smoke, false)
	pr.on_hit = func(pos: Vector3, _tg: Node3D) -> void:
		FX.burst(pos, {"amount": 14, "life": 0.5, "tex": FX.tex_smoke, "add": false, "size": 0.6, "vmin": 2, "vmax": 6, "gravity": Vector3(0, -12, 0), "colors": [Color(0.9, 0.97, 1, 1), Color(0.3, 0.6, 1, 0)]})
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
	var sky = pos + Vector3.UP * 11.0 - _aim_flat(c, t) * 4.0
	var col = Color(0.55, 0.75, 1.0)
	Sfx.play("thunder", sky, 0.6)
	if Game.world:
		Game.world.env.set_tint(Color(0.05, 0.05, 0.15, 0.35))
	# 1) bulut toplanması: dönen koyu topaklar + içinde çakan şimşekler
	VFX.puffs(sky, {"amount": 46, "life": 2.4, "size": 5.0, "radius": 8.0, "vmin": 0.5, "vmax": 2.0, "gravity": Vector3.ZERO, "spin": 30.0, "tangent": 4.0,
		"outline_col": Color(0.03, 0.03, 0.08), "shade": 0.4, "explosive": 0.4,
		"colors": [Color(0.15, 0.15, 0.22, 0), Color(0.16, 0.16, 0.24, 1), Color(0.22, 0.22, 0.32, 1), Color(0.25, 0.25, 0.35, 0)]})
	for k in 6:
		get_tree().create_timer(0.2 + k * 0.18).timeout.connect(func():
			var a = sky + Vector3(randf_range(-8, 8), randf_range(-1, 1), randf_range(-8, 8))
			VFX.bolt(a, a + Vector3(randf_range(-6, 6), randf_range(-3, 0), randf_range(-6, 6)), col, 0.25, 0.15, 2)
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
				head.look_at(nxt, Vector3.UP if absf((nxt - p).normalized().y) < 0.98 else Vector3.RIGHT), 0.0, 1.0, 0.45)
		tw.tween_callback(func():
			VFX.bolt(sky, pos, Color(0.85, 0.95, 1.0), 1.4, 0.4, 6)
			VFX.star(pos + Vector3.UP * 2.0, Color(0.75, 0.9, 1.0), 16.0, 0.35)
			VFX.shockwave(pos + Vector3.UP * 0.2, col, 34.0, 0.7)
			VFX.shockwave(pos + Vector3.UP * 3.0, Color(1, 1, 1), 20.0, 0.4, false)
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
	# yükselen su sütunu
	var cm = CylinderMesh.new()
	cm.top_radius = 5.0; cm.bottom_radius = 8.5; cm.height = 1.0; cm.radial_segments = 32; cm.rings = 4
	var wm = VFX.mat_water(Color(0.04, 0.25, 0.75), Color(0.18, 0.52, 0.98), Color(0.65, 0.9, 1.0), Vector3.UP, 0.92, 0.9, 0.15)
	var col_ = VFX._mi(cm, wm)
	get_tree().current_scene.add_child(col_)
	col_.global_position = start
	col_.scale = Vector3(1, 0.1, 1)
	var tw = col_.create_tween()
	tw.tween_property(col_, "scale", Vector3(1.4, 40.0, 1.4), 0.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(col_, "global_position:y", start.y + 20.0, 0.6)
	tw.tween_interval(0.3)
	tw.tween_property(col_, "scale", Vector3(3.0, 0.1, 3.0), 0.5).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(col_, "global_position:y", start.y, 0.5)
	tw.tween_callback(col_.queue_free)
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


## Shinra Tensei: her şeyi dışarı iten itme dalgası
func j_shinra_tensei(c: Node3D, _t: Node3D) -> void:
	var pos = c.global_position + Vector3.UP
	var r = 16.0
	var wb = VFX.wind_ball(1.0)
	get_tree().current_scene.add_child(wb)
	wb.global_position = pos
	var tw = wb.create_tween()
	tw.tween_property(wb, "scale", Vector3.ONE * r * 0.8, 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(wb, "scale", Vector3.ONE * r * 0.9, 0.2)
	tw.tween_callback(wb.queue_free)
	VFX.star(pos, Color(1, 1, 1), 8.0, 0.2)
	VFX.shockwave(_ground(pos) + Vector3.UP * 0.15, Color(0.9, 0.9, 1.0), r * 2.6, 0.55)
	VFX.shockwave(pos, Color(1, 1, 1), r * 1.6, 0.35, false)
	VFX.cracks(pos, r * 0.9)
	VFX.debris(pos, Color(0.5, 0.42, 0.32), 40, 26.0, 0.6)
	VFX.smoke_ring(_ground(pos), r * 0.6, Color(0.6, 0.55, 0.5))
	VFX.screen_lines(0.7, 1.0)
	Sfx.play("boom", pos, 0.5)
	if Game.world:
		Game.world.env.add_shake(1.6)
		Game.world.env.screen_flash(0.25)
	for pr in get_tree().get_nodes_in_group("projectiles"):
		if pr.shooter != c and not pr.dead and pr.global_position.distance_to(pos) < r:
			pr.apply_clash(false, 0.0)
	for f in get_tree().get_nodes_in_group("fighters"):
		if Combat.hostile(c, f) and not f.is_dead() and f.global_position.distance_to(pos) < r:
			var dd = f.global_position - c.global_position
			dd.y = 0
			f.take_hit(_inf(c, "shinra_tensei", 1.2, {"knock": 30.0, "launch": 7.0, "dir": dd.normalized(), "attacker": c}))


## Raikiri: Chidori'nin keskin, beyaz-mavi hali — daha hızlı hücum
func j_raikiri(c: Node3D, t: Node3D) -> void:
	var m = _mult(c) * _elem_bonus(c, "raiton")
	var hand = _lightning_ball(c, Color(1, 1, 1), Color(0.75, 0.88, 1.0), "chidori")
	hand.scale = Vector3.ONE * 1.25
	_hand_dash(c, t, hand, 0.5, 36.0, {"dmg": 40.0 * m, "element": "raiton", "knock": 16.0, "launch": 3.0, "kind": "heavy", "hitstop": 0.14, "stun": 1.2},
		Color(0.8, 0.9, 1.0))


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


## Amaterasu: baktığın noktada söndürülemeyen kara alevler tutuşur
func j_amaterasu(c: Node3D, t: Node3D) -> void:
	var tg = _tg(c, t, 40.0)
	var pos: Vector3 = tg.global_position if tg else _ground(_aim_ground(c, t, 15.0, 40.0))
	Sfx.play("genjutsu", c.global_position, 0.6)
	if c is Player and Game.world:
		Game.world.env.set_tint(Color(0.6, 0.0, 0.05, 0.25))
		get_tree().create_timer(0.35).timeout.connect(func(): Game.world.env.set_tint(Color(0, 0, 0, 0)))
	var flame = VFX.black_flames(maxf(1.2, tg.height * 0.75) if tg else 1.6)
	VFX.black_smolder(pos, 2.0, 8.0)
	if tg:
		tg.add_child(flame)
		flame.position = Vector3(0, 0.1, 0)
		tg.apply_status("burn", 10.0)
		tg.set_meta("black_flame", true)
	else:
		get_tree().current_scene.add_child(flame)
		flame.global_position = pos
	var dur = 8.0
	var inf = _inf(c, "amaterasu", 0.25, {"knock": 0.0, "launch": 0.0, "kind": "light", "hitstop": 0.0, "element": "katon"})
	_ticks(int(dur / 0.4), 0.4, func(_i):
		var p = (tg.global_position if tg and is_instance_valid(tg) else pos)
		# yukarı yalayan kara alev dilleri (uzayan cel topaklar) + mor kor
		VFX.puffs(p + Vector3.UP * 0.6, {"amount": 6, "life": 0.7, "size": 1.0, "radius": 0.8, "vmin": 2, "vmax": 4, "dir": Vector3.UP, "spread": 15.0, "glow": 1.0,
			"stretch": 2.2, "outline_col": Color(0.5, 0.1, 0.58), "colors": [Color(0.04, 0.0, 0.06, 1), Color(0.03, 0.0, 0.05, 1), Color(0.02, 0.0, 0.03, 0)]})
		VFX.embers(p + Vector3.UP, Color(0.6, 0.15, 0.7), 4, 3.0, 0.8)
		Combat.hit_sphere(c, p + Vector3.UP, 1.8, inf), func():
		if is_instance_valid(flame):
			flame.queue_free())


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


## Enton: Kagutsuchi — kara alevler kullanıcının arkasında beş uzun mızrağa dönüşür, sırayla fırlayıp hedefi çiviler;
## değdiği yerde kara alev tutuşur, son mızrak yere saplanıp kara alev sütunu yükseltir
func j_enton_kagutsuchi(c: Node3D, t: Node3D) -> void:
	var tg = _tg(c, t, 45.0)
	var aim: Vector3 = (tg.global_position + Vector3.UP * float(tg.height) * 0.5) if tg else _aim_ground(c, t, 20.0, 45.0) + Vector3.UP
	Sfx.play("genjutsu", c.global_position, 0.5)
	var inf = _inf(c, "enton_kagutsuchi", 0.45, {"knock": 10.0, "launch": 2.0, "kind": "heavy", "hitstop": 0.05, "element": "katon"})
	var right = c.face_dir().cross(Vector3.UP).normalized()
	for k in 5:
		var mb = MB.new()
		mb.add("cone", Vector3(0, 0, -1.1), Vector3(0.16, 1.6, 0.16), Color.WHITE, Vector3(-90, 0, 0), 8)   # uç
		mb.add("cyl", Vector3(0, 0, 0.6), Vector3(0.09, 2.2, 0.09), Color.WHITE, Vector3(90, 0, 0), 8)   # sap
		for sx in [-1.0, 1.0]:   # geriye kıvrık kanatçıklar
			mb.add("cone", Vector3(0.18 * sx, 0, -0.35), Vector3(0.07, 0.6, 0.05), Color.WHITE, Vector3(-90, 0, 35 * sx), 5)
		var sp = MeshInstance3D.new()
		sp.mesh = mb.build(null)
		sp.material_override = _black_mat()
		sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		get_tree().current_scene.add_child(sp)
		var a = lerpf(-1.0, 1.0, k / 4.0)
		var start = c.global_position + Vector3.UP * (2.0 + (1.0 - absf(a)) * 0.6) + right * a * 1.8 - c.face_dir() * 0.6
		sp.global_position = start
		sp.scale = Vector3.ONE * 0.05
		sp.look_at(aim, Vector3.UP)
		var end = aim + Vector3(randf_range(-0.6, 0.6), randf_range(-0.4, 0.4), randf_range(-0.6, 0.6))
		var fly = start.distance_to(end) / 55.0
		var last = k == 4
		var tw = sp.create_tween()
		tw.tween_property(sp, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK)
		tw.tween_interval(0.15 + k * 0.12)
		tw.tween_callback(func():
			if is_instance_valid(sp):
				sp.look_at(end, Vector3.UP)
				VFX.puffs(sp.global_position, {"amount": 8, "life": 0.5, "size": 0.7, "radius": 0.3, "vmin": 1, "vmax": 3, "glow": 1.0, "stretch": 2.0,
					"outline_col": Color(0.5, 0.1, 0.58), "colors": [Color(0.04, 0.0, 0.06, 1), Color(0.02, 0.0, 0.03, 0)]}))
		tw.tween_property(sp, "global_position", end, fly)
		tw.tween_callback(func():
			for h in Combat.hit_sphere(c, end, 1.4, inf):
				_ignite(h, 6.0)
			VFX.black_smolder(_ground(end), 1.2, 5.0)
			VFX.embers(end, Color(0.6, 0.15, 0.7), 10, 4.0, 0.8)
			if last:
				var gp = _ground(end)
				var col = VFX.black_flames(2.4)
				get_tree().current_scene.add_child(col)
				col.global_position = gp
				col.scale = Vector3(1.0, 2.2, 1.0)
				for h in Combat.hit_sphere(c, gp + Vector3.UP * 1.5, 3.2, inf):
					_ignite(h, 8.0)
				get_tree().create_timer(3.0).timeout.connect(func(): if is_instance_valid(col): col.queue_free()))
		tw.tween_interval(0.8 if not last else 0.2)
		tw.tween_property(sp, "scale", Vector3.ONE * 0.01, 0.3)
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


## Amaterasu: Entenka — kara alevler bedene zırh gibi sarılır: dokunanı tutuşturur, hasarı azaltır (8 sn)
func j_amaterasu_entenka(c: Node3D, t: Node3D) -> void:
	Sfx.play("genjutsu", c.global_position, 0.7)
	var fl = VFX.black_flames(0.95 / maxf(1.0, VFX.epic))   # bedene oturan zırh (rütbe ölçeğiyle devleşmesin)
	c.add_child(fl)
	fl.position = Vector3(0, 0.15, 0)
	fl.scale = Vector3(1.0, 1.15, 1.0)
	if c is Player:
		Buffs.add("entenka", 8.0, {"armor": 0.6})
	var inf = _inf(c, "amaterasu_entenka", 0.12, {"knock": 6.0, "kind": "light", "hitstop": 0.0, "element": "katon"})
	_ticks(16, 0.5, func(_i):
		if not is_instance_valid(c):
			return
		for h in Combat.hit_sphere(c, c.global_position + Vector3.UP, 2.2, inf):
			if not h.has_meta("black_flame"):
				_ignite(h, 5.0)
		VFX.embers(c.global_position + Vector3.UP, Color(0.6, 0.15, 0.7), 4, 2.0, 0.7), func():
		if is_instance_valid(fl):
			fl.queue_free())


## Tensha Fūin: Amaterasu — göze mühürlenmiş kara alev: 20 sn içinde yaklaşan ilk düşmana kendiliğinden ateşlenir
func j_tensha_fuin_amaterasu(c: Node3D, t: Node3D) -> void:
	Sfx.play("seal", c.global_position, 0.8)
	if c is Player:
		Hud.msg("Kopya mühür kuruldu: yaklaşan ilk düşman kara alevle karşılanacak.", Color(0.8, 0.5, 1.0))
	VFX.shockwave(c.global_position + Vector3.UP * 1.6, Color(0.3, 0.0, 0.35), 2.0, 0.5, false)
	var fired = [false]
	_ticks(40, 0.5, func(_i):
		if fired[0] or not is_instance_valid(c):
			return
		var e = Combat.nearest_enemy(c, 12.0)
		if e:
			fired[0] = true
			Combat.popup_text(c.global_position + Vector3.UP * 2.4, "Amaterasu!", Color(0.85, 0.35, 0.95))
			j_amaterasu(c, e))

## Tsukuyomi: göz göze gelen hedef kırmızı-siyah illüzyon dünyasına hapsolur
func j_tsukuyomi(c: Node3D, t: Node3D) -> void:
	var tg = _tg(c, t, 20.0)
	if tg == null:
		if c is Player: Hud.msg("Göz göze gelecek hedef yok.", Color(0.8, 0.8, 0.8))
		return
	Sfx.play("genjutsu", c.global_position, 0.5)
	var cl = CanvasLayer.new()
	cl.layer = 6
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.55, 0.02, 0.04, 0.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(bg)
	var moon = Label.new()
	moon.text = "●"
	moon.add_theme_font_size_override("font_size", 360)
	moon.add_theme_color_override("font_color", Color(0.02, 0, 0, 0.0))
	moon.set_anchors_preset(Control.PRESET_CENTER)
	moon.position = Vector2(-120, -260)
	cl.add_child(moon)
	get_tree().current_scene.add_child(cl)
	var tw = bg.create_tween()
	tw.tween_property(bg, "color:a", 0.75, 0.15)
	tw.parallel().tween_property(moon, "theme_override_colors/font_color:a", 1.0, 0.15)
	tw.tween_interval(1.1)
	tw.tween_property(bg, "color:a", 0.0, 0.3)
	tw.parallel().tween_property(moon, "theme_override_colors/font_color:a", 0.0, 0.3)
	tw.tween_callback(cl.queue_free)
	tg.apply_status("stun", 6.0)
	tg.apply_status("fear", 6.0)
	tg.take_hit(_inf(c, "tsukuyomi", 1.5, {"knock": 0.0, "attacker": c, "dir": Vector3.ZERO}))
	VFX.shockwave(tg.global_position + Vector3.UP * 1.6, Color(0.9, 0.05, 0.05), 5.0, 0.6, false)


## Kamui: hedefin çevresinde uzayı büken girdap — çekip parçalar
func j_kamui(c: Node3D, t: Node3D) -> void:
	var tg = _tg(c, t, 30.0)
	var pos: Vector3 = (tg.global_position + Vector3.UP * tg.height * 0.5) if tg else _aim_ground(c, t, 12.0, 30.0) + Vector3.UP
	var sw = VFX._mi(VFX._sphere(0.5, 32, 16), VFX.mat_spiral(Color(0.05, 0.02, 0.08), Color(0.3, 0.15, 0.45), 3.0, 8.0, 10.0, 1.0, Vector3(0, 0, 1)))
	get_tree().current_scene.add_child(sw)
	sw.global_position = pos
	sw.scale = Vector3(0.1, 0.1, 0.02)
	var tw = sw.create_tween()
	tw.tween_property(sw, "scale", Vector3(9.0, 9.0, 1.0), 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(sw, "rotation:z", TAU * 2.0, 1.4)
	tw.tween_interval(0.6)
	tw.tween_property(sw, "scale", Vector3(0.02, 0.02, 0.02), 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.tween_callback(sw.queue_free)
	Sfx.play("genjutsu", pos, 0.7)
	if tg:
		tg.apply_status("stun", 1.4)
		_ticks(5, 0.2, func(_i):
			if is_instance_valid(tg) and not tg.is_dead():
				tg.take_hit(_inf(c, "kamui", 0.35, {"knock": 0.0, "attacker": c, "dir": Vector3.ZERO})))


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
			var bird = JutsuEngine.shape_mesh("bird", Color(0.95, 0.95, 0.92), 1.4, "")
			for mi in bird.find_children("*", "MeshInstance3D", true, false):
				mi.material_override = Props.toon_color(Color(0.96, 0.95, 0.9))
			pr.add_child(bird)
			pr.on_hit = func(pos: Vector3, _tg: Node3D) -> void:
				VFX.explosion(pos, 1.0, Color(1.0, 0.6, 0.2))
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
	var fd = _aim_flat(c, t)
	var base = _ground(c.global_position + fd * 3.0)
	var wood = Props.toon_color(Color(0.5, 0.36, 0.22))
	var head = Node3D.new()
	get_tree().current_scene.add_child(head)
	head.global_position = base - Vector3.UP * 2.0
	var hn = VfxSerpent.dragon_head(wood, 2.8, Color(1, 0.85, 0.2))
	head.add_child(hn)
	# dallanan tahta boynuzlar + yanak kökleri + sakal kökleri
	var ab = MB.new()
	for sx in [-1.0, 1.0]:
		ab.add("cyl", Vector3(0.32 * sx, 0.75, 0.55), Vector3(0.12, 1.1, 0.12), Color(0.42, 0.3, 0.18), Vector3(-50, 0, -25 * sx), 6)
		ab.add("cyl", Vector3(0.55 * sx, 1.15, 0.85), Vector3(0.08, 0.6, 0.08), Color(0.42, 0.3, 0.18), Vector3(-20, 0, -60 * sx), 5)
		ab.add("cyl", Vector3(0.25 * sx, 1.25, 1.05), Vector3(0.07, 0.55, 0.07), Color(0.42, 0.3, 0.18), Vector3(-70, 0, 10 * sx), 5)
		ab.add("cone", Vector3(0.5 * sx, -0.25, -0.2), Vector3(0.12, 0.7, 0.12), Color(0.38, 0.27, 0.16), Vector3(150, 0, 30 * sx), 5)
		ab.add("sphere", Vector3(0.62 * sx, 0.55, 0.9), Vector3(0.35, 0.25, 0.3), Color(0.32, 0.55, 0.22), Vector3.ZERO, 6)   # yaprak tutamı
	var am = MeshInstance3D.new()
	am.mesh = ab.build(Props.toon())
	am.scale = Vector3.ONE * 2.8
	head.add_child(am)
	var body = VfxSerpent.new()
	body.head = head
	body.count = 18
	body.spacing = 1.15
	body.radius = 1.3
	body.mat = wood
	body.ring_mat = Props.toon_color(Color(0.32, 0.22, 0.13))   # gövde halkaları (kabuk boğumları)
	body.fin_mat = Props.toon_color(Color(0.3, 0.55, 0.22))   # sırtta yapraklı filizler
	get_tree().current_scene.add_child(body)
	VFX.cracks(base, 5.0)
	VFX.debris(base, Color(0.45, 0.35, 0.25), 16, 12.0, 0.45)
	Sfx.play("earth", base)
	var tg = _tg(c, t, 30.0)
	var tw = head.create_tween()
	var top = base + Vector3.UP * 7.0
	tw.tween_method(func(k: float):
		var p = (base - Vector3.UP * 2.0).lerp(top, k) + fd.cross(Vector3.UP) * sin(k * TAU) * 2.5
		var nx = (base - Vector3.UP * 2.0).lerp(top, minf(1.0, k + 0.03)) + fd.cross(Vector3.UP) * sin(minf(1.0, k + 0.03) * TAU) * 2.5
		head.global_position = p
		head.look_at(nx, Vector3.RIGHT if absf((nx - p).normalized().y) > 0.98 else Vector3.UP), 0.0, 1.0, 0.6)
	tw.tween_method(func(k: float):
		var goal = (tg.global_position + Vector3.UP if tg and is_instance_valid(tg) else c.global_position + fd * 20.0)
		var p = top.lerp(goal, k * k)
		if p.distance_to(head.global_position) > 0.01:
			head.look_at(p, Vector3.UP)
		head.global_position = p, 0.0, 1.0, 0.45)
	tw.tween_callback(func():
		var p = head.global_position
		VFX.debris(p, Color(0.5, 0.36, 0.22), 18, 12.0, 0.5)
		VFX.star(p, Color(0.9, 0.8, 0.5), 4.0, 0.18)
		FX.dust(_ground(p), 1.6)
		Combat.hit_sphere(c, p, 4.0, _inf(c, "mokuton_mokuryu_no_jutsu", 1.6, {"stun": 1.6}))
		if tg and is_instance_valid(tg):
			tg.apply_status("bind", 2.0)
		if Game.world: Game.world.env.add_shake(0.8))
	tw.tween_interval(1.4)
	tw.tween_callback(head.queue_free)
