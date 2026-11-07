extends Node
## (kopya) önkoşullu ölçüm: Suisairin kıskaçla, Gufū Bōha yakın kuklayla
## Jutsu hasar ölçümü: her jutsu güç=1 bir düşman tarafından kuklaya atılır, 7 sn içindeki toplam hasar kaydedilir
var main: Node


class Rec extends TrainingDummy:
	var src: Node = null
	var total := 0.0
	var hits := 0

	func take_hit(info: Dictionary) -> void:
		if info.get("attacker") == src:
			total += float(info.get("dmg", 0.0))
			hits += 1

	func _process(_dt: float) -> void:
		hp = 1e9
		if is_instance_valid(src):
			src.attack_cd = 99.0
			src.ranged_cd = 99.0


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	Game.profile["level"] = 30
	# köy dışı açık alan
	var base = Missions.open_ground(Game.from_map(Vector2(Missions._spot("konoha", 500, 700)[0], Missions._spot("konoha", 500, 700)[1])), 40.0)
	pl.global_position = base + Vector3(0, 60, -80)
	pl.set_physics_process(false)
	await get_tree().create_timer(2.0).timeout
	var ids = Data.jutsu.keys().filter(func(k): return Data.jutsu[k] is Dictionary and not String(Data.jutsu[k].get("virtual", "")).begins_with("eye:"))
	var only = OS.get_environment("JDMG_ONLY")
	if only != "":
		ids = ids.filter(func(k): return k in only.split(","))
	var res = {}
	Engine.time_scale = 3.0
	var B = 8
	var bi = 0
	while bi < ids.size():
		var batch = ids.slice(bi, bi + B)
		bi += B
		var pairs = []
		for k in batch.size():
			var p = base + Vector3((k - B * 0.5) * 34.0, 0, 0)
			p.y = Game.ground_height(p.x, p.z)
			var a = Enemy.archetype("rogue", 0)
			a["power"] = 1.0
			a["level"] = 30
			a["respawn"] = false
			a["jutsu"] = []
			var c = Enemy.new()
			c.setup(a)
			get_tree().current_scene.add_child(c)
			c.global_position = p
			c.power = 1.0
			c.target = null
			var d = Rec.new()
			d.src = c
			get_tree().current_scene.add_child(d)
			var sh = String(Data.jutsu[batch[k]].get("shape", ""))
			d.global_position = p + Vector3(0, 0, -(3.0 if batch[k] == "gufu_boha" or sh in ["melee", "rush", "lotus", "kick", "fist", "palm", "lightning_hand", "sphere", "gates"] else 9.0))
			c.look_at(d.global_position, Vector3.UP, true)
			c.facing = atan2(0.0, 1.0)
			pairs.append([batch[k], c, d])
		await get_tree().process_frame
		for pr in pairs:
			if pr[0] == "funato_suisairin":
				Jutsu.execute(pr[1], "funato_shiomaneki", pr[2])
				await get_tree().create_timer(1.5).timeout
			Jutsu.execute(pr[1], pr[0], pr[2])
		await get_tree().create_timer(7.0).timeout
		for pr in pairs:
			var jd: Dictionary = Data.jutsu[pr[0]]
			res[pr[0]] = {"dmg": snappedf(pr[2].total, 0.1), "hits": pr[2].hits, "tier": int(jd.get("tier", 2)), "rank": String(jd.get("canon_rank", "")), "shape": String(jd.get("shape", "")), "cost": int(jd.get("cost", 0))}
			if is_instance_valid(pr[1]):
				pr[1].queue_free()
			pr[2].queue_free()
		# artık efektleri temizle
		for n in get_tree().get_nodes_in_group("fighters"):
			if n is Enemy and n != pl:
				n.queue_free()
		print("JDMG ", bi, "/", ids.size())
	Engine.time_scale = 1.0
	var f = FileAccess.open("D:/Naruto 3D Game/_tmp/jutsu_dmg_pre.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(res, "\t"))
	f.close()
	print("JDMG done ", res.size())
	get_tree().quit()
