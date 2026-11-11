extends Node
## NPC aile hayatı: evlilik, çocuk, köyde aile yürüyüşü, mezuniyet, yas, mezar başı, intikam. WV=köy
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
	await main.shot("wk_" + nm)


func _fam_cam(s, sg := 1.0, d := 4.2) -> void:
	var c = (s.a.global_position + s.b.global_position) * 0.5
	var fd = s._fd(s.a)
	_camw(c + fd * d + fd.cross(Vector3.UP) * 1.4 * sg + Vector3.UP * 1.5, c + Vector3.UP * 0.95)


func _ready() -> void:
	await get_tree().process_frame
	var vid = OS.get_environment("WV") if OS.get_environment("WV") != "" else "konoha"
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": vid, "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	main.world.env.time_of_day = 0.45
	Game.profile["kd_wait"] = 99999.0
	var quick = OS.get_environment("WKQ") != ""
	if OS.get_environment("WKQ") == "1":
		# otomatik akış: köyde kendiliğinden bir aile çıkmalı
		for p in WorldPeople.all().values():
			if not p["female"] and String(p["village"]) == vid and int(p["rank"]) >= 1:
				WorldKin._marry(p)
		WorldKin._walk_t = 0.5
		await get_tree().create_timer(9.0).timeout
		var w = WorldKin.walk
		print("WK auto walk=", is_instance_valid(w), " dist=", snappedf(w.a.global_position.distance_to(pl.global_position), 0.1) if is_instance_valid(w) else -1.0, " moved=", w.a.model.current if is_instance_valid(w) else "")
		if is_instance_valid(w):
			var c9 = w.a.global_position
			_camw(c9 + Vector3(3.0, 1.6, 4.5), c9 + Vector3.UP * 0.9)
			await _shot("50_auto")
			w.leave()
	WorldKin.auto = false
	# --- veri: 300 dünya turu (7.5 saat) hızlı sar, sonra say
	seed(11)
	var wp: Node = null
	for n in get_tree().root.find_children("*", "", true, false):
		if n.has_method("world_tick") and n.has_method("populate"):
			wp = n
			break
	print("WK wp=", wp)
	for i in (0 if quick else 300):
		wp.world_tick()
		WorldKin.world_tick(WorldPeople.TICK)
	var al = WorldPeople.all().values()
	var live = al.filter(func(p): return WorldPeople.alive(p))
	print("WK sim people=", al.size(), " alive=", live.size(), " rogue=", live.filter(func(p): return WorldPeople.is_rogue(p)).size(), " married=", live.filter(func(p): return String(p.get("spouse", "")) != "").size(),
		" kids=", WorldKin.D()["kids"].size(), " grown=", al.filter(func(p): return p.has("parents")).size(), " grief=", live.filter(func(p): return p.get("grief", false)).size(), " avengers=", WorldKin.D()["avengers"])
	for v in ["konoha", "suna", "kiri", "kumo", "iwa"]:
		print("WK   ", v, " n=", live.filter(func(p): return String(p["village"]) == v and not WorldPeople.is_rogue(p)).size(), " couples=", live.filter(func(p): return String(p["village"]) == v and not p["female"] and String(p.get("spouse", "")) != "").size())
	for p in al.filter(func(p): return p.has("parents")).slice(0, 3):
		print("WK grown ", p["name"], " clan=", p["clan"], " lv=", p["level"], " rank=", p["rank"], " par=", p["parents"].map(func(i): return WorldPeople.get_p(i).get("name")), " log=", p["log"])
	# --- köyde aile
	var cp = WorldKin.couple_in(vid)
	if cp.is_empty():
		var men = live.filter(func(p): return String(p["village"]) == vid and not p["female"] and not WorldPeople.is_rogue(p) and int(p["rank"]) >= 1)
		WorldKin._marry(men[0])
		cp = WorldKin.couple_in(vid)
	var fa: Dictionary = cp[0]
	var mo: Dictionary = cp[1]
	if WorldKin.kids_of(fa).is_empty():
		WorldKin._birth(fa, mo)
	for k in WorldKin.kids_of(fa):
		k["age"] = maxf(float(k["age"]), 2000.0)
	print("WK couple ", fa["name"], " + ", mo["name"], " kids=", WorldKin.kids_of(fa).map(func(k): return [k["name"], k["clan"], int(k["age"])]), " lines=", WorldKin.lines_of(fa))
	var base = Missions.open_ground(pl.global_position + Vector3(8, 0, 8), 30.0)
	pl.global_position = base + Vector3(-9, 0.3, 0)
	await get_tree().create_timer(0.6).timeout
	var s = WorldKin.start_walk(fa, mo, vid, base)
	await get_tree().create_timer(1.2).timeout
	print("WK walk kid=", is_instance_valid(s.kid), " a=", s.a.display, " b=", s.b.display)
	_fam_cam(s)
	await _shot("00_family")
	var c0 = (s.a.global_position + s.b.global_position) * 0.5
	_camw(c0 + s._fd(s.a) * 1.9 + Vector3.UP * 1.45, c0 + Vector3.UP * 1.35)
	await _shot("01_faces")
	# yürüyüş
	var tgt = Missions.open_ground(base + Vector3(10, 0, 4), 6.0)
	s._stroll(tgt)
	for i in 3:
		await get_tree().create_timer(1.6).timeout
		var c = s.a.global_position
		_camw(c + Vector3(3.0, 1.6, 4.5), c + Vector3.UP * 0.9)
		await _shot("1%d_stroll" % i)
	await get_tree().create_timer(5.0).timeout
	print("WK stroll dist=", snappedf(s.a.global_position.distance_to(tgt), 0.1), " ab=", snappedf(s.a.global_position.distance_to(s.b.global_position), 0.01))
	for m in ([2] if quick else [0, 1, 2, 3]):
		WorldKin.force_moment = m
		s._moment()
		if quick:
			var tw := 0.0
			while not (s.st.has(s.a) and float(s.st[s.a]["t"]) > 0.9) and tw < 12.0:
				tw += 0.1
				await get_tree().create_timer(0.1).timeout
			var mid = (s.kid.global_position + s.a.global_position) * 0.5
			var away = (s.a.global_position - s.b.global_position).normalized()
			_camw(mid + away * 2.6 + Vector3.UP * 1.25, mid + Vector3.UP * 1.0)
			await _shot("60_pat")
			_camw(mid + away * 1.5 + Vector3.UP * 1.9 + s._fd(s.a) * 1.4, mid + Vector3.UP * 1.0)
			await _shot("61_pat")
			get_tree().quit()
			return
		for i in 3:
			await get_tree().create_timer(1.5 if m != 2 else 2.2).timeout
			_fam_cam(s, 1.0 if i % 2 == 0 else -1.0, 3.6)
			if m == 2 and is_instance_valid(s.kid):
				var kp = s.kid.global_position
				_camw(kp - s.b.global_position.direction_to(s.a.global_position).cross(Vector3.UP) * (2.6 if i != 1 else -2.6) + Vector3.UP * 1.3, (kp + s.a.global_position) * 0.5 + Vector3.UP * 1.0)
			await _shot("2%d_moment%d" % [m, i])
		await get_tree().create_timer(3.0).timeout
	WorldKin.force_moment = -1
	if quick:
		get_tree().quit()
		return
	# --- mezuniyet
	var k0: Dictionary = WorldKin.kids_of(fa)[0]
	WorldKin.D()["kids"].erase(k0["id"])
	WorldKin._graduate(k0)
	var ch = WorldPeople.get_p(String(fa["children"][-1]))
	print("WK graduate ", ch["name"], " clan=", ch["clan"], " eye=", ch["eye"], " jutsu=", ch["jutsu"].size(), " look hair=", ch["look"].get("hair"), "/", fa["look"].get("hair"), "/", mo["look"].get("hair"), " fa log=", fa["log"][-1])
	s.leave()
	# --- ölüm + yas + intikam
	fa["slain_by_player"] = true
	WorldPeople._die(fa, "Test ile savaşırken öldü")
	print("WK death avengers=", WorldKin.D()["avengers"], " mo grief=", mo.get("grief"), " widow=", mo.get("widow"), " mo log=", mo["log"][-1], " ch log=", ch["log"][-1], " ch vendetta=", ch.get("vendetta"), ch.get("vendetta_rel"))
	# mezar başı
	var gy: Node3D = null
	for n in get_tree().root.find_children("*", "Graveyard", true, false):
		if n.vid == vid:
			gy = n
	print("WK graveyard=", gy != null)
	if gy != null:
		WorldKin.mourn_at(vid, gy)
		await get_tree().create_timer(1.5).timeout
		if is_instance_valid(WorldKin.mourner):
			var mn = WorldKin.mourner.a
			print("WK mourner ", mn.display, " lines=", mn.lines_override)
			var mp = mn.global_position
			_camw(mp + Vector3(2.6, 1.3, 2.4), mp + Vector3(0, 0.7, -0.5))
			await _shot("30_mourn")
			_camw(mp + Vector3(-2.2, 1.0, -1.6), mp + Vector3(0, 0.6, 0))
			await _shot("31_mourn_front")
	# intikamcı
	pl.global_position = base + Vector3(0, 0.3, 0)
	await get_tree().create_timer(0.5).timeout
	var q = WorldPeople.get_p(String(WorldKin.D()["avengers"][0]))
	var e = WorldKin.spawn_avenger(q)
	await get_tree().create_timer(0.8).timeout
	print("WK avenger ", e.arch.get("name"), " team=", e.team, " hp=", e.max_hp, " dist=", snappedf(e.global_position.distance_to(pl.global_position), 0.1))
	_camw(e.global_position + (pl.global_position - e.global_position).normalized() * 4.0 + Vector3.UP * 1.5, e.global_position + Vector3.UP * 1.2)
	await _shot("40_avenger")
	get_tree().quit()
