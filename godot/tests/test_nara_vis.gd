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
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "nara", "element": "katon", "hair_style": "diken",
		"hair": Color(0.9, 0.9, 0.92), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
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
	Game.world.env.time_of_day = 0.3
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	var IDS2 = ["kage_kubi"]
	for f in foes:
		f.arch["clan"] = ""
	for id in IDS2:
		pl.global_position = base
		pl.max_chakra = 1e9
		pl.chakra = 1e9
		for i in foes.size():
			foes[i].global_position = base + [fwd * 8.0, fwd * 9.0 + side * 3.0, fwd * 8.5 - side * 3.0][i]
			foes[i].statuses.clear()
		await _wait(0.3)
		Jutsu.execute(pl, id, f0)
		await _wait(1.1)
		for kk in 2:
			var fr = f0.face_dir()
			var vv = [fr * 1.2 + Vector3.UP * 1.5 + fr.cross(Vector3.UP) * 0.3, fr * 0.9 + fr.cross(Vector3.UP) * 1.0 + Vector3.UP * 1.6][kk]
			cc.global_position = f0.global_position + vv
			cc.look_at(f0.global_position + Vector3.UP * 1.4)
			cc.current = true
			await _wait(0.03)
			await main.shot("nc_%s_%d" % [id, kk])
		var fd = fwd
		var sd = side
		cc.global_position = base + Vector3.UP * 4.5 + sd * 7.0 - fd * 1.0
		cc.look_at(base + fd * 4.5 + Vector3.UP * 0.6)
		cc.current = true
		await _wait(0.03)
		await main.shot("nv_%s" % id)
		pl.cam.current = true
		await _wait(1.5)
		_clear()
		for f in foes:
			f.statuses.clear()
			if f.has_meta("kagemane_hold"):
				f.remove_meta("kagemane_hold")
	get_tree().quit()
