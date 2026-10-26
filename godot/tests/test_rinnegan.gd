extends Node
## Rinnegan: (A) efsanevi Rinnegan kaçağı — teknikleri, yenilince gözlerin alınması; (B) uyanış zinciri — EMS + Sv.70 → görev → Rinnegan
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.5).timeout
	pl.max_hp = 999999.0
	pl.hp = pl.max_hp
	# (A)
	var L = {}
	for x in ClanWorld.LEGENDS:
		if x["key"] == "rinkai":
			L = x
	var entry = ClanWorld._legend_entry(L, 9001)
	var at = pl.global_position + pl.face_dir() * 6.0
	var am = Game.to_map(at)
	entry["hide"] = [am.x, am.y]
	entry["escorts"] = 0
	Missions._bingo()["list"].append(entry)
	Missions._bb_spawn(entry, at)
	await get_tree().create_timer(0.3).timeout
	var boss: Enemy = Missions._bb_spawned[9001][0]
	print("RINNE boss=%s eyes=%s lv=%d" % [boss.display_name, boss.get_meta("eyes", {}), boss.level])
	boss.target = pl
	boss.state = "chase"
	boss.set_meta("ea_cd", 0.3)
	var used = []
	for k in 40:
		await get_tree().create_timer(0.2).timeout
		if float(boss.get_meta("ea_cd", 0.0)) > 5.0 and not "art" in used:
			used.append("art")
		if k == 6:
			pl.set_process(false)
			var cam = Camera3D.new()
			main.add_child(cam)
			cam.global_position = boss.global_position + boss.face_dir() * 1.3 + Vector3.UP * 1.6
			cam.look_at(boss.global_position + Vector3.UP * 1.55)
			cam.current = true
			await main.shot("rinne_enemy_face")
			cam.queue_free()
			pl.set_process(true)
	print("RINNE enemy_arts_used=%s" % used)
	boss.hp = 1.0
	boss.sub_cd = 99.0
	boss.guard_cd = 99.0
	boss.take_hit({"dmg": 99.0, "kind": "heavy", "attacker": pl, "dir": Vector3.FORWARD})
	await get_tree().create_timer(0.5).timeout
	pl.combat.modes.eyes._steal(boss)
	var n = 0
	for g in Game.profile["gear"]:
		if g["id"] == "goz_rinnegan":
			n += 1
	print("RINNE stolen_rinnegan=%d" % n)
	# (B)
	Game.profile["level"] = 72
	for g in Game.profile["gear"].duplicate():
		if g["id"] == "goz_rinnegan":
			Game.profile["gear"].erase(g)
	Gear.grant(Game.profile, "goz_ems", "sag_goz")
	Gear.grant(Game.profile, "goz_ems", "sol_goz")
	Game.profile["active_mission"] = {}
	Progress._check_rinnegan_path(99.0)
	print("RINNE offer=%s dialog=%s" % [Game.profile["flags"].get("rinne_offer", false), Hud.dialog_open()])
	Hud.close_dialog()
	Progress.rinnegan_done({}, true)
	await get_tree().create_timer(0.5).timeout
	print("RINNE awakened r=%s l=%s can_learn_shinra='%s'" % [Gear.equipped(Game.profile, "sag_goz").get("id", ""), Gear.equipped(Game.profile, "sol_goz").get("id", ""), Progress.can_learn("shinra_tensei")])
	pl.set_process(false)
	var cam2 = Camera3D.new()
	main.add_child(cam2)
	cam2.global_position = pl.global_position + pl.face_dir() * 1.0 + Vector3.UP * 1.62
	cam2.look_at(pl.global_position + Vector3.UP * 1.58)
	cam2.current = true
	await get_tree().create_timer(0.3).timeout
	await main.shot("rinne_player_face")
	get_tree().quit()
