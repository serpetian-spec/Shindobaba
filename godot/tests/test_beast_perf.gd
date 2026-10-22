extends Node
## Kurama dövüşü sırasında kare süreleri (+ kurama ekran görüntüsü)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Game.profile["level"] = 40
	var pl = main.player
	var lair: Vector2 = TailedBeasts.LAIRS["kurama"]
	pl.respawn(Game.from_map(lair + Vector2(0, -260)))
	await get_tree().create_timer(5.0).timeout
	var b = TailedBeasts.spawned.get("kurama")
	if b:
		var to = b.global_position - pl.global_position
		pl.yaw = rad_to_deg(atan2(-to.x, -to.z))
		pl.pitch = 8.0
		b._start_fight()
	var times = []
	for i in 360:
		await get_tree().process_frame
		times.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		if i == 120:
			await main.shot("k1_kurama")
		if i == 200 and b:
			b.atk = ""
			b._begin("ball", 0.0)
	var dts = []
	var last = Time.get_ticks_usec()
	for i in 240:
		await get_tree().process_frame
		var now = Time.get_ticks_usec()
		dts.append((now - last) / 1000.0)
		last = now
	dts.sort()
	print("BEASTPERF frame p50=%.1f p99=%.1f max=%.1f  >25ms=%d" % [dts[dts.size() / 2], dts[int(dts.size() * 0.99)], dts[-1], dts.filter(func(x): return x > 25.0).size()])
	get_tree().quit()
