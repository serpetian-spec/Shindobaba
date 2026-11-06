extends Node
## Yol takımları: konuşma seçenekleri, dostça düello (pes etme + dost), saldırı (düşman + suç), kaçakken tanıyıp saldırma
var main: Node
var AT

func _team_near(pl) -> Dictionary:
	AT.teams.clear()
	AT._spawn(pl.global_position)
	await get_tree().create_timer(0.5).timeout
	if AT.teams.is_empty():
		return {}
	var tm = AT.teams[-1]
	var i = 0
	for n in tm["nodes"]:
		n.global_position = pl.global_position + Vector3(3 + i, 0, 3)
		n.goal = n.global_position
		i += 1
	await get_tree().create_timer(0.3).timeout
	return tm

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.5).timeout
	Hud.close_dialog()
	AT = main.actors.get_node("AmbientTeams")
	var pl = main.player
	pl.max_hp = 1e9; pl.hp = 1e9
	var vs = Game.village("konoha")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 300, vs["y"])))
	await get_tree().create_timer(2.0).timeout
	# kanon ad var mı
	var canon = 0
	for vid in Game.profile.get("vteams", {}):
		for tm0 in Game.profile["vteams"][vid]:
			for pe in tm0["people"]:
				if String(pe["name"]) in AT.CANON:
					canon += 1
	# 1) konuşma
	var tm = await _team_near(pl)
	var n = tm["nodes"][1]
	n.on_talk.call(n)
	await get_tree().create_timer(0.2).timeout
	print("AMB kanon_ad=%d  konuşma: %s" % [canon, Hud.last_dialog.substr(0, 50)])
	# 2) düello
	var vt = n.get_meta("vt")
	var person = AT.roster(String(vt[0]))[int(vt[1])]["people"][int(vt[2])]
	var nfr = Friends.all().size()
	AT._spar(n, person, String(vt[0]))
	await get_tree().create_timer(0.4).timeout
	var duelist = null
	for f in get_tree().get_nodes_in_group("fighters"):
		if f is Enemy and String(f.display_name).ends_with("(düello)"):
			duelist = f
	print("AMB düello başladı=%s" % (duelist != null))
	if duelist:
		duelist.hp = duelist.max_hp * 0.2
		await get_tree().create_timer(2.5).timeout
		print("AMB düello pes etti=%s  yeni dost=%s  npc tekrar görünür=%s" % [not is_instance_valid(duelist) or duelist.dead, Friends.all().size() > nfr, is_instance_valid(n) and n.visible])
	Hud.close_dialog()
	# 3) saldırı
	var h0 = Crime.heat()
	tm = await _team_near(pl)
	var cnt = tm["nodes"].size()
	AT._team_attack(tm, true)
	await get_tree().create_timer(0.5).timeout
	var hl = get_tree().get_nodes_in_group("fighters").filter(func(f): return f is Enemy and f.team == "enemy" and f.target == pl and not f.dead)
	var hostile = hl.size()
	print("   düşmanlar: ", hl.map(func(f): return "%s@%.0fm" % [f.display_name, f.global_position.distance_to(pl.global_position)]))
	print("AMB saldırı: takım=%d düşmana dönen=%d suç %d->%d" % [cnt, hostile, h0, Crime.heat()])
	for f in get_tree().get_nodes_in_group("fighters"):
		if f is Enemy and f.team == "enemy":
			f.queue_free()
	await get_tree().create_timer(0.3).timeout
	# 4) kaçakken tanıyıp saldırır
	Game.profile["flags"]["rogue"] = true
	tm = await _team_near(pl)
	await get_tree().create_timer(0.5).timeout
	print("AMB kaçak: takım düşman oldu=%s" % tm.get("hostile", false))
	get_tree().quit()
