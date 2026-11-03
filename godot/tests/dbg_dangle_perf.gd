extends Node
## 20 karakter (uzun saç + pelerin + bant) kameraya 3-10 m: ikincil hareket kare başı maliyeti
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	var v = Game.village("konoha")
	var base = Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500))
	base.y = Game.terrain_height(base.x, base.z)
	var ms = []
	var hs = ["uzun", "savas_yelesi", "atkuyruğu", "yele", "ikiz_orgu"]
	for i in 20:
		var m = CharacterModel.new()
		main.add_child(m)
		m.setup({"gender": "f" if i % 2 == 0 else "m", "hair_style": hs[i % hs.size()], "band": Color(0.2, 0.2, 0.4), "band_style": "head", "outer_style": "pelerin", "outer": Color(0.5, 0.4, 0.3)})
		m.global_position = base + Vector3((i % 5) * 1.5, 0, 3 + (i / 5) * 2.0)
		m.play("run")
		m.set_process(false)
		ms.append(m)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.global_position = base + Vector3(3, 1.6, 0)
	cam.look_at(base + Vector3(3, 1.2, 6))
	await get_tree().create_timer(0.5).timeout
	var pts = 0
	for m in ms:
		for d in m._dangles:
			for c in d.chains:
				pts += c["rest"].size()
	var tot = 0
	var frames = 120
	for f in frames:
		for m in ms:
			m.global_position.z += 0.05
		var t0 = Time.get_ticks_usec()
		for m in ms:
			m._dangle_process(1.0 / 60.0)
		tot += Time.get_ticks_usec() - t0
		await get_tree().process_frame
	print("PERF chars=20 points=", pts, " avg_ms_per_frame=", snappedf(tot / 1000.0 / frames, 0.01))
	get_tree().quit()
