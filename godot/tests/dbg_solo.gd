extends Node
## 1v1 görevler: n kişilik adım tek güçlü ninja doğurur
var main: Node


func _count() -> Array:
	return get_tree().get_nodes_in_group("fighters").filter(func(e): return e is Enemy and e.has_meta("mission") and not e.is_dead())


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	Game.profile["level"] = 20
	Game.profile["rank"] = 2
	Missions.abandon() if Missions.has_method("abandon") else null
	var cam = get_viewport().get_camera_3d()
	var cf = -cam.global_transform.basis.z
	cf.y = 0
	var at = Game.to_map(pl.global_position + cf.normalized() * 14.0)
	var m = {"title": "Test Kampı", "rank": "B", "village": "konoha", "giver": "Hokage", "hook": "", "brief": "t",
		"steps": [{"kind": "kill", "at": [at.x, at.y], "enemy": "rogue", "n": 4, "text": "Kaçakları yen"},
			{"kind": "kill", "at": [at.x, at.y], "enemy": "rogue", "n": 3, "boss": {"name": "Lider", "hp": 800.0, "level": 22, "power": 2.0}, "text": "Lideri yen"}]}
	Missions.accept(m)
	await get_tree().create_timer(2.5).timeout
	var es = _count()
	print("SOLO step1 enemies=", es.size(), " ", es.map(func(e): return [e.display_name, int(e.max_hp), snappedf(e.power, 0.01), e.arch.get("style", "")]), " need=", Missions.active()["steps"][0]["n"])
	await main.shot("solo_step1")
	for e in es:
		e.take_hit({"dmg": 99999.0, "attacker": pl, "kind": "heavy", "dir": Vector3.FORWARD})
	await get_tree().create_timer(3.0).timeout
	es = _count()
	print("SOLO step2 enemies=", es.size(), " ", es.map(func(e): return [e.display_name, int(e.max_hp)]), " step=", Missions.st.get("i", "?") if "st" in Missions else "")
	get_tree().quit()
