extends Node
## Binaların içinden geçilebiliyor mu? Konoha, başka köyler ve mezralarda yakındaki her büyük model örneğinin
## ayak izi içinde (zeminden 1 m yukarıda) 5 noktada çarpışma aranır; boş kalan örnekler raporlanır.
## Ardından oyuncu birkaç binaya doğru yürütülür ve içine girip girmediği ölçülür.
var main: Node
const R := 230.0


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var spots = []
	var kv = Game.village("konoha")
	for o in [Vector2(0, 0), Vector2(-540, 600), Vector2(350, -420), Vector2(-420, -300), Vector2(500, 250), Vector2(-1020, -640), Vector2(70, -30), Vector2(-150, 1000)]:
		spots.append(["konoha%+d%+d" % [o.x, o.y], Vector2(kv["x"], kv["y"]) + o])
	for vid in ["suna", "kiri", "iwa", "kumo"]:
		var v = Game.village(vid)
		if not v.is_empty():
			spots.append([vid, Vector2(v["x"], v["y"]) + Vector2(60, -80)])
			spots.append(["story_" + vid, BuildVillageStory._site(v)])
	var nh = 0
	for p in Game.pois:
		if p["t"] in ["hamlet", "inn"] and nh < 6:
			spots.append([p["t"] + str(nh), Vector2(p["x"], p["y"])])
			nh += 1
	var total_bad = 0
	var groups := {}
	for s in spots:
		var p = Game.from_map(s[1])
		p.y = Game.terrain_height(p.x, p.z) + 1.0
		main.player.respawn(p)
		await get_tree().create_timer(7.0).timeout
		var r = _probe(Vector2(p.x, p.z), s[0], groups)
		total_bad += r
		await _walk_into(p, s[0])
	var keys = groups.keys()
	keys.sort_custom(func(a, b): return groups[a][1] > groups[b][1])
	for k in keys:
		var gr = groups[k]
		if gr[1] == 0:
			print("TAMAM %-60s %d" % [k, gr[0]])
		else:
			print("BOS  %-60s %d/%d  ör: %s" % [k, gr[1], gr[0], gr[2]])
	print("BINA_CARPISMA toplam boş örnek=", total_bad, " yürüyüşte içeri giren=", walk_in, "/", walk_n)
	get_tree().quit()


var walk_in := 0
var walk_n := 0


## yakın evlere 14 m'den koşarak dal: gövdenin içine girilirse say
func _walk_into(c: Vector3, label: String) -> void:
	var pl = main.player
	var picks = []
	for k in Builder.roof_points:
		for rp in Builder.roof_points[k]:
			if Vector2(rp.x, rp.z).distance_to(Vector2(c.x, c.z)) < 160.0:
				picks.append(rp)
	picks.shuffle()
	for rp in picks.slice(0, 5):
		var ang = randf() * TAU
		var st = rp + Vector3(sin(ang), 0, cos(ang)) * 14.0
		st.y = Game.terrain_height(st.x, st.z) + 0.3
		pl.respawn(st)
		var d = (rp - st)
		pl.yaw = rad_to_deg(atan2(-d.x, -d.z))
		await get_tree().create_timer(0.4).timeout
		Input.action_press("forward")
		var inside = false
		for i in 200:
			await get_tree().physics_frame
			var q = pl.global_position
			if Vector2(q.x, q.z).distance_to(Vector2(rp.x, rp.z)) < 1.8 and q.y < rp.y - 2.5:
				inside = true
		Input.action_release("forward")
		walk_n += 1
		if inside:
			walk_in += 1
			print("ICERI ", label, " ev=", Vector3i(rp), " oyuncu=", Vector3i(pl.global_position))


func _probe(c: Vector2, label: String, groups: Dictionary) -> int:
	var space = main.player.get_world_3d().direct_space_state
	var q = PhysicsShapeQueryParameters3D.new()
	var sph = SphereShape3D.new()
	sph.radius = 0.35
	q.shape = sph
	q.collision_mask = 1
	q.exclude = [main.player.get_rid()]
	var names := {}
	for k in AssetLib._cache:
		var m = AssetLib._cache[k]
		if m != null:
			names[m] = String(k).replace("res://assets/", "").left(70)
	for k in AssetLib._cache:
		var ks = String(k)
		if ks.begins_with("lod|") and AssetLib._cache[k] != null:
			var src = instance_from_id(int(ks.split("|")[1]))
			names[AssetLib._cache[k]] = "LOD:" + names.get(src, ks)
	for i in HouseKit.templates.size():
		for part in ["walls", "roof", "detail"]:
			names[HouseKit.templates[i][part]] = "housekit_%s_%d" % [part, i]
	var bad = 0
	for gi in get_tree().root.find_children("*", "GeometryInstance3D", true, false):
		if not gi.is_visible_in_tree():
			continue
		var xfs: Array = []
		var a: AABB
		var mname := ""
		if gi is MultiMeshInstance3D:
			var mm: MultiMesh = gi.multimesh
			if mm == null or mm.mesh == null:
				continue
			if gi.visibility_range_begin > 0.0:
				continue  # LOD kopyası
			a = mm.mesh.get_aabb()
			mname = names.get(mm.mesh, "?")
			for i in mm.instance_count:
				xfs.append(gi.global_transform * mm.get_instance_transform(i))
		elif gi is MeshInstance3D and gi.mesh != null:
			a = gi.mesh.get_aabb()
			if a.size.length() > 90.0 or gi.mesh is PrimitiveMesh:
				continue  # birleşik hücre görselleri / basit parçalar
			if gi.get_parent() is Skeleton3D or String(gi.get_parent().name).contains("Skeleton"):
				continue  # Hokage başları vb. (ayrı çarpışma)
			mname = names.get(gi.mesh, "sahne:" + String(gi.get_parent().get_parent().name if gi.get_parent().get_parent() else gi.get_parent().name) + "/" + gi.name)
			xfs.append(gi.global_transform)
		else:
			continue
		if mname == "?":
			if String(gi.get_parent().name).begins_with("@"):
				continue
			mname = "?" + gi.get_parent().name
		var low = mname.to_lower()
		if low.contains("nature/") or low.contains("bamboo") or low.contains("rock") or low.contains("vegetation") or low.contains("tree_") or low.contains("trees"):
			continue  # bitki örtüsü / kaya: ayrı sistem
		var gname = mname
		for xf in xfs:
			var o: Vector3 = xf.origin
			if Vector2(o.x, o.z).distance_to(c) > R:
				continue
			var sx = xf.basis.x.length(); var sy = xf.basis.y.length(); var sz = xf.basis.z.length()
			if a.size.x * sx < 3.5 or a.size.z * sz < 3.5 or a.size.y * sy < 2.6:
				continue
			var hollow = 0
			for f in [Vector2(0.5, 0.5), Vector2(0.27, 0.5), Vector2(0.73, 0.5), Vector2(0.5, 0.27), Vector2(0.5, 0.73)]:
				var lp = Vector3(a.position.x + a.size.x * f.x, 0.0, a.position.z + a.size.z * f.y)
				var wp: Vector3 = xf * lp
				var gy = maxf(Game.terrain_height(wp.x, wp.z), (xf * Vector3(lp.x, a.position.y, lp.z)).y)
				q.transform = Transform3D(Basis(), Vector3(wp.x, gy + 1.0, wp.z))
				var hit = false
				for h in space.intersect_shape(q, 8):
					if h["collider"] is StaticBody3D:
						hit = true
						break
				if not hit:
					hollow += 1
			if not groups.has(gname):
				groups[gname] = [0, 0, ""]
			groups[gname][0] += 1
			if hollow >= (1 if mname.begins_with("housekit_walls") else 2):
				groups[gname][1] += 1
				if groups[gname][2] == "":
					groups[gname][2] = "%s (%d,%d,%d) %dx%dx%d" % [label, o.x, o.y, o.z, a.size.x * sx, a.size.y * sy, a.size.z * sz]
				bad += 1
	return bad
