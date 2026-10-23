extends Node
var main: Node
func _ready() -> void:
	for f in ["frog", "snake", "shiba"]:
		var n: Node3D = (load("res://assets/packs/%s.glb" % f) as PackedScene).instantiate()
		add_child(n)
		var sk: Skeleton3D = n.find_child("*", true, false) as Skeleton3D
		for c in n.find_children("*", "Skeleton3D", true, false):
			sk = c
		var names = []
		for i in sk.get_bone_count():
			names.append(sk.get_bone_name(i))
		var ab = AABB()
		var first = true
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var a = mi.global_transform * mi.get_aabb()
			ab = a if first else ab.merge(a)
			first = false
		var ap: AnimationPlayer = n.find_child("AnimationPlayer", true, false)
		print("GLB ", f, " aabb=", ab, " bones=", names)
	get_tree().quit()
