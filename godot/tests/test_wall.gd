extends Node
## Duvar koşusu/tırmanış testi: Konoha ev duvarları, Hokage uçurumu, orman ağacı.
## Her denemede: duvara koş, ileri basılı tut; yükselme, tek karedeki en büyük sıçrama (ışınlanma), duvarda kalma süresi,
## bacak hareketi (sol ayak kemiğinin kalçaya göre oynama aralığı) ve tepeye çıkış yazılır.
var main: Node
var pl: Player


func _ray(from: Vector3, to: Vector3) -> Dictionary:
	return pl.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1, [pl.get_rid()]))


## spawn çevresinde boyu yeterli bir duvar bul: [duvar noktası, dışa normal]
func _find_wall(c: Vector3, skip: Array) -> Array:
	for r in [8.0, 14.0, 22.0, 32.0]:
		for k in 24:
			var a = TAU * k / 24.0
			var d = Vector3(sin(a), 0, cos(a))
			var h = _ray(c + Vector3.UP * 1.0, c + Vector3.UP * 1.0 + d * r)
			if h.is_empty():
				continue
			var n: Vector3 = h["normal"]
			n.y = 0
			if n.length() < 0.7:
				continue
			n = n.normalized()
			var hp: Vector3 = h["position"]
			var dup = false
			for s in skip:
				if s.distance_to(hp) < 10.0:
					dup = true
			if dup:
				continue
			# en az 4 m yüksek
			if _ray(hp + n * 0.3 + Vector3.UP * 4.0, hp - n * 0.6 + Vector3.UP * 4.0).is_empty():
				continue
			return [hp, n]
	return []


func _bone_y(name: String) -> float:
	var sk = pl.model.skel
	var bi = sk.find_bone(name)
	var hi = sk.find_bone("Hips")
	return (sk.get_bone_global_pose(bi).origin - sk.get_bone_global_pose(hi).origin).length()


func _run(label: String, start: Vector3, toward: Vector3, frames := 420) -> void:
	pl.respawn(start)
	var d = (toward - start)
	d.y = 0
	pl.yaw = rad_to_deg(atan2(-d.x, -d.z))
	pl.pitch = -8.0
	pl.cam_dist = 8.0
	await get_tree().create_timer(1.0).timeout
	var y0 = pl.global_position.y
	var prev = pl.global_position
	var maxjump = 0.0
	var wall_t = 0.0
	var foot_min = 99.0
	var foot_max = -99.0
	var entered = -1
	var left_at = -1
	var stuck = 0
	Input.action_press("forward")
	for i in frames:
		await get_tree().physics_frame
		var p = pl.global_position
		maxjump = maxf(maxjump, p.distance_to(prev))
		if pl.wall_n != Vector3.ZERO:
			wall_t += 1.0 / 60.0
			if entered < 0:
				entered = i
			var fy = _bone_y("LeftFoot")
			foot_min = minf(foot_min, fy)
			foot_max = maxf(foot_max, fy)
			if p.distance_to(prev) < 0.02:
				stuck += 1
		elif entered >= 0 and left_at < 0:
			left_at = i
		prev = p
		if i in [entered + 20, entered + 60]:
			await main.shot("%s_%d" % [label, i])
	Input.action_release("forward")
	await get_tree().create_timer(0.8).timeout
	await main.shot("%s_son" % label)
	print("DUVAR %s: yükselme=%.1f m, max kare sıçrama=%.2f m, duvarda=%.1f sn (giriş kare %d, çıkış %d), duvarda takılı kare=%d, ayak oynama=%.2f m, son wall=%s gr=%s" % [
		label, pl.global_position.y - y0, maxjump, wall_t, entered, left_at, stuck, foot_max - foot_min, pl.wall_n != Vector3.ZERO, pl.grounded])


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.42
	pl = main.player
	var v = Game.village("konoha")
	var spots = [Vector2(-300, -200), Vector2(200, 150), Vector2(-700, 300)]
	var used = []
	var hn = 0
	for s in spots:
		var c = Game.from_map(Vector2(v["x"] + s.x, v["y"] + s.y))
		c.y = Game.terrain_height(c.x, c.z) + 0.2
		pl.respawn(c)
		await get_tree().create_timer(2.0).timeout
		var w = _find_wall(pl.global_position, used)
		if w.is_empty():
			print("DUVAR ev%d: duvar bulunamadı" % hn)
			continue
		used.append(w[0])
		var st: Vector3 = w[0] + w[1] * 6.0
		st.y = Game.terrain_height(st.x, st.z) + 0.2
		await _run("ev%d" % hn, st, w[0])
		hn += 1
	# Hokage uçurumu
	var cn = float(v["hokage_rock"]["y"]) - float(v["y"])
	var rs = Game.from_map(Vector2(v["x"] + 46.0, v["y"] + cn - 25))
	rs.y = Game.terrain_height(rs.x, rs.z) + 0.1
	await _run("ucurum", rs, rs + Vector3(0, 0, -50), 600)
	get_tree().quit()
