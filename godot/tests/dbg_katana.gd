extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	for id in ["katana", "wakizashi", "chakura_to"]:
		var m = CharacterModel.weapon_mesh(id)
		print("WM %s %s" % [id, m.get_aabb() if m else "null"])
	get_tree().quit()
