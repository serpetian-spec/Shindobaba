extends Node
## Miras: mezun çocuğa yol bırakma töreni + kayıt geçişi. LV=köy
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
	await main.shot("lg_" + nm)


func _dump(tag: String) -> void:
	var pr = Game.profile
	var m: Dictionary = pr.get("mastery", {})
	print("LG ", tag, " name=", pr["name"], " gender=", pr["gender"], " clan=", pr["clan"], " el=", pr["elements"], " rank=", pr["rank"], " power=", pr.get("level"), " nin=", snappedf(float(m.get("ninjutsu", 0)), 0.1), " tai=", snappedf(float(m.get("taijutsu", 0)), 0.1), " ryo=", pr["ryo"], " learned=", pr["learned"], " slots=", pr["slots"].filter(func(x): return x != ""))
	var eq = []
	for sl in pr.get("equip", {}):
		var g = Gear.find(pr, pr["equip"][sl])
		eq.append("%s=%s%s" % [sl, g.get("id", "?"), (" lvl%d" % int(g["lvl"])) if g.has("lvl") else ""])
	print("LG ", tag, " equip=", eq, " hp=", Game.player.max_hp, " kin=", Kin.rows().map(func(r): return r[0]), " spouse=", Friends.spouse_id(), " children=", pr.get("children", []).map(func(k): return [k["name"], k.get("sib")]))
	for id in Friends.all():
		var f: Dictionary = Friends.all()[id]
		print("LG ", tag, "   ", id, " ", f["name"], " title=", f.get("title"), " kin=", f.get("kin"), " child=", f.get("child"), " bond=", f["bond"], " rank=", f.get("rank"), " lv=", f.get("pupil_lv"), " eye=", f.get("eye"), " romance=", f.get("romance"))


func _ready() -> void:
	await get_tree().process_frame
	var vid = OS.get_environment("LV") if OS.get_environment("LV") != "" else "konoha"
	main.creator_state = {"slot": 3, "name": "Kenta", "gender": "m", "clan": "uchiha", "village": vid, "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.25, 0.5), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.1, 0.1, 0.1)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	var pr = Game.profile
	main.world.env.time_of_day = 0.45
	pr["rank"] = 3
	pr["mastery"] = {"ninjutsu": 62.0, "taijutsu": 48.0, "chakra": 55.0, "dayaniklilik": 50.0, "hiz": 30.0, "shurikenjutsu": 20.0}
	Mastery.refresh_level(pr)
	pr["ryo"] = 4200
	for j in ["katon_goukakyuu", "katon_housenka", "doton_doryuheki", "suiton_suikoudan"]:
		if Data.jutsu.has(j) and not j in pr["learned"]:
			pr["learned"].append(j)
	pr["elements"] = ["katon", "doton"]
	Progress.on_power_changed()
	Progress.ensure_rank_outfit()
	Gear.apply_look(pr)
	pl.rebuild_model()
	Kin.ensure()
	pr["kd_wait"] = 99999.0
	var lk = ClanWorld.clan_look("hyuga", "chunin", Progress.home(), true, "adult")
	var sid = Friends._make_friend("Hyūga Hana", "hyuga", lk, 90, "Eşin")
	Friends.all()[sid]["romance"] = "eş"
	Friends.all()[sid]["love"] = 90
	pr["spouse"] = sid
	var now = Time.get_unix_time_from_system()
	pr["children"] = [{"name": "Uchiha Ren", "gender": "m", "clans": ["uchiha"], "born": now - 6000.0}, {"name": "Uchiha Mio", "gender": "f", "clans": ["uchiha"], "born": now - 2000.0}]
	for k in pr["children"]:
		KidLife.ensure(k)
	pr["children"][0]["clans"] = ["uchiha"]
	pr["children"][0]["tr"] = {"shuriken": 6.0, "taijutsu": 5.0, "chakra": 4.0}
	Friends.inst().graduation()
	Hud.close_dialog()
	var cid = ""
	for id in Friends.all():
		if Friends.all()[id].get("child", false):
			cid = id
	if cid == "":
		print("LG no child")
		get_tree().quit()
		return
	Friends.all()[cid]["taught"] = ["katon_goukakyuu"]
	var base = Missions.open_ground(pl.global_position + Vector3(6, 0, 6), 30.0)
	pl.global_position = base + Vector3(0, 0.3, 0)
	await get_tree().create_timer(1.0).timeout
	var kid = Friends.inst()._spawn_npc(cid, base + Vector3(2.6, 0, 0.4), false)
	await get_tree().create_timer(1.5).timeout
	_dump("before")
	print("LG opts=", Legacy.opts(cid, kid).map(func(o): return o["label"]), " block=", Legacy.block())
	var mid0 = base + Vector3(1.6, 0, 0.2)
	_camw(mid0 + Vector3(0.3, 1.3, 3.4), mid0 + Vector3.UP * 1.0)
	await _shot("00_before")
	Legacy.start(cid, kid)
	var i := 1
	while is_instance_valid(Legacy.cur) and i < 22:
		await get_tree().create_timer(1.15).timeout
		var fo = pl.global_position
		var sg = 1.0 if i % 2 == 0 else -1.0
		_camw(fo + Vector3(0.9 * sg, 1.25, 2.6), fo + Vector3(0.5 * 0, 1.0, 0))
		await _shot("%02d" % i)
		i += 1
	var t := 0.0
	while is_instance_valid(Legacy.cur) and t < 30.0:
		t += 0.25
		await get_tree().create_timer(0.25).timeout
	_dump("after")
	print("LG locked=", pl.input_locked, " hold=", pl.get("scene_hold"), " ancestors=", pr.get("ancestors"))
	_camw(pl.global_position + pl.face_dir() * 2.2 + Vector3.UP * 1.3, pl.global_position + Vector3.UP * 1.0)
	await _shot("zz_after_face")
	get_tree().quit()
