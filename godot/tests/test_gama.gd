extends Node
## Kâğıt Yolu: kule görüntüsü, antrenmanlar, kule tepesine rampalardan yürüyerek çıkılabilir mi
var main: Node
func _w(t): await get_tree().create_timer(t).timeout
func _shot(name: String, at: Vector3, from: Vector3) -> void:
	main.player.set_process(false)
	main.player.cam.global_position = from
	main.player.cam.look_at(at)
	await _w(0.2)
	await main.shot(name)
	main.player.set_process(true)
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(1.5)
	Hud.close_dialog()
	main.world.env.time_of_day = 0.45
	var L: Array = LegendPaths.lairs["gama"]
	var c = Vector3(L[0], 0, -L[1])
	c.y = Game.terrain_height(c.x, c.z)
	var pl = main.player
	pl.respawn(c + Vector3(0, 1, 30))
	await _w(6.0)
	var sp = LegendPaths.drill_spots.get("gama", {})
	print("GAM noktalar: ", sp.keys())
	var cen: Vector3 = sp["center"]
	# mekânın yerel ekseni: kuklalardan merkeze (+n), sağ (+x)
	var pm: Vector3 = (sp["posts"][0] + sp["posts"][2]) * 0.5
	var fw = (cen - pm); fw.y = 0; fw = fw.normalized()
	var rt = (sp["posts"][2] - sp["posts"][0]); rt.y = 0; rt = rt.normalized()
	var LW = func(x, y, n): return cen + rt * x + fw * (n + 3.0) + Vector3.UP * y
	Hud.show_game_hud(false)
	await _shot("gam_genel", LW.call(0, 1, 6), LW.call(0, 14, -16))
	await _shot("gam_golet", LW.call(0, 1, 15), LW.call(4, 4, 4))
	await _shot("gam_heykel", LW.call(11, 2.5, 9), LW.call(5, 3, 2))
	await _shot("gam_masa", LW.call(6, 0.6, 2), LW.call(3, 2.5, -1.5))
	Hud.show_game_hud(true)
	var LP = LegendPaths.node()
	var pr = Game.profile
	LP.start_drill("gama", "gamayudan")
	Hud.close_dialog()
	await _w(0.3)
	await _shot("gam_kabak", cen, cen + Vector3(0, 14, -16))
	for bag in LP.drill["dummies"]:
		if is_instance_valid(bag):
			pl.global_position = bag.global_position - Vector3.UP * 0.4
			await _w(0.1)
	await _w(0.3)
	print("GAM gamayudan: aktif=%s öğrenildi=%s" % [not LP.drill.is_empty(), "gamayudan" in pr["learned"]])
	LP.start_drill("gama", "kebari_senbon")
	Hud.close_dialog()
	await _w(0.3)
	for i2 in 30:
		var d = LP.drill["dummies"][i2 % 3]
		if is_instance_valid(d):
			d.take_hit({"dmg": 5.0, "melee": true})
	await _w(0.2)
	print("GAM kebari_senbon: aktif=%s öğrenildi=%s" % [not LP.drill.is_empty(), "kebari_senbon" in pr["learned"]])
	pl.max_hp = 1e6; pl.hp = 1e6
	LP.start_drill("gama", "hari_jizo")
	Hud.close_dialog()
	pl.global_position = LP.drill["center"] + Vector3.UP * 0.5
	await _w(21.5)
	print("GAM hari_jizo: aktif=%s öğrenildi=%s" % [not LP.drill.is_empty(), "hari_jizo" in pr["learned"]])
	# gölet suyu yürünür mü
	var hx = cen
	for e in Game.water_list:
		if is_instance_valid(e[0]) and (e[1] as Vector2).distance_to(Vector2(cen.x, cen.z)) < 30.0:
			hx = Vector3(e[1].x, e[4], e[1].y)
			break
	pl.global_position = hx + Vector3.UP * 2.0
	await _w(1.5)
	print("GAM gölet: su=%.2f y=%.2f on_water=%s" % [Game.water_level(pl.global_position.x, pl.global_position.z), pl.global_position.y, pl.on_water])
	get_tree().quit()
