extends Node
## Görünmez yapı dedektörü: köydeki görünen mesh'lerin üçgenleri ayrı bir fizik katmanına (20) kopyalanır; ızgara ışınları
## gerçek çarpışmaya çarpıp aynı yerde görünen yüzeye çarpmıyorsa "görünmez çarpışma" sayılır. VIDS=konoha,suna
var main: Node
const VIS_LAYER := 1 << 19


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.2, 0.15, 0.1), "top": Color(0.2, 0.3, 0.5), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	if OS.get_environment("LOAD") != "":   # oyuncunun kaydıyla (kopyası) tara: kendi önbelleği ve dünya durumu
		main.load_slot(int(OS.get_environment("LOAD")))
		await get_tree().create_timer(6.0).timeout
	else:
		main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var vids = OS.get_environment("VIDS").split(",", false)
	if vids.is_empty():
		vids = PackedStringArray(["konoha", "suna", "kiri", "kumo", "iwa"])
	for vid in vids:
		var v = Game.village(vid)
		if v.is_empty():
			continue
		var c = Game.from_map(Vector2(v["x"], v["y"]))
		var R = minf(float(v.get("r", 300.0)), 600.0)
		if OS.get_environment("VOFF") != "":   # köy dışı: merkezden kaydır (orman / çevre)
			var o = OS.get_environment("VOFF").split(",")
			c += Vector3(float(o[0]), 0, float(o[1]))
			c.y = Game.terrain_height(c.x, c.z)
		if OS.get_environment("VR") != "":
			R = float(OS.get_environment("VR"))
		pl.respawn(c)
		await get_tree().create_timer(float(OS.get_environment("WAIT")) if OS.get_environment("WAIT") != "" else 4.0).timeout   # sıfırdan kurulan köy (peyzaj) için uzun bekle
		pl.set_physics_process(false)
		# görünen geometri -> katman 20
		var faces = PackedVector3Array()
		var parts = []   # [küresel AABB, dönüşüm, yerel yüzler]: şüpheli noktayı yerel geometriyle yeniden doğrulamak için
		var nmesh = 0
		for mi in get_tree().root.find_children("*", "GeometryInstance3D", true, false):
			if not mi.is_visible_in_tree():
				continue
			var ab: AABB = mi.global_transform * mi.get_aabb()
			if Vector2(ab.get_center().x - c.x, ab.get_center().z - c.z).length() > R + ab.size.length() * 0.5:
				continue
			if mi is MeshInstance3D and mi.mesh != null:
				if mi.mesh.get_surface_count() == 0:
					continue
				var fx = mi.mesh.get_faces()
				var xf = mi.global_transform
				for q in fx:
					faces.append(xf * q)
				parts.append([ab, xf, fx])
				nmesh += 1
			elif mi is MultiMeshInstance3D and mi.multimesh != null and mi.multimesh.mesh != null:
				var mm: MultiMesh = mi.multimesh
				var fx = mm.mesh.get_faces()
				for i in mm.instance_count:
					var xf = mi.global_transform * mm.get_instance_transform(i)
					var p0 = xf.origin
					if Vector2(p0.x - c.x, p0.z - c.z).length() > R:
						continue
					for q in fx:
						faces.append(xf * q)
					parts.append([xf * mm.mesh.get_aabb(), xf, fx])
				nmesh += 1
		var sb = StaticBody3D.new()
		sb.collision_layer = VIS_LAYER
		sb.collision_mask = 0
		var cs = CollisionShape3D.new()
		var sh = ConcavePolygonShape3D.new()
		sh.backface_collision = true
		sh.set_faces(faces)
		cs.shape = sh
		sb.add_child(cs)
		add_child(sb)
		await get_tree().physics_frame
		await get_tree().physics_frame
		var space = get_viewport().world_3d.direct_space_state
		var bad = {}
		var nray = 0
		var step = 4.0
		var gx = -R
		while gx <= R:
			var gz = -R
			while gz <= R:
				if gx * gx + gz * gz < R * R * 0.9:
					var px = c.x + gx; var pz = c.z + gz
					var gy = Game.terrain_height(px, pz)
					for hh in [1.0, 2.6]:
						var o = Vector3(px, gy + hh, pz)
						for dd in [Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(0, 0, -1)]:
							nray += 1
							var q = PhysicsRayQueryParameters3D.create(o, o + dd * 4.0, 0xFFFFFFFF & ~VIS_LAYER)
							q.collide_with_areas = false
							var h1 = space.intersect_ray(q)
							if h1.is_empty():
								continue
							var col = h1["collider"]
							if col is CharacterBody3D or (col != null and col.is_in_group("fighters")):
								continue
							var shp = null
							if col is CollisionObject3D:
								var ow = col.shape_find_owner(int(h1["shape"]))
								shp = col.shape_owner_get_shape(ow, 0) if ow >= 0 else null
							if (shp is CylinderShape3D or shp is CapsuleShape3D or shp is SphereShape3D) and OS.get_environment("CYL") == "":
								continue   # ağaç gövdesi vb. (CYL=1 ile bunlar da denetlenir)
							var q2 = PhysicsRayQueryParameters3D.create(o, o + dd * 4.6, VIS_LAYER)
							var h2 = space.intersect_ray(q2)
							var d1 = o.distance_to(h1["position"])
							if d1 < 0.05:
								continue   # başlangıç zaten bir şeyin içinde
							if h2.is_empty() or o.distance_to(h2["position"]) > d1 + 0.6:
								var hp: Vector3 = h1["position"]
								var key = Vector2i(int(floor(hp.x / 3.0)), int(floor(hp.z / 3.0)))
								if not bad.has(key):
									var nm = String(col.name) if col else "?"
									var par = String(col.get_parent().name) if col and col.get_parent() else ""
									bad[key] = [hp, nm + "/" + par + " " + (shp.get_class() if shp else "?") + ((" %s" % str((shp as BoxShape3D).size)) if shp is BoxShape3D else ""), 0, o, dd, d1]
								bad[key][2] += 1
				gz += step
			gx += step
		# yerel doğrulama: dev tek ConcavePolygon (milyonlarca üçgen) ince gövdelerde ışın kaçırabiliyor -> şüpheli her hücreyi
		# yalnız çevresindeki görünür parçalardan kurulan küçük şekille yeniden dene; görünen yüzey yakınsa yanlış alarm
		var raw = bad.size()
		for key in bad.keys():
			var e = bad[key]
			var o: Vector3 = e[3]
			var lf = PackedVector3Array()
			for pt in parts:
				if (pt[0] as AABB).grow(1.0).intersects(AABB(o - Vector3(5, 5, 5), Vector3(10, 10, 10))):
					for q in pt[2]:
						lf.append(pt[1] * q)
			var ok = false
			if not lf.is_empty():
				var lb = StaticBody3D.new()
				lb.collision_layer = 1 << 20
				lb.collision_mask = 0
				var lcs = CollisionShape3D.new()
				var lsh = ConcavePolygonShape3D.new()
				lsh.backface_collision = true
				lsh.set_faces(lf)
				lcs.shape = lsh
				lb.add_child(lcs)
				add_child(lb)
				await get_tree().physics_frame
				space = get_viewport().world_3d.direct_space_state
				var h3 = space.intersect_ray(PhysicsRayQueryParameters3D.create(o, o + (e[4] as Vector3) * 4.6, 1 << 20))
				ok = not h3.is_empty() and o.distance_to(h3["position"]) <= float(e[5]) + 0.6
				if not ok:   # sıyırma ışını (gövde kenarı): çarpılan noktanın 0.3 m yakınında görünen yüzey varsa görünmez duvar değildir
					var sq = PhysicsShapeQueryParameters3D.new()
					var sph = SphereShape3D.new()
					sph.radius = 0.3
					sq.shape = sph
					sq.transform = Transform3D(Basis.IDENTITY, e[0])
					sq.collision_mask = 1 << 20
					ok = not space.intersect_shape(sq, 1).is_empty()
				lb.free()
			if ok:
				bad.erase(key)
		print("INVIS ", vid, " raw=", raw, " meshes=", nmesh, " faces=", faces.size() / 3, " rays=", nray, " bad_cells=", bad.size())
		var lst = bad.values()
		lst.sort_custom(func(a, b): return a[2] > b[2])
		for i in mini(25, lst.size()):
			var e = lst[i]
			var lp = Vector2((e[0] as Vector3).x - c.x, (e[0] as Vector3).z - c.z)
			print("   at local(%.0f, %.0f) y=%.1f hits=%d  %s" % [lp.x, lp.y, (e[0] as Vector3).y, e[2], e[1]])
		sb.queue_free()
		pl.set_physics_process(true)
	get_tree().quit()
