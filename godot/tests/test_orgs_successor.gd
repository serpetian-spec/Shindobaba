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
	var st = Orgs.state()
	print("ORG Akatsuki ayakta: örgüt sayısı=", Orgs.random_orgs().size())
	st["akatsuki_dead"] = Orgs.AKATSUKI.map(func(m): return m["name"])
	var o1 = Orgs.random_orgs()
	print("ORG Akatsuki çöktü: örgüt sayısı=%d ad=%s" % [o1.size(), o1[0]["name"] if o1.size() > 0 else "-"])
	print("ORG tekrar çağrı aynı mı: ", Orgs.random_orgs()[0]["name"] == o1[0]["name"])
	o1[0]["dead"] = o1[0]["members"].map(func(m): return m["name"])
	print("ORG örgüt de çöktü: sayı=", Orgs.random_orgs().size())
	st["rorg_gone_t"] = Time.get_unix_time_from_system() - 2000.0
	var o2 = Orgs.random_orgs()
	print("ORG 30 dk sonra: sayı=%d yeni ad=%s" % [o2.size(), o2[0]["name"] if o2.size() > 0 else "-"])
	get_tree().quit()
