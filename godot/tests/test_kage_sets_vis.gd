extends Node
## Kage ve ANBU setleri: her biri oyuncuya giydirilir, önden kare
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	var vs = Game.village("suna")
	var base = Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"]))
	pl.respawn(base)
	await _w(1.5)
	Hud.close_dialog()
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	var pr = Game.profile
	var stock = Gear.shop_stock("c", "konoha")
	print("KS in_stock=", Gear.KAGE_SETS.all(func(x): return x in stock), " anbu=", Gear.ANBU_SETS.all(func(x): return x in stock), " hat=", "kage_sapkasi" in stock)
	for sid in Gear.KAGE_SETS + Gear.ANBU_SETS:
		Gear.grant(pr, sid, "set")
		if sid in Gear.KAGE_SETS:
			Gear.grant(pr, "kage_sapkasi", "kafa")
		else:
			pr["equip"].erase("kafa")
			Gear.grant(pr, "anbu_kurt", "kafa")
		Gear.apply_look(pr)
		pl.rebuild_model()
		await _w(0.6)
		pl.facing = 0.0
		if pl.model:
			pl.model.rotation.y = 0.0
		cc.global_position = pl.global_position + Vector3(1.2, 1.4, -2.6)
		cc.look_at(pl.global_position + Vector3(0, 1.0, 0))
		cc.current = true
		await _w(0.3)
		await main.shot("ks_%s" % sid)
	get_tree().quit()
