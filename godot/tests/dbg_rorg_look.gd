extends Node
## Rastgele örgüt kıyafetleri: farklı tohumlarla 4 örgütten birer üye yan yana
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.0).timeout
	pl.visible = false
	pl.set_process(false)
	Hud.show_game_hud(false)
	var i = 0
	for sd in [11, 22]:
		Game.profile["seed"] = sd
		Orgs.state().erase("rorgs")
		for o in Orgs.random_orgs():
			for k in 2:
				var m = CharacterModel.new()
				main.add_child(m)
				m.setup(Orgs._ro_look(o, o["members"][k]))
				var p = pl.global_position + Vector3(-5.6 + i * 1.6, 0, -6)
				p.y = Game.ground_height(p.x, p.z)
				m.global_position = p
				m.rotation.y = PI
				m.play("idle", 0.0)
				i += 1
			print("RL %s: %s" % [o["name"], o["dress"]])
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.fov = 40
	cam.current = true
	cam.global_position = pl.global_position + Vector3(0, 1.5, 2.5)
	cam.look_at(pl.global_position + Vector3(0, 1.1, -6))
	await get_tree().create_timer(1.0).timeout
	await main.shot("orgs_look")
	get_tree().quit()
