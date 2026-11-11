extends Node
## Kuyruklu canavar bekleme / ara hareket / yürüyüş / koşu pozları: her canavar için yerinde kareler.
## Kullanım: --test=res://tests/test_beast_idle.gd --shots=<dizin> [--tag=a] [--ids=shukaku,matatabi]

var main: Node
var pl: Player
var tag := "a"
var ids := ["shukaku", "matatabi"]
var face := 0.78
var acts := false


func _ready() -> void:
	await get_tree().process_frame
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
		if a.begins_with("--face="):
			face = float(a.substr(7))
		if a == "--acts":
			acts = true
		if a.begins_with("--ids="):
			ids = Array(a.substr(6).split(","))
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12),
		"top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	Game.world.env.weather_t = 9999.0
	Game.world.env.region_weather = "açık"
	pl = main.player
	pl.set_process(false)
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(4.0).timeout
	var base = pl.global_position
	for id in ids:
		await _beast(id, base)
	print("BEAST IDLE BITTI")
	get_tree().quit()


func _beast(id: String, base: Vector3) -> void:
	var b = TailedBeast.new()
	b.setup(id)
	get_tree().current_scene.add_child(b)
	var p = base + Vector3.FORWARD * b.height * 0.9
	p.y = Game.ground_height(p.x, p.z)
	b.global_position = p
	b.home = p
	b.set_physics_process(false)
	b.facing = PI * face
	b.rig.rotation.y = b.facing
	pl.global_position = p + Vector3(b.height * 3.0, 0, 0)
	var cam = Camera3D.new()
	get_tree().current_scene.add_child(cam)
	cam.global_position = p + Vector3(0, b.height * 0.45, b.height * 2.0)
	cam.look_at(p + Vector3.UP * b.height * 0.4)
	cam.far = 4000.0
	cam.current = true
	var r: BeastRig = b.rig
	r.fid_wait = 999.0
	await get_tree().create_timer(1.2).timeout
	await main.shot("bi_%s_%s_0bekle" % [tag, id])
	for f in [["look", 2.8], ["shake", 1.2], ["growl", 1.8], ["paw", 1.8], ["stretch", 2.6]]:
		r.fid = f[0]
		r.fid_dur = f[1]
		r.fid_t = 0.0
		r.fid_side = 1.0
		await get_tree().create_timer(f[1] * 0.5).timeout
		await main.shot("bi_%s_%s_1%s" % [tag, id, f[0]])
		await get_tree().create_timer(f[1] * 0.5 + 0.4).timeout
	r.move_speed = 1.0
	await get_tree().create_timer(0.9).timeout
	await main.shot("bi_%s_%s_2yuru" % [tag, id])
	r.run_target = 1.0
	await get_tree().create_timer(1.1).timeout
	await main.shot("bi_%s_%s_3kos_a" % [tag, id])
	await get_tree().create_timer(0.17).timeout
	await main.shot("bi_%s_%s_3kos_b" % [tag, id])
	await get_tree().create_timer(0.17).timeout
	await main.shot("bi_%s_%s_3kos_c" % [tag, id])
	if acts:
		r.move_speed = 0.0
		r.run_target = 0.0
		await get_tree().create_timer(1.2).timeout
		for a in [["swipe_r", 1.6, [0.3, 0.5, 0.62]], ["slam", 1.8, [0.4, 0.66]], ["roar", 1.6, [0.5]]]:
			r.play_action(a[0], a[1])
			var el := 0.0
			for q in a[2]:
				await get_tree().create_timer(a[1] * q - el).timeout
				el = a[1] * q
				await main.shot("bi_%s_%s_4%s_%d" % [tag, id, a[0], int(q * 100)])
			await get_tree().create_timer(a[1] - el + 0.5).timeout
	cam.queue_free()
	b.queue_free()
	await get_tree().create_timer(0.4).timeout
