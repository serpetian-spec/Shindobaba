extends Node
## Aile dramı: KD=safe|hurt|late (kamp sonucu), KS="news,camp,ward,grave" adımları, KV=köy, KC=klan, KW=kim (kardeş/anne/baba)
var main: Node
var cam: Camera3D


func _camw(p: Vector3, t: Vector3) -> void:
	if cam == null or not is_instance_valid(cam):
		cam = Camera3D.new()
		main.add_child(cam)
		cam.fov = 55.0
	cam.global_position = p
	cam.look_at(t)
	cam.current = true


func _shot(nm: String) -> void:
	await get_tree().create_timer(0.1).timeout
	await main.shot("kd_" + nm)


## Sahne sürerken oyuncu + odak noktasını iki yandan çek
func _film(nm: String, step: float, max_n: int, dist := 3.0, focus = null) -> void:
	var pl = main.player
	var i := 0
	while is_instance_valid(KinDrama.cur) and i < max_n:
		var fo: Vector3 = pl.global_position
		if focus is Node3D and is_instance_valid(focus):
			fo = focus.global_position
		elif is_instance_valid(KinDrama.cur.v):
			fo = KinDrama.cur.v.global_position
		var mid = (pl.global_position + fo) * 0.5
		var dv = fo - pl.global_position
		dv.y = 0
		if dv.length() < 0.2:
			dv = pl.face_dir()
		var side = dv.normalized().cross(Vector3.UP)
		var sgn = 1.0 if i % 2 == 0 else -1.0
		var dd = maxf(dist, dv.length() * 0.75)
		_camw(mid + side * dd * sgn + Vector3.UP * 1.35 + dv.normalized() * 0.5 * sgn, mid + Vector3.UP * 0.8)
		await _shot("%s_%02d" % [nm, i])
		i += 1
		await get_tree().create_timer(step).timeout
	print("KD film ", nm, " shots=", i)
	var t := 0.0
	while is_instance_valid(KinDrama.cur) and t < 40.0:
		t += 0.25
		await get_tree().create_timer(0.25).timeout


func _ready() -> void:
	await get_tree().process_frame
	var mode = OS.get_environment("KD") if OS.get_environment("KD") != "" else "safe"
	var steps = (OS.get_environment("KS") if OS.get_environment("KS") != "" else "news,camp").split(",")
	var clan = OS.get_environment("KC") if OS.get_environment("KC") != "" else "uchiha"
	var vid = OS.get_environment("KV") if OS.get_environment("KV") != "" else "konoha"
	var who = OS.get_environment("KW") if OS.get_environment("KW") != "" else "kardeş"
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": clan, "village": vid, "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	var pr = Game.profile
	pr["age"] = "adult"
	pl.model.apply_age("adult")
	main.world.env.time_of_day = 0.45
	Kin.ensure()
	pr["kd_wait"] = 99999.0
	var id = Kin.id_of(who)
	var f: Dictionary = Friends.all()[id]
	print("KD victims=", KinDrama.victims().size(), " can=", KinDrama.can_start(), " victim=", f["name"], " rel=", KinDrama.rel_word(id), " me=", KinDrama.me_word(id))
	if "news" in steps or "camp" in steps:
		var base = Missions.open_ground(pl.global_position + Vector3(6, 0, 6), 30.0)
		pl.global_position = base + Vector3(0, 0.3, 0)
		await get_tree().create_timer(0.8).timeout
		print("KD begin=", KinDrama.begin(id), " d=", KinDrama.d(), " where=", Friends.where_text(id), " avail=", Friends.available(f))
		var e = KinDrama.entry()
		print("KD foe=", e.get("alias"), " ", e.get("name"), " rank=", e.get("rank"), " lv=", e.get("level"), " crimes=", e.get("crimes"), " hide=", e.get("hide"))
		await get_tree().create_timer(1.0).timeout
		await _film("nw", 2.2, 9 if "news" in steps else 0)
		print("KD news done wp=", pr.get("waypoint"), " locked=", pl.input_locked, " hold=", pl.get("scene_hold"), " stage=", KinDrama.d().get("stage"))
	if "camp" in steps:
		var e2 = KinDrama.entry()
		var eid = int(e2["id"])
		KinDrama.d()["el"] = {"safe": 100.0, "hurt": 800.0, "late": 1300.0}[mode]
		var hp = Game.from_map(Vector2(e2["hide"][0], e2["hide"][1]))
		pl.respawn(Missions.open_ground(hp + Vector3(55, 0, 0), 20.0) + Vector3(0, 0.4, 0))
		var t := 0.0
		while not is_instance_valid(KinDrama.cur) and t < 12.0:
			t += 0.25
			await get_tree().create_timer(0.25).timeout
		await get_tree().create_timer(0.8).timeout
		var kd = KinDrama.cur
		print("KD camp cur=", is_instance_valid(kd), " t=", t, " spawned=", Missions._bb_spawned.has(eid))
		if not is_instance_valid(kd) or not is_instance_valid(kd.v):
			get_tree().quit()
			return
		var foe = kd.foe
		var cp: Vector3 = kd.v.global_position
		var to_pl = (pl.global_position - cp)
		to_pl.y = 0
		to_pl = to_pl.normalized()
		print("KD foe hp=", foe.hp, " name=", foe.display_name, " dist=", pl.global_position.distance_to(cp))
		# yaklaş
		pl.global_position = cp + to_pl * 14.0 + Vector3(0, 0.4, 0)
		pl.velocity = Vector3.ZERO
		await get_tree().create_timer(1.6).timeout
		var side = to_pl.cross(Vector3.UP)
		_camw(cp + to_pl * 4.2 + side * 2.2 + Vector3.UP * 1.5, cp + Vector3.UP * 0.7)
		await _shot("cp_front")
		_camw(cp - to_pl * 1.0 + side * 3.2 + Vector3.UP * 1.2, cp + Vector3.UP * 0.6)
		await _shot("cp_side")
		_camw(cp - to_pl * 3.6 - side * 1.0 + Vector3.UP * 1.6, cp + Vector3.UP * 0.6)
		await _shot("cp_back")
		if mode != "late":
			foe.die({"attacker": pl})
			print("KD foe killed status=", e2.get("status"))
			await get_tree().create_timer(1.0).timeout
		await _film("rs" if mode != "late" else "lt", 1.7, 16, 2.6)
		await get_tree().create_timer(1.5).timeout
		print("KD after: status=", f.get("status"), " injury=", f.get("injury"), " away>now=", float(f.get("away", 0.0)) > Time.get_unix_time_from_system(), " abducted=", f.get("abducted"), " d=", KinDrama.d(), " killer=", f.get("killer_name"), " locked=", pl.input_locked, " hold=", pl.get("scene_hold"), " where=", Friends.where_text(id))
		print("KD bingo tracked=", e2.get("tracked"), " status=", e2.get("status"), " crimes=", e2.get("crimes"))
	if "ward" in steps:
		if not f.has("injury"):
			Friends.injure(id, "Görevde yaralandı")
			Hud.close_dialog()
		var hosp = Exams.find_point(["hospital"])
		print("KD hosp=", hosp)
		pl.respawn(hosp + Vector3(0, 0.3, 0))
		await get_tree().create_timer(0.8).timeout
		var it = Interact.nearest(pl.global_position)
		print("KD door kind=", it.get("kind"), " vid=", it.get("vid"))
		Interiors.inst.enter(it)
		await get_tree().create_timer(3.0).timeout
		var I = Interiors.inst
		var pt = null
		for n in I.npcs:
			if is_instance_valid(n) and n.get_meta("bedside", false):
				pt = n
		print("KD ward patient=", pt, " opts=", Friends.options_for(pt).map(func(o): return o["label"]) if pt else [])
		_camw(I.L(1.2, 1.9, 4.9), I.L(3.6, 0.7, 6.6))
		await _shot("wd_bed")
		_camw(I.L(3.6, 2.6, 6.59), I.L(3.6, 0.6, 6.6))
		await _shot("wd_top")
		if pt:
			var w = pt.get_meta("ward")
			w.bedside()
			for i in 5:
				await get_tree().create_timer(2.3).timeout
				if i % 2 == 0:
					_camw(I.L(1.6, 1.4, 5.2), I.L(3.7, 0.7, 6.3))
				else:
					_camw(I.L(5.6, 1.3, 5.0), I.L(3.7, 0.7, 6.2))
				await _shot("wd_side_%d" % i)
			var t2 := 0.0
			while w.ward_busy and t2 < 20.0:
				t2 += 0.25
				await get_tree().create_timer(0.25).timeout
			print("KD ward done opts=", Friends.options_for(pt).map(func(o): return o["label"]), " locked=", pl.input_locked)
	if "grave" in steps:
		if String(f.get("status", "")) != "öldü":
			f["status"] = "öldü"
			f["killer"] = 1
		f["avenged"] = true
		f["buried"] = true
		var gp = Graveyard.pos_of(Progress.home())
		print("KD grave pos=", gp, " opts=", KinDrama.grave_opts(Progress.home()).map(func(o): return o["label"]))
		pl.respawn(Missions.open_ground(gp + Vector3(3, 0, 3), 10.0) + Vector3(0, 0.3, 0))
		await get_tree().create_timer(1.5).timeout
		KinDrama.start_grave(id)
		var fd = pl.face_dir()
		var sd = fd.cross(Vector3.UP)
		for i in 7:
			await get_tree().create_timer(1.9).timeout
			var sg = 1.0 if i % 2 == 0 else -1.0
			_camw(pl.global_position + fd * 1.6 + sd * 1.9 * sg + Vector3.UP * 1.0, pl.global_position + fd * 0.3 + Vector3.UP * 0.5)
			await _shot("gr_%d" % i)
		print("KD grave told=", f.get("avenged_told"), " cur=", is_instance_valid(KinDrama.cur))
	get_tree().quit()
