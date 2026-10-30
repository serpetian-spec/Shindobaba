extends Node
## Crash avı: sınır savaşı (Kiri öncüleri, savunma dalgaları) sırasında rastgele örgüt üyeleri gelir, hepsi birlikte dövüşür
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	Game.profile["level"] = 40
	Game.profile["rank"] = 3
	# köy dışına: sınır karakoluna
	var outpost = Missions._spot("konoha", 700, 1300)
	var op = Game.from_map(Vector2(outpost[0], outpost[1]))
	pl.global_position = Missions.open_ground(op + Vector3(10, 0, 0), 30.0) + Vector3.UP
	await get_tree().create_timer(1.0).timeout
	var m = {"title": "Sınır Savaşı: Kiri Öncüleri", "rank": "B", "village": "konoha", "giver": "Hokage", "hook": "", "event": "border_war", "brief": "test",
		"steps": [{"kind": "defend", "at": outpost, "enemy": "kiri", "waves": [3, 4, 5], "text": "Saldırı dalgalarını püskürt."},
			{"kind": "kill", "at": outpost, "enemy": "kiri", "n": 2, "boss": {"name": "Öncü Komutanı", "hp": 1800.0, "level": 40, "power": 2.3}, "text": "Öncü komutanını yen."}]}
	Missions.accept(m)
	await get_tree().create_timer(3.0).timeout
	for o in Orgs.random_orgs():
		for mm in o["members"]:
			Orgs.spawn_ro_member(o, mm, pl.global_position + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10)))
	print("WAR spawned orgs")
	for t in 120:
		pl.hp = pl.max_hp
		await get_tree().create_timer(0.5).timeout
		if t % 6 == 0:
			# rastgele bir düşmanı öldür (ölüm/ödül/klon zincirleri)
			var es = get_tree().get_nodes_in_group("fighters").filter(func(e): return is_instance_valid(e) and e is Enemy and e.team == "enemy" and not e.is_dead())
			if not es.is_empty():
				var e = es.pick_random()
				e.take_hit({"dmg": 99999.0, "attacker": pl, "kind": "heavy", "dir": Vector3.FORWARD})
			print("WAR t=", t, " enemies=", es.size(), " step=", Missions.active().get("step", -1))
	print("WAR done")
	get_tree().quit()
