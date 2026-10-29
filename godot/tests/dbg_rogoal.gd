extends Node
## Örgüt amaç görevleri: her amaç için görev üretilir; 4 üye düşünce merkez açılır
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	Game.profile["level"] = 30
	var o = Orgs.random_orgs()[0]
	for g in Orgs.RO_GOALS:
		o["goal"] = g[0]
		var j = Orgs.ro_goal_job(o)
		print("RG %s -> %s (%d adım)" % [g[0], j["title"], j["steps"].size()])
	Missions.accept(Orgs.ro_goal_job(o))
	print("RG accepted=%s" % Missions.active().get("title"))
	Game.profile["active_mission"] = {}
	for m in o["members"].slice(1):
		Orgs._ro_member_down(o["name"], m["name"])
	await get_tree().create_timer(3.0).timeout
	print("RG base_open=%s" % o.get("base_open", false))
	get_tree().quit()
