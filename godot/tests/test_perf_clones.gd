extends Node
## Performans: N kişi (klon/düşman) varken kare süresi, çizim çağrısı, işlem/fizik süresi
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

var invuln := false
var spawn_t := 0
class First extends Node:
	static var span_t0 := 0
	static var span_sum := 0
	static var p0 := 0
	static var pspan := 0
	static var pspan_max := 0
	static var phys_max := 0
	func _physics_process(_d):
		span_t0 = Time.get_ticks_usec()
	func _process(_d):
		p0 = Time.get_ticks_usec()
class Last extends Node:
	func _physics_process(_d):
		var x = Time.get_ticks_usec() - First.span_t0
		First.span_sum += x
		First.phys_max = maxi(First.phys_max, x)
	func _process(_d):
		First.pspan = Time.get_ticks_usec() - First.p0
		First.pspan_max = maxi(First.pspan_max, First.pspan)
func _process(_d: float) -> void:
	if invuln and main and main.player:
		main.player.combat.invuln = 5.0

func _measure(tag: String) -> void:
	await _w(1.0)
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var n = 0
	First.span_sum = 0
	var t0 = Time.get_ticks_usec()
	var proc = 0.0
	var phys = 0.0
	var dc = 0.0
	var ft = []
	var last = Time.get_ticks_usec()
	while Time.get_ticks_usec() - t0 < 3000000:
		First.pspan_max = 0
		First.phys_max = 0
		await get_tree().process_frame
		var now = Time.get_ticks_usec()
		if (now - last) / 1000.0 > 50.0:
			print("   SPIKE t=%.2fs since_spawn process_span_max=%.0fms phys_span_max=%.0fms" % [(now - spawn_t) / 1e6, First.pspan_max / 1000.0, First.phys_max / 1000.0])
			var vp = get_viewport().get_viewport_rid()
			print("   SPIKE render_cpu=%.1fms render_gpu=%.1fms total_cpu=%.1f" % [RenderingServer.viewport_get_measured_render_time_cpu(vp), RenderingServer.viewport_get_measured_render_time_gpu(vp), RenderingServer.get_frame_setup_time_cpu()])
			print("   SPIKE %.0fms proc=%.0fms phys=%.0fms objs_new=%d draws=%d vmem=%dMB" % [(now - last) / 1000.0, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576])
		ft.append((now - last) / 1000.0)
		last = now
		n += 1
		proc += Performance.get_monitor(Performance.TIME_PROCESS)
		phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
		dc += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var fps = n / 3.0
	var spikes = ft.filter(func(x): return x > 50.0)
	var idx = []
	for i in ft.size():
		if ft[i] > 50.0:
			idx.append("%d:%.0f" % [i, ft[i]])
	print("  spike frames: ", idx)
	print("  spikes>50ms: %d max=%.0fms sum=%.0fms" % [spikes.size(), ft.max(), spikes.reduce(func(a, b): return a + b, 0.0)])
	print("  phys3d active=%d pairs=%d islands=%d" % [Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS), Performance.get_monitor(Performance.PHYSICS_3D_COLLISION_PAIRS), Performance.get_monitor(Performance.PHYSICS_3D_ISLAND_COUNT)])
	print("  callbacks span=%.2fms/frame" % [First.span_sum / 1000.0 / n])
	print("PERF %-14s fps=%.0f frame=%.1fms med=%.1fms proc=%.1fms phys=%.1fms draws=%.0f objs=%d nodes=%d" % [tag, fps, 1000.0 / fps, _med(ft), proc / n * 1000.0, phys / n * 1000.0, dc / n, Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])

func _med(a: Array) -> float:
	a.sort()
	return a[a.size() / 2]

func _ready() -> void:
	await get_tree().process_frame
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	var f1 = First.new()
	f1.process_physics_priority = -100000
	get_tree().root.add_child(f1)
	f1.process_priority = -100000
	var l1 = Last.new()
	l1.process_physics_priority = 100000
	l1.process_priority = 100000
	get_tree().root.add_child(l1)
	Engine.max_fps = 0
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl: Player = main.player
	pl.max_hp = 1e9
	pl.hp = 1e9
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(8.0)
	await _measure("base")
	await _measure("base2")
	var mode = "clones"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="):
			mode = a.substr(7)
	if mode == "cast":
		Game.profile["learned"].append("bunshin")
		pl.chakra = 9999.0
		Jutsu.execute(pl, "bunshin", null)
		await _measure("cast_bunshin")
		await _measure("cast_bunshin2")
	elif mode == "clones":
		for n in [2, 6]:
			for k in (2 if n == 2 else 4):
				var cl = ShadowClone.new()
				cl.team = pl.team
				cl.look = pl.model.look.duplicate()
				cl.life = 999.0
				var tc = Time.get_ticks_usec()
				get_tree().current_scene.add_child(cl)
				print("  spawn clone %.1fms" % ((Time.get_ticks_usec() - tc) / 1000.0))
				cl.global_position = pl.global_position + Vector3(randf_range(-4, 4), 0.5, randf_range(-4, 4))
			await _measure("clones=%d" % n)
	else:
		for n in [3, 6]:
			for k in 3:
				var a = Enemy.archetype("rogue", 0)
				a["respawn"] = false
				a["hp"] = 99999.0
				if mode == "invuln":
					invuln = true
					a["jutsu"] = []
					a["tools"] = false
				if mode == "melee":
					a["jutsu"] = []
					a["tools"] = false
				var e = Enemy.new()
				var ts = Time.get_ticks_usec()
				spawn_t = ts
				e.setup(a)
				var ts2 = Time.get_ticks_usec()
				get_tree().current_scene.add_child(e)
				print("  enemy setup=%.0fms add=%.0fms" % [(ts2 - ts) / 1000.0, (Time.get_ticks_usec() - ts2) / 1000.0])
				e.global_position = pl.global_position + Vector3(randf_range(-8, 8), 0.5, randf_range(6, 12))
				e.home = e.global_position
				if mode == "nomodel":
					e.model.visible = false
					e.model.process_mode = Node.PROCESS_MODE_DISABLED
				if mode == "nodangle":
					for dn in e.model.find_children("*", "Dangle", true, false):
						dn.queue_free()
				if mode == "nosim":
					for dn in e.model.find_children("*", "PhysicalBoneSimulator3D", true, false):
						dn.queue_free()
				if mode == "hidden":
					e.team = "player"
					e.visible = false
				if mode == "friendly" or mode == "still":
					e.team = "player"
				if mode == "still":
					e.arch["speed"] = 0.0
					e.set_meta("still", true)
				if mode == "nofcol":
					a["jutsu"] = []
					a["tools"] = false
				if mode == "frozen":
					e.set_physics_process(false)
				if mode == "nocol":
					e.collision_layer = 0
					e.collision_mask = 1
			if mode == "nofcol":
				for f in get_tree().get_nodes_in_group("fighters"):
					if f is CollisionObject3D:
						f.collision_mask = 1 | 2
			await _measure("enemies=%d" % n)
	get_tree().quit()
