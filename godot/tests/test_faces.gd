extends Node
## Yüz hatları: aynı hazır yüzden farklı yüzler (önden + yandan), kadın / erkek / çocuk
var main: Node
var made := []

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _mk(at: Vector3, yaw: float, extra: Dictionary) -> CharacterModel:
	var lk = {"gender": "m", "hair_style": "kel", "hair": Color(0.12, 0.1, 0.1), "top": Color(0.2, 0.3, 0.5), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.4, 0.75), "band": null, "age": "adult"}
	lk.merge(extra, true)
	var m = CharacterModel.new()
	main.add_child(m)
	m.setup(lk)
	m.global_position = at
	m.rotation.y = yaw
	made.append(m)
	return m

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.1, 0.1, 0.12), "skin": Color(0.95, 0.8, 0.68), "eye": Color(0.2, 0.4, 0.8)}
	main._start_new_game()
	await _w(3.0)
	Hud.close_dialog()
	Hud.show_game_hud(false)
	var pl: Player = main.player
	var b0 = Missions.open_ground(pl.global_position + Vector3(0, 0, 30), 30.0) + Vector3(0, 60, 0)   # havada: arka plan gök
	pl.visible = false
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.fov = 11.0
	cc.current = true
	var sets = [["dojutsu", {"gender": "m", "face_id": 0, "face_cut": 0}, [1, 0, 4, 8]], ["goz_a", {"gender": "m", "face_id": 0, "face_cut": 0}, [0, 1, 2, 6]]]
	for st in sets:
		for m in made:
			m.queue_free()
		made.clear()
		await _w(0.1)
		var i = 0
		for cut in st[2]:
			var ex: Dictionary = (st[1] as Dictionary).duplicate()
			if cut >= 0:
				ex["eye_art"] = cut
			else:
				ex["face_id"] = -cut * 7 + 3   # NPC: her şey yüz kimliğinden
			var m = _mk(b0 + Vector3((i - 1.5) * 0.3, 0, 0), PI, ex)
			m.play("idle", 0.0)
			i += 1
		await _w(0.6)
		if st[0] == "dojutsu":
			var dk = [1, 2, 5, 6]
			for j in made.size():
				var em: ShaderMaterial = made[j].eye_mat
				em.set_shader_parameter("dojutsu", dk[j])
				em.set_shader_parameter("dojutsu_l", dk[j])
				if dk[j] == 6:
					em.set_shader_parameter("rings_r", 1.0)
					em.set_shader_parameter("rings_l", 1.0)
		var hy = made[0].eye_center_model.y * made[0].age_scale if "age_scale" in made[0] else 1.6
		var hb: Skeleton3D = made[0].skel
		var hc = b0 + Vector3(0, (hb.global_transform * hb.get_bone_global_pose(hb.find_bone("Head")).origin).y - b0.y + 0.07, 0)
		cc.global_position = hc + Vector3(0, 0, 3.4)
		cc.look_at(hc)
		await _w(0.2)
		await main.shot("yuz_%s_on" % st[0])
		if false:
			cc.global_position = hc + Vector3(-2.4, 0, 2.4)
			cc.look_at(hc)
			await _w(0.2)
			await main.shot("yuz_%s_capraz" % st[0])
			cc.global_position = hc + Vector3(-3.4, 0, 0.0)
			cc.look_at(hc)
			await _w(0.2)
			await main.shot("yuz_%s_yan" % st[0])
	get_tree().quit()
