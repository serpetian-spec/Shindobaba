extends Node
## Duraklatmada cooldown düşüyor mu: oyuncu jutsu cd, alet cd, düşman jcd (gerçek saat)
var main: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.5).timeout
	Hud.close_dialog()
	var pl = main.player
	pl.combat.cooldowns["katon_goukakyuu"] = 10.0
	var e = Enemy.new()
	e.setup(Enemy.archetype("rogue", 0))
	main.actors.add_child(e)
	e.jcd["x"] = Game.now() + 10.0
	await get_tree().create_timer(0.1).timeout
	var c0 = pl.combat.cooldowns["katon_goukakyuu"]
	main._pause()
	Menus.pause(main)
	await get_tree().create_timer(3.0, true).timeout
	var c1 = pl.combat.cooldowns["katon_goukakyuu"]
	var erem = float(e.jcd["x"]) - Game.now()
	print("PCD duraklatma 3 sn: oyuncu cd %.2f -> %.2f | düşman jcd kalan %.2f (10'dan)" % [c0, c1, erem])
	main.resume()
	await get_tree().create_timer(2.0).timeout
	print("PCD devam 2 sn: oyuncu cd %.2f" % pl.combat.cooldowns["katon_goukakyuu"])
	get_tree().quit()
