extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 98, "name": "A", "gender": "m", "clan": "uchiha", "element": "katon", "village": "konoha", "hair_style": "s2", "hair": Color(0.2, 0.2, 0.2), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	Game.profile["flags"]["hatred"] = true
	Buffs.add("hatred", 99999.0, {"jutsu": 1.12})
	Buffs.add("asker_hapi", 600.0, {"melee": 1.2})
	Game.save_game()
	print("BUFF slotA ", Buffs.active.keys())
	main.to_main_menu()
	await get_tree().create_timer(0.5).timeout
	print("BUFF menu ", Buffs.active.keys())
	main.creator_state = main.creator_state.duplicate()
	main.creator_state["slot"] = 99
	main.creator_state["name"] = "B"
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	print("BUFF slotB ", Buffs.active.keys())
	Game.save_game()
	main.to_main_menu()
	await get_tree().create_timer(0.5).timeout
	main.load_slot(98)
	await get_tree().create_timer(4.0).timeout
	print("BUFF reload A ", Buffs.active.keys())
	main.to_main_menu()
	await get_tree().create_timer(0.5).timeout
	main.load_slot(99)
	await get_tree().create_timer(4.0).timeout
	print("BUFF reload B ", Buffs.active.keys())
	get_tree().quit()
