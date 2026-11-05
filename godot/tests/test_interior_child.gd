extends Node
## Çocuk (genin öncesi) karakter dışarıda ve bina içinde aynı boyda mı: model ölçeği, iskelet baş yüksekliği, kamera mesafesi, NPC boyları
var main: Node


func _head_y(m) -> float:
	var sk: Skeleton3D = m.skel
	var bi = sk.find_bone("Head")
	return (sk.global_transform * sk.get_bone_global_pose(bi)).origin.y - m.global_position.y


func _report(tag: String, pl) -> void:
	var m = pl.model
	var npcs = []
	for v in get_tree().current_scene.find_children("*", "Villager", true, false):
		if v.model and v.global_position.distance_to(pl.global_position) < 25.0:
			npcs.append("%s:%.2f sc=%.2f as=%.2f ov=%.2f/%.2f/%.2f anim=%s" % [String(v.look.get("age", "?")), _head_y(v.model), v.model.scale.x, v.model.age_scale, v.model.overlay.head_scale, v.model.overlay.limb_scale, v.model.overlay.leg_len, v.model.current])
	print("PL ov=%.2f/%.2f/%.2f anim=%s gender=%s" % [m.overlay.head_scale, m.overlay.limb_scale, m.overlay.leg_len, m.current, m.look.get("gender", "")])
	print("CHILD %s scale=%.3f age_scale=%.3f age=%s head_y=%.2f cam_dist=%.2f cam_h=%.2f npcs=%s" % [tag, m.scale.x, m.age_scale, m.look.get("age", "?"), _head_y(m), pl.cam_dist, pl.cam.global_position.y - pl.global_position.y, npcs.slice(0, 6)])


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	var pl = main.player
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	_report("dışarı", pl)
	await main.shot("child_out")
	var v = Game.village("konoha")
	var c = Game.from_map(Vector2(v["x"], v["y"]))
	var done = {}
	for it in Interact.items:
		var room = String(it.get("room", ""))
		if it.get("kind", "") != "enter" or room == "" or done.has(room) or Vector2(it["pos"].x - c.x, it["pos"].z - c.z).length() > float(v["r"]) * 1.3:
			continue
		if not room in ["academy"]:
			continue
		done[room] = true
		pl.respawn(it["pos"] + Vector3(0, 0.3, 0))
		await get_tree().create_timer(0.8).timeout
		Interiors.inst.enter(it)
		await get_tree().create_timer(2.0).timeout
		Hud.close_dialog()
		_report("içeri:" + room, pl)
		await main.shot("child_in_" + room)
		Interiors.inst.exit()
		await get_tree().create_timer(1.5).timeout
		_report("çıkış:" + room, pl)
	get_tree().quit()
