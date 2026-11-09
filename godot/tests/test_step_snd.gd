extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "suna", "hair_style": "s2", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	var p = main.player.global_position
	print("STEP suna=", Game.step_sound(p), " sfx_ok=", Sfx.has_method("play"))
	for v in Game.world_info["villages"]:
		var q = Vector3(float(v["x"]), 0, -float(v["y"]))
		print("STEP ", v.get("id", ""), " -> ", Game.step_sound(q))
	get_tree().quit()
