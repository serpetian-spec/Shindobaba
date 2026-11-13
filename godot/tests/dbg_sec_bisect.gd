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
	var t0 = Time.get_ticks_usec()
	var n = 0
	var f = 0
	var worst = 0
	var last = t0
	while Time.get_ticks_usec() - t0 < 12000000:
		await get_tree().process_frame
		var now = Time.get_ticks_usec()
		f += 1
		worst = maxi(worst, now - last)
		last = now
		if now - t_post > 6000:
			n += 1
	print("BIS 12 sn: ort FPS %d, en kotu an %d FPS, uzun kare %d, portre var=%s" % [f / 12, 1000000 / maxi(1, worst), n, Hud.portrait_tex != null])
	get_tree().quit()
