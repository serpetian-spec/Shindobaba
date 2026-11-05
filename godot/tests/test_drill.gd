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
	var L: Array = LegendPaths.lairs["kapi"]
	var c = Vector3(L[0], 0, -(L[1] - 5.5))
	c.y = Game.terrain_height(c.x, c.z)
	main.player.respawn(c + Vector3(0, 1, 30))
	await get_tree().create_timer(5.0).timeout
	print("DOJO antrenman noktaları: ", LegendPaths.drill_spots.get("kapi", {}).keys())
	# antrenman: Omote Renge (40 vuruş) ve Ura Renge (3 tur)
	var pr = Game.profile
	var LP = LegendPaths.node()
	LP.start_drill("kapi", "omote_renge")
	Hud.close_dialog()
	await get_tree().create_timer(0.3).timeout
	var ds: Array = LP.drill["dummies"]
	print("DRILL kukla=%d" % ds.size())
	for k in 40:
		ds[k % ds.size()].take_hit({"dmg": 5.0, "melee": true})
	await get_tree().create_timer(0.2).timeout
	print("DRILL vuruş bitti: aktif=%s öğrenildi=%s" % [not LP.drill.is_empty(), "omote_renge" in pr["learned"]])
	LP.start_drill("kapi", "ura_renge")
	Hud.close_dialog()
	var cen: Vector3 = LP.drill["center"]
	for step in 4 * 40:
		var a = TAU * step / 40.0
		var q = cen + Vector3(cos(a) * 12.0, 0, sin(a) * 12.0)
		q.y = Game.ground_height(q.x, q.z) + 0.1
		main.player.global_position = q
		await get_tree().physics_frame
		await get_tree().physics_frame
	print("DRILL tur bitti: aktif=%s öğrenildi=%s acc=%s t=%s proc=%s" % [not LP.drill.is_empty(), "ura_renge" in pr["learned"], LP.drill.get("acc"), LP.drill.get("t"), LP.is_processing()])
	get_tree().quit()
