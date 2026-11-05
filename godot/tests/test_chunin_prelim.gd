extends Node
## Chūnin ön eleme (kule salonu) + finaller + sonuç: rakip gerçekten gelip dövüşüyor mu, seyirciler yerinde mi, sınav Chūnin ile bitiyor mu

var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _kill(r: Node, pl: Node) -> void:
	var n = 0
	while is_instance_valid(r) and not r.is_dead() and n < 400:
		r.take_hit({"dmg": 60.0, "attacker": pl, "kind": "light", "knock": 1.0, "dir": Vector3.FORWARD, "melee": true})
		n += 1
		await _wait(0.12)


func _report(tag: String) -> void:
	var it = Interiors.inst
	var pl = Game.player
	var e = ChuninExam.st.get("duel")
	var line = "[%s] stage=%d inside=%s pl=%s" % [tag, ChuninExam.stage, it.inside if it else "?", pl.global_position.round()]
	if e != null and is_instance_valid(e):
		line += " duel=%s pos=%s dist=%.1f state=%s target=%s hp=%d" % [e.display_name, e.global_position.round(), e.global_position.distance_to(pl.global_position), e.state,
			("player" if e.target == pl else str(e.target)), int(e.hp)]
	else:
		line += " duel=none"
	print(line)
	if ChuninExam.stage == 5:
		var sp = ChuninExam.stadium_pos()
		var inn = 0
		var tot2 = 0
		for n in Exams.nodes:
			if is_instance_valid(n) and n is Villager:
				tot2 += 1
				if Vector2(n.global_position.x - sp.x, n.global_position.z - sp.z).length() < Stadium.R_FIELD - 1.0:
					inn += 1
		print("   stadium audience total=%d in_field=%d" % [tot2, inn])
	if it and it.inside != "":
		var bad = 0
		var tot = 0
		for n in get_tree().current_scene.find_children("*", "Villager", true, false):
			if n.global_position.distance_to(it.origin) < 80.0:
				tot += 1
				if n.global_position.y < it.origin.y + 4.0 and absf(n.global_position.x - it.origin.x) < Interiors.HALL_W * 0.5 - 4.5:
					bad += 1
		print("   audience total=%d on_floor=%d" % [tot, bad])


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
	ChuninExam.host = host
	ChuninExam.st = {"written": 5, "forest_days": 0.0, "prelim_wins": 0, "final_wins": 0, "jutsu": {}, "kawarimi": 0, "hp_lost": 0.0, "invasion": false, "mates_alive": 2}
	ChuninExam._forest()
	await _wait(1.5)
	pr["inventory"]["scroll_heaven"] = 1
	pr["inventory"]["scroll_earth"] = 1
	var tw: Vector3 = ChuninExam.st["tower"]
	tw.y = Game.ground_height(tw.x, tw.z)
	pl.respawn(tw + Vector3(10, 1.0, 0))
	await _wait(3.0)
	_report("hall")
	Hud.close_dialog()
	ExamUI._resume()
	ChuninExam._next_prelim()
	for k in 6:
		await _wait(1.0)
		pl.hp = pl.max_hp
		_report("prelim1 t%d" % k)
	var e = ChuninExam.st.get("duel")
	if e and is_instance_valid(e):
		await _kill(e, pl)
	await _wait(3.5)
	_report("prelim2 start")
	for k in 3:
		await _wait(1.0)
		pl.hp = pl.max_hp
		_report("prelim2 t%d" % k)
	e = ChuninExam.st.get("duel")
	if e and is_instance_valid(e):
		await _kill(e, pl)
	await _wait(4.0)
	Hud.close_dialog()
	_report("after prelims")
	# finaller: stadyuma git
	if ChuninExam.stage == 4:
		var sp = ChuninExam.stadium_pos()
		pl.respawn(sp + Vector3(0, 1.0, 0))
		await _wait(3.0)
		Hud.close_dialog()
		ExamUI._resume()   # eşleşme ekranındaki "Arenaya çık" düğmesi
		ChuninExam._next_final()
		for round in 4:
			_report("final r%d" % round)
			e = ChuninExam.st.get("duel")
			if e and is_instance_valid(e):
				for k in 2:
					await _wait(1.0)
					pl.hp = pl.max_hp
				_report("final r%d fight" % round)
				await _kill(e, pl)
			await _wait(4.0)
			Hud.close_dialog()
			if ChuninExam.stage == 0:
				break
	ExamUI._resume()
	await _wait(0.5)
	print("[END] stage=%d rank=%s mission=%s" % [ChuninExam.stage, pr.get("rank"), pr.get("active_mission", {}).get("title", "")])
	get_tree().quit()
