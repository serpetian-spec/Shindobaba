extends Node
## Kawarimi iç mekânda: Chūnin ön eleme salonu (kule) ve görev mağarası — oyuncu odada kalmalı (arazi yüksekliğine düşüp dışarı atılıyordu);
## hedefli (rakibin arkası), hedefsiz (geriye 7 m, duvara doğru) ve düşmanın Kawarimi'si
var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _check(tag: String, pl: Node, y0: float) -> bool:
	var it = Interiors.inst
	var ok = it.inside != "" and absf(pl.global_position.y - y0) < 3.0
	print("KAW %s inside=%s dy=%.2f %s" % [tag, it.inside, pl.global_position.y - y0, "OK" if ok else "HATA"])
	return ok


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pr = Game.profile
	pr["level"] = 36
	var pl: Player = main.player
	pl.max_hp = 1e9
	pl.hp = 1e9
	await _wait(1.0)
	var good = 0
	var tot = 0
	# 1) Chūnin kule salonu
	ChuninExam.host = "konoha"
	ChuninExam.st = {"written": 5, "forest_days": 0.0, "prelim_wins": 0, "final_wins": 0, "jutsu": {}, "kawarimi": 0, "hp_lost": 0.0, "invasion": false, "mates_alive": 2}
	ChuninExam._forest()
	await _wait(1.5)
	pr["inventory"]["scroll_heaven"] = 1
	pr["inventory"]["scroll_earth"] = 1
	var tw: Vector3 = ChuninExam.st["tower"]
	tw.y = Game.ground_height(tw.x, tw.z)
	pl.respawn(tw + Vector3(10, 1.0, 0))
	await _wait(3.0)
	Hud.close_dialog()
	ExamUI._resume()
	ChuninExam._next_prelim()
	await _wait(3.0)
	var y0 = pl.global_position.y
	var e = ChuninExam.st.get("duel")
	for k in 3:
		pl.combat.sub_bars = 3.0
		pl.combat.action = ""
		pl.combat.substitute()
		await _wait(1.2)
		tot += 1
		good += 1 if _check("salon hedefli %d" % k, pl, y0) else 0
	# hedefsiz: duvara doğru geri kaç
	if e and is_instance_valid(e):
		e.global_position = pl.global_position + Vector3(0, 0, 60)
	for k in 3:
		pl.yaw = k * 120.0
		pl.facing = deg_to_rad(k * 120.0)
		pl.combat.sub_bars = 3.0
		pl.combat.action = ""
		pl.combat.substitute()
		await _wait(1.2)
		tot += 1
		good += 1 if _check("salon hedefsiz %d" % k, pl, y0) else 0
	# düşmanın Kawarimi'si salonda
	if e and is_instance_valid(e):
		e.global_position = pl.global_position + pl.face_dir() * 3.0
		e.sub_cd = 0.0
		e.arch["sub"] = 1.0
		var ey0 = e.global_position.y
		e.take_hit({"dmg": 1.0, "attacker": pl, "kind": "light", "knock": 0.0})
		await _wait(0.5)
		tot += 1
		var eok = absf(e.global_position.y - ey0) < 3.0
		good += 1 if eok else 0
		print("KAW düşman salonda dy=%.2f %s" % [e.global_position.y - ey0, "OK" if eok else "HATA"])
	ChuninExam._fail("test")
	await _wait(2.0)
	Hud.close_dialog()
	if Interiors.inst.inside != "":
		Interiors.inst.exit()
		await _wait(1.5)
	# 2) mağara görevi (iç mekân in)
	for room in ["lair_cave", "lair_lab"]:
		await _cave(room, pl)
	print("KAW SONUÇ salon %d / %d (mağaralar yukarıda)" % [good, tot])
	get_tree().quit()


func _cave(room: String, pl) -> void:
	var p0 = pl.global_position
	Interiors.inst.enter({"pos": p0, "out": p0, "room": room, "seed": 3})
	await _wait(2.5)
	if Interiors.inst.inside != "":
		var y1 = pl.global_position.y
		for k in 4:
			pl.yaw = k * 90.0
			pl.facing = deg_to_rad(k * 90.0)
			pl.combat.sub_bars = 3.0
			pl.combat.action = ""
			pl.combat.substitute()
			await _wait(1.2)
			_check("%s %d" % [room, k], pl, y1)
		Interiors.inst.exit()
		await _wait(1.5)
	else:
		print("KAW %s açılamadı" % room)
