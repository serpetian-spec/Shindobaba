extends Node
## Kage binası kapıları: önünden kapı noktasına giden yol açık mı (ışın), kapıya girilince Kage odası açılıyor mu
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 98, "name": "T", "gender": "m", "clan": "none", "element": "katon", "hair_style": "s2", "hair": Color(0.2, 0.2, 0.2), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	var pl = main.player
	var vs = get_tree().current_scene.find_child("VillageStream", true, false)
	for vid in ["suna", "kiri", "kumo", "iwa"]:
		var v = Game.village(vid)
		pl.respawn(Game.from_map(Vector2(v["x"], v["y"])) + Vector3(0, 2, 0))
		var rec = vs.request(vid)
		var t = 0.0
		while not rec.get("done", false) and t < 200.0:
			await get_tree().create_timer(0.5).timeout
			t += 0.5
		await get_tree().create_timer(2.0).timeout
		var door = null
		var doors = []
		for it in Interact.items:
			if it.get("kind", "") == "enter" and String(it.get("room", "")) == "kage" and String(it.get("vid", "")) == vid:
				doors.append(it)
		if doors.is_empty():
			print("KAPI %s YOK" % vid)
			continue
		for dd in doors:
			pl.respawn(dd["pos"] + Vector3(0, 0.3, 1.5))
			await get_tree().create_timer(1.2).timeout
			var nn = Interact.nearest(pl.global_position)
			var ev = InputEventAction.new()
			ev.action = "interact"
			ev.pressed = true
			Input.parse_input_event(ev)
			await get_tree().create_timer(0.1).timeout
			var ev2 = InputEventAction.new()
			ev2.action = "interact"
			ev2.pressed = false
			Input.parse_input_event(ev2)
			await get_tree().create_timer(2.0).timeout
			print("F_KAPI %s y=%.0f en_yakın=%s -> içeride=%s" % [vid, dd["pos"].y, String(nn.get("label", "YOK")).left(28), Interiors.inst.inside])
			if Interiors.inst.inside != "":
				Interiors.inst.exit()
				await get_tree().create_timer(1.5).timeout
		door = doors[0]
		var dp: Vector3 = door["pos"]
		var from = dp + Vector3(0, 1.2, 14.0)
		from.y = Game.ground_height(from.x, from.z) + 1.2
		var q = PhysicsRayQueryParameters3D.create(from, dp + Vector3(0, 1.0, 0))
		q.exclude = [pl.get_rid()]
		var hit = pl.get_world_3d().direct_space_state.intersect_ray(q)
		var blocked = not hit.is_empty() and hit["position"].distance_to(dp) > float(door.get("radius", 5.0))
		pl.respawn(dp + Vector3(0, 0.3, 0))
		await get_tree().create_timer(0.8).timeout
		Interiors.inst.enter(door)
		await get_tree().create_timer(1.6).timeout
		print("KAPI %s yol_%s oda=%s" % [vid, "KAPALI@" + str(hit.get("position")) if blocked else "acik", Interiors.inst.inside])
		await main.shot("kage_room_%s" % vid)
		Interiors.inst.exit()
		await get_tree().create_timer(1.0).timeout
	get_tree().quit()
