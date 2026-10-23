extends Node
## Konoha ramen tezgâhı (Ichiraku modeli) önden ve yandan
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.42
	main.world.env.region_weather = "açık"
	main.world.env.weather_t = 9999.0
	main.world.env.overcast = 0.0
	var pl = main.player
	var v = Game.village("konoha")
	var shop = Game.from_map(Vector2(v["x"] + 70, v["y"] - 30))
	shop.y = Game.terrain_height(shop.x, shop.z)
	pl.global_position = Game.from_map(Vector2(v["x"] + 70, v["y"] - 30 + 9))
	pl.global_position.y = Game.terrain_height(pl.global_position.x, pl.global_position.z) + 0.2
	pl.reset_physics_interpolation()
	await get_tree().create_timer(6.0).timeout
	pl.set_process(false)
	pl.set_physics_process(false)
	for spot in [[Vector3(0, 3.5, -13), "pl_ramen_on"], [Vector3(10, 4, -6), "pl_ramen_yan"], [Vector3(0, 2.0, -6.5), "pl_ramen_yakin"]]:
		pl.cam.global_position = shop + spot[0]
		pl.cam.look_at(shop + Vector3(0, 2.0, 0))
		await get_tree().create_timer(0.4).timeout
		await main.shot(spot[1])
	get_tree().quit()
