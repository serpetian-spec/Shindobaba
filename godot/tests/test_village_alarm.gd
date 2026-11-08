extends Node
## Kaçak köyde alarm: sokaktaki ninja köylüler (devriye/nöbetçi/çatı) saldırıya katılır, rütbesinin gücüyle
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	Orgs.flags()["rogue"] = true
	Orgs.flags()["rogue_from"] = "kiri"
	var pl = main.player
	pl.max_hp = 1e9; pl.hp = 1e9
	var vs = Game.village("konoha")
	pl.respawn(Game.from_map(Vector2(float(vs["x"]), float(vs["y"]))))
	await _w(4.0)
	Hud.close_dialog()
	var ninj = 0
	for v in get_tree().get_nodes_in_group("talkers"):
		if (v is Villager or v is ClanResident) and Friends.is_ninja(v) and v.global_position.distance_to(pl.global_position) < 32.0:
			ninj += 1
	print("ALARM ninja villagers within 32m=%d" % ninj)
	Orgs._raid = {"vid": "konoha", "wave": 0, "t": 99.0, "out_t": 0.0, "nodes": [], "kage": false}
	await _w(4.0)
	var n = 0
	for e in get_tree().get_nodes_in_group("fighters"):
		if e is Enemy and not e.dead and e.target == pl and e.global_position.distance_to(pl.global_position) < 40.0:
			n += 1
			if n <= 4:
				print("ALARM enemy %s lv=%d hp=%.0f power=%.2f jutsu=%d" % [e.display_name, e.level, e.max_hp, e.power, (e.arch.get("jutsu", []) as Array).size()])
	print("ALARM hostile ninjas=%d" % n)
	get_tree().quit()
