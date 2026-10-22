extends Node
## Hokage Kayası taş yüzleri
var main: Node
func _at(x: float, n: float) -> Vector3:
	var v = Game.village("konoha")
	var p = Game.from_map(Vector2(v["x"] + x, v["y"] + n))
	p.y = Game.terrain_height(p.x, p.z) + 0.2
	return p
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.42
	var pl = main.player
	for spot in [[0, 700, 18.0, 14.0, "h1_uzak"], [0, 900, 25.0, 14.0, "h2_yakin"], [-250, 950, 20.0, 12.0, "h3_yan"]]:
		pl.global_position = _at(spot[0], spot[1])
		pl.velocity = Vector3.ZERO
		pl.reset_physics_interpolation()
		pl.yaw = 0.0
		pl.pitch = spot[2]
		pl.cam_dist = spot[3]
		await get_tree().create_timer(4.0).timeout
		await main.shot(spot[4])
	get_tree().quit()
