extends Node
## NPC dengesi: kaçak S iken yol jōnin'i / köy muhafızı / köy jōnin takımı / ANBU / av-ninjası can-güç; kaçan dostun kıyafeti
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	Game.profile["flags"]["rogue"] = true
	print("BAL OYUNCU Güç63 can=%.0f" % Stats.ninja_hp(63))
	Orgs.flags()["infamy"] = 2500
	var rows = []
	# yol jōnin'i (ambient takım saldırısı yolu)
	var at = get_tree().current_scene.find_child("AmbientTeams", true, false)
	for rk in [1, 2]:
		var a = Orgs._village_arch("konoha", 0, "jonin" if rk >= 2 else "chunin")
		Stats.npc_ninja(a, [15, 35, 60][rk] + 5)
		rows.append(["yol " + ["genin", "chunin", "jonin"][rk], a])
	for w in Orgs.RAID_WAVES:
		var a = Orgs._village_arch("konoha", 0, "jonin")
		Stats.npc_ninja(a, 40 + int(w["lv"]) * 5 + Orgs.rogue_rank() * 3, float(w["hp"]))
		rows.append(["baskın " + String(w["title"]), a])
	var ah = Enemy.archetype("rogue", 0)
	Stats.npc_ninja(ah, 77 + Orgs.rogue_rank() * 4, 1.35)
	rows.append(["av-ninjası", ah])
	for rk in ["C", "B", "A", "S"]:
		var lvb = {"C": 22, "B": 47, "A": 90, "S": 150}[rk]
		var ab = Enemy.archetype("rogue", 0)
		Stats.npc_ninja(ab, lvb, {"C": 1.15, "B": 1.3, "A": 1.5, "S": 1.8}[rk])
		ab["skill"] = clampf(0.2 + lvb * 0.009, 0.3, 0.9)
		rows.append(["bingo " + rk, ab])
	var bd = Enemy.archetype("bandit", 0)
	bd["level"] = 15
	bd["hp"] = float(bd["hp"]) * (1.0 + 15 * 0.04)
	bd["power"] = float(bd["power"]) * (1.0 + 15 * 0.015)
	rows.append(["haydut (yol)", bd])
	for r in rows:
		var e = Enemy.new()
		e.setup(r[1])
		print("BAL %-28s Güç=%d can=%.0f güç=%.2f skill=%.2f" % [r[0], e.level, e.max_hp, e.power, e.skill])
		e.free()
	get_tree().quit()
