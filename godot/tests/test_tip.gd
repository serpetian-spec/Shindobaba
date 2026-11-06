extends Node
## Şifacı Yolu: Yuge Şifa Tapınağı görüntüsü + antrenmanlar (balık/hasta başında bekleme, neşter vuruşu), havuz suyunda yürüme
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
	main.world.env.time_of_day = 0.42
	main.world.env.weather = "açık"
	var L: Array = LegendPaths.lairs["tip"]
	var c = Vector3(L[0], 0, -L[1])
	c.y = Game.terrain_height(c.x, c.z)
	var pl = main.player
	pl.respawn(c + Vector3(0, 1, 30))
	await _w(6.0)
	var sp = LegendPaths.drill_spots.get("tip", {})
	print("TIP noktalar: ", sp.keys(), " hasta=", sp.get("patients", []).size(), " leğen=", sp.get("basins", []).size())
	Hud.show_game_hud(false)
	await _shot("tip_genel", c + Vector3(0, 2, -2), c + Vector3(-14, 14, 26))
	await _shot("tip_koğuş", sp["patients"][1] + Vector3(0, 0.6, 0), sp["patients"][1] + Vector3(4, 3, 6))
	await _shot("tip_leğen", sp["basins"][1] + Vector3(0, 0.6, 1), sp["basins"][1] + Vector3(-3, 2.5, -3.5))
	await _shot("tip_tapınak", c + Vector3(0, 2.5, -14), c + Vector3(3, 3.5, -2))
	Hud.show_game_hud(true)
	var LP = LegendPaths.node()
	var pr = Game.profile
	# 1) balık: her leğenin başında dur
	LP.start_drill("tip", "shousen")
	Hud.close_dialog()
	for td in LP.drill["tend"]:
		pl.global_position = td["pos"] + Vector3.UP * 0.2
		await _w(2.0)
		pl.global_position = td["pos"] + Vector3(4, 0.2, 0)   # yarıda ayrıl -> sıfırlanmalı
		await _w(0.3)
		print("TIP yarıda ayrıl: t=%.1f done=%s" % [td["t"], td["done"]])
		pl.global_position = td["pos"] + Vector3.UP * 0.2
		await _w(4.4)
	print("TIP balık: aktif=%s öğrenildi=%s" % [not LP.drill.is_empty(), "shousen" in pr["learned"]])
	# 2) hasta
	LP.start_drill("tip", "saikan_chushutsu_no_jutsu")
	Hud.close_dialog()
	await _w(0.3)
	await _shot("tip_halka", LP.drill["tend"][0]["pos"], LP.drill["tend"][0]["pos"] + Vector3(5, 4, 6))
	for td in LP.drill["tend"]:
		pl.global_position = td["pos"] + Vector3.UP * 0.2
		await _w(3.4)
	print("TIP hasta: aktif=%s öğrenildi=%s" % [not LP.drill.is_empty(), "saikan_chushutsu_no_jutsu" in pr["learned"]])
	# 3) neşter
	LP.start_drill("tip", "chakura_no_mesu")
	Hud.close_dialog()
	await _w(0.3)
	for i in 30:
		var d = LP.drill["dummies"][i % 3]
		if is_instance_valid(d):
			d.take_hit({"dmg": 5.0, "melee": true})
	await _w(0.2)
	print("TIP neşter: aktif=%s öğrenildi=%s" % [not LP.drill.is_empty(), "chakura_no_mesu" in pr["learned"]])
	# havuz suyu üstünde yürünür mü
	var hx = c
	for e in Game.water_list:
		if is_instance_valid(e[0]) and (e[1] as Vector2).distance_to(Vector2(c.x, c.z)) < 30.0:
			hx = Vector3(e[1].x, e[4], e[1].y)
			break
	pl.global_position = hx + Vector3.UP * 2.0
	await _w(1.5)
	print("TIP havuz: terr=%.2f su=%.2f y=%.2f on_water=%s" % [Game.terrain_height(pl.global_position.x, pl.global_position.z), Game.water_level(pl.global_position.x, pl.global_position.z), pl.global_position.y, pl.on_water])
	get_tree().quit()
