extends Node
## Yedi kılıç elde (beklerken): yüz açık mı — önden ve yandan
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
	var base = pl.global_position + Vector3(0, 0, -10)
	base.y = Game.ground_height(base.x, base.z)
	var ids = MistSwords.IDS
	for i in ids.size():
		var L = CharacterModel.default_look()
		L["weapon_r"] = ids[i]
		if ids[i] == "kiba":
			L["weapon_l"] = "kiba"
		var m = CharacterModel.new()
		main.add_child(m)
		m.setup(L)
		m.global_position = base + Vector3((i - 3) * 2.8, 0, 0)
		m.rotation.y = PI
		m.set_drawn(true, false)
		m.play("idle", 0.0)
	await get_tree().create_timer(1.5).timeout
	pl.cam.global_position = base + Vector3(0, 1.5, 11)
	pl.cam.look_at(base + Vector3(0, 1.3, 0))
	await main.shot("hold_all_front")
	pl.cam.global_position = base + Vector3(-6, 1.6, 7)
	pl.cam.look_at(base + Vector3(-1.5, 1.3, 0))
	await main.shot("hold_all_angle")
	get_tree().quit()
