extends Node
## Hareket dizisi: yan çekimde koşu -> ani duruş -> dönüş, 0.07 s arayla kareler (doğallık/yaylanma kontrolü).
## Uç sapması zaman serisi de yazdırılır (aşma/zıplama sayısı). HAIR, OUTER env.
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	var v = Game.village("konoha")
	var base = Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500))
	base.y = Game.terrain_height(base.x, base.z)
	var st = OS.get_environment("HAIR") if OS.get_environment("HAIR") != "" else "uzun"
	var ou = OS.get_environment("OUTER")
	var lk = {"gender": "f" if st in ["uzun", "atkuyruğu"] else "m", "hair_style": st, "hair": Color(0.55, 0.25, 0.15), "top_style": "uzun", "band": Color(0.15, 0.2, 0.4), "band_style": "head", "village": "konoha", "face": [0, 0, 0]}
	if ou != "":
		lk["outer_style"] = ou
		lk["outer"] = Color(0.75, 0.7, 0.6)
	var m = CharacterModel.new()
	main.add_child(m)
	m.setup(lk)
	m.global_position = base
	m.rotation.y = -PI * 0.5
	m.play("idle")
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.fov = 35
	await get_tree().create_timer(0.8).timeout
	var fwd = Vector3(1, 0, 0)
	var shots = 0
	var t = 0.0
	var phase = ""
	var next_shot = 0.0
	var series = []
	m.play("run")
	while t < 2.6:
		await get_tree().process_frame
		var dt = get_process_delta_time()
		t += dt
		if t < 1.0:
			m.global_position += fwd * 7.0 * dt
			phase = "run"
		elif t < 1.03:
			m.play("idle")
			phase = "stop"
		elif t > 1.9 and t < 2.2:
			m.rotation.y += 9.0 * dt
			phase = "spin"
		var c = m.global_position + Vector3(0, 1.25, 0)
		cam.global_position = c + Vector3(0, 0.1, -2.4)
		cam.look_at(c)
		# uç sapması: ilk dinamiğin en uzun zincirinin ucu, ileri eksende
		if not m._dangles.is_empty():
			var d = m._dangles[0]
			if d._live:
				var rest: PackedVector3Array = d.chains[0]["rest"]
				var xf = d.skel.global_transform
				if d.ext_root >= 0:
					xf = xf * d.skel.get_bone_global_pose(d.ext_root) * d.ext_rest_inv
				var dev = d._p[0][rest.size() - 1] - xf * rest[rest.size() - 1]
				series.append("%.2f:%+.3f/%+.3f" % [t, dev.x, dev.y])
		if t > 0.5 and t >= next_shot and shots < 24:
			await main.shot("sq_%02d_%s" % [shots, phase])
			shots += 1
			next_shot = t + 0.085
	var out = []
	for i in range(0, series.size(), 6):
		out.append(series[i])
	print("SERIES ", " ".join(out))
	get_tree().quit()
