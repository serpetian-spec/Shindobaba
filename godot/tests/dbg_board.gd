extends Node
## Görev panosu çeşitliliği: her rütbede 3 tazeleme, başlıklar ve kalıplar
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	var pr = Game.profile
	for rk in [1, 2, 3]:
		pr["rank"] = rk
		pr["level"] = [10, 25, 45][rk - 1]
		var all = {}
		for k in 3:
			var lst = Missions.board_missions("konoha", true)
			var titles = []
			for m in lst:
				titles.append("[%s] %s" % [m["rank"], m["title"]])
				all[m["title"]] = true
				Missions.accept(m["id"]) if k == 2 and m == lst[0] else null
			print("BOARD rank%d #%d: %s" % [rk, k, ", ".join(titles)])
			Missions.abandon()
		print("BOARD rank%d farklı başlık: %d" % [rk, all.size()])
	get_tree().quit()
