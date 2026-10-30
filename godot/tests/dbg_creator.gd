extends Node
## Karakter yaratma ekranı: sekmeler, oklu seçiciler, shinobi evi arka planı (köye göre)
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	Menus._ctab = "kimlik"
	main.start_creator(3)
	await get_tree().create_timer(1.5).timeout
	await main.shot("cr_1_kimlik")
	Menus._ctab = "gorunum"
	main.creator_state["hair_style"] = "savas_yelesi"
	main.creator_state["hair"] = Color(0.08, 0.08, 0.1)
	main._update_preview()
	Menus.creator(main, main.creator_state, main._update_preview, main._start_new_game)
	await get_tree().create_timer(1.2).timeout
	await main.shot("cr_2_gorunum")
	Menus._ctab = "kiyafet"
	main.creator_state["village"] = "suna"
	main._update_preview()
	Menus.creator(main, main.creator_state, main._update_preview, main._start_new_game)
	await get_tree().create_timer(1.2).timeout
	await main.shot("cr_3_kiyafet_suna")
	get_tree().quit()
