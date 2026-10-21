extends Node
## Dövüş testi: açık alanda düşman, kombo, ateş topu, chidori, su ejderhası; debug çıktıları + ekran görüntüleri.

var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken",
		"hair": Color(0.08, 0.08, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	Game.world.env.time_of_day = 0.45
	# Konoha'nın doğusundaki antrenman alanı (açık)
	var v := Game.village("konoha")
	var base := Game.from_map(Vector2(v["x"] + 300, v["y"] + 140))
	pl.respawn(base)
	pl.yaw = 0.0
	pl.pitch = -8.0
	pl.cam_dist = 6.0
	var e := Enemy.new()
	e.setup(Enemy.archetype("rogue", 1))
	main.actors.add_child(e)
	e.global_position = base + Vector3(0, 0, -8)
	e.home = e.global_position
	e.lose_target(999)
	e.state = "idle"
	await _wait(1.5)
	print("ENEMY pos=", e.global_position, " hp=", e.hp, " visible=", e.model.visible, " state=", e.state)
	await main.shot("c1_dusman")
	pl.chakra = 999
	for jid in ["katon_goukakyuu", "raiton_chidori", "suiton_suiryuudan", "fuuton_daitoppa", "katon_housenka"]:
		if not jid in Game.profile["learned"]:
			Game.profile["learned"].append(jid)
	pl.combat.lock_target = e
	pl.combat.begin_cast("katon_goukakyuu")
	print("cast action=", pl.combat.action, " cast_time=", pl.combat.cast_time)
	for i in 6:
		await _wait(0.15)
		print("t=", i, " action=", pl.combat.action, " projectiles=", get_tree().get_nodes_in_group("projectiles").size(), " enemy hp=", e.hp)
		if i == 3:
			await main.shot("c2_atestopu")
	await _wait(0.3)
	await main.shot("c3_patlama")
	await _wait(2.0)
	pl.combat.cooldowns.clear()
	e.hp = e.max_hp
	pl.combat.begin_cast("raiton_chidori")
	await _wait(0.5)
	await main.shot("c4_chidori")
	await _wait(0.5)
	await main.shot("c5_chidori_vurus")
	await _wait(2.0)
	pl.combat.cooldowns.clear()
	if is_instance_valid(e):
		e.hp = e.max_hp
	pl.combat.begin_cast("suiton_suiryuudan")
	await _wait(0.9)
	await main.shot("c6_su_ejderhasi")
	await _wait(1.5)
	pl.combat.cooldowns.clear()
	# yakın dövüş kombosu
	var e2 := Enemy.new()
	e2.setup(Enemy.archetype("bandit", 0))
	main.actors.add_child(e2)
	e2.global_position = pl.global_position + pl.face_dir() * 2.5
	e2.lose_target(999)
	for i in 5:
		pl.combat.attack()
		await _wait(0.2)
		pl.combat.attack()
		await _wait(0.2)
		if i == 2:
			await main.shot("c7_kombo")
	print("bandit hp=", e2.hp if is_instance_valid(e2) else -1)
	await _wait(0.5)
	pl.combat.begin_cast("fuuton_daitoppa")
	await _wait(0.6)
	await main.shot("c8_daitoppa")
	get_tree().quit()


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout
