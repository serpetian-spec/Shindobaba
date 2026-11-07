extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	Hud.close_dialog()
	var pr = Game.profile
	var pl = main.player
	var ey = pl.combat.modes.eyes
	# Senju düşmanı öldür, hücre al
	var a = ClanWorld.make_enemy("senju", 30, {"outfit": "rogue"})
	var e = Enemy.new()
	e.setup(a)
	main.actors.add_child(e)
	e.global_position = pl.global_position + Vector3(2, 0, 0)
	await get_tree().create_timer(0.3).timeout
	print("SD group=", e.is_in_group("senju_bearers"))
	e.take_hit({"dmg": 1e9, "kind": "heavy", "attacker": pl, "knock": 0.0})
	await get_tree().create_timer(1.0).timeout
	print("SD dead=", e.is_dead(), " cell_target=", ey.cell_target == e)
	if ey.cell_target:
		ey._take_cells(ey.cell_target)
	print("SD jar=", pr["flags"].get("senju_jar"), " opts=", EyeSurgery.options("black").map(func(o): return o["label"]))
	EyeSurgery._finish_cells("black")
	print("SD cells=", pr["flags"].get("senju_cells", false), " dna=", Eyes.has_senju_dna(pr))
	# Rinnegan: EMS + DNA + Güç 100, EMS açık
	Gear.grant(pr, "goz_ems", "sag_goz"); Gear.grant(pr, "goz_ems", "sol_goz"); Gear.apply_look(pr)
	pr["flags"]["senju_cells"] = true
	pr["level"] = 90
	ey.open_ms()
	pr["flags"]["rinne_xp"] = 899.0
	await get_tree().create_timer(4.5).timeout
	print("SD lv90 eye=", Gear.equipped(pr, "sag_goz").get("id"))
	pr["level"] = 100
	pr["flags"]["rinne_xp"] = 899.0
	if not ey.active: ey.open_ms()
	await get_tree().create_timer(4.5).timeout
	print("SD lv100 eye=", Gear.equipped(pr, "sag_goz").get("id"))
	get_tree().quit()
