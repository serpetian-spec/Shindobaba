extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	var v = Game.village("konoha")
	main.player.respawn(Game.from_map(Vector2(v["x"], v["y"] - 40)))
	await get_tree().create_timer(3.0).timeout
	var lm = Interact.landmarks(main.player.global_position, 2500.0)
	print("YERLER ", lm.size(), ": ", lm.map(func(x): return x["name"]))
	await main.shot("lm_minimap")
	main._pause()
	Menus.world_map(main)
	await get_tree().create_timer(0.6).timeout
	await main.shot("lm_harita")
	get_tree().quit()
