extends Node
## Her köyün ilk kapısını dışarıdan çek (kapı-sur birleşimi)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	var pl = main.player
	await get_tree().create_timer(2.0).timeout
	Hud.show_game_hud(false)
	var only = OS.get_environment("GATES")
	for vid in (only.split(",") if only != "" else ["konoha", "suna", "kiri", "kumo", "iwa", "ame", "kusa", "taki", "oto", "tetsu"]):
		var v = Game.village(vid)
		var gates: Array = v.get("gates", [])
		if gates.is_empty():
			continue
		var c = Game.from_map(Vector2(v["x"], v["y"]))
		var r = float(v["r"])
		var g = float(gates[0])
		var dir = Vector3(sin(deg_to_rad(g)), 0, -cos(deg_to_rad(g)))
		var outp = c + dir * (r * 0.95 + 150.0)
		outp.y = Game.ground_height(outp.x, outp.z)
		pl.respawn(outp)
		pl.set_process(false)
		await get_tree().create_timer(7.0).timeout
		var cam = Camera3D.new()
		main.add_child(cam)
		cam.far = 4000
		cam.current = true
		var gp = c + dir * r * 0.95
		gp.y = Game.ground_height(gp.x, gp.z)
		cam.global_position = outp + Vector3(0, 30, 0) + dir * 40.0
		cam.look_at(gp + Vector3(0, 15, 0))
		await get_tree().create_timer(0.5).timeout
		await main.shot("gate_%s" % vid)
		cam.queue_free()
		pl.set_process(true)
	get_tree().quit()
