extends Node
## Kusarigama sırtta (kında): koşu + ani duruş + dönüşte zincir kare dizisi, zincir boyu ölçümü
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(1.5).timeout
	Hud.show_game_hud(false)
	Gear.grant(Game.profile, "kusarigama", "sag")
	Gear.apply_look(Game.profile)
	pl.rebuild_model()
	await get_tree().create_timer(1.5).timeout
	pl.model.set_drawn(false, false)
	pl.set_physics_process(false)
	pl.set_process(false)
	var m = pl.model
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.fov = 40
	cam.current = true
	await get_tree().create_timer(0.5).timeout
	var fw = pl.face_dir()
	m.play("run")
	var t = 0.0
	var shots = 0
	var nx = 0.3
	var maxlen = 0.0
	while t < 2.4:
		await get_tree().process_frame
		var dt = get_process_delta_time()
		t += dt
		if t < 1.0:
			pl.global_position += fw * 7.0 * dt
		elif t < 1.05:
			m.play("idle")
		elif t > 1.6 and t < 1.95:
			pl.rotation.y += 10.0 * dt
		var L = 0.0
		for k in m.KCH_N:
			L += m._kch_p[k].distance_to(m._kch_p[k + 1])
		maxlen = maxf(maxlen, L)
		var c = pl.global_position + Vector3.UP * 1.1
		cam.global_position = c - fw * 2.4 + fw.cross(Vector3.UP) * 1.2 + Vector3(0, 0.3, 0)
		cam.look_at(c)
		if t > nx and shots < 16:
			await main.shot("ks_%02d" % shots)
			shots += 1
			nx = t + 0.13
	print("KCHAIN rest_len=", m.KCH_N * m.KCH_SEG, " max_len=", snappedf(maxlen, 0.01))
	get_tree().quit()
