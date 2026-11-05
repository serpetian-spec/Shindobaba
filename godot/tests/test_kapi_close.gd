extends Node
## Klan jutsuları testi: ClanJutsu'nun uyguladığı her jutsu sırayla atılır (hata/çökme yok mu),
## seçilmiş olanların etki anında ekran görüntüsü alınır, uçuş kipi (Keijūgan, kum bulutu) denenir.

var main: Node
var IDS = []


func _wait(t: float) -> void:
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
	return e


func _clear() -> void:
	for n in get_tree().current_scene.get_children():
		if n is Projectile:
			n.queue_free()
	for f in get_tree().get_nodes_in_group("fighters"):
		if f is ShadowClone or f is Summon or f is ClanConstruct:
			f.queue_free()


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uzumaki", "element": "katon", "hair_style": "diken",
		"hair": Color(0.7, 0.2, 0.15), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	Game.world.env.weather = "açık"
	var v := Game.village("konoha")
	var al = Game.world_info["landmarks"].filter(func(l): return l.get("id", "") == "arena_earth")[0]
	var base := Game.from_map(Vector2(al["x"], al["y"]))
	var vs = Game.village("suna")
	base = Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"]))
	pl.respawn(base)
	pl.max_hp = 1e9
	pl.hp = 1e9
	pl.max_chakra = 1e9
	pl.chakra = 1e9
	pl.yaw = 0.0
	pl.pitch = -12.0
	pl.cam_dist = 10.0
	var pr = Game.profile
	pr["level"] = 60
	pr["rank"] = 4
	await _wait(1.5)
	var fwd: Vector3 = pl.cam_forward()
	fwd.y = 0
	fwd = fwd.normalized()
	var side = fwd.cross(Vector3.UP)
	var foes = [_enemy(base + fwd * 8.0), _enemy(base + fwd * 12.0 + side * 3.0), _enemy(base + fwd * 10.0 - side * 3.5)]
	await _wait(0.5)

	var f0 = foes[0]
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	for f in foes:
		f.arch["clan"] = ""
	pl.rebuild_model()
	await _wait(0.5)
	Game.set_meta("sandbox", true)
	for f in foes:
		f.global_position = base + fwd * 60.0 + side * 30.0
		f.set_physics_process(false)
	var plan = {"hirudora": [0.6, 0.75], "asakujaku": [0.45]}
	for id in plan.keys():
		pr["learned"].append(id)
		pl.combat.cooldowns.erase(id)
		pl.combat.action = ""
		pl.global_position = base
		pl.yaw = rad_to_deg(atan2(-fwd.x, -fwd.z))
		pl.facing = atan2(-fwd.x, -fwd.z)
		f0.global_position = base + fwd * 5.0
		f0.hp = 1e9
		f0.max_hp = 1e9
		await _wait(0.4)
		Jutsu.execute(pl, id, f0)
		var tsum = 0.0
		for k in plan[id].size():
			await _wait(float(plan[id][k]) - tsum)
			tsum = float(plan[id][k])
			var prj = get_tree().current_scene.get_children().filter(func(n): return n is Projectile)
			var fp = prj[0].global_position if prj.size() > 0 else pl.global_position + fwd * 3.0 + Vector3.UP * 1.5
			if id == "asakujaku":
				cc.global_position = pl.global_position - fwd * 6.0 + Vector3.UP * 2.5
				cc.look_at(pl.global_position + Vector3.UP * 1.5)
			else:
				cc.global_position = fp + fwd * 7.0 + side * 3.5 + Vector3.UP * 1.0
				cc.look_at(fp)
			cc.current = true
			Hud.close_dialog()
			await main.shot("kapi2_%s_%d" % [id, k])
		pl.cam.current = true
		await _wait(2.5)
		_clear()
	get_tree().quit()
