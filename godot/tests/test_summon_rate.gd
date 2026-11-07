extends Node
## Çağrı vuruş sıklığı + binerken spam engeli
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	pl.max_hp = 1e9; pl.hp = 1e9; pl.max_chakra = 1e6; pl.chakra = 1e6
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(1.0)
	Contracts.sign("kurbağa")
	Hud.close_dialog()
	Jutsu.execute(pl, "kuchiyose", null)
	await _w(1.5)
	var sm = get_tree().get_nodes_in_group("fighters").filter(func(f): return f is Summon)
	print("SUM count=%d" % sm.size())
	if sm.is_empty():
		get_tree().quit()
		return
	var s: Summon = sm[0]
	var e = Enemy.new()
	var a = Enemy.archetype("rogue", 0)
	a["hp"] = 1e7
	a["respawn"] = false
	e.setup(a)
	get_tree().current_scene.add_child(e)
	e.global_position = s.global_position + s.face_dir() * 3.0
	e.home = e.global_position
	e.set_physics_process(false)
	var hp0 = e.hp
	var n = 0
	var last_cd = s.cd
	for k in 100:
		await _w(0.1)
		if s.cd > last_cd + 0.5:
			n += 1
		last_cd = s.cd
	print("SUM auto 10s: attacks=%d dmg=%.0f height=%.1f" % [n, hp0 - e.hp, s.height])
	# binerken spam: 10 hızlı saldırı tıkı
	s.def = s.def.duplicate()
	s.def["mount"] = true
	s.mounted = true
	pl.set_meta("riding", s)
	await _w(0.2)
	s.cd = 0.0
	var hp1 = e.hp
	var calls = 0
	for k in 10:
		var ev = InputEventAction.new()
		ev.action = "attack"
		ev.pressed = true
		var before = s.cd
		s._unhandled_input(ev) if s.has_method("_unhandled_input") else s._input(ev)
		if s.cd > before + 0.1:
			calls += 1
		await _w(0.05)
	print("SUM mounted 10 clicks in 0.5s -> attacks=%d" % calls)
	get_tree().quit()
