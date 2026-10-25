extends Node
## Her köyde akademi ve hastane kapıları: var mı, gir-çık, iç mekân çekimi (köye özel akademi)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	var pl = main.player
	await get_tree().create_timer(3.0).timeout
	for vid in ["konoha", "suna", "kiri", "kumo", "iwa"]:
		var v = Game.village(vid)
		var c = Game.from_map(Vector2(v["x"], v["y"]))
		for room in ["academy", "hospital"]:
			var door = null
			for it in Interact.items:
				if it.get("kind", "") == "enter" and String(it.get("room", "")) == room and Vector2(it["pos"].x - c.x, it["pos"].z - c.z).length() < float(v["r"]) * 1.3:
					door = it
			if door == null:
				print("ROOM %s %s YOK" % [vid, room])
				continue
			pl.respawn(door["pos"] + Vector3(0, 0.3, 0))
			await get_tree().create_timer(0.8).timeout
			Interiors.inst.enter(door)
			await get_tree().create_timer(1.6).timeout
			var ok = Interiors.inst.inside == room
			if room == "academy":
				pl.set_process(false)
				var cam = Camera3D.new()
				main.add_child(cam)
				cam.global_position = Interiors.inst.L(-5.5, 3.2, 1.0)
				cam.look_at(Interiors.inst.L(0, 1.2, 13.0))
				cam.current = true
				await get_tree().create_timer(0.3).timeout
				await main.shot("academy_" + vid)
				cam.queue_free()
				pl.set_process(true)
			Interiors.inst.exit()
			await get_tree().create_timer(1.4).timeout
			print("ROOM %s %s inside_ok=%s back_out=%s" % [vid, room, ok, Interiors.inst.inside == ""])
	get_tree().quit()
