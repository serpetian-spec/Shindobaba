extends Node
## Büyük dünya testi: yükleme süresi, bellek, önemli yerlerin görüntüleri, yol boyunca koşarken kare süreleri.
var main: Node


func _shot_at(pl, m: Vector2, yaw: float, pitch: float, dist: float, name: String, wait := 2.5, h_off := 0.0) -> void:
	var p = Game.from_map(m)
	p.y = maxf(p.y, 0.0) + h_off
	pl.respawn(p)
	pl.yaw = yaw
	pl.pitch = pitch
	pl.cam_dist = dist
	await get_tree().create_timer(wait).timeout
	await main.shot(name)


func _ready() -> void:
	await get_tree().process_frame
	print("YUKLEME_SURESI_s=", Time.get_ticks_msec() / 1000.0)
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	Game.world.env.time_of_day = 0.42
	var kv = Game.village("konoha")
	var ame = Game.village("ame")
	var d = Vector2(kv["x"], kv["y"]).distance_to(Vector2(ame["x"], ame["y"]))
	print("KONOHA_AME_m=", d, " kosu_s=", d / 11.0, " sprint_s=", d / 19.0)
	var suna = Game.village("suna")
	var ds = Vector2(kv["x"], kv["y"]).distance_to(Vector2(suna["x"], suna["y"]))
	print("KONOHA_SUNA_m=", ds, " sprint_dk=", ds / 19.0 / 60.0)
	print("BELLEK_MB static=", Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, " vram=", Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0)
	# 1) Konoha'dan Hokage kayasına bakış
	var hk = kv.get("hokage_rock", {"y": kv["y"] + 1100})
	await _shot_at(pl, Vector2(kv["x"], float(hk["y"]) - 700), 0.0, 8.0, 6.0, "s1_hokage_kayasi", 4.0)
	# 2) Konoha dışı orman (dev ağaçlar)
	await _shot_at(pl, Vector2(kv["x"] + 2600, kv["y"] - 400), 30.0, 10.0, 7.0, "s2_ates_ormani", 5.0)
	# 3) yol + trafik
	var rd: Dictionary = Game.roads[0]
	var rp: Vector2 = rd["pts"][4]
	await _shot_at(pl, rp, 0.0, -8.0, 9.0, "s3_yol", 5.0)
	# 4) en yakın POI'ler
	var kinds_done = {}
	for poi in Game.pois:
		if kinds_done.has(poi["t"]) or kinds_done.size() >= 5:
			continue
		if not poi["t"] in ["hamlet", "camp", "inn", "monument", "checkpoint"]:
			continue
		kinds_done[poi["t"]] = true
		await _shot_at(pl, Vector2(poi["x"], poi["y"] - 45.0), 0.0, -14.0, 10.0, "s4_poi_" + poi["t"], 5.0)
	# 5) Sonun Vadisi
	var ve = Game.village("valley_end")
	await _shot_at(pl, Vector2(ve["x"], ve["y"] + 150), 0.0, 12.0, 6.0, "s5_sonun_vadisi", 4.0)
	# 6) Suna (köy akışla kurulur)
	await _shot_at(pl, Vector2(suna["x"], suna["y"] - float(suna["r"]) * 0.6), 0.0, 8.0, 7.0, "s6_suna", 9.0)
	var kumo = Game.village("kumo")
	await _shot_at(pl, Vector2(kumo["x"], kumo["y"] - float(kumo["r"]) * 0.7), 0.0, 14.0, 7.0, "s7_kumo", 9.0)
	# 7) uzaktan köy silueti + ufuk
	await _shot_at(pl, Vector2(kumo["x"], kumo["y"] - 7000), 0.0, 4.0, 7.0, "s8_ufuk_kumo", 4.0, 80.0)
	# 8) kare süreleri: yol boyunca sprint hızında ilerle (19 m/s)
	var pts: PackedVector2Array = Game.roads[2]["pts"]
	var pos = pts[1]
	var seg = 1
	var times: Array = []
	var spikes = 0
	var worst = 0.0
	pl.respawn(Game.from_map(pos))
	await get_tree().create_timer(3.0).timeout
	var last = Time.get_ticks_usec()
	for f in 1200:
		var target: Vector2 = pts[mini(seg + 1, pts.size() - 1)]
		var step = 19.0 / 60.0
		var dv = target - pos
		if dv.length() < step and seg < pts.size() - 2:
			seg += 1
		pos += dv.normalized() * step
		var g = Game.from_map(pos)
		g.y = maxf(g.y, 0.0)
		pl.global_position = g
		pl.velocity = Vector3.ZERO
		await get_tree().process_frame
		var now = Time.get_ticks_usec()
		var ms = (now - last) / 1000.0
		last = now
		times.append(ms)
		worst = maxf(worst, ms)
		if ms > 25.0:
			spikes += 1
	times.sort()
	print("PERF frames=", times.size(), " p50=", times[times.size() / 2], " p99=", times[int(times.size() * 0.99)], " max=", worst, " >25ms=", spikes)
	print("BELLEK_MB_SON static=", Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, " vram=", Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, " nodes=", Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	get_tree().quit()
