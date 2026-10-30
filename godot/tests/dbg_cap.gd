extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	var m = CharacterModel.new()
	main.add_child(m)
	m.setup({"gender": "m", "hair_style": "diken", "hair": Color(1, 0, 1), "top_style": "uzun", "band": null})
	print("CAP eye=", m.eye_center_model, " skull_c=", m.skull_c, " skull_r=", m.skull_r, " head_ab=", m.head_ab)
	var hb = m.skel.get_bone_global_rest(m.skel.find_bone("Head"))
	print("CAP headbone=", hb.origin, " basis z=", hb.basis.z)
	var cap = CharacterModel._scalp_cap(m.skull_c, m.skull_r, 1.0, m.eye_center_model.y, m.head_ab)
	print("CAP verts=", cap.get_surface_count(), " ", cap.surface_get_array_len(0) if cap.get_surface_count() > 0 else 0, " aabb=", cap.get_aabb())
	get_tree().quit()
