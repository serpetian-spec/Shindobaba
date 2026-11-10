extends Node
## Bijū Ōgi (epik canavar teknikleri) testi: her canavar çıkar, hedef kuklaya iki epik tekniğini kullanır; tekniğin
## ortasında ve sonunda yandan geniş kamerayla kare alınır. Hata/çökme yakalanır. --shots=<dizin> [--only=shukaku]
var main: Node
var pl: Player
var only := ""


func _ready() -> void:
	await get_tree().process_frame
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12),
		"top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	Game.world.env.weather_t = 9999.0
	Game.world.env.region_weather = "açık"
	pl = main.player
	var v = Game.village("konoha")
	pl.respawn(Game.from_map(Vector2(v["x"] - float(v["r"]) - 700, v["y"])))   # köy dışı çayır: kum/ışık zemine karışmasın
	await get_tree().create_timer(4.0).timeout
	var base = pl.global_position
	for id in ["shukaku", "matatabi", "isobu", "son_goku", "kokuo", "saiken", "chomei", "gyuki", "kurama"]:
		if only != "" and not id in only.split(","):
			continue
		await _beast(id, base)
	print("OGI BITTI")
	get_tree().quit()


func _beast(id: String, base: Vector3) -> void:
	var b = TailedBeast.new()
	b.setup(id)
	get_tree().current_scene.add_child(b)
	var p = base
	p.y = Game.ground_height(p.x, p.z)
	b.global_position = p
	b.home = p
	b.set_physics_process(false)
	b.facing = 0.0
	b.rig.rotation.y = 0.0
	# hedef: canavarın önünde birkaç düşman kukla (oyuncu uzakta, etkilenmesin)
	pl.global_position = p + Vector3(b.height * 3.0, 0, 0)
	var dummies = []
	for k in 3:
		var a = Enemy.archetype("rogue", 0)
		var e = Enemy.new()
		e.setup(a)
		e.team = "player"   # canavarın düşmanı
		get_tree().current_scene.add_child(e)
		var q = p + Vector3((k - 1) * 6.0, 0, -b.height * 1.1)
		q.y = Game.ground_height(q.x, q.z)
		e.global_position = q
		e.set_physics_process(false)
		dummies.append(e)
	var cam = Camera3D.new()
	get_tree().current_scene.add_child(cam)
	cam.far = 4000.0
	var tgt = dummies[1]
	cam.global_position = p + Vector3(b.height * 2.6, b.height * 1.7, -b.height * 0.2)
	cam.look_at(p + Vector3(0, 0, -b.height * 1.2))
	cam.current = true
	await get_tree().create_timer(1.0).timeout
	var ts = clampf(b.height / 14.0, 2.0, 3.5)
	for t in BijuuArts.techs(id):
		if not t.get("epic", false):
			continue
		var hp0 = 0.0
		for d in dummies:
			if is_instance_valid(d):
				hp0 += d.hp
		BijuuArts.use(b, id, String(t["key"]), {"s": ts, "dmg": b._dmg(30.0), "from": b.rig.mouth_pos(), "aim": tgt.global_position + Vector3.UP, "tgt": tgt, "col": b.info["chakra"]})
		await get_tree().create_timer(0.9).timeout
		await main.shot("ogi_%s_%s_a" % [id, t["key"]])
		await get_tree().create_timer(1.6).timeout
		await main.shot("ogi_%s_%s_b" % [id, t["key"]])
		await get_tree().create_timer(1.5).timeout
		var hp1 = 0.0
		for d in dummies:
			if is_instance_valid(d):
				hp1 += d.hp
		print("OGI %s %s hasar=%.0f" % [id, t["key"], hp0 - hp1])
		for d in dummies:
			if is_instance_valid(d):
				d.hp = d.max_hp
	for d in dummies:
		if is_instance_valid(d):
			d.queue_free()
	b.queue_free()
	cam.queue_free()
	await get_tree().create_timer(0.5).timeout
