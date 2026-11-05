extends Node
## Genin takımıyla (hocanın verdiği) görev bitince missions_done D/C sayacı artıyor mu
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl = main.player
	await get_tree().create_timer(2.0).timeout
	Hud.close_dialog()
	var pr = Game.profile
	pr["rank"] = 1
	pr["story"] = Journal.FREE
	GeninSquad.ensure_formed()
	for r in 3:
		var before = (pr["missions_done"] as Dictionary).duplicate()
		GeninSquad.request_mission()
		await get_tree().process_frame
		for o in Hud.last_options:
			if String(o["label"]).begins_with("Geliyorum"):
				o["cb"].call()
		Hud.close_dialog()
		var sq = GeninSquad.data()
		if not sq.has("meet"):
			print("SQM %d buluşma yok: %s" % [r, Hud.last_dialog.left(80)])
			continue
		var at = Vector3(float(sq["meet"][0]), float(sq["meet"][1]), float(sq["meet"][2]))
		pl.respawn(at + Vector3(0, 1, 0))
		await get_tree().create_timer(2.0).timeout
		Hud.close_dialog()
		var m = Missions.active()
		print("SQM %d görev aktif=%s rank=%s başlık=%s" % [r, not m.is_empty(), m.get("rank", "?"), m.get("title", "")])
		Missions.complete()
		await get_tree().create_timer(2.0).timeout
		Hud.close_dialog()
		print("SQM %d önce=%s sonra=%s takım_sayaç=%d" % [r, before, pr["missions_done"], int(GeninSquad.data().get("missions", 0))])
	get_tree().quit()
