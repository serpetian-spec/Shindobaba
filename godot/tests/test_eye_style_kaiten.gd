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
	var pr = Game.profile
	print("EYE before avail=%s" % str(FightingStyles.available(pr)))
	Gear.grant(pr, "goz_byakugan", "sag_goz")
	Gear.grant(pr, "goz_sharingan", "sol_goz")
	print("EYE after avail=%s" % str(FightingStyles.available(pr)))
	var pl = main.player
	pl.chakra = 999.0
	var f = []
	Jutsu.execute(pl, "kaiten", null)
	for k in 6:
		await _w(0.18)
		f.append(snappedf(pl.facing, 0.1))
	print("KAITEN facing samples=%s" % str(f))
	get_tree().quit()
