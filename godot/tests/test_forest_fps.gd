extends Node
## Orman kare hızı: köy içi / orman halkası / orman derini — kare süresi, üçgen, çizim çağrısı, ekran belleği; ağaç modellerinin üçgen sayısı
var main: Node


func _tris(m) -> int:
	if m == null:
		return 0
	var n = 0
	for s in (m as Mesh).get_surface_count():
		var a = (m as Mesh).surface_get_arrays(s)
		var idx = a[Mesh.ARRAY_INDEX]
		n += (idx.size() if idx != null and idx.size() > 0 else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return n


func _measure(tag: String, yaw: float) -> void:
	var pl = main.player
	pl.yaw = yaw
	await get_tree().create_timer(1.0).timeout
	var t0 = Time.get_ticks_usec()
	var n = 0
	var worst = 0.0
	var prim = 0.0
	var draws = 0.0
	var objs = 0.0
	var last = t0
	while Time.get_ticks_usec() - t0 < 3000000:
		await get_tree().process_frame
		var now = Time.get_ticks_usec()
		worst = maxf(worst, (now - last) / 1000.0)
		last = now
		n += 1
		prim += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		draws += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		objs += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	var ms = (Time.get_ticks_usec() - t0) / 1000.0 / n
	print("FF    gpu %.1f ms, cpu %.1f ms" % [RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()), RenderingServer.viewport_get_measured_render_time_cpu(get_viewport().get_viewport_rid())])
	var mb = 1048576.0
	print("FF %s: %.1f ms (%.0f fps) worst %.0f ms | tris %.2f M | draws %.0f | objs %.0f | vram %.0f MB (tex %.0f, buf %.0f)" % [tag, ms, 1000.0 / ms, worst, prim / n / 1e6, draws / n, objs / n,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / mb, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) / mb,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_BUFFER_MEM_USED) / mb])


func _go(at: Vector3) -> void:
	var q = Missions.open_ground(at, 40.0)
	q.y = Game.ground_height(q.x, q.z) + 0.5
	main.player.global_position = q
	main.player.velocity = Vector3.ZERO
	await get_tree().create_timer(float(OS.get_environment("FFW")) if OS.get_environment("FFW") != "" else 14.0).timeout


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "eye": Color(0.2, 0.4, 0.9), "skin": Color(0.96, 0.8, 0.66)}
	main._start_new_game()
	Hud.show_game_hud(false)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	await get_tree().create_timer(4.0).timeout
	Hud.close_dialog()
	Game.world.env.time_of_day = 0.45
	Game.world.env.weather_t = 999
	WorldDay.auto = false
	Game.profile["kd_wait"] = 99999.0
	var veg = Game.world.vegetation
	for t in [0, 1, 9, 5, 8, 10, 15]:
		var fl = []
		for v in veg.meshes[t]:
			fl.append(_tris(v[0]))
		print("FF mesh t=", t, " full=", fl, " lod=", _tris(veg.lods[t]), " far=", _tris(veg.fars[t]))
	print("FF settings=", Game.settings, " win=", get_window().size)
	var v = Game.village("konoha")
	var c = Game.from_map(Vector2(float(v["x"]), float(v["y"])))
	var r = float(v["r"])
	if OS.get_environment("FFX") != "":
		var dir2 = Vector3(0.7, 0, -0.7)
		await _go(c + dir2 * (r + 2500.0))
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
		if OS.get_environment("FFX") == "q":
			for q in [2, 1, 0]:
				Game.set_quality(q)
				await get_tree().create_timer(6.0).timeout
				await _measure("kalite %d" % q, 0.0)
				await main.shot("ff_q%d" % q)
			print("FF done")
			get_tree().quit()
			return
		if OS.get_environment("FFQ") != "":
			Game.set_quality(int(OS.get_environment("FFQ")))
			await get_tree().create_timer(6.0).timeout
		await _measure("X taban", 0.0)
		RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
		await _measure("X golge suzgec dusuk", 0.0)
		RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD)
		await _measure("X golge suzgec sert", 0.0)
		RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
		var so = []
		for k in veg.chunks:
			for ch in veg.chunks[k]["node"].get_children():
				if ch is MultiMeshInstance3D and ch.cast_shadow == 3:
					ch.visible = false
					so.append(ch)
		await _measure("X agac golge aticilari gizli", 0.0)
		var om = StandardMaterial3D.new()
		for ch in so:
			ch.visible = true
			ch.material_override = om
		await _measure("X agac golgesi opak malzeme", 0.0)
		await main.shot("ff_opak")
		for ch in so:
			ch.material_override = null
		await get_tree().create_timer(0.5).timeout
		await main.shot("ff_normal")
		Game.world.env.post.visible = false
		await _measure("X cizgi (outline) kapali", 0.0)
		Game.world.env.post.visible = true
		var vp = get_viewport()
		vp.scaling_3d_scale = 0.5
		await _measure("X cozunurluk yari", 0.0)
		vp.scaling_3d_scale = 1.0
		var sun: DirectionalLight3D = null
		for n in get_tree().root.find_children("*", "DirectionalLight3D", true, false):
			if n.shadow_enabled:
				sun = n
		if sun:
			print("FF sun shadow max=", sun.directional_shadow_max_distance, " mode=", sun.directional_shadow_mode)
			sun.shadow_enabled = false
			await _measure("X golge kapali", 0.0)
			sun.shadow_enabled = true
		var hid = []
		for k in veg.chunks:
			for ch in veg.chunks[k]["node"].get_children():
				if ch is MultiMeshInstance3D and ch.visibility_range_begin >= 690.0:
					ch.visible = false
					hid.append(ch)
		await _measure("X uzak (700+) gizli", 0.0)
		for k in veg.chunks:
			for ch in veg.chunks[k]["node"].get_children():
				if ch is MultiMeshInstance3D and ch.visibility_range_begin >= 270.0 and ch.visible:
					ch.visible = false
					hid.append(ch)
		await _measure("X orta+uzak (280+) gizli", 0.0)
		for k in veg.chunks:
			veg.chunks[k]["node"].visible = false
		await _measure("X bitki ortusu tamamen gizli", 0.0)
		for k in veg.chunks:
			veg.chunks[k]["node"].visible = true
		for h in hid:
			h.visible = true
		var we = get_tree().root.find_children("*", "WorldEnvironment", true, false)
		if not we.is_empty():
			var e: Environment = we[0].environment
			print("FF env ssao=", e.ssao_enabled, " ssil=", e.ssil_enabled, " sdfgi=", e.sdfgi_enabled, " glow=", e.glow_enabled, " volfog=", e.volumetric_fog_enabled, " ssr=", e.ssr_enabled, " msaa=", vp.msaa_3d, " scale=", vp.scaling_3d_scale)
		print("FF done")
		get_tree().quit()
		return
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	await _go(c + Vector3(-120, 0, -120))
	await _measure("koy ici", 0.0)
	await _measure("koy ici 2", PI)
	# orman halkası: kapısız bir yön (kuzeydoğu)
	var dir = Vector3(0.7, 0, -0.7)
	await _go(c + dir * (r + 330.0))
	var cnt = {}
	for k in veg.chunks:
		for ch in veg.chunks[k]["node"].get_children():
			if ch is MultiMeshInstance3D and ch.multimesh != null:
				var key = "%d tris, cast=%d, vis %d-%d" % [_tris(ch.multimesh.mesh), ch.cast_shadow, int(ch.visibility_range_begin), int(ch.visibility_range_end)]
				cnt[key] = int(cnt.get(key, 0)) + ch.multimesh.instance_count
	var keys = cnt.keys()
	keys.sort_custom(func(a, b): return cnt[a] > cnt[b])
	for k in keys.slice(0, 22):
		print("FF   mm ", cnt[k], " x ", k)
	await _measure("orman halkasi (disari bakis)", atan2(-dir.x, -dir.z))
	await _measure("orman halkasi (koye bakis)", atan2(dir.x, dir.z))
	await main.shot("ff_forest")
	await _go(c + dir * (r + 2500.0))
	await _measure("orman derin", 0.0)
	await _measure("orman derin 2", PI * 0.5)
	print("FF done")
	get_tree().quit()
