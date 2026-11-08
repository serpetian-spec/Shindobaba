extends Node
## Magen: Kijō no Rōkaku — istiridye vurulup ölünce serap kopyalar silinir
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "hozuki", "element": "suiton", "hair_style": "diken", "hair": Color(0.8, 0.85, 0.9), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl: Player = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(1.5)
	PathJutsu.cast_path(pl, "magen_kijo_no_rokaku", null)
	await _w(1.0)
	var clams = get_tree().get_nodes_in_group("clan_construct").filter(func(u): return u.kind == "clam")
	var decoys0 = _count_clones()
	print("MAGEN clams=%d decoys=%d" % [clams.size(), decoys0])
	if clams.is_empty():
		get_tree().quit()
		return
	var cl = clams[0]
	cl.take_hit({"dmg": 9999.0, "knock": 0.0, "kind": "heavy", "attacker": null})
	await _w(1.0)
	print("MAGEN after: clam_dead=%s decoys=%d" % [str(not is_instance_valid(cl) or cl.dead), _count_clones()])
	get_tree().quit()


func _count_clones() -> int:
	var n = 0
	for ch in get_tree().current_scene.get_children():
		if ch is ShadowClone and not ch.is_queued_for_deletion():
			n += 1
	return n
