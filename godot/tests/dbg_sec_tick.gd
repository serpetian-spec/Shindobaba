extends Node
## Saniyede bir uzayan kare: o karede hangi sistem çalışıyor (instr.py ile)
var main: Node
var t_proc := 0
var t_pre := 0
var t_post := 0
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await get_tree().create_timer(14.0).timeout
	Hud.close_dialog()
	RenderingServer.frame_pre_draw.connect(func(): t_pre = Time.get_ticks_usec())
	RenderingServer.frame_post_draw.connect(func(): t_post = Time.get_ticks_usec())
	var last = Time.get_ticks_usec()
	var t0 = last
	Engine.set_meta("pf", {})
	var n = 0
	while Time.get_ticks_usec() - t0 < 14000000:
		await get_tree().process_frame
		var now = Time.get_ticks_usec()
		var d: Dictionary = Engine.get_meta("pf")
		if now - last > 24000:
			var arr = []
			for k in d:
				arr.append([d[k], k])
			arr.sort_custom(func(a, b): return a[0] > b[0])
			var txt = ""
			var sum = 0
			for a in arr:
				sum += a[0]
			for a in arr.slice(0, 6):
				txt += " %s=%d" % [a[1], a[0] / 100]
			print("TICK t=%.2f kare=%d (x0.1ms) cizim oncesi=%d cizim=%d cizim sonrasi(fizik vb)=%d" % [(now - t0) / 1000000.0, (now - last) / 100, (t_pre - last) / 100, (t_post - t_pre) / 100, (now - t_post) / 100])
			n += 1
		Engine.set_meta("pf", {})
		last = now
	print("TICK bitti, uzun kare %d" % n)
	get_tree().quit()
