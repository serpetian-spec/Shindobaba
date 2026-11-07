extends Node
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
	Game.profile["flags"]["rogue"] = true
	Orgs._ensure_hideout()
	Game.profile["jinchuriki"] = "kurama"
	print("MIND jin=%s" % TailedBeasts.player_jinchuriki())
	var door = {}
	for it in Interact.items:
		if String(it.get("room", "")) == "rogue_hideout":
			door = it
	pl.global_position = door["out"] + Vector3(0, 0.5, 0)
	await _w(1.0)
	pass
	await _w(2.0)
	print("MIND in cave inside=%s pos=%s enemy=%s" % [Interiors.inst.inside, pl.global_position, Combat.nearest_enemy(pl, 40.0)])
	print("  pm=%d paused=%s tb_in_tree=%s can_process=%s" % [TailedBeasts.process_mode, get_tree().paused, TailedBeasts.is_inside_tree(), TailedBeasts.can_process()])
	TailedBeasts.enter_mindscape()
	for k in 8:
		await _w(0.15)
		print("  t%d y=%.0f sp=%s" % [k, pl.global_position.y, TailedBeasts.mind.spawn_point() if TailedBeasts.mind else null])
	await _w(0.8)
	print("MIND entered mind=%s y=%.0f inside=%s" % [TailedBeasts.mind, pl.global_position.y, Interiors.inst.inside])
	TailedBeasts.exit_mindscape()
	await _w(2.5)
	print("MIND exited mind=%s pos=%s inside=%s" % [TailedBeasts.mind, pl.global_position, Interiors.inst.inside])
	TailedBeasts.enter_mindscape()
	await _w(2.0)
	print("MIND 2nd enter mind=%s y=%.0f" % [TailedBeasts.mind, pl.global_position.y])
	get_tree().quit()
