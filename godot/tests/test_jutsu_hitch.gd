extends Node
## Yetenek takılması: jutsuları art arda iki kez atar; her atıştan sonraki 2,5 sn'de en uzun karenin FPS karşılığını yazar.
## İlk atış ikinciye göre çok düşükse kök "ilk kullanım hazırlığı" (gölgelendirici / doku / ağ kurulumu). JH_N: kaç jutsu
var main: Node


func _worst(sec: float) -> float:
	var w = 0
	var t0 = Time.get_ticks_usec()
	var last = t0
	while Time.get_ticks_usec() - t0 < sec * 1000000.0:
		await get_tree().process_frame
		var t = Time.get_ticks_usec()
		w = maxi(w, t - last)
		last = t
	return 1000000.0 / maxf(w, 1.0)


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await get_tree().create_timer(5.0).timeout
	Hud.close_dialog()
	var pl = main.player
	var v = Game.village("konoha")
	var q = Game.from_map(Vector2(float(v["x"]) + float(v["r"]) + 300.0, float(v["y"])))
	q.y = Game.ground_height(q.x, q.z) + 1.0
	pl.global_position = q
	Game.profile["kd_wait"] = 99999.0
	await get_tree().create_timer(10.0).timeout
	var dummy = preload("res://scripts/actors/dummy.gd").new()
	main.add_child(dummy)
	dummy.global_position = pl.global_position + Vector3(0, 0, -9)
	await get_tree().create_timer(1.5).timeout
	print("JH bos FPS (en dusuk): %.0f" % await _worst(3.0))
	var ids = OS.get_environment("JH_IDS").split(",", false) if OS.get_environment("JH_IDS") != "" else PackedStringArray(["katon_goukakyuu", "katon_housenka", "suiton_suiryuudan", "fuuton_daitoppa", "doton_doryuheki", "raiton_chidori", "rasengan", "kage_bunshin", "bunshin", "kawarimi", "kuchiyose", "suiton_suijinheki", "katon_karyuu", "shousen"])
	var rows := []
	for id in ids:
		if not Data.jutsu.has(id):
			print("JH yok: ", id)
			continue
		var r := [id]
		for k in 2:
			pl.chakra = 99999.0
			pl.global_position = q
			pl.velocity = Vector3.ZERO
			Jutsu.execute(pl, id, dummy)
			r.append(await _worst(2.5))
			await get_tree().create_timer(1.0).timeout
		rows.append(r)
		print("JH %-22s ilk atis en dusuk %3.0f FPS | ikinci atis en dusuk %3.0f FPS" % [r[0], r[1], r[2]])
	print("JH bitti")
	get_tree().quit()
