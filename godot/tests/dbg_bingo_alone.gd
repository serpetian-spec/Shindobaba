extends Node
## Bingo kaçağı yalnız doğuyor mu (kamp/eskort yok)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var e = Missions._bb_new()
	Missions._bingo()["list"].append(e)
	var hp = Game.from_map(Vector2(e["hide"][0], e["hide"][1]))
	main.player.respawn(hp + Vector3(60, 0, 0))
	await get_tree().create_timer(5.0).timeout
	var sp = Missions._bb_spawned.get(int(e["id"]), [])
	var en = get_tree().get_nodes_in_group("enemies").filter(func(x): return x.global_position.distance_to(hp) < 40.0)
	print("BINGO nodes=%d enemies_near=%d" % [sp.size(), en.size()])
	get_tree().quit()
