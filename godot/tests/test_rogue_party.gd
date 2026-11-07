extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	Game.profile["rank"] = 2
	Game.profile["flags"]["rogue"] = true
	var lk = CharacterModel.default_look()
	lk["band_style"] = "slashed"
	var id = Friends.add_person("Kaçak Deneme", lk, 2, "spar", "konoha", main.player.global_position, "Kaçak ninja")
	Friends.all()[id]["bond"] = 50
	print("PARTY rogue_flag=%s status='%s' ok=%s" % [Friends.all()[id].get("rogue", false), Friends.all()[id].get("status", ""), Friends.set_party(id, true)])
	get_tree().quit()
