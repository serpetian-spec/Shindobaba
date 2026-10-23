extends Node
## Kuyruklu canavar teknikleri testi: her canavarın jinchūriki pelerininde üç tekniği (hedef kuklalara), iki tam dönüşüm,
## boss canavarların kendi teknikleri ve düşman jinchūriki. Her teknikten ekran görüntüsü alır.
## Kullanım: --test=res://tests/test_bijuu.gd --shots=<dizin>  (ek: --only=shukaku,kurama)

var main: Node
var pl: Player
var foes: Array = []
const IDS := ["shukaku", "matatabi", "isobu", "son_goku", "kokuo", "saiken", "chomei", "gyuki", "kurama"]


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12),
		"top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	Game.world.env.weather_t = 9999.0
	Game.world.env.region_weather = "açık"
	pl = main.player
	Game.profile["level"] = 60
	pl.max_chakra = 9999.0
	var only = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7).split(",")
	var v = Game.village("suna")   # açık çöl: ağaç yok, efektler net görünsün
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(4.0).timeout
	var base = pl.global_position
	pl.cam_dist = 9.0
	for id in IDS:
		if not only.is_empty() and not id in only:
			continue
		await _cloak_run(id, base)
	if only.is_empty() or "giant" in only:
		for id in ["shukaku", "kurama"]:
			await _giant_run(id, base)
	if only.is_empty() or "boss" in only:
		await _boss_run(base)
	if only.is_empty() or "enemy" in only:
		await _enemy_run(base)
	print("BIJUU TEST BITTI")
	get_tree().quit()


func _spawn_foes(base: Vector3, fwd: Vector3, n := 3, dist := 14.0) -> void:
	for f in foes:
		if is_instance_valid(f):
			f.queue_free()
	foes.clear()
	for i in n:
		var e = Enemy.new()
		var a = Enemy.archetype("bandit", i)
		a["hp"] = 99999.0
		a["respawn"] = false
		a["aggr"] = 0.05
		a["tools"] = false
		a["jutsu"] = []
		e.setup(a)
		get_tree().current_scene.add_child(e)
		var side = fwd.cross(Vector3.UP).normalized()
		var p = base + fwd * (dist + i * 2.0) + side * (i - 1) * 3.0
		p.y = Game.ground_height(p.x, p.z)
		e.global_position = p
		e.home = p
		foes.append(e)


func _reset(base: Vector3) -> void:
	pl.global_position = base
	pl.velocity = Vector3.ZERO
	pl.reset_physics_interpolation()
	pl.facing = 0.0
	pl.yaw = 0.0   # kamera oyuncunun arkasından -Z'ye (hedeflere) baksın
	pl.chakra = pl.max_chakra
	pl.statuses.clear()
	pl.input_locked = 0.0


func _cloak_run(id: String, base: Vector3) -> void:
	_reset(base)
	TailedBeasts.make_jinchuriki(id)
	TailedBeasts.beasts()[id]["trust"] = 100.0
	var cl: BeastCloak = pl.combat.modes.cloak
	cl.set_level(5)
	await get_tree().create_timer(0.6).timeout
	var keys = BijuuArts.techs(id)
	for i in keys.size():
		_reset(base)
		_spawn_foes(base, -pl.global_transform.basis.z if false else Vector3.FORWARD)
		await get_tree().create_timer(0.3).timeout
		pl.combat.lock_target = foes[1]
		cl.tech_cd.clear()
		pl.chakra = pl.max_chakra
		cl._tech(i)
		var waits = {"kaen_breath": 0.7, "sumi": 0.6, "sabaku_taiso": 0.7, "funkatsu": 1.0, "tako_ude": 0.45, "chakra_kaina": 0.42, "renkudan": 0.25,
			"aobi_dama": 0.55, "kakogan": 0.8, "fukuso": 0.9, "rinpun": 0.42, "mushi_swarm": 0.45, "neko_pounce": 0.45, "shell_roll": 0.45, "horn_ram": 0.4,
			"bijudama_rasengan": 0.5, "sango": 0.45, "kiri_genjutsu": 1.2, "futton_boil": 1.0, "slime": 0.8, "acid_mist": 1.2, "hane_flight": 0.5,
			"tako_bunshin": 0.4, "biju_hoko": 0.3, "steam_burst": 0.2, "suna_tate": 0.6, "yoton_yoroi": 0.6}
		await get_tree().create_timer(float(waits.get(keys[i]["key"], 0.5))).timeout
		await main.shot("bj_%s_%d_%s" % [id, i, keys[i]["key"]])
		print("BIJUU %s %s: foes hp %s binds %s" % [id, keys[i]["key"], str(foes.map(func(f): return int(f.hp) if is_instance_valid(f) else -1)),
			str(foes.map(func(f): return f.statuses.keys() if is_instance_valid(f) else []))])
		await get_tree().create_timer(1.6).timeout
	cl.set_level(0)
	await get_tree().create_timer(0.5).timeout


func _giant_run(id: String, base: Vector3) -> void:
	_reset(base)
	TailedBeasts.make_jinchuriki(id)
	TailedBeasts.beasts()[id]["trust"] = 100.0
	var cl: BeastCloak = pl.combat.modes.cloak
	cl.set_level(6)
	await get_tree().create_timer(1.0).timeout
	for i in 3:
		_reset(base)
		_spawn_foes(base, Vector3.FORWARD, 3, 40.0)
		await get_tree().create_timer(0.3).timeout
		pl.combat.lock_target = foes[1]
		cl.tech_cd.clear()
		cl._tech(i)
		await get_tree().create_timer(0.55).timeout
		await main.shot("bjg_%s_%d" % [id, i])
		await get_tree().create_timer(1.5).timeout
	cl._giant_swipe()
	await get_tree().create_timer(0.5).timeout
	await main.shot("bjg_%s_pence" % id)
	cl.set_level(0)
	await get_tree().create_timer(0.8).timeout


func _boss_run(base: Vector3) -> void:
	for id in ["isobu", "son_goku", "gyuki", "saiken"]:
		_reset(base)
		pl.cam_dist = 14.0
		var b = TailedBeast.new()
		b.setup(id)
		get_tree().current_scene.add_child(b)
		var p = base + Vector3.FORWARD * (b.height * 1.3)
		p.y = Game.ground_height(p.x, p.z)
		b.global_position = p
		b.home = p
		b.aggro = true
		b.facing = 0.0
		b.rig.rotation.y = 0.0
		await get_tree().create_timer(1.0).timeout
		var i = 0
		for t in BijuuArts.techs(id):
			b.facing = atan2(-(pl.global_position - b.global_position).x, -(pl.global_position - b.global_position).z)
			b.rig.rotation.y = b.facing
			BijuuArts.use(b, id, t["key"], {"s": clampf(b.height / 14.0, 2.0, 3.5), "dmg": 5.0, "from": b.rig.mouth_pos(), "aim": pl.global_position + Vector3.UP, "tgt": pl, "col": b.info["chakra"]})
			await get_tree().create_timer(0.8).timeout
			await main.shot("bjb_%s_%d_%s" % [id, i, t["key"]])
			pl.hp = pl.max_hp
			await get_tree().create_timer(1.2).timeout
			i += 1
		b.aggro = false
		b.queue_free()
		await get_tree().create_timer(0.5).timeout


func _enemy_run(base: Vector3) -> void:
	_reset(base)
	pl.cam_dist = 7.0
	for f in foes:
		if is_instance_valid(f):
			f.queue_free()
	foes.clear()
	var e = Enemy.new()
	var a = Enemy.archetype("jinchuriki", 3)
	a["respawn"] = false
	e.setup(a)
	get_tree().current_scene.add_child(e)
	var p = base + Vector3.FORWARD * 12.0
	p.y = Game.ground_height(p.x, p.z)
	e.global_position = p
	e.home = p
	await get_tree().create_timer(1.0).timeout
	for k in 3:
		e.ranged_cd = 0.0
		e.target = pl
		e._beast_tech(12.0)
		pl.hp = pl.max_hp
		await get_tree().create_timer(0.8).timeout
		await main.shot("bje_%d" % k)
		await get_tree().create_timer(1.5).timeout
