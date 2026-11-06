extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.5).timeout
	Hud.close_dialog()
	Game.set_meta("sandbox", true)
	var pl = main.player
	pl.max_hp = 1e9; pl.hp = 1e9
	var vs = Game.village("suna")
	var base = Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 600, vs["y"]))
	pl.respawn(base)
	await get_tree().create_timer(1.0).timeout
	for id in ["raiton_chidori", "katon_goukakyuu"]:
		var e := Enemy.new()
		e.setup(Enemy.archetype("rogue", 1))
		main.actors.add_child(e)
		e.global_position = base + Vector3(0, 0, -7)
		e.max_hp = 1e7; e.hp = 1e7
		e.set_physics_process(false)
		pl.global_position = base
		await get_tree().create_timer(0.2).timeout
		var log := []
		var orig_hit = e.hp
		Jutsu.execute(pl, id, e)
		var last = e.hp
		for k in 40:
			await get_tree().create_timer(0.1).timeout
			if e.hp < last:
				log.append("%.1fs:-%.0f" % [k * 0.1, last - e.hp])
				last = e.hp
		print("CHD %s toplam=%.0f  vuruşlar=%s" % [id, orig_hit - e.hp, " ".join(log)])
		e.queue_free()
		await get_tree().create_timer(1.0).timeout
	get_tree().quit()
