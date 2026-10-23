extends Node
## Hazır model geçişi görsel kontrolü: Konoha sokakları, pazar, tapınak, kuş bakışı, orman, yol, mezra, çöl, kar
var main: Node


func _at(x: float, n: float) -> Vector3:
	var v = Game.village("konoha")
	var p = Game.from_map(Vector2(float(v["x"]) + x, float(v["y"]) + n))
	p.y = Game.terrain_height(p.x, p.z)
	return p


func _go(p: Vector3, yaw: float, pitch := -12.0, dist := 7.0) -> void:
	var pl = main.player
	pl.global_position = p
	pl.velocity = Vector3.ZERO
	pl.reset_physics_interpolation()
	pl.yaw = yaw
	pl.pitch = pitch
	pl.cam_dist = dist


func _map(mx: float, my: float) -> Vector3:
	var p = Game.from_map(Vector2(mx, my))
	p.y = Game.terrain_height(p.x, p.z)
	return p


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var env = Game.world.env
	env.time_of_day = 0.42
	env.region_weather = "açık"
	env.weather_t = 99999.0
	env.overcast = 0.0
	var shots = [
		[_at(0, -700), 0.0, -8.0, 8.0, "w1_konoha_cadde"],
		[_at(-20, -6), 90.0, -14.0, 9.0, "w2_pazar"],
		[_at(-1020, -700), 0.0, 8.0, 14.0, "w3_tapinak"],
		[_at(-300, -300), 30.0, -10.0, 9.0, "w4_mahalle"],
		[_at(0, -900) + Vector3(0, 120, 0), 0.0, -25.0, 12.0, "w5_kus_bakisi"],
		[_at(-200, -1900), 180.0, -8.0, 9.0, "w6_orman"],
	]
	for v in Game.world_info["villages"]:
		if v["id"] == "suna":
			shots.append([_map(float(v["x"]) + float(v["r"]) * 2.2, float(v["y"])), 270.0, -8.0, 9.0, "w7_col"])
		if v["id"] == "kumo":
			shots.append([_map(float(v["x"]), float(v["y"]) - float(v["r"]) * 2.0), 0.0, -6.0, 9.0, "w8_kumo_yolu"])
		if v["id"] == "tetsu":
			shots.append([_map(float(v["x"]), float(v["y"]) - float(v["r"]) * 2.0), 0.0, -8.0, 9.0, "w9_kar"])
	for sh in shots:
		_go(sh[0], sh[1], sh[2], sh[3])
		await get_tree().create_timer(5.0).timeout
		await main.shot(sh[4])
	get_tree().quit()
