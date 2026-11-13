extends Node
## Uzun oyun sızıntı testi: oyun hızlandırılmış akar, oyuncu köy içinde ve dışında noktalar arasında gezer.
## Her 30 sn: FPS + düğüm / nesne sayıları + en çok artan düğüm türleri. SOAK_SEC (gerçek sn), SOAK_TS (zaman ölçeği)
var main: Node
var base := {}


func _census() -> Dictionary:
	var d := {}
	var stack: Array = [get_tree().root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		var k = n.get_class()
		if n.get_script() != null:
			k = String(n.get_script().resource_path).get_file()
		d[k] = int(d.get(k, 0)) + 1
		for c in n.get_children(true):
			stack.append(c)
	return d


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await get_tree().create_timer(5.0).timeout
	Hud.close_dialog()
	var v = Game.village("konoha")
	var c = Game.from_map(Vector2(float(v["x"]), float(v["y"])))
	var r = float(v["r"])
	var spots = [c, c + Vector3(0, 0, r * 0.35), Game.from_map(Vector2(float(v["x"]) + 1050.0, float(v["y"]) + 540.0)), c + Vector3(0.7, 0, 0.7) * (r + 260.0),
		c + Vector3(-r * 0.4, 0, 0), c + Vector3(0.7, 0, -0.7) * (r + 900.0), c + Vector3(r * 0.3, 0, -r * 0.3)]
	var ts = float(OS.get_environment("SOAK_TS")) if OS.get_environment("SOAK_TS") != "" else 4.0
	var total = float(OS.get_environment("SOAK_SEC")) if OS.get_environment("SOAK_SEC") != "" else 400.0
	await get_tree().create_timer(12.0).timeout
	base = _census()
	Engine.time_scale = ts
	var t_start = Time.get_ticks_msec()
	var i = 0
	while Time.get_ticks_msec() - t_start < total * 1000.0:
		var q: Vector3 = spots[i % spots.size()]
		q.y = Game.ground_height(q.x, q.z) + 1.0
		main.player.global_position = q
		main.player.velocity = Vector3.ZERO
		i += 1
		# 26 sn bekle, son 4 sn FPS ölç (gerçek zaman)
		var t0 = Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 26000:
			await get_tree().process_frame
		t0 = Time.get_ticks_usec()
		var n = 0
		while Time.get_ticks_usec() - t0 < 4000000:
			await get_tree().process_frame
			n += 1
		var fps = n * 1000000.0 / (Time.get_ticks_usec() - t0)
		var cen = _census()
		var grow := []
		for k in cen:
			var dlt = int(cen[k]) - int(base.get(k, 0))
			if dlt >= 15:
				grow.append([dlt, k, cen[k]])
		grow.sort_custom(func(a, b): return a[0] > b[0])
		var txt = ""
		for g in grow.slice(0, 10):
			txt += " %s +%d(%d)" % [g[1], g[0], g[2]]
		print("SOAK oyun-dk %4.1f | nokta %d | FPS %3.0f | dugum %6d | yetim %5d | nesne %7d | kaynak %6d | bellek %5d MB |%s" % [(Time.get_ticks_msec() - t_start) / 60000.0 * ts, (i - 1) % spots.size(), fps,
			int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), int(Performance.get_monitor(Performance.OBJECT_COUNT)),
			int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)), int(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0), txt])
	print("SOAK bitti")
	get_tree().quit()
