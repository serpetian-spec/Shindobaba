extends Node
## Performans profili: senaryolar (Konoha sokak, pazar öğlen, orman, yolda koşu, gece Konoha) için
## kare süresi, CPU/GPU süresi, çizim çağrısı, nesne, primitive; ayrıca Konoha merkezinde sistem kapatma deneyleri.
var main: Node
var pl: Player
var vp_rid: RID


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Hud.show_game_hud(true)
	pl = main.player
	vp_rid = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	Game.world.env.weather_t = 999
	Game.world.env.weather = "açık"
	var v = Game.village("konoha")
	var c = Vector2(v["x"], v["y"])
	var only = OS.get_environment("PROF_ONLY")
	if OS.get_environment("PROF_Q") != "":
		Game.set_quality(int(OS.get_environment("PROF_Q")))
	var scen = [
		["konoha_sokak", c + Vector2(420, -380), 0.4, false],
		["pazar_oglen", c + Vector2(0, -60), 0.5, false],
		["orman", c + Vector2(0, -2600), 0.4, false],
		["yol_kosu", c + Vector2(0, -1650), 0.4, true],
		["gece_konoha", c + Vector2(0, -60), 0.92, false],
	]
	for s in scen:
		if only != "" and not String(s[0]) in only.split(","):
			continue
		await _scenario(s[0], s[1], s[2], s[3])
	if only == "" or "ablation" in only:
		await _ablation(c + Vector2(0, -60))
	if "proc" in only:
		await _proc_ablation(c + Vector2(0, -2600))
		await _proc_ablation(c + Vector2(0, -60))
	get_tree().quit()


func _place(m: Vector2) -> void:
	var p = Game.from_map(m)
	p.y = Game.ground_height(p.x, p.z) + 0.1
	pl.respawn(p)


func _sample(label: String, secs: float, move := Vector3.ZERO) -> Dictionary:
	var dts = []
	var cpu = []
	var gpu = []
	var calls = 0.0; var objs = 0.0; var prims = 0.0; var proc = 0.0; var phys = 0.0
	var n = 0
	var t = 0.0
	Prof.reset()
	while t < secs:
		await get_tree().process_frame
		var dt = get_process_delta_time()
		t += dt
		pl.yaw += dt * 25.0
		if move != Vector3.ZERO:
			var np = pl.global_position + move * dt
			np.y = Game.ground_height(np.x, np.z)
			pl.global_position = np
			pl.velocity = Vector3.ZERO
		dts.append(dt * 1000.0)
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(vp_rid) + RenderingServer.get_frame_setup_time_cpu())
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(vp_rid))
		calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		objs += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
		prims += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		n += 1
	dts.sort()
	var avg = 0.0
	for x in dts:
		avg += x
	avg /= dts.size()
	var ga = 0.0; var ca = 0.0
	for x in gpu:
		ga += x
	for x in cpu:
		ca += x
	var r = {"avg": avg, "p50": dts[dts.size() / 2], "p99": dts[int(dts.size() * 0.99)], "max": dts[-1], "over25": dts.filter(func(x): return x > 25.0).size(),
		"over33": dts.filter(func(x): return x > 33.0).size(), "gpu": ga / n, "rcpu": ca / n, "calls": calls / n, "objs": objs / n, "prims": prims / n, "proc": proc / n, "phys": phys / n,
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT)}
	print("PROF %-22s avg=%5.1f p50=%5.1f p99=%5.1f max=%5.1f >25=%d >33=%d | gpu=%5.1f rcpu=%5.1f proc=%5.1f phys=%5.1f | calls=%d objs=%d prims=%dk nodes=%d" % [
		label, r.avg, r.p50, r.p99, r.max, r.over25, r.over33, r.gpu, r.rcpu, r.proc, r.phys, int(r.calls), int(r.objs), int(r.prims / 1000.0), int(r.nodes)])
	var arr = []
	for k in Prof.data:
		arr.append([Prof.data[k] / float(n) / 1000.0, k, Prof.peak[k] / 1000.0])
	arr.sort()
	arr.reverse()
	var txt = ""
	for e in arr.slice(0, 10):
		txt += "%s=%.2f(pk %.1f) " % [e[1], e[0], e[2]]
	print("   SYS ", txt)
	return r


func _scenario(name: String, m: Vector2, tod: float, run: bool) -> void:
	Game.world.env.time_of_day = tod
	_place(m)
	await get_tree().create_timer(4.0).timeout
	if run:
		var dir = Vector3(0, 0, 1)  # güney kapısından güneye
		await _sample(name, 10.0, dir * 19.0)
	else:
		await _sample(name, 6.0)


func _ablation(m: Vector2) -> void:
	Game.world.env.time_of_day = 0.5
	_place(m)
	await get_tree().create_timer(4.0).timeout
	var base = await _sample("ABL temel", 4.0)
	var w = Game.world
	var tests = [
		["golge_kapali", func(on): w.env.sun.shadow_enabled = on],
		["outline_kapali", func(on): w.env.post.visible = on],
		["cimen_gizli", func(on): _vis_named(w, "Grass", on)],
		["bitki_gizli", func(on): w.vegetation.visible = on],
		["akis_gizli", func(on): w.stream.visible = on],
		["arazi_gizli", func(on): w.terrain.visible = on],
		["aktorler_gizli", func(on): main.actors.visible = on],
		["hud_gizli", func(on): Hud.show_game_hud(on)],
	]
	for tt in tests:
		tt[1].call(false)
		await get_tree().create_timer(0.6).timeout
		await _sample("ABL " + tt[0], 3.0)
		tt[1].call(true)
		await get_tree().create_timer(0.4).timeout
	# hangi düğümler çok? (stream altındaki çocuk sayıları)
	var counts = {}
	_count(get_tree().root, counts, 0)
	var arr = []
	for k in counts:
		arr.append([counts[k], k])
	arr.sort()
	arr.reverse()
	print("TOP NODE TYPES: ", arr.slice(0, 12))
	var mi = 0; var mmi = 0; var lights = 0; var shadow_mi = 0
	for n in get_tree().root.find_children("*", "GeometryInstance3D", true, false):
		if n is MultiMeshInstance3D:
			mmi += 1
		elif n is MeshInstance3D:
			mi += 1
			if (n as MeshInstance3D).cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and n.is_visible_in_tree():
				shadow_mi += 1
	for n in get_tree().root.find_children("*", "Light3D", true, false):
		if n.is_visible_in_tree():
			lights += 1
	print("MESH=%d MULTIMESH=%d SHADOW_MESH=%d LIGHTS=%d" % [mi, mmi, shadow_mi, lights])


## Hangi düğümün _process'i pahalı? Alt sistemleri tek tek durdurup süreyi ölç
func _proc_ablation(m: Vector2) -> void:
	Game.world.env.time_of_day = 0.5
	_place(m)
	await get_tree().create_timer(5.0).timeout
	await _sample("PROC temel", 3.0)
	var cands = []
	for n in Game.world.get_children():
		cands.append(n)
	for n in main.actors.get_children():
		if not n is CharacterBody3D:
			cands.append(n)
	for n in get_tree().root.get_children():
		if n != main:
			cands.append(n)
	cands.append(pl)
	cands.append(main)
	for n in cands:
		var modes = n.process_mode
		n.process_mode = Node.PROCESS_MODE_DISABLED
		await get_tree().create_timer(0.3).timeout
		var r = await _sample("PROC-" + String(n.name), 1.2)
		n.process_mode = modes
	# NPC'ler topluca
	var npcs = main.actors.get_children().filter(func(x): return x is CharacterBody3D and x != pl)
	for x in npcs:
		x.process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().create_timer(0.3).timeout
	await _sample("PROC-tum_npc(%d)" % npcs.size(), 1.2)
	for x in npcs:
		x.process_mode = Node.PROCESS_MODE_INHERIT


func _vis_named(root: Node, nm: String, on: bool) -> void:
	for n in root.find_children("*", "", true, false):
		if String(n.name).begins_with(nm) and n is Node3D:
			n.visible = on


func _count(n: Node, counts: Dictionary, depth: int) -> void:
	var c = n.get_class()
	counts[c] = counts.get(c, 0) + 1
	for ch in n.get_children():
		_count(ch, counts, depth + 1)
