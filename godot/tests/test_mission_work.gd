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
	get_tree().quit()
