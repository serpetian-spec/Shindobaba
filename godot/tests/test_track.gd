extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	var v = Game.village("konoha")
	main.player.respawn(Game.from_map(Vector2(v["x"], v["y"] - 40)))
	await get_tree().create_timer(2.0).timeout
	Game.profile["waypoint"] = [main.player.global_position.x + 200, 0.0, main.player.global_position.z, "Ramen"]
	Game.profile["track"] = "waypoint"
	await get_tree().create_timer(0.3).timeout
	print("TRACK wp ", Missions.has_marker, " ", Missions.target_name)
	Game.profile["track"] = "none"
	await get_tree().create_timer(0.3).timeout
	print("TRACK none ", Missions.has_marker)
	Game.profile["track"] = "story"
	await get_tree().create_timer(0.3).timeout
	print("TRACK story ", Missions.has_marker, " ", Missions.target_name)
	main._pause()
	Menus.ninja_menu(main, "missions")
	await get_tree().create_timer(0.6).timeout
	await main.shot("track_tab")
	get_tree().quit()
