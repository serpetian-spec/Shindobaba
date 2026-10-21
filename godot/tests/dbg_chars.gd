extends SceneTree
func _init():
	for p in ["res://assets/chars/Superhero_Male_FullBody.gltf", "res://assets/chars/hair/Hair_SimpleParted.gltf", "res://assets/chars/hair/Eyebrows_Regular.gltf"]:
		var s = load(p).instantiate()
		print("=== ", p)
		_walk(s, 0)
	quit()
func _walk(n, d):
	var extra = ""
	if n is Skeleton3D:
		extra = " bones=%d first=%s" % [n.get_bone_count(), n.get_bone_name(0)]
	if n is MeshInstance3D:
		extra = " surfaces=%d aabb=%s" % [n.mesh.get_surface_count(), n.get_aabb()]
		for i in n.mesh.get_surface_count():
			var m = n.mesh.surface_get_material(i)
			extra += " [%s %s]" % [m.resource_name if m else "-", m.albedo_texture.resource_path.get_file() if m and m is StandardMaterial3D and m.albedo_texture else ""]
	print("  ".repeat(d), n.name, " <", n.get_class(), ">", extra)
	for c in n.get_children(): _walk(c, d + 1)
