extends Node
## Akamaru + İki Başlı Kurt referans açıları (VER)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var v = Game.village("suna")
	var base = Missions.open_ground(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 700)), 160.0)
	pl.respawn(base)
	await get_tree().create_timer(3.0).timeout
	pl.set_process(false)
	var ver = OS.get_environment("VER")
	var p = base + Vector3(0, 0, -8.0)
	p.y = Game.terrain_height(p.x, p.z)
	var ak = InuzukaModels.akamaru(1.3)
	main.add_child(ak["root"])
	ak["root"].global_position = p
	ak["root"].rotation.y = 0.0
	var w = InuzukaModels.twin_wolf(2, 4.4)
	main.add_child(w["root"])
	var p2 = base + Vector3(14, 0, -12.0)
	p2.y = Game.terrain_height(p2.x, p2.z)
	w["root"].global_position = p2
	w["root"].rotation.y = deg_to_rad(-25)
	await get_tree().create_timer(0.6).timeout
	var shots = [
		["ak_front", p + Vector3(0.0, 1.6, -3.6), p + Vector3(0.0, 1.5, -0.9)],
		["ak_side", p + Vector3(-4.0, 1.3, -0.6), p + Vector3(0, 1.0, -0.3)],
		["wolf_front", p2 + Vector3(-4.5, 2.2, -11.0), p2 + Vector3(-0.5, 2.0, -2.0)],
		["wolf_side", p2 + Vector3(-12.0, 3.0, 2.0), p2 + Vector3(0, 2.5, 0)],
	]
	for s in shots:
		pl.cam.global_position = s[1]
		pl.cam.look_at(s[2])
		await get_tree().create_timer(0.25).timeout
		await main.shot("inu_%s_%s" % [ver, s[0]])
	get_tree().quit()
