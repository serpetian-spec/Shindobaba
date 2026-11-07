extends Node
## Kaçakken yoldaki köy takımına doğrudan vurmak: takım düşmana dönüşür (suç yok); köylüyken suç
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
	var at = get_tree().current_scene.find_child("AmbientTeams", true, false)
	for rogue in [true, false]:
		Game.profile["flags"]["rogue"] = rogue
		var vs = Game.village("suna")
		pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400 + (0 if rogue else 300), vs["y"])))
		await _w(1.0)
		at.teams.clear()
		at._spawn(pl.global_position)
		await _w(1.5)
		var tm = at.teams[0]
		var n = tm["nodes"][0]
		n.global_position = pl.global_position + pl.face_dir() * 1.2
		var crime0 = int(Game.profile.get("crime", {}).get("heat", 0)) if Game.profile.has("crime") else -1
		print("  dbg n=%s vt=%s in_fighters=%s dead=%s team=%s cap=%s d=%.2f" % [n, n.has_meta("vt"), n.is_in_group("fighters"), n.is_dead(), n.team, Combat.capsule_hit(pl.global_position + Vector3.UP + pl.face_dir() * 1.0, n, 0.9), n.global_position.distance_to(pl.global_position)])
		Combat.hit_sphere(pl, pl.global_position + Vector3.UP + pl.face_dir() * 1.0, 0.9, {"dmg": 5.0, "kind": "light", "melee": true})
		await get_tree().process_frame
		var ens = get_tree().get_nodes_in_group("fighters").filter(func(f): return f is Enemy and not f.dead and f.global_position.distance_to(pl.global_position) < 200.0)
		print("PROVOKE rogue=%s hostile=%s enemies=%d targets_player=%s crime_log=%s" % [rogue, tm.get("hostile", false), ens.size(), ens.all(func(e): return e.target == pl), str(Game.profile.get("crimes", Game.profile.get("crime", "-"))).left(120)])
		for e in ens:
			e.queue_free()
	get_tree().quit()
