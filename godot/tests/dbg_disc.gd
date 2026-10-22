extends Node
var main: Node
func _count() -> int:
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	var n = 0
	for y in range(0, int(img.get_height() * 0.35), 3):
		for x in range(0, img.get_width(), 3):
			var c = img.get_pixel(x, y)
			if c.b > 0.45 and c.r < 0.2 and c.g < 0.25 and c.b - c.g > 0.3:
				n += 1
	return n
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var env = main.world.env
	env.time_of_day = 0.45
	env.region_weather = "yağmur"
	env.weather_t = 9999.0
	env.overcast = 0.85
	main.player.pitch = -8.0
	main.player.cam_dist = 6.0
	await get_tree().create_timer(3.0).timeout
	main.player.set_physics_process(false)
	var base = await _count()
	print("DISC base=", base)
	var cands = []
	for parent in [main, main.world, main.actors, env]:
		for c in parent.get_children():
			if c is Node3D or c is CanvasLayer:
				cands.append(c)
	for c in cands:
		if not ("visible" in c) or not c.visible:
			continue
		c.visible = false
		await get_tree().process_frame
		var n = await _count()
		c.visible = true
		if n < base * 0.3:
			print("DISC GİZLENDİ: ", c.get_path(), " ", c.get_class(), " n=", n)
	get_tree().quit()
