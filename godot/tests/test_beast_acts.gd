extends Node
## Tam dönüşümde teknik hareketleri + epik Bijūdama: her tekniğin vuruş anı ve top şarjı/atışı/patlaması kare kare.
## Kullanım: --test=res://tests/test_beast_acts.gd --shots=<dizin> [--ids=kurama,shukaku]

var main: Node
var pl: Player
var ids := ["kurama", "shukaku", "matatabi"]


func _ready() -> void:
	await get_tree().process_frame
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ids="):
			ids = Array(a.substr(6).split(","))
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12),
		"top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	Game.world.env.weather_t = 9999.0
	Game.world.env.region_weather = "açık"
	pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(4.0).timeout
	for id in ids:
		await _run(id)
	print("ACTS BITTI")
	get_tree().quit()


func _process(_dt: float) -> void:
	if pl:
		pl.chakra = pl.max_chakra
		pl.hp = pl.max_hp


func _cam(cam: Camera3D, h: float, wide := 1.0) -> void:
	var b = pl.global_position
	var f = pl.face_dir()
	var r = f.cross(Vector3.UP).normalized()
	cam.global_position = b + f * h * 1.2 * wide + r * h * 1.5 * wide + Vector3.UP * h * 0.55
	cam.look_at(b + Vector3.UP * h * 0.5 + f * h * 0.3)


func _run(id: String) -> void:
	TailedBeasts.make_jinchuriki(id)
	TailedBeasts.beasts()[id]["trust"] = 100.0
	pl.chakra = pl.max_chakra
	var cl: BeastCloak = pl.combat.modes.cloak
	cl.set_level(6)
	await get_tree().create_timer(1.5).timeout
	var h = cl.rig.height_m
	var cam = Camera3D.new()
	get_tree().current_scene.add_child(cam)
	cam.far = 4000.0
	cam.fov = 60.0
	cam.current = true
	# --- Bijūdama: şarj başı, tam boy, yutma, atış, patlama
	cl.bomb_cd = 0.0
	pl.chakra = pl.max_chakra
	cl._bomb()
	var marks = [0.5, 1.5, 1.95, 2.2, 2.7, 3.3]
	var t0 := 0.0
	for i in marks.size():
		await get_tree().create_timer(marks[i] - t0).timeout
		t0 = marks[i]
		_cam(cam, h, 1.0 if i < 4 else 2.2)
		await get_tree().process_frame
		await main.shot("ba_%s_0top%d" % [id, i])
	await get_tree().create_timer(2.5).timeout
	# --- teknikler: her birinin vuruş anı
	var l = BijuuArts.techs(id)
	for i in l.size():
		cl.tech_cd.clear()
		pl.chakra = pl.max_chakra
		var key: String = l[i]["key"]
		var an: Array = BijuuArts.anim(key)
		var p0 = pl.global_position
		cl._tech(i)
		print("TEKNIK %s %s -> %s %.1f sn, çıkış %.2f | rig.action=%s" % [id, key, an[0], an[1], an[2], cl.rig.action if is_instance_valid(cl.rig) else "?"])
		var hit = maxf(0.12, float(an[1]) * float(an[2]))
		await get_tree().create_timer(hit * 0.6).timeout
		_cam(cam, h)
		await get_tree().process_frame
		await main.shot("ba_%s_%d%s_a" % [id, i + 1, key])
		await get_tree().create_timer(hit * 0.4 + 0.25).timeout
		_cam(cam, h)
		await get_tree().process_frame
		await main.shot("ba_%s_%d%s_b" % [id, i + 1, key])
		await get_tree().create_timer(3.0).timeout
		if is_instance_valid(cl.rig) and cl.level == 6:
			pl.global_position = p0
	cl.set_level(0)
	cam.queue_free()
	await get_tree().create_timer(0.8).timeout
