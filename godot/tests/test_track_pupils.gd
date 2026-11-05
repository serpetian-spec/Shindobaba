extends Node
## 1) Harita işaretçisi: dost işaretlenince görev kaybolmaz — L (cycle_track) ve menü ◀ ▶ ile aktif hedefler arasında geçilir
## 2) Öğrenci takımı: Jōnin olunca 3 genin; D/C/B görevinde eşlik; görev/idman/teknik ile gelişim; seviye savaş arketipine yansır

var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _pupil_nodes() -> Array:
	return get_tree().current_scene.find_children("*", "Enemy", true, false).filter(func(e): return is_instance_valid(e) and not e.dead and e.has_meta("friend_id") and String(e.get_meta("friend_id")).begins_with("pu_"))


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "akimichi", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pr = Game.profile
	var pl: Player = main.player
	await _wait(1.5)
	# ---------------- 1) takip
	var dm = {}
	for k in 20:
		for m in Missions.board_missions("konoha", true):
			if String(m.get("rank", "")) == "D":
				dm = m
				break
		if not dm.is_empty():
			break
	Missions.accept(dm)
	await _wait(1.0)
	var mpos: Vector3 = Missions.target_marker
	var mname = Missions.target_name
	var fid = ""
	for id in Friends.all():
		if Friends.where(id) != Vector3.INF:
			fid = id
			break
	if fid != "":
		Friends.show_on_map(fid)
	else:   # yeni oyunda konumu bilinen dost yoksa aynı yolla (waypoint) bir dostu işaretle
		var hp = pl.global_position + Vector3(120, 0, 40)
		pr["waypoint"] = [hp.x, hp.y, hp.z, "Dost: Deneme"]
		pr["track"] = "waypoint"
	await _wait(0.5)
	print("TRACK after friend: track=%s name='%s' (mission was '%s')" % [pr.get("track", ""), Missions.target_name, mname])
	var opts = Missions.track_options()
	print("TRACK options: ", opts.map(func(o): return o[1]))
	var back_ok = false
	for i in opts.size():
		Missions.cycle_track()
		await _wait(0.3)
		if String(pr.get("track", "")) == "":
			back_ok = Missions.target_marker.distance_to(mpos) < 1.0 and Missions.target_name == mname
			break
	print("TRACK back to mission via L: ", back_ok, " name='", Missions.target_name, "'")
	Missions.cycle_track()
	await _wait(0.3)
	print("TRACK next: track=%s name='%s'" % [pr.get("track", ""), Missions.target_name])
	var ms = load("res://scripts/ui/menus.gd")
	ms.ninja_menu(main, "missions")
	await _wait(0.5)
	await main.shot("track_menu")
	main.resume() if Game.paused else Hud.close_dialog()
	Game.ui_open = false
	Missions.abandon()
	pr["active_mission"] = {}
	await _wait(0.5)
	# ---------------- 2) öğrenciler
	pr["mastery"] = {"chakra": 30.0, "dayaniklilik": 15.0, "hiz": 8.0, "kenjutsu": 11.4, "ninjutsu": 35.0, "taijutsu": 60.0}
	Mastery.refresh_level(pr)
	Progress.promote(3)
	await _wait(0.6)
	print("PUPIL dialog: ", Hud.last_dialog.left(120))
	Hud.close_dialog()
	Game.ui_open = false
	var ids = PupilSquad.ids()
	for id in ids:
		var f = Friends.all().get(id, {})
		print("PUPIL %s name=%s lv=%.1f el=%s clan=%s rank=%d" % [id, f.get("name", "?"), f.get("pupil_lv", -1), f.get("element", ""), f.get("clan", ""), f.get("rank", -1)])
	# görev: C rank
	var cm = {}
	for k in 30:
		for m in Missions.board_missions("konoha", true):
			if String(m.get("rank", "")) == "C":
				cm = m
				break
		if not cm.is_empty():
			break
	Missions.accept(cm)
	await _wait(2.0)
	print("TRACK after accept C: track='%s' name='%s'" % [pr.get("track", ""), Missions.target_name])
	var pn = _pupil_nodes()
	print("PUPIL spawned on C mission: ", pn.size(), " levels=", pn.map(func(e): return e.level), " team=", pn.map(func(e): return e.team))
	var c: Vector3 = Missions.target_marker
	pl.respawn(c + Vector3(10, 1, 0))
	await _wait(4.0)
	pn = _pupil_nodes()
	print("PUPIL after teleport: n=%d dists=%s" % [pn.size(), pn.map(func(e): return snappedf(e.global_position.distance_to(pl.global_position), 0.1))])
	await main.shot("pupils_follow")
	var lv0 = float(Friends.all()["pu_0"]["pupil_lv"])
	Missions.complete()
	await _wait(1.5)
	var lv1 = float(Friends.all()["pu_0"]["pupil_lv"])
	print("PUPIL mission growth: %.2f -> %.2f (beklenen +1.2)  missions=%d  nodes_after=%d" % [lv0, lv1, int(pr["pupils"]["missions"]), _pupil_nodes().size()])
	# A görevinde gelmezler
	var am = {}
	pr["rank"] = 3
	for k in 30:
		for m in Missions.board_missions("konoha", true):
			if String(m.get("rank", "")) == "A":
				am = m
				break
		if not am.is_empty():
			break
	if not am.is_empty():
		Missions.accept(am)
		await _wait(1.5)
		print("PUPIL on A mission (0 beklenir): ", _pupil_nodes().size())
		Missions.abandon()
		pr["active_mission"] = {}
		await _wait(1.0)
		print("PUPIL abandoned A: lv=%.2f (değişmemeli)" % float(Friends.all()["pu_0"]["pupil_lv"]))
	# idman
	PupilSquad.on_spar("pu_0", true)
	var f0: Dictionary = Friends.all()["pu_0"]
	var a = Friends.arch(f0)
	print("PUPIL spar: lv=%.2f arch_level=%d hp=%d" % [f0["pupil_lv"], a["level"], a["hp"]])
	# flört: öğrencide yok
	print("PUPIL romance opts (0 beklenir): ", Friends._romance_opts("pu_0").size() + Friends._romance_opts("pu_1").size() + Friends._romance_opts("pu_2").size())
	# teknik öğret: öğrencinin doğasına uygun öğretilebilir bir jutsu bul ve oyuncuya ver
	var el = String(f0["element"])
	var given = ""
	for jid in Data.jutsu:
		var j = Data.jutsu[jid]
		if String(j.get("element", "")) == el and int(j.get("level", 99)) <= int(f0["pupil_lv"]) + 6 and GeninSquad._teachable(jid):
			given = jid
			break
	pr["learned"].append(given)
	var tops = PupilSquad.options("pu_0")
	print("PUPIL options: ", tops.map(func(o): return o["label"]))
	for o in tops:
		if String(o["label"]).begins_with("Sana bir teknik"):
			o["cb"].call()
	await _wait(0.3)
	print("PUPIL teach menu: '%s' opts=%s" % [Hud.last_dialog.left(60), Hud.last_options.map(func(o): return o["label"])])
	for o in Hud.last_options:
		if String(o["label"]).begins_with(String(Data.jutsu[given]["name"])):
			o["cb"].call()
			break
	await _wait(0.3)
	a = Friends.arch(f0)
	print("PUPIL taught=%s arch_jutsu_has=%s" % [f0["taught"], given in a["jutsu"]])
	Hud.close_dialog()
	# takipten çıkar: köyde kal
	for o in PupilSquad.options("pu_0"):
		if String(o["label"]).begins_with("Takım:"):
			o["cb"].call()
	Missions.accept(cm.duplicate(true))
	await _wait(1.5)
	print("PUPIL follow off -> nodes=%d (0 beklenir)" % _pupil_nodes().size())
	# chūnin terfisi
	f0["pupil_lv"] = 21.5
	PupilSquad._grow(f0, 1.0)
	print("PUPIL chunin: rank=%d title=%s" % [f0["rank"], f0["title"]])
	get_tree().quit()
