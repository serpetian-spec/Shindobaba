extends Node
## Düz yumruk atarken FPS: dururken / art arda vururken / sonra (köy içi ve köy dışı)
var main: Node
func _fps(sec: float, punch: bool) -> Array:
	var pl = main.player
	var t0 = Time.get_ticks_usec()
	var n = 0
	var last = t0
	var worst = 0
	var pt = 0.0
	while Time.get_ticks_usec() - t0 < sec * 1000000.0:
		await get_tree().process_frame
		var now = Time.get_ticks_usec()
		worst = maxi(worst, now - last)
		if punch and now - last > 28000:
			print("KOTU t=%.2f sn  %d FPS  action=%s step=%s" % [(now - t0) / 1000000.0, int(1000000.0 / (now - last)), str(pl.combat.action), str(pl.combat.step)])
		pt += (now - last) / 1000000.0
		last = now
		n += 1
		if punch and pt > 0.22:
			pt = 0.0
			pl.combat.attack()
	return [n * 1000000.0 / (Time.get_ticks_usec() - t0), 1000000.0 / maxf(1.0, worst)]
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await get_tree().create_timer(8.0).timeout
	Hud.close_dialog()
	var pl = main.player
	var v = Game.village("konoha")
	var c = Game.from_map(Vector2(float(v["x"]), float(v["y"])))
	var spots = {"koy ici": pl.global_position}
	for nm in spots:
		var q: Vector3 = spots[nm]
		q.y = Game.ground_height(q.x, q.z) + 1.0
		pl.global_position = q
		pl.velocity = Vector3.ZERO
		await get_tree().create_timer(6.0).timeout
		var a = await _fps(4.0, false)
		var b = await _fps(14.0, true)
		var d = await _fps(4.0, false)
		print("PUNCH %s | dururken %.0f (en kotu an %.0f) | yumruk atarken %.0f (en kotu an %.0f) | sonra %.0f (en kotu an %.0f)" % [nm, a[0], a[1], b[0], b[1], d[0], d[1]])
	get_tree().quit()
