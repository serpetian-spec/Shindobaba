extends Node
## Sis'in Yedi Kılıç Ustası: dünya durumu, Bingo girdisi, kılıçla doğma, kılıca özgü teknik, yenilince kılıcın oyuncuya geçmesi
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.5).timeout
	pl.max_hp = 999999.0
	pl.hp = pl.max_hp
	var s = Swordsmen.state()
	for id in s:
		print("STATE %s %s %s" % [id, s[id]["state"], s[id].get("name", "")])
	var only = ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
	for id in (MistSwords.IDS if only == "" else [only]):
		s[id] = {"state": "rogue", "name": Swordsmen._name(), "level": 50}
		Missions.add_swordsman(id, s[id])
		var entry = {}
		for x in Missions._bingo()["list"]:
			if x["status"] == "alive" and String(x.get("mist_sword", "")) == id:
				entry = x
		var at = pl.global_position + pl.face_dir() * 9.0
		var am = Game.to_map(at)
		entry["hide"] = [am.x, am.y]
		entry["escorts"] = 0
		Missions._bb_spawn(entry, at)
		await get_tree().create_timer(0.3).timeout
		var boss: Enemy = Missions._bb_spawned[int(entry["id"])][0]
		boss.set_physics_process(false)
		boss.model.play("idle", 0.0)
		await get_tree().create_timer(0.3).timeout
		pl.set_process(false)
		var f0 = boss.face_dir()
		pl.cam.global_position = boss.global_position + f0 * 3.4 + Vector3.UP * 1.4 + f0.cross(Vector3.UP) * 0.8
		pl.cam.look_at(boss.global_position + Vector3.UP * 1.0)
		await main.shot("pose_" + id)
		pl.set_process(true)
		boss.set_physics_process(true)
		boss.set_meta("ms_cd", 0.5)
		boss.target = pl
		boss.state = "chase"
		var c0 = float(boss.get_meta("ms_cd"))
		var used = false
		for k in 16:
			await get_tree().create_timer(0.25).timeout
			if float(boss.get_meta("ms_cd", 0.0)) > 2.0:
				used = true
			if k == 5:
				pl.set_process(false)
				var fd = boss.face_dir()
				pl.cam.global_position = boss.global_position + fd * 3.6 + fd.cross(Vector3.UP) * 1.6 + Vector3.UP * 1.7
				pl.cam.look_at(boss.global_position + Vector3.UP * 1.1)
				await main.shot("swordsman_" + id)
				pl.set_process(true)
		print("SWORD %s name=%s weapon=%s tech_used=%s plhp_lost=%d" % [id, boss.display_name, boss.model.look.get("weapon_r", ""), used, int(pl.max_hp - pl.hp)])
		pl.hp = pl.max_hp
		boss.hp = 1.0
		boss.sub_cd = 99.0
		boss.guard_cd = 99.0
		boss.take_hit({"dmg": 50.0, "kind": "heavy", "attacker": pl, "dir": Vector3.FORWARD})
		await get_tree().create_timer(0.8).timeout
		print("CLAIM %s player_has=%s state=%s" % [id, Swordsmen.player_has(id), s[id]["state"]])
		for n in Missions._bb_spawned.get(int(entry["id"]), []):
			if is_instance_valid(n):
				n.queue_free()
		Missions._bb_spawned.erase(int(entry["id"]))
		await get_tree().create_timer(0.5).timeout
	get_tree().quit()
