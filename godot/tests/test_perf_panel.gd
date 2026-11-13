extends Node
var main: Node
func _key(k: int) -> void:
	var e = InputEventKey.new()
	e.keycode = k
	e.pressed = true
	Input.parse_input_event(e)
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(5.0).timeout
	Hud.close_dialog()
	main.perf_panel.min_fps = [58, 57, 55, 52, 50, 47, 44, 40, 37, 33, 31, 30]   # oturum grafiği görünsün diye örnek
	main.perf_panel.min_nodes = [190000, 190400, 191000, 192500, 194000, 196000, 199000, 203000, 207000, 211000, 214000, 216000]
	_key(KEY_F3)
	await get_tree().create_timer(6.0).timeout
	for i in 6:
		_key(KEY_F4)
		await get_tree().create_timer(3.2).timeout
	_key(KEY_F4)
	await get_tree().create_timer(3.0).timeout
	print("PANEL acik=", main.perf_panel.visible, " denemeler=", main.perf_panel.test_fps)
	await main.shot("perf_panel")
	_key(KEY_F3)
	await get_tree().create_timer(0.5).timeout
	print("PANEL kapali=", not main.perf_panel.visible, " olcek=", get_viewport().scaling_3d_scale, " bitki=", Game.world.vegetation.visible)
	get_tree().quit()
