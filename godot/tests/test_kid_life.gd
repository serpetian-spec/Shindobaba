extends Node
## Çocuk büyütme: doğum sahnesi, bebek (beşik, kucağa alma), çocuk dersleri (shuriken / taijutsu / yaprak), oyun, okul ziyareti, mezuniyet kalıtımı.
## KL="birth,baby,school,shuriken,taijutsu,leaf,lift,grad"  HV=köy
var main: Node
var cam: Camera3D


func _camw(p: Vector3, t: Vector3) -> void:
	if cam == null or not is_instance_valid(cam):
		cam = Camera3D.new()
		main.add_child(cam)
		cam.fov = 60.0
	cam.global_position = p
	cam.look_at(t)
	cam.current = true


func _cam(x: float, y: float, d: float, tx: float, ty: float, td: float) -> void:
	var I = Interiors.inst
	_camw(I.L(x, y, d), I.L(tx, ty, td))


func _shot(nm: String) -> void:
	await get_tree().create_timer(0.1).timeout
	await main.shot("kl_" + nm)


func _idle(o, sec: float) -> void:
	var t := 0.0
	while o.busy and t < sec:
		t += 0.25
		await get_tree().create_timer(0.25).timeout


## Sahne sürerken sırayla verilen kameralardan çek (world: dünya koordinatı [pos, hedef])
func _film(o, nm: String, cams: Array, step: float, max_n: int, world := false) -> void:
	var i := 0
	await get_tree().create_timer(1.2).timeout
	while o.busy and i < max_n:
		var c = cams[i % cams.size()]
		if world:
			_camw(c[0], c[1])
		else:
			_cam(c[0], c[1], c[2], c[3], c[4], c[5])
		await _shot("%s_%02d" % [nm, i])
		i += 1
		await get_tree().create_timer(step).timeout
	print("KID film ", nm, " shots=", i, " busy=", o.busy)


func _ready() -> void:
	await get_tree().process_frame
	var parts = (OS.get_environment("KL") if OS.get_environment("KL") != "" else "baby,shuriken,taijutsu,leaf,lift,grad").split(",")
	var vid = OS.get_environment("HV") if OS.get_environment("HV") != "" else "konoha"
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": vid, "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	var pr = Game.profile
	pr["age"] = "adult"
	pl.model.apply_age("adult")
	var lk = ClanWorld.clan_look("hyuga", "genin", Progress.home(), true, "adult")
	var id = Friends._make_friend("Hana", "hyuga", lk, 90, "Eşin")
	var f: Dictionary = Friends.all()[id]
	f["romance"] = "eş"
	f["love"] = 60   # sarılma sahnesi araya girmesin
	f["job"] = "evde"
	f["job_until"] = Time.get_unix_time_from_system() + 99999.0
	pr["spouse"] = id
	var now = Time.get_unix_time_from_system()
	var kids = []
	if "baby" in parts:
		kids.append({"name": "Hyūga Mio", "gender": "f", "clans": ["hyuga"], "born": now})
	var school = "school" in parts
	kids.append({"name": "Hyūga Ren", "gender": "m", "clans": ["hyuga"], "born": now - (4000.0 if school else 2000.0)})
	pr["children"] = kids
	for k in kids:
		KidLife.ensure(k)
		k["clans"] = ["hyuga"]
		print("KID ", k["name"], " stage=", KidLife.stage(k), " el=", k["element"], " text: ", KidLife.stage_text(k))
	var kid: Dictionary = kids[-1]
	if school:
		main.world.env.time_of_day = 0.45
		var ac = Exams.find_point(["academy"])
		print("KID school ac=", ac, " at_school=", KidLife.at_school(kid), " note=", KidLife.note_text())
		pl.respawn(Missions.open_ground(ac + Vector3(9, 0, 9), 20.0) + Vector3(0, 0.5, 0))
		await get_tree().create_timer(1.5).timeout
		SchoolVisit.tick()
		await get_tree().create_timer(2.0).timeout
		var sv = SchoolVisit.cur
		print("KID school cur=", sv, " nodes=", sv.nodes.size() if sv else 0, " c=", sv.c if sv else null)
		if sv and not sv.nodes.is_empty():
			var kn0 = sv.nodes[0]
			var wide = [sv.c + Vector3(-1.0, 1.9, 5.0), sv.c + Vector3(0.6, 0.9, 0.0)]
			pl.global_position = sv._gy(sv.c + Vector3(-5.0, 0, 3.0))
			await get_tree().create_timer(5.0).timeout
			_camw(wide[0], wide[1])
			await _shot("sc_ambient")
			print("KID school opts=", SchoolVisit.opts(kn0).map(func(o): return o["label"]), " friends opts=", Friends.options_for(kn0).size())
			sv._watch(kn0, kid)
			await _film(sv, "scw", [wide, [sv.post + Vector3(-1.2, 1.3, 1.6), sv.post + Vector3(0, 1.0, 0)]], 1.8, 8, true)
			print("KID watch tr=", kid.get("tr"), " stuck=", sv.stuck.size())
			await get_tree().create_timer(0.6).timeout
			sv._bento(kn0, kid)
			var sp0 = sv.c + Vector3(-2.6, 0, 2.4)
			await _film(sv, "scb", [[sp0 + Vector3(0.2, 1.1, 2.6), sp0 + Vector3(0, 0.5, 0)], [sp0 + Vector3(1.6, 0.9, 1.2), sp0 + Vector3(-0.5, 0.6, 0)]], 2.2, 8, true)
			print("KID bento tr=", kid.get("tr"), " locked=", pl.input_locked, " hold=", pl.scene_hold)
	if "birth" in parts:
		pr["baby_due"] = now - 1.0
		Friends._baby_tick()
		print("KID birth_wait=", pr.get("birth_wait"), " wp=", pr.get("waypoint"), " spouse_home=", HomeLife.spouse_home())
	main.world.env.time_of_day = 0.8
	var door = HomeLife.door_pos()
	print("KID door=", door, " home=", Progress.home())
	pl.respawn(door + Vector3(0, 0.3, 0))
	await get_tree().create_timer(0.8).timeout
	Interiors.inst.enter(Interact.nearest(pl.global_position))
	await get_tree().create_timer(1.3).timeout
	var hl = HomeLife.cur
	var W = hl.W
	var D = hl.D
	var lc = hl.cradle_pos - Interiors.inst.origin
	var cx = lc.x
	var cd = -lc.z
	var tx = (hl.target_pos - Interiors.inst.origin).x
	var fx = W * 0.5 - 2.35
	print("KID home W=", W, " D=", D, " baby=", is_instance_valid(hl.baby), " kids=", hl.kids.size(), " routine=", hl.routine, " children=", pr["children"].size())
	if "birth" in parts:
		await _film(hl, "bi", [[fx - 3.0, 1.6, 1.4, fx - 0.4, 0.7, 4.0], [fx - 2.4, 1.2, 5.6, fx - 0.2, 0.6, 4.2], [fx + 0.3, 1.5, 1.2, fx - 1.2, 1.0, 2.6]], 2.2, 16)
		_cam(fx - 2.2, 1.6, 1.2, fx, 0.4, 3.2)
		await _shot("bi_rest")
		print("KID birth done children=", pr["children"].size(), " met=", pr["children"][-1].get("met"), " routine=", hl.routine, " mw=", is_instance_valid(hl.mw), " opts=", HomeLife.spouse_opts(id).map(func(o): return o["label"]))
	if "baby" in parts:
		var t := 0.0
		while not is_instance_valid(hl.baby_held) and t < 30.0:
			t += 0.25
			await get_tree().create_timer(0.25).timeout
		await get_tree().create_timer(3.0).timeout
		_cam(cx + 1.1, 1.5, cd + 0.1, cx - 0.7, 1.1, cd)
		await _shot("baby_front")
		await _idle(hl, 20.0)
	await _idle(hl, 25.0)
	while hl.greet_n > 0:
		await get_tree().create_timer(0.25).timeout
	hl._kids_idle(0.0)
	var kn = null
	for k in hl.kids:
		if String(k.display_override) == String(kid["name"]):
			kn = k
	print("KID node=", kn, " opts=", HomeLife.kid_opts(kn).map(func(o): return o["label"]) if kn else [])
	if kn == null:
		get_tree().quit()
		return
	await get_tree().create_timer(1.2).timeout
	var kp = kn.global_position - Interiors.inst.origin
	kn.set_physics_process(false)
	var ctr = Interiors.inst.L(0, 0, D * 0.5)
	hl._look_at(kn, ctr)
	var kf = (ctr - kn.global_position).normalized()
	await get_tree().create_timer(0.3).timeout
	_camw(kn.global_position + kf * 0.8 + Vector3.UP * 0.95, kn.global_position + Vector3.UP * 0.9)
	await _shot("kid_face")
	kn.set_physics_process(true)
	if "shuriken" in parts:
		hl._kid_shuriken(kn, kid)
		await _film(hl, "sh", [[tx + 2.7, 1.7, 1.3, tx + 0.2, 1.0, 4.6], [tx - 1.5, 1.2, 3.9, tx + 0.35, 0.85, 2.55], [tx + 1.1, 1.4, D - 2.3, tx, 1.15, D]], 2.3, 14)
		print("KID shuriken tr=", kid.get("tr"), " locked=", pl.input_locked, " hold=", pl.scene_hold)
	if "taijutsu" in parts:
		kid["last"] = {}
		await get_tree().create_timer(0.8).timeout
		hl._kid_taijutsu(kn, kid)
		await _film(hl, "tj", [[0.1, 1.2, 0.8, 0.1, 0.85, 2.6], [1.6, 1.3, 1.5, 0.0, 0.85, 2.6]], 1.7, 10)
		print("KID taijutsu tr=", kid.get("tr"))
	if "leaf" in parts:
		kid["last"] = {}
		await get_tree().create_timer(0.8).timeout
		hl._kid_leaf(kn, kid)
		await _film(hl, "lf", [[0.05, 1.0, 1.0, 0.05, 0.65, 2.7], [0.25, 0.75, 2.2, -0.42, 0.72, 2.7]], 2.2, 10)
		print("KID leaf tr=", kid.get("tr"))
	if "lift" in parts:
		kid["last"] = {}
		await get_tree().create_timer(0.8).timeout
		hl._kid_lift(kn, kid)
		await _film(hl, "up", [[0.1, 1.4, 0.3, 0.1, 1.25, 2.5]], 1.0, 8)
		print("KID lift tr=", kid.get("tr"))
	if "grad" in parts:
		kid["born"] = now - 6000.0
		print("KID power=", KidLife.power(kid), " stage=", KidLife.stage(kid))
		Friends.inst().graduation()
		for fid in Friends.all():
			if String(Friends.all()[fid]["name"]) == String(kid["name"]):
				var g: Dictionary = Friends.all()[fid]
				print("KID grad friend ", g["name"], " clan=", g["clan"], " el=", g["element"], " lv=", g.get("pupil_lv"), " eye=", g.get("eye"), " child=", g.get("child"))
	get_tree().quit()
