extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	Hud.close_dialog()
	var fs = Friends.all()
	fs["t_rogue"] = {"name": "Kaçak Deneme", "look": {"band_style": "slashed"}, "rogue": true, "status": "öldü", "bond": 30, "village": "konoha", "log": []}
	fs["t_village"] = {"name": "Köylü Deneme", "look": {}, "status": "öldü", "bond": 30, "village": "konoha", "log": [], "family": []}
	Friends.inst()._funeral_tick()
	Hud.close_dialog()
	print("RF rogue buried=", fs["t_rogue"].get("buried"), " funeral_t=", fs["t_rogue"].get("funeral_t"), " | village funeral_t=", fs["t_village"].has("funeral_t"))
	get_tree().quit()
