extends Node
## Tam dönüşüm hasar ölçümü: ustalık 50 oyuncu, her canavar için pençe / top / teknikler -> gerçek hp farkı.
## Karşılaştırma: aynı Güç'teki eşit rakip canı (Stats.ninja_hp(60)).
var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


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


func _measure(pl, fn: Callable, dist: float) -> float:
	var base = pl.global_position
	var f = _foe(base + Vector3(0, 0, -dist))
	pl.facing = 0.0
	var c = pl.combat
	c.lock_target = f
	await _wait(0.1)
	var h0 = f.hp
	fn.call()
	await _wait(3.0)
	var d = h0 - f.hp
	f.queue_free()
	await _wait(0.1)
	return d


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uzumaki", "element": "katon", "hair_style": "diken",
		"hair": Color(0.9, 0.7, 0.2), "top": Color(0.9, 0.45, 0.1), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.4, 0.9)}
	main._start_new_game()
	var pl: Player = main.player
	await _wait(1.5)
	Hud.close_dialog()
	var m = Game.profile.get("mastery", {})
	for k in ["taijutsu", "ninjutsu", "kenjutsu"]:
		m[k] = 50.0
	Game.profile["mastery"] = m
	print("BDMG ref hp(60)=%d  melee_mult=%.2f jutsu_mult=%.2f" % [Stats.ninja_hp(60), Stats.melee_mult(Game.profile), Stats.jutsu_mult(Game.profile)])
	var cl = pl.combat.modes.cloak
	var ids = OS.get_environment("BEASTS").split(",", false) if OS.get_environment("BEASTS") != "" else ["kurama", "shukaku", "gyuki"]
	for bid in ids:
		Game.profile["jinchuriki"] = bid
		pl.global_position = Vector3(0, 0, 0)
		for lv in [5, 6]:
			cl.set_level(lv)
			await _wait(0.8)
			pl.chakra = 99999.0
			var row = []
			cl.bomb_cd = 0.0
			var sw = 0.0
			if lv == 6:
				sw = await _measure(pl, func(): cl._giant_swipe(), 10.0)
			row.append("swipe=%d" % sw)
			cl.bomb_cd = 0.0
			pl.chakra = 99999.0
			row.append("bomb=%d" % (await _measure(pl, func(): cl._bomb(), 25.0)))
			var l = BijuuArts.techs(bid)
			for i in l.size():
				cl.tech_cd.clear()
				pl.chakra = 99999.0
				row.append("%s=%d" % [l[i]["key"], await _measure(pl, func(): cl._tech(i), 15.0)])
			print("BDMG %s L%d %s" % [bid, lv, "  ".join(row)])
		cl.deactivate()
		await _wait(0.5)
	get_tree().quit()
