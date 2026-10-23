extends Node
## Ağaç testi: Konoha güney kapısından Ateş ormanına koşar, yol boyunca dev ve normal ağaçlara dokunacak kadar yaklaşır.
## Her kareyi ölçer; 20 ms'yi aşan kareleri o anda olanlarla (çarpışma havuzu, parça kurulumu, shader derlemesi) yazar.
## Görünürlük: oyuncunun çevresindeki ağaç MultiMesh'lerinin görünürlük aralığından dolayı gizlenip gizlenmediğini sayar,
## birkaç noktada kamerayı 360° çevirerek ekran görüntüsü alır.

var main: Node
var pl: Player
var veg: Node
var frames: Array = []
var events: Array = []
var last := {}
var mode := ""
var phase_t := 0.0
var path: Array = []
var seg := 0
var installs := 0
var pool_moves := 0
const SPEED := 19.0


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Hud.show_game_hud(false)
	pl = main.player
	veg = Game.world.vegetation
	Game.world.env.time_of_day = 0.42
	Game.world.env.weather_t = 9999.0
	Game.world.env.region_weather = "açık"
	var v = Game.village("konoha")
	var R = float(v["r"])
	# güney kapısından güneye, sonra batıya: orman halkası (köy r+30 .. r+700)
	for q in [Vector2(0, -R + 40), Vector2(0, -R - 120), Vector2(0, -R - 420), Vector2(-300, -R - 600), Vector2(-700, -R - 500),
			Vector2(-900, -R - 200), Vector2(-1100, -R + 300)]:
		path.append(Game.from_map(Vector2(v["x"], v["y"]) + q))
	pl.respawn(path[0])
	pl.cam_dist = 6.0
	await get_tree().create_timer(4.0).timeout
	_snap()
	mode = "run"


func _snap() -> void:
	last = {
		"cell": veg.last_cell,
		"chunks": veg.chunks.size(),
		"pipe": _pipes(),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
	}


func _pipes() -> int:
	return int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_MESH)) + int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SURFACE)) \
		+ int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_DRAW)) + int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SPECIALIZATION))


func _process(dt: float) -> void:
	if mode == "":
		return
	var ms = dt * 1000.0
	var why = []
	if veg.last_cell != last["cell"]:
		why.append("havuz")
	if veg.chunks.size() != last["chunks"]:
		why.append("parça%+d" % (veg.chunks.size() - int(last["chunks"])))
	var pp = _pipes()
	if pp != last["pipe"]:
		why.append("shader+%d" % (pp - int(last["pipe"])))
	var nd = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	if absi(nd - int(last["nodes"])) > 30:
		why.append("düğüm%+d" % (nd - int(last["nodes"])))
	if mode != "shots":
		frames.append(ms)
		if ms > 20.0:
			events.append("%.1f ms  [%s]  %s  phys=%.1f proc=%.1f" % [ms, mode, ", ".join(why),
				Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0])
	_snap()


func _physics_process(dt: float) -> void:
	if mode != "run":
		return
	if seg >= path.size() - 1:
		mode = "done_run"
		_after_run.call_deferred()
		return
	var a: Vector3 = path[seg]
	var b: Vector3 = path[seg + 1]
	var to = Vector3(b.x - pl.global_position.x, 0, b.z - pl.global_position.z)
	if to.length() < 6.0:
		seg += 1
		return
	var d = to.normalized()
	var p = pl.global_position + d * SPEED * dt
	p.y = Game.terrain_height(p.x, p.z)
	pl.global_position = p
	pl.velocity = Vector3.ZERO
	pl.yaw = rad_to_deg(atan2(-d.x, -d.z))
	pl.facing = atan2(-d.x, -d.z)


func _near_trees(kind_filter: Array, maxn := 6) -> Array:
	var p = pl.global_position
	var out = []
	for k in veg.chunks:
		for tr in veg.chunks[k]["trees"]:
			if tr[5] in kind_filter:
				var dd = Vector2(tr[0] - p.x, tr[2] - p.z).length()
				if dd > 15.0 and dd < 400.0:
					out.append([dd, tr])
	out.sort_custom(func(x, y): return x[0] < y[0])
	return out.slice(0, maxn)


## oyuncunun çevresindeki ağaçlardan kaç tanesinin hiçbir LOD'u görünür değil (görünürlük aralığı yüzünden gizli)
func _hidden_count(radius: float) -> Array:
	var cam = pl.cam
	var cp = cam.global_position
	var p = pl.global_position
	var total = 0
	var hidden = 0
	for k in veg.chunks:
		var node: Node3D = veg.chunks[k]["node"]
		for tr in veg.chunks[k]["trees"]:
			if Vector2(tr[0] - p.x, tr[2] - p.z).length() > radius:
				continue
			total += 1
			var vis = false
			for mmi in node.get_children():
				if not mmi is MultiMeshInstance3D:
					continue
				# bu ağacı içeren mi? (aynı tip ise yaklaşık kabul: tamponda konum ara)
				var mm: MultiMesh = mmi.multimesh
				var found = false
				for i in mm.instance_count:
					var o = mm.get_instance_transform(i).origin + node.global_position
					if absf(o.x - tr[0]) < 0.05 and absf(o.z - tr[2]) < 0.05:
						found = true
						break
				if not found:
					continue
				var ab: AABB = mmi.global_transform * mmi.get_aabb()
				var d = cp.distance_to(ab.get_center())
				var b0 = mmi.visibility_range_begin
				var e0 = mmi.visibility_range_end
				if (b0 <= 0.0 or d >= b0 - mmi.visibility_range_begin_margin) and (e0 <= 0.0 or d <= e0 + mmi.visibility_range_end_margin):
					vis = true
					break
			if not vis:
				hidden += 1
	return [hidden, total]


func _after_run() -> void:
	var run_frames = frames.duplicate()
	# 2) ağaçlara yaklaş: dev ağaç (9) ve normal ağaçlar (0,1,2)
	mode = "approach"
	for grp in [[9], [0, 1, 2, 5]]:
		for e in _near_trees(grp, 5):
			var tr: Array = e[1]
			var tp = Vector3(tr[0], 0, tr[2])
			# 40 m'den dokunana kadar koş
			var dir = (Vector3(pl.global_position.x, 0, pl.global_position.z) - tp).normalized()
			var start = tp + dir * 40.0
			start.y = Game.terrain_height(start.x, start.z)
			pl.global_position = start
			pl.reset_physics_interpolation()
			for i in 40:
				var q = start.lerp(tp + dir * (1.5 + float(tr[3]) * (1.2 if tr[5] == 9 else 0.4)), float(i) / 39.0)
				q.y = Game.terrain_height(q.x, q.z)
				pl.global_position = q
				pl.yaw = rad_to_deg(atan2(dir.x, dir.z))
				await get_tree().physics_frame
	# 3) görünürlük: birkaç noktada gizli ağaç sayısı + 360° ekran görüntüleri
	mode = "shots"
	var spots = []
	for e in _near_trees([9, 0, 1, 2], 40):
		spots.append(e[1])
	var picks = [0, 10, 25]
	var hid_total = 0
	var tot_total = 0
	for pi in picks:
		if pi >= spots.size():
			break
		var tr: Array = spots[pi]
		var q = Vector3(tr[0] + 6.0, 0, tr[2] + 6.0)
		q.y = Game.terrain_height(q.x, q.z)
		pl.global_position = q
		pl.reset_physics_interpolation()
		await get_tree().create_timer(1.5).timeout
		var hc = _hidden_count(120.0)
		hid_total += hc[0]
		tot_total += hc[1]
		print("GÖRÜNÜRLÜK nokta ", pi, ": 120 m içinde ", hc[1], " ağaç, gizli ", hc[0])
		for ang in [0, 90, 180, 270]:
			pl.yaw = float(ang)
			pl.pitch = -6.0
			await get_tree().create_timer(0.4).timeout
			await main.shot("tr_%d_%d" % [pi, ang])
	# 4) LOD sınırında yavaş yürüyüş: 20 m'den 300 m'ye uzaklaş, gizlenen sayısını izle
	mode = "lod"
	if not spots.is_empty():
		var tr: Array = spots[0]
		var origin = Vector3(tr[0], 0, tr[2])
		var maxh = 0
		for dist in range(10, 320, 20):
			var q = origin + Vector3(float(dist), 0, 0)
			q.y = Game.terrain_height(q.x, q.z)
			pl.global_position = q
			pl.reset_physics_interpolation()
			await get_tree().create_timer(0.25).timeout
			var hc = _hidden_count(60.0)
			maxh = maxi(maxh, hc[0])
		print("LOD yürüyüşü: 60 m içinde en fazla gizli ağaç = ", maxh)
	_report(run_frames)
	get_tree().quit()


func _report(run_frames: Array) -> void:
	var all = frames.duplicate()
	for label in [["KOŞU", run_frames], ["TÜMÜ (koşu+yaklaşma+lod)", all]]:
		var arr: Array = label[1].duplicate()
		if arr.is_empty():
			continue
		arr.sort()
		var n = arr.size()
		var over20 = arr.filter(func(x): return x > 20.0).size()
		var over25 = arr.filter(func(x): return x > 25.0).size()
		var over50 = arr.filter(func(x): return x > 50.0).size()
		var avg = 0.0
		for x in arr:
			avg += x
		avg /= n
		print("AĞAÇ %s kare=%d ort=%.1f p50=%.1f p99=%.1f max=%.1f  >20=%d >25=%d >50=%d" % [label[0], n, avg, arr[n / 2], arr[int(n * 0.99)], arr[n - 1], over20, over25, over50])
	var ev = events.duplicate()
	ev.sort_custom(func(a, b): return float(a.split(" ")[0]) > float(b.split(" ")[0]))
	for e in ev.slice(0, 12):
		print("  YAVAŞ ", e)
