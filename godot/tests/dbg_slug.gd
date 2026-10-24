extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	var d = SummonModels.build("slug_queen", 14.0, 34.0)
	var root: Node3D = d["root"]
	add_child(root)
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		print("MI %s parent=%s aabb=%s verts=%d" % [mi.name, mi.get_parent().name, mi.get_aabb(), mi.mesh.surface_get_array_len(0) if mi.mesh.get_surface_count() > 0 else -1])
	print("HEAD ", d["head"].position if d["head"] else null)
	get_tree().quit()
