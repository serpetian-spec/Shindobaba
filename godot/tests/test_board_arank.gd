extends Node
## Chūnin Sv.30+ panosunda A-rank görev çıkıyor mu
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(1.0).timeout
	Game.profile["rank"] = 2
	for lv in [20, 35]:
		Game.profile["level"] = lv
		var got = []
		for i in 5:
			var l = Missions.board_missions(Progress.home(), true)
			got.append(",".join(l.map(func(m): return m["rank"])))
		print("BOARD lv=%d limits=%s -> %s" % [lv, Missions.board_limits(Progress.home()), got])
	get_tree().quit()
