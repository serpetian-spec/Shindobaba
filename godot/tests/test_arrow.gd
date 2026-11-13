extends Node
## Hedef oku her görev türünün her adımında gerçek nesneyi gösteriyor mu.
## Her adım: ok nerede, o adımın gerçek nesneleri ([F] noktası / kişi / düşman / toplanacak eşya) nerede, en yakınına kaç metre.
## AR_ONLY=kelime (başlıkta geçen) ile tek görev
var main: Node
var bad := 0
var rows := 0


func _state() -> Dictionary:
	return {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _measure(tag: String) -> void:
	var m = Missions.active()
	if m.is_empty():
		return
	var s = Missions._cur()
	var mk: Vector3 = Missions.target_marker
	var k = Missions._key()
	var its = Interact.items.filter(func(it): return it.get("kind", "") == "quest" and it.get("qkey", "") == k)
	var src = "F"
	var pts = []
	for it in its:
		pts.append(it["pos"])
	if s["kind"] == "cat" and Missions.st.has("cat") and is_instance_valid(Missions.st["cat"]):
		src = "kedi"
		pts = [Missions.st["cat"].global_position]
	if String(s.get("work", "")) == "hunt" and is_instance_valid(MissionWork.inst):
		src = "av"
		pts = []
		for p in MissionWork.inst.hunt_d.get("prey", []):
			if is_instance_valid(p):
				pts.append(p.global_position)
	if s["kind"] == "goto":
		src = "yer"
		pts = [Missions._w(s["at"])]
	if pts.is_empty():
		src = "kişi"
		var id = s.get("npc_id", s.get("npc", {}).get("id", "") if s.get("npc") is Dictionary else "")
		var n = Missions.npcs.get(id)
		if is_instance_valid(n):
			pts.append(n.global_position)
	if pts.is_empty():
		src = "düşman/eşya"
		for e in Missions.step_nodes:
			if is_instance_valid(e) and ((e is Enemy and not e.dead) or e is Pickup or e is Prey):
				pts.append(e.global_position)
		for e in Missions.pickups:
			if is_instance_valid(e):
				pts.append(e.global_position)
	if pts.is_empty():
		src = "yapı"
		for e in Missions.step_nodes:
			if is_instance_valid(e) and e is Node3D and not e.has_meta("ui_mark"):
				pts.append(e.global_position)
	var best = 1e9
	for p in pts:
		best = minf(best, _flat(p, mk))
	var verdict = "TAMAM"
	if pts.is_empty():
		verdict = "nesne yok (yer hedefi)"
	elif best > 6.0:
		verdict = "YANLIŞ"
		bad += 1
	rows += 1
	print("AR %-8s | %-34s | adım %d/%d %-8s %-8s | ok adı: %-26s | nesne: %-11s x%d | okla arası %s m | %s" % [tag, String(m["title"]).left(34), int(m["step"]) + 1, m["steps"].size(), s["kind"], String(s.get("work", "-")),
		String(Missions.target_name).left(26), src, pts.size(), ("%.1f" % best) if not pts.is_empty() else "-", verdict])


func _run(m: Dictionary, tag: String) -> void:
	if m.is_empty():
		print("AR %s boş" % tag)
		return
	var only = OS.get_environment("AR_ONLY")
	if only != "" and String(m.get("title", "")).findn(only) < 0 and tag.findn(only) < 0:
		return
	if not Missions.active().is_empty():
		Missions.abandon()
		await get_tree().create_timer(0.4).timeout
	m["type"] = "quest"
	if not m.has("village"):
		m["village"] = "konoha"
	if not m.has("giver"):
		m["giver"] = "Test"
	Missions.accept(m)
	await get_tree().create_timer(0.5).timeout
	var guard = 0
	while not Missions.active().is_empty() and guard < 14:
		guard += 1
		var s = Missions._cur()
		var at: Vector3 = Missions._w(s["at"]) if s.has("at") else Missions.target_marker
		at.y = Game.ground_height(at.x, at.z)
		main.player.respawn(at + Vector3(9, 0.5, 9))
		main.player.hp = main.player.max_hp
		await get_tree().create_timer(1.6).timeout
		if Missions.active().is_empty() or Missions._cur() != s:
			continue   # adım kendiliğinden ilerledi
		_measure(tag)
		Hud.close_dialog()
		Missions._next_step()
		await get_tree().create_timer(0.4).timeout
	if not Missions.active().is_empty():
		Missions.abandon()
	await get_tree().create_timer(0.3).timeout


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = _state()
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	Game.profile["rank"] = 3
	Game.profile["level"] = 60
	Missions.board_village = "konoha"
	# 1) el yazımı görevler
	for q in ["_q_cat", "_q_weeds", "_q_fence", "_q_babysit", "_q_investigate", "_q_border", "_q_hunt", "_q_guard", "_q_relay", "_q_fish", "_q_repair", "_q_build", "_q_teach", "_q_stealth", "_q_chase", "_q_rescue", "_q_sabotage"]:
		var m: Dictionary = Missions.call(q, "konoha")
		m["rank"] = m.get("rank", "C")
		await _run(m, "köy")
	for q in [["_q_herbs", false], ["_q_herbs", true], ["_q_escort", "C"], ["_q_track", "A"], ["_q_defend", "B"]]:
		var m2: Dictionary = Missions.call(q[0], "konoha", q[1])
		m2["rank"] = m2.get("rank", "C")
		await _run(m2, "köy")
	# 2) pano üreteci: her kalıp + iş türünden birer tane
	var seen = {}
	for k in 6:
		for sp in MissionGen.specs("konoha", ["D", "C", "B", "A", "S"], 40):
			var sig = "%s/%s" % [sp.get("p", ""), sp["r"]]
			if seen.has(sig):
				continue
			seen[sig] = true
			var gm: Dictionary = Missions._from_spec("konoha", sp)
			gm["rank"] = sp["r"]
			await _run(gm, "pano")
	# 3) kaçak işleri
	Game.profile["rogue"] = true
	await _run(RogueJobs.job_poach("C"), "kaçak")
	await _run(RogueJobs.job_heist("C"), "kaçak")
	await _run(RogueJobs.job_smuggle("C"), "kaçak")
	await _run(RogueJobs.job_jail("C"), "kaçak")
	await _run(RogueJobs.job_decoy("C"), "kaçak")
	await _run(RogueJobs.job_fence(), "kaçak")
	await _run(RogueJobs.job_hut(), "kaçak")
	print("AR ÖZET satır=%d yanlış=%d kalıp=%d" % [rows, bad, seen.size()])
	get_tree().quit()
