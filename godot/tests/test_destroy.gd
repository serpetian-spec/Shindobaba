extends Node
## Dünya hasarı testi: Gōkakyū orman kenarında ve bir evde (yangın -> kömür / yıkım), Rasengan ile ağaç devirme ve ev yıkma.
var main: Node
var cam: Camera3D
var worst := 0.0


func _process(dt: float) -> void:
	worst = maxf(worst, dt * 1000.0)


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var env = main.world.env
	env.time_of_day = 0.45
	env.region_weather = "açık"
	env.weather_t = 9999.0
	env.overcast = 0.0
	var pl = main.player
	Game.profile["level"] = 30
	pl.max_chakra = 99999.0
	pl.chakra = 99999.0
	cam = Camera3D.new()
	cam.fov = 62
	main.add_child(cam)
	env.attach_post(cam)
	# ---------------------------------------------------------------- orman kenarı
	var kv = {}
	for v in Game.world_info["villages"]:
		if v["id"] == "konoha":
			kv = v
	var edge = Game.from_map(Vector2(float(kv["x"]) + float(kv["r"]) + 120.0, float(kv["y"])))
	edge.y = Game.ground_height(edge.x, edge.z) + 0.5
	pl.respawn(edge)
	await get_tree().create_timer(5.0).timeout
	var trs = _trees(pl.global_position, 70.0, [0, 9, 1])
	print("AGAC ", trs.size())
	if trs.size() >= 2 and not "--house" in OS.get_cmdline_user_args():
		var tr: Array = trs[0]
		var tp = Vector3(tr[0], tr[1], tr[2])
		var dir = (tp - pl.global_position)
		dir.y = 0
		dir = dir.normalized()
		var stand = tp - dir * 26.0
		stand.y = Game.ground_height(stand.x, stand.z) + 0.3
		pl.respawn(stand)
		await get_tree().create_timer(1.0).timeout
		var dm = _dummy(tp - dir * 2.0)
		pl.yaw = rad_to_deg(atan2(-dir.x, -dir.z))
		pl.combat.lock_target = dm
		pl.set_process(false)
		_frame_side(stand, tp, 34.0, 10.0)
		cam.current = true
		worst = 0.0
		Jutsu.execute(pl, "katon_goukakyuu", dm)
		await _shot("d1_orman_gokakyu_a", 1.6)
		await _shot("d1_orman_gokakyu_b", 2.6)
		_frame_side(stand, tp, 40.0, 16.0)
		await _shot("d1_orman_yangin", 3.0)
		await _shot("d1_orman_yayilim", 4.0)
		await _shot("d1_orman_komur", 9.0)
		print("YANGIN worst=%.1fms aktif=%d agaclar=%d" % [worst, WorldDamage.blazes.size(), WorldDamage.trees.size()])
		# Rasengan ile devirme (yanmamış bir ağaç)
		var t2 = null
		for o in trs:
			if not WorldDamage.trees.has(WorldDamage._tid(o)):
				t2 = o
				break
		if t2 != null:
			var tp2 = Vector3(t2[0], t2[1], t2[2])
			var d2 = (tp2 - pl.global_position)
			d2.y = 0
			d2 = d2.normalized()
			var st2 = tp2 - d2 * 7.0
			st2.y = Game.ground_height(st2.x, st2.z) + 0.3
			pl.set_process(true)
			pl.respawn(st2)
			await get_tree().create_timer(0.6).timeout
			var dm2 = _dummy(tp2 - d2 * 1.6)
			pl.yaw = rad_to_deg(atan2(-d2.x, -d2.z))
			pl.combat.lock_target = dm2
			_frame_side(st2, tp2, 30.0, 12.0)
			Jutsu.execute(pl, "rasengan", dm2)
			await _shot("d2_rasengan_agac_a", 1.3)
			await _shot("d2_rasengan_agac_b", 1.2)
			await _shot("d2_rasengan_agac_c", 2.0)
			# büyük patlama: Odama ile birkaç ağaç
			Jutsu.execute(pl, "odama_rasengan", dm2)
			await _shot("d2_odama_a", 1.8)
			await _shot("d2_odama_b", 2.2)
			print("DEVRILEN ", WorldDamage.gone.size())
	if "--forest" in OS.get_cmdline_user_args():
		get_tree().quit()
		return
	# ---------------------------------------------------------------- ev
	var kc = Game.from_map(Vector2(float(kv["x"]) - 50.0, float(kv["y"]) - 200.0))
	kc.y = Game.ground_height(kc.x, kc.z) + 0.5
	pl.set_process(true)
	pl.respawn(kc)
	await get_tree().create_timer(4.0).timeout
	WorldDamage._drain()
	var hs = _houses(pl.global_position, 260.0)
	print("EV ", hs.size())
	var n := 0
	for rec in hs:
		if n >= 2:
			break
		var t: Dictionary = HouseKit.templates[rec["ti"]]
		var front: Vector3 = rec["basis"] * Vector3(0, 0, -1)
		front.y = 0
		front = front.normalized()
		var hp: Vector3 = rec["pos"]
		var dist = 22.0 if n == 0 else 9.0
		var stand = hp + front * (t["d"] * 0.5 * float(rec["scale"]) + dist)
		stand.y = Game.ground_height(stand.x, stand.z) + 0.3
		# ev ile oyuncu arasında başka bina olmasın: ışın testi
		var space = get_viewport().world_3d.direct_space_state
		var q = PhysicsRayQueryParameters3D.create(stand + Vector3.UP * 1.5, hp + Vector3.UP * 1.5)
		var hit = space.intersect_ray(q)
		if hit.is_empty() or _house_hit_dist(rec, hit["position"]) > 1.2:
			continue
		pl.respawn(stand)
		await get_tree().create_timer(0.8).timeout
		var wallp = hp + front * (t["d"] * 0.5 * float(rec["scale"]) + 1.0)
		wallp.y = Game.ground_height(wallp.x, wallp.z)
		var dm3 = _dummy(wallp)
		pl.yaw = rad_to_deg(atan2(front.x, front.z))
		pl.combat.lock_target = dm3
		var side = front.cross(Vector3.UP).normalized()
		# yüksek açı: önünde başka bina varsa kamerayı yükselt
		var look = hp + Vector3.UP * 4.0
		var cp = hp + front * (t["d"] * 0.5 + 26.0) + side * 12.0 + Vector3.UP * 12.0
		for k in 12:
			var qq = PhysicsRayQueryParameters3D.create(cp, look)
			var hh = space.intersect_ray(qq)
			if hh.is_empty() or _house_hit_dist(rec, hh["position"]) < 1.2:
				break
			cp += Vector3.UP * 5.0
		cam.global_position = cp
		cam.look_at(look)
		cam.current = true
		if n == 0:
			pl.set_process(false)
			worst = 0.0
			Jutsu.execute(pl, "katon_goukakyuu", dm3)
			await _shot("d3_ev_gokakyu_a", 1.8)
			await _shot("d3_ev_yaniyor", 4.0)
			await _shot("d3_ev_yaniyor_b", 6.0)
			await _shot("d3_ev_cokus", 7.5)
			await _shot("d3_ev_moloz", 3.0)
			print("EV YANGIN durum=%s isi=%.0f worst=%.1fms" % [rec.get("state", ""), float(rec.get("heat", 0)), worst])
		else:
			pl.set_process(true)
			Jutsu.execute(pl, "rasengan", dm3)
			await _shot("d4_ev_rasengan_a", 1.25)
			await _shot("d4_ev_rasengan_b", 0.6)
			await _shot("d4_ev_rasengan_c", 1.4)
			await _shot("d4_ev_rasengan_moloz", 2.5)
			print("EV RASENGAN durum=%s korumali=%s" % [rec.get("state", ""), WorldDamage._protected(rec)])
		n += 1
	get_tree().quit()


func _shot(name: String, wait: float) -> void:
	await get_tree().create_timer(wait).timeout
	print("SHOT ", name, " blaze=", WorldDamage.blazes.size())
	await main.shot(name)


func _dummy(p: Vector3) -> Node3D:
	var d = preload("res://scripts/actors/dummy.gd").new()
	main.actors.add_child(d)
	d.global_position = p
	return d


func _frame_side(a: Vector3, b: Vector3, dist: float, h: float) -> void:
	var mid = a.lerp(b, 0.55)
	var f = (b - a)
	f.y = 0
	f = f.normalized()
	var side = f.cross(Vector3.UP).normalized()
	cam.global_position = mid + side * dist + Vector3.UP * h - f * dist * 0.3
	cam.look_at(mid + Vector3.UP * 7.0)


func _trees(p: Vector3, r: float, types: Array) -> Array:
	var out = []
	for tr in WorldDamage._trees_near(p, r):
		if int(tr[5]) in types:
			out.append(tr)
	out.sort_custom(func(a, b): return Vector2(a[0] - p.x, a[2] - p.z).length() < Vector2(b[0] - p.x, b[2] - p.z).length())
	return out


func _houses(p: Vector3, r: float) -> Array:
	var out = []
	for rec in WorldDamage._houses_near(p, r):
		if not WorldDamage._protected(rec):
			out.append(rec)
	out.sort_custom(func(a, b): return a["pos"].distance_to(p) < b["pos"].distance_to(p))
	return out


func _house_hit_dist(rec: Dictionary, hp: Vector3) -> float:
	return WorldDamage._house_dist(rec, hp)
