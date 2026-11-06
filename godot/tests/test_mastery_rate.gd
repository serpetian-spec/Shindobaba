extends Node
## Ustalık gelişim hızı (gerçek oyun yolu): 30 sn su üstünde dur, 6 jutsu at -> chakra / ninjutsu artışı
var main: Node
func _w(t): await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(1.5)
	Hud.close_dialog()
	var pl = main.player
	var pr = Game.profile
	pl.max_chakra = 1e6; pl.chakra = 1e6
	pl.global_position = Vector3(-2720, 1.0, 630)   # deniz
	await _w(1.0)
	var c0 = Mastery.get_v(pr, "chakra")
	await _w(30.0)
	var c1 = Mastery.get_v(pr, "chakra")
	print("MST su üstü 30 sn: chakra %.3f -> %.3f (dakikada %.2f)" % [c0, c1, (c1 - c0) * 2.0])
	pl.global_position = Game.from_map(Vector2(Game.village("suna")["x"] + 900, Game.village("suna")["y"])) + Vector3.UP
	await _w(1.0)
	Game.profile["learned"].append("katon_goukakyuu")
	var n0 = Mastery.get_v(pr, "ninjutsu"); var ch0 = Mastery.get_v(pr, "chakra")
	for i in 6:
		pl.combat.cooldowns.erase("katon_goukakyuu")
		pl.combat.begin_cast("katon_goukakyuu")
		await _w(2.0)
	print("MST 6 jutsu: ninjutsu +%.3f  chakra +%.3f" % [Mastery.get_v(pr, "ninjutsu") - n0, Mastery.get_v(pr, "chakra") - ch0])
	get_tree().quit()
