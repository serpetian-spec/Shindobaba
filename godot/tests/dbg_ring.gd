extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	for st in ["kase", "uzun"]:
		CharacterModel._skull_cache.clear()
		var m = CharacterModel.new()
		main.add_child(m)
		m.setup({"gender": "f" if st == "kase" else "m", "hair_style": st, "band": Color(0.15, 0.2, 0.45), "band_style": "head", "village": "konoha"})
		m._band_ring_full()
		var rad: PackedFloat32Array = m.band_ring[1]
		var out = []
		for k in rad.size():
			var a = (float(k) + 0.5) / rad.size() * TAU - PI
			out.append("%d:%.3f" % [int(rad_to_deg(a)), rad[k]])
		print(st, " by=", m.band_ring[0], " skull_c=", m.skull_c, " ", " ".join(out))
		var bz_min = 9.0; var bz_max = -9.0
		for q in m.body_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			if absf(q.y - m.band_ring[0]) < 0.014 and absf(q.x) < 0.03:
				bz_min = minf(bz_min, q.z); bz_max = maxf(bz_max, q.z)
		print("  body z at band y (x~0): ", bz_min, " .. ", bz_max)
		m.queue_free()
	get_tree().quit()
