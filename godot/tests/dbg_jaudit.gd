extends Node
## Jutsu görsel denetimi: her jutsu oyuncudan hedefe atılır, salınımdan 0.6 ve 1.3 sn sonra küçük kare (480x270) kaydedilir.
## JA_RANGE="baş:son" (sıralı jutsu listesinde), JA_ONLY="id1,id2"
var main: Node
var out := "D:/Naruto 3D Game/_tmp/audit"


func _snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	img.resize(480, 270, Image.INTERPOLATE_BILINEAR)
	img.save_png(out.path_join(name + ".png"))


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	DirAccess.make_dir_recursive_absolute(out)
	var pl = main.player
	Game.profile["level"] = 60
	pl.max_chakra = 99999.0
	Hud.show_game_hud(false)
	Combat.quiet = true
	pl.set_process(false)
	var ids = Data.jutsu.keys().filter(func(k): return Data.jutsu[k] is Dictionary and not String(Data.jutsu[k].get("virtual", "")).begins_with("eye:"))
	ids.sort()
	var only = OS.get_environment("JA_ONLY")
	if only != "":
		ids = ids.filter(func(k): return k in only.split(","))
	var rg = OS.get_environment("JA_RANGE")
	if rg != "":
		var ab = rg.split(":")
		ids = ids.slice(int(ab[0]), int(ab[1]))
	var spot = Missions._spot("suna", 600, 900)
	var base = Missions.open_ground(Game.from_map(Vector2(spot[0], spot[1])), 60.0)
	pl.global_position = base + Vector3(0, 1, 0)
	await get_tree().create_timer(4.0).timeout
	var cam = Camera3D.new()
	cam.fov = 55
	main.add_child(cam)
	cam.current = true
	var a = Enemy.archetype("rogue", 0)
	a["hp"] = 1e9
	a["respawn"] = false
	a["jutsu"] = []
	var tgt = Enemy.new()
	tgt.setup(a)
	get_tree().current_scene.add_child(tgt)
	var k = 0
	for id in ids:
		var p = base + Vector3((k % 8) * 110.0, 0, int(k / 8) % 4 * 110.0)
		p.y = Game.ground_height(p.x, p.z)
		k += 1
		pl.global_position = p
		pl.velocity = Vector3.ZERO
		pl.facing = 0.0
		pl.model.rotation.y = 0.0
		var tp = p + Vector3(0, 0, -11.0)
		tp.y = Game.ground_height(tp.x, tp.z)
		tgt.global_position = tp
		tgt.home = tp
		tgt.hp = tgt.max_hp
		tgt.statuses.clear()
		tgt.set_physics_process(false)
		tgt.target = null
		pl.hp = pl.max_hp
		pl.chakra = 99999.0
		var mid = (p + tp) * 0.5 + Vector3.UP * 1.5
		cam.global_position = mid + Vector3(14.0, 5.0, 3.0)
		cam.look_at(mid, Vector3.UP)
		await get_tree().create_timer(0.5).timeout
		await _snap("%s__0" % id)
		Jutsu.execute(pl, id, tgt)
		await get_tree().create_timer(0.6).timeout
		await _snap("%s__a" % id)
		await get_tree().create_timer(0.7).timeout
		await _snap("%s__b" % id)
		await get_tree().create_timer(0.6).timeout
		if pl.has_method("end_flight"):
			pl.end_flight() if pl.get("fly_src") != "" else null
		print("JA ", k, "/", ids.size(), " ", id)
	print("JA done")
	get_tree().quit()
