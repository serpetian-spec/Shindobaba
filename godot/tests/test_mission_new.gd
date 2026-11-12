extends Node
## Yeni görev türleri (5. adım): MN=hunt,guard,relay (virgülle), MV=köy
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
	print("MN start ", m["title"], " [", m["rank"], "] steps=", m["steps"].map(func(s): return s["kind"]), " news=", m.get("news"))
	return m


func _finish_wait(tag: String) -> void:
	for w in 60:
		if Missions.active().is_empty():
			break
		await get_tree().create_timer(0.5).timeout
	print("MN ", tag, " done=", Missions.active().is_empty(), " news=", WorldNews.recent().slice(-1))


func _q(q: Dictionary, rank: String) -> Dictionary:
	q["rank"] = rank
	q["village"] = Progress.home()
	q["type"] = "quest"
	q["giver"] = "Görev Masası"
	return await _begin(q)


func _orbit(c: Vector3, tag: String, d := 7.0, h := 3.0, angs := [0.6, 2.4, 4.2]) -> void:
	for i in angs.size():
		_camw(c + Vector3(cos(angs[i]) * d, h, sin(angs[i]) * d), c + Vector3.UP * 1.0)
		await _shot("%s_%d" % [tag, i])


func _cur_npc() -> Node3D:
	var s = Missions._cur()
	return Missions.npcs.get(s.get("npc_id", s.get("npc", {}).get("id", "")))


func _ready() -> void:
	await get_tree().process_frame
	var vid = OS.get_environment("MV") if OS.get_environment("MV") != "" else "konoha"
	var which = (OS.get_environment("MN") if OS.get_environment("MN") != "" else "hunt,guard,relay,fish,repair,build,teach").split(",")
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
	seed(11)
	var W = MissionWork.I()

	if "hunt" in which:
		var m = await _q(Missions._q_hunt(vid), "C")
		var hn = _cur_npc()
		print("MN hunt npc=", hn != null, " camp=", W.hunt_d.has("rack"))
		if hn:
			pl.global_position = hn.global_position + Vector3(3, 0.3, 3)
			await get_tree().create_timer(1.2).timeout
			await _orbit(W.hunt_d["root"].global_position, "hunt_camp", 7.5, 3.2)
		await _talk_cur()
		await get_tree().create_timer(0.8).timeout
		var prey: Array = W.hunt_d.get("prey", [])
		print("MN hunt step=", Missions._cur().get("kind"), " prey=", prey.size(), " kind=", W.hunt_d.get("kind"))
		for kind in ["geyik", "domuz", "tavşan"]:
			# her tür: yakından görünüş
			var p0 = Prey.new()
			p0.kind = kind
			p0.position = Missions.open_ground(W.hunt_d["root"].global_position + Vector3(12, 0, 10), 8.0)
			get_tree().current_scene.add_child(p0)
			p0.set_physics_process(false)
			pl.global_position = p0.global_position + Vector3(30, 0, 30)
			await get_tree().create_timer(0.2).timeout
			_camw(p0.global_position + Vector3(2.6, 1.3, 2.2), p0.global_position + Vector3.UP * 0.7)
			await _shot("prey_" + kind)
			if kind == "domuz":
				# saldırı: oyuncu önünde, canı düşmeli
				p0.set_physics_process(true)
				pl.global_position = p0.global_position + p0.face_dir() * 7.0 + Vector3.UP * 0.2
				var hp0 = pl.hp
				await get_tree().create_timer(0.5).timeout
				_camw(p0.global_position + Vector3(4, 2, 5), (p0.global_position + pl.global_position) * 0.5 + Vector3.UP * 0.6)
				await _shot("boar_paw")
				print("MN boar charge_t=", p0.charge_t)
				await get_tree().create_timer(1.6).timeout
				print("MN boar hit: hp ", hp0, " -> ", pl.hp, " rest=", p0.rest_t)
				# oyuncunun vuruşu işler mi
				var bh = p0.hp
				Combat.hit_sphere(pl, p0.global_position + Vector3.UP * 0.5, 1.0, {"dmg": 20.0})
				print("MN boar took: ", bh, " -> ", p0.hp)
				pl.hp = pl.max_hp
			if kind == "geyik":
				p0.set_physics_process(true)
				var a0 = p0.global_position
				# arkadan sessizce: fark etmemeli
				pl.global_position = p0.global_position - p0.face_dir() * 5.0 + Vector3.UP * 0.2
				await get_tree().create_timer(0.6).timeout
				print("MN deer behind: flee=", p0.flee_t > 0.0)
				pl.global_position = p0.global_position + p0.face_dir() * 12.0 + Vector3.UP * 0.2
				await get_tree().create_timer(1.5).timeout
				print("MN deer front: flee=", p0.flee_t > 0.0, " moved=", snappedf(p0.global_position.distance_to(a0), 0.1))
			p0.queue_free()
		for i in prey.size():
			var p: Prey = prey[i]
			if i == 0:
				pl.global_position = p.global_position + Vector3(40, 0, 40)
				await get_tree().create_timer(0.3).timeout
				_camw(p.global_position + Vector3(9, 4, 9), p.global_position + Vector3.UP * 0.6)
				await _shot("hunt_herd")
			pl.global_position = p.global_position - p.face_dir() * 2.0 + Vector3.UP * 0.2
			p.take_hit({"dmg": 999.0, "attacker": pl})
			await get_tree().create_timer(1.2).timeout
			if i == 0:
				_camw(p.global_position + Vector3(2.4, 1.6, 2.0), p.global_position + Vector3.UP * 0.3)
				await _shot("hunt_dead")
			var its = _works("carcass")
			print("MN carcass items=", its.size())
			if its.is_empty():
				break
			W.run(its[0])
			if i == 0:
				await get_tree().create_timer(0.9).timeout
				_side(p.global_position, 2.8, 1.2)
				await _shot("hunt_lift")
			await _wait_work()
			if i == 0:
				await get_tree().create_timer(0.3).timeout
				for k in 3:
					var a = [0.5, 2.6, 4.4][k]
					_camw(pl.global_position + Vector3(cos(a) * 3.0, 1.6, sin(a) * 3.0), pl.global_position + Vector3.UP * 1.2)
					await _shot("hunt_carry_%d" % k)
			var rk = _works("rack")
			print("MN rack items=", rk.size(), " marker_d=", snappedf(Missions.target_marker.distance_to(W.hunt_d["rack_front"]), 0.1))
			pl.global_position = W.hunt_d["rack_front"] + Vector3(0.5, 0.2, 2.5)
			await get_tree().create_timer(0.3).timeout
			W.run(rk[0])
			await _wait_work()
			await get_tree().create_timer(1.6).timeout
			print("MN hung=", W.hunt_d.get("hung"), " st.n=", Missions.st.get("n"), " step=", Missions.active().get("step", -1))
		var rc: Vector3 = W.hunt_d["rack"]
		pl.global_position = rc + Vector3(4, -1.8, 4)
		await get_tree().create_timer(0.3).timeout
		_camw(rc + Vector3(0.5, 0.2, 4.2), rc - Vector3.UP * 0.8)
		await _shot("hunt_rack_0")
		_camw(rc + Vector3(3.6, 0.6, 1.5), rc - Vector3.UP * 0.8)
		await _shot("hunt_rack_1")
		if Missions._cur().get("kind", "") == "talk":
			await _talk_scene("hunt_pay", 0)
		await _finish_wait("hunt")

	if "guard" in which:
		for round in 1:
			seed(21 + round)
			var m = await _q(Missions._q_guard(vid), "D")
			var g = _cur_npc()
			var key = "%s:guard_post" % String(m["id"])
			print("MN guard npc=", g != null, " site=", W.sites.has(key))
			if round == 0 and W.sites.has(key):
				var sc: Vector3 = W.sites[key]["root"].global_position
				pl.global_position = sc + Vector3(4, 0.3, 5)
				await get_tree().create_timer(1.2).timeout
				await _orbit(sc, "guard_post", 6.5, 2.6, [1.2, 2.3, 0.2])
			await _talk_cur()
			await get_tree().create_timer(0.8).timeout
			var lamps = _works("lamp")
			print("MN lamps=", lamps.size(), " tod=", snappedf(main.world.env.time_of_day, 0.01))
			for i in lamps.size():
				var node: Node3D = lamps[i]["node"]
				pl.global_position = node.global_position + Vector3(1.5, 0.2, 1.5)
				await get_tree().create_timer(0.2).timeout
				W.run(lamps[i])
				if round == 0 and i == 0:
					await get_tree().create_timer(0.9).timeout
					_camw(node.global_position + Vector3(2.6, 1.7, 2.2), node.global_position + Vector3.UP * 1.5)
					await _shot("lamp_act")
				await _wait_work()
			if round == 0 and lamps.size() > 0:
				var l0: Vector3 = lamps[0]["node"].global_position
				_camw(l0 + Vector3(9, 5, 9), l0 + Vector3(-4, 1, -4))
				await get_tree().create_timer(0.6).timeout
				await _shot("lamp_lit")
			var guard_n := 0
			while not Missions.active().is_empty() and guard_n < 6:
				guard_n += 1
				var s = Missions._cur()
				if s["kind"] == "kill":
					await get_tree().create_timer(0.5).timeout
					var foes = get_tree().get_nodes_in_group("fighters").filter(func(f): return f is Enemy and not f.is_dead() and Combat.hostile(pl, f) and f.global_position.distance_to(pl.global_position) < 60.0)
					print("MN smuggler fight foes=", foes.size(), " names=", foes.map(func(f): return f.get("display_name") if f.get("display_name") != null else f.name))
					if round == 0 and not foes.is_empty():
						_camw(foes[0].global_position + Vector3(3, 1.8, 3), foes[0].global_position + Vector3.UP)
						await _shot("guard_fight")
					for f in foes:
						f.die({"attacker": pl})
					await get_tree().create_timer(1.5).timeout
					continue
				if s["kind"] != "talk":
					print("MN guard unexpected step ", s["kind"])
					break
				var npc = _cur_npc()
				if not s.has("choices"):
					print("MN guard final say_if=", s.has("say_if"), " flags=", Missions.active().get("flags"))
					pl.global_position = npc.global_position + Vector3(1.6, 0.2, 0.4)
					await get_tree().create_timer(0.3).timeout
					npc.talk()
					await get_tree().create_timer(0.2).timeout
					print("MN guard final line: ", Hud.last_dialog.substr(0, 60))
					Missions._after_talk(npc, s)
					await _wait_work()
					break
				# yolcu: gelmesini bekle
				var stop = Missions._w(s["at"])
				pl.global_position = stop + Vector3(1.5, 0.3, 1.0)
				var d0 = npc.global_position.distance_to(stop)
				if round == 0 and guard_n == 1:
					await get_tree().create_timer(2.5).timeout
					_camw(stop + Vector3(3, 2.2, 2), npc.global_position + Vector3.UP)
					await _shot("guard_arrive")
				var wt := 0.0
				while npc.global_position.distance_to(stop) > 2.0 and wt < 25.0:
					wt += 0.25
					await get_tree().create_timer(0.25).timeout
				print("MN traveller ", npc.display, " walked ", snappedf(d0, 0.1), " m in ", wt, " s; left=", snappedf(npc.global_position.distance_to(stop), 0.1))
				pl.global_position = npc.global_position + Vector3(1.4, 0.2, 0.6)
				await get_tree().create_timer(0.3).timeout
				npc.talk()
				await get_tree().create_timer(0.2).timeout
				var bad = String(s["choices"][0]["search"]) == "tags"
				var pick = 0 if round == 0 else 1
				Hud.last_options[pick]["cb"].call()
				if pick == 0:
					await get_tree().create_timer(2.6).timeout
					if bad or guard_n == 1:
						var c = (pl.global_position + npc.global_position) * 0.5
						var sd = (npc.global_position - pl.global_position).normalized().cross(Vector3.UP)
						_camw(c + sd * 2.4 + Vector3.UP * 1.3, c + Vector3.UP * 0.5)
						await _shot("guard_search_%s" % ("bad" if bad else "ok"))
						_camw(c - sd * 1.6 + Vector3.UP * 1.6, c + Vector3.UP * 0.25)
						await _shot("guard_search_%s_b" % ("bad" if bad else "ok"))
					await _wait_work()
				await get_tree().create_timer(0.4).timeout
				print("MN reply: ", Hud.last_dialog.substr(0, 50))
				Hud.last_options[0]["cb"].call()
				await get_tree().create_timer(1.0).timeout
			await _finish_wait("guard%d" % round)
			main.world.env.time_of_day = 0.45

	if "relay" in which:
		seed(31)
		var m = await _q(Missions._q_relay(vid), "C")
		print("MN relay brief: ", String(m["brief"]).substr(0, 120))
		for i in 3:
			var s = Missions._cur()
			if s.get("kind", "") != "talk":
				break
			var npc = _cur_npc()
			var key = "%s:beacon%d" % [String(m["id"]), i]
			print("MN beacon ", i, " npc=", npc != null, " site=", W.sites.has(key), " d_village=", snappedf(Game.to_map(npc.global_position).distance_to(Vector2(Game.village(vid)["x"], Game.village(vid)["y"])), 1.0) if npc else -1)
			if npc == null or not W.sites.has(key):
				break
			var sc: Vector3 = W.sites[key]["root"].global_position
			pl.global_position = npc.global_position + npc.face_dir() * 1.7 + Vector3.UP * 0.2
			await get_tree().create_timer(1.2).timeout
			if i == 0:
				await _orbit(sc, "beacon_unlit", 6.5, 2.8, [0.9, 2.6])
			npc.talk()
			await get_tree().create_timer(0.2).timeout
			if i == 0:
				print("MN beacon line: ", Hud.last_dialog.substr(0, 90))
			Missions._after_talk(npc, s)
			if i == 0:
				await get_tree().create_timer(1.6).timeout
				_camw(sc + Vector3(4.5, 2.4, 5.0), sc + Vector3.UP * 1.3)
				await _shot("beacon_walk")
				await get_tree().create_timer(1.3).timeout
				await _shot("beacon_torch")
			await _wait_work()
			await get_tree().create_timer(2.5).timeout
			if i == 0:
				_camw(sc + Vector3(5.5, 2.6, 6.0), sc + Vector3.UP * 2.2)
				await _shot("beacon_lit")
				await get_tree().create_timer(3.0).timeout
				_camw(sc + Vector3(5.0, 1.2, 6.0), sc + Vector3.UP * 6.5)
				await _shot("beacon_far")
			await _wait_work()
			print("MN beacon ", i, " lit=", W.sites[key].get("lit", false), " step=", Missions.active().get("step", -1))
		await _finish_wait("relay")
	if "fish" in which:
		seed(41)
		MissionWork.test_auto = true
		var fq = Missions._q_fish(vid)
		print("MN fish shore=", not fq.is_empty())
		if not fq.is_empty():
			await _q(fq, "D")
			var d = W.job_d
			var h0 = d["mid"]
			print("MN fish dock dy=", snappedf(d["dy"], 0.01), " wl=", d["wl"], " land_y=", snappedf(d["root"].global_position.y, 0.01), " water_under_end=", snappedf(Game.terrain_height(d["cast_at"].x, d["cast_at"].z), 0.01))
			pl.global_position = d["start"] + Vector3(2, 0.3, 3)
			await get_tree().create_timer(1.2).timeout
			await _orbit(h0, "fish_dock", 11.0, 4.5, [0.4, 2.2, 4.0])
			await _talk_cur()
			await get_tree().create_timer(0.8).timeout
			var its = _works("fish")
			print("MN fish items=", its.size(), " step=", Missions._cur().get("kind"))
			for i in its.size():
				pl.global_position = d["start"] + Vector3(0, 0.2, 1.0)
				await get_tree().create_timer(0.2).timeout
				W.run(its[i])
				if i == 0:
					for k in 7:
						await get_tree().create_timer(0.85).timeout
						var ca: Vector3 = d["cast_at"]
						var sd = (d["dir"] as Vector3).cross(Vector3.UP)
						_camw(ca + sd * 5.5 + Vector3.UP * 2.2 - d["dir"] * 1.0, ca + d["dir"] * 2.2 + Vector3.UP * 0.8)
						await _shot("fish_a_%d" % k)
				await _wait_work()
				await get_tree().create_timer(0.3).timeout
			print("MN fish n=", d.get("fish_n"), " step=", Missions.active().get("step", -1))
			_camw(d["basket"] + Vector3(0.9, 0.9, 0.9), d["basket"])
			await _shot("fish_basket")
			if Missions._cur().get("kind", "") == "talk":
				await _talk_scene("fish_pay", 0)
			await _finish_wait("fish")

	if "repair" in which:
		seed(51)
		await _q(Missions._q_repair(vid), "D")
		var d = W.job_d
		var rc: Vector3 = d["root"].global_position
		pl.global_position = rc + Vector3(3, 0.3, 6)
		await get_tree().create_timer(1.2).timeout
		await _orbit(rc, "repair_site", 8.5, 3.4, [1.0, 1.9, 2.6])
		await _talk_cur()
		await get_tree().create_timer(0.8).timeout
		var its = _works("plank")
		print("MN repair items=", its.size())
		for i in its.size():
			pl.global_position = rc + Vector3(1, 0.2, 4)
			await get_tree().create_timer(0.2).timeout
			W.run(its[i])
			if i == 0:
				for k in 6:
					await get_tree().create_timer(1.0).timeout
					_camw(pl.global_position + Vector3(2.6, 1.5, 2.8), pl.global_position + Vector3.UP * 1.0)
					await _shot("repair_a_%d" % k)
			await _wait_work()
			await get_tree().create_timer(0.3).timeout
		print("MN repair step=", Missions.active().get("step", -1))
		pl.global_position = rc + Vector3(-3.4, 0.2, 4.6)
		await get_tree().create_timer(0.3).timeout
		_camw(rc + Vector3(1.5, 2.0, 7.0), rc + Vector3.UP * 1.2)
		await _shot("repair_done")
		if Missions._cur().get("kind", "") == "talk":
			await _talk_scene("repair_pay", 0)
		await _finish_wait("repair")

	if "build" in which:
		seed(61)
		await _q(Missions._q_build(vid), "C")
		var d = W.job_d
		var bc: Vector3 = d["root"].global_position
		pl.global_position = bc + Vector3(3, 0.3, 6)
		await get_tree().create_timer(1.2).timeout
		await _orbit(bc, "build_lot", 9.0, 4.0, [1.0, 2.4])
		await _talk_cur()
		await get_tree().create_timer(0.8).timeout
		for stg in 4:
			var its = _works("build")
			print("MN build stage=", stg, " items=", its.size(), " n=", Missions._cur().get("n"))
			if its.is_empty():
				break
			pl.global_position = bc + Vector3(2, 0.2, 4)
			await get_tree().create_timer(0.2).timeout
			W.run(its[0])
			if stg == 0:
				await get_tree().create_timer(2.2).timeout
				_camw(pl.global_position + Vector3(-2.8, 1.6, 2.6), pl.global_position + Vector3.UP * 1.2)
				await _shot("build_carry")
			await _wait_work()
			await get_tree().create_timer(0.3).timeout
			_camw(bc + Vector3(6.5, 3.6, 7.5), bc + Vector3.UP * 1.8)
			await _shot("build_stage_%d" % stg)
		print("MN build step=", Missions.active().get("step", -1), " stage=", d.get("stage"))
		if Missions._cur().get("kind", "") == "talk":
			await _talk_scene("build_pay", 0)
		await _finish_wait("build")

	if "teach" in which:
		seed(71)
		var m = await _q(Missions._q_teach(vid), "D")
		var d = W.job_d
		print("MN teach site=", d.get("kind"), " kids=", (d.get("kids", []) as Array).size(), " step0=", Missions._cur().get("kind"), " work=", Missions._cur().get("work"))
		var tc: Vector3 = d["root"].global_position
		pl.global_position = tc + Vector3(3, 0.3, 6)
		await get_tree().create_timer(1.2).timeout
		await _orbit(tc, "teach_yard", 10.0, 4.5, [1.2, 2.0, 4.4])
		if Missions._cur().get("kind", "") == "talk":
			await _talk_cur()
			await get_tree().create_timer(0.8).timeout
		var its = _works("teach")
		print("MN teach items=", its.size())
		for i in its.size():
			pl.global_position = tc + Vector3(0, 0.2, 3.0)
			await get_tree().create_timer(0.2).timeout
			W.run(its[i])
			if i == 0:
				for k in 10:
					await get_tree().create_timer(1.15).timeout
					var tg: Vector3 = d["targets"][0]
					_camw(Vector3(tg.x + 4.2, tc.y + 2.0, tc.z + 4.6), Vector3(tg.x, tc.y + 1.0, tc.z - 0.8))
					await _shot("teach_a_%d" % k)
			await _wait_work(30.0)
			await get_tree().create_timer(0.3).timeout
		print("MN teach step=", Missions.active().get("step", -1))
		var tg0: Vector3 = d["targets"][0]
		_camw(tg0 + Vector3(0.9, 0.3, 1.6), tg0)
		await _shot("teach_target")
		if Missions._cur().get("kind", "") == "talk":
			await _talk_scene("teach_pay", 0)
		await _finish_wait("teach")
	get_tree().quit()
