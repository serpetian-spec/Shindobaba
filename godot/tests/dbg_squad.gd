extends Node
## Genin takımı: doğum, takip, savaş, düşme (öldürme sayılmaz), sınav takımı aynı kişiler, Chūnin'de dağılma
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pr = Game.profile
	pr["level"] = 12
	pr["rank"] = 1
	var pl = main.player
	var v = Game.village("konoha")
	var p = Game.from_map(Vector2(v["x"] + 1600, v["y"]))
	p.y = Game.ground_height(p.x, p.z) + 0.5
	pl.respawn(p)
	await get_tree().create_timer(3.0).timeout
	var sq = main.get_node("Actors/GeninSquad")
	var names = []
	for m in sq.members:
		if m["node"] and is_instance_valid(m["node"]):
			names.append("%s@%.1fm" % [m["node"].display_name, m["node"].global_position.distance_to(pl.global_position)])
	print("SQUAD spawned: %s" % [names])
	# oyuncu yürür: takip
	pl.global_position = p + Vector3(30, 0, 0)
	pl.global_position.y = Game.ground_height(pl.global_position.x, pl.global_position.z) + 0.5
	await get_tree().create_timer(6.0).timeout
	var ds = []
	for m in sq.members:
		if m["node"] and is_instance_valid(m["node"]):
			ds.append("%.1f" % m["node"].global_position.distance_to(pl.global_position))
	print("SQUAD follow dist after 6s: %s" % [ds])
	# düşman: takım saldırıyor mu
	var e = Enemy.new()
	var a = Enemy.archetype("bandit", 0)
	a["hp"] = 400.0
	a["respawn"] = false
	e.setup(a)
	get_tree().current_scene.add_child(e)
	e.global_position = pl.global_position + Vector3(6, 0, 6)
	e.home = e.global_position
	var hp0 = e.hp
	pl.set_physics_process(false)
	await get_tree().create_timer(8.0).timeout
	print("SQUAD bandit hp %d -> %d (dead=%s)" % [hp0, e.hp if is_instance_valid(e) else -1, (not is_instance_valid(e)) or e.is_dead()])
	# takım arkadaşı düşer: öldürme sayılmaz
	var kills0 = int(pr["stats"].get("kills", 0))
	var xp0 = int(pr.get("xp", 0))
	var m0 = sq.members[0]["node"]
	if m0 and is_instance_valid(m0):
		m0.take_hit({"dmg": 99999.0, "kind": "heavy", "knock": 1.0, "attacker": null})
	await get_tree().create_timer(1.0).timeout
	print("SQUAD mate down: kills %d->%d xp %d->%d  down_t=%.0f" % [kills0, int(pr["stats"].get("kills", 0)), xp0, int(pr.get("xp", 0)), float(sq.members[0]["down"])])
	# sınav takımı aynı kişiler
	var team = Exams.spawn_teammates(pl.global_position, 2, 12)
	print("SQUAD exam team: %s vs squad %s,%s" % [team.map(func(x): return x.display_name), pr["squad"]["mates"][0]["name"], pr["squad"]["mates"][1]["name"]])
	Exams._clear_nodes()
	await main.shot("squad")
	# Chūnin: dağılır
	Progress.promote(2)
	await get_tree().create_timer(1.5).timeout
	var alive = 0
	for m in sq.members:
		if m["node"] and is_instance_valid(m["node"]):
			alive += 1
	print("SQUAD after chunin: state=%s alive=%d" % [pr["squad"]["state"], alive])
	get_tree().quit()
