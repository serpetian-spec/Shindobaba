extends Node
## Gardırop: saç stili ve Susanoo seçenekleri oklu satırda
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	Menus._eq_slot = "sac"
	Menus.ninja_menu(main, "wardrobe")
	await get_tree().create_timer(1.0).timeout
	await main.shot("wr_sac")
	var pr = Game.profile
	Gear.grant(pr, "goz_ems", "sag_goz"); Gear.grant(pr, "goz_ems", "sol_goz")
	Gear.apply_look(pr)
	Menus._eq_slot = "susanoo"
	Menus.ninja_menu(main, "wardrobe")
	await get_tree().create_timer(1.5).timeout
	await main.shot("wr_susanoo")
	get_tree().quit()
