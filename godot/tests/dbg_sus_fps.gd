extends Node
## Susanoo açıkken FPS (oyun kamerasıyla) + açılış süresi
var main: Node
func _fps(sec: float) -> float:
	var t0 = Time.get_ticks_usec()
	var n = 0
	while Time.get_ticks_usec() - t0 < sec * 1000000.0:
		await get_tree().process_frame
		n += 1
	return n * 1000000.0 / (Time.get_ticks_usec() - t0)
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "dağınık", "hair": Color(0.08, 0.08, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.1, 0.1, 0.1)}
	main._start_new_game()
	var pl = main.player
	var pr = Game.profile
	Gear.grant(pr, "goz_ems", "sag_goz", null, null, {"lvl": 3, "origin": "dogustan"})
	Gear.grant(pr, "goz_ems", "sol_goz", null, null, {"lvl": 3, "origin": "dogustan"})
	Gear.apply_look(pr)
	pl.rebuild_model()
	pl.chakra = 9999999
	pl.max_chakra = 9999999
	Susanoo.config(pr)["mastery"] = 99999.0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await get_tree().create_timer(6.0).timeout
	Hud.close_dialog()
	var eyes = pl.combat.modes.eyes
	eyes.toggle()
	await get_tree().create_timer(1.0).timeout
	print("SFPS kapali %.0f" % await _fps(3.0))
	for t in [1, 2, 3, 4, 5, 5]:
		Susanoo.config(pr)["tier_pref"] = t
		var t0 = Time.get_ticks_usec()
		eyes._start_susanoo()
		var open_ms = (Time.get_ticks_usec() - t0) / 1000.0
		await get_tree().create_timer(1.5).timeout
		print("SFPS kademe %d: %.0f FPS (acilis %.0f)" % [t, await _fps(3.0), open_ms])
		eyes._end_susanoo()
		await get_tree().create_timer(0.6).timeout
	get_tree().quit()
