extends Node
## Dostluk/düşmanlık + takım + dinamik yaşam: klan üyesiyle tanış, bağ, takım, hayat olayları, kaçış, ölüm, arkadaş kartı
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	Game.profile["rank"] = 2
	Game.profile["level"] = 30
	var fr = main.actors.get_node("Friends")
	var ids = []
	for k in 3:
		var v = ClanResident.new()
		v.clan = ["hyuga", "uchiha", "nara"][k]
		v.vid = "konoha"
		v.given = ClanWorld.person_name(v.clan, k == 1)
		v.display_override = v.given
		v.role = "nurse"
		v.look_extra = ClanWorld.clan_look(v.clan, "chunin", "konoha", k == 1, "adult")
		v.eye_kind = 2 if k == 0 else 0
		main.actors.add_child(v)
		v.global_position = pl.global_position + Vector3(2 + k, 0, 0)
		await get_tree().create_timer(0.3).timeout
		print("FR opts=", Friends.options_for(v).map(func(o): return o["label"]))
		Friends._meet(v)
		ids.append(String(v.get_meta("friend_id")))
		v.vanish()
	var f0: Dictionary = Friends.all()[ids[0]]
	print("FR met ", f0["name"], " rank=", Friends.RANKS[f0["rank"]], " family=", f0["family"].map(func(m): return m["rel"] + " " + m["name"]))
	Friends.add_bond(ids[0], 40)
	Friends.add_bond(ids[1], -50)
	print("FR enemy greet=", Friends.greeting(ids[1]), " opts=", Friends._friend_opts(ids[1], null).map(func(o): return o["label"]))
	Menus.clear()
	Friends.set_party(ids[0], true)
	for i in 25:
		fr._life_event()
	for id in ids:
		var f: Dictionary = Friends.all()[id]
		print("FR life ", f["name"], " rank=", Friends.RANKS[f["rank"]], " status=", f["status"], " log=", f["log"])
	fr._defect(ids[2])
	print("FR defect bingo=", Friends.bingo_status(ids[2]))
	Friends.all()[ids[0]]["status"] = ""
	Friends.all()[ids[0]]["away"] = 0.0
	Friends.all()[ids[0]]["party"] = true
	await get_tree().create_timer(2.0).timeout
	print("FR members=", fr.members.size(), " spawned=", fr.members.size() > 0 and fr.members[0]["node"] != null)
	Menus.clear()
	Menus._friend_i = 0
	Menus.ninja_menu(main, "missions")
	await get_tree().create_timer(1.0).timeout
	await main.shot("friends_tab")
	Menus.clear()
	get_tree().quit()
