extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.load_slot(97)
	await get_tree().create_timer(6.0).timeout
	var pl = main.player
	pl.respawn(Vector3(21921.0, 50.0, -17725.0))
	await get_tree().create_timer(6.0).timeout
	var pts = [Vector3(21921.0, 49.2, -17726.0), Vector3(21950.0, 49.2, -17716.0), Vector3(21792.0, 51.3, -18016.0), Vector3(21845.0, 52.8, -17945.0)]
	var n = 0
	var best = {}
	for cs in get_tree().root.find_children("*", "CollisionShape3D", true, false):
		if not cs.shape is ConvexPolygonShape3D:
			continue
		n += 1
		var gp: Vector3 = cs.global_position
		for i in pts.size():
			var d = Vector2(gp.x - pts[i].x, gp.z - pts[i].z).length()
			if not best.has(i) or d < best[i][0]:
				best[i] = [d, cs]
	print("CVX total=", n)
	for i in best:
		var cs = best[i][1]
		var aabb = AABB()
		var ptsx: PackedVector3Array = cs.shape.points
		for q in ptsx:
			aabb = aabb.expand(q)
		print("CVX pt", i, " d=", snappedf(best[i][0], 0.1), " pos=", cs.global_position.snapped(Vector3(0.1, 0.1, 0.1)), " size=", aabb.size.snapped(Vector3(0.1, 0.1, 0.1)), " dis=", cs.disabled, " path=", cs.get_path())
	# ayrıca o noktada aşağı ışın: ne üstünde duruluyor
	var space = get_viewport().world_3d.direct_space_state
	for p in pts:
		var h = space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP * 30, p - Vector3.UP * 30))
		print("CVX down ", p, " -> ", h.get("position", "yok"), " ", h.get("collider").get_path() if h.has("collider") else "")
	print("CVX player=", pl.global_position)
	get_tree().quit()
