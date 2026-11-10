extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	for f in DirAccess.get_files_at("user://bake"):
		if not f.ends_with(".scn"):
			continue
		var ps = ResourceLoader.load("user://bake/" + f, "", ResourceLoader.CACHE_MODE_IGNORE)
		if not ps is PackedScene:
			continue
		var root = ps.instantiate()
		var n = 0; var bad = 0; var bad_inst = 0; var tot_inst = 0
		for m in root.find_children("*", "MultiMeshInstance3D", true, false):
			if m.multimesh == null or m.multimesh.instance_count == 0:
				continue
			n += 1
			tot_inst += m.multimesh.instance_count
			if m.multimesh.get_aabb().size.length() < 0.001:
				bad += 1
				bad_inst += m.multimesh.instance_count
		print("BAKE ", f, " mm=", n, " bad=", bad, " inst=", tot_inst, " bad_inst=", bad_inst)
		root.free()
	get_tree().quit()
