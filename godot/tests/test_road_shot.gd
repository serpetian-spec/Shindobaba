extends Node
## Köy dışı toprak yol: gece ve gündüz, oyuncunun arkasından (yüzey ışık yamaları / köşeli görünüm kontrolü)
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.35, 0.22, 0.12), "top": Color(0.15, 0.25, 0.55), "pants": Color(0.25, 0.27, 0.32), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(3.0)
	Hud.close_dialog()
	var pl = main.player
	var vs = Game.village("konoha")
	var m = Vector2(float(vs["x"]) + 260.0, float(vs["y"]) + 120.0)
	var rp = Roadside._nearest_road_point(m, 900.0)
	print("ROAD point ", rp, " from ", m)
	pl.respawn(Game.from_map(rp))
	await _w(5.0)
	Hud.close_dialog()
	pl.cam_dist = 5.0
	for tod in [0.95, 0.45]:
		Game.world.env.time_of_day = tod
		await _w(1.5)
		await main.shot("road_%d" % int(tod * 100))
		pl.yaw += 1.57
		await _w(1.0)
		await main.shot("road_%d_b" % int(tod * 100))
	get_tree().quit()
