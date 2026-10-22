extends Node
var main: Node
func _ready() -> void:
	for g in ["m", "f"]:
		var m = CharacterModel.new()
		main.add_child(m)
		m.setup({"gender": g})
		var sk: Skeleton3D = m.skel
		var out = g + ": aabb=" + str(m.body_mesh.get_aabb()) + "\n"
		for b in ["Hips", "Spine", "Chest", "UpperChest", "Neck", "Head", "LeftShoulder", "LeftUpperArm", "LeftLowerArm", "LeftHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "LeftToes"]:
			var i = sk.find_bone(b)
			if i >= 0:
				out += "  %s %s\n" % [b, str(sk.get_bone_global_rest(i).origin)]
		print(out)
	get_tree().quit()
