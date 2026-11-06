extends Node
## Kök çarpışması: kökler üzerinde yukarıdan ışın — fizik çarpışma yüksekliği vs görünen mesh yüksekliği (fark ~0 olmalı)
var main: Node

func _mesh_y(faces: PackedVector3Array, x: float, z: float, top := 50.0) -> float:
	var best := -INF
	for i in range(0, faces.size(), 3):
		var h = Geometry3D.ray_intersects_triangle(Vector3(x, top, z), Vector3.DOWN, faces[i], faces[i + 1], faces[i + 2])
		if h != null:
			best = maxf(best, (h as Vector3).y)
	return best

func _ready() -> void:
	await get_tree().process_frame
	var w3d = get_viewport().world_3d
	for kind in ["giant", "oak", "broad"]:
		var m: ArrayMesh = AnimeTree.mesh(kind, "green", 1)
		var origin = Vector3(5000, 200, 5000)
		var sb = StaticBody3D.new()
		add_child(sb)
		sb.global_position = origin
		for L in (m.get_meta("roots", []) as Array):
			var a: Vector3 = L[0]; var b: Vector3 = L[1]
			var cs = CollisionShape3D.new()
			var cap = CapsuleShape3D.new()
			cap.radius = maxf(0.12, float(L[2]))
			cap.height = maxf(cap.radius * 2.0 + 0.01, (b - a).length() + cap.radius * 2.0)
			cs.shape = cap
			cs.transform = AnimeTree.limb_xf(a, b)
			sb.add_child(cs)
		await get_tree().physics_frame
		await get_tree().physics_frame
		var faces = m.surface_get_arrays(0)
		var fv := PackedVector3Array()
		var verts: PackedVector3Array = faces[Mesh.ARRAY_VERTEX]
		var idx = faces[Mesh.ARRAY_INDEX]
		if idx != null and (idx as PackedInt32Array).size() > 0:
			for i in idx:
				fv.append(verts[i])
		else:
			fv = verts
		var roots: Array = m.get_meta("roots", [])
		var worst := 0.0
		var bumps := 0
		var holes := 0
		var n := 0
		for r in roots:
			for k in 6:
				var p: Vector3 = (r[0] as Vector3).lerp(r[1], 0.15 + k * 0.14)
				var trunk_r = (roots[0][0] as Vector3).y / 1.6
				if Vector2(p.x, p.z).length() < trunk_r * 1.1:
					continue   # gövdenin içi (gövdenin kendi silindir çarpışması var)
				var top = maxf((r[0] as Vector3).y, (r[1] as Vector3).y) + 2.5
				var my = _mesh_y(fv, p.x, p.z, top)
				if my == -INF or my < 0.15:
					continue
				var q = PhysicsRayQueryParameters3D.create(origin + Vector3(p.x, top, p.z), origin + Vector3(p.x, -5, p.z))
				var hit = w3d.direct_space_state.intersect_ray(q)
				var py = (hit["position"].y - origin.y) if not hit.is_empty() else -INF
				n += 1
				var dif = py - my
				if kind == "giant" and roots.find(r) < 4 and absf(dif) > 0.3:
					print("  kök%d t=%.2f p=(%.2f,%.2f) mesh_y=%.2f fizik_y=%.2f fark=%.2f" % [roots.find(r), 0.15 + k * 0.14, p.x, p.z, my, py, dif])
				if dif > 0.35: bumps += 1
				if dif < -0.5: holes += 1
				worst = maxf(worst, absf(dif) if py != -INF else 99.0)
		print("ROOTS %s kök kapsülü=%d örnek=%d görünmez_tümsek(>0.35m)=%d içinden_geçme(<-0.5m)=%d en_kötü=%.2f m" % [kind, roots.size(), n, bumps, holes, worst])
		sb.queue_free()
	get_tree().quit()
