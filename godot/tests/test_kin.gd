extends Node
## Kendi ailen: kurulum, baba dersi, anne bentosu / sarılma (dünyada), bekâr evinde aile sofrası.
## KC=klan (varsayılan uchiha), KV=köy, KP="world,home"
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
	await main.shot("kn_" + nm)


## Dünya sahnesi sürerken iki kişinin yanından çek
func _film_w(nm: String, v: Node3D, step: float, max_n: int) -> void:
	var pl = main.player
	var i := 0
	await get_tree().create_timer(1.0).timeout
	while is_instance_valid(KinScene.cur) and i < max_n:
		var mid = (pl.global_position + v.global_position) * 0.5
		var d = (v.global_position - pl.global_position)
		d.y = 0
		var side = d.normalized().cross(Vector3.UP)
		var sgn = 1.0 if i % 2 == 0 else -1.0
		_camw(mid + side * 2.6 * sgn + Vector3.UP * 1.5 + d.normalized() * 0.4 * sgn, mid + Vector3.UP * 1.05)
		await _shot("%s_%02d" % [nm, i])
		i += 1
		await get_tree().create_timer(step).timeout
	print("KIN film ", nm, " shots=", i)
	var t := 0.0
	while is_instance_valid(KinScene.cur) and t < 25.0:
		t += 0.25
		await get_tree().create_timer(0.25).timeout


func _ready() -> void:
	await get_tree().process_frame
	var clan = OS.get_environment("KC") if OS.get_environment("KC") != "" else "uchiha"
	var vid = OS.get_environment("KV") if OS.get_environment("KV") != "" else "konoha"
	var parts = (OS.get_environment("KP") if OS.get_environment("KP") != "" else "world,home").split(",")
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": clan, "village": vid, "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	var pr = Game.profile
	pr["age"] = "adult"
	pl.model.apply_age("adult")
	Kin.ensure()
	var ids = {}
	for rel in ["baba", "anne", "kardeş"]:
		var id = Kin.id_of(rel)
		ids[rel] = id
		var f: Dictionary = Friends.all().get(id, {})
		print("KIN ", rel, " id=", id, " name=", f.get("name"), " title=", f.get("title"), " clan=", f.get("clan"), " rank=", f.get("rank"), " call=", Kin.call_name(id), " hair=", f.get("look", {}).get("hair"), " eye=", f.get("look", {}).get("eye"))
		f["job"] = "evde"
		f["job_until"] = Time.get_unix_time_from_system() + 99999.0
	print("KIN rows=", Kin.rows().map(func(r): return r[0]), " host=", HomeLife.host_id() == ids["anne"], " learned=", pr.get("learned", []).size(), " level=", pr.get("level"))
	if "world" in parts:
		main.world.env.time_of_day = 0.45
		var base = Missions.open_ground(pl.global_position + Vector3(6, 0, 6), 30.0)
		pl.global_position = base + Vector3(0, 0.3, 0)
		await get_tree().create_timer(1.0).timeout
		var dad = Friends.inst()._spawn_npc(ids["baba"], base + Vector3(3.0, 0, 0.5), false)
		var mom = Friends.inst()._spawn_npc(ids["anne"], base + Vector3(-3.0, 0, 0.5), false)
		var sib = Friends.inst()._spawn_npc(ids["kardeş"], base + Vector3(0.5, 0, 3.5), false)
		await get_tree().create_timer(1.5).timeout
		for pair in [["baba", dad], ["anne", mom], ["kardeş", sib]]:
			print("KIN opts ", pair[0], "=", Kin.opts(ids[pair[0]], pair[1]).map(func(o): return o["label"]), " all=", Friends.options_for(pair[1]).size())
		_camw(base + Vector3(0, 2.2, -6.5), base + Vector3(0, 1.0, 1.0))
		await _shot("family")
		pr["level"] = 40
		var before = pr.get("learned", []).size()
		KinScene.start("lesson", ids["baba"], dad)
		await _film_w("ls", dad, 2.0, 8)
		print("KIN lesson learned ", before, "->", pr.get("learned", []).size(), " locked=", pl.input_locked, " hold=", pl.scene_hold)
		# ikinci ders: öğrenecek teknik kalmadıysa avuç çalışması
		pr["learned"] = pr.get("learned", []) + ClanWorld.clan_jutsu(clan, 99, 40)
		KinScene.start("lesson", ids["baba"], dad)
		await _film_w("pd", dad, 1.6, 6)
		KinScene.start("bento", ids["anne"], mom)
		await _film_w("bt", mom, 1.6, 6)
		print("KIN bento hp=", pl.hp, "/", pl.max_hp)
		KinScene.start("hug", ids["anne"], mom)
		await _film_w("hg", mom, 1.5, 3)
		for n in [dad, mom, sib]:
			if is_instance_valid(n):
				n.queue_free()
	if "home" in parts:
		main.world.env.time_of_day = 0.8
		var door = HomeLife.door_pos()
		print("KIN door=", door, " host_home=", HomeLife.host_home(), " where=", Friends.where(ids["anne"]))
		pl.respawn(door + Vector3(0, 0.3, 0))
		await get_tree().create_timer(0.8).timeout
		Interiors.inst.enter(Interact.nearest(pl.global_position))
		await get_tree().create_timer(2.6).timeout
		var hl = HomeLife.cur
		var I = Interiors.inst
		var tb = hl.D * 0.5 + 0.5
		print("KIN pl=", pl.global_position - I.origin, " W=", hl.W, " D=", hl.D)
		print("KIN home sp=", is_instance_valid(hl.sp), " kin_host=", hl.kin_host, " folk=", hl.folk.size(), " routine=", hl.routine)
		_camw(I.L(2.8, 1.9, 0.8), I.L(-0.4, 0.8, 3.6))
		await _shot("home_greet")
		await get_tree().create_timer(4.0).timeout
		_camw(I.L(-2.2, 1.5, tb - 2.6), I.L(0.0, 0.5, tb))
		await _shot("home_folk")
		var t := 0.0
		while hl.busy and t < 15.0:
			t += 0.25
			await get_tree().create_timer(0.25).timeout
		print("KIN home opts=", HomeLife.spouse_opts(ids["anne"]).map(func(o): return o["label"]))
		hl._meal()
		await get_tree().create_timer(19.0).timeout
		_camw(I.L(-2.4, 1.6, tb - 2.4), I.L(0.0, 0.5, tb))
		await _shot("home_meal_a")
		_camw(I.L(0.0, 2.7, tb + 0.01), I.L(0.0, 0.3, tb))
		await _shot("home_meal_top")
		await get_tree().create_timer(4.0).timeout
		_camw(I.L(2.2, 1.3, tb + 2.2), I.L(0.0, 0.5, tb))
		await _shot("home_meal_b")
		t = 0.0
		while hl.busy and t < 30.0:
			t += 0.25
			await get_tree().create_timer(0.25).timeout
		print("KIN meal done busy=", hl.busy, " locked=", pl.input_locked)
	get_tree().quit()
