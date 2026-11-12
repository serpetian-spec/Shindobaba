extends Node
## Konuşmalar: her ilişki için selam, durum sözü, konu sözleri (metin dökümü)
var main: Node


func _mk(nm: String, extra: Dictionary) -> String:
	var id = Friends.add_person(nm, {"gender": "f", "hair": Color(0.2, 0.1, 0.1)}, 2, "patrol", "konoha", Game.player.global_position)
	Friends.all()[id].merge(extra, true)
	return id


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	main.world.env.time_of_day = 0.45
	Game.profile["rank"] = 3
	Aging.set_years(Game.profile, 26.0)
	WorldNews.headline("Kumo sınırında bir kervan soyuldu")
	var ids = {"es": _mk("Aya", {"romance": "eş", "bond": 90}), "sevgili": _mk("Emi", {"romance": "sevgili", "bond": 70}), "cocuk": _mk("Ren", {"child": true, "bond": 80, "rank": 0}),
		"ogrenci": _mk("Sota", {"pupil": true, "bond": 50, "rank": 0}), "hoca": _mk("Genma", {"squad_key": "sensei", "bond": 50}), "takim": _mk("Kaito", {"squad_key": "a", "bond": 40}),
		"dost": _mk("Hana", {"bond": 80}), "arkadas": _mk("Miki", {"bond": 30}), "tanidik": _mk("Yuna", {"bond": 5})}
	for k in Kin.pr().get("kin_ids", {}):
		ids["kin_" + String(k)] = String(Kin.pr()["kin_ids"][k])
	for r in ids:
		var f: Dictionary = Friends.all()[ids[r]]
		print("TK [", r, "] rel=", Talk.rel(f), " yas=", snappedf(Aging.person_years(f), 0.1))
		for i in 3:
			print("TK   selam: ", Friends.greeting(ids[r]))
	# durum sözleri: aynı kişilere değişikliklerden sonra
	Game.profile["rank"] = 4
	Aging.body()["fat"] = 0.6
	for r in ["es", "dost", "kin_anne", "kin_baba", "cocuk"]:
		if ids.has(r):
			print("TK rütbe -> [", r, "] ", Friends.greeting(ids[r]))
			print("TK kilo  -> [", r, "] ", Friends.greeting(ids[r]))
	Game.player.hp = Game.player.max_hp * 0.2
	for r in ["es", "dost", "kin_anne", "ogrenci"]:
		if ids.has(r):
			print("TK yara  -> [", r, "] ", Friends.greeting(ids[r]))
	Game.player.hp = Game.player.max_hp
	for r in ["es", "sevgili", "cocuk", "hoca", "dost"]:
		var f: Dictionary = Friends.all()[ids[r]]
		for key in ["antrenman", "aile", "şaka", "dedikodu", "övgü"]:
			for i in 2:
				var t = Talk.topic(f, key)
				print("TK konu [", r, "/", key, "] ", Talk.label(f, key, "-"), " :: ", t[0], " || ", t[1].map(func(x): return x[1]))
	print("TK koy: ", Talk.village_news(), " | ", Talk.village_news())
	for l in ["Hokage Kulesi'nde yine görev kuyruğu var.", "Ichiraku'nun yeni ramen tarifi efsaneymiş!"]:
		print("TK yerel(", Outfits.village_near(), "): ", Talk.localize(l))
	for tr in ["ciddi", "neşeli", "utangaç", "gururlu", "sıcakkanlı", "alaycı"]:
		var f2: Dictionary = Friends.all()[ids["arkadas"]]
		f2["trait"] = tr
		print("TK tepki [", tr, "] ", Talk.react(f2, "gift_like", "Dango kutusu"), " | ", Talk.react(f2, "provoke"), " | ", Talk.react(f2, "meet"), " | ", Talk.react(f2, "breakup"))
	for r in ["kin_anne", "kin_baba", "kin_kardeş", "es"]:
		if ids.has(r):
			var f3: Dictionary = Friends.all()[ids[r]]
			print("TK tepki [", r, "] ", Talk.react(f3, "gift_like", "Sake"), " | ", Talk.react(f3, "provoke"), " | ", Talk.react(f3, "sorry_ok"))
			if r.begins_with("kin"):
				for key in ["antrenman", "övgü", "dedikodu"]:
					for i in 2:
						print("TK aile konu [", r, "/", key, "] ", Talk.kin_topic(f3, Talk.rel(f3), key)[0])
	var fr: Dictionary = Friends.all()[ids["tanidik"]]
	fr["rogue"] = true
	fr["status"] = "kaçak"
	for i in 3:
		print("TK kaçak selam: ", Friends.greeting(ids["tanidik"]))
	for key in ["şaka", "dedikodu"]:
		for i in 2:
			print("TK kaçak konu [", key, "] ", Talk.rogue_topic(fr, key)[0])
	for k in ["inn", "weapon", "gate", "ramen"]:
		print("TK esnaf [", k, "] ", Talk.keeper(k), " || ", Talk.keeper(k))
	for c in ["uchiha", "nara", "akimichi", "bilinmeyen"]:
		print("TK klan [", c, "] ", Talk.clan_hello(c, "Soy Ad", 0))
	print("TK seslenme: ", Talk.you())
	get_tree().quit()
