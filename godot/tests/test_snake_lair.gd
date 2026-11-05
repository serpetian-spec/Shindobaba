extends Node
## Yılan Yolu: in dışı (taş yılanlar) + yer altı laboratuvarı içi
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	Hud.close_dialog()
	main.world.env.time_of_day = 0.42
	var L: Array = LegendPaths.lairs["yilan"]
	var c = Vector3(L[0], 0, -(L[1] + 7.0))
	c.y = Game.terrain_height(c.x, c.z)
	main.player.respawn(c + Vector3(0, 1, 22))
	await get_tree().create_timer(5.0).timeout
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	for k in 2:
		cc.global_position = c + [Vector3(0, 8, 26), Vector3(14, 6, 4)][k]
		cc.look_at(c + Vector3(0, 6, -18))
		cc.current = true
		Hud.show_game_hud(false)
		await get_tree().create_timer(0.4).timeout
		await main.shot("snake_out_%d" % k)
	var door = {}
	for it in Interact.items:
		if String(it.get("room", "")) == "snake_lab":
			door = it
	print("SNK kapı=", not door.is_empty())
	main.player.cam.current = true
	Interiors.inst.enter(door)
	await get_tree().create_timer(2.5).timeout
	Hud.close_dialog()
	var o: Vector3 = Interiors.inst.origin
	print("SNK içeride=", Interiors.inst.inside, " usta-act=", Interact.items.filter(func(x): return String(x.get("kind", "")) == "path_mentor").size())
	cc.global_position = o + Vector3(0, 2.6, -2.0)
	cc.look_at(o + Vector3(0, 1.6, -20))
	cc.current = true
	await get_tree().create_timer(0.3).timeout
	await main.shot("snake_in_0")
	cc.global_position = o + Vector3(-5, 3.0, -9.0)
	cc.look_at(o + Vector3(3, 1.2, -22))
	await get_tree().create_timer(0.2).timeout
	await main.shot("snake_in_1")
	get_tree().quit()
