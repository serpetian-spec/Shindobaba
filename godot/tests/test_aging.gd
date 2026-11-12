extends Node
## Yaş + vücut tipi: aynı kişinin yaş sırası, vücut tipleri, yüz yakın çekimi, oyuncuda canlı değişim
var main: Node
var cam: Camera3D
var pl: Node3D
var made: Array = []


func _camw(p: Vector3, t: Vector3, fov := 30.0) -> void:
	if cam == null or not is_instance_valid(cam):
		cam = Camera3D.new()
		main.add_child(cam)
	cam.fov = fov
	cam.global_position = p
	cam.look_at(t)
	cam.current = true


func _mk(at: Vector3, yaw: float, extra: Dictionary) -> CharacterModel:
	var lk = {"gender": "m", "hair_style": "diken", "hair": Color(0.12, 0.1, 0.1), "top": Color(0.2, 0.3, 0.5), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8), "own_hair": true, "band": null}
	lk.merge(extra, true)
	var m = CharacterModel.new()
	main.add_child(m)
	m.setup(lk)
	m.global_position = at
	m.rotation.y = yaw
	made.append(m)
	return m


func _solo(m) -> void:
	for x in made:
		if is_instance_valid(x):
			x.visible = m == null or x == m


func _clear() -> void:
	for m in made:
		if is_instance_valid(m):
			m.queue_free()
	made.clear()


func _head(m: CharacterModel) -> Vector3:
	return m.skel.global_transform * m.skel.get_bone_global_pose(m.skel.find_bone("Head")).origin


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	pl = main.player
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	main.world.env.time_of_day = 0.45
	var which = (OS.get_environment("AG") if OS.get_environment("AG") != "" else "ages,body,live").split(",")
	var base = Missions.open_ground(pl.global_position + Vector3(0, 0, 30), 30.0)
	var gy = func(x: float) -> Vector3: return Vector3(base.x + x, Game.ground_height(base.x + x, base.z), base.z)
	pl.global_position = base + Vector3(0, 0.3, -14)
	await get_tree().create_timer(0.5).timeout

	if "ages" in which:
		var ys = [8.0, 13.0, 17.0, 25.0, 45.0, 58.0, 70.0, 86.0]
		for i in ys.size():
			_mk(gy.call((i - 3.5) * 1.15), PI, {"years": ys[i], "age_seed": "ayni"})
		await get_tree().create_timer(1.2).timeout
		var c = gy.call(0.0)
		_camw(c + Vector3(0, 1.3, 9.5), c + Vector3.UP * 0.95)
		await main.shot("age_row_front")
		_camw(c + Vector3(8.5, 1.3, 2.0), c + Vector3.UP * 0.95, 34.0)
		await main.shot("age_row_side")
		for i in [3, 4, 5, 6, 7]:
			var m: CharacterModel = made[i]
			var h = _head(m)
			_camw(h + Vector3(0.0, 0.0, 0.62), h, 26.0)
			await get_tree().create_timer(0.1).timeout
			await main.shot("age_face_%d" % int(ys[i]))
			if i >= 6:
				_solo(m)
				_camw(m.global_position + Vector3(3.2, 1.1, 0.0), m.global_position + Vector3.UP * 0.9)
				await get_tree().create_timer(0.1).timeout
				await main.shot("age_profile_%d" % int(ys[i]))
				_solo(null)
			print("AG yas=", ys[i], " evre=", m.look["age"], " sac=", m.look["hair"], " old=", snappedf(m.look.get("old", 0.0), 0.01), " lines=", snappedf(m.look.get("lines", 0.0), 0.01), " boy=", snappedf(_head(m).y - m.global_position.y, 0.01))
		_clear()
		await get_tree().create_timer(0.3).timeout

	if "body" in which:
		var sets = [["zayıf", -0.6, 0.0], ["normal", 0.0, 0.0], ["kaslı", 0.0, 1.0], ["dolgun", 0.5, 0.0], ["kilolu", 1.0, 0.0], ["iri", 0.7, 0.8]]
		for g in 2:
			for i in sets.size():
				_mk(gy.call((i - 2.5) * 1.3), PI, {"gender": "mf"[g], "hair_style": "diken" if g == 0 else "uzun", "years": 26.0, "fat": sets[i][1], "mus": sets[i][2], "top_style": "tişört", "sleeves": false})
			await get_tree().create_timer(1.2).timeout
			var c = gy.call(0.0)
			_camw(c + Vector3(0, 1.2, 8.5), c + Vector3.UP * 0.95)
			await main.shot("body_%s_front" % "mf"[g])
			_camw(c + Vector3(7.5, 1.2, 3.0), c + Vector3.UP * 0.95, 34.0)
			await main.shot("body_%s_34" % "mf"[g])
			_camw(c + Vector3(0, 1.2, -8.5), c + Vector3.UP * 0.95)
			await main.shot("body_%s_back" % "mf"[g])
			for i in [0, 2, 4]:
				var m: CharacterModel = made[i]
				_solo(m)
				_camw(m.global_position + Vector3(3.6, 1.0, 0.0), m.global_position + Vector3.UP * 0.9)
				await get_tree().create_timer(0.1).timeout
				await main.shot("body_%s_side_%d" % ["mf"[g], i])
				_camw(m.global_position + Vector3(2.4, 1.0, 2.6), m.global_position + Vector3.UP * 0.9)
				await get_tree().create_timer(0.1).timeout
				await main.shot("body_%s_q_%d" % ["mf"[g], i])
			_solo(null)
			# hareket halinde (koşu) göbek / kas bozulmuyor mu
			for m in made:
				m.play("run")
			await get_tree().create_timer(0.45).timeout
			_camw(c + Vector3(5.5, 1.2, 6.5), c + Vector3.UP * 0.95, 34.0)
			await main.shot("body_%s_run" % "mf"[g])
			_clear()
			await get_tree().create_timer(0.3).timeout

	if "live" in which:
		# oyuncu: yaş ve vücut oyun içinde değişir
		Game.profile["rank"] = 3
		Aging.set_years(Game.profile, 24.0)
		pl.rebuild_model()
		await get_tree().create_timer(0.8).timeout
		var f = pl.face_dir()
		print("AG oyuncu yas=", snappedf(Aging.player_years(), 0.1), " evre=", pl.model.look["age"], " body=", Aging.body())
		for k in 12:
			Aging.feed(0.05)
		Aging._chk = 0.0
		await get_tree().create_timer(0.5).timeout
		print("AG 12 ramen: fat=", snappedf(Aging.body()["fat"], 0.01), " model fat=", snappedf(pl.model.look.get("fat", 0.0), 0.01), " belly=", pl.model.overlay.b_belly)
		_camw(pl.global_position + f * 4.0 + Vector3.UP * 1.1 + f.cross(Vector3.UP) * 2.0, pl.global_position + Vector3.UP * 0.95)
		await main.shot("live_fat")
		pl.spend_stamina(12000.0)
		for k in 300:
			Aging.train(0.0015)
		Aging._chk = 0.0
		await get_tree().create_timer(0.5).timeout
		print("AG antrenman: body=", Aging.body(), " arm=", snappedf(pl.model.overlay.b_arm, 0.01))
		await main.shot("live_trained")
		# 40 yıl geçer
		Game.profile["clock"] = Aging.clock() + 44.0 * Aging.YEAR
		Aging._chk = 0.0
		await get_tree().create_timer(0.6).timeout
		print("AG +44 yil: yas=", snappedf(Aging.player_years(), 0.1), " sac=", pl.model.look["hair"], " lines=", snappedf(pl.model.look.get("lines", 0.0), 0.01), " stoop=", snappedf(rad_to_deg(pl.model.overlay.stoop), 0.1))
		await main.shot("live_old")
		var h = _head(pl.model)
		_camw(h + f * 0.62, h, 26.0)
		await get_tree().create_timer(0.1).timeout
		await main.shot("live_old_face")
		# dünya ninjaları: yaş dağılımı
		var ys = []
		var fs = []
		for id in WorldPeople.all():
			var p = WorldPeople.get_p(id)
			ys.append(Aging.person_years(p))
			fs.append(Aging.person_shape(p))
		ys.sort()
		if not ys.is_empty():
			print("AG dunya n=", ys.size(), " yas min/orta/max=", snappedf(ys[0], 0.1), "/", snappedf(ys[ys.size() / 2], 0.1), "/", snappedf(ys[-1], 0.1), " kilolu(>0.4)=", fs.filter(func(v): return v.x > 0.4).size(), " kasli(>0.5)=", fs.filter(func(v): return v.y > 0.5).size())
	get_tree().quit()
