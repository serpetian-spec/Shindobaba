extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.0).timeout
	pl.set_process(false)
	pl.visible = false
	var L = CharacterModel.default_look()
	L["eye_r"] = {"kind": 6, "lvl": 3, "id": "goz_rinnegan", "origin": "uyanis"}
	L["eye_l"] = {"kind": 6, "lvl": 3, "id": "goz_rinnegan", "origin": "uyanis"}
	var m = CharacterModel.new()
	main.add_child(m)
	m.setup(L)
	var p = pl.global_position + Vector3(0, 0, -5)
	p.y = Game.ground_height(p.x, p.z)
	m.global_position = p
	m.rotation.y = 0
	m.play("idle", 0.0)
	m.set_dojutsu_eyes(int(OS.get_environment("RR") if OS.get_environment("RR") != "" else "6"), 3, int(OS.get_environment("RL") if OS.get_environment("RL") != "" else "6"), 3)
	await get_tree().create_timer(0.6).timeout
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.fov = 30
	cam.global_position = p + Vector3(0, 1.58, -1.1)
	cam.look_at(p + Vector3(0, 1.56, 0))
	cam.current = true
	await get_tree().create_timer(0.3).timeout
	await main.shot("rinne_face")
	get_tree().quit()
