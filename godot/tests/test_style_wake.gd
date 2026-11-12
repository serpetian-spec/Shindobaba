extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "hyuga", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "eye": Color(0.2, 0.4, 0.9), "skin": Color(0.96, 0.8, 0.66)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var p = Game.profile
	print("SW start level=", p["level"], " avail=", FightingStyles.available(p), " key=", FightingStyles.player_key(p))
	for k in ["ninjutsu", "taijutsu", "chakra", "dayaniklilik"]:
		for i in 60:
			Mastery.gain(p, k, 30.0)
	Mastery.refresh_level(p)
	print("SW after level=", p["level"], " avail=", FightingStyles.available(p), " key=", FightingStyles.player_key(p), " sel=", p.get("fight_style", ""))
	get_tree().quit()
