extends Node
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "f", "clan": "none", "element": "fuuton", "hair_style": "uzun", "hair": Color(0.9, 0.78, 0.4), "top": Color(0.9, 0.88, 0.85), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.4, 0.35)}
	main._start_new_game()
	await _w(2.0)
	var pl = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(1.5)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	var base = pl.cam.global_transform
	var tests = {"a_copy": base, "b_up1": base.translated(Vector3(0, 1, 0)), "c_lookat": Transform3D.IDENTITY}
	for k in tests:
		var t: Transform3D = tests[k]
		if k == "c_lookat":
			cc.global_position = pl.global_position + Vector3(1.5, 1.4, 3.0)
			cc.look_at(pl.global_position + Vector3.UP, Vector3.UP)
		else:
			cc.global_transform = t
		cc.current = true
		await _w(0.1)
		print("CAM %s cur=%s pos=%s" % [k, get_viewport().get_camera_3d() == cc, cc.global_position])
		await main.shot("cam_" + k)
	get_tree().quit()
