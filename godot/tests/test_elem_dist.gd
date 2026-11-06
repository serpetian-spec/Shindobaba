extends Node
## Element dağılımı: her düşman üreticisinden N örnek -> setup sonrası taşınan jutsuların elementi
## + chakra: katon ninjası 60 sn oyuncuya karşı kaç jutsu atıyor
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.5).timeout
	Hud.close_dialog()
	var gens = {
		"konoha_köy": func(i): return Orgs._village_arch("konoha", i),
		"ame_köy": func(i): return Orgs._village_arch("ame", i),
		"kumo": func(i): return Enemy.archetype("kumo", i),
		"rogue": func(i): return Enemy.archetype("rogue", i),
		"oto": func(i): return Enemy.archetype("oto", i),
		"genin_rival": func(i): return Enemy.archetype("genin_rival", i),
	}
	for g in gens:
		var cnt := {}
		var jcnt := {}
		for i in 1000:
			var a = gens[g].call(i)
			var e = Enemy.new()
			e.setup(a)
			var el = String(e.element)
			cnt[el] = int(cnt.get(el, 0)) + 1
			for jid in e.arch.get("jutsu", []):
				var je = String(Data.jutsu.get(jid, {}).get("element", ""))
				if je != "":
					jcnt[je] = int(jcnt.get(je, 0)) + 1
			e.free()
		print("DIST %s element=%s jutsu_element=%s" % [g, cnt, jcnt])
	# chakra testi: Lv15 katon ninjası 60 sn
	var pl = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await get_tree().create_timer(1.0).timeout
	pl.max_hp = 1e9
	pl.hp = 1e9
	var a = Enemy.archetype("rogue", 0)
	a["element"] = "katon"
	a["level"] = 15
	a["jutsu"] = Enemy.auto_jutsu("rogue", "katon", 15)
	var e = Enemy.new()
	e.setup(a)
	main.actors.add_child(e)
	e.global_position = pl.global_position + Vector3(0, 0, -14)
	e.home = e.global_position
	e.target = pl
	e.state = "chase"
	var casts = 0
	var was = false
	for k in 600:
		await get_tree().create_timer(0.1).timeout
		var now = e.state == "cast"
		if now and not was:
			casts += 1
		was = now
		if k % 100 == 0:
			print("CHK t=%ds chakra=%.0f/%.0f casts=%d" % [k / 10, e.chakra, e.max_chakra, casts])
	print("CHK 60 sn toplam jutsu=%d jutsular=%s" % [casts, e.arch["jutsu"]])
	get_tree().quit()
