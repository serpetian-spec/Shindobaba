extends Node
## Büyük olaylarda gerçek ninjalar: Chūnin Sınavı sahası + sonuç, Kage halefi, baskın (akıncı / savunan)
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


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "eye": Color(0.2, 0.4, 0.9), "skin": Color(0.96, 0.8, 0.66)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	await get_tree().create_timer(3.0).timeout
	WorldDay.bond_pass()
	# --- 1) sınav sahası
	var wt = WorldDay.exam_teams()
	print("WE exam_teams=", wt.size())
	for t in wt.slice(0, 3):
		print("WE   team ", t.map(func(p): return "%s/%s lv%d hoca=%s" % [p["name"], p["village"], int(p["level"]), String(WorldPeople.get_p(String(p.get("sensei", ""))).get("name", "-"))]))
	ChuninExam.host = "konoha"
	ChuninExam.st = {}
	var field: Array = ChuninExam._field()
	var wc = []
	for t in field:
		for r in t:
			if r.has("wid"):
				wc.append(r)
	print("WE field teams=", field.size(), " world_cands=", wc.size())
	for r in wc.slice(0, 4):
		print("WE   cand ", r["name"], " | ", r["style"], " lv", r["lv"], " j=", r["j"])
	# sahaya çıkış + görüntü
	if not wc.is_empty():
		var at = pl.global_position + Vector3(0, 0, -6)
		for i in mini(3, wc.size()):
			var e = ChuninExam._rival_enemy(wc[i], 1.0, i)
			e.global_position = at + Vector3(i * 1.6 - 1.6, 0.3, 0)
			e.set_physics_process(false)
			e.set_process(false)
		await get_tree().create_timer(1.0).timeout
		_camw(at + Vector3(0, 1.5, 5.0), at + Vector3(0, 1.0, 0))
		await get_tree().create_timer(0.3).timeout
		await main.shot("we_exam")
		Exams._clear_nodes()
		# sonuç: ilk üçü finalist
		ChuninExam.st["finalists"] = wc.slice(0, 3)
		WorldDay.exam_beaten(String(wc[3]["wid"]) if wc.size() > 3 else "")
		ChuninExam._field_after()
		for r in wc.slice(0, 5):
			var p = WorldPeople.get_p(String(r["wid"]))
			print("WE   after ", p["name"], " rank=", p["rank"], " | ", (p["log"] as Array).back())
	# --- 2) Kage halefi
	for vid in ["suna", "kiri"]:
		var c = WorldDay.kage_candidate(vid)
		Kage.succeed(vid)
		var r = Kage.reign(vid)
		print("WE kage ", vid, " cand=", c.get("name", "-"), " lv", c.get("level", 0), " dream=", WorldDay.dream(c) if not c.is_empty() else "", " -> ", Kage.kage_name(vid), " wid=", r.get("wid", ""), " clan=", r.get("clan", ""), " free=", WorldDay._free(c) if not c.is_empty() else "")
	var old = WorldPeople.get_p(String(Kage.reign("suna").get("wid", "")))
	Kage.succeed("suna", "bir savaşta şehit düştü")
	print("WE kage2 suna old=", old.get("name", "-"), " alive=", WorldPeople.alive(old) if not old.is_empty() else "", " log=", (old.get("log", ["-"]) as Array).back(), " -> ", Kage.kage_name("suna"))
	# --- 3) baskın
	await get_tree().create_timer(0.5).timeout
	Kage.start_raid("kumo")
	await get_tree().create_timer(2.0).timeout
	var rn: Array = Kage.raid["nodes"]
	var ra: Array = Kage.raid["allies"]
	var rw = rn.filter(func(e): return is_instance_valid(e) and e.arch.has("world_person"))
	var aw = ra.filter(func(e): return is_instance_valid(e) and e.arch.has("world_person"))
	print("WE raid foes=", rn.size(), " real=", rw.size(), " allies=", ra.size(), " real=", aw.size())
	for e in rw.slice(0, 3) + aw.slice(0, 2):
		print("WE   ", e.team, " ", e.display_name, " lv", e.arch.get("level"), " hp=", int(e.max_hp), " j=", e.arch.get("jutsu", []))
	var at2: Vector3 = Kage.raid["at"]
	_camw(at2 + Vector3(0, 9, 26), at2 + Vector3(0, 1, 0))
	await get_tree().create_timer(4.0).timeout
	await main.shot("we_raid")
	if not rw.is_empty():
		var v = rw[0]
		var wid = String(v.arch["world_person"])
		v.die({"attacker": pl})
		await get_tree().create_timer(0.5).timeout
		var p = WorldPeople.get_p(wid)
		print("WE raid kill ", p["name"], " alive=", WorldPeople.alive(p), " | ", (p["log"] as Array).back())
	await get_tree().create_timer(6.0).timeout
	print("WE raid after 12s foes_alive=", rn.filter(func(e): return is_instance_valid(e) and not e.is_dead()).size(), " allies_alive=", ra.filter(func(e): return is_instance_valid(e) and not e.is_dead()).size())
	print("WE done")
	get_tree().quit()
