extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	for k in Gear.ITEMS:
		var it = Gear.ITEMS[k]
		if not it.has("weapon") or it.has("removed"):
			continue
		var m = CharacterModel.weapon_mesh(k)
		if m == null:
			print("WB ", k, " | mesh YOK")
			continue
		var bb: AABB = m.get_aabb()
		print("WB %s | z %.2f..%.2f | table %s" % [k, bb.position.z, bb.end.z, str(CharacterModel.KEY_WEAPON.get(k, "-"))])
	get_tree().quit()
