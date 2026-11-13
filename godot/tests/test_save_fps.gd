extends Node
## Kullanıcının kaydının KOPYASIYLA (kayit_97) FPS: kayıtlı konumda bekler, sonra Konoha merkez / çarşı. Kayıt boyutlarını da yazar.
var main: Node


func _fps(tag: String, wait: float) -> void:
	await get_tree().create_timer(wait).timeout
	var t0 = Time.get_ticks_usec()
	var n = 0
	while Time.get_ticks_usec() - t0 < 4000000:
		await get_tree().process_frame
		n += 1
	var cm = 0
	for x in get_tree().root.find_children("*", "Skeleton3D", true, false):
		cm += 1
	print("FPS %-22s %4.0f | dugum %d | iskelet %d" % [tag, n * 1000000.0 / (Time.get_ticks_usec() - t0), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), cm])


func _ready() -> void:
	await get_tree().process_frame
	main.load_slot(int(OS.get_environment("SF_SLOT")) if OS.get_environment("SF_SLOT") != "" else 97)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await get_tree().create_timer(4.0).timeout
	Hud.close_dialog()
	var big := []
	for k in Game.profile:
		var v = Game.profile[k]
		var sz = JSON.stringify(v).length() if (v is Dictionary or v is Array) else 0
		if sz > 4000:
			big.append([sz, k, v.size()])
	big.sort_custom(func(a, b): return a[0] > b[0])
	for b in big.slice(0, 14):
		print("KAYIT %-22s %7d harf | %5d oge" % [b[1], b[0], b[2]])
	print("KAYIT konum=", main.player.global_position, " saat=", Game.world.env.time_of_day)
	await _fps("kayitli konum", 16.0)
	var v0 = Game.village(String(Game.profile.get("village", "konoha")))
	var c = Game.from_map(Vector2(float(v0["x"]), float(v0["y"])))
	for sp in [["koy merkez", c], ["koy carsi", c + Vector3(0, 0, float(v0["r"]) * 0.35)]]:
		var q: Vector3 = sp[1]
		q.y = Game.ground_height(q.x, q.z) + 1.0
		main.player.global_position = q
		main.player.velocity = Vector3.ZERO
		await _fps(sp[0], 14.0)
	get_tree().quit()
