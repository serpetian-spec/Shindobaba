extends SceneTree
func _init():
	var s = load("res://assets/anim/ual2.glb").instantiate()
	var sk = s.find_child("GeneralSkeleton", true, false)
	for c in sk.get_children():
		if c is MeshInstance3D:
			var skin = c.skin
			print("skin binds: ", skin.get_bind_count() if skin else -1)
			if skin:
				for i in min(8, skin.get_bind_count()):
					print("  bind ", i, " name='", skin.get_bind_name(i), "' bone=", skin.get_bind_bone(i))
			var arr = c.mesh.surface_get_arrays(0)
			var v = arr[Mesh.ARRAY_VERTEX]; var b = arr[Mesh.ARRAY_BONES]; var w = arr[Mesh.ARRAY_WEIGHTS]
			print("verts ", v.size(), " bones ", b.size() if b else -1, " weights ", w.size() if w else -1, " format ", c.mesh.surface_get_format(0))
			print("first bones: ", b.slice(0, 8) if b else null)
			print("mat: ", c.mesh.surface_get_material(0), " override: ", c.get_surface_override_material(0))
	quit()
