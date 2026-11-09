extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 98, "name": "T", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "s2", "hair": Color(0.2, 0.2, 0.2), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.5).timeout
	var pr = Game.profile
	Gear.grant(pr, "alin_koruyucu", "kafa", Color(0.15, 0.2, 0.45))
	for w in ["alin", "kakashi", "zabuza", "sakura", "boyun", "bel", "kol", "kusak", "bandana"]:
		pr["band_wear"] = w
		Gear.apply_look(pr)
		main.player.rebuild_model()
		await get_tree().process_frame
		var n = main.player.model.find_children("*", "MeshInstance3D", true, false).size()
		print("BAND ", w, " look_wear=", pr["look"].get("band_wear"), " band=", pr["look"].get("band") != null, " meshes=", n)
	# menü: ekipman > kafa çekmecesi (Takılış satırı kurulabiliyor mu)
	Menus._eq_slot = "kafa"
	var body = VBoxContainer.new()
	add_child(body)
	Menus._tab_wardrobe(main, body)
	await get_tree().process_frame
	var found = false
	for l in body.find_children("*", "Label", true, false):
		if "TAKI" in l.text.to_upper():
			found = true
	print("BAND menu row=", found)
	get_tree().quit()
