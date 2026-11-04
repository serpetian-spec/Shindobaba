extends Node
## Klan jutsuları testi: ClanJutsu'nun uyguladığı her jutsu sırayla atılır (hata/çökme yok mu),
## seçilmiş olanların etki anında ekran görüntüsü alınır, uçuş kipi (Keijūgan, kum bulutu) denenir.

var main: Node
var IDS = ["kaiten", "hakke_hasangeki", "jukenho_ichigekishin", "juken"]


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
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "hyuga", "element": "katon", "hair_style": "diken",
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

	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	for id in IDS:
		pl.global_position = base
		pl.facing = atan2(-fwd.x, -fwd.z)
		pl.velocity = Vector3.ZERO
		pl.statuses.clear()
		for i in foes.size():
			foes[i].global_position = base + [fwd * 4.0, fwd * 6.0 + side * 2.0, fwd * 5.0 - side * 2.5][i]
			foes[i].statuses.clear()
			foes[i].arch["clan"] = "hyuga" if (id == "hyuga_soke_no_juinjutsu" and i == 0) else ""
			var tv = pl.global_position - foes[i].global_position
			foes[i].facing = atan2(-tv.x, -tv.z)
		await _wait(0.4)
		pl.cam.current = true
		var hp0 = foes.map(func(f): return f.hp)
		if id == "jukenho_ichigekishin":
			pl.apply_status("bind", 5.0)
			print("BIND before=", pl.has_status("bind"))
		if id == "hyuga_soke_no_juinjutsu":
			Jutsu.execute(pl, id, foes[1])   # mühürsüz hedef: etkisiz olmalı
			await _wait(0.3)
			print("JUIN nonhyuga stun=", foes[1].has_status("stun"))
		Jutsu.execute(pl, id, foes[0])
		if id == "jukenho_ichigekishin":
			await _wait(0.3)
			print("BIND after=", pl.has_status("bind"))
		if id == "juho_soshiken":
			await _wait(0.8)
			pl.global_position = foes[0].global_position - fwd * 1.3
			pl.facing = atan2(-fwd.x, -fwd.z)
			pl.combat.attack()
			await _wait(0.5)
			print("LION buff=", Buffs.active.has("juho_soshiken"), " foe0 sealed=", foes[0].has_status("sealed"))
		var times = [0.12 if id == "hakke_hasangeki" else 0.3]
		for tt in times:
			await _wait(tt)
			await main.shot("hy_%s_%.2f" % [id, tt])
			var fd = pl.face_dir()
			var sd = fd.cross(Vector3.UP)
			if id == "hyuga_soke_no_juinjutsu":
				var sk = foes[0].model.skel
				var hp = sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Head")).origin
				var mf = foes[0].model.global_transform.basis.z.normalized()
				cc.global_position = hp + mf * 0.9 + Vector3.UP * 0.1
				cc.look_at(hp + Vector3.UP * 0.08)
			else:
				cc.global_position = pl.global_position + Vector3.UP * 2.2 + sd * 7.0 + fd * 2.0
				cc.look_at(pl.global_position + Vector3.UP * 1.2 + fd * 2.0)
			cc.current = true
			await _wait(0.03)
			await main.shot("hy_%s_yan_%.2f" % [id, tt])
			pl.cam.current = true
		if id == "juuken_64":
			print("64 sealed=", foes[0].has_status("sealed"), " slow=", foes[0].has_status("slow"))
			pl.apply_status("sealed", 3.0)
			pl.combat.begin_cast("juken")
			print("SEALED player cast_jutsu=", pl.combat.cast_jutsu, " action=", pl.combat.action)
			pl.statuses.erase("sealed")
		await _wait(1.2)
		print("HP %s: %s" % [id, str(range(foes.size()).map(func(i): return snappedf(hp0[i] - foes[i].hp, 0.1)))])
		_clear()
	get_tree().quit()
