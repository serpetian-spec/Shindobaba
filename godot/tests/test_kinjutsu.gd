extends Node
var main: Node
func _w(t): await get_tree().create_timer(t).timeout
func _foe(pos, team := "enemy") -> Enemy:
	var e := Enemy.new()
	e.setup(Enemy.archetype("rogue", 1))
	main.actors.add_child(e)
	e.global_position = pos
	e.home = pos
	e.team = team
	e.set_physics_process(false)
	return e
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(1.5)
	Hud.close_dialog()
	var pl = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 600, vs["y"])))
	await _w(1.0)
	# 1) simsar listesi
	Game.profile["flags"]["rogue"] = true
	Game.profile["level"] = 200
	Orgs.flags()["infamy"] = 99999
	Orgs._kinjutsu_dialog()
	await _w(0.2)
	var btns := []
	var stack = [Hud.dialog_layer]
	while not stack.is_empty():
		var nd = stack.pop_back()
		if nd is Button:
			btns.append(nd.text)
		elif nd is Label:
			btns.append(nd.text)
		for ch in nd.get_children():
			stack.append(ch)
	var all = " ".join(btns)
	var txt = ""
	for k in ["gedo_rinne_tensei_no_jutsu", "chi_no_juin", "fushi_tensei", "shihohappo_shuriken", "taju_kage_bunshin_no_jutsu", "shiki_fujin"]:
		txt += "%s=%s " % [k, String(Data.jutsu[k]["name"]) in all]
	print("KIN simsar diyalog: ", Hud.last_dialog.substr(0, 40), " | ", txt)
	Hud.close_dialog()
	Game.profile["flags"]["rogue"] = false
	# 2) Kishō Tensei — düşen dost yok
	pl.combat.cooldowns["kisho_tensei"] = 99.0
	pl.combat.cooldowns.erase("kisho_tensei")
	pl.combat.cooldowns["kisho_tensei"] = 88.0
	Jutsu.execute(pl, "kisho_tensei", null)
	await _w(0.3)
	print("KIN kisho dostsuz: cd iade=%s" % (not pl.combat.cooldowns.has("kisho_tensei")))
	# düşen dost
	var ally = _foe(pl.global_position + Vector3(3, 0, 0), "player")
	ally.set_meta("teammate", true)
	ally.set_physics_process(true)
	await _w(0.2)
	ally.take_hit({"dmg": 1e9, "kind": "heavy", "attacker": null})
	await _w(0.5)
	var nf = Enemy.fallen.size()
	pl.hp = pl.max_hp
	Jutsu.execute(pl, "kisho_tensei", null)
	await _w(2.0)
	var revived = get_tree().get_nodes_in_group("fighters").filter(func(f): return f is Enemy and f.team == "player" and not f.dead).size()
	print("KIN kisho: düşen=%d dirilen=%d oyuncu can=%.0f iyileşemez=%s" % [nf, revived, pl.hp, Buffs.has("rinne_bedel")])
	Buffs.remove("rinne_bedel")
	pl.hp = pl.max_hp
	# 3) Shiki Fūjin
	var foe = _foe(pl.global_position + Vector3(0, 0, -5))
	foe.max_hp = 5000; foe.hp = 5000
	Jutsu.execute(pl, "shiki_fujin", foe)
	await _w(2.5)
	print("KIN shiki: hedef öldü=%s oyuncu can=%.0f bedel=%s" % [not is_instance_valid(foe) or foe.dead, pl.hp, Buffs.has("rinne_bedel")])
	print("KIN sozo cd=%s" % str(Data.jutsu["sozo_saisei"]["cd"]))
	get_tree().quit()
