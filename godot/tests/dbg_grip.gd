extends Node
## Elde tutuş yakın çekimi: WID silahı, iki el, önden/yandan/üstten; kemik konumlarına göre kamera
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
	Gear.grant(Game.profile, OS.get_environment("WID"), "sag")
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
	var sk: Skeleton3D = pl.model.skel
	for w in pl.model.weapons:
		var n: Node3D = w["node"]
		var hb0 = sk.find_bone(w["side"] + "Hand")
		var lb0 = sk.find_bone(w["side"] + "LowerArm")
		var hw = (sk.global_transform * sk.get_bone_global_pose(hb0)).origin
		var ew = (sk.global_transform * sk.get_bone_global_pose(lb0)).origin
		var inv = n.global_transform.basis.inverse()
		print("GRIP ", w["side"], " id=", w["id"], " visible=", n.is_visible_in_tree(), " node_origin_to_hand=", (inv * (hw - n.global_position)).snapped(Vector3.ONE * 0.01), " to_elbow(local)=", (inv * (ew - hw)).normalized().snapped(Vector3.ONE * 0.01), " hold=", pl.model.rig.hold)
	for w in pl.model.weapons:
		var nn: Node3D = w["node"]
		for mi in nn.find_children("*", "MeshInstance3D", true, false) + ([nn] if nn is MeshInstance3D else []):
			print("WNODE ", w["side"], " ", nn.get_class(), " mesh_aabb=", mi.mesh.get_aabb() if mi.mesh else null, " parent=", nn.get_parent().name, " basis=", nn.transform.basis)
	for w in pl.model.weapons:
		var nn: Node3D = w["node"]
		var mi: MeshInstance3D = nn if nn is MeshInstance3D else nn.get_child(0)
		var elb = pl.model._attach(w["side"] + "LowerArm", Transform3D(Basis.IDENTITY, pl.model._grest(pl.model.skel.find_bone(w["side"] + "LowerArm")).origin))
		await get_tree().process_frame
		var ew = elb.get_child(0).global_position
		var fist = mi.global_position
		var long_end = mi.global_transform * Vector3(-0.4, 0, -0.085)
		var short_end = mi.global_transform * Vector3(0.12, 0, -0.085)
		var to_elb = (ew - fist).normalized()
		var hand_pos = (w["hand"] as Node3D).global_position
		var mid = mi.global_transform * Vector3(-0.14, 0, -0.085)
		var fa = ew - hand_pos
		var off = (mid - hand_pos) - fa.normalized() * (mid - hand_pos).dot(fa.normalized())
		print("SIDE ", w["side"], " shaft_offset_from_forearm_axis=", snappedf(off.length(), 0.01), " up=", snappedf(off.normalized().dot(Vector3.UP), 0.01))
		print("DIR ", w["side"], " long_end.dot(elbow)=", snappedf((long_end - fist).normalized().dot(to_elb), 0.01), " short.dot=", snappedf((short_end - fist).normalized().dot(to_elb), 0.01), " fist-elbow=", snappedf(fist.distance_to(ew), 0.01))
	var fw = pl.face_dir()
	var sd = fw.cross(Vector3.UP)
	var c = pl.global_position + Vector3.UP * 1.0
	var vi = 0
	for o in [fw * 2.2, sd * 2.2, -sd * 2.2, fw * 1.6 + sd * 1.2]:
		cam.global_position = c + o + Vector3.UP * 0.2
		cam.look_at(c)
		await get_tree().process_frame
		await main.shot("g_body_%d" % vi)
		vi += 1
	for w in pl.model.weapons:
		var hp = (w["hand"] as Node3D).global_position
		var i = 0
		for o in [fw * 0.7, sd * 0.7 * (1.0 if w["side"] == "Left" else -1.0), Vector3.UP * 0.7 + fw * 0.1]:
			cam.global_position = hp + o
			cam.look_at(hp, Vector3.UP if absf((o as Vector3).normalized().y) < 0.9 else fw)
			await get_tree().process_frame
			await main.shot("g_%s_%d" % [w["side"], i])
			i += 1
	get_tree().quit()
