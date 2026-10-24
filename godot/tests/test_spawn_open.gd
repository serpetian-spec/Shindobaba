extends Node
## Ryūchi İni çevresinde düşman doğma noktaları: ham zemin noktası kaya içinde mi, open_ground sonrası açık mı
var main: Node
func _blocked(q: Vector3) -> bool:
	var space = Game.world.get_world_3d().direct_space_state
	var sq = PhysicsShapeQueryParameters3D.new()
	var sph = SphereShape3D.new()
	sph.radius = 0.5
	sq.shape = sph
	sq.collision_mask = 1
	sq.transform = Transform3D(Basis.IDENTITY, q + Vector3.UP * 1.1)
	return not space.intersect_shape(sq, 1).is_empty()

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var at: Array = LegendPaths.lairs["yilan"]
	var c = Game.from_map(Vector2(float(at[0]), float(at[1])))
	pl.respawn(c + Vector3(0, 0, 20))
	await get_tree().create_timer(4.0).timeout
	var raw_bad = 0
	var fix_bad = 0
	for i in 200:
		var a = randf() * TAU
		var q = c + Vector3(cos(a), 0, sin(a)) * randf_range(0.0, 55.0)
		q.y = Game.ground_height(q.x, q.z)
		if _blocked(q):
			raw_bad += 1
		if _blocked(Missions.open_ground(q, 30.0)):
			fix_bad += 1
	print("SPAWN raw_blocked=%d/200 fixed_blocked=%d/200" % [raw_bad, fix_bad])
	get_tree().quit()
