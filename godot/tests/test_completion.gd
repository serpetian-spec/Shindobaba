extends Node
## Oynanış tamamlama testi: yetenek etkileri, ipli kunai + duvar atılımı, klan dışı kekkei genkai yolları
var main: Node


func _ok(name: String, cond: bool, extra := "") -> void:
	print("%s %s %s" % ["OK  " if cond else "FAIL", name, extra])


func _site(kind: String) -> Dictionary:
	for it in Interact.items:
		if it.get("kind", "") == "kg_site" and it.get("site", "") == kind:
			return it
	return {}


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "suiton", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	var pl = main.player
	var pr = Game.profile
	pr["level"] = 80
	pr["rank"] = 3
	await get_tree().create_timer(2.0).timeout

	# ---------------- 1) yetenek etkileri
	var r0 = Stats.sense_radius(pr)
	pr["skills"].append_array(["shi_hiss1", "shi_hiss2", "shi_gizli1", "shi_gizli2", "sum1", "sum2", "sage1", "tai_kombo1", "tai_kombo2",
		"kg1", "fuin_master", "gen_guc1", "gen_kai", "fuin_depo", "lid1", "lid_itibar", "gates1"])
	_ok("sense", Stats.sense_radius(pr) > r0, "%d -> %d m" % [int(r0), int(Stats.sense_radius(pr))])
	_ok("stealth", Stats.skill(pr, "stealth") > 0.5, str(Stats.skill(pr, "stealth")))
	_ok("carry", Stats.carry_cap(pr, "salve") > 10, "salve cap %d" % Stats.carry_cap(pr, "salve"))
	_ok("kg power", Stats.jutsu_cat_mult(pr, "ninjutsu", "hyoton") > 1.2, str(Stats.jutsu_cat_mult(pr, "ninjutsu", "hyoton")))
	_ok("gen power", Stats.jutsu_cat_mult(pr, "genjutsu", "") > 1.1, str(Stats.jutsu_cat_mult(pr, "genjutsu", "")))
	var c0 = pl.combat._combo_base(1)
	var c1 = pl.combat._combo(1)
	_ok("combo", float(c1["dur"]) < float(c0["dur"]) and float(c1["dmg"]) > float(c0["dmg"]), "dur %.2f->%.2f dmg %.1f->%.1f" % [c0["dur"], c1["dur"], c0["dmg"], c1["dmg"]])
	# genjutsu direnci + Kai
	pl.apply_status("stun", 4.0)
	_ok("gen resist", float(pl.statuses.get("stun", 0.0)) < 4.0, "stun %.2f" % pl.statuses.get("stun", 0.0))
	var ev = InputEventAction.new()
	ev.action = "substitute"
	ev.pressed = true
	pl._unhandled_input(ev)
	_ok("kai", not pl.has_status("stun"))
	# arkadan saldırı
	var e = Enemy.new()
	main.actors.add_child(e)
	e.global_position = pl.global_position + pl.face_dir() * 2.0
	await get_tree().process_frame
	e.target = null
	var hp0 = e.hp
	e.take_hit({"dmg": 10.0, "attacker": pl, "dir": pl.face_dir(), "kind": "light"})
	_ok("backstab", hp0 - e.hp > 10.5, "hasar %.1f" % (hp0 - e.hp))
	e.queue_free()
	# itibar
	var rep0 = int(pr.get("rep", {}).get("konoha", 0))
	Missions._rep("konoha", 10)
	_ok("rep", int(pr["rep"]["konoha"]) - rep0 > 10, "+%d" % (int(pr["rep"]["konoha"]) - rep0))

	# ---------------- 2) ipli kunai + duvar atılımı
	Hud.show_game_hud(false)
	var v = Game.village("konoha")
	var start = Game.from_map(Vector2(v["x"] + 60, v["y"] - 300))
	pl.respawn(start + Vector3(0, 14, 0))
	pl.yaw = 0.0
	pl.pitch = 8.0
	pl.cam_dist = 7.0
	await get_tree().create_timer(0.3).timeout
	pl.grounded = false
	var a0 = pl.global_position
	var ok_rope = false
	for yaw in [0.0, 90.0, 180.0, 270.0, 45.0, 135.0, 225.0, 315.0]:
		pl.yaw = yaw
		await get_tree().process_frame
		pl.grounded = false
		pl.rope_ok = true
		if pl.rope_kunai():
			ok_rope = true
			break
	_ok("rope fire", ok_rope, "nokta %s" % str(pl.rope_pt))
	await get_tree().create_timer(0.25).timeout
	await main.shot("cp1_ipli_kunai")
	for i in 120:
		await get_tree().physics_frame
		if pl.rope_t < 0.0:
			break
	_ok("rope pull", pl.global_position.distance_to(a0) > 4.0, "%.1f m" % pl.global_position.distance_to(a0))
	_ok("rope once", not pl.rope_ok)
	pl.wall_n = Vector3(0, 0, 1)
	pl.chakra = 100.0
	pl._wall_boost()
	_ok("wall boost", pl.wall_boost_t > 0.0 and pl.chakra < 100.0)
	pl._leave_wall()
	pl.wall_boost_t = -1.0

	# ---------------- 3) kekkei genkai yolları
	pr["elements"] = ["suiton", "fuuton", "katon", "doton"]
	pr["missions_done"]["S"] = 1
	# eğitmen: iki doğadan 2'şer jutsu
	var have = {"suiton": 0, "katon": 0}
	for jid in Data.jutsu:
		if String(jid).begins_with("_") or not Data.jutsu[jid] is Dictionary:
			continue
		var j: Dictionary = Data.jutsu[jid]
		var el = String(j.get("element", ""))
		if have.has(el) and have[el] < 2:
			pr["learned"].append(jid)
			have[el] += 1
	var topts = KgPaths.trainer_options()
	var labels = topts.map(func(o): return o["label"])
	_ok("trainer futton", labels.any(func(l): return String(l).contains("Futton") and not String(l).contains("gerekli")), str(labels))
	for kind in ["hermit", "volcano", "dust"]:
		var it = _site(kind)
		_ok("site " + kind, not it.is_empty())
		if it.is_empty():
			continue
		pl.respawn(it["pos"] + Vector3(0, 1, 6))
		pl.yaw = 0.0
		pl.pitch = -10.0
		pl.cam_dist = 14.0
		await get_tree().create_timer(4.0).timeout
		await main.shot("cp_site_" + kind)
		Hud.close_dialog()
		KgPaths.interact_site(it)
		var nat = KgPaths.SITES[kind]["nature"]
		var q = KgPaths.site_quest(kind, [Game.to_map(it["pos"]).x, Game.to_map(it["pos"]).y])
		Hud.close_dialog()
		Missions.accept(q)
		await get_tree().create_timer(0.5).timeout
		Missions.complete()
		await get_tree().create_timer(0.3).timeout
		_ok("awaken " + nat, Progress.has_nature(nat))
	print("natures: ", pr.get("natures", []))
	get_tree().quit()
