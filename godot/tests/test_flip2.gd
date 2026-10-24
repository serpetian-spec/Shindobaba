extends Node
## Havada ikinci Ctrl sıçrayışı ve Space ikinci zıplama: takla tüm vücutla mı?
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Kaito", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12),
		"top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8), "village": "konoha"}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	Menus.clear()
	Hud.show_game_hud(false)
	var p: Player = main.player
	var base = Exams.find_point(["training"])
	base.y = Game.terrain_height(base.x, base.z)
	p.global_position = base
	await get_tree().create_timer(1.0).timeout
	var cam = Camera3D.new()
	main.add_child(cam)
	for mode in ["ctrl", "space"]:
		p.global_position = base
		p.velocity = Vector3.ZERO
		await get_tree().create_timer(0.6).timeout
		p._leap(1.0)
		await get_tree().create_timer(1.3).timeout
		if mode == "ctrl":
			p._leap(1.0)
		else:
			p._jump()
		while p.flip_t <= 0.0 and not p.grounded:
			await get_tree().process_frame
		for i in 6:
			await get_tree().create_timer(0.07).timeout
			var side = p.face_dir().cross(Vector3.UP)
			cam.global_position = p.global_position + Vector3.UP * 1.2 + side * 3.2
			cam.look_at(p.global_position + Vector3.UP * 0.9)
			cam.current = true
			await main.shot("f2_%s_%d" % [mode, i])
		cam.current = false
		var t = 0.0
		while not p.grounded and t < 8.0:
			await get_tree().process_frame
			t += get_process_delta_time()
	get_tree().quit()
