extends Node
## Gizli jutsular satılmaz: simsar iz satar -> görev -> parşömen açılınca öğrenilir; Sekiz Kapı simsarda yok; Shiki Fūjin yalnız tapınak
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uzumaki", "element": "katon", "hair_style": "diken", "hair": Color(0.8, 0.2, 0.2), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pr = Game.profile
	pr["level"] = 30
	pr["ryo"] = 99999
	pr["flags"]["rogue"] = true
	Orgs.flags()["infamy"] = 2500
	Orgs.flags()["hideout"] = [Game.to_map(main.player.global_position).x, Game.to_map(main.player.global_position).y]
	Orgs._kinjutsu_dialog()
	var labels = Hud.last_options.map(func(o): return String(o["label"]))
	print("KA options=%d gates_in=%s shiki_in=%s first=%s" % [labels.size(), str(labels.any(func(l): return "Renge" in l or "Asakujaku" in l or "Hachimon" in l)), str(labels.any(func(l): return "Shiki" in l)), labels[0] if labels.size() > 0 else "-"])
	var opt = Hud.last_options[0]
	var before = pr["learned"].size()
	opt["cb"].call()
	var lead = String(Orgs.flags().get("kinjutsu_lead", ""))
	print("KA after_buy learned_delta=%d lead=%s mission=%s steps=%d" % [pr["learned"].size() - before, lead, str(pr.get("active_mission", {}).get("title")), (pr.get("active_mission", {}).get("steps", []) as Array).size()])
	Orgs.kinjutsu_found({"jid": lead}, true)
	print("KA after_quest learned=%s" % str(lead in pr["learned"]))
	# tapınak
	Hud.close_dialog()
	Progress._uzumaki_shrine()
	var so = Hud.last_options
	print("KA shrine_opts=%d" % so.size())
	if so.size() > 0:
		so[0]["cb"].call()
	print("KA shiki_learned=%s" % str("shiki_fujin" in pr["learned"]))
	await _w(0.5)
	get_tree().quit()
