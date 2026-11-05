extends Node
## Genin takımı her yeni oyunda farklı mı: hoca adı/cinsiyeti/saçı, takım arkadaşları; savaş arketipi bunları taşıyor mu
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.0).timeout
	var seen = {}
	for r in 6:
		Game.profile.erase("squad")
		var sq = GeninSquad.ensure_formed()
		var s = sq["sensei"]
		var a = GeninSquad.sensei_arch(45)
		var L = {}
		GeninSquad.dress_sensei(L)
		print("SQUAD %d hoca=%s (%s, %s) arch_g=%s | takım=%s" % [r, s["name"], s.get("gender", "?"), s["hair_style"], a["look"]["gender"], sq["mates"].map(func(m): return "%s/%s/%s" % [m["name"], m["gender"], m["hair_style"]])])
		seen[s["name"]] = true
	print("SQUAD farklı hoca adı: %d / 6   sensei_name()=%s" % [seen.size(), GeninSquad.sensei_name()])
	get_tree().quit()
