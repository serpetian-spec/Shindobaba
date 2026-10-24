extends Node
## Mükemmel Susanoo teknikleri (slottan)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "dağınık", "hair": Color(0.08, 0.08, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.1, 0.1, 0.1)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var pr = Game.profile
	Gear.grant(pr, "goz_ems", "sag_goz", null, null, {"lvl": 3, "origin": "dogustan"})
	Gear.grant(pr, "goz_ems", "sol_goz", null, null, {"lvl": 3, "origin": "dogustan"})
	Gear.apply_look(pr)
	pl.rebuild_model()
	pl.chakra = 99999
	pl.max_chakra = 99999
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.5).timeout
	var eyes = pl.combat.modes.eyes
	eyes.toggle()
	Susanoo.config(pr)["tier_pref"] = 5
	eyes._start_susanoo()
	await get_tree().create_timer(1.0).timeout
	print("SUSIDS %s" % [SpecialSlots.refresh(pr)])
	pl.set_process(false)
	var H = Susanoo.TIER_HEIGHT[5]
	var fwd = pl.face_dir()
	var e = Enemy.new()
	var a = Enemy.archetype("bandit", 0)
	a["hp"] = 999999.0
	a["respawn"] = false
	e.setup(a)
	main.add_child(e)
	var ep = pl.global_position + fwd * 70.0
	ep.y = Game.ground_height(ep.x, ep.z)
	e.global_position = ep
	e.set_physics_process(false)
	pl.combat.lock_target = e
	for i in 3:
		pl.combat.begin_cast("susanoo_t%d" % i)
		await get_tree().create_timer(0.75 if i != 2 else 1.1).timeout
		pl.cam.global_position = pl.global_position + fwd.cross(Vector3.UP) * H * 1.6 + Vector3.UP * H * 0.5 - fwd * H * 0.3
		pl.cam.look_at(pl.global_position + fwd * 40.0 + Vector3.UP * H * 0.3)
		await get_tree().create_timer(0.05).timeout
		await main.shot("sus_tech%d" % i)
		await get_tree().create_timer(1.5).timeout
	get_tree().quit()
