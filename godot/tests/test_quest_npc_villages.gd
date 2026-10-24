extends Node
## Her ana köyde: jōnin terfi görevinin konuşma kişileri bina içine/çatıya düşmüyor ve konuşulabiliyor
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	for vid in Progress.HOME_VILLAGES.keys():
		Game.profile["village"] = vid
		var v = Game.village(vid)
		pl.global_position = Game.from_map(Vector2(v["x"], v["y"])) + Vector3.UP * 3
		await get_tree().create_timer(4.0).timeout   # köy akışla kurulsun
		var m = Exams._jonin_mission()
		Missions.accept(m)
		await get_tree().create_timer(0.3).timeout
		for step in 2:
			if step == 1:
				Missions._next_step()
			await get_tree().create_timer(0.8).timeout
			var s = Missions._cur()
			var id = s.get("npc", {}).get("id", "")
			var npc = Missions.npcs.get(id)
			if npc == null:
				print("QNPC %s step%d YOK" % [vid, step])
				continue
			var p = npc.global_position
			var sp = pl.get_world_3d().direct_space_state
			var hit = sp.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP * 60, p + Vector3.DOWN, 1))
			var blocked = not hit.is_empty() and float(hit["position"].y) > p.y + 1.0
			pl.global_position = p + Vector3(1.5, 0.3, 0)
			await get_tree().create_timer(0.3).timeout
			var tt = Missions.talk_target_near(pl.global_position, 4.0)
			print("QNPC %s step%d %s blocked=%s talk=%s" % [vid, step, npc.display, blocked, tt != null])
		Missions.abandon()
		await get_tree().create_timer(0.3).timeout
	get_tree().quit()
