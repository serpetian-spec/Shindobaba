extends Node
var main: Node
func _tris(m: Mesh) -> int:
	var n = 0
	for s in m.get_surface_count():
		var a = m.surface_get_arrays(s)
		var idx = a[Mesh.ARRAY_INDEX]
		n += (idx.size() if idx != null else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return n
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	var pl = main.player
	var veg = Game.world.vegetation
	for t in veg.meshes:
		var line = "TİP %d:" % t
		for v in veg.meshes[t]:
			var parts = []
			for m in v:
				parts.append(str(_tris(m)) if m != null else "-")
			line += " [" + "/".join(parts) + "]"
		if veg.lods[t] != null:
			line += " lod=" + str(_tris(veg.lods[t]))
		print(line)
	var v = Game.village("konoha")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"]) + Vector2(-300, -float(v["r"]) - 600)))
	await get_tree().create_timer(6.0).timeout
	var cp = pl.cam.global_position
	var sums = {}
	for k in veg.chunks:
		for mmi in veg.chunks[k]["node"].get_children():
			if not mmi is MultiMeshInstance3D:
				continue
			var ab: AABB = mmi.global_transform * mmi.get_aabb()
			var d = cp.distance_to(ab.get_center())
			if mmi.visibility_range_begin > 0 and d < mmi.visibility_range_begin:
				continue
			if mmi.visibility_range_end > 0 and d > mmi.visibility_range_end + mmi.visibility_range_end_margin:
				continue
			var mm: MultiMesh = mmi.multimesh
			var key = "%s b%d sh%d" % [mm.mesh.resource_name if mm.mesh.resource_name != "" else str(mm.mesh.get_instance_id() % 10000), int(mmi.visibility_range_begin), mmi.cast_shadow]
			var tri = _tris(mm.mesh) * mm.instance_count
			sums[key] = sums.get(key, 0) + tri
	var arr = []
	for k in sums:
		arr.append([sums[k], k])
	arr.sort_custom(func(a, b): return a[0] > b[0])
	for e in arr.slice(0, 20):
		print("ÜÇGEN ", e[0], "  ", e[1])
	get_tree().quit()
