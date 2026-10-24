extends Node
## Ağır silah tutuşu deneme: silah düğümünü elde farklı açılarla döndürüp önden/yandan çek
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
	pl.visible = false
	var id = "samehada"
	var angs = [[0, 0], [0, 50], [0, -50], [0, -75], [25, -55], [-25, -55]]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--id="):
			id = a.substr(5)
	var base = pl.global_position + Vector3(0, 0, -10)
	base.y = Game.ground_height(base.x, base.z)
	var models = []
	for i in angs.size():
		var L = CharacterModel.default_look()
		L["weapon_r"] = id
		if id == "kiba":
			L["weapon_l"] = id
		var m = CharacterModel.new()
		main.add_child(m)
		m.setup(L)
		m.global_position = base + Vector3((i - 2.5) * 2.6, 0, 0)
		m.rotation.y = PI
		m.set_drawn(true, false)
		m.play("idle", 0.0)
		models.append(m)
	await get_tree().create_timer(0.8).timeout
	for i in angs.size():
		for w in models[i].weapons:
			var n: Node3D = w["node"]
			n.transform.basis = Basis.from_euler(Vector3(deg_to_rad(angs[i][0]), deg_to_rad(angs[i][1]), 0))
	await get_tree().create_timer(0.3).timeout
	pl.cam.global_position = base + Vector3(0, 1.4, 9)
	pl.cam.look_at(base + Vector3(0, 1.2, 0))
	await main.shot("hold_front_" + id)
	pl.cam.global_position = base + Vector3(-12, 1.6, 2.5)
	pl.cam.look_at(base + Vector3(0, 1.2, 0))
	await main.shot("hold_side_" + id)
	get_tree().quit()
