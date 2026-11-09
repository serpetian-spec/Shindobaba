extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.start_creator(98)
	await get_tree().process_frame
	main.creator_state["village"] = "konoha"
	main.creator_state["clan"] = "inuzuka"
	main.creator_state.erase("face_paint")
	Menus._ctab = "gorunum"
	main.start_creator(98)
	main.creator_state["clan"] = "inuzuka"
	Menus._ctab = "gorunum"
	Menus.creator(main, main.creator_state, main._update_preview, main._start_new_game)
	await get_tree().process_frame
	print("FPC state face_paint=", main.creator_state.get("face_paint"))
	var labels = []
	for l in get_tree().root.find_children("*", "Label", true, false):
		if "BOYA" in l.text.to_upper():
			labels.append(l.text)
	print("FPC rows=", labels)
	main.creator_state["face_paint"] = CharacterModel.CLAN_FACE_PAINT.get("inuzuka")   # UI: klan seçimi (pick) bunu yapar
	main.creator_state["face_paint_col_name"] = "Mavi"
	main.creator_state["name"] = "T"
	main._start_new_game()
	await get_tree().create_timer(2.5).timeout
	var lk = Game.profile["look"]
	print("FPC look=", lk.get("face_paint"), " col=", lk.get("face_paint_col"), " mat_col=", main.player.model.face_skin_mat.get_shader_parameter("paint_col") if main.player.model.face_skin_mat else "none")
	get_tree().quit()
