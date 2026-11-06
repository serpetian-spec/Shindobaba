extends Node
## Efsane Yolu jutsu gücü: her yol jutsusunu tek dayanıklı hedefe at, 4 sn'deki gerçek hasarı ölç;
## aynı kanon rütbesindeki genel element jutsularının ortalamasıyla kıyasla (oran > 1.6 => fazla güçlü)
var main: Node

func _foe(pos: Vector3) -> Enemy:
	var e := Enemy.new()
	e.setup(Enemy.archetype("rogue", 1))
	main.actors.add_child(e)
	e.global_position = pos
	e.home = pos
	e.max_hp = 1e7
	e.hp = 1e7
	e.set_physics_process(false)
	return e

func _dmg(pl, id: String, base: Vector3) -> float:
	var f = _foe(base + Vector3(0, 0, -7))
	pl.global_position = base
	pl.facing = 0.0
	pl.combat.cooldowns.erase(id)
	pl.combat.action = ""
	await get_tree().create_timer(0.15).timeout
	var h0 = f.hp
	var before := {}
	for ch in get_tree().current_scene.get_children():
		before[ch] = true
	Jutsu.execute(pl, id, f)
	await get_tree().create_timer(4.0).timeout
	var d = h0 - f.hp
	for n in get_tree().current_scene.get_children():
		if n is Projectile or n is ShadowClone or n is Summon:
			n.queue_free()
	for ch in get_tree().current_scene.get_children():   # jutsunun sahneye eklediği her şey (kapı, baş, alan, kukla) silinir: sonraki ölçümü kirletmesin
		if not before.has(ch) and ch != pl:
			ch.queue_free()
	for f2 in get_tree().get_nodes_in_group("fighters"):   # kuklalar, çağrılar, Edo savaşçıları: sonraki ölçüme saldırmasın
		if f2 != pl and is_instance_valid(f2) and (f2.get("team") == "player" or f2 is ShadowClone or f2 is Summon):
			f2.queue_free()
	await get_tree().create_timer(0.2).timeout
	f.queue_free()
	if pl.combat.has_method("cancel"):
		pl.combat.cancel()
	pl.hp = pl.max_hp
	return d

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.5).timeout
	Hud.close_dialog()
	Game.set_meta("sandbox", true)
	var pl = main.player
	pl.max_hp = 1e9; pl.hp = 1e9; pl.max_chakra = 1e9; pl.chakra = 1e9
	var vs = Game.village("suna")
	var base = Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 600, vs["y"]))
	pl.respawn(base)
	await get_tree().create_timer(1.0).timeout
	var part = int(OS.get_environment("PART")) if OS.get_environment("PART") != "" else (9 if OS.get_environment("IDS") != "" else 0)
	# taban: genel element jutsuları, rütbe başına ortalama
	if part == 0 and OS.get_environment("IDS") == "":
		var by_rank := {}
		for id in Data.jutsu:
			var j = Data.jutsu[id]
			if not j is Dictionary or String(j.get("category", "")) != "ninjutsu" or String(j.get("element", "")) == "":
				continue
			if not String(j.get("learn", "")).begins_with("trainer") and not String(j.get("learn", "")).begins_with("scroll"):
				continue
			var rk = String(j.get("canon_rank", ""))
			if not by_rank.has(rk):
				by_rank[rk] = []
			if (by_rank[rk] as Array).size() < 6:
				by_rank[rk].append(id)
		for rk in by_rank:
			var tot = 0.0
			var n = 0
			for id in by_rank[rk]:
				var d = await _dmg(pl, id, base)
				if d > 0:
					tot += d; n += 1
			print("BASE %s ort=%.0f (%d jutsu)" % [rk, tot / maxf(1, n), n])
	elif OS.get_environment("IDS") != "":
		for id in OS.get_environment("IDS").split(","):
			var j = Data.jutsu.get(id, {})
			var d = await _dmg(pl, id, base)
			print("PATH - %s rütbe=%s cd=%s hasar=%.0f" % [id, String(j.get("canon_rank", "?")), str(j.get("cd", "?")), d])
	else:
		var pids = LegendPaths.PATHS.keys()
		pids.sort()
		var half = pids.slice(0, 7) if part == 1 else pids.slice(7)
		for pid in half:
			for id in LegendPaths.PATHS[pid]["order"]:
				var j = Data.jutsu.get(id, {})
				var d = await _dmg(pl, id, base)
				print("PATH %s %s rütbe=%s cd=%s hasar=%.0f" % [pid, id, String(j.get("canon_rank", "?")), str(j.get("cd", "?")), d])
	get_tree().quit()
