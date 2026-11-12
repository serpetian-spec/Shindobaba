extends Node
## Dünya ninjalarının günü: günün işi dağılımı, köyde gerçek kişilerin sahneye çıkması, takım çıkışı / dönüşü, tanışma, yol. WV=köy
var main: Node
var cam: Camera3D


func _camw(p: Vector3, t: Vector3) -> void:
	if cam == null or not is_instance_valid(cam):
		cam = Camera3D.new()
		main.add_child(cam)
		cam.fov = 50.0
	cam.global_position = p
	cam.look_at(t)
	cam.current = true


func _shot(nm: String) -> void:
	await get_tree().create_timer(0.1).timeout
	await main.shot("wd_" + nm)


func _cast() -> Array:
	return get_tree().get_nodes_in_group("talkers").filter(func(n): return is_instance_valid(n) and n.has_meta("world_person") and not n.is_queued_for_deletion())


func _tp(pl, at: Vector3) -> void:
	at.y = Game.ground_height(at.x, at.z) + 0.3
	pl.global_position = at
	pl.velocity = Vector3.ZERO
	pl.reset_physics_interpolation()


func _ready() -> void:
	await get_tree().process_frame
	var vid = OS.get_environment("WV") if OS.get_environment("WV") != "" else "konoha"
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": vid, "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "eye": Color(0.2, 0.4, 0.9), "skin": Color(0.96, 0.8, 0.66)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	main.world.env.time_of_day = 0.5
	Game.profile["kd_wait"] = 99999.0
	WorldDay.auto = false
	WorldKin.auto = false
	var vl = WorldDay.vl
	print("WD vl=", vl, " people=", WorldPeople.all().size())
	# --- 1) günün işi dağılımı (dilim dilim)
	var mine = WorldPeople.all().values().filter(func(p): return String(p["village"]) == vid)
	for ph in ["sabah", "oglen", "aksam", "gece"]:
		var cnt = {}
		for p in mine:
			var a = WorldDay.act_of(p, ph)
			cnt[a] = int(cnt.get(a, 0)) + 1
		print("WD act ", ph, " ", cnt)
	# --- 1b) bağlar: hoca / rakip
	seed(5)
	for i in 6:
		WorldDay.bond_pass()
	var vm = WorldPeople.all().values().filter(func(p): return String(p["village"]) == vid and WorldPeople.alive(p))
	print("WD bonds ", vid, ": genin=", vm.filter(func(p): return int(p["rank"]) == 0).size(), " with_sensei=", vm.filter(func(p): return p.has("sensei")).size(), " rivals=", vm.filter(func(p): return p.has("rival")).size(),
		" max_students=", vm.map(func(p): return (p.get("students", []) as Array).size()).max())
	var rvs = vm.filter(func(p): return p.has("rival") and int(p["rank"]) < 3)
	if not rvs.is_empty():
		var a0: Dictionary = rvs[0]
		var b0 = WorldPeople.get_p(String(a0["rival"]))
		a0["rank"] = int(a0["rank"]) + 1
		WorldDay.on_promote(a0)
		print("WD   rival ", a0["name"], " (lv ", a0["level"], ") vs ", b0["name"], " (lv ", b0["level"], ") behind=", b0.get("behind", false), " log=", (b0["log"] as Array).slice(-1), " lines=", WorldDay.lines(b0, "gezi").slice(0, 3))
		a0["rank"] = int(a0["rank"]) - 1
	var st = vm.filter(func(p): return p.has("sensei"))
	if not st.is_empty():
		var sn = WorldPeople.get_p(String(st[0]["sensei"]))
		print("WD   student ", st[0]["name"], " sensei=", sn["name"], " ties=", WorldDay.ties(sn).map(func(b): return "%s:%s" % [b[1], b[0]["name"]]), " lines=", WorldDay.lines(st[0], "gezi").slice(0, 3))
	# --- 1c) kişilik + hedef
	var dc = {}
	for p in WorldPeople.all().values():
		if WorldPeople.alive(p) and not WorldPeople.is_rogue(p):
			var d = WorldDay.dream(p)
			dc[d] = int(dc.get(d, 0)) + 1
	print("WD dreams (world) ", dc)
	var seen_d = {}
	for p in vm:
		var d = WorldDay.dream(p)
		if not seen_d.has(d):
			seen_d[d] = true
			print("WD   dream ", d, " ", p["name"], " temper=", WorldDay.temper(p).snapped(Vector2(0.1, 0.1)), " | ", WorldDay.dream_line(p), " | ", WorldDay.regard(p).get("line", ""))
	# --- 2) kapı / görev masası konumu
	var gs = WorldDay.gates(vid)
	var c0 = Game.from_map(Vector2(float(Game.village(vid)["x"]), float(Game.village(vid)["y"])))
	for g in gs:
		var bd = 1e9
		for s in vl.sites.get(vid, []):
			if String(s["type"]) == "guard":
				bd = minf(bd, (s["pos"] as Vector3).distance_to(g))
		print("WD gate ", g.snapped(Vector3.ONE), " r=", snappedf(g.distance_to(c0), 1.0), " nearest guard=", snappedf(bd, 0.1))
	print("WD hall ", WorldDay.hall(vid).snapped(Vector3.ONE), " centre=", c0.snapped(Vector3.ONE), " player=", pl.global_position.snapped(Vector3.ONE))
	var types = {}
	for s in vl.sites.get(vid, []):
		types[String(s["type"])] = int(types.get(String(s["type"]), 0)) + 1
	print("WD sites ", types)
	# --- 3) hızlı benzetim: 200 tur (5 saat) — ölüm / yara / kayıp oranı
	if OS.get_environment("WDQ") == "":
		seed(7)
		var wp: Node = null
		for n in get_tree().root.find_children("*", "", true, false):
			if n.has_method("world_tick") and n.has_method("populate"):
				wp = n
				break
		WorldDay.vl = null
		var alive0 = WorldPeople.all().values().filter(func(p): return WorldPeople.alive(p)).size()
		var runs_n = 0
		var hurt_n = 0
		var clk0 = float(Game.profile.get("clock", 0.0))
		for i in 200:
			Game.profile["clock"] = float(Game.profile.get("clock", 0.0)) + 90.0
			wp.world_tick()
			WorldKin.world_tick(WorldPeople.TICK)
			for k in 3:
				var vv = (WorldPeople.MAJOR + WorldPeople.MINOR).pick_random()
				if not WorldDay.dispatch(vv).is_empty():
					runs_n += 1
			for run in (WorldDay.D()["runs"] as Array).duplicate():
				if float(Game.profile["clock"]) >= float(run["t1"]):
					WorldDay.resolve(run)
			hurt_n = maxi(hurt_n, WorldPeople.all().values().filter(func(p): return WorldDay.hurt(p)).size())
		var al = WorldPeople.all().values()
		var live = al.filter(func(p): return WorldPeople.alive(p))
		print("WD sim runs=", runs_n, " people=", al.size(), " alive ", alive0, "->", live.size(), " dead_on_mission=", al.filter(func(p): return not WorldPeople.alive(p) and (p["log"] as Array).any(func(l): return String(l).begins_with("Bir görevden dönmedi"))).size(),
			" missing=", live.filter(func(p): return p.get("missing", false)).size(), " max_hurt=", hurt_n, " out_now=", live.filter(func(p): return WorldDay.away(p)).size(), " rogue=", live.filter(func(p): return WorldPeople.is_rogue(p)).size())
		for v in WorldPeople.MAJOR:
			print("WD   ", v, " ninja=", live.filter(func(p): return String(p["village"]) == v and not WorldPeople.is_rogue(p)).size())
		var smp = live.filter(func(p): return String(p["village"]) == vid and (p["log"] as Array).size() >= 3)
		if not smp.is_empty():
			print("WD log ", smp[0]["name"], " ", smp[0]["log"])
		var dc2 = {}
		for p in live:
			if not WorldPeople.is_rogue(p):
				dc2[WorldDay.dream(p)] = int(dc2.get(WorldDay.dream(p), 0)) + 1
		print("WD dreams after sim ", dc2)
		WorldDay.vl = vl
		Game.profile["clock"] = clk0 + 18000.0
	# --- 4) köyde sahne: gerçek kişiler rollerde
	await get_tree().create_timer(3.0 if OS.get_environment("WDL") != "" else 14.0).timeout
	var cs = _cast()
	print("WD staged=", cs.size(), " of village npcs=", vl.npcs.size())
	for n in cs:
		var p = WorldPeople.get_p(String(n.get_meta("world_person")))
		print("WD   ", p["name"], " rank=", p["rank"], " role=", n.role, " act=", n.get_meta("world_act"), " now=", WorldDay.act_of(p), " d=", snappedf(n.global_position.distance_to(pl.global_position), 1.0), " tag=", n.name_tag != null)
	# iki kez sahnede olan var mı
	var ids = cs.map(func(n): return String(n.get_meta("world_person")))
	var dup = ids.filter(func(i): return ids.count(i) > 1)
	print("WD duplicates=", dup)
	# --- 5) antrenman sahası (varsa): eşleşen gerçek çift
	var spar_at = Vector3.INF
	for s in vl.sites.get(vid, []):
		if String(s["type"]) == "spar":
			spar_at = s["pos"]
			break
	if spar_at != Vector3.INF and OS.get_environment("WDL") == "":
		_tp(pl, spar_at + Vector3(7, 0, 7))
		await get_tree().create_timer(7.0).timeout
		var sp = _cast().filter(func(n): return n.role == "spar")
		print("WD spar site cast=", sp.size())
		for n in sp:
			var p = WorldPeople.get_p(String(n.get_meta("world_person")))
			print("WD   spar tie=", WorldDay.tie_of(p, WorldPeople.get_p(String(sp[1 - sp.find(n)].get_meta("world_person")))) if sp.size() == 2 else "-")
			print("WD   spar ", p["name"], " close=", WorldPeople.get_p(String(p.get("close", ""))).get("name", "-"), " lines=", n.lines_override.slice(0, 2), " log=", (p["log"] as Array).slice(-1))
		if not sp.is_empty():
			var c = sp[0].global_position
			_camw(c + Vector3(3.2, 1.7, 4.2), c + Vector3(-0.8, 1.1, 0))
			await _shot("10_spar")
			_camw(c + Vector3(1.6, 1.6, 2.2), c + Vector3(0, 1.5, 0))
			await _shot("11_spar_close")
	# --- 6) takım çıkışı: kapıya yürür
	var gate: Vector3 = gs[0] if not gs.is_empty() else c0
	var h = WorldDay.hall(vid)
	_tp(pl, Vector3(float(OS.get_environment("WX")), 0, float(OS.get_environment("WZ"))) if OS.get_environment("WX") != "" else c0 + Vector3(-120, 0, -120))
	await get_tree().create_timer(4.0).timeout
	var npts = vl._streets(Game.village(vid)).filter(func(q): return q.distance_to(pl.global_position) > 30.0 and q.distance_to(pl.global_position) < 58.0).size()
	print("WD leave: street pts near=", npts, " outdoors=", WorldDay._outdoors(), " vil=", WorldDay.village_of(pl.global_position))
	var run = WorldDay.dispatch(vid)
	print("WD run=", run.get("rank", "?"), " what=", run.get("what", "?"), " team=", (run.get("team", []) as Array).map(func(i): return WorldPeople.get_p(i)["name"]), " groups=", WorldDay._groups.size())
	var team_nodes: Array = WorldDay._groups[-1]["nodes"] if not WorldDay._groups.is_empty() else []
	if not team_nodes.is_empty():
		var lead = team_nodes[0]
		var tgt: Vector3 = lead.dest
		var d0 = lead.global_position.distance_to(tgt)
		await get_tree().create_timer(2.5).timeout
		if is_instance_valid(lead):
			var c = lead.global_position
			var fd = Vector3(-sin(lead.facing), 0, -cos(lead.facing))
			_camw(c + fd * 5.0 + fd.cross(Vector3.UP) * 2.0 + Vector3.UP * 1.6, c + Vector3.UP * 1.1)
			await _shot("20_team_leave")
		for k in 5:
			await get_tree().create_timer(4.0).timeout
			if not is_instance_valid(lead):
				print("WD   lead gone at step ", k)
				break
			print("WD   lead d=", snappedf(lead.global_position.distance_to(tgt), 1.0), " (start ", snappedf(d0, 1.0), ") pl_d=", snappedf(lead.global_position.distance_to(pl.global_position), 1.0), " stuck_n=", lead.nav.get("n", 0), " followers=", team_nodes.slice(1).filter(func(n): return is_instance_valid(n)).map(func(n): return snappedf(n.global_position.distance_to(lead.global_position), 0.1)), " bubble=", lead.bubble != null and lead.bubble.visible)
		for n in team_nodes:
			if is_instance_valid(n):
				n.queue_free()
		await get_tree().create_timer(0.3).timeout
	if OS.get_environment("WDL") != "":
		print("WD done")
		get_tree().quit()
		return
	# --- 7) dönüş: biri yaralı
	if not run.is_empty():
		_tp(pl, gate + (h - gate).normalized() * 20.0)
		await get_tree().create_timer(2.0).timeout
		seed(3)
		run["t1"] = Aging.clock()
		run["ri"] = 4
		run["need"] = 400.0
		for i in run["team"]:
			var tn = WorldDay.staged(String(i))
			if tn != null:
				tn.queue_free()
		await get_tree().create_timer(0.3).timeout
		WorldPeople.get_p(run["team"][0])["hurt_t"] = Aging.clock() + 500.0   # sahne: yaralı dönüş
		WorldDay._t = 0.0
		await get_tree().create_timer(1.0).timeout
		var back: Array = run.get("back", [])
		print("WD back=", back.map(func(i): return WorldPeople.get_p(i)["name"]), " hurt=", back.filter(func(i): return WorldDay.hurt(WorldPeople.get_p(i))).size(), " lost=", (run["team"] as Array).size() - back.size(), " groups=", WorldDay._groups.size())
		for i in run["team"]:
			print("WD   ", WorldPeople.get_p(i)["name"], " ", (WorldPeople.get_p(i)["log"] as Array).slice(-1), " status=", WorldPeople.get_p(i).get("status", ""), " missing=", WorldPeople.get_p(i).get("missing", false))
		if not WorldDay._groups.is_empty():
			var g: Dictionary = WorldDay._groups[-1]
			var lead = g["nodes"][0]
			await get_tree().create_timer(2.0).timeout
			if is_instance_valid(lead):
				var c = lead.global_position
				var fd = Vector3(-sin(lead.facing), 0, -cos(lead.facing))
				_camw(c + fd * 5.0 + fd.cross(Vector3.UP) * 1.6 + Vector3.UP * 1.6, c + Vector3.UP * 1.1)
				await _shot("30_team_back")
				for k in 3:
					await get_tree().create_timer(1.5).timeout
					if is_instance_valid(lead):
						print("WD   back anim=", lead.model.current, " y_err=", snappedf(lead.global_position.y - Game.ground_height(lead.global_position.x, lead.global_position.z), 0.01), " d=", snappedf(lead.global_position.distance_to(lead.dest), 1.0), " floor=", lead.is_on_floor(), " pos=", lead.global_position.snapped(Vector3.ONE), " goal=", lead.goal.snapped(Vector3.ONE), " dest=", lead.dest.snapped(Vector3.ONE), " pl=", pl.global_position.snapped(Vector3.ONE), " gate=", gate.snapped(Vector3.ONE), " pts=", lead.points.size())
				if is_instance_valid(lead):
					var c2 = lead.global_position
					var fd2 = Vector3(-sin(lead.facing), 0, -cos(lead.facing))
					_camw(c2 + fd2 * 5.0 + fd2.cross(Vector3.UP) * 1.6 + Vector3.UP * 1.6, c2 + Vector3.UP * 1.1)
					await _shot("31_team_back2")
				print("WD   back line=", g["line"], " d_to_hall=", snappedf(lead.global_position.distance_to(lead.dest), 1.0))
		print("WD patient0=", WorldDay.patient(vid, 0).get("name", "-"))
	# --- 7b) seni tanırlar: kan davası / minnet / rütbe
	var rs = _cast().filter(func(n): return not n.has_meta("friend_id") and n.follow == null and n.role != "roof" and n.dest == Vector3.INF)
	print("WD regard candidates=", rs.size())
	var kinds = ["", "saved", "vendetta"]
	for i in mini(3, rs.size()):
		var n = rs[i]
		var rp = WorldPeople.get_p(String(n.get_meta("world_person")))
		if kinds[i] == "saved":
			rp["saved_by_player"] = true
		elif kinds[i] == "vendetta":
			rp["vendetta"] = "Uchiha Test"
		_tp(pl, n.global_position + Vector3(2.2, 0, 1.0))
		n.greet_cd = 0.0
		await get_tree().create_timer(1.3).timeout
		var to = pl.global_position - n.global_position
		to.y = 0
		var fd = Vector3(-sin(n.facing), 0, -cos(n.facing))
		print("WD   regard ", kinds[i], " -> ", WorldDay.regard(rp), " bubble=", n.bubble.text if n.bubble and n.bubble.visible else "-", " faces_player=", snappedf(fd.dot(to.normalized()), 0.01), " bow=", n.bow_t > 0.0, " role=", n.role)
		var c = n.global_position
		_camw(c + Vector3(2.6, 1.5, 2.8), c + Vector3(0, 1.2, 0))
		await _shot("35_regard_%d" % i)
		rp.erase("saved_by_player")
		rp.erase("vendetta")
	# --- 8) tanışma
	var cs2 = _cast().filter(func(n): return not n.has_meta("friend_id"))
	if not cs2.is_empty():
		var n = cs2[0]
		var p = WorldPeople.get_p(String(n.get_meta("world_person")))
		print("WD talk opts=", Friends.options_for(n).map(func(o): return o["label"]), " lines=", n.lines_override)
		WorldDay.meet(n)
		Hud.close_dialog()
		var fid = WorldDay.friend_of(String(p["id"]))
		var f: Dictionary = Friends.all().get(fid, {})
		print("WD met fid=", fid, " name=", f.get("name"), " clan=", f.get("clan"), " rank=", f.get("rank"), " wid=", f.get("wid"), " fam=", f.get("family"), " site=", f.get("site", "-"), " opts=", Friends.options_for(n).size())
		WorldPeople._die(p, "Test ölümü")
		print("WD friend after death status=", Friends.all()[fid].get("status"))
	# --- 9) dilim değişimi: gece
	var before = _cast().size()
	main.world.env.time_of_day = 0.92
	await get_tree().create_timer(4.0).timeout
	var cs3 = _cast()
	print("WD night: staged ", before, "->", cs3.size(), " invalid_left=", cs3.filter(func(n): return not WorldDay.still(n) and not n.going_home and not n.fading).size())
	# --- 10) yolda karşılaşma
	main.world.env.time_of_day = 0.5
	var run2 = WorldDay.dispatch(vid, true)
	if not run2.is_empty() and not gs.is_empty():
		var out = (gate - c0).normalized()
		_tp(pl, gate + out * 420.0)
		await get_tree().create_timer(2.5).timeout
		var nodes = WorldDay.road_meet(run2)
		print("WD road nodes=", nodes.size(), " village_at_player=", WorldDay.village_of(pl.global_position))
		if not nodes.is_empty():
			var p0: Vector3 = nodes[0].global_position
			await get_tree().create_timer(5.0).timeout
			if is_instance_valid(nodes[0]):
				print("WD   road moved=", snappedf(nodes[0].global_position.distance_to(p0), 0.1), " y_err=", snappedf(nodes[0].global_position.y - Game.ground_height(nodes[0].global_position.x, nodes[0].global_position.z), 0.01))
				var c = nodes[0].global_position
				var fd = Vector3(-sin(nodes[0].facing), 0, -cos(nodes[0].facing))
				_camw(c + fd * 5.5 + fd.cross(Vector3.UP) * 2.0 + Vector3.UP * 1.7, c + Vector3.UP * 1.0)
				await _shot("40_road")
	print("WD done")
	get_tree().quit()
