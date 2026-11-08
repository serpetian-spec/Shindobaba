extends Node
## Bugünkü Konoha: oyuncunun kendi kamerasıyla, ilk sürümdeki gibi arkadan açı
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.35, 0.22, 0.12), "top": Color(0.15, 0.25, 0.55), "pants": Color(0.25, 0.27, 0.32), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(3.0)
	Hud.close_dialog()
	Game.world.env.time_of_day = 0.42
	var pl = main.player
	var vs = Game.village("konoha")
	var c = Game.from_map(Vector2(float(vs["x"]), float(vs["y"]) + 60.0))
	pl.respawn(Missions.open_ground(c, 10.0))
	await _w(4.0)
	Hud.close_dialog()
	pl.cam_dist = 6.0
	await _w(1.0)
	await main.shot("now_a")
	pl.yaw += 1.4
	await _w(1.0)
	await main.shot("now_b")
	get_tree().quit()
