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
	var base = pl.global_position + Vector3(0, 0, -30)
	for spec in [["hawk_giant", 8.0, 8.0], ["monkey_small", 2.0, 2.0], ["toad_boss", 17.0, 17.0], ["toad_mid", 4.0, 4.0], ["toad_small", 1.0, 1.0], ["snake_giant", 4.0, 30.0], ["dog_small", 0.6, 0.8], ["snake_boss", 8.0, 70.0], ["slug_queen", 6.0, 14.0], ["wolf_giant", 6.0, 10.0], ["monkey_king", 9.0, 9.0], ["cat_giant", 6.0, 10.0], ["turtle_giant", 6.0, 14.0]]:
		var d = SummonModels.build(spec[0], spec[1], spec[2])
		var root: Node3D = d["root"]
		main.add_child(root)
		var p = base
		p.y = Game.terrain_height(p.x, p.z)
		root.global_position = p
		root.rotation.y = PI * 0.15
		var h: float = spec[1]
		pl.cam.global_position = p + Basis(Vector3.UP, root.rotation.y) * Vector3(h * 0.6, h * 0.7, -h * 1.9)
		pl.cam.look_at(p + Vector3.UP * h * 0.5)
		await get_tree().create_timer(0.4).timeout
		await main.shot("sc_%s" % spec[0])
		root.queue_free()
	get_tree().quit()
