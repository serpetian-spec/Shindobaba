extends Node
## Kaçak köye açıkta girer: köy ninjası görünce anında alarm — kaç sn sürüyor
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	pl.max_hp = 1e9; pl.hp = 1e9
	var vs = Game.village("konoha")
	pl.respawn(Game.from_map(Vector2(float(vs["x"]), float(vs["y"]))))
	await _w(3.0)
	Hud.close_dialog()
	var ninja = null
	for v in get_tree().get_nodes_in_group("talkers"):
		if (v is Villager or v is ClanResident) and Friends.is_ninja(v) and not v.has_meta("friend_id"):
			ninja = v
			break
	pl.global_position = ninja.global_position + ninja.face_dir() * 5.0 + Vector3.UP * 0.2
	Orgs._raid = {}
	Orgs.flags()["rogue"] = true
	Orgs.flags()["rogue_from"] = "konoha"
	var t0 = Time.get_ticks_msec()
	while Orgs._raid.is_empty() and Time.get_ticks_msec() - t0 < 6000:
		await get_tree().process_frame
	print("RSPOT %s alarm after %.2f s (ninja 5 m önünde)" % ["OK" if not Orgs._raid.is_empty() else "NO", (Time.get_ticks_msec() - t0) / 1000.0])
	get_tree().quit()
