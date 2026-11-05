extends Node
## Chūnin 2. aşama uçtan uca, ev sahibi köy EXAM_HOST ortam değişkeninden: alan/kamp/rakip doğuyor mu, kamp taşıyıcısı ve pusucu
## parşömen bırakıyor mu, iki parşömenle kuleye varınca ön eleme başlıyor mu, süre dolunca eleme + görev listesi temizleniyor mu.

var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _kill(r: Node, pl: Node) -> void:
	var n = 0
	while is_instance_valid(r) and not r.is_dead() and n < 300:
		r.take_hit({"dmg": 80.0, "attacker": pl, "kind": "light", "knock": 1.0, "dir": Vector3.FORWARD, "melee": true})
		n += 1
		await _wait(0.15)


func _ready() -> void:
	await get_tree().process_frame
	var host = OS.get_environment("EXAM_HOST")
	if host == "":
		host = "konoha"
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "akimichi", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pr = Game.profile
	pr["mastery"] = {"chakra": 17.0, "dayaniklilik": 6.6, "hiz": 3.8, "kenjutsu": 11.4, "ninjutsu": 21.2, "taijutsu": 46.6}
	pr["level"] = 36
	var pl: Player = main.player
	await _wait(1.0)
	var ok = true
	ChuninExam.host = host
	ChuninExam.st = {"written": 5, "forest_days": 0.0, "prelim_wins": 0, "final_wins": 0, "jutsu": {}, "kawarimi": 0, "hp_lost": 0.0, "invasion": false, "mates_alive": 2}
	ChuninExam._forest()
	await _wait(2.0)
	pl.max_hp = 1e9
	pl.hp = 1e9
	var need = String(ChuninExam.st["need"])
	print("[%s] AREA=%s need=%s camps=%d team=%d mission=%s" % [host, ChuninExam.area_name(), need, ChuninExam.st["camps"].size(), ChuninExam.team.size(), pr.get("active_mission", {}).get("title", "")])
	if ChuninExam.team.size() != 2 or ChuninExam.st["camps"].size() != 4:
		ok = false
	# 1) kamp taşıyıcısı
	var cp = ChuninExam.st["camps"][0]
	var tc = Vector3(cp["pos"][0], cp["pos"][1], cp["pos"][2])
	tc.y = Game.ground_height(tc.x, tc.z)
	pl.respawn(tc + Vector3(6, 0.5, 0))
	pl.hp = 1e9
	await _wait(2.0)
	var spawned = ChuninExam.rivals.filter(func(r): return is_instance_valid(r))
	var carrier = null
	for r in spawned:
		if r.has_meta("carries"):
			carrier = r
	print("[%s] camp rivals=%d carrier=%s ground_y=%.1f rival_y=%s" % [host, spawned.size(), carrier != null, tc.y, ", ".join(spawned.map(func(r): return "%.1f" % r.global_position.y))])
	if carrier == null:
		ok = false
	else:
		await _kill(carrier, pl)
		await _wait(0.6)
	var got_camp = int(pr["inventory"].get("scroll_" + need, 0)) > 0
	print("[%s] camp scroll=%s" % [host, got_camp])
	ok = ok and got_camp
	# 2) pusucu: parşömeni geri al, gün değiştir, taşıyanı kes (3. gün: her zaman gerekli olan)
	pr["inventory"].erase("scroll_" + need)
	ChuninExam.st["forest_t"] = 3.0 * ChuninExam.DAY_LEN - 0.5
	ChuninExam.st["day"] = 2
	await _wait(1.5)
	var amb = null
	for r in ChuninExam.rivals:
		if is_instance_valid(r) and not r.dead and r.display_name.begins_with("Pusucu") and r.has_meta("carries"):
			amb = r
	print("[%s] ambush carrier=%s carries=%s" % [host, amb != null, amb.get_meta("carries") if amb else ""])
	if amb:
		await _kill(amb, pl)
		await _wait(0.6)
	var got_amb = int(pr["inventory"].get("scroll_" + need, 0)) > 0
	print("[%s] ambush scroll=%s" % [host, got_amb])
	ok = ok and got_amb
	# 3) kuleye var -> ön eleme
	var tw: Vector3 = ChuninExam.st["tower"]
	tw.y = Game.ground_height(tw.x, tw.z)
	pl.respawn(tw + Vector3(10, 1.0, 0))
	await _wait(2.5)
	print("[%s] tower stage=%d (3 = ön eleme)" % [host, ChuninExam.stage])
	ok = ok and ChuninExam.stage == 3
	# 4) süre dolunca eleme (yeni orman)
	ChuninExam._fail("test")
	Hud.close_dialog()
	ChuninExam._forest()
	await _wait(1.0)
	ChuninExam.st["forest_t"] = 0.05
	await _wait(1.0)
	Hud.close_dialog()
	var am = pr.get("active_mission", {})
	print("[%s] timeout stage=%d mission_empty=%s hud_obj=%s" % [host, ChuninExam.stage, am.is_empty(), Hud.objective_lbl.text.contains("Parşömen")])
	ok = ok and ChuninExam.stage == 0 and am.is_empty() and not Hud.objective_lbl.text.contains("Parşömen")
	print("[%s] RESULT %s" % [host, "OK" if ok else "FAIL"])
	get_tree().quit()
