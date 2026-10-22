extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	Game.world.env.time_of_day = 0.42
	var kv = Game.village("konoha")
	for i in 3:
		var y = float(kv["y"]) - 600.0 + i * 500.0
		pl.respawn(Game.from_map(Vector2(kv["x"], y)))
		pl.yaw = 0.0
		pl.pitch = 12.0
		pl.cam_dist = 6.0
		await get_tree().create_timer(4.0).timeout
		print("pos ", i, " y=", y, " h=", Game.terrain_height(float(kv["x"]), -y), " hokage_y=", kv.get("hokage_rock", {}).get("y", 0))
		await main.shot("k%d" % i)
	get_tree().quit()
