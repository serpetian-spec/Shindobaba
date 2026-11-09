
extends RefCounted
## F9: bulunduğun yerin çevresinde görünmez çarpışma taraması (dbg_invis'in oyun içi hâli).
## Görünen geometri ayrı bir fizik katmanına kopyalanır; ızgara ışınları gerçek çarpışmaya çarpıp aynı yerde görünen
## yüzeye çarpmıyorsa (0.3 m içinde görünen yüzey de yoksa) "görünmez" sayılır. Rapor: user://gorunmez_rapor.txt + ekran mesajı.
const VIS_LAYER := 1 << 19


static func run(tree: SceneTree, center: Vector3, R := 35.0) -> void:
	var faces = PackedVector3Array()
	for mi in tree.root.find_children("*", "GeometryInstance3D", true, false):
		if not mi.is_visible_in_tree():
			continue
		var ab: AABB = mi.global_transform * mi.get_aabb()
		if not ab.grow(R).has_point(center):
			continue
		if mi is MeshInstance3D and mi.mesh != null and mi.mesh.get_surface_count() > 0:
			var xf = mi.global_transform
			for q in mi.mesh.get_faces():
				faces.append(xf * q)
		elif mi is MultiMeshInstance3D and mi.multimesh != null and mi.multimesh.mesh != null:
			var mm: MultiMesh = mi.multimesh
			var fx = null
			for i in mm.instance_count:
				var xf = mi.global_transform * mm.get_instance_transform(i)
				if xf.basis.get_scale().length() < 0.01 or Vector2(xf.origin.x - center.x, xf.origin.z - center.z).length() > R + 20.0:
					continue   # gizlenmiş (yıkılan ev: 0.001 ölçek) ya da uzak
				if fx == null:
					fx = mm.mesh.get_faces()
				for q in fx:
					faces.append(xf * q)
	var sb = StaticBody3D.new()
	sb.collision_layer = VIS_LAYER
	sb.collision_mask = 0
	var cs = CollisionShape3D.new()
	var sh = ConcavePolygonShape3D.new()
	sh.backface_collision = true
	sh.set_faces(faces)
	cs.shape = sh
	sb.add_child(cs)
	tree.current_scene.add_child(sb)
	await tree.physics_frame
	await tree.physics_frame
	var space = tree.current_scene.get_viewport().world_3d.direct_space_state
	var bad = {}
	var gx = -R
	while gx <= R:
		var gz = -R
		while gz <= R:
			var px = center.x + gx; var pz = center.z + gz
			var gy = Game.terrain_height(px, pz)
			if absf(gy - center.y) < 25.0:
				for hh in [1.0, 2.6]:
					var o = Vector3(px, maxf(gy, center.y - 2.0) + hh, pz)
					for dd in [Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(0, 0, -1)]:
						var q = PhysicsRayQueryParameters3D.create(o, o + dd * 3.0, 0xFFFFFFFF & ~VIS_LAYER)
						q.collide_with_areas = false
						var h1 = space.intersect_ray(q)
						if h1.is_empty():
							continue
						var col = h1["collider"]
						if col is CharacterBody3D or (col != null and col.is_in_group("fighters")):
							continue
						var d1 = o.distance_to(h1["position"])
						if d1 < 0.05:
							continue
						var h2 = space.intersect_ray(PhysicsRayQueryParameters3D.create(o, o + dd * 3.6, VIS_LAYER))
						if not h2.is_empty() and o.distance_to(h2["position"]) <= d1 + 0.6:
							continue
						var sq = PhysicsShapeQueryParameters3D.new()
						var sph = SphereShape3D.new()
						sph.radius = 0.3
						sq.shape = sph
						sq.transform = Transform3D(Basis.IDENTITY, h1["position"])
						sq.collision_mask = VIS_LAYER
						if not space.intersect_shape(sq, 1).is_empty():
							continue
						var hp: Vector3 = h1["position"]
						var key = Vector2i(int(floor(hp.x / 2.0)), int(floor(hp.z / 2.0)))
						if not bad.has(key):
							var path = str(col.get_path()) if col and col.is_inside_tree() else "?"
							var shp = null
							if col is CollisionObject3D:
								var ow = col.shape_find_owner(int(h1["shape"]))
								shp = col.shape_owner_get_shape(ow, 0) if ow >= 0 else null
							bad[key] = "%s  %s  %s" % [str(hp.snapped(Vector3(0.1, 0.1, 0.1))), path, shp.get_class() if shp else "?"]
			gz += 1.5
		gx += 1.5
	sb.queue_free()
	var lines = ["Konum: %s  köy: %s  zaman: %s" % [str(center.snapped(Vector3(0.1, 0.1, 0.1))), Outfits.village_near(center), Time.get_datetime_string_from_system()]]
	lines.append("Görünmez çarpışma: %d nokta" % bad.size())
	for k in bad:
		lines.append("  " + String(bad[k]))
	var f = FileAccess.open("user://gorunmez_rapor.txt", FileAccess.READ_WRITE if FileAccess.file_exists("user://gorunmez_rapor.txt") else FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_string("\n".join(lines) + "\n\n")
	Hud.msg("Görünmez yapı taraması: %d nokta (rapor: gorunmez_rapor.txt)" % bad.size(), Color(1, 0.8, 0.4) if bad.size() > 0 else Color(0.6, 1, 0.6), 6.0)
