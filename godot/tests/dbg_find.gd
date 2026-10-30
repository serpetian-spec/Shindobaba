extends Node
## Haritada bulma + takım paneli
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	Game.profile["rank"] = 2
	var v = ClanResident.new()
	v.clan = "nara"; v.vid = "konoha"; v.given = "Nara Shun"; v.display_override = v.given; v.role = "nurse"
	v.look_extra = ClanWorld.clan_look("nara", "chunin", "konoha", false, "adult")
	main.actors.add_child(v)
	var home = pl.global_position + Vector3(60, 0, 0)
	v.global_position = home
	await get_tree().create_timer(0.3).timeout
	Friends._meet(v)
	Menus.clear()
	var id = String(v.get_meta("friend_id"))
	v.queue_free()
	Friends.show_on_map(id)
	print("FIND wp=", Game.profile.get("waypoint"))
	pl.global_position = home + Vector3(5, 0, 0)
	await get_tree().create_timer(1.5).timeout
	var found = get_tree().get_nodes_in_group("talkers").filter(func(n): return String(n.get_meta("friend_id", "")) == id)
	print("FIND spawned=", found.size())
	# takım paneli
	var f: Dictionary = Friends.all()[id]
	f["bond"] = 70
	f["rank"] = 1
	Friends.set_party(id, true)
	await get_tree().create_timer(2.0).timeout
	print("PARTY visible=", Hud.party_box.visible, " row0=", Hud.party_rows[0][1].text)
	await main.shot("party")
	get_tree().quit()
