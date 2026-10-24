extends Node
## Sis'in Yedi Kılıcı: yan yana dik (yassı yüz kameraya), tek tek yakın çekim + elinde tutan karakter (ölçek)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.5).timeout
	pl.set_process(false)
	var base = pl.global_position + Vector3(0, 0, -20)
	base.y = Game.ground_height(base.x, base.z)
	var only = ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
	var ids = MistSwords.IDS if only == "" else [only]
	var nodes = []
	for i in ids.size():
		var mi = MeshInstance3D.new()
		mi.mesh = CharacterModel.weapon_mesh(ids[i])
		main.add_child(mi)
		mi.global_position = base + Vector3(0, 0.9, (i - (ids.size() - 1) * 0.5) * 0.95)
		mi.rotation = Vector3(-PI * 0.5, 0, 0)   # ağız yukarı, yassı yüz +X
		nodes.append(mi)
	var cam = pl.cam
	cam.global_position = base + Vector3(4.2 if only == "" else 2.4, 1.6, 0)
	cam.look_at(base + Vector3(0, 1.4, 0))
	await get_tree().create_timer(0.4).timeout
	await main.shot("swords_row" if only == "" else "sword_" + only)
	if only == "":
		for i in ids.size():
			for n in nodes:
				n.visible = false
			nodes[i].visible = true
			cam.global_position = nodes[i].global_position + Vector3(2.3, 0.75, 0.0)
			cam.look_at(nodes[i].global_position + Vector3(0, 0.7, 0))
			await get_tree().create_timer(0.15).timeout
			await main.shot("sword_" + ids[i])
	get_tree().quit()
