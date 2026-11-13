extends Node
## Susanoo silah özel saldırıları: her silahta kukla hasar alıyor mu, hata var mı
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "dağınık", "hair": Color(0.08, 0.08, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.1, 0.1, 0.1)}
	main._start_new_game()
	var pl = main.player
	var pr = Game.profile
	Gear.grant(pr, "goz_ems", "sag_goz", null, null, {"lvl": 3, "origin": "dogustan"})
	Gear.grant(pr, "goz_ems", "sol_goz", null, null, {"lvl": 3, "origin": "dogustan"})
	Gear.apply_look(pr)
	pl.rebuild_model()
	pl.chakra = 9999999
	pl.max_chakra = 9999999
	Susanoo.config(pr)["mastery"] = 99999.0
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.5).timeout
	Hud.close_dialog()
	var eyes = pl.combat.modes.eyes
	eyes.toggle()
	await get_tree().create_timer(0.4).timeout
	for wp in (OS.get_environment("WPS").split(",") if OS.get_environment("WPS") != "" else Susanoo.WEAPONS.keys()):
		Susanoo.config(pr).merge({"weapon": wp, "armor": randi() % Susanoo.ARMORS.size(), "face": randi() % Susanoo.FACES.size(), "tier_pref": 4}, true)
		eyes._start_susanoo()
		await get_tree().create_timer(0.8).timeout
		var f = pl.face_dir()
		var ar = Enemy.archetype("rogue", 0)
		ar["respawn"] = false
		var e = Enemy.new()
		e.setup(ar)
		main.add_child(e)
		var ep = pl.global_position + f * 9.0
		ep.y = Game.ground_height(ep.x, ep.z)
		e.global_position = ep
		e.home = ep
		e.set_process(false)
		e.set_physics_process(false)
		e.max_hp = 100000.0
		e.hp = 100000.0
		var hp0 = e.hp if e else -1.0
		eyes.susanoo_node.special(pl, f)
		await get_tree().create_timer(0.8).timeout
		var held = 0
		for w in eyes.susanoo_node.body.weapons:
			if w.get("node") != null:
				held += 1
		print("SILAH %s: eldeki model %d, hedef can %s -> %s" % [wp, held, hp0, (e.hp if e and is_instance_valid(e) else "oldu")])
		if e and is_instance_valid(e):
			e.queue_free()
		eyes._end_susanoo()
		await get_tree().create_timer(0.4).timeout
	Menus.ninja_menu(main, "wardrobe")
	await get_tree().create_timer(1.0).timeout
	print("SILAH menu acildi")
	get_tree().quit()
