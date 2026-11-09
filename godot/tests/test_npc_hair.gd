extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "kısa", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(25.0).timeout
	var cnt = {}
	var n = 0; var anime = 0; var wrong = 0
	for m in get_tree().current_scene.find_children("*", "Node3D", true, false):
		if m is CharacterModel and is_instance_valid(m) and m.look is Dictionary and not m.look.is_empty():
			n += 1
			var hs = String(m.look.get("hair_style", ""))
			if CharacterModel.AnimeHair.has(hs): anime += 1
			if String(CharacterModel.HAIR_GENDER.get(hs, "")) not in ["", String(m.look.get("gender", "m"))]: wrong += 1
			cnt[hs] = int(cnt.get(hs, 0)) + 1
			if hs == "kısa" and n < 400: print("KISA ", m.get_parent().name, " own=", m.look.get("own_hair"), " npc=", m.look.get("npc"), " keep=", m.look.get("keep_hair"), " g=", m.look.get("gender"), " head=", m.head_ab.size)
	print("NPCH models=", n, " anime=", anime, " wrong_gender=", wrong, " player=", main.player.model.look.get("hair_style"))
	print("NPCH styles=", cnt)
	var cam = get_viewport().get_camera_3d()
	await main.shot("npc_hair_village")
	get_tree().quit()
