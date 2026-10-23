extends Node
## Oyuncu silah kını akışı: kınında başlar, [N] ile çekilir/sokulur, saldırınca anında çekilir, mühürde kına girer.
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.42
	await get_tree().create_timer(1.5).timeout
	var pl = main.player
	Game.profile["rank"] = 3
	Gear.grant(Game.profile, "katana", "sag")
	Gear.apply_look(Game.profile)
	pl.model.queue_free()
	pl.model = CharacterModel.new()
	pl.add_child(pl.model)
	pl.model.setup(pl._look_with_age())
	await get_tree().create_timer(0.5).timeout
	var ok = true
	var m: CharacterModel = pl.model
	print("WD has_weapon=", m.has_weapon(), " drawn=", m.drawn)
	ok = ok and m.has_weapon() and not m.drawn
	var cam: Camera3D = pl.cam
	var shot = func(n: String) -> void:
		pl.set_process(false)
		var c = pl.global_position + Vector3(0, 1.1, 0)
		var back = pl.model.global_transform.basis.z
		cam.global_position = c + back.rotated(Vector3.UP, 0.7) * 2.6 + Vector3(0, 0.3, 0)
		cam.look_at(c)
		await get_tree().process_frame
		await main.shot(n)
		pl.set_process(true)
	await shot.call("wd_0_kinda")
	pl.combat.toggle_weapon()
	await get_tree().create_timer(0.16).timeout
	await shot.call("wd_1_uzanma")
	await get_tree().create_timer(0.5).timeout
	print("WD after toggle drawn=", m.drawn, " in_hand=", m.weapons[0]["node"].get_parent() == m.weapons[0]["hand"])
	ok = ok and m.drawn and m.weapons[0]["node"].get_parent() == m.weapons[0]["hand"]
	await shot.call("wd_2_elde")
	pl.combat.toggle_weapon()
	await get_tree().create_timer(0.7).timeout
	print("WD after 2nd toggle drawn=", m.drawn, " profile=", Game.profile.get("weapon_drawn"))
	ok = ok and not m.drawn
	pl.combat.attack()
	await get_tree().process_frame
	print("WD after attack drawn=", m.drawn)
	ok = ok and m.drawn
	await get_tree().create_timer(0.8).timeout
	# model yeniden kurulsa da durum korunur
	pl.model.queue_free()
	pl.model = CharacterModel.new()
	pl.add_child(pl.model)
	pl.model.setup(pl._look_with_age())
	await get_tree().create_timer(0.3).timeout
	print("WD rebuilt drawn=", pl.model.drawn)
	ok = ok and pl.model.drawn
	pl.model.overlay.snap("seal", 1.0)
	await get_tree().create_timer(0.2).timeout
	var w0 = pl.model.weapons[0]
	print("WD seal stowed=", pl.model._stowed, " in_sheath=", w0["node"].get_parent() == w0["sheath"])
	ok = ok and w0["node"].get_parent() == w0["sheath"]
	await shot.call("wd_3_muhur")
	pl.model.overlay.snap("seal", 0.0)
	await get_tree().create_timer(0.2).timeout
	ok = ok and w0["node"].get_parent() == w0["hand"]
	print("WD RESULT ", "OK" if ok else "FAIL")
	get_tree().quit()
