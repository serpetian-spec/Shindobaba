extends Node
var main: Node
var t_post := 0
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	await get_tree().create_timer(14.0).timeout
	Hud.close_dialog()
	RenderingServer.frame_post_draw.connect(func(): t_post = Time.get_ticks_usec())
	await get_tree().create_timer(0.5).timeout
	print("BIS pencere %s" % DisplayServer.window_get_size())
	if main.perf_panel == null:
		main._make_perf_panel()
	var pp = main.perf_panel
	for rnd in 2:
		for i in pp.TESTS.size():
			pp._apply_test(i)
			await get_tree().create_timer(1.0).timeout
			var t0 = Time.get_ticks_usec()
			var f = 0
			while Time.get_ticks_usec() - t0 < 4000000:
				await get_tree().process_frame
				f += 1
			print("BIS tur %d  %s: %d FPS" % [rnd + 1, pp.TESTS[i], f / 4])
	pp._apply_test(0)
	get_tree().quit()
