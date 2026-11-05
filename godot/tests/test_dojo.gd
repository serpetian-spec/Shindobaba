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
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	var views = [[Vector3(0, 14, 38), Vector3(0, 2, 0)], [Vector3(18, 6, 22), Vector3(-2, 2, -2)], [Vector3(0, 3.5, 2.0), Vector3(0, 3.2, -20)], [Vector3(-14, 4, 8), Vector3(-6, 1.5, -2)]]
	for k in views.size():
		cc.global_position = c + views[k][0]
		cc.look_at(c + views[k][1])
		cc.current = true
		await get_tree().create_timer(0.4).timeout
		await main.shot("dojo_%d" % k)
	get_tree().quit()
