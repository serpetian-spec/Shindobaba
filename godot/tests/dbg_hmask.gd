extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	for st in ["uzun", "kase"]:
		var m = CharacterModel.new()
		main.add_child(m)
		m.setup({"gender": "f", "hair_style": st, "band": Color(0.15, 0.2, 0.45), "band_style": "head", "village": "konoha"})
		print(st, " slabs=", m._hm_slabs, " skull_c=", m.skull_c, " band_y=", m.band_ring[0], " mats=", m._hair_mats.size())
		for e in m._hair_mats:
			print("  mat hm_on=", e[0].get_shader_parameter("hm_on"), " shader=", e[0].shader.resource_path)
		for mi in m.find_children("*", "MeshInstance3D", true, false):
			if mi.name != "VHair":
				continue
			var xf: Transform3D = m._hair_mats[m._hair_mats.size() - 1][1]
			var sl = m._hm_slabs[0]
			var n_in = 0; var n_cut = 0; var front_out = 0
			for si in mi.mesh.get_surface_count():
				for v in mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]:
					var p = xf * v
					if p.y > sl[0].x and p.y < sl[0].y:
						n_in += 1
						var q = (Vector2(p.x, p.z) - sl[1]) / Vector2(sl[0].z, sl[0].w)
						if q.length_squared() > 1.0:
							n_cut += 1
						if p.z > m.skull_c.z + 0.06:
							front_out += 1
			print("  VHair in_slab=", n_in, " cut=", n_cut, " front=", front_out)
		m.queue_free()
	get_tree().quit()
