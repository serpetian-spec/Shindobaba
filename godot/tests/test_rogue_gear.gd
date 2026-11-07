extends Node
## S-rank kaçak = Kage seviyesi: ANBU eşyaları takılabilir
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	Game.profile["rank"] = 2
	Game.profile["flags"]["rogue"] = true
	for inf in [0, 1000, 2500, 5000]:
		Orgs.flags()["infamy"] = inf
		print("RG infamy=%d eff=%d anbu_maske='%s' set_anbu='%s'" % [inf, Gear.eff_rank(Game.profile), Gear.req_text("anbu_maske", Game.profile), Gear.req_text("set_anbu", Game.profile)])
	get_tree().quit()
