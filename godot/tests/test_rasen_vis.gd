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
	# ---- Rasengan: koşarak mı gidiyor? (anim + hız ölçümü, yan görünüş)
	pl.global_position = base
	for f in foes:
		f.global_position = base + fwd * 40.0 + side * 20.0
	f0.global_position = base + fwd * 9.0
	await _wait(0.6)
	Game.set_meta("sandbox", true)
	for id in ["rasengan", "fuuton_rasenshuriken"]:
		pr["learned"].append(id)
		pl.combat.cooldowns.erase(id)
		pl.global_position = base
		f0.global_position = base + fwd * 12.0
		f0.velocity = Vector3.ZERO
		f0.set_physics_process(false)
		f0.set_process(false)
		f0.state = "idle"
		await _wait(0.5)
		pl.combat.begin_cast(id)
		var ca = pl.combat.cast_anim
		var shots = 0
		var tt = 0.0
		var plan = [0.35, 0.8] if id != "rasengan" else [0.3]
		while is_instance_valid(ca) and not ca.released:
			await get_tree().process_frame
			tt += get_process_delta_time()
			if shots < plan.size() and tt >= plan[shots]:
				var fd = pl.face_dir()
				var sd = fd.cross(Vector3.UP).normalized()
				cc.global_position = pl.global_position + fd * 4.0 + sd * 2.5 + Vector3.UP * (1.6 if shots == 0 else 3.6)
				cc.look_at(pl.global_position + Vector3.UP * (1.7 if shots == 0 else 2.3))
				cc.current = shots == 0
				if shots == 1:
					pl.cam.current = true
				await main.shot("rs_%s_pre_%d" % [id, shots])
				pl.cam.current = true
				shots += 1
		if id == "rasengan":
			for k in 6:
				await _wait(0.15)
				var fd2 = pl.face_dir()
				var sd2 = fd2.cross(Vector3.UP).normalized()
				print("RAS t=%.2f anim=%s vel=%.1f" % [k * 0.15, pl.model.anim.current_animation if pl.model.get("anim") else "?", pl.velocity.length()])
				cc.global_position = pl.global_position + sd2 * 4.5 + Vector3.UP * 1.3
				cc.look_at(pl.global_position + Vector3.UP * 1.0)
				cc.current = true
				await main.shot("rs_rasengan_run_%d" % k)
		else:
			await _wait(0.15)
			var fd3 = pl.face_dir()
			var sd3 = fd3.cross(Vector3.UP).normalized()
			cc.global_position = pl.global_position + sd3 * 5.0 + fd3 * 2.0 + Vector3.UP * 2.5
			cc.look_at(pl.global_position + fd3 * 5.0 + Vector3.UP * 1.5)
			cc.current = true
			await main.shot("rs_flight")
			while is_instance_valid(f0) and get_tree().current_scene.get_children().any(func(n): return n is Projectile):
				await get_tree().process_frame
			await _wait(0.12)
			for kk in 3:
				var c2 = f0.global_position
				cc.global_position = c2 - fd3 * 16.0 + sd3 * 6.0 + Vector3.UP * 4.0
				cc.look_at(c2 + Vector3.UP * 1.0)
				cc.current = true
				await main.shot("rs_burst_%d" % kk)
				await _wait(0.3)
		pl.cam.current = true
		await _wait(2.5)
		_clear()
	get_tree().quit()
