extends SceneTree
func _init():
	var s = load("res://assets/anim/ual2.glb").instantiate()
	var sk = s.find_child("GeneralSkeleton", true, false)
	for c in sk.get_children():
		if c is MeshInstance3D:
			var skin = c.skin
			for si in c.mesh.get_surface_count():
				var arr = c.mesh.surface_get_arrays(si)
				var v = arr[Mesh.ARRAY_VERTEX]; var b = arr[Mesh.ARRAY_BONES]; var w = arr[Mesh.ARRAY_WEIGHTS]
				var per = b.size() / v.size()
				var hist = {}
				var ymin = 99.0; var ymax = -99.0
				for i in v.size():
					var best = -1.0; var bn = ""
					for k in per:
						if w[i*per+k] > best:
							best = w[i*per+k]; bn = skin.get_bind_name(b[i*per+k])
					hist[bn] = hist.get(bn, 0) + 1
					ymin = min(ymin, v[i].y); ymax = max(ymax, v[i].y)
				print("surface ", si, " verts ", v.size(), " y ", ymin, "..", ymax)
				print(hist)
	quit()
