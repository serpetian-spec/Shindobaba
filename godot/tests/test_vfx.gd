extends Node
## Jutsu efekt vitrini: her element uçuşta + çarpmada, Henge önce/sonra (yürürken), yanma ve tek seferlik aura sönüyor mu.
var main: Node
var pl: Player
var e: Node3D
var base: Vector3


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _enemy() -> void:
	if is_instance_valid(e) and not e.is_dead():
		e.hp = e.max_hp
		e.global_position = base + Vector3(0, 0, -11)
		return
	e = Enemy.new()
	e.setup(Enemy.archetype("rogue", 1))
	main.actors.add_child(e)
	e.global_position = base + Vector3(0, 0, -11)
	e.home = e.global_position
	e.max_hp = 99999.0
	e.hp = 99999.0
	e.lose_target(999)
	e.state = "idle"


func _cast(jid: String, mid: float, imp: float, tag: String) -> void:
	_enemy()
	pl.respawn(base)
	pl.facing = 0.0
	pl.chakra = 999
	pl.combat.cooldowns.clear()
	pl.combat.lock_target = e
	if not jid in Game.profile["learned"]:
		Game.profile["learned"].append(jid)
	pl.combat.begin_cast(jid)
	await _wait(mid)
	await main.shot("v_%s_a" % tag)
	await _wait(imp)
	await main.shot("v_%s_b" % tag)
	await _wait(1.2)


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.08, 0.08, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	Hud.show_game_hud(false)
	pl = main.player
	Game.world.env.time_of_day = 0.45
	Game.profile["elements"] = ["katon", "suiton", "fuuton", "doton", "raiton"]
	var v = Game.village("konoha")
	base = Game.from_map(Vector2(v["x"] + 300, v["y"] + 140))
	pl.respawn(base)
	pl.yaw = 62.0
	pl.pitch = -8.0
	pl.cam_dist = 9.0
	await _wait(1.5)
	await _cast("katon_goukakyuu", 0.55, 0.35, "katon")
	await _cast("katon_housenka", 0.5, 0.35, "housenka")
	await _cast("suiton_suiryuudan", 0.9, 0.7, "suiton")
	await _cast("suiton_suikoudan", 0.45, 0.3, "suikoudan")
	await _cast("fuuton_daitoppa", 0.45, 0.25, "fuuton")
	await _cast("fuuton_shinkuu", 0.45, 0.2, "shinkuu")
	await _cast("doton_doryuheki", 0.5, 0.3, "doton")
	await _cast("doton_doryuusou", 0.5, 0.25, "doryuusou")
	await _cast("raiton_chidori", 0.5, 0.45, "chidori")
	await _cast("rasengan", 0.55, 0.45, "rasengan")
	# Henge: önce / sonra koşarken
	pl.respawn(base)
	pl.combat.cooldowns.clear()
	pl.yaw = 30.0
	pl.cam_dist = 5.0
	await _wait(0.5)
	await main.shot("v_henge_0")
	Jutsu.j_henge(pl, null)
	await _wait(0.8)
	Input.action_press("forward")
	await _wait(1.0)
	await main.shot("v_henge_1_kosarken")
	var d = pl.get_node_or_null("Disguise")
	print("HENGE disguise=", d != null, " model_visible=", pl.model.visible, " disguise_anim=", d.current if d else "-", " player_anim=", pl.model.current,
		" disguise_rot=", d.rotation.y if d else 0.0, " model_rot=", pl.model.rotation.y)
	Input.action_release("forward")
	pl.combat.attack()
	await _wait(0.6)
	print("HENGE after attack: disguise=", pl.get_node_or_null("Disguise") != null and not pl.get_node("Disguise").is_queued_for_deletion(), " model_visible=", pl.model.visible, " buff=", Buffs.has("henge"))
	await main.shot("v_henge_2_bitti")
	# yanma + tek seferlik aura
	_enemy()
	e.apply_status("burn", 2.0)
	FX.aura(pl, Color(1, 0.7, 0.3), 0.8)
	await _wait(0.8)
	await main.shot("v_yanma_0")
	await _wait(3.5)
	var n = 0
	for c in pl.get_children():
		if c is GPUParticles3D:
			n += 1
	print("BURN statuses=", e.statuses, " player_aura_particles=", n)
	await main.shot("v_yanma_1_bitti")
	get_tree().quit()
