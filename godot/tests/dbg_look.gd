extends Node
## Konoha görünüm taraması: sokak seviyesinde 4 yön, kuşbakışı, Hokage kayası, gece gökyüzü, yağmur.
## LOOK_ONLY="street,top,rock,night,rain,cloud" ile seçilir
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var env = Game.world.env
	await get_tree().create_timer(3.0).timeout
	var only = OS.get_environment("LOOK_ONLY")
	var want = func(k): return only == "" or k in only.split(",")
	env.time_of_day = 0.42
	env.region_weather = "açık"
	env.weather = "açık"
	env.weather_t = 999
	env.overcast = 0.0
	env.rain.emitting = false
	var cam = Camera3D.new()
	cam.far = 20000.0
	main.add_child(cam)
	cam.current = true
	env.attach_post(cam)
	var v = Game.village("konoha")
	var c = Game.from_map(Vector2(v["x"], v["y"]))
	c.y = Game.ground_height(c.x, c.z)
	var sp = OS.get_environment("LOOK_AT")
	var p = pl.global_position
	if sp != "":
		var a = sp.split(",")
		p = Game.from_map(Vector2(v["x"] + float(a[0]), v["y"] + float(a[1])))
		p.y = Game.ground_height(p.x, p.z)
		pl.respawn(p + Vector3.UP * 0.5)
	pl.set_physics_process(false)
	pl.set_process(false)
	await get_tree().create_timer(5.0).timeout
	if want.call("street"):
		for k in 4:
			var yaw = k * PI * 0.5
			var f = Vector3(sin(yaw), 0, -cos(yaw))
			cam.global_position = p + Vector3(0, 1.8, 0) - f * 3.0
			cam.look_at(cam.global_position + f * 10.0 + Vector3(0, 1.0, 0))
			await get_tree().create_timer(0.6).timeout
			await main.shot("look_street_%d" % k)
	if want.call("tree"):
		var best = null
		for sp2 in Builder.leaf_spots:
			if best == null or sp2[0].distance_to(p) < best[0].distance_to(p):
				best = sp2
		if best:
			var tp: Vector3 = best[0]
			pl.respawn(tp - Vector3(0, tp.y - Game.ground_height(tp.x, tp.z) - 0.5, 0) + Vector3(6, 0, 6))
			await get_tree().create_timer(9.0).timeout
			cam.global_position = Vector3(tp.x, Game.ground_height(tp.x, tp.z) + 1.7, tp.z) + Vector3(9, 0, 9)
			cam.look_at(tp + Vector3(0, -6, 0))
			var am = Game.world.get_node("Ambience")
			print("FALL ", am.fall_pool.map(func(e): return e.emitting), " ", am.fall_pool.map(func(e): return e.global_position))
			for kk in 8:
				print("T", kk, " ", am.fall_pool.map(func(e): return [e.get_meta("tree", ""), e.emitting]))
				await get_tree().create_timer(0.5).timeout
			if OS.get_environment("WAIT") != "":
				await get_tree().create_timer(float(OS.get_environment("WAIT"))).timeout
			if OS.get_environment("LATE") != "":
				var e = am._emitter(16, 7.0, Vector3(2, 0.6, 2), Vector3(0.3, -1.0, 0.2), 0.2, 0.6, FX.tex_leaf, false, [Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)], 0.3, true)
				e.process_material.gravity = Vector3(0, -0.8, 0)
				e.process_material.color = Color(1, 0, 0)
				e.preprocess = 0.0
				e.global_position = cam.global_position - cam.global_transform.basis.z * 5.0
				e.emitting = true
				await get_tree().create_timer(3.0).timeout
			await main.shot("look_tree_a")
			await get_tree().create_timer(0.7).timeout
			await main.shot("look_tree_b")
	if want.call("top"):
		cam.global_position = p + Vector3(60, 45, 70)
		cam.look_at(p)
		await get_tree().create_timer(1.0).timeout
		await main.shot("look_top")
	if want.call("vista"):
		# referans konoha.png açısı: güneyden yüksekten Hokage Kayası'na doğru
		var vp = Game.from_map(Vector2(v["x"], v["y"] - 1350.0))
		vp.y = Game.ground_height(vp.x, vp.z) + 150.0
		var vt = Game.from_map(Vector2(v["x"], v["y"] + 700.0))
		vt.y = Game.ground_height(vt.x, vt.z) + 40.0
		pl.respawn(Game.from_map(Vector2(v["x"], v["y"] - 900.0)))
		await get_tree().create_timer(8.0).timeout
		cam.global_position = vp
		cam.look_at(vt)
		await get_tree().create_timer(1.0).timeout
		await main.shot("look_vista")
		cam.global_position = Game.from_map(Vector2(v["x"] + 120.0, v["y"] - 300.0)) + Vector3(0, Game.ground_height(vp.x, vp.z) + 45.0, 0)
		cam.look_at(Game.from_map(Vector2(v["x"], v["y"] + 300.0)) + Vector3(0, Game.ground_height(vp.x, vp.z) + 10.0, 0))
		await get_tree().create_timer(1.0).timeout
		await main.shot("look_vista2")
	if want.call("rock"):
		var rk: Dictionary = v.get("hokage_rock", {})
		var rq = Game.from_map(Vector2(float(rk.get("x", v["x"])), float(rk.get("y", v["y"] + 1170.0))))
		rq.y = Game.ground_height(rq.x, rq.z)
		pl.respawn(rq + Vector3(0, 0, 250))
		await get_tree().create_timer(8.0).timeout
		for k in 3:
			cam.global_position = rq + Vector3([-260.0, 0.0, 260.0][k], 40.0, 380.0)
			cam.look_at(rq + Vector3(0, 90, 0))
			await get_tree().create_timer(0.8).timeout
			await main.shot("look_rock_%d" % k)
	if want.call("shops"):
		var k = 0
		for sh in [[-170.0, -23.0, 1.0], [-250.0, -23.0, 1.0], [-110.0, 23.0, -1.0]]:
			var sp2 = Game.from_map(Vector2(v["x"] + sh[0] + 12.0, v["y"] + sh[1] + sh[2] * 30.0))
			sp2.y = Game.ground_height(sp2.x, sp2.z)
			pl.respawn(sp2 + Vector3(3, 0.5, 0))
			await get_tree().create_timer(2.5).timeout
			var tg = Game.from_map(Vector2(v["x"] + sh[0], v["y"] + sh[1]))
			cam.global_position = sp2 + Vector3(0, 1.7, 0)
			cam.look_at(Vector3(tg.x, sp2.y + 2.0, tg.z))
			await get_tree().create_timer(0.5).timeout
			await main.shot("look_shop_%d" % k)
			k += 1
	if want.call("hokage"):
		var tp = Game.from_map(Vector2(v["x"], v["y"] + 600.0 - 35.0 - 14.0))
		tp.y = Game.ground_height(tp.x, tp.z)
		pl.respawn(tp + Vector3(4, 0.5, 0))
		await get_tree().create_timer(6.0).timeout
		for k in 2:
			env.time_of_day = [0.42, 0.95][k]
			await get_tree().create_timer(1.5).timeout
			cam.global_position = tp + Vector3(9, 4.0, 4)
			cam.look_at(tp + Vector3(0, 3.0, -12), Vector3.UP)
			await main.shot("look_hk_%d" % k)
		env.time_of_day = 0.42
	if want.call("stairs"):
		var rk2: Dictionary = v.get("hokage_rock", {})
		var cn2 = float(rk2.get("y", v["y"] + 1170.0))
		var sq = Game.from_map(Vector2(v["x"] - 285.0, cn2 - 60.0))
		sq.y = Game.ground_height(sq.x, sq.z)
		pl.respawn(sq + Vector3(0, 0.5, 30))
		await get_tree().create_timer(6.0).timeout
		for k in 2:
			cam.global_position = sq + Vector3([-40.0, 40.0][k], 45.0, 70.0)
			cam.look_at(sq + Vector3(0, 40.0, -30.0))
			await get_tree().create_timer(0.6).timeout
			await main.shot("look_st_%d" % k)
	if want.call("roofs"):
		cam.global_position = p + Vector3(25, 22, 30)
		cam.look_at(p + Vector3(0, 10, 0))
		await get_tree().create_timer(0.8).timeout
		await main.shot("look_roof")
	if want.call("cloud"):
		cam.global_position = p + Vector3(0, 2, 0)
		cam.look_at(p + Vector3(30, 18, -60))
		await get_tree().create_timer(0.6).timeout
		await main.shot("look_cloud")
	if want.call("rain"):
		env.weather = "yağmur"
		env.region_weather = "yağmur"
		env.overcast = 1.0
		env.rain.emitting = true
		await get_tree().create_timer(3.0).timeout
		cam.global_position = pl.global_position + Vector3(0, 2.0, 4.0)
		cam.look_at(pl.global_position + Vector3(0, 1.5, -6))
		await main.shot("look_rain")
		env.rain.emitting = false
		env.weather = "açık"
		env.region_weather = "açık"
		env.overcast = 0.0
	if want.call("nightcity"):
		env.time_of_day = 0.95
		await get_tree().create_timer(1.5).timeout
		for k in 2:
			var yaw = k * PI
			var f = Vector3(sin(yaw), 0, -cos(yaw))
			cam.global_position = p + Vector3(0, 1.8, 0) - f * 3.0
			cam.look_at(cam.global_position + f * 10.0 + Vector3(0, 2.0, 0))
			await get_tree().create_timer(0.6).timeout
			await main.shot("look_nc_%d" % k)
		cam.global_position = Game.from_map(Vector2(v["x"] + 120.0, v["y"] - 300.0)) + Vector3(0, c.y + 45.0, 0)
		cam.look_at(Game.from_map(Vector2(v["x"], v["y"] + 300.0)) + Vector3(0, c.y + 10.0, 0))
		await get_tree().create_timer(1.0).timeout
		await main.shot("look_nc_top")
		env.time_of_day = 0.42
	if want.call("night"):
		env.time_of_day = 0.98
		await get_tree().create_timer(1.5).timeout
		cam.global_position = p + Vector3(0, 2, 0)
		cam.look_at(p + Vector3(10, 30, -30))
		await main.shot("look_night")
	get_tree().quit()
