extends Node
## Katana normal tutuş + kusarigama kınlama (sırta koyma) kareleri
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.0).timeout
	Hud.show_game_hud(false)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.fov = 40
	cam.current = true
	for wid in ["kusarigama", "katana"]:
		Gear.grant(Game.profile, wid, "sag")
		Gear.apply_look(Game.profile)
		pl.rebuild_model()
		await get_tree().create_timer(2.5).timeout
		pl.model.set_drawn(true, false)
		await get_tree().create_timer(3.0).timeout
		pl.set_process(false)
		var fw = pl.face_dir()
		var c0 = pl.global_position + Vector3.UP * 1.0
		cam.global_position = c0 + fw * 3.0 - fw.cross(Vector3.UP) * 1.2 + Vector3(0, 0.3, 0)
		cam.look_at(c0)
		await get_tree().create_timer(0.2).timeout
		await main.shot("w_%s_front" % wid)
		cam.global_position = c0 - fw.cross(Vector3.UP) * 3.2 + Vector3(0, 0.4, 0)
		cam.look_at(c0)
		await get_tree().create_timer(0.2).timeout
		await main.shot("w_%s_side" % wid)
		pl.model.set_drawn(false, true)
		await get_tree().create_timer(0.18).timeout
		await main.shot("w_%s_stow1" % wid)
		await get_tree().create_timer(0.2).timeout
		await main.shot("w_%s_stow2" % wid)
		pl.set_process(true)
	get_tree().quit()
