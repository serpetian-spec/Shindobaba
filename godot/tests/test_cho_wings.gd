extends Node
## Kelebek Modu kanatları: önden/arkadan/yandan + karakter dönünce kanatlar da dönüyor mu

var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "akimichi", "element": "doton", "hair_style": "diken",
		"hair": Color(0.45, 0.25, 0.15), "top": Color(0.55, 0.15, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	Game.world.env.weather = "açık"
	var pl: Player = main.player
	var vs = Game.village("suna")
	var base = Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"]))
	pl.respawn(base)
	await _wait(2.0)
	Jutsu.execute(pl, "cho_modo", null)
	await _wait(1.2)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	for turn in 2:
		var c = pl.global_position + Vector3.UP * 1.3
		var fd = pl.face_dir()
		var sd = fd.cross(Vector3.UP).normalized()
		var views = {"front": fd * 6.5, "back": -fd * 6.5, "side": sd * 6.5 + fd * 1.0, "close": sd * 2.2 - fd * 0.6}
		for k in views:
			cc.global_position = c + views[k] + Vector3.UP * 0.6
			cc.look_at(c)
			cc.current = true
			Hud.close_dialog()
			await _wait(0.1)
			await main.shot("wing_%d_%s" % [turn, k])
		# karakteri 90° döndür: kanatlar birlikte dönmeli
		pl.yaw += 90.0
		if pl.model:
			pl.model.rotation.y += PI * 0.5
		await _wait(0.6)
	get_tree().quit()
