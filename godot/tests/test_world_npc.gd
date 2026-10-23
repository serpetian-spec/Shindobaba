extends Node
## Klanlı dünya + yol karşılaşmaları testi: Uchiha bölgesi / Hyūga konağı sakinleri, klan düşmanlarının özel yetenekleri,
## Uchiha göz çalma, efsanevi Bingo girdileri ve her karşılaşma türünün hatasız başlaması. Ekran görüntüleri: --shots
var main: Node
var god := true
var errors := 0


func _process(_dt: float) -> void:
	if god and Game.player:
		Game.player.hp = Game.player.max_hp
		Game.player.chakra = Game.player.max_chakra


func _frame_ms(sec: float) -> float:
	var n := 0
	var t0 := Time.get_ticks_usec()
	var end := Time.get_ticks_msec() + int(sec * 1000)
	while Time.get_ticks_msec() < end:
		await get_tree().process_frame
		n += 1
	return (Time.get_ticks_usec() - t0) / 1000.0 / maxf(1.0, n)


func _cam(at: Vector3, from: Vector3) -> Camera3D:
	var cam := Camera3D.new()
	get_tree().current_scene.add_child(cam)
	cam.global_position = from
	cam.look_at(at)
	cam.current = true
	return cam


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Game.profile["level"] = 30
	Game.profile["rank"] = 2
	await get_tree().create_timer(3.0).timeout
	Game.world.env.time_of_day = 0.42
	Encounters.gap_t = 99999.0   # testte kendiliğinden başlamasın
	var v = Game.village("konoha")
	var cen := Vector2(v["x"], v["y"])
	var part_b := OS.get_cmdline_user_args().has("--part=b")
	if part_b:
		await _part_b(cen, v)
		return
	# ---------------- Uchiha bölgesi sakinleri
	var up := Game.from_map(cen + Vector2(-1020, -640) + Vector2(0, -44))
	main.player.respawn(up)
	var base_ms := await _frame_ms(2.0)
	await get_tree().create_timer(6.0).timeout
	var res: Array = ClanWorld.residents("konoha")
	var with_ms := await _frame_ms(3.0)
	print("WN residents konoha=", res.size(), " frame_ms before=", snappedf(base_ms, 0.1), " after=", snappedf(with_ms, 0.1))
	var ush: Array = res.filter(func(r): return is_instance_valid(r) and r.clan == "uchiha")
	if not ush.is_empty():
		var r0: Node3D = ush[0]
		for r in ush:
			if r.eye_kind == 1:
				r0 = r
				break
		var c1 := _cam(r0.global_position + Vector3.UP * 1.5, r0.global_position + r0.global_transform.basis.z * -2.2 + Vector3(0.6, 1.7, 0))
		c1.global_position = r0.global_position + Vector3(0, 1.6, 0) + (Vector3(sin(r0.facing), 0, cos(r0.facing)) * -2.0)
		c1.look_at(r0.global_position + Vector3.UP * 1.5)
		await get_tree().create_timer(0.6).timeout
		await main.shot("wn_uchiha_sakin")
		var c2 := _cam(up, up + Vector3(25, 18, 25))
		await get_tree().create_timer(0.5).timeout
		await main.shot("wn_uchiha_bolge")
		c1.queue_free(); c2.queue_free()
		r0.talk()
		await get_tree().create_timer(0.4).timeout
		await main.shot("wn_sakin_diyalog")
		Hud.close_dialog()
	# ---------------- köy hayatı ara sokaklara yayılıyor mu (yola uzaklık dağılımı)
	var mid := Game.from_map(cen + Vector2(300, 200))
	main.player.respawn(mid)
	await get_tree().create_timer(14.0).timeout
	var life = get_tree().current_scene.find_child("VillageLife", true, false)
	if life:
		var off := 0
		var tot := 0
		for n in life.npcs:
			if not is_instance_valid(n) or not n is Villager:
				continue
			tot += 1
			var m := Game.to_map(n.global_position)
			var best := 1e9
			for e in Game.road_segments_near(m, 40.0):
				var rd: Dictionary = Game.roads[e.x]
				var a: Vector2 = rd["pts"][e.y]
				var b: Vector2 = rd["pts"][e.y + 1]
				var q := Geometry2D.get_closest_point_to_segment(m, a, b)
				best = minf(best, m.distance_to(q))
			if best > 7.0:
				off += 1
		var st: Array = life.street_cache.get("konoha", [])
		print("WN village life npcs=", tot, " off_road(>7m)=", off, " street_pts=", st.size())
		var cs := _cam(mid, mid + Vector3(30, 26, 30))
		await get_tree().create_timer(0.5).timeout
		await main.shot("wn_koy_hayati")
		cs.queue_free()
	# ---------------- Hyūga konağı
	var hp_ := Game.from_map(cen + Vector2(-1050, 250) + Vector2(-20, -30))
	main.player.respawn(hp_)
	await get_tree().create_timer(5.0).timeout
	var hy: Array = ClanWorld.residents("konoha").filter(func(r): return is_instance_valid(r) and r.clan == "hyuga")
	print("WN hyuga residents=", hy.size())
	if not hy.is_empty():
		var h0: Node3D = hy[0]
		var c3 := _cam(h0.global_position + Vector3.UP * 1.55, h0.global_position + Vector3(sin(h0.facing), 0, cos(h0.facing)) * -1.8 + Vector3(0, 1.65, 0))
		await get_tree().create_timer(0.6).timeout
		await main.shot("wn_hyuga_sakin")
		c3.queue_free()
	# ---------------- klan düşmanları (vahşi doğa)
	var wild := Game.from_map(cen + Vector2(0, -float(v["r"]) - 260))
	main.player.respawn(wild)
	await get_tree().create_timer(3.0).timeout
	for cl in ["uchiha", "hyuga", "kaguya", "nara", "akimichi", "aburame", "hozuki", "chinoike", "yuki", "sabaku", "yotsuki", "kako"]:
		var at: Vector3 = main.player.global_position + main.player.face_dir() * 7.0
		var e: Enemy = ClanWorld.spawn_enemy(cl, 30, at)
		print("WN clan ", cl, " jutsu=", e.arch["jutsu"], " eyes=", e.get_meta("eyes", {}))
		await get_tree().create_timer(0.3).timeout
		e.target = main.player
		var tr: ClanTrait = e.get_node("ClanTrait")
		tr.cd = 0.0
		await get_tree().create_timer(0.35).timeout
		if cl in ["uchiha", "hyuga", "kaguya", "nara", "akimichi", "chinoike", "aburame"]:
			var cam := _cam(e.global_position + Vector3.UP, main.player.global_position + Vector3(-6, 5, -6))
			await main.shot("wn_klan_%s" % cl)
			cam.queue_free()
		# bir jutsusunu da attır
		if not (e.arch["jutsu"] as Array).is_empty():
			Jutsu.execute(e, e.arch["jutsu"][0], main.player)
		await get_tree().create_timer(1.6).timeout
		await get_tree().create_timer(2.5).timeout
		if cl != "uchiha":
			e.die({})
		else:
			# göz çalma: öldür, beden kalsın, gözler alınabilsin
			e.die({})
			main.player.global_position = e.global_position + Vector3(1.5, 0, 0)
			await get_tree().create_timer(4.0).timeout
			var eyes_node = main.player.combat.modes.eyes if main.player.combat and main.player.combat.modes else null
			print("WN uchiha corpse valid=", is_instance_valid(e), " steal_target=", eyes_node.steal_target == e if eyes_node else "?")
			if eyes_node and eyes_node.steal_target == e:
				eyes_node._steal(e)
				print("WN eyes taken ok, goz_hirsizi=", Game.profile["flags"].get("goz_hirsizi", 0))
	print("WN partA done")
	get_tree().quit()


func _part_b(cen: Vector2, v: Dictionary) -> void:
	var wild := Game.from_map(cen + Vector2(0, -float(v["r"]) - 260))
	main.player.respawn(wild)
	await get_tree().create_timer(3.0).timeout
	# ---------------- efsaneler
	Game.profile["level"] = 80
	for i in 12:
		ClanWorld._seed_legends()
	var legends: Array = Missions._bingo()["list"].filter(func(x): return x.has("legend"))
	print("WN legends=", legends.size(), " ", legends.map(func(x): return "%s/%s" % [x["alias"], x["level"]]))
	var bbc: Array = []
	for i in 30:
		bbc.append(Missions._bb_new())
	print("WN bingo clan rogues ", bbc.filter(func(x): return x.has("clan")).size(), "/30: ", bbc.filter(func(x): return x.has("clan")).map(func(x): return x["name"]))
	if not legends.is_empty():
		var L: Dictionary = legends.filter(func(x): return x["legend"] == "senba")[0] if legends.any(func(x): return x["legend"] == "senba") else legends[0]
		var lp: Vector3 = main.player.global_position + main.player.face_dir() * 12.0
		var lm := Game.to_map(lp)
		L["hide"] = [lm.x, lm.y]
		Missions._bb_spawn(L, lp)
		await get_tree().create_timer(1.0).timeout
		var boss: Enemy = Missions._bb_spawned[int(L["id"])][0]
		print("WN legend spawned ", boss.display_name, " jutsu=", boss.arch["jutsu"], " eyes=", boss.get_meta("eyes", {}))
		var cl := _cam(boss.global_position + Vector3.UP * 1.4, boss.global_position + Vector3(sin(boss.facing), 0, cos(boss.facing)) * -4.0 + Vector3(1.5, 2.0, 0))
		await get_tree().create_timer(0.5).timeout
		await main.shot("wn_efsane")
		cl.queue_free()
		for n in Missions._bb_spawned[int(L["id"])]:
			if is_instance_valid(n):
				n.queue_free()
		Missions._bb_spawned.erase(int(L["id"]))
	# ---------------- karşılaşmalar
	for k in ["merchant", "rivals", "toll_fought", "contact", "child"]:
		Encounters.remember({"k": k, "name": "Test " + k, "vid": "konoha", "won": true})
	var kinds := ["performers", "shrine", "merchant", "duel", "wounded", "hunter", "patrol", "performers", "shrine", "rumor", "rivals", "toll", "lost_child", "clan_rogue", "sandstorm", "mist", "storm",
		"merchant_return", "rival_rematch", "toll_revenge", "contact", "child_gift"]
	for k in kinds:
		Encounters.start(k)
		await get_tree().create_timer(1.2).timeout
		var cur: Dictionary = Encounters.cur
		print("WN encounter ", k, " nodes=", cur.get("nodes", []).size(), " t=", Time.get_ticks_msec() / 1000)
		if k in ["performers", "shrine"] and not cur.is_empty():
			var c: Vector3 = cur["center"] if k not in ["storm", "mist", "sandstorm"] else main.player.global_position
			var cam := _cam(c + Vector3.UP * 1.2, c + Vector3(-9, 6, -9))
			main.player.global_position = c + Vector3(-5, 0, -5)
			await get_tree().create_timer(1.8 if k != "storm" else 3.0).timeout
			await main.shot("wn_enc_%s" % k)
			cam.queue_free()
		# NPC'lerle konuşma diyaloglarını da tetikle
		for n in cur.get("nodes", []):
			if is_instance_valid(n) and n is EncounterNPC:
				n.talk()
				await get_tree().create_timer(0.2).timeout
				Hud.close_dialog()
				break
		Encounters._abort()
		Game.world.env.region_weather = "açık"
		await get_tree().create_timer(0.3).timeout
	# kaçan kaçak -> intikam pususu
	Encounters.start("patrol")
	await get_tree().create_timer(1.0).timeout
	var pf: Array = Encounters.cur.get("foes", [])
	if not pf.is_empty():
		Encounters._escape(pf[0])
		print("WN escaped -> nemesis mem=", Encounters._has("nemesis"))
	Encounters._abort()
	Encounters.start("nemesis")
	await get_tree().create_timer(1.5).timeout
	print("WN nemesis foes=", Encounters.cur.get("foes", []).size())
	if not Encounters.cur.is_empty():
		var nb = Encounters.cur["foes"][0]
		var cn := _cam(nb.global_position + Vector3.UP * 1.3, nb.global_position + Vector3(-5, 3, -5))
		await get_tree().create_timer(0.5).timeout
		await main.shot("wn_enc_nemesis")
		cn.queue_free()
	print("WN done")
	get_tree().quit()
