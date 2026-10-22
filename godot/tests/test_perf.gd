extends Node
## Takılma (stutter) testi: oyuncuyu Konoha sokaklarından ormana ve geri yürütür, her karenin süresini ölçer,
## 25 ms'yi aşan kareleri o anda olan olaylarla (NPC doğumu, ağaç havuzu, shader derlemesi...) birlikte yazar.

var main: Node
var pl: Player
var path: Array = []
var seg := 0
var seg_t := 0.0
var running := false
var frames: Array = []
var last := {}
var t0 := 0
var veg: Node
var life: Node
const SPEED := 16.0


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	pl = main.player
	Game.world.env.time_of_day = 0.4
	Game.world.env.weather_t = 999
	veg = Game.world.vegetation
	life = main.actors.get_node_or_null("VillageLife")
	var v = Game.village("konoha")
	for q in [Vector2(-120, 120), Vector2(-50, -195), Vector2(150, -100), Vector2(250, 150), Vector2(-50, 260), Vector2(-300, 250),
			Vector2(-560, -100), Vector2(-700, -500), Vector2(-300, -800), Vector2(0, -500), Vector2(-50, -195)]:
		path.append(Game.from_map(Vector2(v["x"], v["y"]) + q))
	pl.respawn(path[0])
	pl.cam_dist = 6.0
	await get_tree().create_timer(3.0).timeout
	_snap_state()
	t0 = Time.get_ticks_msec()
	running = true


func _snap_state() -> void:
	last = {
		"npcs": life.npcs.size() if life else 0,
		"veg_cell": veg.last_cell if veg else Vector2i.ZERO,
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"pipe_mesh": int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_MESH)),
		"pipe_surf": int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SURFACE)),
		"pipe_draw": int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_DRAW)),
		"pipe_spec": int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SPECIALIZATION)),
		"pipe_canvas": int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_CANVAS)),
	}


func _physics_process(dt: float) -> void:
	if not running:
		return
	if seg >= path.size() - 1:
		return
	var a: Vector3 = path[seg]
	var b: Vector3 = path[seg + 1]
	var len = Vector2(a.x - b.x, a.z - b.z).length()
	seg_t += dt * SPEED / maxf(1.0, len)
	if seg_t >= 1.0:
		seg_t = 0.0
		seg += 1
		return
	var p = a.lerp(b, seg_t)
	p.y = Game.ground_height(p.x, p.z)
	pl.global_position = p
	pl.velocity = Vector3.ZERO
	var d = b - a
	pl.yaw = rad_to_deg(atan2(-d.x, -d.z))
	pl.facing = deg_to_rad(pl.yaw)


func _process(dt: float) -> void:
	if not running:
		return
	var ms = dt * 1000.0
	frames.append(ms)
	var prev = last.duplicate()
	_snap_state()
	if ms > 25.0:
		var ev = []
		if last["npcs"] != prev["npcs"]:
			ev.append("npc %d->%d" % [prev["npcs"], last["npcs"]])
		if last["veg_cell"] != prev["veg_cell"]:
			ev.append("veg_cell")
		if last["nodes"] != prev["nodes"]:
			ev.append("nodes %+d" % (last["nodes"] - prev["nodes"]))
		for k in ["pipe_mesh", "pipe_surf", "pipe_draw", "pipe_spec", "pipe_canvas"]:
			if last[k] != prev[k]:
				ev.append("%s %+d" % [k, last[k] - prev[k]])
		print("SPIKE t=%.2fs %.1fms proc=%.1f phys=%.1f  %s" % [(Time.get_ticks_msec() - t0) * 0.001, ms,
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, ", ".join(ev)])
	if seg >= path.size() - 1 or Time.get_ticks_msec() - t0 > 60000:
		running = false
		var s = frames.duplicate()
		s.sort()
		var n = s.size()
		var tot = 0.0
		for x in s:
			tot += x
		var big = s.filter(func(x): return x > 25.0).size()
		var huge = s.filter(func(x): return x > 50.0).size()
		print("PERF frames=%d avg=%.1fms p50=%.1f p95=%.1f p99=%.1f max=%.1f  >25ms=%d >50ms=%d" % [n, tot / n, s[n / 2], s[int(n * 0.95)], s[int(n * 0.99)], s[n - 1], big, huge])
		get_tree().quit()
