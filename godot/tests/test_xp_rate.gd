extends Node
## XP temposu: farklı oyuncu seviyelerinde tipik öldürmeler kaç seviye kazandırıyor
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(1.0).timeout
	for plv in [5, 15, 30, 50]:
		Game.profile["level"] = plv
		var need = Data.xp_for_level(plv)
		var line = "XP plv=%d need=%d |" % [plv, need]
		for spec in [["bandit", 2, false], ["rogue", 8, false], ["rogue", 28, false], ["boss", 45, true], ["boss", 60, true]]:
			var a = Enemy.archetype(spec[0] if spec[0] != "boss" else "rogue", 0)
			a["level"] = spec[1]
			if spec[2]:
				a["xp"] = spec[1] * 30
			var e = Enemy.new()
			e.setup(a)
			if spec[2]:
				e.set_meta("bingo_id", 1)
			var x = Progress.kill_xp(e)
			line += " %s%d:%d(%.0f%%)" % [spec[0], spec[1], x, x * 100.0 / need]
			e.free()
		print(line)
	get_tree().quit()
