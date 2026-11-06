extends Node
## Taijutsu staminası: 20 sn boyunca hazır oldukça at -> stamina nasıl iner, kaç kez atılabiliyor
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.5).timeout
	Hud.close_dialog()
	var pl = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 500, vs["y"])))
	await get_tree().create_timer(1.0).timeout
	for id in ["rakanken", "okasho"]:
		Game.profile["learned"].append(id)
		pl.stamina = pl.max_stamina
		pl.combat.cooldowns.erase(id)
		var casts = 0
		var line = ""
		for k in 200:
			if pl.combat.action == "" and float(pl.combat.cooldowns.get(id, 0.0)) <= 0.0:
				var s0 = pl.stamina
				pl.combat.begin_cast(id)
				if pl.stamina < s0:
					casts += 1
			if k % 20 == 0:
				line += "%d:%.0f " % [k / 10, pl.stamina]
			await get_tree().create_timer(0.1).timeout
		print("TAI %s maliyet=%.0f maks=%.0f 20sn'de atış=%d  stamina(sn:değer)= %s" % [id, Stats.tai_stamina_cost(Data.jutsu[id]), pl.max_stamina, casts, line])
		await get_tree().create_timer(3.0).timeout
	get_tree().quit()
