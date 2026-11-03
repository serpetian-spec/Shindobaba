extends Node
## Pençe sağ el aday yönleri: her aday için sağ ve sol el yakın çekim
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(1.0).timeout
	Gear.grant(Game.profile, "pence", "sag")
	Gear.apply_look(Game.profile)
	pl.rebuild_model()
	await get_tree().create_timer(2.5).timeout
	Hud.show_game_hud(false)
	Game.profile["weapon_drawn"] = true
	pl.model.set_drawn(true, false)
	await get_tree().create_timer(1.5).timeout
	pl.set_physics_process(false)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.fov = 35
	var fw = pl.face_dir()
	var sd = fw.cross(Vector3.UP)
	var cands = {"cur": Basis(Vector3.UP, PI), "rz": Basis(Vector3.BACK, PI), "rx": Basis(Vector3.RIGHT, PI), "id": Basis.IDENTITY}
	var L = null
	for w in pl.model.weapons:
		if w["side"] == "Left":
			L = (w["node"] as Node3D).global_transform.basis
	for k in cands:
		for w in pl.model.weapons:
			if w["side"] == "Right":
				var n3: Node3D = (w["node"] as Node3D).get_child(0)
				n3.transform.basis = cands[k]
				var B = n3.global_transform.basis
				var m = func(v: Vector3) -> Vector3: return v - 2.0 * v.dot(sd) * sd
				print("CAND ", k, " det=", snappedf(B.determinant(), 0.01), " x=", snappedf(B.x.normalized().dot(m.call(L.x.normalized())), 0.01), " y=", snappedf(B.y.normalized().dot(m.call(L.y.normalized())), 0.01), " z=", snappedf(B.z.normalized().dot(m.call(L.z.normalized())), 0.01))
	print("LDET ", L.determinant())
	get_tree().quit()
	return
	for k in cands:
		for w in pl.model.weapons:
			if w["side"] == "Right":
				(w["node"] as Node3D).get_child(0).transform.basis = cands[k]
		await get_tree().process_frame
		for w in pl.model.weapons:
			var hp = (w["hand"] as Node3D).global_position
			var i = 0
			for o in [fw * 0.7, sd * 0.7 * (1.0 if w["side"] == "Left" else -1.0)]:
				cam.global_position = hp + o
				cam.look_at(hp)
				await get_tree().process_frame
				await main.shot("p_%s_%s_%d" % [k, w["side"], i])
				i += 1
	get_tree().quit()
