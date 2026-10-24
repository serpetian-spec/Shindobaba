extends Node
## Klan birimleri (kukla, mürekkep, golem, arı, böcek) yakın çekim
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	Hud.show_game_hud(false)
	var pl = main.player
	var v = Game.village("konoha")
	pl.respawn(Game.from_map(Vector2(v["x"] - 300, v["y"] - float(v["r"]) - 120)))
	await get_tree().create_timer(2.0).timeout
	var cam = Camera3D.new()
	main.add_child(cam)
	for k in (OS.get_environment("CN").split(",") if OS.get_environment("CN") != "" else ["puppet", "ink", "golem"]):
		ClanConstruct.spawn(pl, k, 1, {"tier": 3})
		await get_tree().create_timer(0.8).timeout
		var u = null
		for f in get_tree().get_nodes_in_group("fighters"):
			if f is ClanConstruct:
				u = f
		if u:
			u.set_physics_process(false)
			u.global_position = pl.global_position + pl.face_dir() * 3.0
			u.vis.rotation.y = pl.facing + PI
			var c = u.global_position + Vector3.UP * u.height * 0.55
			var fr = Basis(Vector3.UP, u.vis.rotation.y) * Vector3(0, 0, -1)
			var cd_ = maxf(3.0, u.height * 1.5)
			for side in [["on", fr * cd_], ["yan", fr.cross(Vector3.UP) * cd_ + fr * cd_ * 0.5]]:
				cam.global_position = c + side[1] + Vector3.UP * 0.3
				cam.look_at(c)
				cam.current = true
				await get_tree().create_timer(0.2).timeout
				await main.shot("cn_%s_%s" % [k, side[0]])
			u.queue_free()
		await get_tree().create_timer(0.3).timeout
	get_tree().quit()
