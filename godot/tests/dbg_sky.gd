extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.42
	main.player.pitch = 40.0
	main.player.cam_dist = 4.0
	await get_tree().create_timer(3.0).timeout
	await main.shot("sky_a")
	main.world.env.env.sky.radiance_size = Sky.RADIANCE_SIZE_256
	main.world.env.env.sky.process_mode = Sky.PROCESS_MODE_QUALITY
	await get_tree().create_timer(2.0).timeout
	await main.shot("sky_b")
	main.world.env.post.visible = false
	await get_tree().create_timer(1.0).timeout
	await main.shot("sky_c")
	get_tree().quit()
