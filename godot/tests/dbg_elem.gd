extends Node
## Element kilidi: Su ile başlayan oyuncu Ateş jutsusu öğrenemez (parşömen, eğitmen, klan, yasak); ikinci doğa alınca klan teknikleri açılır
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "suiton", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	var pr = Game.profile
	pr["level"] = 40
	pr["rank"] = 3
	Progress.clan_unlocks(false)
	var bad = []
	for jid in pr["learned"]:
		var j: Dictionary = Data.jutsu.get(jid, {})
		var el = String(j.get("element", ""))
		if el in ["katon", "fuuton", "doton", "raiton"] and not String(j.get("learn", "")).begins_with("path:"):
			bad.append(jid)
	print("ELEM suiton+uchiha lv40 learned=%d  yasak-element=%s" % [pr["learned"].size(), bad])
	print("ELEM direct katon_goukakyuu -> %s" % Progress.learn("katon_goukakyuu", false))
	print("ELEM direct suiton_suikoudan -> %s" % Progress.learn("suiton_suikoudan", false))
	print("ELEM can_learn katon_karyuu: %s" % Progress.can_learn("katon_karyuu"))
	var opts = Progress.trainer_options(["konoha", "taijutsu", "genjutsu", "academy", "jonin", "fuin", "kumo", "iwa", "suna", "kiri"], 200)
	var tbad = 0
	for o in opts:
		if "Katon" in String(o["label"]) or "Ateş" in String(o["label"]):
			tbad += 1
	print("ELEM trainer opts=%d  ateş-adı-geçen=%d" % [opts.size(), tbad])
	var shop_bad = 0
	for iid in Progress.scroll_shop_items(200, 99):
		var jj: Dictionary = Data.jutsu[Data.items[iid]["jutsu"]]
		if not "suiton" in jj.get("elements", []):
			shop_bad += 1
	print("ELEM scroll shop non-suiton=%d" % shop_bad)
	var n0 = pr["learned"].size()
	pr["elements"].append("katon")
	Progress.clan_unlocks(false)
	print("ELEM ikinci doğa katon -> klan teknikleri açıldı: +%d" % (pr["learned"].size() - n0))
	get_tree().quit()
