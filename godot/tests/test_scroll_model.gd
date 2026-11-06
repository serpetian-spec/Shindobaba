extends Node
## Parşömen modeli yakın çekim (3 açı)
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.5).timeout
	Hud.close_dialog()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.45
	var pj = PathJutsu.get_pinst()
	var p = main.player.global_position + Vector3(0, 40, 0)
	var sc = pj.scroll_node(0.5, 0.35)
	pj.scene_add(sc, p)
	sc.scale = Vector3.ONE * 4.0
	main.player.set_process(false)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.current = true
	var views = {"on": Vector3(0, 0.3, -3.2), "yan": Vector3(-2.4, 0.8, -2.2), "ust": Vector3(0.6, 2.6, -1.6)}
	for k in views:
		cc.global_position = p + views[k]
		cc.look_at(p)
		await get_tree().create_timer(0.2).timeout
		await main.shot("scroll_" + k)
	get_tree().quit()
