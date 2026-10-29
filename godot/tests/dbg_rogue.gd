extends Node
## Kaçak hayatı: sığınak, köye girince muhafız dalgaları ve Kage, simsar (parşömen/kinjutsu), sığınakta doğma
var main: Node
func _guards() -> Array:
	return get_tree().get_nodes_in_group("fighters").filter(func(x): return x.has_meta("village_guard") and not x.dead)

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	Game.profile["rank"] = 2
	Game.profile["level"] = 25
	Orgs.defect()
	await get_tree().create_timer(0.5).timeout
	var hp = Orgs.hideout_pos()
	var v = Game.village(Progress.home())
	var c = Game.from_map(Vector2(v["x"], v["y"]))
	pl.respawn(c + Vector3(0, 0, 50))
	await get_tree().create_timer(4.0).timeout
	var g = _guards()
	print("ROGUE in_village dist=%.0f guards=%d names=%s" % [Game.to_map(pl.global_position).distance_to(Vector2(v["x"], v["y"])), g.size(), g.map(func(x): return x.display_name) if not g.is_empty() and "display_name" in g[0] else []])
	if not g.is_empty():
		Hud.show_game_hud(false)
		var cam = Camera3D.new()
		main.add_child(cam)
		cam.current = true
		pl.set_process(false)
		cam.global_position = pl.global_position + Vector3(10, 7, 14)
		cam.look_at(pl.global_position + Vector3(0, 1, 0))
		await get_tree().create_timer(0.6).timeout
		await main.shot("raid_wave1")
		cam.queue_free()
		pl.set_process(true)
		Hud.show_game_hud(true)
	# dalgaları hızlıca bitir: Kage gelmeli
	for w in 4:
		for x in _guards():
			x.take_hit({"dmg": 1e7, "attacker": pl})
		Orgs._raid["t"] = 0.0
		await get_tree().create_timer(1.5).timeout
	g = _guards()
	print("ROGUE after_waves wave=%s kage=%s guards=%s" % [Orgs._raid.get("wave"), Orgs._raid.get("kage"), g.map(func(x): return x.display_name) if not g.is_empty() and "display_name" in g[0] else g.size()])
	pl.respawn(hp + Vector3(0, 0, 8))
	await get_tree().create_timer(3.0).timeout
	Orgs.add_infamy(1000)
	print("ROGUE rank=%s scrolls=%d" % [Orgs.rogue_rank_name(), Progress.scroll_shop_items(6 + Orgs.rogue_rank() * 3, Orgs.rogue_rank() * 3).size()])
	Progress.on_player_died()
	await get_tree().create_timer(3.5).timeout
	print("ROGUE respawn_dist_to_hideout=%.0f raid_empty=%s" % [pl.global_position.distance_to(hp), Orgs._raid.is_empty()])
	get_tree().quit()
