extends Node
## Klan teknikleri + özel modlar + mühür örme testi.

var main: Node
var pl: Player
var log_lines: Array = []


func L(s: String) -> void:
	print("CLANTEST ", s)


func _enemy(offset: Vector3, kind := "rogue") -> Enemy:
	var e = Enemy.new()
	var a = Enemy.archetype(kind, 0)
	a["hp"] = 2000.0
	e.setup(a)
	main.actors.add_child(e)
	e.global_position = pl.global_position + offset
	e.home = e.global_position
	e.lose_target(999)
	e.state = "idle"
	return e


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.1, 0.1, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	pl = main.player
	Game.world.env.time_of_day = 0.45
	var v = Game.village("konoha")
	var base = Game.from_map(Vector2(v["x"] + 300, v["y"] + 140))
	pl.respawn(base)
	pl.yaw = 0.0
	pl.pitch = -10.0
	pl.cam_dist = 8.0
	Game.profile["level"] = 25
	Game.profile["rank"] = 2
	await _wait(1.0)
	var e = _enemy(Vector3(0, 0, -9))
	pl.combat.lock_target = e
	var shots = {"juuken_64": 0.6, "kaiten": 0.4, "kagemane": 0.5, "baika": 0.8, "nikudan": 0.6, "mushi_swarm": 1.2, "ninken": 1.5,
		"gatsuga": 0.4, "shintenshin": 0.6, "mokuton_spikes": 0.5, "mokuton_wall": 0.7, "hyoton_senbon": 0.15, "hyoton_spears": 0.3,
		"bone_bullets": 0.3, "bone_armor": 0.4, "chakra_chains": 0.4, "suika": 0.5, "water_gun": 0.1, "kage_kubi": 0.6}
	var clans = {"juuken_64": "hyuga", "kaiten": "hyuga", "kagemane": "nara", "kage_kubi": "nara", "baika": "akimichi", "nikudan": "akimichi",
		"mushi_swarm": "aburame", "ninken": "inuzuka", "gatsuga": "inuzuka", "shintenshin": "yamanaka", "mokuton_spikes": "senju",
		"mokuton_wall": "senju", "hyoton_senbon": "yuki", "hyoton_spears": "yuki", "bone_bullets": "kaguya", "bone_armor": "kaguya",
		"chakra_chains": "uzumaki", "suika": "hozuki", "water_gun": "hozuki"}
	for jid in shots.keys():
		if not is_instance_valid(e) or e.dead:
			e = _enemy(Vector3(0, 0, -9))
			pl.combat.lock_target = e
		Game.profile["clan"] = clans[jid]
		Game.profile["learned"] = []
		Progress.clan_unlocks(false)
		var learned = jid in Game.profile["learned"]
		pl.chakra = 999
		pl.combat.cooldowns.clear()
		pl.combat.action = ""
		var hp0 = e.hp
		Jutsu.execute(pl, jid, e)
		await _wait(shots[jid])
		await main.shot("k_" + jid)
		await _wait(0.8)
		L("%s learned=%s enemy_hp %d -> %d status=%s team=%s size=%.1f" % [jid, learned, hp0, e.hp if is_instance_valid(e) else -1,
			str(e.statuses) if is_instance_valid(e) else "-", e.team if is_instance_valid(e) else "-", pl.combat.modes.size])
		# geri al
		if pl.combat.modes.size != 1.0:
			pl.combat.modes.set_size(1.0, 0.0)
		pl.combat.action = ""
		pl.velocity = Vector3.ZERO
		pl.respawn(base)
		if is_instance_valid(e):
			e.global_position = base + Vector3(0, 0, -9)
			e.statuses.clear()
			e.guarding = false
			e.hp = 2000.0
			e.team = "enemy"
			e.lose_target(999)
			e.state = "idle"
	# ---- modlar
	var md: PlayerModes = pl.combat.modes
	Game.profile["clan"] = "uchiha"
	md.toggle_dojutsu()
	await _wait(0.5)
	await main.shot("m_sharingan")
	L("sharingan dojutsu=%s timescale=%.2f" % [md.dojutsu, Engine.time_scale])
	md.toggle_dojutsu()
	Game.profile["clan"] = "hyuga"
	md.toggle_dojutsu()
	await _wait(1.0)
	await main.shot("m_byakugan")
	L("byakugan markers=%d" % md.markers.size())
	md.toggle_dojutsu()
	Game.profile["clan"] = "none"
	md.next_gate(); md.next_gate(); md.next_gate()
	await _wait(0.6)
	await main.shot("m_gates")
	L("gates=%d melee=%.2f speed=%.2f" % [md.gates, Buffs.mod("melee"), Buffs.mod("speed")])
	md.next_gate()
	Game.profile["skills"].append("sage")
	md.toggle_sage()
	await _wait(1.8)
	await main.shot("m_sage")
	L("sage=%s jutsu_mult=%.2f" % [md.sage, Buffs.mod("jutsu")])
	md._end_sage()
	Game.profile["skills"].append("jinchuriki")
	md.beast_key()
	await _wait(0.5)
	pl.chakra = 999
	md.beast_key()
	await _wait(0.5)
	await main.shot("m_beast")
	L("beast=%s cd=%.1f" % [md.beast, md.beast_cd])
	md._end_beast()
	# ---- mühür örme: Ateş topu (Mi Hitsuji Saru I Uma Tora) -> keşif
	Game.profile["clan"] = "none"
	Game.profile["elements"] = ["katon"]
	Game.profile["learned"].erase("katon_goukakyuu")
	var keymap = {"Ne": KEY_1, "Ushi": KEY_2, "Tora": KEY_3, "U": KEY_4, "Tatsu": KEY_5, "Mi": KEY_6, "Uma": KEY_7, "Hitsuji": KEY_8,
		"Saru": KEY_9, "Tori": KEY_0, "Inu": KEY_MINUS, "I": KEY_EQUAL}
	L("seals order=%s" % str(Data.seals))
	for pass_i in 2:
		_press_action("seal_mode", true)
		for s in Data.jutsu["katon_goukakyuu"]["seals"]:
			var ev = InputEventKey.new()
			ev.physical_keycode = keymap[s]
			ev.pressed = true
			md.handle_input(ev)
		_press_action("seal_mode", false)
		await _wait(0.6)
		L("seal pass %d learned=%s" % [pass_i, "katon_goukakyuu" in Game.profile["learned"]])
		if pass_i == 1:
			await main.shot("m_seal_cast")
	get_tree().quit()


func _press_action(a: String, pressed: bool) -> void:
	var ev = InputEventAction.new()
	ev.action = a
	ev.pressed = pressed
	pl.combat.modes.handle_input(ev)


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout
