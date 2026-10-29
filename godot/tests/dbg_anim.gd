extends Node
## Jutsuya özel koreografi: hazırlık ve salınım kareleri (yandan, yakın)
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
	cam.current = true
	cam.fov = 50
	var ids = OS.get_environment("IDS").split(",")
	for id in ids:
		var fw = pl.face_dir()
		var c0 = pl.global_position + Vector3.UP * 1.0
		cam.global_position = c0 + fw * 2.2 - fw.cross(Vector3.UP) * 2.6 + Vector3.UP * 0.4
		cam.look_at(c0)
		var a = CastAnim.play(pl, id)
		await get_tree().create_timer(maxf(0.05, a.release_t - 0.08)).timeout
		await main.shot("an_%s_a" % id)
		await get_tree().create_timer(0.2).timeout
		await main.shot("an_%s_b" % id)
		await get_tree().create_timer(1.2).timeout
	get_tree().quit()
