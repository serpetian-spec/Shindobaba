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
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "hatake", "element": "raiton", "hair_style": "diken",
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
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	for f in foes:
		f.arch["clan"] = ""
	Gear.grant(pr, "hakko_chakura_to", "sag")
	pr["weapon_drawn"] = true
	if pl.model and pl.model.has_method("refresh_gear"):
		pl.model.refresh_gear()
	var SH = {"hatake_raiju_tsuiga": [0.42, 0.55]}
	for id in SH.keys():
		pl.global_position = base
		pl.chakra = 1e9
		for i in foes.size():
			foes[i].global_position = base + [fwd * 8.0, fwd * 9.0 + side * 3.0, fwd * 8.5 - side * 3.0][i]
			foes[i].statuses.clear()
			foes[i].stun_meter = 0.0
			foes[i].state = "idle"
			foes[i].velocity = Vector3.ZERO
			for m in ["cc_start", "cc_imm", "cc_n", "cc_last"]:
				if foes[i].has_meta(m):
					foes[i].remove_meta(m)
		await _wait(0.6)
		var ctr = base.lerp(f0.global_position, 0.45)
		Jutsu.execute(pl, id, f0)
		var tsum = 0.0
		for ti in SH[id].size():
			await _wait(SH[id][ti] - tsum)
			tsum = SH[id][ti]
			var near_hand = id in ["raikiri", "hatake_shiden"]
			var fdp = pl.face_dir()
			var sdp = fdp.cross(Vector3.UP).normalized()
			var ctr2 = (pl.global_position + Vector3.UP * 0.2 + fdp * 1.0) if near_hand else f0.global_position
			ctr = ctr2
			var views = [fdp * 3.2 + sdp * 2.2 + Vector3.UP * 0.8, sdp * 3.6 - fdp * 0.5 + Vector3.UP * 0.6] if near_hand else [-fdp * 4.5 + sdp * 2.5 + Vector3.UP * 1.5, sdp * 4.5 + Vector3.UP * 1.2]
			for kk in 2:
				cc.global_position = ctr + views[kk]
				cc.look_at(ctr + Vector3.UP * 1.4)
				cc.current = true
				Hud.close_dialog()
				await _wait(0.02)
				await main.shot("sv_%s_%d_%d" % [id, ti, kk])
		pl.cam.current = true
		await _wait(4.0)
		_clear()
	get_tree().quit()
