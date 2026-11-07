extends Node
## Büyük görev mağarası: içeri gir, düşmanlar salonun dibinde, görüntü
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	pl.max_hp = 1e9
	pl.hp = 1e9
	var spot = Missions._spot("konoha", 400, 700)
	Missions.accept({"title": "Kaçakların Sığınağı", "rank": "B", "village": "konoha", "giver": "Hokage", "hook": "", "brief": "x",
		"steps": [{"kind": "kill", "at": spot, "enemy": "rogue", "n": 3, "camp": true, "text": "Kaçakları avla."}]})
	await _w(0.5)
	var door = {}
	for it in Interact.items:
		if String(it.get("room", "")).begins_with("lair_"):
			door = it
	if door.is_empty():
		print("LAIR no door (lair kind=%s)" % Missions.st.get("lair", "-"))
		get_tree().quit()
		return
	pl.global_position = door["out"] + Vector3(0, 0.5, 0)
	await _w(1.0)
	Interiors.inst.enter(door)
	await _w(2.0)
	var foes = Missions.step_nodes.filter(func(x): return x is Enemy and is_instance_valid(x))
	print("LAIR room=%s foes=%d first_d=%.1f player_y-origin=%.2f" % [Interiors.inst.inside, foes.size(), foes[0].global_position.distance_to(pl.global_position) if foes.size() > 0 else -1.0, pl.global_position.y - Interiors.inst.origin.y])
	pl.yaw = 0.0
	pl.pitch = -8.0
	pl.cam_dist = 6.0
	await _w(0.4)
	await main.shot("lair_big")
	get_tree().quit()
