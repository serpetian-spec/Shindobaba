extends Node
## Kaçak hayatı: sığınak, köy yasağı, simsar işi, sığınakta doğma
var main: Node
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
	print("ROGUE hideout=%s dist_from_village=%.0f r=%s" % [hp, Game.to_map(hp).distance_to(Vector2(v["x"], v["y"])), v["r"]])
	var c = Game.from_map(Vector2(v["x"], v["y"]))
	pl.respawn(c + Vector3(0, 0, 50))
	await get_tree().create_timer(1.0).timeout
	print("ROGUE after_enter dist=%.0f (should be > r)" % Game.to_map(pl.global_position).distance_to(Vector2(v["x"], v["y"])))
	pl.respawn(hp + Vector3(0, 0, 8))
	await get_tree().create_timer(3.0).timeout
	var br = Interact.items.filter(func(it): return it.get("kind", "") == "rogue_broker")
	print("ROGUE broker_items=%d" % br.size())
	var job = Orgs._rogue_job("B")
	print("ROGUE job=%s steps=%d" % [job["title"], job["steps"].size()])
	Orgs.add_infamy(400)
	print("ROGUE rank=%s infamy=%d" % [Orgs.rogue_rank_name(), Orgs.infamy()])
	Progress.on_player_died()
	await get_tree().create_timer(3.5).timeout
	print("ROGUE respawn_dist_to_hideout=%.0f" % pl.global_position.distance_to(hp))
	Hud.show_game_hud(false)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	pl.set_process(false)
	cam.global_position = hp + Vector3(18, 12, 18)
	cam.look_at(hp)
	await get_tree().create_timer(0.5).timeout
	await main.shot("rogue_hideout")
	get_tree().quit()
