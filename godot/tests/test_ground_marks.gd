extends Node
## Çölde ayak izi + su üstünde yürürken halka dalga
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	pl.max_chakra = 1e6
	pl.chakra = 1e6
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(1.0)
	print("MARK biome=%d" % Game.biome_at(pl.global_position.x, pl.global_position.z))
	Input.action_press("forward")
	await _w(2.5)
	Input.action_release("forward")
	await _w(0.3)
	print("MARK prints=%d" % GroundMarks._prints.size())
	pl.yaw = 180.0
	pl.pitch = -35.0
	pl.cam_dist = 5.0
	await _w(0.4)
	await main.shot("marks_sand")
	# deniz: kıyıdan açığa doğru su bul
	var base = pl.global_position
	var found = Vector3.ZERO
	for r in range(200, 6000, 150):
		for k in 16:
			var a = TAU * k / 16.0
			var q = base + Vector3(cos(a), 0, sin(a)) * r
			if Game.terrain_height(q.x, q.z) < -2.0:
				found = q
				break
		if found != Vector3.ZERO:
			break
	print("MARK water at %s" % found)
	if found != Vector3.ZERO:
		pl.respawn(Vector3(found.x, 0.5, found.z))
		await _w(1.0)
		Input.action_press("forward")
		await _w(1.2)
		pl.yaw = 180.0
		pl.pitch = -25.0
		await _w(0.25)
		await main.shot("marks_water")
		Input.action_release("forward")
		await _w(0.8)
		await main.shot("marks_water_idle")
		print("MARK on_water=%s y=%.2f" % [pl.on_water, pl.global_position.y])
	get_tree().quit()
