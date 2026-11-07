extends Node
## Görev bitince cesetler hemen kalkmamalı
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
	Missions.accept({"title": "Test", "rank": "C", "village": "konoha", "giver": "Hokage", "hook": "", "brief": "x",
		"steps": [{"kind": "kill", "at": spot, "enemy": "bandit", "n": 2, "text": "Haydutları temizle."}]})
	await _w(0.5)
	pl.global_position = Missions.target_marker + Vector3(0, 1, 0)
	await _w(3.0)
	var foes = Missions.step_nodes.filter(func(x): return x is Enemy)
	print("CORPSE foes=%d" % foes.size())
	for e in foes:
		e.take_hit({"dmg": 1e7, "attacker": pl, "kind": "heavy"})
	await _w(3.0)
	var alive = foes.filter(func(x): return is_instance_valid(x))
	print("CORPSE after kill+complete: valid=%d/%d mission_active=%s" % [alive.size(), foes.size(), not Missions.active().is_empty()])
	await _w(5.0)
	print("CORPSE after 8s valid=%d" % foes.filter(func(x): return is_instance_valid(x)).size())
	get_tree().quit()
