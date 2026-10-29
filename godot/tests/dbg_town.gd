extends Node
## Köy boşluk + köylü dağılımı denetimi: tepeden çekim, köylülerin ana yola uzaklık dağılımı.
## env VILLAGE="konoha,suna", WAIT=12
var main: Node


func _road_dist(q: Vector2) -> float:
	var best = 1e9
	for e in Game.road_segments_near(q, 40.0):
		var rd: Dictionary = Game.roads[e.x]
		if rd["kind"] != "road" and rd["kind"] != "street":
			continue
		var a: Vector2 = rd["pts"][e.y]
		var b: Vector2 = rd["pts"][e.y + 1]
		var ab = b - a
		var k = clampf((q - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
		best = minf(best, q.distance_to(a + ab * k))
	return best


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var cam = Camera3D.new()
	cam.far = 20000.0
	main.add_child(cam)
	var only = OS.get_environment("VILLAGE")
	var ids = only.split(",") if only != "" else PackedStringArray(["konoha", "suna", "tani"])
	var wait = float(OS.get_environment("WAIT")) if OS.get_environment("WAIT") != "" else 12.0
	for vid in ids:
		var v = Game.village(vid)
		Game.world.env.time_of_day = 0.5
		Game.world.env.weather_t = 999
		Game.world.env.weather = "açık"
		Game.world.env.overcast = 0.0
		Game.world.env.set_process(false)
		Game.world.env.env.fog_density = 0.0001
		var c = Game.from_map(Vector2(v["x"], v["y"]))
		var r = float(v["r"])
		var off = Vector2(float(OS.get_environment("OX")) if OS.get_environment("OX") != "" else r * 0.25, float(OS.get_environment("OY")) if OS.get_environment("OY") != "" else r * 0.2)
		var p = Game.from_map(Vector2(v["x"] + off.x, v["y"] + off.y))
		p.y = Game.ground_height(p.x, p.z) + 0.5
		pl.respawn(p)
		pl.set_physics_process(false)
		await get_tree().create_timer(wait).timeout
		# köylü dağılımı
		var vl = main.get_node_or_null("World/VillageLife")
		if vl == null:
			for n in get_tree().root.find_children("*", "", true, false):
				if n.get_script() and String(n.get_script().resource_path).ends_with("village_life.gd"):
					vl = n
					break
		var hist = [0, 0, 0, 0]
		var cnt = 0
		if vl:
			for n in vl.npcs:
				if not is_instance_valid(n):
					continue
				cnt += 1
				var d = _road_dist(Game.to_map(n.global_position))
				hist[0 if d < 4.0 else (1 if d < 9.0 else (2 if d < 18.0 else 3))] += 1
			print("TOWN %s r=%d npcs=%d queue=%d streets=%d  yolda<4:%d  4-9:%d  9-18:%d  18+:%d" % [vid, r, cnt, vl.queue.size(), vl.street_cache.get(vid, []).size(), hist[0], hist[1], hist[2], hist[3]])
		# tepeden (oyuncu çevresi 140 m) ve geniş tepe
		cam.current = true
		main.world.env.attach_post(cam)
		for z in [[p, 120.0, "yakin"], [c, r * 1.9, "genis"]]:
			cam.global_position = z[0] + Vector3(0, z[1], 0.01)
			cam.look_at(z[0], Vector3.FORWARD)
			await get_tree().create_timer(1.2).timeout
			await main.shot("town_%s_%s" % [vid, z[2]])
		# eğik yakın çekimler (arsalar, ara sokaklar)
		for k in 2:
			var yaw2 = k * PI
			var fw2 = Vector3(sin(yaw2), 0, -cos(yaw2))
			cam.global_position = p + Vector3(0, 22.0, 0) - fw2 * 18.0
			cam.look_at(p + fw2 * 22.0)
			await get_tree().create_timer(0.6).timeout
			await main.shot("town_%s_egik%d" % [vid, k])
		# sokak seviyesi dört yön
		for k in 4:
			var yaw = k * PI * 0.5
			var fw = Vector3(sin(yaw), 0, -cos(yaw))
			cam.global_position = p + Vector3(0, 2.0, 0)
			cam.look_at(cam.global_position + fw * 10.0 + Vector3(0, 0.6, 0))
			await get_tree().create_timer(0.5).timeout
			await main.shot("town_%s_sokak%d" % [vid, k])
		cam.current = false
	get_tree().quit()
