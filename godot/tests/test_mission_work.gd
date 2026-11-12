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


func _ready() -> void:
	await get_tree().process_frame
	var vid = OS.get_environment("MV") if OS.get_environment("MV") != "" else "konoha"
	var which = (OS.get_environment("MW") if OS.get_environment("MW") != "" else "weeds,fence,herb,cat,baby").split(",")
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": vid, "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	pl = main.player
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	main.world.env.time_of_day = 0.45
	Game.profile["kd_wait"] = 99999.0
	Game.profile["age"] = "adult"
	pl.model.apply_age("adult")
	seed(5)

	if "weeds" in which:
		var m = await _start(Missions._q_weeds(vid))
		var s0 = Missions._cur()
		var farmer = Missions.npcs.get("ciftci")
		print("MW weeds farmer=", farmer != null, " kind=", s0["kind"], " site=", m.has("site"))
		if farmer:
			pl.global_position = farmer.global_position + Vector3(4, 0.2, 2)
			await get_tree().create_timer(1.6).timeout
			_camw(farmer.global_position + Vector3(2.6, 1.3, 2.2), farmer.global_position + Vector3.UP * 0.9)
			await _shot("weeds_farmer_0")
			await get_tree().create_timer(0.9).timeout
			await _shot("weeds_farmer_1")
			await _talk_cur()
			await get_tree().create_timer(0.6).timeout
		var ws = _works("weed")
		print("MW weeds objs=", ws.size(), " step=", Missions._cur()["kind"])
		if not ws.is_empty():
			var w0: Node3D = ws[0]["node"]
			_camw(w0.global_position + Vector3(0.9, 0.6, 0.9), w0.global_position + Vector3.UP * 0.2)
			await _shot("weeds_obj")
			var fr: Node3D = MissionWork.I().field_d["root"]
			_camw(fr.global_position + Vector3(-9.5, 5.0, 9.0), fr.global_position + Vector3.UP * 0.3)
			await _shot("weeds_field")
			await _do(ws[0], "weeds_a", [0.9, 1.4, 1.9, 2.5, 3.0])
			for k in range(1, 4):
				ws = _works("weed")
				pl.global_position = ws[0]["node"].global_position + Vector3(1.5, 0.2, 0)
				await get_tree().create_timer(0.2).timeout
				Missions.on_interact(ws[0])
				await _wait_work()
			var pk = MissionWork.I().piles.get("weeds")
			if pk:
				_camw(pk.global_position + Vector3(1.1, 0.9, 1.1), pk.global_position + Vector3.UP * 0.3)
				await _shot("weeds_pile")
			print("MW weeds n=", Missions.st.get("n"), " pile children=", pk.get_child_count() if pk else -1)

	if "fence" in which:
		var m2 = await _start(Missions._q_fence(vid))
		print("MW fence step0=", Missions._cur()["kind"], " hana=", Missions.npcs.has("teyze"))
		var ps = _works("paint")
		print("MW fence panels=", ps.size())
		if not ps.is_empty():
			var gd: Node3D = MissionWork.I().get_meta("garden")
			var hana = Missions.npcs.get("teyze")
			if hana:
				print("MW fence hana dist=", snappedf(hana.global_position.distance_to(gd.global_position), 0.1))
			_camw(gd.global_position + Vector3(4.5, 3.6, 7.5), gd.global_position + Vector3.UP * 0.4)
			await _shot("fence_garden")
			await _do(ps[0], "fence_a", [0.9, 1.6, 2.4, 3.2, 4.2])
			await _do(ps[1], "fence_b", [2.0])
			for k in range(2, ps.size()):
				pl.global_position = ps[k]["node"].global_position + ps[k]["nrm"] * 1.5 + Vector3.UP * 0.2
				await get_tree().create_timer(0.2).timeout
				Missions.on_interact(ps[k])
				await _wait_work()
			_camw(gd.global_position + Vector3(-4.5, 3.2, 7.5), gd.global_position + Vector3.UP * 0.4)
			await _shot("fence_done")
			print("MW fence after step=", Missions._cur().get("kind"), " ", Missions._cur().get("text"))
			if hana:
				_camw(hana.global_position + Vector3(2.4, 1.3, 2.4), hana.global_position + Vector3.UP * 0.9)
				await _shot("fence_hana")

	if "herb" in which:
		var m3 = await _start(Missions._q_herbs(vid, false))
		Missions._next_step()   # goto adımı
		await get_tree().create_timer(0.5).timeout
		var hs = _works("herb")
		print("MW herb objs=", hs.size(), " step=", Missions._cur()["kind"])
		if not hs.is_empty():
			var h0: Node3D = hs[0]["node"]
			_camw(h0.global_position + Vector3(0.8, 0.55, 0.8), h0.global_position + Vector3.UP * 0.22)
			await _shot("herb_obj")
			await _do(hs[0], "herb_a", [0.8, 1.25, 1.5, 1.9, 2.4])
			for k in range(1, 6):
				hs = _works("herb")
				pl.global_position = hs[0]["node"].global_position + Vector3(1.5, 0.2, 0)
				await get_tree().create_timer(0.2).timeout
				Missions.on_interact(hs[0])
				await _wait_work()
			print("MW herb step=", Missions._cur().get("kind"), " inv=", Game.profile["inventory"].get("herb"))
			var nurse = Missions.npcs.get("hemsire")
			if nurse:
				pl.global_position = nurse.global_position + Vector3(1.8, 0.2, 0.3)
				await get_tree().create_timer(0.4).timeout
				nurse.talk()
				await get_tree().create_timer(0.2).timeout
				Missions._after_talk(nurse, Missions._cur())
				for i in 5:
					await get_tree().create_timer(0.7).timeout
					if not is_instance_valid(nurse):
						break
					var c = (pl.global_position + nurse.global_position) * 0.5
					var d = (nurse.global_position - pl.global_position).normalized().cross(Vector3.UP)
					_camw(c + d * 2.6 + Vector3.UP * 1.25, c + Vector3.UP * 0.95)
					await _shot("herb_give_%d" % i)
				await _wait_work()
				print("MW herb done active=", Missions.active().is_empty())

	if "cat" in which:
		var m4 = await _start(Missions._q_cat(vid))
		print("MW cat step=", Missions._cur()["kind"], " lady=", Missions.npcs.has("leydi"))
		var cat = Missions.st.get("cat")
		if cat:
			cat.set_physics_process(false)
			pl.global_position = cat.global_position + Vector3(1.0, 0.2, 0.2)
			await get_tree().create_timer(0.4).timeout
			cat.catch()
			for i in 5:
				await get_tree().create_timer(0.42).timeout
				_side(pl.global_position + pl.face_dir() * 0.5, 2.3, 0.9, 1.0 if i % 2 == 0 else -1.0)
				await _shot("cat_catch_%d" % i)
			await _wait_work()
			await get_tree().create_timer(0.5).timeout
			_camw(pl.global_position + pl.face_dir() * 2.0 + Vector3.UP * 1.4, pl.global_position + Vector3.UP * 1.2)
			await _shot("cat_shoulder")
			print("MW cat step=", Missions._cur().get("kind"), " rider=", is_instance_valid(MissionWork.I().rider))
			var lady = Missions.npcs.get("leydi")
			if lady:
				pl.global_position = lady.global_position + Vector3(1.8, 0.2, 0.3)
				await get_tree().create_timer(0.4).timeout
				lady.talk()
				await get_tree().create_timer(0.2).timeout
				Missions._after_talk(lady, Missions._cur())
				for i in 5:
					await get_tree().create_timer(0.75).timeout
					if not is_instance_valid(lady):
						break
					var c2 = (pl.global_position + lady.global_position) * 0.5
					var d2 = (lady.global_position - pl.global_position).normalized().cross(Vector3.UP)
					_camw(c2 + d2 * 2.4 + Vector3.UP * 1.3, c2 + Vector3.UP * 1.0)
					await _shot("cat_give_%d" % i)
				await _wait_work()
				print("MW cat done active=", Missions.active().is_empty())

	if "baby" in which:
		var m5 = await _start(Missions._q_babysit(vid))
		var mom = Missions.npcs.get("anne")
		print("MW baby step=", Missions._cur()["kind"], " mom=", mom != null)
		if mom:
			pl.global_position = mom.global_position + Vector3(1.8, 0.2, 0.3)
			await get_tree().create_timer(0.4).timeout
			mom.talk()
			await get_tree().create_timer(0.2).timeout
			Missions._after_talk(mom, Missions._cur())
			await get_tree().create_timer(1.5).timeout
		var kid = Missions.npcs.get("cocuk")
		print("MW baby kid=", kid != null, " step=", Missions._cur()["kind"], " mom walking vis=", mom.visible if mom else null)
		var shots := 0
		var t := 0.0
		var last := ""
		while t < 75.0 and Missions._cur().get("kind", "") == "babysit" and is_instance_valid(kid):
			var kp = MissionWork.I().kid_play
			var stt = String(kp.get("state", ""))
			if stt != last:
				print("MW baby t=", snappedf(t, 0.1), " state=", stt, " n=", kp.get("n"))
				last = stt
			var its = Interact.items.filter(func(it): return it.get("work", "") in ["ball", "comfort"])
			if not its.is_empty() and not MissionWork.active() and float(kp.get("t", 0.0)) > (1.4 if stt == "wait" else 2.5):
				var it = its[0]
				if stt == "cry":
					_camw(kid.global_position + Vector3(1.6, 0.9, 1.6), kid.global_position + Vector3.UP * 0.45)
					await _shot("baby_cry")
				pl.global_position = (it["node"] as Node3D).global_position + Vector3(1.2, 0.2, 0.5)
				pl.global_position.y = Game.ground_height(pl.global_position.x, pl.global_position.z) + 0.1
				await get_tree().create_timer(0.3).timeout
				Missions.on_interact(it)
				for i in (3 if stt == "cry" else 2):
					await get_tree().create_timer(0.55 if stt == "cry" else 0.3).timeout
					var c3 = (pl.global_position + kid.global_position) * 0.5
					var d3 = (kid.global_position - pl.global_position)
					d3.y = 0
					_camw(c3 + d3.normalized().cross(Vector3.UP) * (2.6 + d3.length() * 0.4) + Vector3.UP * 1.2, c3 + Vector3.UP * 0.6)
					if shots < 3:
						await _shot("baby_%s_%d_%d" % [stt, shots, i])
				shots += 1
				await _wait_work()
			elif stt == "chase" and shots < 12 and fmod(t, 3.0) < 0.11:
				_camw(kid.global_position + Vector3(2.4, 1.2, 2.4), kid.global_position + Vector3.UP * 0.5)
			t += 0.1
			await get_tree().create_timer(0.1).timeout
		print("MW baby end t=", snappedf(t, 0.1), " step=", Missions._cur().get("kind"), " mom vis=", mom.visible if is_instance_valid(mom) else null)
		await get_tree().create_timer(1.2).timeout
		if is_instance_valid(mom):
			_camw(mom.global_position + Vector3(2.4, 1.4, 2.4), mom.global_position + Vector3.UP * 0.9)
			await _shot("baby_mom_walk")
		await get_tree().create_timer(3.0).timeout
		if is_instance_valid(mom):
			_camw(mom.global_position + Vector3(2.4, 1.4, 2.4), mom.global_position + Vector3.UP * 0.9)
			await _shot("baby_mom_back")
			print("MW baby mom dist=", snappedf(mom.global_position.distance_to(pl.global_position), 0.1))
	if "inv" in which:
		var m6 = await _start(Missions._q_investigate(vid), "C")
		print("MW inv steps=", m6["steps"].size(), " cur=", Missions._cur().get("text"), " sites=", MissionWork.I().sites.keys())
		await _npc_shots("magdur", "inv_victim")
		await _npc_shots("tanik1", "inv_baker")
		await _talk_scene("inv_t1")
		await _npc_shots("tanik2", "inv_guard", 1)
		await _talk_scene("inv_t2")
		print("MW inv step=", Missions._cur().get("kind"), " ", Missions._cur().get("text"))
		var cl = _works("clue")
		print("MW inv clues=", cl.size())
		for k in cl.size():
			var cn: Node3D = cl[k]["node"]
			_camw(cn.global_position + Vector3(1.5, 1.1, 1.5), cn.global_position + Vector3.UP * 0.2)
			await _shot("inv_clue%d_obj" % k)
			await _do(cl[k], "inv_clue%d" % k, [0.9, 2.2] if k == 0 else [1.2], 2.4, 1.0)
		print("MW inv after clues step=", Missions._cur().get("kind"), " ", Missions._cur().get("text"))
		Missions._next_step()   # şüpheli seçimi
		await get_tree().create_timer(0.4).timeout
		Missions._next_step()   # kamp baskını
		await get_tree().create_timer(0.8).timeout
		var sk = _works("sack")
		print("MW inv sack=", sk.size(), " step=", Missions._cur().get("text"))
		if not sk.is_empty():
			var sn: Node3D = sk[0]["node"]
			_camw(sn.global_position + Vector3(1.3, 0.9, 1.3), sn.global_position + Vector3.UP * 0.25)
			await _shot("inv_sack_obj")
			await _do(sk[0], "inv_sack", [0.7, 1.2, 1.6], 2.4, 1.0)
			await get_tree().create_timer(0.4).timeout
			_camw(pl.global_position - pl.face_dir() * 2.2 + pl.face_dir().cross(Vector3.UP) * 1.2 + Vector3.UP * 1.4, pl.global_position + Vector3.UP * 1.0)
			await _shot("inv_sack_back")
			print("MW inv rider=", is_instance_valid(MissionWork.I().rider), " step=", Missions._cur().get("text"))
			await _talk_scene("inv_return", 9, 0.75)
			print("MW inv done=", Missions.active().is_empty())

	if "escort" in which:
		var m7 = await _start(Missions._q_escort(vid, "C"), "C")
		var mer = Missions.npcs.get("eskort")
		await get_tree().create_timer(1.0).timeout
		mer = Missions.npcs.get("eskort")
		print("MW escort mer=", mer != null, " cart=", not MissionWork.I().cart_d.is_empty())
		if mer and OS.get_environment("MDBG") != "":
			for i in 6:
				mer = Missions.npcs.get("eskort")
				if mer and is_instance_valid(mer):
					var s0 = Missions._cur()
					var gp = mer.global_position
					print("MW dbg id=", mer.get_instance_id(), " pos=", gp, " gh=", Game.ground_height(gp.x, gp.z), " og=", snappedf(Missions.open_ground(gp, 0.0).distance_to(gp), 0.1), " dat=", snappedf(Game.to_map(gp).distance_to(Vector2(s0["at"][0], s0["at"][1])), 0.1), " pl=", snappedf(pl.global_position.distance_to(gp), 1.0))
				await get_tree().create_timer(0.3).timeout
			get_tree().quit()
			return
		if mer:
			await _talk_cur()
			await get_tree().create_timer(0.5).timeout
			print("MW escort step=", Missions._cur().get("kind"), " path=", mer.path.size())
			for i in 4:
				pl.global_position = mer.global_position + mer.face_dir() * 3.0 + Vector3(0, 0.2, 0)
				await get_tree().create_timer(2.5).timeout
				var cd = MissionWork.I().cart_d
				if cd.is_empty():
					break
				var ox: Node3D = cd["ox"]
				var f = mer.face_dir()
				var r = f.cross(Vector3.UP).normalized()
				_camw(ox.global_position + r * (7.0 if i % 2 == 0 else -6.0) + f * (3.0 if i < 2 else -7.0) + Vector3.UP * 2.6, ox.global_position + Vector3.UP * 1.0)
				await _shot("escort_cart_%d" % i)
				print("MW escort i=", i, " mer-ox=", snappedf(mer.global_position.distance_to(ox.global_position), 0.1), " ox-cart=", snappedf(ox.global_position.distance_to(cd["cart"].global_position), 0.1), " path_i=", mer.path_i)
			# pusu: sinme
			Missions._spawn("bandit", mer.global_position + mer.face_dir() * 9.0, 1, 2.0)
			await get_tree().create_timer(1.6).timeout
			_camw(mer.global_position + mer.face_dir() * 2.2 + Vector3(0.8, 1.3, 0), mer.global_position + Vector3.UP * 0.8)
			await _shot("escort_cower")
			for e in Missions.step_nodes:
				if is_instance_valid(e) and e is Enemy:
					e.queue_free()
			await get_tree().create_timer(1.2).timeout
			_camw(mer.global_position + mer.face_dir() * 2.2 + Vector3(0.8, 1.3, 0), mer.global_position + Vector3.UP * 0.8)
			await _shot("escort_after")
			mer.path_i = mer.path.size()
			await get_tree().create_timer(0.6).timeout
			print("MW escort step=", Missions._cur().get("kind"), " ", Missions._cur().get("text"))
			await _talk_scene("escort_pay", 6, 0.5)
			print("MW escort done=", Missions.active().is_empty())

	if "track" in which:
		var m8 = await _start(Missions._q_track(vid, "C"), "C")
		await _talk_cur()
		await get_tree().create_timer(0.6).timeout
		var dd = MissionWork.I().dog_d
		print("MW track step=", Missions._cur().get("kind"), " dog=", not dd.is_empty(), " prints=", (Missions.st.get("prints", []) as Array).size())
		if not dd.is_empty():
			var dog: Node3D = dd["dog"]
			var prints: Array = Missions.st["prints"]
			for i in 5:
				pl.global_position = prints[mini(i * 3, prints.size() - 1)] + Vector3.UP * 0.2
				await get_tree().create_timer(1.3 if i < 4 else 4.0).timeout
				var dp = dog.global_position
				var tp = pl.global_position - dp
				tp.y = 0
				var sd = tp.normalized().cross(Vector3.UP)
				_camw(dp + sd * 2.6 + tp.normalized() * 1.0 + Vector3.UP * 1.1, dp + Vector3.UP * 0.4)
				await _shot("track_dog_%d" % i)
				print("MW track i=", i, " idx=", Missions.st.get("idx"), " dog_i=", dd.get("i"), " d=", snappedf(tp.length(), 0.1))
			_camw(pl.global_position + Vector3(1.5, 2.2, 1.5), pl.global_position + Vector3(0, 0, 0))
			await _shot("track_prints")

	if "border" in which:
		var m9 = await _start(Missions._q_border(vid), "C")
		var gd2 = Missions.npcs.get("nobetci")
		var s9 = Missions._cur()
		print("MW border guard=", gd2 != null, " at=", s9.get("at"), " sites=", MissionWork.I().sites.keys())
		var w9 = Missions._w(s9["at"])
		pl.global_position = w9 + Vector3(3, 1.0, 12)
		await get_tree().create_timer(3.0).timeout
		gd2 = Missions.npcs.get("nobetci")
		var sd9 = {}
		for k in MissionWork.I().sites:
			sd9 = MissionWork.I().sites[k]
		print("MW border guard2=", gd2 != null, " site=", not sd9.is_empty())
		if not sd9.is_empty():
			var rc: Vector3 = sd9["root"].global_position
			_camw(rc + Vector3(9, 6.5, 15), rc + Vector3.UP * 1.5)
			await _shot("border_wide")
			_camw(rc + Vector3(-8, 3.0, 9), rc + Vector3.UP * 1.5)
			await _shot("border_wide2")
			if gd2:
				_camw(gd2.global_position + gd2.face_dir() * 2.6 + Vector3(1.0, 1.4, 0), gd2.global_position + Vector3.UP * 1.0)
				await _shot("border_guard")
				await _talk_scene("border_talk")
				await get_tree().create_timer(2.0).timeout
				_camw(rc + Vector3(5, 3.5, 10), rc + Vector3.UP * 1.5)
				await _shot("border_open")
				print("MW border open=", sd9.get("open"), " step=", Missions._cur().get("text"))
				var s10 = Missions._cur()
				var w10 = Missions._w(s10["at"])
				pl.global_position = w10 + Vector3(2, 1.0, 2)
				await get_tree().create_timer(3.5).timeout
				await _talk_scene("border_letter", 6, 0.6)
				print("MW border done=", Missions.active().is_empty())
	if "stealth" in which:
		await _start(Missions._q_stealth(vid), "B")
		Missions._next_step()
		await get_tree().create_timer(0.8).timeout
		main.world.env.time_of_day = 0.45
		for e in Missions.st.get("guards", []):
			if is_instance_valid(e):
				e.queue_free()
		var bk = _works("book")
		print("MW stealth step=", Missions._cur().get("kind"), " book=", bk.size())
		if not bk.is_empty():
			var bn: Node3D = bk[0]["node"]
			pl.global_position = bn.global_position + Vector3(3, 0.3, 3)
			await get_tree().create_timer(1.0).timeout
			_camw(bn.global_position + Vector3(1.4, 1.3, 1.4), bn.global_position + Vector3.UP * 0.5)
			await _shot("stealth_obj")
			_camw(bn.global_position + Vector3(5, 3.5, 6), bn.global_position + Vector3.UP * 0.5)
			await _shot("stealth_wide")
			await _do(bk[0], "stealth_take", [0.7, 1.1, 1.5], 2.4, 1.0)
			print("MW stealth after=", Missions._cur().get("text"))
			await get_tree().create_timer(0.5).timeout
			await _talk_scene("stealth_give", 4, 0.7)
			print("MW stealth done=", Missions.active().is_empty())

	if "chase" in which:
		await _start(Missions._q_chase(vid), "B")
		if Missions._cur().get("kind") == "goto":
			pl.global_position = Missions.open_ground(Missions._w(Missions._cur()["at"]), 30.0) + Vector3(14, 0.5, 0)
			await get_tree().create_timer(0.3).timeout
			if Missions._cur().get("kind") == "goto":
				Missions._next_step()
		await get_tree().create_timer(0.8).timeout
		var th = Missions.st.get("thief")
		print("MW chase thief=", th != null, " cur=", Missions._cur().get("kind"), " st=", Missions.st.keys())
		if th:
			th.set_physics_process(false)
			pl.global_position = th.global_position + Vector3(2, 0.2, 0)
			await get_tree().create_timer(0.3).timeout
			Missions.on_kill(th)
			th.queue_free()
			await get_tree().create_timer(0.5).timeout
			var sc2 = _works("scroll")
			print("MW chase scroll=", sc2.size(), " step=", Missions._cur().get("kind"))
			if not sc2.is_empty():
				var sn2: Node3D = sc2[0]["node"]
				_camw(sn2.global_position + Vector3(0.9, 0.7, 0.9), sn2.global_position + Vector3.UP * 0.1)
				await _shot("chase_obj")
				await _do(sc2[0], "chase_take", [0.7, 1.1, 1.5], 2.4, 1.0)
				print("MW chase after=", Missions._cur().get("text"))
				await get_tree().create_timer(0.5).timeout
				await _talk_scene("chase_give", 4, 0.7)
				print("MW chase done=", Missions.active().is_empty())

	if "rescue" in which:
		await _start(Missions._q_rescue(vid), "B")
		await get_tree().create_timer(1.0).timeout
		main.world.env.time_of_day = 0.45
		var hs2 = Missions.npcs.get("rehine")
		print("MW rescue hostage=", hs2 != null, " step=", Missions._cur().get("kind"))
		if hs2:
			for e in Missions.step_nodes:
				if is_instance_valid(e) and e is Enemy:
					e.queue_free()
			pl.global_position = hs2.global_position + hs2.face_dir() * 3.0 + Vector3(1.5, 0.3, 0)
			await get_tree().create_timer(1.2).timeout
			var hf = hs2.face_dir()
			var hr = hf.cross(Vector3.UP).normalized()
			_camw(hs2.global_position + hf * 2.2 + hr * 1.2 + Vector3.UP * 1.1, hs2.global_position + Vector3.UP * 0.55)
			await _shot("rescue_bound_0")
			_camw(hs2.global_position - hf * 1.6 + hr * 2.0 + Vector3.UP * 1.2, hs2.global_position + Vector3.UP * 0.55)
			await _shot("rescue_bound_1")
			_camw(hs2.global_position + hr * -2.4 + Vector3.UP * 0.9, hs2.global_position + Vector3.UP * 0.55)
			await _shot("rescue_bound_2")
			Missions._next_step()
			await get_tree().create_timer(0.5).timeout
			hs2 = Missions.npcs.get("rehine")
			print("MW rescue talk step=", Missions._cur().get("text"), " bound=", MissionWork.I().bound_d.has(hs2))
			pl.global_position = hs2.global_position + hr * 2.0 + Vector3.UP * 0.2
			await get_tree().create_timer(0.3).timeout
			Missions._after_talk(hs2, Missions._cur())
			for i in 5:
				await get_tree().create_timer(0.5).timeout
				_camw(hs2.global_position + hf * 2.3 + hr * (1.0 if i % 2 == 0 else 2.0) + Vector3.UP * 1.1, hs2.global_position + hr * 0.4 + Vector3.UP * 0.55)
				await _shot("rescue_untie_%d" % i)
			await _wait_work()
			await get_tree().create_timer(0.6).timeout
			print("MW rescue mode=", hs2.mode, " step=", Missions._cur().get("text"))
			var dad = Missions.npcs.get("baba")
			print("MW rescue dad=", dad != null)
			if dad:
				pl.global_position = dad.global_position + dad.face_dir() * 1.7 + Vector3.UP * 0.2
				hs2.global_position = dad.global_position + dad.face_dir() * 3.5 + Vector3(1.5, 0.2, 0)
				await get_tree().create_timer(0.5).timeout
				dad.talk()
				await get_tree().create_timer(0.2).timeout
				Missions._after_talk(dad, Missions._cur())
				for i in 9:
					await get_tree().create_timer(0.6).timeout
					if not is_instance_valid(dad) or not is_instance_valid(hs2):
						break
					var c5 = (hs2.global_position + dad.global_position) * 0.5
					var d5 = (hs2.global_position - dad.global_position)
					d5.y = 0
					_camw(c5 + d5.normalized().cross(Vector3.UP) * 2.8 + Vector3.UP * 1.3, c5 + Vector3.UP * 1.0)
					await _shot("rescue_reunion_%d" % i)
				await _wait_work()
				print("MW rescue done=", Missions.active().is_empty())

	if "sabo" in which:
		await _start(Missions._q_sabotage(vid), "B")
		await get_tree().create_timer(1.0).timeout
		for e in Missions.st.get("guards", []):
			if is_instance_valid(e):
				e.queue_free()
		var cr = _works("crate")
		print("MW sabo crates=", cr.size(), " step=", Missions._cur().get("kind"))
		if not cr.is_empty():
			var cn2: Node3D = cr[0]["node"]
			var fz = cn2.global_transform.basis.z
			pl.global_position = cn2.global_position + fz * 3.0 + Vector3.UP * 0.3
			await get_tree().create_timer(1.0).timeout
			_camw(cn2.global_position + fz * 3.4 + Vector3(0.8, 1.5, 0), cn2.global_position + Vector3.UP * 0.7)
			await _shot("sabo_obj")
			var camp_c = Missions._w(Missions._cur()["at"])
			_camw(camp_c + Vector3(14, 10, 16), camp_c + Vector3.UP * 0.5)
			await _shot("sabo_wide")
			var nodes = cr.map(func(x): return x["node"])
			Missions.on_interact(cr[0])
			var t2 := 0.0
			var k2 := 0
			while MissionWork.active() and t2 < 10.0:
				if k2 < 4 and t2 >= [0.7, 1.0, 1.25, 1.7][k2]:
					var rr = fz.cross(Vector3.UP).normalized()
					_camw(cn2.global_position + fz * 1.6 + rr * (2.2 if k2 % 2 == 0 else -2.2) + Vector3.UP * 1.3, cn2.global_position + fz * 0.7 + Vector3.UP * 0.9)
					await _shot("sabo_tag_%d" % k2)
					k2 += 1
				t2 += 0.05
				await get_tree().create_timer(0.05).timeout
			_camw(cn2.global_position + fz * 1.8 + Vector3(0.3, 0.9, 0), cn2.global_position + Vector3.UP * 0.65)
			await _shot("sabo_tagged")
			for k in range(1, 4):
				var rest = _works("crate")
				if rest.is_empty():
					break
				pl.global_position = rest[0]["node"].global_position + rest[0]["node"].global_transform.basis.z * 2.0 + Vector3.UP * 0.2
				await get_tree().create_timer(0.2).timeout
				Missions.on_interact(rest[0])
				await _wait_work()
			print("MW sabo step=", Missions._cur().get("text"), " tagged=", MissionWork.I().tagged.size())
			var safe = Missions._w(Missions._cur()["at"])
			_camw(cn2.global_position + fz * 6.0 + Vector3(2.5, 3.0, 0), cn2.global_position + Vector3.UP * 0.8)
			pl.global_position = safe + Vector3.UP * 0.5
			for i in 4:
				await get_tree().create_timer(0.3).timeout
				await _shot("sabo_boom_%d" % i)
			await get_tree().create_timer(2.0).timeout
			await _shot("sabo_debris")
			print("MW sabo after boom step=", Missions._cur().get("text"))

	if "defend" in which:
		await _start(Missions._q_defend(vid, "B"), "B")
		await get_tree().create_timer(0.5).timeout
		var s11 = Missions._cur()
		pl.global_position = Missions._w(s11["at"]) + Vector3(3, 1.0, 3)
		await get_tree().create_timer(2.5).timeout
		await _talk_cur()
		await get_tree().create_timer(1.0).timeout
		print("MW defend step=", Missions._cur().get("kind"), " hid=", (Missions.st.get("hid", []) as Array).size())
		var bsite = {}
		for k in MissionWork.I().sites:
			if String(k).ends_with("barricade"):
				bsite = MissionWork.I().sites[k]
		if not bsite.is_empty():
			var bc: Vector3 = bsite["root"].global_position
			_camw(bc + Vector3(10, 7, 12), bc + Vector3.UP * 0.5)
			await _shot("defend_wide")
			_camw(bc + Vector3(2.5, 1.6, 3.0), bc + Vector3(0, 0.5, -0.6))
			await _shot("defend_hide")
			_camw(bc + Vector3(-3.0, 1.4, 1.5), bc + Vector3(0, 0.5, -0.6))
			await _shot("defend_hide2")
			Missions.st["wave"] = 99
			Missions.st["alive"] = []
			await get_tree().create_timer(1.2).timeout
			_camw(bc + Vector3(2.5, 1.6, 3.0), bc + Vector3(0, 0.9, -0.6))
			await _shot("defend_cheer_0")
			await get_tree().create_timer(0.3).timeout
			await _shot("defend_cheer_1")
			print("MW defend after=", Missions._cur().get("text"))
			await _talk_scene("defend_pay", 4, 0.5)
			print("MW defend done=", Missions.active().is_empty())
	if "items" in which:
		var names = ["yabani mantar", "bal peteği", "yassı nehir taşı", "nadir kuş yumurtası", "kuş yuvası", "tahta oyuncak", "eski kunai", "yıldırım kristali", "kahraman suyu",
			"kan şişesi", "mühür parşömeni", "çalıntı harita", "mühür kâğıdı", "mektup", "kil parçası", "kukla parçası", "kâğıt turna", "kayıp kurbağa", "yılan pulu", "demir cevheri",
			"kargo sandığı", "kuru odun", "balık ağı", "kâğıt fener", "pirinç demeti", "tavuk", "çay yaprağı"]
		var base = MissionWork.I().clear_spot(pl.global_position + Vector3(20, 0, 0), 10.0, 10.0, 80.0)
		pl.global_position = base + Vector3(-14, 0.3, 0)
		await get_tree().create_timer(1.0).timeout
		var k3 := 0
		for nm in names:
			var q = base + Vector3((k3 % 6 - 2.5) * 3.0, 0, (k3 / 6 - 2.0) * 3.0)
			var n3 = MissionWork.I().make("item", q, 0.5, k3, MissionWork.item_label(nm), {"item": nm, "act": MissionWork.item_act(nm)})
			print("MW item ", nm, " -> ", MissionWork.item_class(nm), " / ", MissionWork.item_act(nm), " / ", MissionWork.item_label(nm))
			k3 += 1
		await get_tree().create_timer(1.5).timeout
		k3 = 0
		for nm in names:
			var q = base + Vector3((k3 % 6 - 2.5) * 3.0, 0, (k3 / 6 - 2.0) * 3.0)
			q.y = Game.ground_height(q.x, q.z)
			_camw(q + Vector3(0.75, 0.6, 0.95), q + Vector3.UP * 0.16)
			await _shot("item_%02d" % k3)
			k3 += 1

	if "pool" in which:
		for spec in [["kuru odun", 3], ["yabani mantar", 2], ["tavuk", 2]]:
			var sp = {"r": "C", "p": "collect", "t": "Deneme", "b": "Deneme görevi.", "item": spec[0], "n": spec[1], "g": "Yaşlı Teyze Kiku", "s1": "Topla gel.", "s2": "Eline sağlık!"}
			var q7 = Missions._from_spec(vid, sp)
			await _start(q7, "C")
			if Missions._cur().get("kind") == "talk":
				await _talk_cur()
				await get_tree().create_timer(0.6).timeout
			var tag7 = MissionWork.item_class(spec[0])
			var its7 = _works("item")
			print("MW pool ", spec[0], " objs=", its7.size(), " step=", Missions._cur().get("kind"), " rider=", MissionWork.I().rider_kind)
			if its7.is_empty():
				continue
			await _do(its7[0], "pool_%s_a" % tag7, [0.6, 1.0, 1.3, 1.6], 2.4, 1.0)
			for k in range(1, int(spec[1])):
				its7 = _works("item")
				pl.global_position = its7[0]["node"].global_position + Vector3(1.5, 0.2, 0)
				await get_tree().create_timer(0.2).timeout
				Missions.on_interact(its7[0])
				await _wait_work()
			await get_tree().create_timer(0.4).timeout
			if MissionWork.I().rider_kind == "load":
				var f7 = pl.face_dir()
				_camw(pl.global_position - f7 * 2.0 + f7.cross(Vector3.UP) * 1.3 + Vector3.UP * 1.3, pl.global_position + Vector3.UP * 0.95)
				await _shot("pool_%s_back" % tag7)
				_camw(pl.global_position + f7.cross(Vector3.UP) * 2.4 + Vector3.UP * 1.1, pl.global_position + Vector3.UP * 0.95)
				await _shot("pool_%s_side" % tag7)
			print("MW pool after=", Missions._cur().get("text"), " load_n=", MissionWork.I().load_n)
			await _talk_scene("pool_%s_give" % tag7, 3, 0.45)
			print("MW pool done=", Missions.active().is_empty())
	if "spots" in which:
		var labs = ["[F] Mühür taşını uyandır", "[F] Ritim taşını çal", "[F] Yosun taşında meditasyon", "[F] Sandığı aç", "[F] Mühürlü parşömeni aç"]
		var base2 = MissionWork.I().clear_spot(pl.global_position + Vector3(20, 0, 0), 8.0, 4.0, 80.0)
		var made = []
		for k in labs.size():
			var q = base2 + Vector3((k - 2) * 3.2, 0, 0)
			MissionWork.I().make("spot", q, 0.0, k, labs[k], {"style": MissionWork.spot_class(labs[k])})
			print("MW spot ", labs[k], " -> ", MissionWork.spot_class(labs[k]))
		pl.global_position = base2 + Vector3(0, 0.3, 5)
		await get_tree().create_timer(1.0).timeout
		_camw(base2 + Vector3(0, 2.6, 7.5), base2 + Vector3.UP * 0.5)
		await _shot("spots_wide")
		for k in labs.size():
			var its8 = Interact.items.filter(func(x): return x.get("work", "") == "spot" and x.get("label", "") == labs[k])
			if its8.is_empty():
				print("MW spot yok ", labs[k])
				continue
			var it8 = its8[0]
			var n8: Node3D = it8["node"]
			pl.global_position = n8.global_position + Vector3(0.3, 0.2, 1.8)
			await get_tree().create_timer(0.3).timeout
			MissionWork.I().run(it8)
			var t8 := 0.0
			var j8 := 0
			var times8 = [0.8, 1.5, 2.3]
			while MissionWork.active() and t8 < 8.0:
				if j8 < times8.size() and t8 >= times8[j8]:
					_camw(n8.global_position + Vector3(2.0 if j8 % 2 == 0 else -2.0, 1.2, 1.9), n8.global_position + Vector3(0, 0.6, 0.4))
					await _shot("spots_%d_%d" % [k, j8])
					j8 += 1
				t8 += 0.05
				await get_tree().create_timer(0.05).timeout
			_camw(n8.global_position + Vector3(0.9, 1.0, 1.9), n8.global_position + Vector3(0, 0.5, 0))
			await _shot("spots_%d_done" % k)
			print("MW spot done ", k, " t=", snappedf(t8, 0.1))
	if "clues2" in which:
		var cks = ["rice", "vial", "rag", "bag", "puppet", "clay", "receipt", "sandal", "skin", "needle"]
		var base3 = MissionWork.I().clear_spot(pl.global_position + Vector3(20, 0, 0), 9.0, 4.0, 80.0)
		for k in cks.size():
			var q = base3 + Vector3((k % 5 - 2) * 2.6, 0, (k / 5) * 4.0 - 2.0)
			MissionWork.I().make("clue", q, 0.0, k, "[F] İzi incele", {"clue": k, "ck": cks[k], "find": MissionWork.clue_find(cks[k])})
		pl.global_position = base3 + Vector3(0, 0.3, 9)
		await get_tree().create_timer(1.0).timeout
		for k in cks.size():
			var q = base3 + Vector3((k % 5 - 2) * 2.6, 0, (k / 5) * 4.0 - 2.0)
			_camw(q + Vector3(0.5, 1.5, 1.9), q + Vector3(0, 0.1, 0))
			await _shot("clues2_%02d_%s" % [k, cks[k]])
		var itc = Interact.items.filter(func(x): return x.get("ck", "") == "puppet")[0]
		pl.global_position = itc["node"].global_position + Vector3(0.3, 0.2, 1.6)
		await get_tree().create_timer(0.3).timeout
		MissionWork.I().run(itc)
		await get_tree().create_timer(1.0).timeout
		_camw(itc["node"].global_position + Vector3(2.0, 1.2, 1.6), itc["node"].global_position + Vector3(0, 0.5, 0.4))
		await _shot("clues2_examine")
		await _wait_work()

	if "sites2" in which:
		var kinds = ["well_poisoned", "barn_robbed", "stable_burnt", "workbench", "notice"]
		var base4 = pl.global_position + Vector3(30, 0, 0)
		for k in kinds.size():
			var sd2: Dictionary = MissionWork.I().site(kinds[k], base4 + Vector3(k * 14.0, 0, 0))
			var r2: Node3D = sd2["root"]
			var who = Missions._make_npc(Missions._npc("s%d" % k, "Mağdur", "merchant"), sd2["npc_at"])
			MissionWork.I().place_worker(who, sd2["npc_at"], sd2["face"])
			MissionWork.I().busy(who, "fret")
			pl.global_position = r2.global_position + Vector3(0, 0.3, 9)
			await get_tree().create_timer(0.8).timeout
			print("MW site ", kinds[k], " at=", r2.global_position, " npc d=", snappedf(who.global_position.distance_to(r2.global_position), 0.1))
			_camw(r2.global_position + Vector3(3.6, 2.6, 5.6), r2.global_position + Vector3.UP * 1.0)
			await _shot("sites2_%s_a" % kinds[k])
			_camw(r2.global_position + Vector3(-4.2, 1.8, 3.4), r2.global_position + Vector3.UP * 1.0)
			await _shot("sites2_%s_b" % kinds[k])

	if "spots2" in which:
		var labs2 = ["[F] Hücre kabını aç ve nakle gir", "[F] Zirvede bulutları ısıt"]
		var base5 = MissionWork.I().clear_spot(Missions._w(Missions._spot(vid, 150, 300)), 6.0, 4.0, 80.0)
		for k in labs2.size():
			MissionWork.I().make("spot", base5 + Vector3((k - 0.5) * 6.0, 0, 0), 0.0, k, labs2[k], {"style": MissionWork.spot_class(labs2[k])})
			print("MW spot2 ", labs2[k], " -> ", MissionWork.spot_class(labs2[k]))
		for k in labs2.size():
			var it9 = Interact.items.filter(func(x): return x.get("work", "") == "spot" and x.get("label", "") == labs2[k])[0]
			var n9: Node3D = it9["node"]
			pl.global_position = n9.global_position + Vector3(0.3, 0.2, 2.2)
			await get_tree().create_timer(0.5).timeout
			_camw(n9.global_position + Vector3(1.6, 1.4, 2.6), n9.global_position + Vector3(0, 0.9, 0))
			await _shot("spots2_%d_idle" % k)
			MissionWork.I().run(it9)
			var t9 := 0.0
			var j9 := 0
			var times9 = [0.9, 1.6, 2.6, 3.4] if k == 0 else [0.7, 0.95, 1.5, 2.3]
			while MissionWork.active() and t9 < 9.0:
				if j9 < times9.size() and t9 >= times9[j9]:
					if k == 1 and j9 >= 2:
						_camw(n9.global_position + Vector3(12.0, 2.0, 26.0), n9.global_position + Vector3(0, 24.0, 0))
					else:
						_camw(n9.global_position + Vector3(2.2 if j9 % 2 == 0 else -2.2, 1.4, 2.4), n9.global_position + Vector3(0, 1.0, 0.6))
					await _shot("spots2_%d_%d" % [k, j9])
					j9 += 1
				t9 += 0.05
				await get_tree().create_timer(0.05).timeout
			print("MW spot2 done ", k, " t=", snappedf(t9, 0.1))

	if "poolresc" in which:
		var rng2 = RandomNumberGenerator.new()
		rng2.seed = 11
		var sp2 = {}
		for k in 200:
			sp2 = MissionGen._one(vid, "C", rng2)
			if sp2.get("p", "") == "rescue":
				break
		var q2 = Missions._from_spec(vid, sp2)
		print("MW poolresc spec kin=", sp2.get("kin"), " steps=", q2["steps"].map(func(x): return x["kind"]))
		await _start(q2, "C")
		await get_tree().create_timer(1.0).timeout
		print("MW poolresc lair=", Missions.st.get("lair"), " lair_h=", Missions.active().get("lair_h"))
		var h3 = Missions.npcs.get("rehine")
		if h3 == null:
			# in: kapıdan gir, rehine içeride
			var door3 = Interact.items.filter(func(x): return String(x.get("room", "")).begins_with("lair_"))
			print("MW poolresc doors=", door3.size())
			if not door3.is_empty():
				pl.global_position = door3[0]["pos"] + Vector3(0, 0.3, 0)
				await get_tree().create_timer(0.3).timeout
				Interiors.inst.enter(door3[0])
				await get_tree().create_timer(2.5).timeout
				h3 = Missions.npcs.get("rehine")
		print("MW poolresc hostage=", h3 != null, " inside=", Interiors.inst.inside if Interiors.inst else "?")
		for e in Missions.step_nodes:
			if is_instance_valid(e) and e is Enemy:
				e.queue_free()
		await get_tree().create_timer(0.2).timeout
		Missions._next_step()
		await get_tree().create_timer(0.5).timeout
		if h3:
			pl.global_position = h3.global_position + h3.face_dir() * 1.8 + Vector3.UP * 0.2
			await get_tree().create_timer(0.4).timeout
			_camw(h3.global_position + h3.face_dir() * 2.6 + Vector3(1.0, 1.2, 0), h3.global_position + Vector3.UP * 0.6)
			await _shot("poolresc_bound")
			Missions._after_talk(h3, Missions._cur())
			await _wait_work()
			await get_tree().create_timer(0.5).timeout
			print("MW poolresc mode=", h3.mode, " step=", Missions._cur().get("text"))
			if Interiors.inst and Interiors.inst.inside != "":
				Interiors.inst.exit()
				await get_tree().create_timer(2.5).timeout
				print("MW poolresc out: host-player d=", snappedf(h3.global_position.distance_to(pl.global_position), 0.1), " host y-ground=", snappedf(h3.global_position.y - Game.ground_height(h3.global_position.x, h3.global_position.z), 0.1))
			var kin3 = Missions.npcs.get("yakin")
			print("MW poolresc kin=", kin3 != null, " name=", kin3.display if kin3 else "")
			if kin3:
				pl.global_position = kin3.global_position + kin3.face_dir() * 1.7 + Vector3.UP * 0.2
				h3.global_position = kin3.global_position + kin3.face_dir() * 3.5 + Vector3(1.5, 0.2, 0)
				await get_tree().create_timer(0.5).timeout
				kin3.talk()
				await get_tree().create_timer(0.2).timeout
				Missions._after_talk(kin3, Missions._cur())
				for i in 4:
					await get_tree().create_timer(1.2).timeout
					if not is_instance_valid(kin3) or not is_instance_valid(h3):
						break
					var c6 = (h3.global_position + kin3.global_position) * 0.5
					var d6 = (h3.global_position - kin3.global_position)
					d6.y = 0
					_camw(c6 + d6.normalized().cross(Vector3.UP) * 2.8 + Vector3.UP * 1.3, c6 + Vector3.UP * 1.0)
					await _shot("poolresc_reunion_%d" % i)
				await _wait_work()
				await get_tree().create_timer(0.5).timeout
				print("MW poolresc done=", Missions.active().is_empty())

	if "poolinv" in which:
		var rng3 = RandomNumberGenerator.new()
		for sd3 in [3, 4, 5, 6, 7, 8, 9, 10, 12, 14, 15, 16]:
			rng3.seed = sd3
			var sp3 = {}
			for k in 300:
				sp3 = MissionGen._one(vid, "C", rng3)
				if sp3.get("p", "") == "investigate":
					break
			var q3 = Missions._from_spec(vid, sp3)
			print("MW poolinv ", sp3["t"], " item=", sp3["item"], " site=", q3["steps"][0].get("site", "-"), " clues=", q3["steps"][3].get("clues"))
		for lp in (MissionLocal.POOL.get("suna", []) as Array) + (MissionLocal.POOL.get("iwa", []) as Array) + (MissionLocal.POOL.get("ame", []) as Array):
			if lp["p"] == "investigate":
				var q4 = Missions._from_spec(vid, lp)
				print("MW poolinv local ", lp["t"], " site=", q4["steps"][0].get("site", "-"), " clues=", q4["steps"][3].get("clues"))
		rng3.seed = 3
		var sp5 = {}
		for k in 300:
			sp5 = MissionGen._one(vid, "C", rng3)
			if sp5.get("p", "") == "investigate":
				break
		await _start(Missions._from_spec(vid, sp5), "C")
		await get_tree().create_timer(1.0).timeout
		await _npc_shots("veren", "poolinv_victim", 1)
		for k in 3:
			if Missions._cur().get("kind", "") == "collect":
				break
			Missions._next_step()
			await get_tree().create_timer(0.4).timeout
		var cl2 = _works("clue")
		print("MW poolinv step=", Missions._cur().get("text"), " clues=", cl2.size(), " kinds=", cl2.map(func(x): return x.get("ck")))
		for k in cl2.size():
			await _do(cl2[k], "poolinv_clue%d" % k, [1.2] if k == 1 else [])
			await _wait_work()
			await get_tree().create_timer(0.3).timeout
		print("MW poolinv after clues step=", Missions._cur().get("kind"), " ", Missions._cur().get("text"))

	if "snake" in which or "puppet" in which:
		Game.profile["rank"] = 5
		var ts = Missions._templates("S", vid)
		print("MW S titles=", ts.map(func(x): return x["title"]))
		for q5 in ts:
			if ("snake" in which and "Yılan" in q5["title"]) or ("puppet" in which and "Kukla" in q5["title"]):
				await _start(q5, "S")
				await get_tree().create_timer(1.0).timeout
				main.world.env.time_of_day = 0.45
				var first = "anne" if "Yılan" in q5["title"] else "tanik"
				await _npc_shots(first, "S_%s" % first, 1)
				if Missions._cur().get("kind", "") != "collect":
					Missions._next_step()
					await get_tree().create_timer(0.6).timeout
				var cl3 = _works("clue")
				print("MW S clues=", cl3.size(), " kinds=", cl3.map(func(x): return x.get("ck")), " step=", Missions._cur().get("text"))
				for k in cl3.size():
					await _do(cl3[k], "S_%s_clue%d" % [first, k], [1.2])
					await _wait_work()
					await get_tree().create_timer(0.3).timeout
				main.world.env.time_of_day = 0.45
				print("MW S after clues step=", Missions._cur().get("kind"), " ", Missions._cur().get("text"), " lair=", Missions.st.get("lair"), " lair_h=", Missions.active().get("lair_h"))
				if first == "tanik":
					var bs = Missions.step_nodes.filter(func(x): return is_instance_valid(x) and x is Boss)
					print("MW S boss=", bs.size())
					for b2 in bs:
						b2.queue_free()
					Missions._next_step()
					await get_tree().create_timer(0.5).timeout
					print("MW S puppet step=", Missions._cur().get("text"), " npc=", is_instance_valid(Missions.npcs.get("tanik")))
					await _talk_scene("S_tanik_pay", 2)
					print("MW S puppet done=", Missions.active().is_empty())
					continue
				var door4 = Interact.items.filter(func(x): return String(x.get("room", "")).begins_with("lair_"))
				print("MW S doors=", door4.size())
				if door4.is_empty():
					continue
				pl.global_position = door4[0]["pos"] + Vector3(0, 0.3, 0)
				await get_tree().create_timer(0.3).timeout
				Interiors.inst.enter(door4[0])
				await get_tree().create_timer(2.5).timeout
				var kid2 = Missions.npcs.get("rehine")
				print("MW S inside=", Interiors.inst.inside, " kid=", kid2 != null, " enemies=", Missions.step_nodes.filter(func(x): return is_instance_valid(x) and x is Enemy).size())
				if kid2 == null:
					continue
				print("MW S kid pos rel=", kid2.global_position - Interiors.inst.origin, " bound=", MissionWork.I().bound_d.has(kid2))
				for e in Missions.step_nodes:
					if is_instance_valid(e) and e is Enemy:
						e.queue_free()
				await get_tree().create_timer(0.2).timeout
				pl.global_position = kid2.global_position + kid2.face_dir() * 2.2 + Vector3.UP * 0.2
				await get_tree().create_timer(0.5).timeout
				_camw(kid2.global_position + kid2.face_dir() * 3.2 + Vector3(1.4, 1.3, 0), kid2.global_position + Vector3.UP * 0.5)
				await _shot("S_kid_bound")
				# içeriden çıkıp geri gir: rehine saklanıp yeniden görünmeli
				Interiors.inst.exit()
				await get_tree().create_timer(2.5).timeout
				print("MW S out: kid vis=", kid2.visible, " valid=", is_instance_valid(kid2))
				Interiors.inst.enter(door4[0])
				await get_tree().create_timer(2.5).timeout
				print("MW S re-in: kid vis=", kid2.visible, " same=", Missions.npcs.get("rehine") == kid2)
				for e in Missions.step_nodes:
					if is_instance_valid(e) and e is Enemy:
						e.queue_free()
				Missions._next_step()
				await get_tree().create_timer(1.0).timeout
				print("MW S talk step=", Missions._cur().get("text"), " kid valid=", is_instance_valid(kid2), " same=", Missions.npcs.get("rehine") == kid2)
				pl.global_position = kid2.global_position + kid2.face_dir() * 1.8 + Vector3.UP * 0.2
				await get_tree().create_timer(0.4).timeout
				Missions._after_talk(kid2, Missions._cur())
				await get_tree().create_timer(1.6).timeout
				_camw(kid2.global_position + kid2.face_dir() * 2.4 + Vector3(1.2, 1.1, 0), kid2.global_position + Vector3.UP * 0.5)
				await _shot("S_kid_untie")
				await _wait_work()
				await get_tree().create_timer(0.5).timeout
				print("MW S kid mode=", kid2.mode, " step=", Missions._cur().get("text"))
				Interiors.inst.exit()
				await get_tree().create_timer(3.0).timeout
				print("MW S out2: kid-player d=", snappedf(kid2.global_position.distance_to(pl.global_position), 0.1), " kid y-ground=", snappedf(kid2.global_position.y - Game.ground_height(kid2.global_position.x, kid2.global_position.z), 0.1))
				var mom2 = Missions.npcs.get("anne")
				print("MW S mom=", mom2 != null and is_instance_valid(mom2))
				if mom2 and is_instance_valid(mom2):
					pl.global_position = mom2.global_position + mom2.face_dir() * 1.7 + Vector3.UP * 0.2
					kid2.global_position = mom2.global_position + mom2.face_dir() * 3.5 + Vector3(1.5, 0.2, 0)
					await get_tree().create_timer(0.6).timeout
					mom2.talk()
					await get_tree().create_timer(0.2).timeout
					Missions._after_talk(mom2, Missions._cur())
					for i in 3:
						await get_tree().create_timer(1.3).timeout
						if not is_instance_valid(mom2) or not is_instance_valid(kid2):
							break
						var c7 = (kid2.global_position + mom2.global_position) * 0.5
						var d7 = (kid2.global_position - mom2.global_position)
						d7.y = 0
						_camw(c7 + d7.normalized().cross(Vector3.UP) * 2.8 + Vector3.UP * 1.3, c7 + Vector3.UP * 0.9)
						await _shot("S_reunion_%d" % i)
					await _wait_work()
					await get_tree().create_timer(0.5).timeout
					for w in 40:
						if Missions.active().is_empty():
							break
						await get_tree().create_timer(0.5).timeout
						if w % 8 == 0:
							print("MW S wait w=", w, " work=", MissionWork.active(), " busy_run=", MissionWork.I().busy_run, " step=", Missions._cur().get("text"), " dlg=", Hud.dialog_open() if Hud.has_method("dialog_open") else "?")
					print("MW S snake done=", Missions.active().is_empty())

	get_tree().quit()
