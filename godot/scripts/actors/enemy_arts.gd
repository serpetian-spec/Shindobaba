class_name EnemyArts
extends RefCounted
## Düşmanların "büyük" teknikleri: göz (dōjutsu) sahipleri Genjutsu / Kaiten / Amaterasu / Tsukuyomi kullanır,
## Mangekyō sahipleri can yarıya inince Susanoo (İnsansı) açar; sözleşmeli kaçaklar (meta "contract") zorlanınca çağırma yapar.
## Enemy._physics_process her karede tick() çağırır (yalnız ilgili düşmanlarda maliyet).


static func wants(e: Enemy) -> bool:
	return e.has_meta("eyes") or e.has_meta("contract")


static func tick(e: Enemy, dt: float) -> void:
	if e.dead:
		return
	var cd = float(e.get_meta("ea_cd", 4.0)) - dt
	e.set_meta("ea_cd", cd)
	var t = e.target
	if t == null or not is_instance_valid(t) or t.is_dead() or e.state in ["hitstun", "knockdown", "cast"] or e.has_status("stun") or e.has_status("bind"):
		return
	var d = e.global_position.distance_to(t.global_position)
	# sözleşmeli kaçak: canı %70'in altına inince bir kez çağırma (boss tarzı "kuchiyose" kendi yönetir)
	if e.has_meta("contract") and String(e.arch.get("style", "")) != "kuchiyose" and not e.get_meta("ea_summoned", false) and e.hp < e.max_hp * 0.7 and d < 35.0:
		e.set_meta("ea_summoned", true)
		Combat.popup_text(e.global_position + Vector3.UP * 2.6, "Kuchiyose no Jutsu!", Color(0.85, 0.6, 1.0))
		e.model.play("cast_out", 0.05, 1.0, true)
		Contracts.summon(e, {"id": "kuchiyose"})
		e.set_meta("ea_cd", 4.0)
		return
	if not e.has_meta("eyes"):
		return
	var kind = int(e.get_meta("eyes").get("kind", 0))
	if kind in [4, 5] and not e.has_meta("kamui_user"):
		e.set_meta("kamui_user", randf() < 0.25)   # Obito tarzı Mangekyō: darbeler içinden geçer
	maybe_izanagi(e)
	var eblind = float(e.get_meta("ms_blind", 0.0))
	if kind == 4 and e.has_meta("ea_susanoo") and is_instance_valid(e.get_meta("ea_susanoo")):
		_ms_strain(e, dt * 0.004)   # açık Susanoo düşmanın da gözünü yorar (oyuncuyla aynı kural)
	# Mangekyō: can yarıya inince Susanoo (kör Mangekyō açamaz)
	if kind in [4, 5] and not e.has_meta("ea_susanoo") and e.hp < e.max_hp * 0.5 and (kind == 5 or eblind < 1.0):
		_susanoo(e)
	var sn = e.get_meta("ea_susanoo") if e.has_meta("ea_susanoo") else null
	if sn and is_instance_valid(sn):
		sn.rotation.y = e.facing
		var sc = float(e.get_meta("ea_sus_cd", 2.5)) - dt
		e.set_meta("ea_sus_cd", sc)
		if sc <= 0.0 and d < Susanoo.TIER_HEIGHT[sn.tier] * 0.8:
			e.set_meta("ea_sus_cd", randf_range(2.5, 4.0))
			var dir = (t.global_position - e.global_position)
			dir.y = 0
			sn.swipe(e, dir.normalized())
	if cd > 0.0:
		return
	match kind:
		1, 3:   # Sharingan / Ketsuryūgan: göz göze gelince genjutsu
			if d < 14.0:
				_gaze(e, t, 1.2, Color(0.9, 0.05, 0.05), "Genjutsu!")
				e.set_meta("ea_cd", randf_range(10.0, 14.0))
		2:   # Byakugan: yakındayken Hakkeshō Kaiten
			if d < 4.5:
				Combat.popup_text(e.global_position + Vector3.UP * 2.4, "Hakkeshō Kaiten!", Color(0.85, 0.9, 1.0))
				FX.ring(e.global_position + Vector3.UP * 1.0, Color(0.85, 0.92, 1.0), 4.5, 0.5)
				var dir = (t.global_position - e.global_position).normalized()
				Combat.hit_sphere(e, e.global_position + Vector3.UP, 3.5, {"dmg": 14.0 * e.power, "knock": 16.0, "launch": 5.0, "kind": "heavy", "dir": dir})
				e.set_meta("ea_cd", randf_range(8.0, 11.0))
		6:   # Rinnegan: yakında Shinra Tensei (her şeyi iter), uzakta Banshō Ten'in (kendine çeker)
			if d < 8.0:
				Combat.popup_text(e.global_position + Vector3.UP * 2.6, "Shinra Tensei!", Color(0.75, 0.65, 1.0))
				FX.ring(e.global_position + Vector3.UP * 1.0, Color(0.85, 0.8, 1.0), 12.0, 0.45)
				VFX.shockwave(e.global_position + Vector3.UP, Color(0.8, 0.75, 1.0), 10.0, 0.5, false)
				Combat.hit_zone(e, e.global_position, Vector3.ZERO, 9.0, 180.0, 6.0, {"dmg": 24.0 * e.power, "knock": 30.0, "launch": 6.0, "kind": "heavy"})
				if Game.world:
					Game.world.env.add_shake(0.7)
				e.set_meta("ea_cd", randf_range(9.0, 12.0))
			elif d < 28.0:
				Combat.popup_text(e.global_position + Vector3.UP * 2.6, "Banshō Ten'in!", Color(0.75, 0.65, 1.0))
				VFX.bolt(e.global_position + Vector3.UP * 1.4, t.global_position + Vector3.UP, Color(0.8, 0.75, 1.0), 0.15, 0.4, 0)
				var pull = e.global_position + (t.global_position - e.global_position).normalized() * 2.0
				pull.y = Game.jutsu_floor(pull.x, pull.z)
				t.create_tween().tween_property(t, "global_position", pull, 0.35).set_trans(Tween.TRANS_QUAD)
				t.apply_status("stun", 0.6)
				e.set_meta("ea_cd", randf_range(7.0, 10.0))
		4, 5:   # Mangekyō: Amaterasu (uzak) / Tsukuyomi (yakın); Mangekyō (Ebedi değil) her kullanımda gözünü yorar
			if kind == 4 and eblind >= 1.0:
				if d < 14.0:
					_gaze(e, t, 1.2, Color(0.9, 0.05, 0.05), "Genjutsu!")   # kör Mangekyō: yalnız sıradan Sharingan genjutsusu
					e.set_meta("ea_cd", randf_range(10.0, 14.0))
				return
			if kind == 4:
				_ms_strain(e, 0.12)
			if d < 9.0 and randf() < 0.45:
				_gaze(e, t, 2.6, Color(0.6, 0.0, 0.05), "Tsukuyomi!")
				if t == Game.player and Game.world:
					Game.world.env.flash_tint(Color(0.55, 0.0, 0.05, 0.5), 1.2)
				e.set_meta("ea_cd", randf_range(14.0, 18.0))
			elif d < 30.0:
				_amaterasu(e, t)
				e.set_meta("ea_cd", randf_range(12.0, 16.0))


## Düşman Mangekyō körlüğü (oyuncuyla aynı kural): dolunca Mangekyō teknikleri ve Susanoo kapanır
static func _ms_strain(e: Enemy, amount: float) -> void:
	var b = float(e.get_meta("ms_blind", 0.0))
	var nb = minf(1.0, b + amount)
	e.set_meta("ms_blind", nb)
	if b < 1.0 and nb >= 1.0:
		Combat.popup_text(e.global_position + Vector3.UP * 2.6, "Gözleri karardı!", Color(0.7, 0.2, 0.25))
		var sn = e.get_meta("ea_susanoo") if e.has_meta("ea_susanoo") else null
		if sn and is_instance_valid(sn):
			sn.queue_free()
		e.remove_meta("ea_susanoo")


## Düşman İzanagi (oyuncuyla aynı kural, kanon): Sharingan sahibi düşman canı %35'in altına inince bir kez,
## bu tekniği biliyorsa (%40) İzanagi'yi ÖNCEDEN açar — 10 sn içinde ölürse yanılsama; süre bitince gözü kararır
static func maybe_izanagi(e: Enemy) -> void:
	if e.get_meta("izanagi_checked", false) or e.hp > e.max_hp * 0.35:
		return
	if not e.has_meta("eyes") or not int(e.get_meta("eyes").get("kind", 0)) in [1, 4, 5]:
		return
	e.set_meta("izanagi_checked", true)
	if randf() > 0.4:
		return
	Jutsu.execute(e, "izanagi", null)   # oyuncunun İzanagi jutsusuyla aynı kod


## Düşman Kamui geçirgenliği (oyuncuyla aynı kural): darbe gelince 2.5 sn içinden geçer, sonra katılaşır; 6 sn bekleme.
## Geçirgenken saldıramaz; bitişte katılaşma anı açık (vurulabilir). Körlük biriktirir.
static func kamui_phase(e: Enemy) -> bool:
	if not e.get_meta("kamui_user", false) or float(e.get_meta("ms_blind", 0.0)) >= 1.0:
		return false
	var now = Time.get_ticks_msec()
	if now < int(e.get_meta("kamui_until", 0)):
		return true
	if now < int(e.get_meta("kamui_next", 0)):
		return false
	e.set_meta("kamui_until", now + 2500)
	e.set_meta("kamui_next", now + 8500)
	_ms_strain(e, 0.05)
	Combat.popup_text(e.global_position + Vector3.UP * 2.6, "Kamui!", Color(0.75, 0.6, 0.9))
	MsArts.kamui_vortex(e.global_position + Vector3.UP * 1.0, 0.9, 2.7)
	if e.model:
		for g in e.model.find_children("*", "GeometryInstance3D", true, false):
			(g as GeometryInstance3D).transparency = 0.55
		e.get_tree().create_timer(2.5).timeout.connect(func():
			if is_instance_valid(e) and e.model:
				for g in e.model.find_children("*", "GeometryInstance3D", true, false):
					(g as GeometryInstance3D).transparency = 0.0)
	return true


static func _gaze(e: Enemy, t: Node3D, stun: float, col: Color, label: String) -> void:
	# ortak genjutsu kapısı (oyuncununkiyle aynı): göz teması, Kyō Tenchi-ten yansıtması, Sharingan direnci
	stun *= Eyes.genjutsu_land(e, t, true)
	if stun <= 0.05:
		return
	t.apply_status("stun", stun)
	FX.ring(t.global_position + Vector3.UP * 1.6, col, 1.6, 0.6, false, (e.global_position - t.global_position).normalized())
	Combat.popup_text(t.global_position + Vector3.UP * 2.2, label, col.lightened(0.3))
	Combat.popup_text(e.global_position + Vector3.UP * 2.4, label, col.lightened(0.3))


## Kara alev: hedefi sarar, uzun süre yakar (oyuncunun Amaterasu'suyla aynı görsel)
static func _amaterasu(e: Enemy, t: Node3D) -> void:
	Combat.popup_text(e.global_position + Vector3.UP * 2.4, "Amaterasu!", Color(0.9, 0.3, 0.35))
	e.model.play("cast_out", 0.05, 1.2, true)
	t.take_hit({"dmg": 12.0 * e.power, "knock": 0.0, "kind": "light", "dir": e.face_dir(), "element": "katon", "attacker": e})
	# oyuncunun Amaterasu'suyla aynı ortak sistem: yer değiştirme / ani atılmayla sıyrılabilirsin
	Amaterasu.ignite(e, t, t.global_position, 6.0, {"dmg": 1.5 * e.power, "knock": 0.0, "kind": "light", "element": "katon", "attacker": e})


## Düşman Susanoo'su: İnsansı kademe; her düşmanda rengi ve yapısı farklı (renk, zırh, yüz, silah, yoğunluk rastgele;
## NPC başına bir kez zar, jutsularındaki Susanoo da aynı). Hasarı azaltır, aralıklarla dev savuruş yapar.
static func _susanoo(e: Enemy) -> void:
	var pr = random_susanoo(e)
	var col: Array = pr["susanoo"]["color"]
	var sn = Susanoo.new()
	sn.name = "Susanoo"
	e.add_child(sn)
	sn.build(pr, 3, e.model)
	_susanoo_after(e, sn, col)


## NPC'nin rastgele Susanoo'su (renk, kenar, zırh, yüz, silah, yoğunluk): ilk istekte zar atılır, NPC'de saklanır
## (aynı NPC'nin Susanoo'su ve Susanoo jutsuları hep aynı görünür)
static func random_susanoo(n: Node) -> Dictionary:
	if n.has_meta("sus_pr"):
		return n.get_meta("sus_pr")
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var col: Array = Susanoo.COLORS[rng.randi() % Susanoo.COLORS.size()].duplicate()
	if rng.randf() < 0.5:   # paletin arasından ara tonlar
		var c2: Array = Susanoo.COLORS[rng.randi() % Susanoo.COLORS.size()]
		var k = rng.randf_range(0.2, 0.5)
		for i in 3:
			col[i] = lerpf(col[i], c2[i], k)
	var rim = Color(col[0], col[1], col[2]).lightened(rng.randf_range(0.2, 0.5))
	var pr = {"susanoo": {"color": col, "rim_color": [rim.r, rim.g, rim.b], "armor": rng.randi() % Susanoo.ARMORS.size(), "face": rng.randi() % Susanoo.FACES.size(),
		"weapon": ["kilic", "kilic", "mizrak", "kalkan", "yay", "yok"][rng.randi() % 6], "wings": false, "mastery": 999.0, "tier_pref": 3,
		"density": rng.randf_range(0.7, 1.4), "glow": rng.randf_range(0.7, 1.5), "flow": rng.randf_range(0.5, 1.8)}}
	n.set_meta("sus_pr", pr)
	return pr


static func _susanoo_after(e: Enemy, sn: Susanoo, col: Array) -> void:
	e.set_meta("ea_susanoo", sn)
	e.arch["guard"] = 0.7   # Susanoo içinde darbeleri çoğunlukla tutar
	var fs = sn.scale
	sn.scale = fs * 0.1
	sn.create_tween().tween_property(sn, "scale", fs, 0.6).set_trans(Tween.TRANS_BACK)
	Hud.banner(e.display_name, "SUSANOO!", Color(col[0], col[1], col[2]).lightened(0.3))
	Sfx.play("roar", e.global_position, 1.4, 0.6)
