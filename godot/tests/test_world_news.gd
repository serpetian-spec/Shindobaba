extends Node
## Görev işleri (D rütbe): gerçek nesne + hareket. MW=weeds,fence,herb,cat,baby (virgülle), MV=köy
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
	await main.shot("mw_" + nm)


func _side(target: Vector3, d := 2.6, h := 1.1, sg := 1.0) -> void:
	var fd = pl.face_dir()
	var c = (pl.global_position + target) * 0.5
	_camw(c + fd.cross(Vector3.UP).normalized() * d * sg + Vector3.UP * h + fd * 0.4, c + Vector3.UP * 0.6)


func _start(q: Dictionary, rank := "D") -> Dictionary:
	if not Missions.active().is_empty():
		Missions.abandon()
		await get_tree().create_timer(0.5).timeout
	q["rank"] = rank
	q["village"] = Progress.home()
	q["type"] = "quest"
	q["giver"] = "Görev Masası"
	Missions.accept(q)
	await get_tree().create_timer(0.8).timeout
	var m = Missions.active()
	print("MW start ", m["title"], " steps=", m["steps"].map(func(s): return s["kind"]), " step=", m["step"])
	return m


func _works(kind: String) -> Array:
	return Interact.items.filter(func(it): return String(it.get("work", "")) == kind and it.get("qkey", "") == Missions._key())


func _wait_work(maxt := 20.0) -> void:
	var t := 0.0
	await get_tree().create_timer(0.1).timeout
	while MissionWork.active() and t < maxt:
		t += 0.1
		await get_tree().create_timer(0.1).timeout


## Bir iş nesnesini yap; ara karelerde yandan çek
func _do(it: Dictionary, tag: String, times: Array, d := 2.4, h := 1.0) -> void:
	var node: Node3D = it["node"]
	var np = node.global_position
	var away = Vector3(1, 0, 0.3).normalized()
	if it.has("nrm"):
		away = it["nrm"]
	pl.global_position = np + away * 1.6 + Vector3.UP * 0.2
	pl.velocity = Vector3.ZERO
	await get_tree().create_timer(0.4).timeout
	Missions.on_interact(it)
	var t := 0.0
	var i := 0
	while MissionWork.active() and t < 14.0:
		if i < times.size() and t >= float(times[i]):
			_side(np, d, h, 1.0 if i % 2 == 0 else -1.0)
			if it.has("nrm"):
				var tn = Vector3(away.z, 0, -away.x)
				_camw(np + away * (0.55 if i % 2 == 0 else 1.9) + tn * (2.5 if i % 2 == 0 else -1.6) + Vector3.UP * 1.25, np + Vector3.UP * 0.8 + away * 0.45)
			await _shot("%s_%d" % [tag, i])
			i += 1
		t += 0.05
		await get_tree().create_timer(0.05).timeout
	print("MW do ", tag, " t=", snappedf(t, 0.1), " shots=", i, " locked=", pl.input_locked, " hold=", pl.get("scene_hold"), " lift=", pl.model_lift)


func _talk_cur() -> void:
	var s = Missions._cur()
	var id = s.get("npc_id", s.get("npc", {}).get("id", ""))
	var npc = Missions.npcs.get(id)
	if npc == null or not is_instance_valid(npc):
		print("MW talk: npc yok ", id)
		return
	var t := 0.0
	while not npc.visible and t < 3.0:
		t += 0.1
		await get_tree().create_timer(0.1).timeout
	pl.global_position = npc.global_position + Vector3(1.6, 0.2, 0.4)
	await get_tree().create_timer(0.3).timeout
	npc.talk()
	await get_tree().create_timer(0.3).timeout
	Missions._after_talk(npc, s)


## Konuşma: diyalog aç, teslim/ödeme sahnesini çek
func _talk_scene(tag: String, n_shots := 0, gap := 0.7) -> void:
	var s = Missions._cur()
	var id = s.get("npc_id", s.get("npc", {}).get("id", ""))
	var npc = Missions.npcs.get(id)
	if npc == null or not is_instance_valid(npc):
		print("MW talk: npc yok ", id, " step=", s.get("kind"))
		return
	pl.global_position = npc.global_position + npc.face_dir() * 1.7 + Vector3.UP * 0.2
	await get_tree().create_timer(0.4).timeout
	npc.talk()
	await get_tree().create_timer(0.2).timeout
	Missions._after_talk(npc, s)
	for i in n_shots:
		await get_tree().create_timer(gap).timeout
		if not is_instance_valid(npc):
			break
		var c = (pl.global_position + npc.global_position) * 0.5
		var d = (npc.global_position - pl.global_position).normalized().cross(Vector3.UP)
		_camw(c + d * 2.6 + Vector3.UP * 1.3, c + Vector3.UP * 0.95)
		await _shot("%s_%d" % [tag, i])
	await _wait_work()
	await get_tree().create_timer(0.3).timeout


func _npc_shots(id: String, tag: String, n := 2) -> void:
	var npc = Missions.npcs.get(id)
	if npc == null or not is_instance_valid(npc):
		print("MW npc yok: ", id)
		return
	pl.global_position = npc.global_position + npc.face_dir() * 5.0 + Vector3(1.5, 0.2, 0)
	await get_tree().create_timer(1.2).timeout
	var f = npc.face_dir()
	var r = f.cross(Vector3.UP).normalized()
	_camw(npc.global_position + f * 4.2 + r * 3.2 + Vector3.UP * 2.3, npc.global_position + Vector3.UP * 1.0)
	await _shot(tag + "_wide")
	for i in n:
		_camw(npc.global_position + f * 1.9 + r * (1.3 if i % 2 == 0 else -1.3) + Vector3.UP * 1.3, npc.global_position + Vector3.UP * 1.0)
		await _shot("%s_%d" % [tag, i])
		await get_tree().create_timer(0.5).timeout


func _begin(q: Dictionary) -> Dictionary:
	if not Missions.active().is_empty():
		Missions.abandon()
		await get_tree().create_timer(0.5).timeout
	Missions.accept(q)
	await get_tree().create_timer(0.8).timeout
	var m = Missions.active()
	print("WN start ", m["title"], " [", m["rank"], "] steps=", m["steps"].map(func(s): return s["kind"]), " news=", m.get("news"))
	return m


func _finish_wait(tag: String) -> void:
	for w in 60:
		if Missions.active().is_empty():
			break
		await get_tree().create_timer(0.5).timeout
	print("WN ", tag, " done=", Missions.active().is_empty(), " news=", WorldNews.recent().slice(-1))


func _ready() -> void:
	await get_tree().process_frame
	var vid = OS.get_environment("MV") if OS.get_environment("MV") != "" else "konoha"
	var which = (OS.get_environment("WN") if OS.get_environment("WN") != "" else "missing,robbed,deserter,band,fire,expire,board").split(",")
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": vid, "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	pl = main.player
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	main.world.env.time_of_day = 0.45
	Game.profile["kd_wait"] = 99999.0
	Game.profile["age"] = "adult"
	Game.profile["rank"] = 3
	pl.model.apply_age("adult")
	seed(7)
	if not WorldPeople.data().get("init", false):
		WorldPeople.populate()
	var folk = WorldPeople.all().values().filter(func(p): return String(p["village"]) == vid and WorldPeople.alive(p) and not WorldPeople.is_rogue(p))
	print("WN folk=", folk.size())
	var fi = 0

	if "missing" in which:
		var p = folk[fi]; fi += 1
		# yakını olsun: evlendir
		WorldKin._marry(p)
		print("WN missing person=", p["name"], " rank=", p["rank"], " spouse=", WorldKin.spouse_of(p).get("name", "-"))
		var inc = WorldNews.add("missing", vid, String(p["id"]))
		p["missing"] = true
		var q = WorldNews.mission_for(inc)
		await _begin(q)
		for k in 3:
			if Missions._cur().get("kind", "") == "kill":
				break
			Missions._next_step()
			await get_tree().create_timer(0.5).timeout
		main.world.env.time_of_day = 0.45
		print("WN missing lair=", Missions.st.get("lair"), " lair_h=", Missions.active().get("lair_h"))
		var h = Missions.npcs.get("rehine")
		if h == null:
			var door = Interact.items.filter(func(x): return String(x.get("room", "")).begins_with("lair_"))
			if not door.is_empty():
				pl.global_position = door[0]["pos"] + Vector3(0, 0.3, 0)
				await get_tree().create_timer(0.3).timeout
				Interiors.inst.enter(door[0])
				await get_tree().create_timer(2.5).timeout
				h = Missions.npcs.get("rehine")
		print("WN missing hostage=", h != null, " name=", h.display if h else "")
		for e in Missions.step_nodes:
			if is_instance_valid(e) and e is Enemy:
				e.queue_free()
		await get_tree().create_timer(0.2).timeout
		Missions._next_step()
		await get_tree().create_timer(0.5).timeout
		if h:
			pl.global_position = h.global_position + h.face_dir() * 1.8 + Vector3.UP * 0.2
			await get_tree().create_timer(0.4).timeout
			_camw(h.global_position + h.face_dir() * 2.6 + Vector3(1.0, 1.2, 0), h.global_position + Vector3.UP * 0.6)
			await _shot("wn_missing_bound")
			Missions._after_talk(h, Missions._cur())
			await _wait_work()
			await get_tree().create_timer(0.5).timeout
			if Interiors.inst and Interiors.inst.inside != "":
				Interiors.inst.exit()
				await get_tree().create_timer(2.5).timeout
			var kin = Missions.npcs.get("yakin")
			print("WN missing kin=", kin.display if kin else "yok", " step=", Missions._cur().get("text"))
			if kin:
				var side = kin.face_dir().cross(Vector3.UP).normalized()
				pl.global_position = kin.global_position + kin.face_dir() * 1.7 + Vector3.UP * 0.2
				h.global_position = kin.global_position + kin.face_dir() * 3.5 + side * 1.5 + Vector3.UP * 0.2
				await get_tree().create_timer(0.5).timeout
				kin.talk()
				await get_tree().create_timer(0.2).timeout
				Missions._after_talk(kin, Missions._cur())
				for i in 2:
					await get_tree().create_timer(1.6).timeout
					var c6 = (h.global_position + kin.global_position) * 0.5
					var d6 = (h.global_position - kin.global_position)
					d6.y = 0
					_camw(c6 + d6.normalized().cross(Vector3.UP) * 2.8 + Vector3.UP * 1.3, c6 + Vector3.UP * 1.0)
					await _shot("wn_missing_reunion_%d" % i)
				await _finish_wait("missing")
				print("WN missing flag=", p.get("missing"), " log=", (p["log"] as Array).slice(-1), " open=", WorldNews.open_for(vid).size())

	if "robbed" in which or "deserter" in which:
		var rg = folk[fi]; fi += 1
		rg["level"] = 80
		WorldPeople.defect(rg, "Güç peşinde köyünden kaçtı")
		print("WN rogue=", rg["name"], " alias=", rg.get("alias"), " incs=", WorldNews.open_for(vid).map(func(x): return x["kind"]))
		if "deserter" in which:
			var di = WorldNews.open_for(vid).filter(func(x): return x["kind"] == "deserter")
			if not di.is_empty():
				await _begin(WorldNews.mission_for(di[0]))
				print("WN deserter brief=", String(Missions.active()["brief"]).substr(0, 140))
				for k in 3:
					if Missions._cur().get("kind", "") == "kill":
						break
					Missions._next_step()
					await get_tree().create_timer(0.6).timeout
				var bs = Missions.step_nodes.filter(func(x): return is_instance_valid(x) and x is Enemy)
				print("WN deserter enemies=", bs.map(func(x): return [x.arch.get("name"), x.arch.get("world_person", "-"), int(x.arch.get("level", 0))]))
				WorldNews.tick(1.0)
				print("WN deserter state=", WorldNews.find(String(di[0]["id"])).get("state"))
				Missions.abandon()
				await get_tree().create_timer(0.5).timeout
				WorldNews.tick(1.0)
				print("WN deserter after abandon state=", WorldNews.find(String(di[0]["id"])).get("state"))
		if "robbed" in which:
			var ri = WorldNews.add("robbed", vid, String(rg["id"]), {"crime": "test"})
			await _begin(WorldNews.mission_for(ri))
			await get_tree().create_timer(1.0).timeout
			var mer = Missions.npcs.get("tuccar")
			print("WN robbed merchant=", mer != null, " cart=", not MissionWork.I().cart_d.is_empty(), " step=", Missions._cur().get("text"))
			if mer:
				await _npc_shots("tuccar", "wn_robbed_merchant", 1)
			for k in 4:
				if Missions._cur().get("kind", "") == "kill":
					break
				Missions._next_step()
				await get_tree().create_timer(0.6).timeout
			var bs2 = Missions.step_nodes.filter(func(x): return is_instance_valid(x) and x is Enemy)
			print("WN robbed enemies=", bs2.map(func(x): return [x.arch.get("name"), x.arch.get("world_person", "-"), int(x.arch.get("level", 0)), int(x.max_hp)]))
			if not bs2.is_empty():
				var b0 = bs2[0]
				pl.global_position = b0.global_position + Vector3(0, 0.3, 5)
				await get_tree().create_timer(1.0).timeout
				_camw(b0.global_position + Vector3(1.5, 1.5, 3.0), b0.global_position + Vector3.UP * 1.0)
				await _shot("wn_robbed_boss")
				b0.die({"attacker": pl})
				await get_tree().create_timer(1.5).timeout
				print("WN robbed after kill step=", Missions._cur().get("text"), " rogue alive=", WorldPeople.alive(rg))
			Missions.abandon()
			await get_tree().create_timer(0.5).timeout

	if "band" in which:
		var p2 = folk[fi]; fi += 1
		WorldKin._marry(p2)
		var sp = WorldKin.spouse_of(p2)
		print("WN band dead=", p2["name"], " spouse=", sp.get("name", "-"))
		p2["status"] = "öldü"
		var bi = WorldNews.add("band", vid, String(p2["id"]), {"kin": String(sp.get("id", "")), "rel": "eşi"})
		var qb = WorldNews.mission_for(bi)
		if qb.is_empty():
			print("WN band mission EMPTY")
		else:
			sp["grief"] = true
			await _begin(qb)
			await get_tree().create_timer(1.0).timeout
			for e in get_tree().get_nodes_in_group("enemies"):
				if is_instance_valid(e) and e is Enemy:
					e.queue_free()
			var its = _works("item")
			print("WN band items=", its.size(), " step=", Missions._cur().get("text"))
			if not its.is_empty():
				var nb: Node3D = its[0]["node"]
				pl.global_position = nb.global_position + Vector3(0.3, 0.3, 2.5)
				await get_tree().create_timer(0.6).timeout
				_camw(nb.global_position + Vector3(0.5, 0.8, 1.2), nb.global_position + Vector3.UP * 0.1)
				await _shot("wn_band_item")
				await _do(its[0], "wn_band_take", [0.8])
				await _wait_work()
				await get_tree().create_timer(0.5).timeout
				print("WN band step=", Missions._cur().get("text"))
				await _talk_scene("wn_band_give", 3, 0.9)
				await _finish_wait("band")
				print("WN band grief=", sp.get("grief"), " log=", (sp["log"] as Array).slice(-1))

	if "fire" in which:
		var fi2 = WorldNews.add("fire", vid, String(folk[fi]["id"]), {"crime": "test"})
		await _begin(WorldNews.mission_for(fi2))
		await get_tree().create_timer(1.2).timeout
		var fd = MissionWork.I().fire_d
		print("WN fire site=", not fd.is_empty(), " flames=", _works("flame").size(), " owner=", Missions.npcs.has("evsahibi"), " n=", Missions._cur().get("n"))
		if not fd.is_empty():
			var r: Node3D = fd["root"]
			pl.global_position = r.global_position + Vector3(2, 0.3, 9)
			await get_tree().create_timer(1.0).timeout
			_camw(r.global_position + Vector3(5.5, 3.2, 9.0), r.global_position + Vector3(0.5, 1.6, 0))
			await _shot("wn_fire_a")
			_camw(r.global_position + Vector3(-6.0, 2.4, 6.5), r.global_position + Vector3(0, 1.8, 0))
			await _shot("wn_fire_b")
			var fl = _works("flame")
			for k in fl.size():
				Missions.on_interact(fl[k])
				var t := 0.0
				var shot_i := 0
				while MissionWork.active() and t < 14.0:
					t += 0.1
					await get_tree().create_timer(0.1).timeout
					if k == 0 and shot_i < 4 and t > [0.9, 1.9, 2.6, 3.1][shot_i]:
						_camw(pl.global_position + Vector3(3.0, 1.6, 3.5), pl.global_position + Vector3(-0.5, 1.4, -0.5))
						await _shot("wn_fire_douse_%d" % shot_i)
						shot_i += 1
				print("WN fire flame ", k, " t=", snappedf(t, 0.1), " n=", Missions.st.get("n"))
				await get_tree().create_timer(0.3).timeout
			await get_tree().create_timer(0.8).timeout
			_camw(r.global_position + Vector3(5.5, 3.2, 9.0), r.global_position + Vector3(0.5, 1.6, 0))
			await _shot("wn_fire_out")
			print("WN fire step=", Missions._cur().get("text"), " kid=", Missions.npcs.has("icerdeki"))
			var kid = Missions.npcs.get("icerdeki")
			if kid:
				pl.global_position = kid.global_position + Vector3(0.5, 0.2, 1.6)
				await get_tree().create_timer(0.4).timeout
				Missions._after_talk(kid, Missions._cur())
				await _wait_work()
				await get_tree().create_timer(0.5).timeout
				var ow = Missions.npcs.get("evsahibi")
				print("WN fire owner=", ow != null, " step=", Missions._cur().get("text"))
				if ow:
					pl.global_position = ow.global_position + Vector3(1.6, 0.2, 1.0)
					kid.global_position = ow.global_position + Vector3(-1.5, 0.2, 2.5)
					await get_tree().create_timer(0.5).timeout
					Missions._after_talk(ow, Missions._cur())
					await get_tree().create_timer(2.2).timeout
					_camw(ow.global_position + Vector3(2.5, 1.4, 3.0), ow.global_position + Vector3.UP * 0.8)
					await _shot("wn_fire_reunion")
					await _finish_wait("fire")

	if "expire" in which:
		for k in 6:
			var p5 = folk[fi]; fi += 1
			var i5 = WorldNews.add("missing", vid, String(p5["id"]))
			if i5.is_empty():
				print("WN expire add failed open=", WorldNews.open_for(vid).size())
				continue
			p5["missing"] = true
			i5["left"] = 0.5
			WorldNews.tick(1.0)
			print("WN expire ", p5["name"], " status=", p5["status"], " missing=", p5.get("missing"), " log=", (p5["log"] as Array).slice(-1), " | ", WorldNews.recent().slice(-1))

	if "board" in which:
		for k in 2:
			var p6 = folk[fi]; fi += 1
			p6["missing"] = true
			WorldNews.add("missing", vid, String(p6["id"]))
		WorldNews.add("fire", vid, String(folk[fi]["id"]), {})
		Game.profile["rank"] = 2
		var bl = Missions.board_missions(vid, true)
		print("WN board ", bl.map(func(x): return "%s[%s]%s" % [x["title"], x["rank"], "*" if x.get("dyn", false) else ""]))
		Hud.show_mission_board(vid)
		await get_tree().create_timer(1.0).timeout
		await _shot("wn_board")
	get_tree().quit()
