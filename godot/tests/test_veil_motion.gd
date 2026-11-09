extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "age": "adult", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "s2", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	var pl = main.player
	Game.profile["look"]["head_style"] = OS.get_environment("VH") if OS.get_environment("VH") != "" else "kage"
	Game.profile["look"]["kage_vid"] = "konoha"
	pl.rebuild_model()
	await get_tree().create_timer(0.5).timeout
	var vs = pl.model.find_children("KageVeil" if OS.get_environment("VH") == "" else "*", "Dangle" if OS.get_environment("VH") != "" else "", true, false)
	print("VEIL nodes=", vs.size())
	if vs.is_empty():
		get_tree().quit(); return
	var d = vs[0].get_parent()
	while d != null and not (d is Dangle):
		d = d.get_parent()
	var sk: Skeleton3D = d.skel
	pl.set_physics_process(false)
	var mx = 0.0
	for f in 40:
		pl.model.rotation.y += 0.25
		pl.global_position.x += 0.08
		await get_tree().process_frame
		for b in range(1, sk.get_bone_count()):
			mx = maxf(mx, sk.get_bone_pose_position(b).distance_to(sk.get_bone_rest(b).origin))
	print("VEIL chains=", d.chains.size(), " max_offset=", mx)
	get_tree().quit()
