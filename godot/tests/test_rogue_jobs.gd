extends Node
## Kaçak işleri: RJ=board,heist,smuggle,smuggle2,jail (virgülle), MV=köy
var main: Node
var cam: Camera3D
var pl: Node3D


func _camw(p: Vector3, t: Vector3) -> void:
	if cam == null or not is_instance_valid(cam):
		cam = Camera3D.new()
		main.add_child(cam)
		cam.fov = 50.0
	cam.global_position = p
	cam.look_at(t)
	cam.current = true


func _shot(nm: String) -> void:
	await get_tree().create_timer(0.05).timeout
	await main.shot("rj_" + nm)


func _works(kind: String) -> Array:
	return Interact.items.filter(func(it): return String(it.get("work", "")) == kind and it.get("qkey", "") == Missions._key())


func _wait_work(maxt := 20.0) -> void:
	var t := 0.0
	await get_tree().create_timer(0.1).timeout
	while MissionWork.active() and t < maxt:
		t += 0.1
		await get_tree().create_timer(0.1).timeout


func _begin(q: Dictionary) -> Dictionary:
	if not Missions.active().is_empty():
		Missions.abandon()
		await get_tree().create_timer(0.5).timeout
	if q.is_empty():
		print("RJ iş boş")
		return {}
	Missions.accept(q)
	await get_tree().create_timer(1.0).timeout
	var m = Missions.active()
	print("RJ start ", m["title"], " [", m["rank"], "] steps=", m["steps"].map(func(s): return s["kind"]))
	return m


func _orbit(c: Vector3, tag: String, d := 7.0, h := 3.0, angs := [0.6, 2.4, 4.2]) -> void:
	for i in angs.size():
		_camw(c + Vector3(cos(angs[i]) * d, h, sin(angs[i]) * d), c + Vector3.UP * 1.0)
		await _shot("%s_%d" % [tag, i])


func _cur_npc() -> Node3D:
	var s = Missions._cur()
	return Missions.npcs.get(s.get("npc_id", s.get("npc", {}).get("id", "")))


func _kill_foes(tag: String, shot := true) -> void:
	await get_tree().create_timer(0.6).timeout
	var foes = get_tree().get_nodes_in_group("fighters").filter(func(f): return f is Enemy and not f.is_dead() and f.get_meta("q", "") == Missions._key())
	print("RJ ", tag, " foes=", foes.size(), " names=", foes.map(func(f): return f.get("display_name")))
	if shot and not foes.is_empty():
		_camw(foes[0].global_position + Vector3(3.5, 2.0, 3.5), foes[0].global_position + Vector3.UP)
		await _shot(tag + "_foe")
	for f in foes:
		f.die({"attacker": pl})
	await get_tree().create_timer(1.5).timeout


func _goto_end(tag: String) -> void:
	var s = Missions._cur()
	if s.get("kind", "") == "goto":
		pl.global_position = Missions.open_ground(Missions._w(s["at"]) + Vector3(4, 0, 4), 12.0) + Vector3.UP * 0.3
		# takipçiler de gelsin
		for k in Missions.npcs:
			var n = Missions.npcs[k]
			if is_instance_valid(n) and n.mode == "follow":
				n.global_position = pl.global_position + Vector3(1.5, 0, 1.0)
	for w in 20:
		if Missions.active().is_empty():
			break
		await get_tree().create_timer(0.5).timeout
	print("RJ ", tag, " done=", Missions.active().is_empty(), " step=", Missions.active().get("step", -1), " infamy=", Orgs.infamy(), " news=", WorldNews.recent().slice(-1))


func _ready() -> void:
	await get_tree().process_frame
	var vid = OS.get_environment("MV") if OS.get_environment("MV") != "" else "konoha"
	var which = (OS.get_environment("RJ") if OS.get_environment("RJ") != "" else "board,heist,smuggle,smuggle2,jail").split(",")
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "soy": "shoton", "village": vid, "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	pl = main.player
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	print("RJ soy: natures=", Game.profile.get("natures"), " styles=", FightingStyles.available(Game.profile), " sel=", Game.profile.get("fight_style"), " key=", FightingStyles.player_key(Game.profile))
	main.world.env.time_of_day = 0.45
	Game.profile["kd_wait"] = 99999.0
	Game.profile["age"] = "adult"
	Game.profile["rank"] = 3
	Game.profile["ryo"] = 5000
	pl.model.apply_age("adult")
	Orgs.defect()
	await get_tree().create_timer(1.0).timeout
	Hud.close_dialog()
	seed(11)
	var W = MissionWork.I()
	var hp = Orgs.hideout_pos()
	print("RJ rogue=", Orgs.is_rogue(), " hideout=", hp, " d_village=", snappedf(Game.to_map(hp).distance_to(Vector2(Game.village(vid)["x"], Game.village(vid)["y"])), 1.0))
	pl.global_position = Orgs.hideout_spawn() + Vector3.UP * 0.3
	await get_tree().create_timer(2.0).timeout

	if "board" in which:
		var lst = Missions.board_missions("kacak")
		for m in lst:
			print("RJ board [", m["rank"], "] ", m["title"], " kind=", m.get("rjob", "eski"), " steps=", m["steps"].size(), " dyn=", m.get("dyn", false))
		Hud.show_mission_board("kacak")
		await get_tree().create_timer(1.0).timeout
		await main.shot("rj_board")
		Hud.close_dialog()
		Menus.clear()
		Game.ui_open = false
		await get_tree().create_timer(0.3).timeout

	if "heist" in which:
		seed(21)
		var t0 = Time.get_ticks_msec()
		var rs = RogueJobs.road_spot(350.0, 2400.0)
		print("RJ road_spot=", rs, " ms=", Time.get_ticks_msec() - t0, " d_hide=", snappedf(rs.distance_to(Orgs.hideout_pos()), 1.0), " dir=", MissionWork.road_dir(rs))
		var m = await _begin(RogueJobs.job_heist("C"))
		if not m.is_empty():
			var d = W.job_d
			var c: Vector3 = d["block_at"]
			print("RJ heist site=", d.get("kind"), " road=", Game.road_at(c.x, c.z), " dir=", d["dir"], " hide_d=", snappedf((d["hide"] as Vector3).distance_to(c), 0.1), " stash_d=", snappedf((d["stash"] as Vector3).distance_to(c), 0.1))
			pl.global_position = c + d["side"] * 4.0 + Vector3.UP * 0.3
			await get_tree().create_timer(1.2).timeout
			await _orbit(c, "heist_site", 13.0, 6.0, [0.6, 2.4, 4.2])
			var logs = _works("block")
			print("RJ logs=", logs.size())
			for i in logs.size():
				pl.global_position = logs[i]["node"].global_position + d["side"] * 1.6 + Vector3.UP * 0.2
				await get_tree().create_timer(0.3).timeout
				W.run(logs[i])
				if i == 0:
					for k in 4:
						await get_tree().create_timer(0.75).timeout
						_camw(pl.global_position + d["dir"] * 4.0 + Vector3.UP * 1.8 + d["side"] * 1.0, pl.global_position + Vector3.UP * 0.8)
						await _shot("heist_drag_%d" % k)
				await _wait_work()
				await get_tree().create_timer(0.3).timeout
			_camw(c + d["dir"] * 7.0 + Vector3.UP * 3.0 + d["side"] * 2.0, c + Vector3.UP * 0.3)
			await _shot("heist_blocked")
			print("RJ heist step=", Missions._cur().get("kind"), " placed=", d.get("placed"))
			# çalılıkta bekle, kervan gelsin
			pl.global_position = d["hide"] + Vector3.UP * 0.2
			await get_tree().create_timer(1.0).timeout
			var cv = W.caravan
			print("RJ caravan npc=", is_instance_valid(cv.get("npc")), " chests=", (d.get("chests", []) as Array).size(), " cart=", is_instance_valid(W.cart_d.get("cart")))
			if is_instance_valid(cv.get("npc")):
				var mer: Node3D = cv["npc"]
				var d0 = mer.global_position.distance_to(cv["stop"])
				await get_tree().create_timer(3.0).timeout
				var cart: Node3D = W.cart_d["cart"]
				_camw(cart.global_position + Vector3(4.5, 2.6, 4.5), cart.global_position + Vector3.UP * 1.3)
				await _shot("heist_caravan_road")
				_camw(cart.global_position + Vector3(-2.2, 2.6, -2.4), cart.global_position + Vector3.UP * 1.4)
				await _shot("heist_cart_chests")
				var wt := 0.0
				while not W.caravan.get("halted", true) and wt < 60.0:
					wt += 0.5
					await get_tree().create_timer(0.5).timeout
				print("RJ caravan walked ", snappedf(d0, 0.1), " m in ", wt, " s; halted=", W.caravan.get("halted"), " left=", snappedf(mer.global_position.distance_to(cv["stop"]), 0.1))
				await get_tree().create_timer(0.6).timeout
				_camw(c + d["side"] * 9.0 + Vector3.UP * 4.5 - d["dir"] * 2.0, (c + mer.global_position) * 0.5 + Vector3.UP * 0.8)
				await _shot("heist_halt")
				_camw(d["hide"] + Vector3.UP * 2.6 - d["side"] * 3.5, c + Vector3.UP * 0.5)
				await _shot("heist_from_bush")
			await _kill_foes("heist")
			print("RJ heist step=", Missions._cur().get("kind"), " work=", Missions._cur().get("work"), " n=", Missions._cur().get("n"))
			for i in 2:
				var loot = _works("loot")
				var stash = _works("stash")
				print("RJ loot items=", loot.size(), " stash items=", stash.size())
				if loot.is_empty() or stash.is_empty():
					break
				pl.global_position = loot[0]["node"].global_position + d["side"] * 1.8 + Vector3.UP * 0.2 - Vector3.UP * 1.0
				pl.global_position.y = Game.ground_height(pl.global_position.x, pl.global_position.z) + 0.2
				await get_tree().create_timer(0.3).timeout
				W.run(loot[0])
				if i == 0:
					await get_tree().create_timer(0.7).timeout
					_camw(pl.global_position + d["side"] * 3.0 + Vector3.UP * 1.8, pl.global_position + Vector3.UP * 1.1)
					await _shot("heist_take")
				await _wait_work()
				if i == 0:
					for k in 3:
						var a = [0.5, 2.6, 4.4][k]
						_camw(pl.global_position + Vector3(cos(a) * 3.0, 1.6, sin(a) * 3.0), pl.global_position + Vector3.UP * 1.2)
						await _shot("heist_carry_%d" % k)
				pl.global_position = d["stash"] + Vector3(1.6, 0.2, 1.2)
				await get_tree().create_timer(0.3).timeout
				W.run(stash[0])
				if i == 0:
					await get_tree().create_timer(0.6).timeout
					_camw(d["stash"] + Vector3(2.6, 1.6, -2.4), d["stash"] + Vector3.UP * 0.6)
					await _shot("heist_stash_a")
				await _wait_work()
				await get_tree().create_timer(0.8).timeout
				print("RJ stashed=", d.get("stashed"), " st.n=", Missions.st.get("n"), " step=", Missions.active().get("step", -1))
			_camw(d["stash"] + Vector3(2.2, 1.5, 2.2), d["stash"] + Vector3.UP * 0.5)
			await _shot("heist_stash_done")
			await _goto_end("heist")

	for variant in ["smuggle", "smuggle2"]:
		if not variant in which:
			continue
		seed(31)
		var cover = variant == "smuggle"
		var m = await _begin(RogueJobs.job_smuggle("C"))
		if m.is_empty():
			continue
		var d = W.job_d
		var c: Vector3 = d["root"].global_position
		print("RJ smuggle site=", d.get("kind"), " d_hideout=", snappedf(c.distance_to(Orgs.hideout_spawn()), 0.1))
		pl.global_position = c + Vector3(2.5, 0.3, 3.0)
		await get_tree().create_timer(1.0).timeout
		if cover:
			await _orbit(c, "smug_site", 4.5, 2.2, [0.9, 2.6])
		var pk = _works("pack")
		print("RJ pack items=", pk.size())
		pl.global_position = c + Vector3(0.3, 0.2, 1.6)
		await get_tree().create_timer(0.3).timeout
		W.run(pk[0])
		if cover:
			await get_tree().create_timer(0.8).timeout
			_camw(c + Vector3(2.6, 1.5, 2.6), c + Vector3.UP * 0.7)
			await _shot("smug_load")
		await _wait_work()
		await get_tree().create_timer(0.3).timeout
		var opts = _works("pack")
		print("RJ pack choices=", opts.map(func(x): return x.get("mode")), " step=", Missions.active().get("step", -1))
		var pick = opts.filter(func(x): return String(x.get("mode", "")) == ("cover" if cover else "go"))
		if pick.is_empty():
			continue
		W.run(pick[0])
		await _wait_work()
		await get_tree().create_timer(0.5).timeout
		if cover:
			for k in 3:
				var a = [0.5, 2.6, 4.4][k]
				_camw(pl.global_position + Vector3(cos(a) * 2.4, 1.6, sin(a) * 2.4), pl.global_position + Vector3.UP * 1.1)
				await _shot("smug_basket_%d" % k)
		print("RJ smuggle flags=", Missions.active().get("flags"), " step=", Missions._cur().get("kind"), " rider=", W.rider_kind)
		# karakol
		var g = _cur_npc()
		if g == null:
			print("RJ nöbetçi yok")
			continue
		pl.global_position = g.global_position + g.face_dir() * 1.9 + Vector3.UP * 0.2
		await get_tree().create_timer(1.2).timeout
		if cover:
			await _orbit(g.global_position, "smug_post", 9.0, 4.0, [0.8, 2.9])
		g.talk()
		await get_tree().create_timer(0.3).timeout
		print("RJ guard line: ", Hud.last_dialog.substr(0, 60), " opts=", Hud.last_options.size())
		Hud.last_options[0]["cb"].call()
		for k in 3:
			await get_tree().create_timer(0.9).timeout
			var cc = (pl.global_position + g.global_position) * 0.5
			_camw(cc + Vector3(2.4, 1.6, 2.0) * (1.0 if k % 2 == 0 else -1.0) + Vector3.UP * (0.0 if k % 2 == 0 else 3.2), cc + Vector3.UP * 0.9)
			await _shot("%s_inspect_%d" % [("smug_ok" if cover else "smug_bad"), k])
		await _wait_work()
		await get_tree().create_timer(0.5).timeout
		print("RJ inspect reply: ", Hud.last_dialog.substr(0, 60), " flags=", Missions.active().get("flags"))
		Hud.last_options[0]["cb"].call()
		await get_tree().create_timer(3.0).timeout
		print("RJ after post step=", Missions._cur().get("kind"), " text=", Missions._cur().get("text"))
		if Missions._cur().get("kind", "") == "kill":
			await _kill_foes("smug_fight")
		# alıcı
		var by = _cur_npc()
		print("RJ buyer=", by != null, " step=", Missions._cur().get("kind"))
		if by != null and Missions._cur().get("kind", "") == "talk":
			pl.global_position = by.global_position + by.face_dir() * 1.7 + Vector3.UP * 0.2
			await get_tree().create_timer(0.8).timeout
			by.talk()
			await get_tree().create_timer(0.2).timeout
			Missions._after_talk(by, Missions._cur())
			if cover:
				for k in 3:
					await get_tree().create_timer(0.8).timeout
					var cc2 = (pl.global_position + by.global_position) * 0.5
					_camw(cc2 + Vector3(2.4, 1.5, 2.0), cc2 + Vector3.UP * 0.7)
					await _shot("smug_deliver_%d" % k)
			await _wait_work()
			await get_tree().create_timer(0.5).timeout
		var ryo0 = int(Game.profile["ryo"])
		await _goto_end(variant)
		print("RJ ", variant, " ryo ", ryo0, " -> ", int(Game.profile["ryo"]))

	if "jail" in which:
		seed(41)
		var m = await _begin(RogueJobs.job_jail("C"))
		if not m.is_empty():
			await get_tree().create_timer(0.5).timeout
			var d = W.job_d
			var c: Vector3 = d["root"].global_position
			var pr = Missions.npcs.get("tutsak")
			print("RJ jail site=", d.get("kind"), " prisoner=", is_instance_valid(pr), " name=", pr.display if is_instance_valid(pr) else "", " bound=", W.bound_d.has(pr))
			pl.global_position = c + Vector3(3, 0.3, 8)
			await get_tree().create_timer(1.2).timeout
			await _orbit(c, "jail_site", 8.5, 3.4, [0.9, 1.8, 2.7, 4.6])
			_camw(c + Vector3(0.8, 1.5, 3.4), c + Vector3(0, 1.0, 0))
			await _shot("jail_prisoner")
			await _kill_foes("jail")
			var cg = _works("cage")
			print("RJ cage items=", cg.size(), " step=", Missions._cur().get("kind"))
			if not cg.is_empty():
				pl.global_position = d["front"] + Vector3(0.5, 0.2, 1.5)
				await get_tree().create_timer(0.3).timeout
				W.run(cg[0])
				for k in 4:
					await get_tree().create_timer(0.7).timeout
					_camw(d["front"] + Vector3(2.4, 1.5, 1.4), d["lock"].global_position if is_instance_valid(d["lock"]) else c)
					await _shot("jail_lock_%d" % k)
				await _wait_work()
				await get_tree().create_timer(1.0).timeout
				_camw(c + Vector3(3.5, 2.2, 6.0), c + Vector3.UP * 1.0)
				await _shot("jail_open")
			print("RJ jail step=", Missions._cur().get("kind"), " door_off=", (d["door_cs"] as CollisionShape3D).disabled)
			if Missions._cur().get("kind", "") == "talk" and is_instance_valid(pr):
				pl.global_position = d["front"] + Vector3(-0.8, 0.2, 0.2)
				await get_tree().create_timer(0.4).timeout
				pr.talk()
				await get_tree().create_timer(0.2).timeout
				print("RJ prisoner line: ", Hud.last_dialog.substr(0, 60))
				Missions._after_talk(pr, Missions._cur())
				for k in 3:
					await get_tree().create_timer(0.8).timeout
					_camw(c + Vector3(2.6, 1.6, 4.2), c + Vector3(0, 0.9, 0.6))
					await _shot("jail_untie_%d" % k)
				await _wait_work()
				await get_tree().create_timer(0.5).timeout
				print("RJ prisoner mode=", pr.mode, " bound=", W.bound_d.has(pr))
				# kafesten çıkabiliyor mu
				pl.global_position = c + Vector3(0, 0.2, 9.0)
				await get_tree().create_timer(4.0).timeout
				print("RJ prisoner out d_cell=", snappedf(pr.global_position.distance_to(d["cell"]), 0.1), " d_player=", snappedf(pr.global_position.distance_to(pl.global_position), 0.1))
				_camw(c + Vector3(5, 3, 10), (c + pl.global_position) * 0.5 + Vector3.UP)
				await _shot("jail_follow")
			await _goto_end("jail")
	if "decoy" in which:
		seed(51)
		var m = await _begin(RogueJobs.job_decoy("C"))
		if not m.is_empty():
			var bd: Dictionary = W.sites["%s:beacon0" % String(m["id"])]
			var d = W.job_d
			var dc: Vector3 = d["root"].global_position
			print("RJ decoy depot=", d.get("kind"), " guards=", (W.decoy.get("guards", []) as Array).size(), " d_beacon_depot=", snappedf(dc.distance_to(bd["root"].global_position), 1.0), " tod=", snappedf(main.world.env.time_of_day, 0.01))
			pl.global_position = dc + Vector3(14, 0.3, 14)
			await get_tree().create_timer(1.5).timeout
			main.world.env.time_of_day = 0.45
			await _orbit(dc, "decoy_depot", 8.5, 3.6, [0.9, 1.6, 2.4])
			main.world.env.time_of_day = 0.86
			var it = _works("decoy")
			print("RJ decoy items=", it.size())
			pl.global_position = bd["torch_at"] + Vector3(0.5, 0.2, 2.5)
			await get_tree().create_timer(0.5).timeout
			W.run(it[0])
			for k in 3:
				await get_tree().create_timer(0.9).timeout
				_camw(bd["root"].global_position + Vector3(4.5, 2.6, 5.0), bd["root"].global_position + Vector3.UP * 1.6)
				await _shot("decoy_light_%d" % k)
			await _wait_work()
			await get_tree().create_timer(0.5).timeout
			var g0 = W.decoy["guards"][0]
			print("RJ decoy run=", W.decoy.get("run"), " g_mode=", g0.mode, " g_d_depot=", snappedf(g0.global_position.distance_to(dc), 0.1), " step=", Missions._cur().get("work"))
			# nöbetçilerin koşusu (oyuncu uzakta, kamera depoda)
			pl.global_position = dc + Vector3(-40, 0.3, 30)
			await get_tree().create_timer(2.0).timeout
			_camw(g0.global_position + Vector3(5, 2.5, 5), g0.global_position + Vector3.UP)
			await _shot("decoy_guards_run")
			var wt := 0.0
			while is_instance_valid(g0) and g0.global_position.distance_to(W.decoy["to"]) > 5.0 and wt < 70.0:
				wt += 0.5
				await get_tree().create_timer(0.5).timeout
			print("RJ decoy guards at beacon in ", wt, " s; seen=", W.decoy.get("seen"))
			_camw(bd["root"].global_position + Vector3(6, 3, 7), bd["root"].global_position + Vector3.UP * 1.5)
			await _shot("decoy_guards_at_fire")
			var sk = _works("sack")
			print("RJ decoy sack items=", sk.size())
			if not sk.is_empty():
				pl.global_position = d["sack_at"] + Vector3(0.6, 0.2, 1.6)
				await get_tree().create_timer(0.4).timeout
				_camw(dc + Vector3(1.5, 2.0, 6.0), dc + Vector3.UP)
				await _shot("decoy_empty_depot")
				W.run(sk[0])
				await get_tree().create_timer(0.8).timeout
				await _shot("decoy_take")
				await _wait_work()
				await get_tree().create_timer(0.6).timeout
				_camw(pl.global_position + Vector3(2.5, 1.6, 2.5), pl.global_position + Vector3.UP)
				await _shot("decoy_carry")
			await _goto_end("decoy")
	main.world.env.time_of_day = 0.45

	if "decoy2" in which:
		# görülme: nöbetçilerin yoluna çık
		seed(52)
		var m = await _begin(RogueJobs.job_decoy("C"))
		if not m.is_empty():
			var bd: Dictionary = W.sites["%s:beacon0" % String(m["id"])]
			var it = _works("decoy")
			pl.global_position = bd["torch_at"] + Vector3(0.5, 0.2, 2.5)
			await get_tree().create_timer(0.5).timeout
			W.run(it[0])
			await _wait_work()
			var wt := 0.0
			while not W.decoy.get("seen", false) and wt < 70.0:
				wt += 0.5
				await get_tree().create_timer(0.5).timeout
			var foes = get_tree().get_nodes_in_group("fighters").filter(func(f): return f is Enemy and not f.is_dead() and f.global_position.distance_to(pl.global_position) < 25.0 and Combat.hostile(pl, f))
			print("RJ decoy2 seen=", W.decoy.get("seen"), " after ", wt, " s; foes=", foes.size(), " flags=", Missions.active().get("flags"))
			Missions.abandon()
	if "hut" in which:
		for round in 2:
			seed(61)
			print("RJ hut board has job=", Missions.board_missions("kacak", true).any(func(x): return x.get("rjob", "") == "hut"), " state='", RogueHut.state(), "'")
			var m = await _begin(RogueJobs.job_hut())
			var d = W.job_d
			var c: Vector3 = d["root"].global_position
			print("RJ hut title=", m["title"], " d_hideout=", snappedf(c.distance_to(Orgs.hideout_spawn()), 0.1), " hut_at=", m.get("hut_at"), " old_node=", is_instance_valid(RogueHut.node))
			var u = _cur_npc()
			pl.global_position = u.global_position + Vector3(1.6, 0.2, 0.4)
			await get_tree().create_timer(0.6).timeout
			u.talk()
			await get_tree().create_timer(0.3).timeout
			Missions._after_talk(u, Missions._cur())
			await get_tree().create_timer(0.8).timeout
			for stg in 4:
				var its = _works("build")
				if its.is_empty():
					print("RJ hut build item yok stage=", stg)
					break
				pl.global_position = c + Vector3(2, 0.2, 4)
				await get_tree().create_timer(0.2).timeout
				W.run(its[0])
				await _wait_work()
				await get_tree().create_timer(0.3).timeout
			if round == 0:
				_camw(c + Vector3(6.5, 3.6, 7.5), c + Vector3.UP * 1.8)
				await _shot("hut_built_site")
			u = _cur_npc()
			if u != null and Missions._cur().get("kind", "") == "talk":
				pl.global_position = u.global_position + Vector3(1.6, 0.2, 0.4)
				await get_tree().create_timer(0.4).timeout
				u.talk()
				await get_tree().create_timer(0.3).timeout
				Missions._after_talk(u, Missions._cur())
			for w in 20:
				if Missions.active().is_empty():
					break
				await get_tree().create_timer(0.5).timeout
			await get_tree().create_timer(1.0).timeout
			var hp2 = Missions._w(RogueHut.d().get("at", [0, 0]))
			print("RJ hut done=", Missions.active().is_empty(), " flags=", RogueHut.d(), " node=", is_instance_valid(RogueHut.node), " d_site=", snappedf(Vector2(hp2.x - c.x, hp2.z - c.z).length(), 0.01), " infamy=", Orgs.infamy())
			if round == 1:
				_camw(c + Vector3(6.5, 3.0, 3.5), c + Vector3.UP * 1.5)
				await _shot("hut_rebuilt")
				break
			var hc: Vector3 = RogueHut.node.global_position
			pl.global_position = hc + Vector3(5, 0.3, 1)
			await get_tree().create_timer(0.5).timeout
			await _orbit(hc, "hut_empty", 7.0, 3.0, [0.0, 1.2, 3.6])
			RogueHut.add_loot("chest", 4)
			RogueHut.add_loot("sack", 3)
			await get_tree().create_timer(0.6).timeout
			_camw(hc + Vector3(5.0, 1.8, 0.6), hc + Vector3.UP * 1.1)
			await _shot("hut_loot_front")
			_camw(hc + Vector3(4.0, 2.6, 2.6), hc + Vector3.UP * 0.9)
			await _shot("hut_loot_side")
			var hi = Interact.items.filter(func(x): return x.get("kind", "") == "rogue_hut")
			pl.hp = 10.0
			RogueHut.use()
			print("RJ hut rest items=", hi.size(), " hp=", pl.hp, "/", pl.max_hp)
			# baskın: uzaktayken yakılır
			RogueHut.d()["raid"] = true
			pl.global_position = Missions.open_ground(hc + Vector3(320, 0, 0), 20.0) + Vector3.UP * 0.3
			await get_tree().create_timer(1.5).timeout
			print("RJ hut raid state=", RogueHut.state(), " loot=", RogueHut.loot(), " news=", WorldNews.recent().slice(-1))
			pl.global_position = hc + Vector3(6, 0.3, 2)
			await get_tree().create_timer(1.5).timeout
			await _orbit(hc, "hut_burnt", 6.5, 2.8, [0.3, 2.2, 4.2])
			var hb = Interact.items.filter(func(x): return x.get("kind", "") == "rogue_hut")
			print("RJ hut burnt items=", hb.map(func(x): return x["label"]))
	if "poach" in which:
		seed(71)
		var m = await _begin(RogueJobs.job_poach("C"))
		var kn = _cur_npc()
		pl.global_position = kn.global_position + Vector3(1.6, 0.2, 0.4)
		await get_tree().create_timer(0.8).timeout
		kn.talk()
		await get_tree().create_timer(0.3).timeout
		Missions._after_talk(kn, Missions._cur())
		await get_tree().create_timer(0.8).timeout
		var prey: Array = W.hunt_d.get("prey", [])
		print("RJ poach prey=", prey.size(), " kind=", W.hunt_d.get("kind"))
		for i in prey.size():
			var p: Prey = prey[i]
			pl.global_position = p.global_position - p.face_dir() * 2.0 + Vector3.UP * 0.2
			p.take_hit({"dmg": 999.0, "attacker": pl})
			await get_tree().create_timer(1.2).timeout
			var its = _works("carcass")
			if its.is_empty():
				break
			W.run(its[0])
			await _wait_work()
			var rk = _works("rack")
			pl.global_position = W.hunt_d["rack_front"] + Vector3(0.5, 0.2, 2.5)
			await get_tree().create_timer(0.3).timeout
			W.run(rk[0])
			await _wait_work()
			await get_tree().create_timer(1.6).timeout
		print("RJ poach step=", Missions._cur().get("kind"), " text=", Missions._cur().get("text"))
		var ko = _cur_npc()
		if ko != null:
			var stop = Missions._w(Missions._cur()["at"])
			pl.global_position = stop + Vector3(1.5, 0.3, 1.0)
			await get_tree().create_timer(2.0).timeout
			_camw(stop + Vector3(4, 2.4, 3), ko.global_position + Vector3.UP)
			print("RJ keeper start d=", snappedf(ko.global_position.distance_to(stop), 0.1))
			_camw(ko.global_position + (stop - ko.global_position).normalized() * 5.0 + Vector3.UP * 1.8, ko.global_position + Vector3.UP)
			await _shot("poach_keeper_comes")
			var wt := 0.0
			while ko.global_position.distance_to(stop) > 2.5 and wt < 40.0:
				wt += 0.5
				await get_tree().create_timer(0.5).timeout
			print("RJ keeper arrived in ", wt, " s d=", snappedf(ko.global_position.distance_to(stop), 0.1), " mode=", ko.mode)
			pl.global_position = ko.global_position + Vector3(1.4, 0.2, 0.6)
			await get_tree().create_timer(0.3).timeout
			ko.talk()
			await get_tree().create_timer(0.3).timeout
			var ryo0 = int(Game.profile["ryo"])
			print("RJ keeper line: ", Hud.last_dialog.substr(0, 50), " opts=", Hud.last_options.map(func(o): return o["label"]))
			Hud.last_options[0]["cb"].call()
			await get_tree().create_timer(0.5).timeout
			print("RJ bribe reply: ", Hud.last_dialog.substr(0, 50), " ryo ", ryo0, " -> ", int(Game.profile["ryo"]), " flags=", Missions.active().get("flags"))
			Hud.last_options[0]["cb"].call()
			await get_tree().create_timer(2.0).timeout
		print("RJ poach step=", Missions._cur().get("kind"), " text=", Missions._cur().get("text"))
		# izler: biri silinir
		await get_tree().create_timer(0.5).timeout
		var tr = _works("trace")
		print("RJ traces=", tr.size())
		if not tr.is_empty():
			var tp: Vector3 = tr[0]["node"].global_position
			_camw(tp + Vector3(1.6, 1.3, 1.6), tp)
			await _shot("trace_prints")
			if tr.size() > 1:
				var tp2: Vector3 = tr[1]["node"].global_position
				_camw(tp2 + Vector3(1.4, 1.1, 1.4), tp2)
				await _shot("trace_cloth")
			pl.global_position = tp + Vector3(1.2, 0.2, 0.6)
			await get_tree().create_timer(0.3).timeout
			W.run(tr[0])
			await get_tree().create_timer(0.7).timeout
			_camw(tp + Vector3(2.4, 1.4, 2.0), tp + Vector3.UP * 0.4)
			await _shot("trace_wipe")
			await _wait_work()
		var ks = _cur_npc()
		if ks != null and Missions._cur().get("kind", "") == "talk":
			pl.global_position = ks.global_position + Vector3(1.6, 0.2, 0.4)
			await get_tree().create_timer(0.4).timeout
			ks.talk()
			await get_tree().create_timer(0.3).timeout
			Missions._after_talk(ks, Missions._cur())
		for w in 20:
			if Missions.active().is_empty():
				break
			await get_tree().create_timer(0.5).timeout
		print("RJ poach done=", Missions.active().is_empty(), " trail=", snappedf(RogueJobs.trail(), 0.1), " infamy=", Orgs.infamy())

	if "fence" in which:
		seed(81)
		if RogueHut.state() != "ok":
			var hp3 = Game.to_map(Missions.open_ground(Orgs.hideout_spawn() + Vector3(30, 0, 20), 20.0))
			RogueHut.built([hp3.x, hp3.y])
		RogueHut.add_loot("chest", 3)
		RogueHut.add_loot("sack", 2)
		await get_tree().create_timer(0.5).timeout
		print("RJ fence board=", Missions.board_missions("kacak", true).any(func(x): return x.get("rjob", "") == "fence"), " loot=", RogueHut.loot())
		var m = await _begin(Missions.board_missions("kacak").filter(func(x): return x.get("rjob", "") == "fence")[0])
		var hc = Missions._w(RogueHut.d()["at"])
		var lt = _works("loot")
		print("RJ fence loot items=", lt.size())
		if not lt.is_empty():
			pl.global_position = lt[0]["node"].global_position + Vector3(1.6, 0.3, 0.8)
			await get_tree().create_timer(0.6).timeout
			_camw(hc + Vector3(6.0, 2.4, 3.0), hc + Vector3(1.5, 0.8, 0.5))
			await _shot("fence_sample")
			W.run(lt[0])
			await _wait_work()
			await get_tree().create_timer(0.6).timeout
			print("RJ fence step=", Missions._cur().get("kind"), " rider=", W.rider_kind)
			var f = _cur_npc()
			pl.global_position = f.global_position + f.face_dir() * 1.8 + Vector3.UP * 0.2
			await get_tree().create_timer(0.8).timeout
			var ryo0 = int(Game.profile["ryo"])
			f.talk()
			await get_tree().create_timer(0.3).timeout
			Missions._after_talk(f, Missions._cur())
			for k in 3:
				await get_tree().create_timer(0.8).timeout
				var cc = (pl.global_position + f.global_position) * 0.5
				_camw(cc + Vector3(2.4, 1.5, 2.0), cc + Vector3.UP * 0.6)
				await _shot("fence_deal_%d" % k)
			await _wait_work()
			for w in 20:
				if Missions.active().is_empty():
					break
				await get_tree().create_timer(0.5).timeout
			print("RJ fence done=", Missions.active().is_empty(), " ryo ", ryo0, " -> ", int(Game.profile["ryo"]), " loot=", RogueHut.loot(), " infamy=", Orgs.infamy())
	get_tree().quit()
