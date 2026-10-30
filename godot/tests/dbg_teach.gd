extends Node
## Akademi hocasında [F]: chūnin+ öğretmenlik seçenekleri görünüyor mu
var main: Node


func _btns() -> Array:
	return Hud.dialog_layer.find_children("*", "Button", true, false).map(func(b): return String(b.text))


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	Progress.set_story(Journal.FREE)
	Game.profile["rank"] = 2
	Progress._academy()
	await get_tree().process_frame
	print("TEACH btns=", _btns())
	for b in Hud.dialog_layer.find_children("*", "Button", true, false):
		if String(b.text).begins_with("Akademide"):
			b.pressed.emit()
	await get_tree().process_frame
	Menus.clear()
	Progress._academy()
	await get_tree().process_frame
	print("TEACH after=", _btns())
	get_tree().quit()
