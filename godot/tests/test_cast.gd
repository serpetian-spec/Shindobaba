extends Node
## Jutsu atma koreografisi testi: mühür yakın çekimleri + her atma stilinin hazırlık/salınım anı.
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	Game.world.env.time_of_day = 0.42
	Game.profile["level"] = 20
	pl.chakra = 9999.0
	pl.max_chakra = 9999.0
	await get_tree().create_timer(3.0).timeout
	var cam: Camera3D = pl.cam
	pl.set_process(false)  # kamera elle
	# 1) mühür yakın çekimleri: tüm 12 mühür + klon
	var seal_list = ["Ne", "Ushi", "Tora", "U", "Tatsu", "Mi", "Uma", "Hitsuji", "Saru", "Tori", "Inu", "I"]
	Data.jutsu["_test_seals"] = {"id": "_test_seals", "name": "Test", "cost": 0, "cd": 0, "element": "", "seals": seal_list}
	var a = CastAnim.play(pl, "_test_seals")
	for i in seal_list.size():
		var target_t = (i + 0.7) * a.per
		while a.t < target_t and is_instance_valid(a):
			await get_tree().process_frame
		Engine.time_scale = 0.0
		_frame_close(cam, pl)
		await get_tree().process_frame
		await main.shot("c_seal_%02d_%s" % [i, seal_list[i]])
		Engine.time_scale = 1.0
	await get_tree().create_timer(1.0).timeout
	# 2) atma stilleri
	for pair in [["katon_goukakyuu", "breath"], ["fuuton_daitoppa", "breath2"], ["bone_bullets", "palm"], ["suiton_suikoudan", "two_palm"], ["doton_doryuheki", "ground"],
			["raiton_chidori", "charge"], ["rasengan", "charge2"], ["kuchiyose", "summon"], ["baika", "power"], ["shousen", "medical"], ["chakra_chains", "scroll"], ["henge", "spin"]]:
		var jid: String = pair[0]
		var an = CastAnim.play(pl, jid)
		var mid_t = an.seal_end + (an.release_t - an.seal_end) * 0.8
		while an.t < mid_t and is_instance_valid(an):
			await get_tree().process_frame
		Engine.time_scale = 0.0
		_frame_body(cam, pl)
		await get_tree().process_frame
		await main.shot("c_%s_hazirlik" % pair[1])
		Engine.time_scale = 1.0
		while is_instance_valid(an) and an.t < an.release_t + 0.1:
			await get_tree().process_frame
		Engine.time_scale = 0.0
		await get_tree().process_frame
		await main.shot("c_%s_salinim" % pair[1])
		Engine.time_scale = 1.0
		while is_instance_valid(an):
			await get_tree().process_frame
		await get_tree().create_timer(0.3).timeout
	print("CAST TEST OK")
	get_tree().quit()


func _frame_close(cam: Camera3D, pl: Node3D) -> void:
	var fwd = pl.face_dir()
	var c = pl.global_position + Vector3.UP * 1.3 * pl.model.age_scale
	cam.global_position = c + fwd * 0.9 + pl.global_transform.basis.x * 0.25 + Vector3.UP * 0.1
	cam.look_at(c)


func _frame_body(cam: Camera3D, pl: Node3D) -> void:
	var fwd = pl.face_dir()
	var side = fwd.cross(Vector3.UP).normalized()
	var c = pl.global_position + Vector3.UP * 0.9 * pl.model.age_scale
	cam.global_position = c + fwd * 2.2 + side * 1.6 + Vector3.UP * 0.4
	cam.look_at(c)
