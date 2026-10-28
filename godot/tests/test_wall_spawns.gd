extends Node
## Suna/Kiri/Iwa: köy içi görev noktaları, sokak/çatı NPC noktaları — duvar/kayalık içinde ya da üstünde olanları say (+ köy surunun çekimi)
var main: Node
func _blocked(q: Vector3) -> bool:
	var sq = PhysicsShapeQueryParameters3D.new()
	var sph = SphereShape3D.new()
	sph.radius = 0.4
	sq.shape = sph
	sq.collision_mask = 1
	sq.transform = Transform3D(Basis.IDENTITY, q + Vector3.UP * 1.0)
	return not main.player.get_world_3d().direct_space_state.intersect_shape(sq, 1).is_empty()

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	var pl = main.player
	await get_tree().create_timer(2.0).timeout
	var life = main.actors.get_node_or_null("VillageLife")
	for vid in ["suna", "kiri", "iwa"]:
		var v = Game.village(vid)
		var c = Game.from_map(Vector2(v["x"], v["y"]))
		var r = float(v["r"])
		pl.respawn(Missions.open_ground(c + Vector3(0, 0, r * 0.75), 40.0))
		await get_tree().create_timer(6.0).timeout
		var bad_inside = 0
		for i in 60:
			var q = Missions._w(Missions._inside(vid, 0.2, 0.8))
			q.y = Game.ground_height(q.x, q.z)
			if _blocked(q):
				bad_inside += 1
		var high = 0
		var near_wall = 0
		for n in life.npcs:
			if not is_instance_valid(n):
				continue
			var gy = Game.ground_height(n.global_position.x, n.global_position.z)
			if n.global_position.y - gy > 4.0:
				high += 1
			var dm = Game.to_map(n.global_position).distance_to(Vector2(v["x"], v["y"]))
			if dm > r * 0.9:
				near_wall += 1
		var roofs: Array = Builder.roof_points.get(vid, [])
		var wall_roofs = roofs.filter(func(q): return Game.to_map(q).distance_to(Vector2(v["x"], v["y"])) > r * 0.9).size()
		print("WALL %s inside_blocked=%d/60 npcs=%d high=%d near_wall=%d roofpts=%d wall_roofpts=%d" % [vid, bad_inside, life.npcs.size(), high, near_wall, roofs.size(), wall_roofs])
		pl.set_process(false)
		var cam = Camera3D.new()
		main.add_child(cam)
		cam.far = 4000
		cam.current = true
		var wallp = c + Vector3(0, 0, r * 1.0)
		wallp.y = Game.ground_height(wallp.x, wallp.z)
		cam.global_position = c + Vector3(r * 0.15, 25, r * 0.78)
		cam.look_at(wallp + Vector3(0, 10, 0))
		await get_tree().create_timer(0.5).timeout
		await main.shot("wall_%s_%s" % [vid, OS.get_environment("VER")])
		cam.queue_free()
		pl.set_process(true)
	get_tree().quit()
