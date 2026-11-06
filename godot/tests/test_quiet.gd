extends Node
## Görev ortasında araya kimse girmez: kaçak + görev aktif -> av-ninjası, yol olayı, takım saldırısı yok
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.15), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.3, 0.3), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	var vs = Game.village("konoha")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 600, vs["y"])))
	await get_tree().create_timer(1.0).timeout
	Orgs.flags()["rogue"] = true
	Game.profile["active_mission"] = {"name": "test", "rank": "C", "steps": [], "step": 0}
	print("Q quiet=%s can_start=%s" % [str(Missions.quiet()), str(Encounters._can_start(pl.global_position))])
	Orgs._hunter_t = 99999.0
	Orgs._hunter_next = 0.0
	var before = Orgs._spawned.size()
	Orgs._hunter_tick(0.1)
	print("Q hunters during mission: %d" % (Orgs._spawned.size() - before))
	Game.profile["active_mission"] = {}
	print("Q quiet after=%s" % str(Missions.quiet()))
	Orgs._hunter_tick(0.1)
	print("Q hunters after mission: %d" % (Orgs._spawned.size() - before))
	get_tree().quit()
