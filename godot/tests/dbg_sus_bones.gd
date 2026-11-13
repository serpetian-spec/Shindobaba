extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	var b = CharacterModel.new()
	add_child(b)
	b.setup({"gender": "m", "age": "adult", "top_style": "uzun", "pants_style": "ninja", "hair_style": "kısa", "band": null, "sleeves": true})
	await get_tree().process_frame
	var sk = b.skel
	for i in sk.get_bone_count():
		var n = sk.get_bone_name(i)
		if n.contains("Thumb") or n.contains("Index") or n.contains("Ring") or n.contains("Little") or n.contains("Intermediate") or n.contains("Distal"):
			if not n.begins_with("LeftMiddle"):
				continue
		var o = sk.get_bone_global_rest(i).origin
		print("BONE %s %.3f %.3f %.3f" % [n, o.x, o.y, o.z])
	print("SKXF ", sk.transform, " ", sk.get_parent().name)
	get_tree().quit()
