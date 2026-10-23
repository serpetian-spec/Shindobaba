extends Node
## Jutsu efekt vitrini: her element × şekil, uçuşta ve çarpmada ekran görüntüsü (yandan kamera).
## Kullanım: --test=res://tests/test_vfx_storm.gd --shots=<klasör>   (isteğe bağlı: --only=id1,id2)
var main: Node
var cam: Camera3D
var dummy: Node3D
var worst := 0.0   # yayın sırasında en uzun kare (ms)


func _process(dt: float) -> void:
	worst = maxf(worst, dt * 1000.0)

const SET := [
	["katon_goukakyuu", 0.35, 0.95], ["katon_housenka", 0.3, 0.9], ["katon_karyuu", 0.5, 1.0],
	["suiton_suiryuudan", 0.7, 1.6], ["suiton_suikoudan", 0.3, 0.8], ["suiton_suijinheki", 0.4, 1.0],
	["fuuton_daitoppa", 0.15, 0.45], ["fuuton_shinkuu", 0.15, 0.4], ["fuuton_rasenshuriken", 0.35, 0.9],
	["doton_doryuheki", 0.3, 0.9], ["doton_doryuusou", 0.3, 0.6], ["raiton_chidori", 0.4, 0.95],
	["rasengan", 0.45, 1.0], ["raiton_nagashi", 0.1, 0.35],
	["katon_goka_senpu", 0.5, 1.2], ["suiton_bakusui_shoha", 0.4, 0.9], ["raiton_kangekiha", 0.2, 0.5],
	["doton_doryudan", 0.5, 1.2], ["yoton_kaisekifu_no_jutsu", 0.3, 0.8], ["hyoton_suishoheki", 0.3, 0.8],
	["futon_senpuken", 0.4, 1.0], ["suiton_suidanha", 0.3, 0.7], ["hissatsu_hyoso", 0.25, 0.6],
	["mokuton_mokuryu_no_jutsu", 0.5, 1.2], ["katon_bakufu_ranbu", 0.4, 0.9],
	["kirin", 1.0, 1.9], ["katon_goryuka_no_jutsu", 0.6, 1.3], ["suiro_no_jutsu", 0.5, 1.5], ["suiton_daibakufu_no_jutsu", 0.5, 1.4],
	["shinra_tensei", 0.15, 0.4], ["raikiri", 0.4, 0.9], ["odama_rasengan", 0.6, 1.2],
	["amaterasu", 0.5, 1.5], ["tsukuyomi", 0.12, 0.6], ["kamui", 0.3, 0.8], ["hiraishin_no_jutsu", 0.05, 0.3],
	["sabaku_kyu", 0.6, 1.25], ["kibaku_nendo", 0.5, 1.2], ["jinton_genkai_hakuri_no_jutsu", 0.9, 1.2],
	["kirigakure_no_jutsu", 1.0, 2.0],  # sis kalıcı: en sonda
]


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.45
	main.world.env.region_weather = "açık"
	main.world.env.weather_t = 9999.0
	main.world.env.overcast = 0.0
	var pl = main.player
	Game.profile["level"] = 60
	pl.max_chakra = 99999.0
	pl.chakra = 99999.0
	pl.respawn(Exams.find_point(["training"]) + Vector3(0, 0.5, 6))
	await get_tree().create_timer(2.5).timeout
	var only = []
	var sample = 0
	var ids_arg = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7).split(",")
		if a.begins_with("--sample="):
			sample = int(a.substr(9))
		if a.begins_with("--ids="):
			ids_arg = a.substr(6).split(",")
	cam = Camera3D.new()
	cam.fov = 60
	main.add_child(cam)
	main.world.env.attach_post(cam)
	cam.current = true
	pl.set_process(false)
	if not ids_arg.is_empty():
		for id in ids_arg:
			await _cast(id, 0.3, 0.8)
		get_tree().quit()
		return
	if sample > 0:
		# rastgele örnek sayfası: SET dışından, erken öğrenilenlere öncelik
		var rng = RandomNumberGenerator.new()
		rng.seed = 7
		var ids = []
		for j in Data.jutsu.values():
			if j is Dictionary and j.has("id") and String(j.get("shape", "")) != "" and not j["id"] in SET.map(func(x): return x[0]):
				ids.append(j)
		ids.shuffle()
		ids.sort_custom(func(a, b): return int(a.get("learn", "") in ["academy", "scroll", "trainer"]) > int(b.get("learn", "") in ["academy", "scroll", "trainer"]))
		var pick = ids.slice(0, sample / 2)
		var rest = ids.slice(sample / 2)
		for i in sample - pick.size():
			pick.append(rest[rng.randi() % rest.size()])
		for j in pick:
			await _cast(j["id"], 0.45, 0.45, true)
		get_tree().quit()
		return
	for e in SET:
		var id: String = e[0]
		if not only.is_empty() and not id in only:
			continue
		if not Data.jutsu.has(id) and not Jutsu.has_method("j_" + id):
			print("YOK: ", id)
			continue
		await _cast(id, e[1], e[2])
	# genel efektler
	if only.is_empty() or "fx" in only:
		var p = pl.global_position + pl.face_dir() * 8.0 + Vector3.UP
		_frame(p, 9.0)
		FX.explosion(p, 1.4)
		await get_tree().create_timer(0.12).timeout
		await main.shot("vx_fx_patlama_a")
		await get_tree().create_timer(0.35).timeout
		await main.shot("vx_fx_patlama_b")
		await get_tree().create_timer(1.5).timeout
		FX.smoke_puff(p, 1.4, 16)
		FX.impact(p + Vector3(3, 0, 0), Color(1, 0.8, 0.4), 1.3)
		VFX.splash(p + Vector3(-3, -1, 0), 1.6)
		VFX.bolt(p + Vector3(0, 14, 2), p + Vector3(0, -1, 2), Color(0.55, 0.75, 1.0), 0.35, 0.4)
		await get_tree().create_timer(0.12).timeout
		await main.shot("vx_fx_karisik")
	get_tree().quit()


func _frame(center: Vector3, dist: float) -> void:
	var pl = main.player
	var side = pl.face_dir().cross(Vector3.UP).normalized()
	cam.global_position = center + side * dist + Vector3.UP * dist * 0.28 - pl.face_dir() * dist * 0.25
	cam.look_at(center)


func _cast(id: String, t1: float, t2: float, one := false) -> void:
	var pl = main.player
	pl.chakra = 99999.0
	for g in ["element_walls", "projectiles", "summons"]:
		for n in get_tree().get_nodes_in_group(g):
			n.queue_free()
	main.world.env.set_tint(Color(0, 0, 0, 0))
	pl.respawn(Exams.find_point(["training"]) + Vector3(0, 0.5, 6))
	if dummy and is_instance_valid(dummy):
		dummy.queue_free()
	dummy = preload("res://scripts/actors/dummy.gd").new()
	main.actors.add_child(dummy)
	var tp = pl.global_position + pl.face_dir() * 16.0
	tp.y = Game.ground_height(tp.x, tp.z)
	dummy.global_position = tp
	pl.combat.lock_target = dummy
	await get_tree().create_timer(0.3).timeout
	_frame(pl.global_position.lerp(tp, 0.5) + Vector3.UP * 1.5, 14.0)
	var tag = id.substr(0, 22)
	worst = 0.0
	Jutsu.execute(pl, id, dummy)
	await get_tree().create_timer(t1).timeout
	var w1 = worst   # ekran görüntüsü kaydı kareyi uzatır; ölçüm ondan önce
	if one:
		await main.shot("sm_%s" % tag)
		await get_tree().create_timer(1.2).timeout
		return
	await main.shot("vx_%s_a" % tag)
	await get_tree().create_timer(maxf(0.05, t2 - t1)).timeout
	await main.shot("vx_%s_b" % tag)
	await get_tree().create_timer(1.6).timeout
	print("VXPERF %s worst=%.1fms" % [id, w1])
	pl.global_position = pl.global_position  # yerinde kalsın
