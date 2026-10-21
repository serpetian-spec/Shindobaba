extends Node
## Görsel duman testi: yeni oyun başlat, birkaç yerden ekran görüntüsü al, çık.

var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken",
		"hair": Color(0.08, 0.08, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	Game.world.env.time_of_day = 0.42
	var v := Game.village("konoha")
	# 1) Konoha ana caddesi, kuzeye (kuleye ve Hokage kayasına) bakış
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] - 330)))
	pl.yaw = 0.0
	pl.pitch = -6.0
	await _wait(3.0)
	await main.shot("01_konoha_cadde")
	# 2) karakter yakın çekim
	pl.cam_dist = 2.6
	pl.yaw = 160.0
	pl.pitch = -5.0
	await _wait(1.5)
	await main.shot("02_karakter")
	# 3) koşu + ninja koşusu pozu
	Input.action_press("forward")
	Input.action_press("dash")
	pl.yaw = 90.0
	pl.cam_dist = 4.0
	await _wait(1.2)
	await main.shot("03_kosu")
	Input.action_release("forward")
	Input.action_release("dash")
	# 4) dövüş: düşman + ateş topu
	var e := Enemy.new()
	e.setup(Enemy.archetype("rogue", 1))
	main.actors.add_child(e)
	e.global_position = pl.global_position + pl.cam_forward() * 9.0
	e.home = e.global_position
	pl.yaw = pl.yaw
	await _wait(0.5)
	Game.profile["learned"].append("katon_goukakyuu")
	pl.chakra = 999
	pl.combat.begin_cast("katon_goukakyuu")
	await _wait(0.75)
	await main.shot("04_goukakyuu")
	await _wait(0.4)
	await main.shot("05_patlama")
	# 5) Hokage kayası yakından + gün batımı
	Game.world.env.time_of_day = 0.71
	pl.respawn(Game.from_map(Vector2(v["x"] + 20, v["y"] + 300)))
	pl.yaw = 0.0
	pl.pitch = 10.0
	pl.cam_dist = 7.0
	await _wait(2.0)
	await main.shot("06_hokage_kayasi")
	# 6) yüksekten dünya
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + 395)) + Vector3(0, 80, 0))
	pl.yaw = 180.0
	pl.pitch = -25.0
	pl.cam_dist = 14.0
	Game.world.env.time_of_day = 0.45
	await _wait(2.5)
	await main.shot("07_kusbakisi")
	# 7) Suna
	var s := Game.village("suna")
	pl.respawn(Game.from_map(Vector2(s["x"] + 200, s["y"])) + Vector3(0, 60, 0))
	pl.yaw = 90.0
	pl.pitch = -20.0
	await _wait(2.5)
	await main.shot("08_suna")
	get_tree().quit()


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout
