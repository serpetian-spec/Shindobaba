extends Node
## HUD testi: 6 slot dolu, biri beklemede, ipucu görünür; 1600x900 ve 1920x1080 ekran görüntüsü.
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Kaito", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	main.world.env.time_of_day = 0.42
	var pr = Game.profile
	var ids = Data.jutsu.keys()
	var picked = []
	for el in ["", "katon", "suiton", "fuuton", "raiton", "doton"]:
		for jid in ids:
			if String(Data.jutsu[jid].get("element", "")) == el and not jid in picked:
				picked.append(jid)
				break
	pr["learned"] = picked
	for i in 6:
		pr["slots"][i] = picked[i] if i < picked.size() else ""
	await get_tree().create_timer(1.0).timeout
	var comb = main.player.combat
	comb.cooldowns[picked[1]] = 4.0
	main.player.hp = main.player.max_hp * 0.62
	Hud.msg("Yeni görev alındı!", Color(0.6, 1, 0.6))
	await get_tree().create_timer(3.0).timeout
	await main.shot("hud_1600")
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await get_tree().create_timer(1.0).timeout
	await main.shot("hud_1920")
	Hud.dialog("Ichiraku Ramen", "Hoş geldin! Bugün ne yiyeceksin?", [{"label": "Miso ramen — 20 Ryō", "cb": func(): pass}])
	await get_tree().create_timer(0.5).timeout
	await main.shot("hud_dialog")
	Hud.close_dialog()
	Hud.banner("YENİ JUTSU", "Katon: Goukakyuu no Jutsu", Color(0.5, 0.85, 1.0))
	await get_tree().create_timer(0.5).timeout
	await main.shot("hud_banner")
	main._pause()
	Menus.ninja_menu(main, "jutsu")
	await get_tree().create_timer(0.6).timeout
	await main.shot("hud_ninja_jutsu")
	main.resume()
	main.to_main_menu()
	await get_tree().create_timer(1.2).timeout
	await main.shot("hud_mainmenu")
	get_tree().quit()
