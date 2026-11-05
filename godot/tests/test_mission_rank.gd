extends Node
## B/A/S görev düşmanları: sayı, can, seviye, güç; Güç 46 oyuncuya karşı kısa dövüş benzetimi (oyuncuya verilen hasar / sn)

var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "akimichi", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pr = Game.profile
	pr["mastery"] = {"chakra": 30.0, "dayaniklilik": 15.0, "hiz": 8.0, "kenjutsu": 11.4, "ninjutsu": 35.0, "taijutsu": 60.0}
	Mastery.refresh_level(pr)
	pr["rank"] = 4
	var pl: Player = main.player
	pl.max_hp = Stats.max_hp(pr)
	pl.hp = pl.max_hp
	print("PLAYER guc=", pr["level"], " hp=", pl.max_hp, " melee=", Stats.melee_mult(pr))
	await _wait(1.0)
	for rk in ["B", "A", "S"]:
		pr["rank"] = 2 if rk == "B" else 4
		var cands = []
		for k in 40:
			for m in Missions.board_missions("konoha", true):
				if String(m.get("rank", "")) == rk and (m.get("steps", []) as Array).any(func(st): return String(st.get("kind", "")) == "kill"):
					cands.append(m)
			if not cands.is_empty():
				break
		if cands.is_empty():
			print("RANK ", rk, " kill görevi bulunamadı")
			continue
		var m = cands[0]
		# öldürme adımına atla
		var steps: Array = m["steps"]
		var ki = 0
		for i in steps.size():
			if String(steps[i].get("kind", "")) == "kill":
				ki = i
				break
		m["steps"] = steps.slice(ki)
		Missions.accept(m)
		await _wait(1.5)
		var c: Vector3 = Missions.target_marker
		pl.respawn(c + Vector3(8, 1, 0))
		pl.max_hp = Stats.max_hp(pr)
		pl.hp = pl.max_hp
		await _wait(3.0)
		var es = Missions.step_nodes.filter(func(e): return is_instance_valid(e) and e is Enemy and not e.dead)
		if es.is_empty():   # mağara ini: içeri girilince doğarlar
			Missions.lair_room(pl.global_position + Vector3(0, 0, 30))
			await _wait(1.0)
			es = Missions.step_nodes.filter(func(e): return is_instance_valid(e) and e is Enemy and not e.dead)
			for e in es:
				e.global_position = pl.global_position + Vector3(randf_range(-4, 4), 0, 5)
		var line = "RANK %s '%s' enemies=%d" % [rk, m.get("title", ""), es.size()]
		for e in es:
			line += " [%s lv%d hp%d pw%.2f]" % [e.display_name.left(14), e.level, int(e.max_hp), e.power]
		print(line)
		# 10 sn dövüş: oyuncu ölmesin diye can sınırı yok, alınan hasarı ölç
		var h0 = pl.hp
		pl.max_hp = 1e7
		pl.hp = 1e7
		for e in es:
			e.target = pl
		await _wait(10.0)
		print("RANK %s dps_to_player=%.1f (oyuncu canı %d -> ~%.0f sn dayanır)" % [rk, (1e7 - pl.hp) / 10.0, int(Stats.max_hp(pr)), Stats.max_hp(pr) / maxf(1.0, (1e7 - pl.hp) / 10.0)])
		Missions.abandon() if Missions.has_method("abandon") else null
		for e in es:
			if is_instance_valid(e):
				e.queue_free()
		Game.profile["active_mission"] = {}
		await _wait(1.0)
	get_tree().quit()
