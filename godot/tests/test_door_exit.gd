extends Node
## Konoha'daki tüm girilebilir kapılara gir-çık: çıkış noktası kapıya yakın ve yerde mi?
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	var vid = "konoha"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--village="):
			vid = a.substr(10)
	var vv = Game.village(vid)
	main.player.respawn(Game.from_map(Vector2(vv["x"], vv["y"])))
	await get_tree().create_timer(4.0).timeout
	var vc = Game.from_map(Vector2(vv["x"], vv["y"]))
	var seen = {}
	var doors = []
	for it in Interact.items:
		if it.get("kind", "") == "enter" and Vector2(it["pos"].x - vc.x, it["pos"].z - vc.z).length() < float(vv.get("r", 300)) * 1.6 and (String(it.get("room", "")) in ["kage", "hokage"] or doors.size() < 25) and not seen.has(String(it.get("room", "")) + str(int(it["pos"].x / 50))):
			seen[String(it.get("room", "")) + str(int(it["pos"].x / 50))] = true
			doors.append(it)
	print("DOORS ", doors.size())
	var n = 0
	for it in doors:
		if n >= 40:
			break
		n += 1
		var pl = main.player
		pl.respawn(it["pos"] + Vector3(0, 0.3, 0))
		await get_tree().create_timer(0.6).timeout
		Interiors.inst.enter(it)
		await get_tree().create_timer(1.2).timeout
		Interiors.inst.exit()
		await get_tree().create_timer(1.4).timeout
		var d = Vector2(pl.global_position.x - it["pos"].x, pl.global_position.z - it["pos"].z).length()
		var gy = Game.ground_height(pl.global_position.x, pl.global_position.z)
		var sq = PhysicsShapeQueryParameters3D.new()
		var sph = SphereShape3D.new()
		sph.radius = 0.4
		sq.shape = sph
		sq.collision_mask = 1
		sq.transform = Transform3D(Basis.IDENTITY, pl.global_position + Vector3.UP * 1.0)
		var stuck = not pl.get_world_3d().direct_space_state.intersect_shape(sq, 1).is_empty()
		var bad = d > 20.0 or pl.global_position.y - gy > 6.0 or stuck
		if String(it.get("room", "")) in ["kage", "hokage"]:
			pl.set_process(false)
			pl.cam.global_position = pl.global_position - pl.face_dir() * 16.0 + Vector3.UP * 9.0
			pl.cam.look_at(pl.global_position + Vector3.UP * 1.2)
			await get_tree().create_timer(0.2).timeout
			await main.shot("kage_exit_" + vid)
			pl.set_process(true)
		print("DOOR %s stuck=%s %s room=%s out=%s dist=%.1f above_ground=%.1f %s" % ["BAD" if bad else "ok", stuck, it.get("label", ""), it.get("room", ""), it.get("out", "-"), d, pl.global_position.y - gy, pl.global_position])
	get_tree().quit()
