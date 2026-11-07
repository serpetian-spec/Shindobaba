extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var fr = get_tree().current_scene.find_child("Friends", true, false)
	var pp = main.player.global_position
	var d0 = fr._dest_for("train")
	Game.profile["flags"]["rogue"] = true
	var d1 = fr._dest_for("train")
	var home_tp = Exams.find_point(["training"])
	print("TRAIN normal=%s dist=%.0f | rogue=%s dist=%.0f from_village_training=%.0f" % [d0["name"], d0["pos"].distance_to(pp), d1["name"], d1["pos"].distance_to(pp), d1["pos"].distance_to(home_tp)])
	get_tree().quit()
