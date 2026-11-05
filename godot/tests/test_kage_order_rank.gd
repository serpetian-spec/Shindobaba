extends Node
## Kage emirleri rütbeye göre: genine A/S emri gelmez (ANBU halleder), Chūnin A alır, Jōnin S alır; örgüt haberi Chūnin altına gelmez
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.5).timeout
	Hud.close_dialog()
	var pr = Game.profile
	var fr = get_tree().current_scene.find_child("Friends", true, false)
	var id = Friends.all().keys()[0]
	var sc = {"title": "Test planı", "kind": "coup", "good": false}
	for rk in [0, 1, 2, 3]:
		for urgent in [false, true]:
			pr["rank"] = rk
			pr["active_mission"] = {}
			fr._kage_order(id, sc, urgent)
			var m = Missions.active()
			print("KAGE rank=%d %s -> görev=%s" % [rk, "S(acil)" if urgent else "A", m.get("title", "-") if not m.is_empty() else "yok (ANBU)"])
			Missions.abandon()
	pr["rank"] = 1
	pr["level"] = 40
	Orgs._ro_job_t = 0.0
	Orgs._ro_job_tick(1.0)
	print("ORG rank=1 haber dialog=%s" % Hud.last_dialog.left(30))
	get_tree().quit()
