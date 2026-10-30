extends Node
var main: Node
func _ready() -> void:
	for n in ["HairSample_Female", "HairSample_Male", "AvatarSample_A", "AvatarSample_B", "AvatarSample_C", "Darkness_Shibu", "Sakurada_Fumiriya", "Sendagaya_Shibu", "masc_vroid", "fem_vroid"]:
		var inst = load("res://assets/vrm/%s.glb" % n).instantiate()
		var names = []
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var mats = []
			for s in mi.mesh.get_surface_count():
				var m = mi.mesh.surface_get_material(s)
				mats.append(m.resource_name if m else "-")
			names.append("%s%s" % [mi.name, mats])
		print("DONOR ", n, ": ", names)
		inst.free()
	get_tree().quit()
