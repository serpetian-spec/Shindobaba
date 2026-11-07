extends Node
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	Game.profile["flags"]["rogue"] = true
	Game.profile["flags"]["rogue_from"] = "suna"
	var pl = main.player
	var v = Game.village("konoha")
	pl.respawn(Game.from_map(Vector2(v["x"] + float(v["r"]) * 0.85, v["y"])))
	await _w(1.0)
	var seen0 = Orgs._spotted_by("konoha")
	await _w(3.0)
	print("SNEAK edge: spotted=%s raid=%s" % [seen0, not Orgs._raid.is_empty()])
	var vg = Villager.new()
	vg.role = "walker"
	get_tree().current_scene.add_child(vg)
	vg.global_position = pl.global_position + pl.face_dir() * -0.0 + Vector3(4, 0, 0)
	vg.facing = atan2(4, 0)   # oyuncuya bakar (-x yönü)
	await _w(0.3)
	vg.facing = atan2(1.0, 0.0)
	print("SNEAK villager near: spotted=%s" % Orgs._spotted_by("konoha"))
	await _w(3.0)
	print("SNEAK after 3s: raid=%s" % (not Orgs._raid.is_empty()))
	get_tree().quit()
