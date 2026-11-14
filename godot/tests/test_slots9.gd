extends Node
## 9 jutsu slotu: HUD çubuğu ve jutsu menüsü ekrana sığıyor mu.
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12),
		"top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	print("slots=", Game.profile["slots"].size(), " ekran=", get_viewport().get_visible_rect().size)
	get_viewport().get_texture().get_image().save_png((ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir() + "/_tmp/kv/slots_hud.png"))
	Menus.ninja_menu(main, "jutsu", "")
	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_png((ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir() + "/_tmp/kv/slots_menu.png"))
	get_tree().quit()
