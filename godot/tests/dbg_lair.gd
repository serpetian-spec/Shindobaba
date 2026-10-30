extends Node
## Görev yerleşkeleri: haydut kampı / kale / karakol / mağara sığınağı / deney ini (içeri girip dövüş)
var main: Node


func _shot_at(c: Vector3, name: String, dist := 26.0, h := 9.0) -> void:
	var pl = main.player
	var cam = get_viewport().get_camera_3d()
	var cf = -cam.global_transform.basis.z
	cf.y = 0
	cf = cf.normalized()
	var p = c - cf * dist
	p.y = Game.ground_height(p.x, p.z) + 0.2
	pl.global_position = p
	pl.velocity = Vector3.ZERO
	await get_tree().create_timer(2.5).timeout
	await main.shot(name)


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	Game.profile["level"] = 25
	Game.profile["rank"] = 2
	var kinds = [["bandit", "Haydut Çetesi", "Haydut çetesini dağıt."], ["samurai", "Paralı Asker Kampı", "Kaçak samurayları yen."], ["kiri", "Sınır Karakolu", "Karakolu dağıt."],
		["rogue", "Kaçakların Sığınağı", "Ödüllü kaçakları avla."], ["rogue", "Deney İni", "Deney inini bas, örgüt üyesini yen."]]
	for k in kinds.size():
		var spot = Missions._spot("konoha", 400, 700)
		var m = {"title": kinds[k][1], "rank": "B", "village": "konoha", "giver": "Hokage", "hook": "", "brief": kinds[k][1],
			"steps": [{"kind": "kill", "at": spot, "enemy": kinds[k][0], "n": 4, "camp": true, "text": kinds[k][2]}]}
		Missions.abandon_active() if Missions.has_method("abandon_active") else null
		Game.profile.erase("active_mission")
		Missions.accept(m)
		await get_tree().create_timer(0.5).timeout
		var s = Missions._cur()
		var c = Missions._w(s["at"])
		print("LAIR ", kinds[k][1], " kind=", Missions.st.get("lair"), " road_dist=", int(Game.road_dist(c.x, c.z)))
		await _shot_at(c, "lair_%d_out" % k)
		if String(Missions.st.get("lair")) in ["cave", "lab"]:
			# ağzın önünden (köy tarafı) bak
			var cam = get_viewport().get_camera_3d()
			var cf = -cam.global_transform.basis.z
			cf.y = 0
			var door0 = {}
			for it in Interact.items:
				if String(it.get("room", "")).begins_with("lair_"):
					door0 = it
			var face = (door0["pos"] - c)
			face.y = 0
			face = face.normalized()
			main.player.global_position = c + face * 16.0
			main.player.yaw = rad_to_deg(atan2(face.x, face.z))
			main.player.global_position.y = Game.ground_height(main.player.global_position.x, main.player.global_position.z) + 0.2
			await get_tree().create_timer(2.0).timeout
			await main.shot("lair_%d_mouth" % k)
		if String(Missions.st.get("lair")) in ["cave", "lab"]:
			var door = {}
			for it in Interact.items:
				if String(it.get("room", "")).begins_with("lair_"):
					door = it
			Interiors.inst.enter(door)
			await get_tree().create_timer(2.5).timeout
			var es = get_tree().get_nodes_in_group("fighters").filter(func(e): return e is Enemy and e.has_meta("mission") and not e.is_dead())
			print("LAIR inside enemies=", es.size(), " y=", es.map(func(e): return int(e.global_position.y)), " player y=", int(main.player.global_position.y))
			var pl = main.player
			pl.look_at(pl.global_position + Vector3(0, 0, -1), Vector3.UP, true)
			await get_tree().create_timer(1.5).timeout
			await main.shot("lair_%d_in" % k)
			Interiors.inst.exit()
			await get_tree().create_timer(1.5).timeout
	get_tree().quit()
