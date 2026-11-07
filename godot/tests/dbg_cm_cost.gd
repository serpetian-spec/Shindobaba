extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	print("---- enemies")
	for kind in ["rogue", "bandit", "rogue", "samurai", "rogue", "rogue"]:
		var a = Enemy.archetype(kind, 0)
		var e = Enemy.new()
		e.setup(a)
		var t = Time.get_ticks_usec()
		get_tree().current_scene.add_child(e)
		print("ENEMY %s total=%.1fms" % [kind, (Time.get_ticks_usec() - t) / 1000.0])
		e.global_position = main.player.global_position + Vector3(randf_range(-5, 5), 0, 8)
		await get_tree().process_frame
	get_tree().quit()
