extends Node
## Takımdaki dost mağaraya seninle girer ve orada savaşır
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	Game.profile["level"] = 25
	Game.profile["rank"] = 2
	var id = Friends._make_friend("Nara Shun", "nara", ClanWorld.clan_look("nara", "chunin", "konoha", false), 80, "Nara klanı")
	Friends.all()[id]["rank"] = 1
	Friends.set_party(id, true)
	var spot = Missions._spot("konoha", 400, 700)
	Missions.accept({"title": "Kaçakların Sığınağı", "rank": "B", "village": "konoha", "giver": "Hokage", "hook": "", "brief": "Ödüllü kaçakları avla.",
		"steps": [{"kind": "kill", "at": spot, "enemy": "rogue", "n": 3, "camp": true, "text": "Ödüllü kaçakları avla."}]})
	await get_tree().create_timer(0.5).timeout
	var door = {}
	for it in Interact.items:
		if String(it.get("room", "")).begins_with("lair_"):
			door = it
	pl.global_position = door["out"] + Vector3(0, 0.5, 0)
	await get_tree().create_timer(3.0).timeout
	var ff = Friends.inst()
	print("PC outside members=", ff.members.size(), " node=", ff.members[0]["node"] if not ff.members.is_empty() else null)
	Interiors.inst.enter(door)
	await get_tree().create_timer(3.0).timeout
	var n = ff.members[0]["node"] if not ff.members.is_empty() else null
	print("PC inside members=", ff.members.size(), " node valid=", is_instance_valid(n) if n else false, " y=", int(n.global_position.y) if n and is_instance_valid(n) else -1, " player y=", int(pl.global_position.y))
	await get_tree().create_timer(1.5).timeout
	await main.shot("party_cave")
	get_tree().quit()
