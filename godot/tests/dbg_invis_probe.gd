extends Node
## Görünmez çarpışma noktası sondası: PTS="vid:x,z;vid:x,z" (köy merkezine göre yerel). Her nokta için 3 m içindeki
## çarpışma şekilleri (sınıf, boyut, yol) ve AABB'si noktayı kapsayan görsel düğümler (görünür mü, menzil) yazılır.
var main: Node


func _path(n: Node) -> String:
	var s = String(n.name)
	var p = n.get_parent()
	for i in 4:
		if p == null:
			break
		s = String(p.name) + "/" + s
		p = p.get_parent()
	return s


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.2, 0.15, 0.1), "top": Color(0.2, 0.3, 0.5), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	for item in OS.get_environment("PTS").split(";", false):
		var a = item.split(":")
		var v = Game.village(a[0])
		var xz = a[1].split(",")
		var c = Game.from_map(Vector2(v["x"], v["y"]))
		var p = c + Vector3(float(xz[0]), 0, float(xz[1]))
		p.y = Game.terrain_height(p.x, p.z)
		pl.respawn(p + Vector3(6, 0, 6))
		await get_tree().create_timer(4.0).timeout
		print("== ", item, " world=", p)
		for cs in get_tree().root.find_children("*", "CollisionShape3D", true, false):
			if cs.disabled or cs.shape == null:
				continue
			var gp: Vector3 = cs.global_position
			if Vector2(gp.x - p.x, gp.z - p.z).length() > 3.5:
				continue
			var sh = cs.shape
			var info = sh.get_class()
			if sh is CylinderShape3D:
				info += " r=%.2f h=%.2f" % [sh.radius, sh.height]
			elif sh is BoxShape3D:
				info += " " + str(sh.size)
			print("  COL ", info, " at ", gp.snapped(Vector3(0.01, 0.01, 0.01)), " ", _path(cs))
		for mi in get_tree().root.find_children("*", "GeometryInstance3D", true, false):
			var ab: AABB = mi.global_transform * mi.get_aabb()
			if not ab.grow(0.5).has_point(Vector3(p.x, ab.get_center().y, p.z)):
				continue
			if ab.size.length() > 300.0 and not (mi is MultiMeshInstance3D):
				continue
			var extra = ""
			if mi is MultiMeshInstance3D and mi.multimesh:
				var near = 0
				var nears = ""
				for i in mi.multimesh.instance_count:
					var o = (mi.global_transform * mi.multimesh.get_instance_transform(i)).origin
					if Vector2(o.x - p.x, o.z - p.z).length() < 3.0:
						near += 1
						nears += " @" + str(o.snapped(Vector3(0.01, 0.01, 0.01)))
				if near == 0:
					continue
				extra = " mm_inst=%d near=%d%s mesh=%s meta=%s" % [mi.multimesh.instance_count, near, nears, mi.multimesh.mesh.resource_name, str(mi.multimesh.mesh.get_meta("anime_tree", ""))]
			print("  VIS vis=", mi.is_visible_in_tree(), " rng=", mi.visibility_range_begin, "-", mi.visibility_range_end, " aabb=", ab.size.snapped(Vector3(0.1, 0.1, 0.1)), extra, " ", _path(mi))
		# yerel görünür geometri -> katman 20, sonra çarpışma merkezine doğru ışınlar
		var faces = PackedVector3Array()
		for mi in get_tree().root.find_children("*", "GeometryInstance3D", true, false):
			if not mi.is_visible_in_tree() or mi.visibility_range_begin > 1.0:
				continue
			if mi is MeshInstance3D and mi.mesh != null and mi.mesh.get_surface_count() > 0:
				var ab: AABB = mi.global_transform * mi.get_aabb()
				if not ab.grow(6.0).has_point(p + Vector3(0, ab.get_center().y - p.y, 0)):
					continue
				for q in mi.mesh.get_faces():
					faces.append(mi.global_transform * q)
			elif mi is MultiMeshInstance3D and mi.multimesh != null and mi.multimesh.mesh != null:
				var mm: MultiMesh = mi.multimesh
				var fx = null
				for i in mm.instance_count:
					var xf = mi.global_transform * mm.get_instance_transform(i)
					if Vector2(xf.origin.x - p.x, xf.origin.z - p.z).length() > 12.0:
						continue
					if fx == null:
						fx = mm.mesh.get_faces()
					for q in fx:
						faces.append(xf * q)
		var sb = StaticBody3D.new()
		sb.collision_layer = 1 << 19
		var cs2 = CollisionShape3D.new()
		var sh2 = ConcavePolygonShape3D.new()
		sh2.backface_collision = true
		sh2.set_faces(faces)
		cs2.shape = sh2
		sb.add_child(cs2)
		add_child(sb)
		await get_tree().physics_frame
		await get_tree().physics_frame
		var space = get_viewport().world_3d.direct_space_state
		for cs in get_tree().root.find_children("*", "CollisionShape3D", true, false):
			if not (cs.shape is CylinderShape3D) or cs.disabled:
				continue
			var gp: Vector3 = cs.global_position
			if Vector2(gp.x - p.x, gp.z - p.z).length() > 3.5:
				continue
			var base_y = gp.y - cs.shape.height * 0.5
			for hh in [1.0, 2.6]:
				var line = "  RAY h=%.1f" % hh
				for k in 8:
					var ang = TAU * k / 8.0
					var dd = Vector3(cos(ang), 0, sin(ang))
					var o = Vector3(gp.x, base_y + hh, gp.z) + dd * 3.0
					var q1 = PhysicsRayQueryParameters3D.create(o, o - dd * 3.0, ~(1 << 19))
					var h1 = space.intersect_ray(q1)
					var q2 = PhysicsRayQueryParameters3D.create(o, o - dd * 3.0, 1 << 19)
					var h2 = space.intersect_ray(q2)
					line += "  %s/%s" % [("%.2f" % o.distance_to(h1["position"])) if not h1.is_empty() else "-", ("%.2f" % o.distance_to(h2["position"])) if not h2.is_empty() else "-"]
				print(line)
		sb.queue_free()
	get_tree().quit()
