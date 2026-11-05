extends Node
## Ustalık artışı görünür mü: vuruş başına kazanım, çeyrek puan bildirimleri, menü ondalıklı
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.5).timeout
	var pr = Game.profile
	var v0 = Mastery.get_v(pr, "taijutsu")
	for i in 40:
		Mastery.gain(pr, "taijutsu", 0.3)
	print("MASTERY taijutsu %.3f -> %.3f (40 vuruş)" % [v0, Mastery.get_v(pr, "taijutsu")])
	Hud.close_dialog()
	Menus.ninja_menu(main, "skills")
	await get_tree().create_timer(0.5).timeout
	await main.shot("mastery_tab")
	get_tree().quit()
