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
	var fs = Friends.all()
	fs["t_dost"] = {"name": "Kaze Ren", "role": "spar", "ninja": true, "look": {"gender": "m"}, "bond": 30, "village": "konoha", "rank": 2, "family": [], "status": "", "log": [], "news": ""}
	fs["t_hoca"] = {"name": "Mori-sensei", "role": "teacher", "ninja": true, "look": {"gender": "m"}, "bond": -50, "village": "konoha", "rank": 2, "family": [], "status": "", "log": [], "news": "", "loyalty": 10}
	print("ROG dost sayısı ", fs.size())
	for id in fs:
		var f = fs[id]
		Friends._ensure_persona(f)
		print("ROG %s rol=%s sadakat=%d" % [f["name"], f.get("role"), int(f["loyalty"])])
	var id0 = ""
	for id in fs:
		if String(fs[id].get("role")) != "teacher":
			id0 = id
	var f0 = fs[id0]
	f0["rank"] = 2
	f0["news"] = "Bir kızım oldu! Adı X. Bir gün akademiye gidecek."
	get_tree().current_scene.find_child("Friends", true, false)._defect(id0)
	print("ROG kaçtı: rütbe=%s rogue=%s news='%s'" % [Friends.rank_label(f0), f0.get("rogue"), f0.get("news")])
	for k in 4:
		print("ROG selam: ", Friends.greeting(id0))
	fs["t_kamp"] = {"name": "Takumi", "role": "spar", "ninja": true, "look": {"gender": "m", "band_style": "slashed"}, "bond": 10, "village": "konoha", "rank": 1, "family": [], "status": "", "log": [], "news": ""}
	print("ROG kamp kaçağı rütbe: ", Friends.rank_label(fs["t_kamp"]))
	var low = 0
	for k in 400:
		var d = {}
		Friends._ensure_persona(d)
		if int(d["loyalty"]) < 30:
			low += 1
	print("ROG 400 kişiden hain: ", low)
	get_tree().quit()
