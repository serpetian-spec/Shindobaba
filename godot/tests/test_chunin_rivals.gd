extends Node
## Chūnin 2. aşama: rakipler ölüyor mu, ne kadar canları var, takım arkadaşları ne durumda (kullanıcı kaydına benzer profil)

var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "akimichi", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pr = Game.profile
	pr["mastery"] = {"chakra": 17.0, "dayaniklilik": 6.6, "hiz": 3.8, "kenjutsu": 11.4, "ninjutsu": 21.2, "taijutsu": 46.6}
	pr["level"] = 36
	var pl: Player = main.player
	pl.max_hp = Stats.max_hp(pr)
	pl.hp = pl.max_hp
	print("PLAYER max_hp=", pl.max_hp, " melee_mult=", Stats.melee_mult(pr))
	await _wait(1.0)
	ChuninExam.host = "konoha"
	ChuninExam.st = {"written": 5, "forest_days": 0.0, "prelim_wins": 0, "final_wins": 0, "jutsu": {}, "kawarimi": 0, "hp_lost": 0.0, "invasion": false, "mates_alive": 2}
	ChuninExam._forest()
	await _wait(2.0)
	for m in ChuninExam.team:
		print("MATE ", m.display_name, " hp=", m.max_hp, " power=", m.power, " lv=", m.level, " jutsu=", m.arch.get("jutsu"), " clan=", m.arch.get("clan", ""))
	# ilk kampa ışınla, rakipler doğsun
	var cp = ChuninExam.st["camps"][0]
	var tc = Vector3(cp["pos"][0], cp["pos"][1], cp["pos"][2])
	tc.y = Game.ground_height(tc.x, tc.z)
	pl.respawn(tc + Vector3(6, 0.5, 0))
	pl.max_hp = 1e9
	pl.hp = 1e9
	await _wait(2.0)
	print("RIVALS n=", ChuninExam.rivals.size())
	for r in ChuninExam.rivals:
		if is_instance_valid(r):
			print("RIVAL ", r.display_name, " hp=", r.max_hp, " power=", r.power, " lv=", r.level, " clan=", r.arch.get("clan", ""), " jutsu=", r.arch.get("jutsu"))
	# her rakibe oyuncu adına 30 hasarlık vuruşlar (0.25 sn arayla) — kaç vuruşta ölüyor?
	for r in ChuninExam.rivals:
		if not is_instance_valid(r):
			continue
		var n = 0
		var t0 = Time.get_ticks_msec()
		while is_instance_valid(r) and not r.is_dead() and n < 200:
			r.take_hit({"dmg": 30.0, "attacker": pl, "kind": "light", "knock": 1.0, "dir": Vector3.FORWARD, "melee": true})
			n += 1
			await _wait(0.25)
		print("KILL ", r.display_name if is_instance_valid(r) else "?", " hits=", n, " dead=", (r.is_dead() if is_instance_valid(r) else "freed"), " hp_left=", (r.hp if is_instance_valid(r) else -1), " t=", (Time.get_ticks_msec() - t0) / 1000.0)
	# pusu dalgası: gün değişsin, parşömeni sıfırla
	pr["inventory"].erase("scroll_" + String(ChuninExam.st["need"]))
	ChuninExam.st["forest_t"] = 4.0 * ChuninExam.DAY_LEN - 0.5
	await _wait(1.5)
	for r in ChuninExam.rivals:
		if is_instance_valid(r) and not r.dead and r.display_name.begins_with("Pusucu"):
			print("AMBUSH ", r.display_name, " carries=", r.get_meta("carries", ""))
			while is_instance_valid(r) and not r.is_dead():
				r.take_hit({"dmg": 60.0, "attacker": pl, "kind": "light", "knock": 1.0, "dir": Vector3.FORWARD, "melee": true})
				await _wait(0.2)
	await _wait(1.0)
	print("SCROLLS need=", ChuninExam.st.get("need"), " inv=", {"heaven": pr["inventory"].get("scroll_heaven", 0), "earth": pr["inventory"].get("scroll_earth", 0)}, " stage=", ChuninExam.stage)
	for r in ChuninExam.rivals:
		if is_instance_valid(r):
			print("  R ", r.display_name, " carries=", r.get_meta("carries", ""), " looted=", r.has_meta("looted"), " dead=", r.dead)
	get_tree().quit()
	# takım arkadaşları tek başına: ikinci kamp, oyuncu uzakta bekler (hasar vermez)
	var cp2 = ChuninExam.st["camps"][1]
	var tc2 = Vector3(cp2["pos"][0], cp2["pos"][1], cp2["pos"][2])
	tc2.y = Game.ground_height(tc2.x, tc2.z)
	pl.respawn(tc2 + Vector3(14, 0.5, 0))
	pl.set_meta("untargetable", true)
	await _wait(1.5)
	var rv = ChuninExam.rivals.filter(func(r): return is_instance_valid(r) and not r.is_dead())
	for m in ChuninExam.team:
		m.global_position = tc2 + Vector3(3, 0.5, 0)
	for sec in 25:
		var line = "T%02d " % sec
		for m in ChuninExam.team:
			line += "%s hp=%d tgt=%s st=%s | " % [m.display_name, int(m.hp), (m.target.display_name if m.target and is_instance_valid(m.target) else "-"), m.state]
		for r in rv:
			if is_instance_valid(r):
				line += "R:%d%s " % [int(r.hp), "x" if r.is_dead() else ""]
		print(line)
		pl.hp = 1e9
		await _wait(1.0)
	get_tree().quit()
