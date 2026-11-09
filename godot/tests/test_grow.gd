extends Node
var main: Node
func _h(pl) -> String:
	var sk: Skeleton3D = pl.model.skel
	var hb = sk.find_bone("Head")
	var hy = (sk.global_transform * sk.get_bone_global_pose(hb)).origin.y - pl.global_position.y
	return "scale=%s age=%s age_scale=%.2f head_h=%.2f pscale=%s" % [str(pl.model.scale), pl.model.look.get("age"), pl.model.age_scale, hy, str(pl.scale)]
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "kumo", "hair_style": "s2", "hair": Color(0.8, 0.3, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(4.0).timeout
	var pl = main.player
	print("GROW start ", _h(pl), " rank=", Game.profile.get("rank"))
	Exams.academy_talk()
	await get_tree().create_timer(1.5).timeout
	print("GROW in_dialog ", _h(pl))
	Hud.close_dialog()
	await get_tree().create_timer(1.0).timeout
	print("GROW after ", _h(pl))
	# hocanın ders/antrenman diyalogları (görev akışı)
	for i in 6:
		if Hud.has_method("dialog_open") and Hud.dialog_open():
			Hud.close_dialog()
		Progress.on_talk("hoca") if Progress.has_method("on_talk") else null
		await get_tree().create_timer(0.8).timeout
		print("GROW step", i, " ", _h(pl), " rank=", Game.profile.get("rank"))
	pl.respawn(pl.global_position + Vector3(2, 0, 0))
	await get_tree().create_timer(0.5).timeout
	print("GROW respawn ", _h(pl))
	pl._leave_wall()
	await get_tree().create_timer(0.3).timeout
	print("GROW leave_wall ", _h(pl))
	get_tree().quit()
