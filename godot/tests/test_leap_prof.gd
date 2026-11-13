extends Node
## Hıza göre kare süresinin dağılımı: betik (process), fizik, çizim CPU, çizim GPU, çizim çağrısı.
## LP_FROM="x,y" LP_DIR="dx,dy" (Konoha merkezine göre), LP_SPEEDS="0,16,70,300"
var main: Node
var pl: Player
var pos := Vector2.ZERO
var dir := Vector2(0, -1)
var speed := 0.0
var acc := []
var rows := {}
var _lt := 0

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	pl = main.player
	Game.world.env.time_of_day = 0.4
	Game.world.env.weather_t = 999
	var vp = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var v = Game.village("konoha")
	var f = OS.get_environment("LP_FROM").split(",")
	var start = Vector2(v["x"], v["y"]) + (Vector2(float(f[0]), float(f[1])) if f.size() == 2 else Vector2(0, 100))
	var d = OS.get_environment("LP_DIR").split(",")
	if d.size() == 2:
		dir = Vector2(float(d[0]), float(d[1])).normalized()
	var sp = OS.get_environment("LP_SPEEDS")
	if sp == "":
		sp = "0,16,70,300"
	pos = start
	pl.respawn(Game.from_map(pos))
	await get_tree().create_timer(5.0).timeout
	for s in sp.split(","):
		pos = start
		pl.respawn(Game.from_map(pos))
		speed = 0.0
		await get_tree().create_timer(2.0).timeout
		speed = float(s)
		acc.clear()
		rows = {"proc": 0.0, "phys": 0.0, "rcpu": 0.0, "rgpu": 0.0, "draw": 0.0, "prim": 0.0, "obj": 0.0, "n": 0}
		var t0 = Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 14000:
			await get_tree().process_frame
			rows["proc"] += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
			rows["phys"] += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
			rows["rcpu"] += RenderingServer.viewport_get_measured_render_time_cpu(vp) + RenderingServer.get_frame_setup_time_cpu()
			rows["rgpu"] += RenderingServer.viewport_get_measured_render_time_gpu(vp)
			rows["draw"] += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			rows["prim"] += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
			rows["obj"] += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
			rows["n"] += 1
		var n = float(rows["n"])
		var a = acc.duplicate()
		a.sort()
		var tot = 0.0
		for x in a:
			tot += x
		print("LP hiz=%4d  kare ort=%.1f p50=%.1f p95=%.1f p99=%.1f max=%.0f  >25ms=%d >50ms=%d >100ms=%d | betik=%.1f fizik=%.1f cizimCPU=%.1f GPU=%.1f | cagri=%d ucgen=%.1fM nesne=%d | yol=%d m" % [
			int(speed), tot / a.size(), a[a.size() / 2], a[int(a.size() * 0.95)], a[int(a.size() * 0.99)], a[-1],
			a.filter(func(x): return x > 25.0).size(), a.filter(func(x): return x > 50.0).size(), a.filter(func(x): return x > 100.0).size(),
			rows["proc"] / n, rows["phys"] / n, rows["rcpu"] / n, rows["rgpu"] / n, int(rows["draw"] / n), rows["prim"] / n / 1e6, int(rows["obj"] / n), int(pos.distance_to(start))])
	get_tree().quit()

func _process(_dt: float) -> void:
	var now = Time.get_ticks_usec()
	if _lt != 0:
		var ms = (now - _lt) / 1000.0
		acc.append(ms)
		if speed > 0.0:
			pos += dir * speed * ms / 1000.0
			var p = Game.from_map(pos)
			p.y = Game.ground_height(p.x, p.z) + (0.0 if speed < 100.0 else 25.0)
			pl.global_position = p
			pl.velocity = Vector3.ZERO
	_lt = now
