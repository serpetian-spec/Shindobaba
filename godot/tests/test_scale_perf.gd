extends Node
## Hangi sistem kare süresini yiyor: sprint hızında yol boyunca koşarken sistemleri tek tek kapatıp ölçer.
var main: Node
var pl
var pts: PackedVector2Array
var pos: Vector2
var seg := 1


func _run(label: String, frames: int) -> void:
	var times: Array = []
	var spikes = 0
	var last = Time.get_ticks_usec()
	for f in frames:
		var target: Vector2 = pts[mini(seg + 1, pts.size() - 1)]
		var dv = target - pos
		if dv.length() < 0.4 and seg < pts.size() - 2:
			seg += 1
		pos += dv.normalized() * (19.0 / 60.0)
		var g = Game.from_map(pos)
		g.y = maxf(g.y, 0.0)
		pl.global_position = g
		pl.velocity = Vector3.ZERO
		await get_tree().process_frame
		var now = Time.get_ticks_usec()
		var ms = (now - last) / 1000.0
		last = now
		times.append(ms)
		if ms > 25.0:
			spikes += 1
	times.sort()
	print("PERF[%s] p50=%.1f p90=%.1f p99=%.1f max=%.1f >25ms=%d fps=%d" % [label, times[times.size() / 2], times[int(times.size() * 0.9)], times[int(times.size() * 0.99)], times[-1], spikes, Engine.get_frames_per_second()])


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	pl = main.player
	pts = Game.roads[2]["pts"]
	pos = pts[1]
	pl.respawn(Game.from_map(pos))
	await get_tree().create_timer(4.0).timeout
	var w = Game.world
	await _run("hepsi", 400)
	# sabit durma
	var keep = pos
	var times = []
	var last = Time.get_ticks_usec()
	for f in 120:
		await get_tree().process_frame
		var now = Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
	times.sort()
	print("PERF[duran] p50=%.1f max=%.1f" % [times[60], times[-1]])
	w.vegetation.process_mode = Node.PROCESS_MODE_DISABLED
	await _run("bitki_akisi_kapali", 300)
	w.stream.process_mode = Node.PROCESS_MODE_DISABLED
	await _run("+yapi_akisi_kapali", 300)
	w.get_node("RoadTraffic").process_mode = Node.PROCESS_MODE_DISABLED
	w.get_node("Wildlife").process_mode = Node.PROCESS_MODE_DISABLED
	await _run("+trafik_hayvan_kapali", 300)
	w.get_node("Grass").visible = false
	await _run("+cimen_gizli", 300)
	w.vegetation.visible = false
	await _run("+bitki_gizli", 300)
	w.terrain.visible = false
	await _run("+arazi_gizli", 300)
	get_tree().quit()
