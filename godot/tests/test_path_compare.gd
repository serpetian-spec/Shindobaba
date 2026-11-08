extends Node
## Yol jutsusu anime karşılaştırması: CMP_IDS (virgüllü) her jutsu için 3 kare (hazırlık, salınım+0.4, salınım+1.2)
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _enemy(pos: Vector3) -> Enemy:
	var e := Enemy.new()
	e.setup(Enemy.archetype("rogue", 1))
	main.actors.add_child(e)
	e.global_position = pos
	e.home = pos
	e.lose_target(999)
	e.state = "idle"
	e.max_hp = 1e9
	e.hp = 1e9
	e.set_physics_process(false)
	return e

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "f", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.15), "top": Color(0.85, 0.55, 0.6), "pants": Color(0.15, 0.3, 0.3), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	Game.world.env.weather = "açık"
	var vs = Game.village("suna")
	var base = Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"]))
	pl.respawn(base)
	pl.max_chakra = 1e9
	pl.chakra = 1e9
	Game.profile["level"] = 60
	Game.set_meta("sandbox", true)
	await _w(1.5)
	Hud.close_dialog()
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	var plan = {}
	for id in OS.get_environment("CMP_IDS").split(",", false):
		plan[id] = [-0.25, 0.4, 1.2]
		if OS.get_environment("CMP_T") != "":
			plan[id] = Array(OS.get_environment("CMP_T").split(",")).map(func(x): return float(x))
	var n = 0
	for id in plan:
		var b0 = base + Vector3(60.0 * n, 0, 0)
		n += 1
		b0.y = Game.ground_height(b0.x, b0.z)
		pl.global_position = b0
		pl.facing = 0.0
		pl.yaw = 0.0
		var fwd = Vector3(0, 0, -1)
		var side = Vector3(1, 0, 0)
		var e = _enemy(b0 + fwd * (float(OS.get_environment("CMP_DIST")) if OS.get_environment("CMP_DIST") != "" else 6.5))
		Game.profile["learned"].append(id)
		pl.combat.cooldowns.erase(id)
		await _w(0.4)
		var nd = String(Data.jutsu.get(id, {}).get("need", ""))
		if nd.begins_with("weapon:"):
			var wid = nd.substr(7)
			Gear.grant(Game.profile, wid, String(Gear.item(wid).get("slot", "silah")))
			if pl.has_method("refresh_look"):
				pl.refresh_look()
		if nd == "juin2" or nd == "juin1":
			Buffs.add(nd, 30.0, {})
		var md = pl.combat.get("modes")
		if md and md.get("sage") != null:
			md.sage = true
		pl.combat.begin_cast(id)
		var rt = pl.combat.cast_time
		print("ANM %s release_t=%.2f" % [id, rt])
		var tsum = 0.0
		if rt < 0.3:
			plan[id][0] = 0.15
		for k in plan[id].size():
			var at = rt + float(plan[id][k])
			await _w(maxf(0.05, at - tsum))
			tsum = at
			if OS.get_environment("CMP_VIEW") == "back":
				cc.global_position = b0 - fwd * 3.6 + side * 1.2 + Vector3.UP * 2.2
				cc.look_at(b0 + fwd * 2.0 + Vector3.UP * 1.3)
			elif OS.get_environment("CMP_VIEW") == "front":
				cc.global_position = pl.global_position + fwd * 2.2 + side * 0.6 + Vector3.UP * 1.6
				cc.look_at(pl.global_position + Vector3.UP * 1.3)
			elif OS.get_environment("CMP_VIEW") == "wide":
				cc.global_position = b0 + side * 60.0 + fwd * 30.0 + Vector3.UP * 30.0
				cc.look_at(b0 - fwd * 30.0 + Vector3.UP * 40.0)
			elif false:
				cc.global_position = b0 + side * 20.0 + fwd * 3.0 + Vector3.UP * 7.0
				cc.look_at(b0 + fwd * 3.0 + Vector3.UP * 8.0)
			elif false:
				cc.global_position = b0 + side * 9.0 - fwd * 2.0 + Vector3.UP * 4.0
				cc.look_at(b0 + fwd * 4.0 + Vector3.UP * 5.0)
			else:
				cc.global_position = b0 + side * 5.0 - fwd * 0.5 + Vector3.UP * 2.0
				cc.look_at(b0 + fwd * 3.2 + Vector3.UP * 1.3)
			cc.current = true
			await main.shot("cmp_%s_%d" % [id, k])
		pl.cam.current = true
		await _w(2.5)
		e.queue_free()
	get_tree().quit()
