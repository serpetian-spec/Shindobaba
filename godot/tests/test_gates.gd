extends Node
## Sekiz Kapı kanon kuralı: kapı kapalıyken Ura Renge/Hirudora atılamaz; Hachimon Tonkō 3 -> 6 -> 7 -> 8 açar; düşman aynı şart
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.15), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.3, 0.3), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	await get_tree().create_timer(1.0).timeout
	Game.set_meta("sandbox", true)
	pl.max_chakra = 1e9; pl.chakra = 1e9; pl.max_hp = 5000; pl.hp = 5000
	for id in ["ura_renge", "hirudora", "hachimon_tonko_no_jin", "omote_renge"]:
		Game.profile["learned"].append(id)
	var try_cast = func(id: String) -> String:
		pl.combat.cooldowns.erase(id)
		pl.combat.action = ""
		pl.combat.cast_jutsu = ""
		pl.combat.begin_cast(id)
		var r = pl.combat.cast_jutsu
		await get_tree().create_timer(2.2).timeout
		return r
	print("GT ura kapalı: '%s'" % await try_cast.call("ura_renge"))
	print("GT omote kapalı (kendisi açar): '%s'" % await try_cast.call("omote_renge"))
	await get_tree().create_timer(9.0).timeout
	print("GT hachimon 1: '%s' kapı=%d" % [await try_cast.call("hachimon_tonko_no_jin"), PathJutsu.gate_level(pl)])
	print("GT ura kapı3: '%s'" % await try_cast.call("ura_renge"))
	print("GT hirudora kapı3: '%s'" % await try_cast.call("hirudora"))
	for k in 2:
		print("GT hachimon +: '%s' kapı=%d" % [await try_cast.call("hachimon_tonko_no_jin"), PathJutsu.gate_level(pl)])
	print("GT hirudora kapı7: '%s'" % await try_cast.call("hirudora"))
	print("GT hp=%d/%d" % [pl.hp, pl.max_hp])
	var e := Enemy.new()
	e.setup(Enemy.archetype("rogue", 1))
	main.actors.add_child(e)
	print("GT düşman gate_ok ura (kapalı)=%s, kapı 3 açık=%s" % [str(PathJutsu.gate_ok(e, "ura_renge")), str((func(): e.set_meta("gates", 3); e.set_meta("gates_until", Game.now() + 5.0); return PathJutsu.gate_ok(e, "ura_renge")).call())])
	get_tree().quit()
