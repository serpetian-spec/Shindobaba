extends Node
## El geometrisi ölçümü: RightHand/LeftHand ağırlıklı köşelerin el kemiği yerel AABB'si (dinlenme pozu)
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var m = main.player.model
	var sk: Skeleton3D = m.skel
	for side in ["Right", "Left"]:
		var bi = sk.find_bone(side + "Hand")
		var rest: Transform3D = sk.get_bone_global_rest(bi)
		var inv = rest.affine_inverse()
		var lo = Vector3(1e9, 1e9, 1e9)
		var hi = -lo
		var n = 0
		for mi in sk.find_children("*", "MeshInstance3D", true, false):
			var mesh: Mesh = mi.mesh
			if mesh == null or mi.skin == null:
				continue
			for si in mesh.get_surface_count():
				var arr = mesh.surface_get_arrays(si)
				var bones = arr[Mesh.ARRAY_BONES]
				var wts = arr[Mesh.ARRAY_WEIGHTS]
				var vs = arr[Mesh.ARRAY_VERTEX]
				if bones == null or bones.is_empty():
					continue
				var per = bones.size() / vs.size()
				for vi in vs.size():
					var best = -1
					var bw = 0.0
					for k in per:
						if wts[vi * per + k] > bw:
							bw = wts[vi * per + k]
							best = bones[vi * per + k]
					var sb = best
					if best < mi.skin.get_bind_count():
						sb = mi.skin.get_bind_bone(best)
						if sb < 0:
							sb = sk.find_bone(mi.skin.get_bind_name(best))
					if sb == bi or sb == sk.find_bone(side + "HandMiddle1") or sb == sk.find_bone(side + "HandIndex1"):
						var p = vs[vi] - rest.origin
						lo = lo.min(p)
						hi = hi.max(p)
						n += 1
		print("HAND ", side, " n=", n, " lo=", lo, " hi=", hi, " hand x axis(model)=", rest.basis.x.snapped(Vector3.ONE * 0.01), " y=", rest.basis.y.snapped(Vector3.ONE * 0.01), " origin=", rest.origin)
	get_tree().quit()
