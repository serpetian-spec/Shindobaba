extends Node
## Seishun Dojosu (Sekiz Kapı Yolu) yeni mekân görüntüsü
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	Hud.close_dialog()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.42
	var L: Array = LegendPaths.lairs["yilan"]
	var c = Vector3(L[0], 0, -(L[1] - 5.5))
	c.y = Game.terrain_height(c.x, c.z)
	main.player.respawn(c + Vector3(0, 1, 30))
	await get_tree().create_timer(5.0).timeout
	print("DOJO antrenman noktaları: ", LegendPaths.drill_spots.get("kapi", {}).keys())
	var pr = Game.profile
	var LP = LegendPaths.node()
	LP.start_drill("yilan", "jagei_jubaku")
	Hud.close_dialog()
	await get_tree().create_timer(0.3).timeout
	for bag in LP.drill["dummies"]:
		main.player.global_position = bag.global_position - Vector3.UP * 0.4
		await get_tree().create_timer(0.1).timeout
	await get_tree().create_timer(0.2).timeout
	print("DRILL2 toplama: aktif=%s öğrenildi=%s" % [not LP.drill.is_empty(), "jagei_jubaku" in pr["learned"]])
	LP.start_drill("yilan", "hebi_bunshin_no_jutsu")
	Hud.close_dialog()
	var cen: Vector3 = LP.drill["center"]
	main.player.global_position = cen + Vector3(0, 0.5, 0)
	var h0 = main.player.hp
	await get_tree().create_timer(21.5).timeout
	print("DRILL2 sis: aktif=%s öğrenildi=%s can %.0f->%.0f" % [not LP.drill.is_empty(), "hebi_bunshin_no_jutsu" in pr["learned"], h0, main.player.hp])
	get_tree().quit()
