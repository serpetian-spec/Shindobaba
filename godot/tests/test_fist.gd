extends Node
## Yumruk: iki elin yakın çekimi (FS=işaret çarpanı denemesi için boş bırak)
var main: Node
var cam: Camera3D
var pl: Node3D


func _camw(p: Vector3, t: Vector3) -> void:
	if cam == null or not is_instance_valid(cam):
		cam = Camera3D.new()
		main.add_child(cam)
		cam.fov = 30.0
	cam.global_position = p
	cam.look_at(t)
	cam.current = true


func _hand(side: String) -> Vector3:
	return MissionWork.I()._bone(pl, side + "Hand")


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	pl = main.player
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	main.world.env.time_of_day = 0.45
	Game.profile["age"] = "adult"
	pl.model.apply_age("adult")
	await get_tree().create_timer(0.5).timeout
	var tags = ["rest", "fist"]
	for k in 2:
		if k == 1:
			pl.model.overlay.fist["Left"] = 1.0
			pl.model.overlay.fist["Right"] = 1.0
		await get_tree().create_timer(0.4).timeout
		for side in ["Left", "Right"]:
			var h = _hand(side)
			var f = pl.face_dir()
			var r = f.cross(Vector3.UP).normalized()
			var views = {"front": f * 0.9 + Vector3.UP * 0.1, "out": r * (0.9 if side == "Right" else -0.9), "back": -f * 0.9 + Vector3.UP * 0.15}
			for v in views:
				_camw(h + views[v], h - Vector3.UP * 0.06)
				await get_tree().create_timer(0.05).timeout
				await main.shot("fist_%s_%s_%s" % [tags[k], side, v])
	# gerçek vuruş anı
	pl.model.overlay.fist.clear()
	get_tree().quit()
