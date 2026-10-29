extends Node
## Mangekyō ile boyun eğdirilen canavar: çağrılır, düşmana saldırır, oyuncuya değil
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.0).timeout
	Gear.grant(Game.profile, "goz_mangekyo", "sag_goz", null, null, {"lvl": 3})
	Gear.grant(Game.profile, "goz_mangekyo", "sol_goz", null, null, {"lvl": 3})
	Game.profile["beast_ms"] = ["matatabi"]
	SpecialSlots.refresh(Game.profile)
	pl.combat.modes.eyes.toggle()
	await get_tree().create_timer(1.5).timeout
	var e = Enemy.new()
	e.setup(Enemy.archetype("rogue", 0))
	e.max_hp = 5000.0; e.hp = 5000.0
	get_tree().current_scene.add_child(e)
	e.global_position = pl.global_position + pl.face_dir() * 30.0
	e.home = e.global_position
	pl.max_hp = 99999.0; pl.hp = 99999.0
	var ok = SpecialSlots.cast(pl, SpecialSlots.MS_BIJUU_ID)
	await get_tree().create_timer(8.0).timeout
	var b = null
	for n in get_tree().get_nodes_in_group("fighters"):
		if n is TailedBeast:
			b = n
	print("MB summoned=%s ally=%s team=%s enemy_hp=%.0f player_hp=%.0f/99999" % [ok, b != null and b.ally_owner == pl, b.team if b else "", e.hp, pl.hp])
	get_tree().quit()
