extends Node
## 1) Kaçış atlayışı: çift Space + geri / sol / sağ — yer değiştirme, yüz dönüyor mu, üç hareketin kareleri
## 2) Yakının dövüşte ölmesi: katil belli mi, Bingo Kitabı'na yazıldı mı, katili öldürünce intikam sayılıyor mu
var main: Node
var pl: Player
var spot := Vector3.ZERO


func _hop(act: String, tag: String, shots: bool) -> void:
	pl.respawn(spot)
	pl.velocity = Vector3.ZERO
	await get_tree().create_timer(1.0).timeout
	var p0 = pl.global_position
	pl.yaw = 0.0
	var f0 = 0.0
	pl._jump()
	await get_tree().create_timer(0.12).timeout
	Input.action_press(act)
	await get_tree().process_frame
	pl._jump()
	var kind = pl.flip_kind
	var fmax = 0.0
	var top = 0.0
	var t = 0.0
	var k = 0
	while t < 1.3:
		await get_tree().process_frame
		t += get_process_delta_time()
		fmax = maxf(fmax, absf(angle_difference(pl.facing, f0)))
		top = maxf(top, pl.global_position.y - p0.y)
		if shots and k < 4 and t > 0.08 + k * 0.1:
			await main.shot("ev_%s_%s_%d" % [tag, kind, k])
			k += 1
		if t > 0.5:
			Input.action_release(act)
	Input.action_release(act)
	var d = pl.global_position - p0
	print("EV %-5s hareket=%-5s yer değişimi x=%.1f z=%.1f (toplam %.1f m) tepe=%.1f m yüz dönmesi=%.0f° yerde=%s" % [tag, kind, d.x, d.z, Vector2(d.x, d.z).length(), top, rad_to_deg(fmax), pl.grounded])


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	pl = main.player
	Game.world.env.time_of_day = 0.4
	var at = pl.global_position + Vector3(0, 0, 900)
	at.y = Game.ground_height(at.x, at.z)
	pl.respawn(at)
	await get_tree().create_timer(1.5).timeout
	# düz, boş bir yer: çevresinde 20 m engel olmayan nokta
	spot = at
	for k in 40:
		var c = at + Vector3(randf_range(-150, 150), 0, randf_range(-150, 150))
		var okk = true
		for a in 8:
			var q = c + Vector3(cos(a * TAU / 8.0), 0, sin(a * TAU / 8.0)) * 20.0
			if absf(Game.ground_height(q.x, q.z) - Game.ground_height(c.x, c.z)) > 1.0 or Missions.open_ground(q, 0.0).distance_to(q) > 0.5:
				okk = false
		if okk and Missions.open_ground(c, 0.0).distance_to(c) < 0.5:
			spot = c
			break
	spot.y = Game.ground_height(spot.x, spot.z) + 0.3
	pl.cam_dist = 6.0
	pl.pitch = -12.0
	# ---- kaçış atlayışı: her yönde üç hareket
	for r in 2:
		for a in [["back", "geri"], ["left", "sol"], ["right", "sağ"], ["back", "geri"]]:
			await _hop(a[0], a[1], false)
	# ileri basılıyken: eski çift zıplama kalmalı
	await _hop("forward", "ileri", true)
	# darbe ıskalıyor mu
	pl.velocity = Vector3.ZERO
	await get_tree().create_timer(0.8).timeout
	var hp0 = pl.hp
	pl._jump()
	await get_tree().create_timer(0.1).timeout
	Input.action_press("back")
	await get_tree().process_frame
	pl._jump()
	await get_tree().create_timer(0.1).timeout
	pl.take_hit({"dmg": 50.0})
	Input.action_release("back")
	print("EV darbe: atlayış sırasında can %.0f -> %.0f" % [hp0, pl.hp])
	await get_tree().create_timer(1.2).timeout
	pl.take_hit({"dmg": 50.0})
	print("EV darbe: yerdeyken can %.0f -> %.0f" % [hp0, pl.hp])
	pl.hp = pl.max_hp
	# ---- yakının ölümü
	var fam = Friends.all().keys().filter(func(id): return KinDrama.is_family(String(id)) and String(Friends.all()[id].get("status", "")) == "")
	print("SL aile: ", fam.map(func(id): return "%s(%s)" % [Friends.all()[id]["name"], KinDrama.rel_word(String(id))]))
	if fam.size() >= 2:
		# a) katil sağ: kitaba yazılır, orada öldürünce intikam
		var fid = String(fam[0])
		var a = Enemy.archetype("rogue", 0)
		a["respawn"] = false
		a["level"] = 20
		Enemy.arm(a)
		var e = Enemy.new()
		e.setup(a)
		main.add_child(e)
		e.global_position = pl.global_position + Vector3(6, 0, 0)
		await get_tree().create_timer(0.5).timeout
		var n0 = Missions._bingo()["list"].size()
		KinDrama.slain(fid, null, [e], e.global_position, "Yol pususu sırasında öldü")
		var f: Dictionary = Friends.all()[fid]
		var ent = Missions._bingo()["list"].filter(func(x): return String(x.get("kin_victim", "")) == fid)
		print("SL a) durum=%s katil=%s | kitapta yeni kayıt=%d kayıt adı=%s takipte=%s | düşmanda işaret=%s | günlük son: %s" % [f["status"], f.get("killer_name", "YOK"), Missions._bingo()["list"].size() - n0,
			ent[0]["name"] if not ent.is_empty() else "YOK", ent[0].get("tracked", false) if not ent.is_empty() else false, e.has_meta("bingo_id"), String(f.get("log", [["", ""]])[-1])])
		await get_tree().create_timer(1.0).timeout
		for k in 40:
			if is_instance_valid(e) and not e.is_dead():
				e.take_hit({"dmg": 5000.0, "attacker": pl})
				await get_tree().create_timer(0.1).timeout
		await get_tree().create_timer(1.5).timeout
		print("SL a) katil öldürüldü: intikam=%s kayıt durumu=%s mezar seçeneği=%s" % [f.get("avenged", false), ent[0]["status"] if not ent.is_empty() else "?",
			KinDrama.grave_opts(String(f.get("village", Progress.home()))).map(func(o): return o["label"])])
		# b) katil dövüşte çoktan ölmüş
		var fid2 = String(fam[1])
		KinDrama.slain(fid2, null, [], pl.global_position, "Yol pususu sırasında öldü")
		var f2: Dictionary = Friends.all()[fid2]
		print("SL b) düşman yokken: durum=%s katil=%s intikam=%s" % [f2["status"], f2.get("killer_name", "bilinmiyor"), f2.get("avenged", false)])
	# c) uzakta görevde ölen tanıdık
	var oth = Friends.all().keys().filter(func(id): return String(Friends.all()[id].get("status", "")) == "")
	if not oth.is_empty():
		var fid3 = String(oth[0])
		KinDrama.slain_far(fid3, "Bir görevde öldü")
		var f3: Dictionary = Friends.all()[fid3]
		print("SL c) uzakta: %s durum=%s katil=%s" % [f3["name"], f3["status"], f3.get("killer_name", "YOK")])
	# ---- baraka baskını: haber geliyor mu, yetişince takım çıkıyor mu, yenince kurtuluyor mu, yetişmeyince yanıyor mu
	Missions._bb_spawned.clear()
	print("HUT sessizlik=", Missions.quiet(), " aktif=", not Missions.active().is_empty(), " sınav=", int(ChuninExam.stage), Exams.cur, " boss=", Hud.boss, " yol=", is_instance_valid(LegendPaths._node) and not LegendPaths._node.drill.is_empty())
	Hud.boss = null
	Orgs.flags()["rogue"] = true
	Orgs.flags()["rogue_from"] = "konoha"
	var hm = Game.to_map(pl.global_position + Vector3(400, 0, 0))
	RogueHut.built([hm.x, hm.y])
	RogueHut.d()["raid"] = true
	RogueHut.tick()
	var wp = Game.profile.get("waypoint", [])
	print("HUT haber: süre=%s sn işaret=%s durum=%s" % [int(float(RogueHut.d().get("raid_at", 0)) - Time.get_unix_time_from_system()), wp[3] if wp is Array and wp.size() > 3 else "YOK", RogueHut.state()])
	var hp = Missions._w([hm.x, hm.y])
	hp.y = Game.ground_height(hp.x, hp.z)
	pl.respawn(hp + Vector3(10, 0.5, 10))
	await get_tree().create_timer(1.5).timeout
	RogueHut.tick()
	print("HUT yetiştin: baskıncı=%d adlar=%s" % [RogueHut.raiders.size(), RogueHut.raiders.map(func(e): return e.display_name)])
	for k in 60:
		for e in RogueHut.raiders.duplicate():
			if is_instance_valid(e) and not e.is_dead():
				e.take_hit({"dmg": 5000.0, "attacker": pl})
		await get_tree().create_timer(0.1).timeout
	await get_tree().create_timer(1.5).timeout
	RogueHut.tick()
	print("HUT takım yenildi: durum=%s baskın=%s" % [RogueHut.state(), RogueHut.d().get("raid", false)])
	RogueHut.d()["raid"] = true
	RogueHut.tick()
	RogueHut.d()["raid_at"] = Time.get_unix_time_from_system() - 1.0
	pl.respawn(at)
	await get_tree().create_timer(1.0).timeout
	RogueHut.tick()
	print("HUT yetişmedin: durum=%s" % RogueHut.state())
	get_tree().quit()
