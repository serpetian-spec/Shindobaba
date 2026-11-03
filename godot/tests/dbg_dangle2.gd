extends Node
## İkincil hareket gövde-içi kontrolü: solda fiziksiz, sağda fizikli aynı saç. Koşarak ilerleme, ani duruş, hızlı dönüş;
## yan ve arka çekim. HAIR=stil1,stil2
var main: Node
var cam: Camera3D
var ms = []


func _cam_side(off: Vector3) -> void:
	var c = (ms[0].global_position + ms[1].global_position) * 0.5
	cam.global_position = c + off
	cam.look_at(c + Vector3(0, 1.2, 0))


func _move(dur: float, vel: Vector3, spin := 0.0) -> void:
	var t = 0.0
	while t < dur:
		await get_tree().process_frame
		var dt = get_process_delta_time()
		t += dt
		for m in ms:
			m.global_position += vel * dt
			m.rotation.y += spin * dt
		cam.global_position += vel * dt


func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	var v = Game.village("konoha")
	var base = Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500))
	base.y = Game.terrain_height(base.x, base.z)
	var styles = OS.get_environment("HAIR").split(",", false)
	if styles.is_empty():
		styles = PackedStringArray(["uzun", "savas_yelesi", "atkuyruğu", "ikiz_orgu", "yele"])
	cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.fov = 40
	var outers = OS.get_environment("OUTER").split(",", false)
	for si in styles.size():
		var st = styles[si]
		var ou = outers[si % outers.size()] if outers.size() > 0 else ""
		ms = []
		for i in 2:
			var m = CharacterModel.new()
			main.add_child(m)
			var lk = {"gender": "f" if st in ["uzun", "ikiz_orgu", "atkuyruğu"] else "m", "hair_style": st, "hair": Color(0.55, 0.25, 0.15), "top_style": "uzun", "band": Color(0.15, 0.2, 0.4), "band_style": "head", "village": "konoha", "face": [0, 0, 0]}
			if ou != "":
				lk["outer_style"] = null if ou == "hakama" else ou
				lk["outer"] = Color(0.12, 0.12, 0.16) if ou == "org_pelerin" else Color(0.75, 0.7, 0.6)
				lk["hakama"] = ou == "hakama"
			if OS.get_environment("HEAD") != "":
				lk["head_style"] = OS.get_environment("HEAD")
				lk["headgear"] = Color(0.7, 0.15, 0.15)
			m.setup(lk)
			m.global_position = base + Vector3(0, 0, i * 1.0)
			m.rotation.y = -PI * 0.5   # yüz +X
			m.play("idle")
			if i == 0:
				m._dangles = []
			ms.append(m)
		_cam_side(Vector3(-0.3, 1.35, -2.8))
		await get_tree().create_timer(1.0).timeout
		await main.shot("d2_%s%s_1rest_back" % [st, ou])
		for m in ms:
			m.play("run")
		await _move(0.8, Vector3(7, 0, 0))
		_cam_side(Vector3(0.2, 1.3, -2.6))
		await main.shot("d2_%s%s_2run_side" % [st, ou])
		for m in ms:
			m.play("idle")
		await _move(0.15, Vector3.ZERO)
		await main.shot("d2_%s%s_3stop_side" % [st, ou])
		await _move(0.3, Vector3.ZERO, 12.0)
		_cam_side(Vector3(-2.6, 1.3, 0.2))
		await main.shot("d2_%s%s_4spin" % [st, ou])
		for m in ms:
			m.queue_free()
		await get_tree().process_frame
	get_tree().quit()
