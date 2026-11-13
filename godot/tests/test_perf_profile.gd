extends Node
## Darboğaz profili: üç yerde (Konoha içi, köy dışı çayır, derin orman) taban + sistemleri tek tek kapatarak ölçer.
## Her satır: ekran kartı süresi (ms), işlemci çizim süresi (ms), kare süresi, çizim çağrısı, üçgen, nesne.
## Pencere eşitlemesi kapalı; asıl bakılacak sayı ekran kartı süresi. PP_Q=0/1/2 kalite, PP_ONLY=koy|cayir|orman
var main: Node
var vp_rid: RID
var _tp := 0
var _td := 0
var a_proc := 0.0
var a_draw := 0.0
var a_rest := 0.0
var a_n := 0


func _on_pf() -> void:
	var t = Time.get_ticks_usec()
	if _td > 0:
		a_rest += t - _td
	_tp = t


func _on_pre() -> void:
	_td = Time.get_ticks_usec()
	if _tp > 0:
		a_proc += _td - _tp


func _on_post() -> void:
	var t = Time.get_ticks_usec()
	a_draw += t - _td
	_td = t
	a_n += 1


func _measure(tag: String) -> void:
	await get_tree().create_timer(0.8).timeout
	var t0 = Time.get_ticks_usec()
	var n = 0
	var prim = 0.0
	var draws = 0.0
	var objs = 0.0
	var gpu = 0.0
	var cpu = 0.0
	var pt = 0.0
	var ft = 0.0
	a_proc = 0.0
	a_draw = 0.0
	a_rest = 0.0
	a_n = 0
	while Time.get_ticks_usec() - t0 < 2500000:
		await get_tree().process_frame
		n += 1
		prim += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		draws += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		objs += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp_rid)
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp_rid)
		pt += Performance.get_monitor(Performance.TIME_PROCESS)
		ft += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	var ms = (Time.get_ticks_usec() - t0) / 1000.0 / n
	print("PP %-34s gpu %5.1f ms | cpu-cizim %5.1f ms | kare %5.1f ms (%3.0f fps) | islem %5.1f ms | fizik %5.1f ms | cagri %5.0f | ucgen %5.2f M | nesne %5.0f" % [tag, gpu / n, cpu / n, ms, 1000.0 / ms,
		pt / n * 1000.0, ft / n * 1000.0, draws / n, prim / n / 1e6, objs / n])
	print("PA %-34s isleyis %5.1f | cizim %5.1f | kalan(fizik+bekleme) %5.1f ms" % [tag, a_proc / maxf(a_n, 1) / 1000.0, a_draw / maxf(a_n, 1) / 1000.0, a_rest / maxf(a_n, 1) / 1000.0])


func _go(at: Vector3, yaw: float) -> void:
	var q = Missions.open_ground(at, 40.0)
	q.y = Game.ground_height(q.x, q.z) + 0.5
	main.player.global_position = q
	main.player.velocity = Vector3.ZERO
	main.player.yaw = yaw
	await get_tree().create_timer(14.0).timeout


func _set_vis(nodes: Array, on: bool) -> void:
	for n in nodes:
		if is_instance_valid(n):
			n.visible = on


func _profile(tag: String) -> void:
	var vp = get_viewport()
	await _measure(tag + " TABAN")
	if OS.get_environment("PP_FAST") != "":
		return
	var cam = vp.get_camera_3d()
	var cm = cam.cull_mask
	cam.cull_mask = 0
	await _measure(tag + " kamera hicbir sey cizmiyor")
	cam.cull_mask = cm
	var far0 = cam.far
	cam.far = 150.0
	await _measure(tag + " gorus 150 m")
	cam.far = far0
	vp.scaling_3d_scale = 0.5
	await _measure(tag + " cozunurluk yari")
	vp.scaling_3d_scale = 1.0
	# çim halısı
	var grass = []
	for g in get_tree().root.find_children("*", "MultiMeshInstance3D", true, false):
		if g.get_script() != null and String(g.get_script().resource_path).ends_with("grass.gd"):
			grass.append(g)
	_set_vis(grass, false)
	await _measure(tag + " cim kapali")
	_set_vis(grass, true)
	# güneş gölgesi
	var sun: DirectionalLight3D = null
	for n in get_tree().root.find_children("*", "DirectionalLight3D", true, false):
		if n.shadow_enabled:
			sun = n
	if sun:
		sun.shadow_enabled = false
		await _measure(tag + " golge kapali")
		sun.shadow_enabled = true
	# son işlem (dış çizgi)
	Game.world.env.post.visible = false
	await _measure(tag + " dis cizgi kapali")
	Game.world.env.post.visible = true
	# ağaç / bitki örtüsü
	var veg = Game.world.vegetation
	veg.visible = false
	await _measure(tag + " bitki ortusu kapali")
	veg.visible = true
	# kişiler
	var ppl = []
	for n in get_tree().root.find_children("*", "Node3D", true, false):
		if n is CharacterModel and n.visible and not main.player.is_ancestor_of(n):
			ppl.append(n)
	_set_vis(ppl, false)
	await _measure(tag + " kisiler gizli (%d)" % ppl.size())
	_set_vis(ppl, true)
	# kişilerin animasyonu (iskelet + karıştırıcı): görünmez olsalar da işler
	var anims = []
	for m in ppl:
		if is_instance_valid(m) and m.get("anim") != null and m.anim.active:
			m.anim.active = false
			anims.append(m)
	await _measure(tag + " kisi animasyonu durdu (%d)" % anims.size())
	for m in anims:
		if is_instance_valid(m):
			m.anim.active = true
	# kişilerin tüm işleyişi (betik + fizik + animasyon)
	var dis = []
	for m in ppl:
		if not is_instance_valid(m):
			continue
		var top: Node = m
		while top.get_parent() != null and not (top is CharacterBody3D) and top.get_parent() != get_tree().current_scene and top.get_parent().get_parent() != null and top.get_parent() is Node3D and not (top.get_parent().name in ["Actors", "World"]):
			top = top.get_parent()
			if top is CharacterBody3D:
				break
		if top.process_mode != Node.PROCESS_MODE_DISABLED:
			top.process_mode = Node.PROCESS_MODE_DISABLED
			dis.append(top)
	await _measure(tag + " kisiler tamamen durdu (%d)" % dis.size())
	for t in dis:
		if is_instance_valid(t):
			t.process_mode = Node.PROCESS_MODE_INHERIT
	# köy hayatı betiği
	var vlife = get_tree().root.find_children("*", "", true, false).filter(func(x): return x.get_script() != null and String(x.get_script().resource_path).ends_with("village_life.gd"))
	for x in vlife:
		x.set_process(false)
	await _measure(tag + " koy hayati betigi durdu (%d)" % vlife.size())
	for x in vlife:
		x.set_process(true)
	# köy yapıları (pişirilmiş köy düğümü)
	var vil = []
	for n in get_tree().root.find_children("Koy_*", "Node3D", true, false):
		if n.visible:
			vil.append(n)
	if not vil.is_empty():
		_set_vis(vil, false)
		await _measure(tag + " koy yapilari gizli")
		_set_vis(vil, true)
	# ışık havuzu (fener ışıkları) + parçacıklar
	var parts = []
	for n in get_tree().root.find_children("*", "GPUParticles3D", true, false):
		if n.visible:
			parts.append(n)
	_set_vis(parts, false)
	await _measure(tag + " parcaciklar gizli (%d)" % parts.size())
	_set_vis(parts, true)


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
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
	if OS.get_environment("PP_Q") != "":
		Game.set_quality(int(OS.get_environment("PP_Q")))
	vp_rid = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	get_tree().process_frame.connect(_on_pf)
	RenderingServer.frame_pre_draw.connect(_on_pre)
	RenderingServer.frame_post_draw.connect(_on_post)
	print("PP ayar=", Game.settings, " pencere=", get_window().size, " ic cozunurluk olcegi=", get_viewport().scaling_3d_scale)
	var v = Game.village("konoha")
	var c = Game.from_map(Vector2(float(v["x"]), float(v["y"])))
	var r = float(v["r"])
	var only = OS.get_environment("PP_ONLY")
	if OS.get_environment("PP_TOUR") != "":   # genel FPS turu: yalnız FPS yazar
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		print("FPS esitleme kipi=", DisplayServer.window_get_vsync_mode(), " ekran yenileme=", DisplayServer.screen_get_refresh_rate(), " sinir=", Engine.max_fps)
		var su = Game.village("suna")
		var spots = [["Konoha merkez", c], ["Konoha carsi", c + Vector3(0, 0, r * 0.35)], ["Antrenman sahasi", Game.from_map(Vector2(float(v["x"]) + 1050.0, float(v["y"]) + 540.0))],
			["Koy disi cayir", c + Vector3(0.7, 0, 0.7) * (r + 260.0)], ["Suna merkez", Game.from_map(Vector2(float(su["x"]), float(su["y"])))]]
		if OS.get_environment("PP_TOD") != "":
			Game.world.env.time_of_day = float(OS.get_environment("PP_TOD"))
		print("FPS gun saati=", Game.world.env.time_of_day, " isik sayisi=", get_tree().root.find_children("*", "OmniLight3D", true, false).size())
		for sp in spots:
			var q: Vector3 = sp[1]
			q.y = Game.ground_height(q.x, q.z) + 1.0
			main.player.global_position = q
			main.player.velocity = Vector3.ZERO
			await get_tree().create_timer(float(OS.get_environment("PP_TOUR"))).timeout
			var t0 = Time.get_ticks_usec()
			var n = 0
			while Time.get_ticks_usec() - t0 < 4000000:
				await get_tree().process_frame
				n += 1
			print("FPS %-18s %4.0f" % [sp[0], n * 1000000.0 / (Time.get_ticks_usec() - t0)])
		get_tree().quit()
		return
	if OS.get_environment("PP_AT") != "":   # köy merkezine göre harita ofseti "x,y" (ör. antrenman sahası 1050,560)
		var f = OS.get_environment("PP_AT").split(",")
		main.player.global_position = Game.from_map(Vector2(float(v["x"]) + float(f[0]), float(v["y"]) + float(f[1]))) + Vector3.UP
		main.player.velocity = Vector3.ZERO
		await get_tree().create_timer(16.0).timeout
		var np = 0
		for n in get_tree().root.find_children("*", "CharacterBody3D", true, false):
			if n.global_position.distance_to(main.player.global_position) < 70.0:
				np += 1
		print("PP 70 m icinde kisi govdesi: ", np)
		var grp = {}
		for m in get_tree().root.find_children("*", "Node3D", true, false):
			if not (m is CharacterModel) or main.player.is_ancestor_of(m):
				continue
			var top: Node = m
			while top.get_parent() != null and not (top is CharacterBody3D):
				top = top.get_parent()
			var key = "?" if top == null or top.get_script() == null else String(top.get_script().resource_path).get_file()
			if top == null or not (top is CharacterBody3D):
				key = "govdesiz:" + String(m.get_parent().name).left(18)
			var g = grp.get(key, [0, 0, 0, 0.0, 0])
			g[0] += 1
			if m.anim != null and m.anim.is_playing():
				g[1] += 1
			if m.skel != null and m.skel.process_mode == Node.PROCESS_MODE_DISABLED:
				g[2] += 1
			g[3] += m.global_position.distance_to(main.player.global_position)
			if m.is_visible_in_tree():
				g[4] += 1
			grp[key] = g
		for k in grp:
			print("PG %-30s adet %3d | animasyon oynuyor %3d | iskelet uykuda %3d | ort uzaklik %5.0f m | gorunur %3d" % [k, grp[k][0], grp[k][1], grp[k][2], grp[k][3] / grp[k][0], grp[k][4]])
		await _profile("SAHA")
		print("PP bitti")
		get_tree().quit()
		return
	if only == "" or only == "koy":
		await _go(c + Vector3(0, 0, r * 0.35), 0.0)
		await _profile("KOY")
	if only == "" or only == "cayir":
		await _go(c + Vector3(0.7, 0, 0.7) * (r + 260.0), 0.0)
		await _profile("CAYIR")
	if only == "" or only == "orman":
		await _go(c + Vector3(0.7, 0, -0.7) * (r + 2500.0), 0.0)
		await _profile("ORMAN")
	print("PP bitti")
	get_tree().quit()
