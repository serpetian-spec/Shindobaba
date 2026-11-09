extends Node
## Kage şapkası tam kontrol: köy x (saç, cinsiyet) x 7 açı
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "age": "adult", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "s2", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	Hud.show_game_hud(false)
	var vids = OS.get_environment("KH_VIDS").split(",") if OS.get_environment("KH_VIDS") != "" else PackedStringArray(["konoha"])
	var combos = [["m", "s2"], ["f", "f2"], ["m", "s8"]]
	var ms = []
	var tags = []
	var i = 0
	for v in vids:
		for cb in combos:
			var lk = Game.profile["look"].duplicate()
			lk["gender"] = cb[0]; lk["hair_style"] = cb[1]; lk["own_hair"] = true
			lk["head_style"] = "kage"; lk["kage_vid"] = v
			var m = CharacterModel.new()
			get_tree().current_scene.add_child(m)
			m.setup(lk)
			m.global_position = main.player.global_position + Vector3(i * 6.0, 0, -4)
			m.rotation.y = PI
			ms.append(m); tags.append("%s_%s" % [v, cb[1]])
			i += 1
	main.player.visible = false
	await get_tree().create_timer(1.0).timeout
	var cam = Camera3D.new()
	get_tree().current_scene.add_child(cam)
	cam.fov = 30
	cam.current = true
	var views = [Vector3(0, 0.05, 1), Vector3(0.7, 0.1, 0.7), Vector3(1, 0.05, 0), Vector3(0, 0.05, -1), Vector3(-0.6, 0.15, -0.75), Vector3(0.05, 1.0, -0.15), Vector3(0, 0.9, -0.9)]
	for k in ms.size():
		var hb = ms[k].skel.find_bone("Head")
		var c: Vector3 = (ms[k].skel.global_transform * ms[k].skel.get_bone_global_pose(hb)).origin + Vector3(0, -0.02, 0)
		for vi in views.size():
			var dv: Vector3 = views[vi].normalized()
			dv = -(ms[k].global_transform.basis * dv); dv.y = -dv.y
			cam.global_position = c + dv * 2.0
			cam.look_at(c, Vector3.UP if absf(dv.y) < 0.9 else Vector3.FORWARD)
			await get_tree().create_timer(0.25).timeout
			await main.shot("k3_%s_%d" % [tags[k], vi])
	get_tree().quit()
