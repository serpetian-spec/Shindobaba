extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	Game.world.env.time_of_day = 0.42
	var v = Game.village("konoha")
	var p = Game.from_map(Vector2(v["x"] + 20, v["y"] - 120))
	pl.respawn(p)
	pl.yaw = 200.0
	pl.pitch = -6.0
	pl.cam_dist = 2.6
	await get_tree().create_timer(4.0).timeout
	await main.shot("p1_cocuk_yakin")
	pl.yaw = 0.0
	pl.cam_dist = 7.0
	pl.pitch = -10.0
	await get_tree().create_timer(3.0).timeout
	await main.shot("p2_sokak")
	print("fps=", Engine.get_frames_per_second(), " npcs=", get_tree().get_nodes_in_group("talkers").size())
	Game.profile["rank"] = 3
	Game.profile["look"]["vest"] = Color(0.38, 0.48, 0.28)
	pl.rebuild_model()
	pl.yaw = 200.0
	pl.cam_dist = 2.8
	await get_tree().create_timer(1.5).timeout
	await main.shot("p3_jonin")
	get_tree().quit()
