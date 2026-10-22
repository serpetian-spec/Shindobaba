extends Node
## Element etkileşim testi: su↔ateş çarpışması, rüzgar ateşi besler, ıslak hedefe yıldırım (zincir),
## ıslak hedefe ateş, su yanığı söndürür, toprak duvar suyu durdurur / yıldırım duvarı parçalar.

var main: Node


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
	e.max_hp = 5000.0
	e.hp = 5000.0
	return e


func _proj(shooter: Node3D, from: Vector3, to: Vector3, el: String, dmg: float, col: Color) -> Projectile:
	var pr = Projectile.new()
	pr.shooter = shooter
	pr.vel = (to - from).normalized() * 18.0
	pr.radius = 1.0
	pr.life = 3.0
	pr.info = {"dmg": dmg, "element": el, "knock": 2.0, "kind": "heavy"}
	pr.add_child(Projectile.energy_mesh(col.lightened(0.4), col, 1.6, 3.0, 3.0, 2.0))
	get_tree().current_scene.add_child(pr)
	pr.global_position = from
	return pr


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.08, 0.08, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	Game.world.env.time_of_day = 0.45
	Game.world.env.weather = "açık"
	var v := Game.village("konoha")
	var base := Game.from_map(Vector2(v["x"] + 300, v["y"] + 140))
	pl.respawn(base)
	pl.max_hp = 9999.0
	pl.hp = 9999.0
	pl.yaw = 90.0
	pl.pitch = -10.0
	pl.cam_dist = 9.0
	await _wait(1.0)
	print("TABLO katon>fuuton=", Elements.mult("katon", "fuuton"), " suiton>katon=", Elements.mult("suiton", "katon"),
		" katon>suiton=", Elements.mult("katon", "suiton"), " yoton>doton=", Elements.mult("yoton", "doton"),
		" hyoton>suiton=", Elements.mult("hyoton", "suiton"), " mokuton>raiton=", Elements.mult("mokuton", "raiton"),
		" ranton>fuuton=", Elements.mult("ranton", "fuuton"), " jinton>doton=", Elements.mult("jinton", "doton"))

	# 1) ateş topu vs su: çarpışma, buhar, ateş söner
	var e := _enemy(base + Vector3(0, 0, -16))
	await _wait(0.5)
	var hp0 = e.hp
	var f1 = _proj(pl, base + Vector3(0, 1.5, 0), e.global_position + Vector3.UP * 1.5, "katon", 26.0, Color(1, 0.4, 0.05))
	var w1 = _proj(e, e.global_position + Vector3(0, 1.5, 0), base + Vector3.UP * 1.5, "suiton", 30.0, Color(0.2, 0.5, 1))
	await _wait(0.42)
	await main.shot("e1_su_ates_carpisma")
	await _wait(1.2)
	print("1) SU vs ATEŞ: ateş yok=", not is_instance_valid(f1) or f1.dead, " su devam/öldü=", is_instance_valid(w1) and not w1.dead, " düşman hasar=", hp0 - e.hp)

	# 2) rüzgar ateşi besler: ateş büyür, rüzgar kaybolur
	hp0 = e.hp
	var f2 = _proj(pl, base + Vector3(0, 1.5, 0), e.global_position + Vector3.UP * 1.5, "katon", 26.0, Color(1, 0.4, 0.05))
	var w2 = _proj(e, e.global_position + Vector3(0, 1.5, 0), base + Vector3.UP * 1.5, "fuuton", 20.0, Color(0.7, 1, 0.8))
	await _wait(0.45)
	var grown = f2.info["dmg"] if is_instance_valid(f2) else -1.0
	await main.shot("e2_ruzgar_besler")
	await _wait(1.2)
	print("2) RÜZGAR+ATEŞ: rüzgar yok=", not is_instance_valid(w2) or w2.dead, " ateş hasarı 26->", grown, " düşman hasar=", hp0 - e.hp)

	# 3) ıslak hedef + yıldırım: ekstra hasar + yanındaki ıslak düşmana zincir
	var e2 := _enemy(base + Vector3(3, 0, -16))
	e.global_position = base + Vector3(0, 0, -16)
	e.velocity = Vector3.ZERO
	await _wait(0.4)
	Combat.hit_sphere(pl, e.global_position + Vector3.UP, 3.0, {"dmg": 1.0, "element": "suiton", "kind": "light"})
	Combat.hit_sphere(pl, e2.global_position + Vector3.UP, 1.0, {"dmg": 1.0, "element": "suiton", "kind": "light"})
	print("3) ıslak mı: e=", e.has_status("wet"), " e2=", e2.has_status("wet"))
	var a0 = e.hp; var b0 = e2.hp
	e.take_hit({"dmg": 20.0, "element": "raiton", "kind": "heavy", "attacker": pl, "dir": Vector3.FORWARD})
	await _wait(0.1)
	await main.shot("e3_islak_yildirim")
	print("3) ISLAK+YILDIRIM: e hasar=", a0 - e.hp, " (normal 20) stun=", e.has_status("stun"), " zincir e2 hasar=", b0 - e2.hp, " e2 stun=", e2.has_status("stun"))

	# 4) ıslak hedefe ateş: zayıf, tutuşmaz
	await _wait(1.5)
	e.apply_status("wet", 5.0)
	a0 = e.hp
	e.take_hit({"dmg": 20.0, "element": "katon", "kind": "heavy", "attacker": pl, "dir": Vector3.FORWARD, "burn": 3.0})
	print("4) ISLAK+ATEŞ: hasar=", a0 - e.hp, " (rogue elementine göre) yanıyor=", e.has_status("burn"), " ıslak kaldı=", e.has_status("wet"))

	# 5) su yanığı söndürür
	e.apply_status("burn", 5.0)
	e.take_hit({"dmg": 2.0, "element": "suiton", "kind": "light", "attacker": pl, "dir": Vector3.FORWARD})
	print("5) SU SÖNDÜRÜR: yanıyor=", e.has_status("burn"), " ıslak=", e.has_status("wet"))

	# 6) rüzgar yanan hedeften alevi yayar
	e.statuses.clear(); e2.statuses.clear()
	e.global_position = base + Vector3(0, 0, -16); e2.global_position = base + Vector3(2.5, 0, -16)
	await _wait(0.1)
	e.apply_status("burn", 4.0)
	e.take_hit({"dmg": 10.0, "element": "fuuton", "kind": "light", "attacker": pl, "dir": Vector3.FORWARD})
	print("6) RÜZGAR YAYAR: e2 yanıyor=", e2.has_status("burn"))

	# 7) toprak duvar suyu durdurur, yıldırım duvarı parçalar
	e.global_position = base + Vector3(0, 0, -20)
	e.face_dir()
	e.facing = 0.0
	Jutsu.j_doton_doryuheki(e, pl)
	await _wait(0.6)
	e.global_position = base + Vector3(14, 0, -30)  # duvarın önünden çekil
	e2.global_position = base + Vector3(-14, 0, -30)
	var walls = get_tree().get_nodes_in_group("element_walls")
	var wpos: Vector3 = walls[0].global_position if not walls.is_empty() else e.global_position
	var w7 = _proj(pl, base + Vector3(0, 1.5, 0), wpos + Vector3.UP * 2.0, "suiton", 30.0, Color(0.2, 0.5, 1))
	await _wait(2.0)
	print("7a) TOPRAK DUVAR vs SU: su durdu=", not is_instance_valid(w7) or w7.dead, " duvar ayakta=", get_tree().get_nodes_in_group("element_walls").size() > 0)
	var r7 = _proj(pl, base + Vector3(0, 1.5, 0), wpos + Vector3.UP * 2.0, "raiton", 40.0, Color(0.6, 0.8, 1))
	await _wait(1.25)
	await main.shot("e4_yildirim_duvar")
	await _wait(1.0)
	print("7b) YILDIRIM vs TOPRAK DUVAR: duvar yıkıldı=", get_tree().get_nodes_in_group("element_walls").is_empty(), " yıldırım geçti/yaşıyor=", is_instance_valid(r7) and not r7.dead)

	# 8) yağmur: ıslatır, ateş zayıflar
	Game.world.env.region_weather = "yağmur"
	Game.world.env.weather = "yağmur"
	print("8) YAĞMUR: katon çarpanı=", Combat.element_mult("katon", ""), " raiton=", Combat.element_mult("raiton", ""))
	await _wait(1.2)
	print("8) yağmurda e ıslak=", e.has_status("wet"))
	Game.world.env.weather = "açık"
	Elements.scorch(base + Vector3(4, 0, -6), 3.0)
	await _wait(0.3)
	await main.shot("e5_yanik_izi")
	get_tree().quit()
