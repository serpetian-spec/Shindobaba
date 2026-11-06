extends Node
## Kâğıt Yolu: kule görüntüsü, antrenmanlar, kule tepesine rampalardan yürüyerek çıkılabilir mi
var main: Node
func _w(t): await get_tree().create_timer(t).timeout
func _shot(name: String, at: Vector3, from: Vector3) -> void:
	main.player.set_process(false)
	main.player.cam.global_position = from
	main.player.cam.look_at(at)
	await _w(0.2)
	await main.shot(name)
	main.player.set_process(true)
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(1.5)
	Hud.close_dialog()
	main.world.env.time_of_day = 0.45
	var L: Array = LegendPaths.lairs["kagit"]
	var c = Vector3(L[0], 0, -L[1])
	c.y = Game.terrain_height(c.x, c.z)
	var pl = main.player
	pl.respawn(c + Vector3(0, 1, 30))
	await _w(6.0)
	var sp = LegendPaths.drill_spots.get("kagit", {})
	print("KGT noktalar: ", sp.keys())
	var top: Vector3 = sp["top"][0]
	Hud.show_game_hud(false)
	await _shot("kgt_genel", top - Vector3(0, 8, 0), top + Vector3(-22, -4, -26))
	await _shot("kgt_yakin", top - Vector3(0, 14, 0), top + Vector3(-9, -12, -12))
	await _shot("kgt_tepe", top + Vector3(-1.5, 1.2, 0), top + Vector3(4, 3, -4))
	await _shot("kgt_avlu", sp["mats"][1] + Vector3(0, 0.5, 0), sp["mats"][1] + Vector3(3, 3, -5))
	Hud.show_game_hud(true)
	# kule tepesine yürüyerek çıkış: yerçekimli kapsül, her rampanın alt ucuna sonra üst ucuna yürür
	var probe = CharacterBody3D.new()
	var pcs = CollisionShape3D.new()
	var cap = CapsuleShape3D.new(); cap.radius = 0.35; cap.height = 1.7
	pcs.shape = cap; pcs.position.y = 0.9
	probe.add_child(pcs)
	get_tree().current_scene.add_child(probe)
	probe.global_position = Missions.open_ground(c + Vector3(0, 0, 4), 10.0) + Vector3.UP * 0.2
	var maxy = probe.global_position.y
	for k in 2400:   # ~40 sn: kuleye yaklaş, etrafında dön ve yüksel (rampa varsa yükseklik artar)
		var to = top - probe.global_position
		to.y = 0
		var ang = float(k) * 0.01
		var dir = (to.normalized() + Vector3(cos(ang), 0, sin(ang)) * 1.2).normalized()
		probe.velocity = dir * 5.0 + Vector3(0, probe.velocity.y - 20.0 / 60.0, 0)
		probe.move_and_slide()
		maxy = maxf(maxy, probe.global_position.y)
		await get_tree().physics_frame
	print("KGT tırmanış: başlangıç y=%.1f ulaşılan en yüksek=%.1f tepe=%.1f" % [c.y, maxy, top.y])
	probe.queue_free()
	var LP = LegendPaths.node()
	var pr = Game.profile
	for jid in ["kami_bunshin", "kami_tsubasa"]:
		LP.start_drill("kagit", jid)
		Hud.close_dialog()
		for td in LP.drill["tend"]:
			pl.global_position = td["pos"] + Vector3.UP * 0.3
			await _w(float(LP.drill["dwell"]) + 0.6)
		print("KGT %s: aktif=%s öğrenildi=%s" % [jid, not LP.drill.is_empty(), jid in pr["learned"]])
	LP.start_drill("kagit", "kami_chocho")
	Hud.close_dialog()
	await _w(0.5)
	await _shot("kgt_kelebek", LP.drill["center"] + Vector3(0, 1.2, 0), LP.drill["center"] + Vector3(6, 4, -8))
	for bf in LP.drill["dummies"]:
		if is_instance_valid(bf):
			pl.global_position = bf.global_position - Vector3.UP * 0.5
			await _w(0.08)
	await _w(0.3)
	print("KGT kami_chocho: aktif=%s öğrenildi=%s" % [not LP.drill.is_empty(), "kami_chocho" in pr["learned"]])
	LP.start_drill("kagit", "kami_yari")
	Hud.close_dialog()
	await _w(0.3)
	for i in 30:
		var d = LP.drill["dummies"][i % 3]
		if is_instance_valid(d):
			d.take_hit({"dmg": 5.0, "melee": true})
	await _w(0.2)
	print("KGT kami_yari: aktif=%s öğrenildi=%s" % [not LP.drill.is_empty(), "kami_yari" in pr["learned"]])
	get_tree().quit()
