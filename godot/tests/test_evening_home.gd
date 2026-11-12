extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "eye": Color(0.2, 0.4, 0.9), "skin": Color(0.96, 0.8, 0.66)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	Game.world.env.time_of_day = 0.5
	await get_tree().create_timer(1.5).timeout
	print("EH day wp=", Game.profile.get("waypoint"), " host=", HomeLife.host_id(), " door=", HomeLife.door_pos())
	Game.world.env.time_of_day = 0.76
	await get_tree().create_timer(2.0).timeout
	print("EH eve wp=", Game.profile.get("waypoint"), " track=", Game.profile.get("track"), " host_home=", HomeLife.host_home())
	await main.shot("eh_eve")
	Game.world.env.time_of_day = 0.4
	await get_tree().create_timer(2.0).timeout
	print("EH morning wp=", Game.profile.get("waypoint"), " track=", Game.profile.get("track"))
	get_tree().quit()
