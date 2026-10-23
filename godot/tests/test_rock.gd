extends Node
## Hokage Kayası: yüzler (ön/yan) + uçuruma duvar koşusuyla tırmanış
var main: Node
func _at(x: float, n: float) -> Vector3:
	var v = Game.village("konoha")
	var p = Game.from_map(Vector2(v["x"] + x, v["y"] + n))
	p.y = Game.terrain_height(p.x, p.z) + 0.1
	return p
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.42
	var v = Game.village("konoha")
	var cn = float(v["hokage_rock"]["y"]) - float(v["y"])
	var pl = main.player
	for spot in [[0.0, cn - 260, 0.0, 14.0, 22.0, "r1_on"], [0.0, cn - 120, 0.0, 22.0, 12.0, "r2_yakin"], [-260.0, cn - 90, -55.0, 15.0, 14.0, "r3_yan"]]:
		pl.respawn(_at(spot[0], spot[1]))
		pl.yaw = spot[2]; pl.pitch = spot[3]; pl.cam_dist = spot[4]
		await get_tree().create_timer(3.5).timeout
		await main.shot(spot[5])
	# tırmanış: iki yüzün arasından kuzeye koş
	pl.respawn(_at(46.0, cn - 25))
	pl.yaw = 0.0; pl.pitch = -5.0; pl.cam_dist = 9.0
	await get_tree().create_timer(1.5).timeout
	var y0 = pl.global_position.y
	Input.action_press("forward")
	var maxjump = 0.0
	var prev = pl.global_position.y
	var on_wall_t = 0.0
	for i in 600:
		await get_tree().physics_frame
		var dy = pl.global_position.y - prev
		maxjump = maxf(maxjump, dy)
		prev = pl.global_position.y
		if pl.wall_n != Vector3.ZERO:
			on_wall_t += 1.0 / 60.0
		if i % 30 == 0:
			print("T", i, " p=", Vector3i(pl.global_position), " wall=", pl.wall_n.snapped(Vector3.ONE * 0.01), " tw=", pl.terrain_wall, " gr=", pl.grounded, " cd=", snappedf(pl.wall_cd, 0.01))
		if i == 90:
			await main.shot("r4_tirman1")
		if i == 220:
			await main.shot("r5_tirman2")
	Input.action_release("forward")
	print("TIRMANIŞ yükselme=", int(pl.global_position.y - y0), " m, tek karede en büyük sıçrama=", snappedf(maxjump, 0.01), " m, duvarda=", snappedf(on_wall_t, 0.1), " sn, story-lookout uzaklık=", int(pl.global_position.distance_to(Exams.find_point(["lookout"]))))
	await main.shot("r6_tepe")
	# kafaya doğru yürü: içinden geçilmemeli
	pl.respawn(_at(0.0, cn - 60))
	await get_tree().create_timer(1.0).timeout
	Input.action_press("forward")
	for i in 240:
		await get_tree().physics_frame
	Input.action_release("forward")
	print("KAFAYA YÜRÜ son n=", int(-(pl.global_position.z) - (-Game.from_map(Vector2(v["x"], v["y"] + cn)).z)), " y=", int(pl.global_position.y - float(v["base"])), " wall=", pl.wall_n != Vector3.ZERO)
	get_tree().quit()
