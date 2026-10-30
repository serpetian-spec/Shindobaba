extends Node
## Animasyon takılması: kılıçla vururken jutsu, jutsu bitişinde vuruş; düşman mühür yaparken vurulursa
var main: Node


func _poses(m) -> String:
	var out = []
	for k in m.overlay.targets:
		if float(m.overlay.targets[k]) > 0.01 or float(m.overlay.weights.get(k, 0.0)) > 0.05:
			out.append("%s=%.2f/%.2f" % [k, float(m.overlay.targets[k]), float(m.overlay.weights.get(k, 0.0))])
	return "anim=%s poses=%s" % [m.current, ", ".join(out)]


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	Game.profile["level"] = 30
	Gear.grant(Game.profile, "katana", "sag")
	Gear.apply_look(Game.profile)
	pl.rebuild_model()
	await get_tree().create_timer(2.0).timeout
	Game.profile["weapon_drawn"] = true
	pl.model.set_drawn(true, false)
	Game.profile["jutsu"] = ["katon_goukakyuu", "katon_housenka"]
	pl.chakra = 999.0
	var e = Enemy.new()
	var a = Enemy.archetype("rogue", 0)
	a["hp"] = 99999.0
	e.setup(a)
	get_tree().current_scene.add_child(e)
	e.global_position = pl.global_position + pl.face_dir() * 3.0
	e.home = e.global_position
	pl.combat.lock_target = e
	# 1) vuruş ortasında jutsu
	pl.combat.attack()
	await get_tree().create_timer(0.15).timeout
	pl.combat.begin_cast("katon_housenka")
	await get_tree().create_timer(0.1).timeout
	pl.combat.attack()
	for k in 6:
		await get_tree().create_timer(0.25).timeout
		print("STUCK seq1 t=", k, " action=", pl.combat.action, " ", _poses(pl.model))
	# 2) jutsu salındıktan hemen sonra vuruş
	pl.combat.cooldowns.clear()
	pl.combat.begin_cast("katon_goukakyuu")
	for k in 40:
		await get_tree().process_frame
		if pl.combat.action == "":
			break
	pl.combat.attack()
	await get_tree().create_timer(0.1).timeout
	pl.combat.attack()
	await get_tree().create_timer(2.5).timeout
	print("STUCK seq2 settled action=", pl.combat.action, " ", _poses(pl.model))
	# 3) düşman mühür yaparken vurulur
	e.set_meta("cast_id", "katon_goukakyuu")
	e.state = "cast"
	e.state_t = 0.0
	CastAnim.play(e, "katon_goukakyuu", 0.55)
	e.model.overlay.set_pose("seal", 1.0)
	await get_tree().create_timer(0.15).timeout
	e.take_hit({"dmg": 5.0, "attacker": pl, "kind": "light", "dir": Vector3.FORWARD})
	await get_tree().create_timer(2.0).timeout
	print("STUCK enemy settled state=", e.state, " ", _poses(e.model))
	get_tree().quit()
