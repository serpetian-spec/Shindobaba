extends Node
## Yağmur ve kar görünümü
var main: Node
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
	var pl = main.player
	pl.pitch = -8.0
	pl.cam_dist = 6.0
	await get_tree().create_timer(3.0).timeout
	await main.shot("r1_yagmur")
	pl.pitch = 20.0
	await get_tree().create_timer(1.0).timeout
	await main.shot("r2_yagmur_yukari")
	# koşarken yağmur geride kalmamalı
	for i in 60:
		pl.global_position += Vector3(0.5, 0, 0)
		await get_tree().physics_frame
	await main.shot("r3_kosarken")
	env.region_weather = "kar"
	env.overcast = 0.6
	pl.pitch = -8.0
	await get_tree().create_timer(4.0).timeout
	await main.shot("r4_kar")
	get_tree().quit()
