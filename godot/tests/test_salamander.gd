extends Node
## Büyük çağrıların yakın, önden çekimi
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.42
	var pl = main.player
	await get_tree().create_timer(2.0).timeout
	pl.set_process(false)
	TailedBeasts.set_process(false)
	var vv = Game.village("suna")
	var base = Game.from_map(Vector2(vv["x"] + float(vv["r"]) + 260, vv["y"] + 120))
	base.y = Game.terrain_height(base.x, base.z)
	pl.respawn(base + Vector3(30, 1, 30))
	await get_tree().create_timer(3.0).timeout
	var specs = [["salamander", 6.0, 26.0]]
	var _old = [["hawk_giant", 8.0, 8.0], ["monkey_small", 2.0, 2.0], ["toad_boss", 17.0, 17.0], ["toad_mid", 4.0, 4.0], ["toad_small", 1.0, 1.0], ["snake_giant", 4.0, 30.0], ["dog_small", 0.6, 0.8], ["snake_boss", 8.0, 70.0], ["slug_queen", 6.0, 14.0], ["wolf_giant", 6.0, 10.0], ["monkey_king", 9.0, 9.0], ["cat_giant", 6.0, 10.0], ["turtle_giant", 6.0, 14.0]]
	if OS.get_environment("SPECS") != "":
		specs = str_to_var(OS.get_environment("SPECS"))
	for spec in specs:
		var d = SummonModels.build(spec[0], spec[1], spec[2])
		var root: Node3D = d["root"]
		main.add_child(root)
		var p = base
		p.y = Game.terrain_height(p.x, p.z)
		root.global_position = p
		root.rotation.y = PI * 0.15
		var h: float = spec[1]
		var L: float = spec[2]
		var views = [Vector3(h * 0.9, h * 1.0, -L * 0.75), Vector3(L * 0.85, h * 0.9, 0.0), Vector3(-h * 1.6, h * 2.2, -L * 0.55)]
		for vi in views.size():
			pl.cam.global_position = p + Basis(Vector3.UP, root.rotation.y) * views[vi]
			pl.cam.look_at(p + Vector3.UP * h * 0.6 + Basis(Vector3.UP, root.rotation.y) * Vector3(0, 0, -L * 0.15))
			await get_tree().create_timer(0.4).timeout
			await main.shot("sal_%s_%d" % [spec[0], vi])
		root.queue_free()
	get_tree().quit()
