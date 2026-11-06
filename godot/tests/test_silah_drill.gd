extends Node
## Silah Yolu antrenmanları: atış talimi (yalnız atış, 8 m), saplı silahları toplama, kunai yağmuru çemberi
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _shot(name: String, at: Vector3, from: Vector3) -> void:
	main.player.set_process(false)
	main.player.cam.global_position = from
	main.player.cam.look_at(at)
	await _w(0.15)
	await main.shot(name)
	main.player.set_process(true)

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	main.world.env.time_of_day = 0.42
	var L: Array = LegendPaths.lairs["silah"]
	var c = Vector3(L[0], 0, -L[1])
	c.y = Game.terrain_height(c.x, c.z)
	main.player.respawn(c + Vector3(0, 1, 30))
	await _w(5.0)
	var sp = LegendPaths.drill_spots.get("silah", {})
	print("SLH noktalar: ", sp.keys(), " posts=", sp.get("posts", []).size())
	var pr = Game.profile
	var LP = LegendPaths.node()
	# 1) atış talimi
	LP.start_drill("silah", "buki_kuchiyose")
	Hud.close_dialog()
	var cen: Vector3 = LP.drill["center"]
	main.player.global_position = cen
	await _w(0.3)
	var d0 = LP.drill["dummies"][0]
	main.player.global_position = d0.global_position + Vector3(0, 0, 3.0)
	d0.take_hit({"dmg": 5.0, "tool": "kunai"})
	d0.take_hit({"dmg": 5.0})
	print("SLH yakın atış + yakın dövüş sayımı (0 olmalı): ", LP.drill["c"])
	main.player.global_position = cen
	await _w(0.1)
	await _shot("slh_hedefler", d0.global_position, cen + Vector3(0, 3, 6))
	for i in 24:
		var d = LP.drill["dummies"][i % 4]
		if not is_instance_valid(d):
			break
		d.take_hit({"dmg": 5.0, "tool": "shuriken"})
	await _w(0.2)
	print("SLH atış: aktif=%s öğrenildi=%s" % [not LP.drill.is_empty(), "buki_kuchiyose" in pr["learned"]])
	# 2) saplı silahları topla
	LP.start_drill("silah", "tesso_kusari")
	Hud.close_dialog()
	await _w(0.3)
	await _shot("slh_toplama", LP.drill["center"], LP.drill["center"] + Vector3(0, 9, 14))
	for w in LP.drill["dummies"]:
		main.player.global_position = w.global_position - Vector3.UP * 0.3
		await _w(0.1)
	await _w(0.2)
	print("SLH toplama: aktif=%s öğrenildi=%s" % [not LP.drill.is_empty(), "tesso_kusari" in pr["learned"]])
	# 3) kunai yağmuru
	LP.start_drill("silah", "tekkosen")
	Hud.close_dialog()
	cen = LP.drill["center"]
	main.player.global_position = cen + Vector3(0, 0.5, 0)
	var h0 = main.player.hp
	await _w(6.0)
	await _shot("slh_yagmur", cen, cen + Vector3(0, 6, 11))
	await _w(15.5)
	print("SLH yağmur: aktif=%s öğrenildi=%s can %.0f->%.0f" % [not LP.drill.is_empty(), "tekkosen" in pr["learned"], h0, main.player.hp])
	get_tree().quit()
