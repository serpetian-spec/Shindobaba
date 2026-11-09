extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "age": "adult", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "s2", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	Hud.show_game_hud(false)
	var ids = ["akatsuki_sapkasi", "hiruzen_migferi", "orgu_bere", "ichiraku_kepi", "bas_ortusu"]
	var ms = []
	for i in ids.size():
		var it = Gear.ITEMS[ids[i]]
		var lk = Game.profile["look"].duplicate()
		for k in it["look"]:
			lk[k] = it["look"][k]
		lk["headgear"] = it["c1"]
		var m = CharacterModel.new()
		get_tree().current_scene.add_child(m)
		m.setup(lk)
		m.global_position = main.player.global_position + Vector3(i * 6.0, 0, -4)
		m.rotation.y = PI
		ms.append(m)
	main.player.visible = false
	await get_tree().create_timer(0.8).timeout
	var cam = Camera3D.new()
	get_tree().current_scene.add_child(cam)
	cam.fov = 30
	cam.current = true
	for i in ids.size():
		var hb = ms[i].skel.find_bone("Head")
		var c: Vector3 = (ms[i].skel.global_transform * ms[i].skel.get_bone_global_pose(hb)).origin
		for v in [["on", Vector3(0, 0.1, 2.0)], ["ceyrek", Vector3(1.4, 0.15, 1.4)], ["yan", Vector3(2.0, 0.1, 0)], ["arka", Vector3(0, 0.3, -2.0)]]:
			cam.global_position = c + v[1]
			cam.look_at(c)
			await get_tree().create_timer(0.3).timeout
			await main.shot("h5_%s_%s" % [ids[i], v[0]])
	get_tree().quit()
