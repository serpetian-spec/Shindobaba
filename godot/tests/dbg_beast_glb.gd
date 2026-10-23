extends SceneTree
## Hayran yapımı canavar modellerinin iskelet/animasyon/boy envanteri (headless --script)

func _init() -> void:
	for f in ["kurama_calfan", "kurama_jdavid", "kurama_kyubi", "kurama_bijuu_mode", "nine_tailed_fox_generic", "nine_tails_deion", "shukaku", "gyuki", "tanuki_lowpoly_anim", "fox_pxltiger_anim"]:
		var p = "res://assets/sketchfab/%s/%s.glb" % [f, f]
		if not ResourceLoader.exists(p):
			var d = DirAccess.open("res://assets/sketchfab/%s" % f)
			var found = ""
			if d:
				for x in d.get_files():
					if x.ends_with(".glb") or x.ends_with(".gltf"):
						found = "res://assets/sketchfab/%s/%s" % [f, x]
			if found == "":
				print(f, ": YOK")
				continue
			p = found
		var sc = load(p)
		if sc == null:
			print(f, ": yüklenemedi")
			continue
		var inst: Node3D = sc.instantiate()
		var sk = inst.find_children("*", "Skeleton3D", true, false)
		var aps = inst.find_children("*", "AnimationPlayer", true, false)
		var meshes = inst.find_children("*", "MeshInstance3D", true, false)
		var anims = []
		for ap in aps:
			for a in ap.get_animation_list():
				anims.append("%s(%.1fs)" % [a, ap.get_animation(a).length])
		var bones = []
		for s in sk:
			for i in mini(s.get_bone_count(), 400):
				bones.append(s.get_bone_name(i))
		var tv = 0
		for m in meshes:
			if m.mesh:
				for si in m.mesh.get_surface_count():
					tv += (m.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		print("%s | path %s | skel %d bones %d | anims %s | meshes %d verts %d" % [f, p, sk.size(), bones.size(), str(anims), meshes.size(), tv])
		if bones.size() > 0:
			print("   bones: ", ", ".join(bones.slice(0, 80)))
		inst.free()
	quit()
