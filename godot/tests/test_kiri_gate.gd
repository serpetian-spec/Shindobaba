extends Node
## Kiri kapısı: yol bağlantısı olmayan sur açıklığı + sur bandı noktası kontrolü
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	var pl = main.player
	await get_tree().create_timer(2.0).timeout
	for vid in ["kiri", "suna"]:
		var v = Game.village(vid)
		var c = Game.from_map(Vector2(v["x"], v["y"]))
		var r = float(v["r"])
		var g = float(v["gates"][0])
		var dir = Vector3(sin(deg_to_rad(g)), 0, -cos(deg_to_rad(g)))
		var inn = Missions.open_ground(c + dir * r * 0.7, 40.0)
		pl.respawn(inn)
		await get_tree().create_timer(6.0).timeout
		var wallp = c + dir * r * 0.97
		var og = Missions.open_ground(wallp, 20.0)
		print("GATE %s gates=%s wall_band=%s open_ground_out=%s dist=%.0f r=%.0f" % [vid, v["gates"], Game.in_village_wall(wallp.x, wallp.z), og, Game.to_map(og).distance_to(Vector2(v["x"], v["y"])), r])
		pl.set_process(false)
		var cam = Camera3D.new()
		main.add_child(cam)
		cam.far = 4000
		cam.current = true
		cam.global_position = inn + Vector3(0, 30, 0)
		cam.look_at(Vector3(wallp.x, Game.ground_height(wallp.x, wallp.z) + 20, wallp.z))
		await get_tree().create_timer(0.5).timeout
		await main.shot("gate_%s" % vid)
		cam.queue_free()
		pl.set_process(true)
	get_tree().quit()
