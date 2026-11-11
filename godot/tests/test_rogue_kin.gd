extends Node
## Kaçak hayatında aile: gece gizli ziyaret, sorgu haberi, para bırakma, "benimle gel". RK=leak|cover, RV=köy
var main: Node
var cam: Camera3D


func _cam(x: float, y: float, d: float, tx: float, ty: float, td: float) -> void:
	var I = Interiors.inst
	if cam == null or not is_instance_valid(cam):
		cam = Camera3D.new()
		main.add_child(cam)
		cam.fov = 60.0
	cam.global_position = I.L(x, y, d)
	cam.look_at(I.L(tx, ty, td))
	cam.current = true


func _shot(nm: String) -> void:
	await get_tree().create_timer(0.1).timeout
	await main.shot("rk_" + nm)


func _film(hl, nm: String, step: float, max_n: int) -> void:
	var pl = main.player
	var I = Interiors.inst
	var i := 0
	await get_tree().create_timer(0.8).timeout
	while hl.busy and i < max_n:
		var a = pl.global_position - I.origin
		var b = (hl.sp.global_position - I.origin) if is_instance_valid(hl.sp) else a
		var mx = (a.x + b.x) * 0.5
		var md = -(a.z + b.z) * 0.5
		var sg = 1.0 if i % 2 == 0 else -1.0
		_cam(clampf(mx + 2.4 * sg, -hl.W * 0.5 + 0.4, hl.W * 0.5 - 0.4), 1.5, maxf(md - 2.2, 0.5), mx, 0.9, md)
		await _shot("%s_%02d" % [nm, i])
		i += 1
		await get_tree().create_timer(step).timeout
	print("RK film ", nm, " shots=", i)
	var t := 0.0
	while hl.busy and t < 40.0:
		t += 0.25
		await get_tree().create_timer(0.25).timeout


func _ready() -> void:
	await get_tree().process_frame
	var mode = OS.get_environment("RK") if OS.get_environment("RK") != "" else "cover"
	var vid = OS.get_environment("RV") if OS.get_environment("RV") != "" else "konoha"
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": vid, "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	var pr = Game.profile
	pr["age"] = "adult"
	pl.model.apply_age("adult")
	pr["kd_wait"] = 99999.0
	pr["ryo"] = 2000
	var lk = ClanWorld.clan_look("", "chunin", Progress.home(), true, "adult")
	var id = Friends._make_friend("Hana", "", lk, 90, "Eşin")
	var f: Dictionary = Friends.all()[id]
	f["romance"] = "eş"
	f["love"] = 90
	pr["spouse"] = id
	# köyden kaç
	Orgs.flags()["rogue"] = true
	Orgs.flags()["rogue_from"] = vid
	print("RK rogue=", Orgs.is_rogue(), " home=", Progress.home(), " avail=", Friends.available(f), " where=", Friends.where_text(id))
	main.world.env.time_of_day = 0.5
	print("RK day: host_home=", HomeLife.host_home())
	main.world.env.time_of_day = 0.85
	print("RK night: host_home=", HomeLife.host_home(), " door=", HomeLife.door_pos())
	# sorgu (sen yokken)
	var s = RogueKin.st()
	if mode == "leak":
		f["bond"] = 20
	seed(7 if mode == "leak" else 3)
	RogueKin.interrogate(id)
	print("RK interrogate st=", s, " hunter_t=", Orgs._hunter_t, "/", Orgs._hunter_next, " log=", f["log"][-1] if not f["log"].is_empty() else "")
	if mode == "leak":
		f["bond"] = 90
	pl.respawn(HomeLife.door_pos() + Vector3(0, 0.3, 0))
	await get_tree().create_timer(0.8).timeout
	Interiors.inst.enter(Interact.nearest(pl.global_position))
	await get_tree().create_timer(1.6).timeout
	var hl = HomeLife.cur
	print("RK home cur=", is_instance_valid(hl), " sp=", is_instance_valid(hl.sp) if hl else false, " busy=", hl.busy if hl else null)
	if not is_instance_valid(hl) or not is_instance_valid(hl.sp):
		get_tree().quit()
		return
	await _film(hl, "ar", 1.8, 12)
	print("RK arrive done st=", RogueKin.st(), " opts=", HomeLife.spouse_opts(id).map(func(o): return o["label"]))
	hl._rogue_gift()
	await _film(hl, "gf", 1.3, 6)
	var tb = hl.D * 0.5 + 0.5
	_cam(-1.6, 1.2, tb - 1.6, -0.3, 0.45, tb)
	await _shot("gf_table")
	print("RK gift ryo=", pr["ryo"], " care=", RogueKin.st()["care"], " bond=", f["bond"])
	hl._rogue_take()
	await _film(hl, "tk", 1.8, 14)
	print("RK take status=", f.get("status"), " rogue=", f.get("rogue"), " where=", Friends.where_text(id), " avail=", Friends.available(f), " pos=", Friends.where(id), " hideout=", Orgs.hideout_spawn(), " locked=", pl.input_locked, " hold=", pl.get("scene_hold"))
	get_tree().quit()
