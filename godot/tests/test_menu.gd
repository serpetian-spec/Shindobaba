extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.to_main_menu()
	await get_tree().create_timer(2.0).timeout
	await main.shot("m1_ana_menu")
	main.start_creator(3)
	main.creator_state["clan"] = "hyuga"
	main.creator_state["gender"] = "f"
	main.creator_state["hair_style"] = "uzun"
	main.creator_state["hair"] = Color(0.1, 0.08, 0.15)
	main._update_preview()
	Menus.creator(main, main.creator_state, main._update_preview, main._start_new_game)
	await get_tree().create_timer(1.5).timeout
	await main.shot("m2_karakter_yarat")
	main._start_new_game()
	await get_tree().create_timer(1.0).timeout
	main._pause()
	Menus.pause(main)
	await get_tree().create_timer(0.5).timeout
	await main.shot("m3_duraklat")
	Menus.world_map(main)
	await get_tree().create_timer(0.5).timeout
	await main.shot("m4_harita")
	get_tree().quit()
