extends Node
## Tam dönüşümde GERÇEK oyuncu fiziğiyle çimende yürüme (havada süzülme hatası) + Isobu Kabuk Yuvarlanışı topu.
## Kullanım: --test=res://tests/test_giant_walk.gd --shots=<dizin> [--tag=a]

var main: Node
var pl: Player
var tag := "a"


func _ready() -> void:
	await get_tree().process_frame
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12),
		"top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	Game.world.env.weather_t = 9999.0
	Game.world.env.region_weather = "açık"
	pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(4.0).timeout
	for id in ["shukaku", "isobu"]:
		await _giant(id)
	print("GIANT WALK BITTI")
	get_tree().quit()


func _giant(id: String) -> void:
	TailedBeasts.make_jinchuriki(id)
	TailedBeasts.beasts()[id]["trust"] = 100.0
	pl.chakra = pl.max_chakra
	var cl: BeastCloak = pl.combat.modes.cloak
	cl.set_level(6)
	await get_tree().create_timer(1.5).timeout
	var h = cl.rig.height_m
	var cam = Camera3D.new()
	get_tree().current_scene.add_child(cam)
	cam.far = 4000.0
	cam.current = true
	Input.action_press("forward")
	var air_n := 0
	var n := 0
	for i in 3:
		await get_tree().create_timer(0.9).timeout
		for k in 20:
			await get_tree().process_frame
			n += 1
			if cl.rig.airborne:
				air_n += 1
		var b = pl.global_position
		cam.global_position = b + Vector3(h * 1.9, h * 0.35, h * 0.5)
		cam.look_at(b + Vector3.UP * h * 0.35)
		print("YURU %s i=%d grounded=%s on_floor=%s wall=%s airborne=%s air_s=%.2f y-g=%.2f lvl=%d" % [id, i, pl.grounded, pl.is_on_floor(), pl.wall_n, cl.rig.airborne, cl.rig.air_s, b.y - Game.ground_height(b.x, b.z), cl.level])
		await main.shot("gw_%s_%s_yuru%d" % [tag, id, i])
	print("YURU %s havada kare: %d / %d" % [id, air_n, n])
	Input.action_release("forward")
	await get_tree().create_timer(0.8).timeout
	if id == "isobu":
		var b0 = pl.global_position
		BijuuArts.use(pl, "isobu", "shell_roll", {"s": cl._giant_s() if cl.has_method("_giant_s") else 3.0, "aim": b0 + pl.face_dir() * 60.0, "dmg": 10.0})
		for q in 3:
			await get_tree().create_timer(0.25).timeout
			var b = pl.global_position
			cam.global_position = b + Vector3(h * 1.5, h * 0.5, h * (0.9 - q * 0.9))
			cam.look_at(b + Vector3.UP * h * 0.35)
			await main.shot("gw_%s_isobu_top%d" % [tag, q])
		await get_tree().create_timer(1.0).timeout
	cl.set_level(0)
	cam.queue_free()
	await get_tree().create_timer(0.6).timeout
