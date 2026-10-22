extends Node
## Görev + köy seçimi testi: Suna'da yeni oyun, birkaç görev türünü kabul edip adım adım tamamlar, Bingo Kitabı, Kiri'de başlangıç.
var main: Node


func _state(vid: String) -> Dictionary:
	return {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "fuuton", "village": vid, "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}


func _cam(pl, yaw: float, pitch: float, dist: float) -> void:
	pl.yaw = yaw
	pl.pitch = pitch
	pl.cam_dist = dist


func _tp(p: Vector3) -> void:
	main.player.respawn(p + Vector3(0, 0.5, 0))
	await get_tree().create_timer(0.4).timeout


func _face(target: Vector3) -> void:
	var pl = main.player
	var d = target - pl.global_position
	pl.yaw = rad_to_deg(atan2(-d.x, -d.z))


func _run_steps(m: Dictionary, shots: String, max_steps := 12) -> void:
	Missions.accept(m)
	await get_tree().create_timer(0.6).timeout
	var guard = 0
	while not Missions.active().is_empty() and guard < max_steps:
		guard += 1
		var a = Missions.active()
		var s = Missions._cur()
		print("  adım %d/%d [%s] %s" % [int(a["step"]) + 1, a["count"], s["kind"], s["text"]])
		var tgt: Vector3 = Missions.target_marker
		match s["kind"]:
			"goto":
				await _tp(tgt + Vector3(1, 0, 1))
				for k in Missions.npcs:
					var fn = Missions.npcs[k]
					if is_instance_valid(fn) and fn.mode == "follow":
						fn.global_position = tgt + Vector3(3, 0, 2)
				await get_tree().create_timer(0.4).timeout
			"talk":
				var id = s.get("npc_id", s.get("npc", {}).get("id", ""))
				var npc = Missions.npcs.get(id)
				await _tp(npc.global_position + Vector3(2, 0, 2))
				_face(npc.global_position)
				main.player.pitch = -8
				main.player.cam_dist = 4.0
				Missions.on_quest_talk(npc)
				await get_tree().create_timer(0.5).timeout
				if shots != "":
					await main.shot("%s_talk%d" % [shots, int(a["step"])])
				Hud.close_dialog()
				if s.get("choices", []).size() > 0:
					for c in s["choices"]:
						if c.get("ok", true):
							pass
				Missions._after_talk(npc, s)
			"kill", "collect", "points", "stealth", "defend", "chase":
				await _tp(tgt + Vector3(6, 0, 6))
				_face(tgt)
				main.player.pitch = -18
				main.player.cam_dist = 9.0
				await get_tree().create_timer(1.2).timeout
				if shots != "":
					await main.shot("%s_%s%d" % [shots, s["kind"], int(a["step"])])
				if s["kind"] == "collect":
					for n in Missions.step_nodes.duplicate():
						if is_instance_valid(n) and n is Pickup and Missions._cur() == s:
							Missions.on_pickup(n.item)
				elif s["kind"] == "points" or s["kind"] == "stealth":
					for it in Interact.items.duplicate():
						if it.get("kind", "") == "quest" and Missions._cur() == s:
							Missions.on_interact(it)
				elif s["kind"] == "defend":
					for w in 6:
						await get_tree().create_timer(3.5).timeout
						for e in (Missions.st.get("alive", []) as Array).duplicate():
							if is_instance_valid(e) and not e.dead:
								e.hp = 0
								e.die({})
						if Missions._cur() != s:
							break
				else:
					for e in Missions.step_nodes.duplicate():
						if is_instance_valid(e) and e is Enemy and not e.dead and Missions._cur() == s:
							e.hp = 0
							e.die({})
				await get_tree().create_timer(0.3).timeout
			"escort":
				var npc = Missions.npcs.get(s["npc_id"])
				await _tp(npc.global_position + Vector3(3, 0, 3))
				await get_tree().create_timer(1.5).timeout
				if shots != "":
					await main.shot("%s_escort" % shots)
				npc.path_i = npc.path.size()
				await get_tree().create_timer(0.3).timeout
			"track":
				await _tp(Missions.st["prints"][0])
				_face(Missions.st["prints"][3])
				main.player.pitch = -25
				main.player.cam_dist = 6.0
				await get_tree().create_timer(0.8).timeout
				if shots != "":
					await main.shot("%s_track" % shots)
				Missions.st["idx"] = Missions.st["prints"].size()
				await get_tree().create_timer(0.3).timeout
			"babysit":
				Missions.st["t"] = 999.0
				await get_tree().create_timer(0.3).timeout
			"cat":
				Missions.on_cat_caught()
			_:
				Missions._next_step()
	print("  sonuç: aktif görev boş mu = ", Missions.active().is_empty(), "  ryo=", Game.profile["ryo"])


func _ready() -> void:
	await get_tree().process_frame
	# ---- Suna'da yeni oyun
	main.creator_state = _state("suna")
	main._start_new_game()
	var pl = main.player
	Game.world.env.time_of_day = 0.42
	await get_tree().create_timer(3.0).timeout
	print("KÖY=", Progress.home(), " hikâye: ", Progress.STORY[0])
	var t0 = Missions.story_target_for(0)
	print("hikâye hedefi 0: ", t0)
	_cam(pl, pl.yaw, -10, 7.0)
	if not t0.is_empty():
		_face(t0["pos"])
	await get_tree().create_timer(0.8).timeout
	await main.shot("q0_suna_baslangic")
	for k in [4, 5, 7, 8, 13]:
		print("hikâye hedefi %d: %s" % [k, Missions.story_target_for(k)])
	# akademi yerleşkesi
	if not t0.is_empty():
		await _tp(t0["pos"] + Vector3(-12, 0, -22))
		_face(t0["pos"])
		pl.pitch = -6
		pl.cam_dist = 12.0
		await get_tree().create_timer(1.0).timeout
		await main.shot("q1_suna_akademi")
	# ---- görevler (Suna masası)
	Game.profile["rank"] = 3
	Game.profile["level"] = 25
	Missions.board_village = "suna"
	for spec in [["_q_fence", "D"], ["_q_investigate", "C"], ["_q_escort", "C"], ["_q_track", "A"], ["_q_stealth", "B"], ["_q_chase", "B"], ["_q_rescue", "B"], ["_q_defend", "B"], ["_q_border", "C"], ["_q_sabotage", "B"], ["_q_babysit", "D"]]:
		var m: Dictionary = Missions.call(spec[0], "suna") if spec[0] not in ["_q_escort", "_q_track", "_q_defend"] else Missions.call(spec[0], "suna", spec[1])
		m["rank"] = spec[1]
		m["village"] = "suna"
		m["type"] = "quest"
		if not m.has("giver"):
			m["giver"] = "Test"
		print("GÖREV: ", m["title"])
		var sh = ""
		if spec[0] in ["_q_investigate", "_q_stealth", "_q_track", "_q_escort", "_q_chase"]:
			sh = "q_" + spec[0].substr(3)
		await _run_steps(m, sh)
	# ---- köye özgü görev masaları
	for vid in ["konoha", "suna", "kiri", "kumo", "iwa", "ame", "nami", "taki", "yu", "tetsu"]:
		if Game.village(vid).is_empty():
			continue
		var lst = Missions.board_missions(vid, true)
		print("MASA %s (itibar %d, limit %s): %s" % [vid, Missions.rep(vid), Missions.board_limits(vid)["max"], ", ".join(lst.map(func(x): return "[%s]%s%s" % [x["rank"], "★" if x.get("local", false) else "", x["title"]]))])
	Game.profile["rep"]["kiri"] = 80
	var kl = Missions.board_missions("kiri", true).filter(func(x): return x.get("local", false))
	if not kl.is_empty():
		print("YEREL GÖREV: ", kl[0]["title"])
		await _run_steps(kl[0], "q_yerel")
	var sl = MissionLocal.POOL["suna"].filter(func(x): return x["p"] == "escort")
	if not sl.is_empty():
		var sm = Missions._from_spec("suna", sl[0])
		print("YEREL GÖREV: ", sm["title"])
		await _run_steps(sm, "")
	var dl = MissionLocal.POOL["tetsu"].filter(func(x): return x["p"] == "duel")
	if not dl.is_empty():
		var dm = Missions._from_spec("tetsu", dl[0])
		print("YEREL GÖREV: ", dm["title"])
		await _run_steps(dm, "q_duello")
	# ---- görev masası diyaloğu
	var mb = {}
	for it in Interact.items:
		if it["kind"] == "mission_board" and Game.to_map(it["pos"]).distance_to(Vector2(Game.village("suna")["x"], Game.village("suna")["y"])) < 300:
			mb = it
	if not mb.is_empty():
		Missions.open_board(mb)
		await get_tree().create_timer(0.4).timeout
		await main.shot("q2_gorev_masasi")
		Hud.close_dialog()
	# ---- Bingo Kitabı
	for i in 3:
		Missions._bingo_tick(1.0)
	Missions.open_bingo_dialog()
	await get_tree().create_timer(0.4).timeout
	await main.shot("q3_bingo")
	Hud.close_dialog()
	var ents = Missions.bingo_entries()
	print("BINGO: %d girdi; ilk: %s «%s» %s %d Ryō, bölge=%s" % [ents.size(), ents[0]["name"], ents[0]["alias"], ents[0]["rank"], ents[0]["bounty"], ents[0]["region"]])
	var e0 = ents[0]
	Missions._bingo_detail(int(e0["id"]))
	await get_tree().create_timer(0.4).timeout
	await main.shot("q4_bingo_detay")
	Hud.close_dialog()
	Missions.track_bounty(int(e0["id"]))
	await get_tree().create_timer(0.5).timeout
	print("takip işareti: ", Missions.has_marker, " ", Missions.target_name)
	var hide = Game.from_map(Vector2(e0["hide"][0], e0["hide"][1]))
	await _tp(hide + Vector3(14, 0, 14))
	_face(hide)
	pl.pitch = -12
	pl.cam_dist = 8.0
	await get_tree().create_timer(2.0).timeout
	await main.shot("q5_aranan_kamp")
	var sp = Missions._bb_spawned.get(int(e0["id"]))
	print("aranan doğdu: ", sp != null)
	if sp != null:
		var boss = sp[0]
		boss.hp = boss.max_hp * 0.25
		await get_tree().create_timer(1.0).timeout
		print("kaçtı mı: ", boss.get_meta("fled", false) if e0["rank"] != "C" else "C-rank kaçmaz")
		var before = int(Game.profile["ryo"])
		boss.hp = 0
		boss.die({})
		await get_tree().create_timer(0.5).timeout
		print("ödül: +", int(Game.profile["ryo"]) - before, " durum: ", Missions.bingo_entries().filter(func(x): return int(x["id"]) == int(e0["id"]))[0]["status"])
	# ---- Kiri'de yeni oyun
	Game.profile = {}
	main.player.queue_free()
	main.player = null
	Game.player = null
	await get_tree().process_frame
	main.creator_state = _state("kiri")
	main._start_new_game()
	pl = main.player
	await get_tree().create_timer(3.0).timeout
	print("KÖY=", Progress.home(), " hikâye: ", Progress.STORY[0], " | ", Progress.STORY[6])
	var k0 = Missions.story_target_for(0)
	print("Kiri akademi hedefi: ", k0)
	if not k0.is_empty():
		_face(k0["pos"])
	pl.pitch = -10
	pl.cam_dist = 7.0
	await get_tree().create_timer(0.8).timeout
	await main.shot("q6_kiri_baslangic")
	get_tree().quit()
