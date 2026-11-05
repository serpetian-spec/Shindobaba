extends Node
## Köyden kaçan dost: Nukenin rütbesi, köy haberi/akademi sohbeti yok; takım hocası hain olamaz (sadakat >= 65)
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.0).timeout
	Game.profile["rank"] = 1
	var cnt = {}
	for k in 300:
		for kind in ["rogue", "genin_rival"]:
			var el = String(Enemy.archetype(kind, 0)["element"])
			cnt[el] = int(cnt.get(el, 0)) + 1
	print("ELM dağılım (600): ", cnt)
	get_tree().quit()
