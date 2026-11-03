extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	var base = Vector3(0, 3000, 0)
	var ids = OS.get_environment("IDS").split(",", false) if OS.get_environment("IDS") != "" else PackedStringArray(["fuma_shuriken", "fuma_kapali", "kyodai_shuriken", "fuma_kare", "fuma_makimono"])
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	var sun = DirectionalLight3D.new()
	main.add_child(sun)
	sun.rotation_degrees = Vector3(-50, 30, 0)
	for i in ids.size():
		var mi = MeshInstance3D.new()
		mi.mesh = CharacterModel.weapon_mesh(ids[i])
		main.add_child(mi)
		mi.global_position = base
		var ab = mi.mesh.get_aabb()
		print("MESH ", ids[i], " aabb=", ab)
		var r = maxf(ab.size.length() * 0.7, 0.3)
		for vw in [["f", Vector3(0, 0, 1)], ["s", Vector3(1, 0.3, 0.2)]]:
			cam.global_position = base + ab.get_center() + (vw[1] as Vector3).normalized() * r * 1.6
			cam.look_at(base + ab.get_center())
			await get_tree().process_frame
			await get_tree().process_frame
			await main.shot("wm_%d_%s_%s" % [i, ids[i], vw[0]])
		mi.queue_free()
	get_tree().quit()
