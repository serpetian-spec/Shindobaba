extends Node
## Bijū hareket animasyonları: savaş duruşu, yürüyüş, koşu/dörtnal, sıçrayış, kombo (pençe/pençe/ısırık-çakma/kuyruk).
## Yandan sabit kamera; canavar yerinde oynatılır (rig durumları elle). --shots=<dizin> [--only=kurama,shukaku]
var main: Node
var pl: Player
var only := ""


func _ready() -> void:
	await get_tree().process_frame
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
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
	var base = pl.global_position
	for id in ["kurama", "shukaku", "chomei", "saiken", "matatabi", "gyuki"]:
		if only != "" and not id in only.split(","):
			continue
		await _beast(id, base)
	print("MOVES BITTI")
	get_tree().quit()


func _beast(id: String, base: Vector3) -> void:
	var b = TailedBeast.new()
	b.setup(id)
	get_tree().current_scene.add_child(b)
	var p = base
	p.y = Game.ground_height(p.x, p.z)
	b.global_position = p
	b.set_physics_process(false)
	b.facing = PI * 0.5
	var r: BeastRig = b.rig
	r.rotation.y = b.facing
	pl.global_position = p + Vector3(0, 0, b.height * 3.0)
	var cam = Camera3D.new()
	get_tree().current_scene.add_child(cam)
	cam.far = 4000.0
	cam.global_position = p + Vector3(0, b.height * 0.5, b.height * 2.2)
	cam.look_at(p + Vector3.UP * b.height * 0.4)
	cam.current = true
	r.aggro = false
	await get_tree().create_timer(1.0).timeout
	await main.shot("mv_%s_1sakin" % id)
	r.aggro = true
	await get_tree().create_timer(1.2).timeout
	await main.shot("mv_%s_2durus" % id)
	r.move_speed = 1.0
	await get_tree().create_timer(0.9).timeout
	await main.shot("mv_%s_3yuru" % id)
	r.run_target = 1.0
	await get_tree().create_timer(1.0).timeout
	await main.shot("mv_%s_4kos_a" % id)
	await get_tree().create_timer(0.17).timeout
	await main.shot("mv_%s_4kos_b" % id)
	r.run_target = 0.0
	r.move_speed = 0.0
	await get_tree().create_timer(0.8).timeout
	r.play_action("leap", 1.5)
	await get_tree().create_timer(0.25).timeout
	await main.shot("mv_%s_5sicra_comel" % id)
	await get_tree().create_timer(0.5).timeout
	await main.shot("mv_%s_5sicra_hava" % id)
	await get_tree().create_timer(0.8).timeout
	r.play_action("swipe_l", 0.55)
	await get_tree().create_timer(0.22).timeout
	await main.shot("mv_%s_6pence" % id)
	await get_tree().create_timer(0.5).timeout
	r.play_action("bite" if r.quadruped else "slam", 0.9)
	await get_tree().create_timer(0.3 if r.quadruped else 0.4).timeout
	await main.shot("mv_%s_7bitir_a" % id)
	await get_tree().create_timer(0.25).timeout
	await main.shot("mv_%s_7bitir_b" % id)
	await get_tree().create_timer(0.6).timeout
	b.queue_free()
	cam.queue_free()
	await get_tree().create_timer(0.3).timeout
