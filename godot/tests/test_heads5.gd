extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "age": "adult", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "s2", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	Hud.show_game_hud(false)
	var ids = OS.get_environment("HD_IDS").split(",") if OS.get_environment("HD_IDS") != "" else PackedStringArray(["akatsuki_sapkasi"])
	var ms = []
	for i in ids.size():
		var it = Gear.ITEMS[ids[i]]
		var lk = Game.profile["look"].duplicate()
		lk["own_hair"] = true
		if OS.get_environment("HD_G") != "":
			lk["gender"] = OS.get_environment("HD_G")
			lk["hair_style"] = OS.get_environment("HD_H")
		lk["village"] = OS.get_environment("HD_V") if OS.get_environment("HD_V") != "" else "konoha"
		for k in it["look"]:
			lk[k] = it["look"][k]
		lk["headgear"] = Color(OS.get_environment("HD_COL")) if OS.get_environment("HD_COL") != "" else it["c1"]
		var m = CharacterModel.new()
		get_tree().current_scene.add_child(m)
		m.setup(lk)
		m.global_position = main.player.global_position + Vector3(i * 6.0, 0, -4)
		m.rotation.y = PI
		ms.append(m)
	main.player.visible = false
	if OS.get_environment("HD_HIDE") != "":
		for m in ms:
			for mi in m.find_children("*", "MeshInstance3D", true, false):
				if String(mi.name) in ["Body", "Cloth", "VFace"]:
					mi.visible = false
	await get_tree().create_timer(0.8).timeout
	var cam = Camera3D.new()
	get_tree().current_scene.add_child(cam)
	cam.fov = 30
	cam.current = true
	for i in ids.size():
		var hb = ms[i].skel.find_bone("Head")
		var c: Vector3 = (ms[i].skel.global_transform * ms[i].skel.get_bone_global_pose(hb)).origin
		var views = [Vector3(0, 0.05, 1), Vector3(0.7, 0.1, 0.7), Vector3(1, 0.05, 0), Vector3(0, 0.05, -1), Vector3(-0.6, 0.15, -0.75), Vector3(0.05, 1.0, -0.15), Vector3(0, 0.9, -0.9)]
		for vi in views.size():
			var dv: Vector3 = views[vi].normalized()
			dv = -(ms[i].global_transform.basis * dv); dv.y = -dv.y
			var v = ["%d" % vi]
			cam.global_position = c + dv * 2.0
			cam.look_at(c, Vector3.UP if absf(dv.y) < 0.9 else Vector3.FORWARD)
			await get_tree().create_timer(0.3).timeout
			await main.shot("h5_%s%s_%s" % [ids[i], OS.get_environment("HD_TAG"), v[0]])
	get_tree().quit()
