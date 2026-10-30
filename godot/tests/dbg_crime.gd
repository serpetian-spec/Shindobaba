extends Node
## Suç sistemi + dinamik Kage + İlişkiler sekmesi
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	Game.profile["rank"] = 2
	Game.profile["level"] = 30
	var v = ClanResident.new()
	v.clan = "uchiha"
	v.vid = "konoha"
	v.given = "Uchiha Riku"
	v.display_override = v.given
	v.role = "nurse"
	v.look_extra = ClanWorld.clan_look("uchiha", "genin", "konoha", false, "teen")
	v.eye_kind = 1
	v.eye_lvl = 2
	main.actors.add_child(v)
	v.global_position = pl.global_position + Vector3(3, 0, 0)
	await get_tree().create_timer(0.5).timeout
	Friends._meet(v)
	Friends.add_bond(String(v.get_meta("friend_id")), 30)
	Menus.clear()
	print("CR opts=", Crime.attack_option(v).map(func(o): return o["label"]))
	var c: Crime = Crime.inst()
	c.attack(v)
	await get_tree().create_timer(0.6).timeout
	var vc = c.victims[0]
	var e = vc["node"]
	print("CR enemy=", e.name, " eyes=", e.get_meta("eyes", {}), " heat=", Crime.heat())
	e.take_hit({"dmg": 99999.0, "knock": 1.0, "kind": "heavy", "dir": Vector3.FORWARD, "element": ""})
	await get_tree().create_timer(1.5).timeout
	print("CR after kill heat=", Crime.heat(), " rogue=", Orgs.is_rogue(), " friend status=", Friends.all()[vc["fid"]]["status"])
	var ey = pl.combat.modes.eyes
	pl.global_position = e.global_position + Vector3(1, 0, 0)
	await get_tree().create_timer(1.0).timeout
	print("CR steal_target=", ey.steal_target != null)
	if is_instance_valid(e):
		ey._steal(e)
	print("CR jars=", Game.profile["gear"].filter(func(g): return String(g["id"]).begins_with("goz")).size(), " rogue=", Orgs.is_rogue())
	Kage.succeed("suna")
	Kage.succeed("kumo")
	print("CR kage suna=", Kage.kage_name("suna"), " kumo=", Kage.kage_name("kumo"), " persona=", Kage.kage_persona("suna"))
	Menus.clear()
	Menus.ninja_menu(main, "relations")
	await get_tree().create_timer(1.0).timeout
	await main.shot("relations")
	get_tree().quit()
