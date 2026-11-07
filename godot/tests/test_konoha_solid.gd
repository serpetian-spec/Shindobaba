extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(4.0).timeout
	var rp: Array = Builder.roof_points.get("konoha", [])
	var space = main.player.get_world_3d().direct_space_state
	var hit = 0
	var n = 0
	for k in range(0, rp.size(), maxi(1, rp.size() / 300)):
		var c: Vector3 = rp[k]
		var g = Game.ground_height(c.x, c.z)
		var q = PhysicsPointQueryParameters3D.new()
		q.position = Vector3(c.x, g + 1.0, c.z)
		q.collision_mask = 1
		n += 1
		if not space.intersect_point(q, 1).is_empty():
			hit += 1
	print("SOLID konoha houses sampled=%d solid=%d" % [n, hit])
	get_tree().quit()
