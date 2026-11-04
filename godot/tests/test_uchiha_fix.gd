extends Node
## Klan jutsuları testi: ClanJutsu'nun uyguladığı her jutsu sırayla atılır (hata/çökme yok mu),
## seçilmiş olanların etki anında ekran görüntüsü alınır, uçuş kipi (Keijūgan, kum bulutu) denenir.

var main: Node
var IDS = ["uchiha_kaenjin"]


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
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken",
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

	for id in IDS:
		pl.global_position = base
		pl.facing = atan2(-fwd.x, -fwd.z)
		pl.velocity = Vector3.ZERO
		for i in foes.size():
			foes[i].global_position = base + [fwd * 8.0, fwd * 12.0 + side * 3.0, fwd * 10.0 - side * 3.5][i]
			foes[i].statuses.clear()
			foes[i].team = "enemy" if foes[i].team == "neutral" else foes[i].team
		await _wait(0.4)
		pl.yaw = -35.0
		for f in foes:
			var tv = pl.global_position - f.global_position
			f.facing = atan2(-tv.x, -tv.z)
		pl.cam.current = true
		var hp0 = foes.map(func(f): return f.hp)
		Jutsu.execute(pl, id, foes[0])
		var prs = []
		if id == "uchihagaeshi":
			await _wait(0.3)
			for k in 2:
				var sp = foes[k].global_position + Vector3.UP * 1.3
				prs.append(Projectile.tool(foes[k], sp, (pl.global_position + Vector3.UP * 1.2 - sp).normalized(), "kunai", pl))
		var times = [0.2, 0.4, 0.8] if id != "izanami" else [0.3, 1.2, 2.5, 4.6]
		for tt in times:
			await _wait(tt)
			await main.shot("ux_%s_%.1f" % [id, tt])
			if id == "izanami":
				var cc2 = Camera3D.new()
				get_tree().current_scene.add_child(cc2)
				cc2.global_position = foes[0].global_position + Vector3.UP * 2.5 + side * 5.0 - fwd * 4.0
				cc2.look_at(foes[0].global_position + Vector3.UP * 1.0)
				cc2.current = true
				await _wait(0.03)
				await main.shot("ux_izanami_yakin_%.1f" % tt)
				cc2.queue_free()
				pl.cam.current = true
			if id == "uchihagaeshi":
				for p in prs:
					if is_instance_valid(p):
						print("UGAESHI t=%.1f shooter=%s vel=%s dead=%s" % [tt, p.shooter.name if is_instance_valid(p.shooter) else "?", p.vel, p.dead])
					else:
						print("UGAESHI t=%.1f projectile freed" % tt)
		if id == "uchiha_kaenjin":
			var cc = Camera3D.new()
			get_tree().current_scene.add_child(cc)
			cc.global_position = pl.global_position + Vector3.UP * 5.0 - fwd * 14.0 + side * 6.0
			cc.look_at(pl.global_position + Vector3.UP * 2.5)
			cc.current = true
			await _wait(0.05)
			await main.shot("ux_kaenjin_genis")
			cc.global_position = pl.global_position + Vector3.UP * 1.5 + fwd * 9.0
			cc.look_at(pl.global_position + Vector3.UP * 3.0)
			await _wait(0.05)
			await main.shot("ux_kaenjin_on")
			cc.queue_free()
		await _wait(1.5)
		print("HP %s: %s" % [id, str(range(foes.size()).map(func(i): return hp0[i] - foes[i].hp))])
		_clear()
	get_tree().quit()
