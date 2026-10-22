extends Node
## Modern arayüz vitrini: her ekranın görüntüsü (envanter, ekipman, jutsu, yetenek, görevler, görev panosu, parşömen, bingo, dükkân, diyalog, harita)
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Kaito", "gender": "m", "clan": "uchiha", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.08, 0.08, 0.1), "top": Color(0.15, 0.2, 0.33), "top2": Color(0.12, 0.12, 0.14), "pants": Color(0.15, 0.15, 0.17), "top_style": "ceket", "pants_style": "ninja", "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.1, 0.1, 0.1)}
	main._start_new_game()
	main.world.env.time_of_day = 0.45
	var pr = Game.profile
	pr["rank"] = 3
	pr["ryo"] = 4200
	for id in ["katana", "tanto", "kunai", "nodachi", "ceket", "uzun_gomlek", "chunin_yelek"]:
		Gear.grant(pr, id)
	if Gear.ITEMS.has("goz_mangekyo"):
		Gear.grant(pr, "goz_mangekyo", "sag_goz", null, null, {"lvl": 3, "origin": "dogustan"})
		Gear.grant(pr, "goz_mangekyo", "sol_goz", null, null, {"lvl": 3, "origin": "dogustan"})
	Gear.apply_look(pr)
	var ids = Data.jutsu.keys()
	pr["learned"] = ids.slice(0, mini(12, ids.size()))
	for i in 6:
		pr["slots"][i] = pr["learned"][i]
	main.player.rebuild_model()
	await get_tree().create_timer(3.0).timeout
	await main.shot("u0_hud")
	main._pause()
	for t in ["inv", "wardrobe", "jutsu", "skills", "missions"]:
		Menus.ninja_menu(main, t)
		await get_tree().create_timer(1.0).timeout
		await main.shot("u1_" + t)
	Menus._eq_slot = "sag"
	Menus.ninja_menu(main, "wardrobe")
	await get_tree().create_timer(1.0).timeout
	await main.shot("u2_ekipman_sag")
	Menus._eq_slot = "sag_goz"
	Menus.ninja_menu(main, "wardrobe")
	await get_tree().create_timer(1.0).timeout
	await main.shot("u2_ekipman_goz")
	main.resume()
	await get_tree().create_timer(0.3).timeout
	Hud.show_mission_board("konoha")
	await get_tree().create_timer(1.0).timeout
	await main.shot("u3_pano")
	if not Missions.board.is_empty():
		Menus._unroll(Missions.board[0], "konoha")
		await get_tree().create_timer(0.8).timeout
		await main.shot("u4_parsomen")
	Hud.close_dialog()
	Menus.bingo_book(main)
	await get_tree().create_timer(1.2).timeout
	await main.shot("u5_bingo")
	Hud.close_dialog()
	Hud.gear_shop("Silahçı", Gear.SHOP_WEAPONS)
	await get_tree().create_timer(1.2).timeout
	await main.shot("u6_dukkan")
	Hud.close_dialog()
	Hud.dialog("Ichiraku Ramen", "Hoş geldin! Bugün ne yiyeceksin? Taze miso ramen, tonkotsu ya da shio... Hepsi el yapımı erişte!", [{"label": "Miso ramen — 20 Ryō", "cb": func(): pass}, {"label": "Tonkotsu — 30 Ryō", "cb": func(): pass}])
	await get_tree().create_timer(2.0).timeout
	await main.shot("u7_diyalog")
	Hud.close_dialog()
	main._pause()
	Menus.world_map(main)
	await get_tree().create_timer(0.8).timeout
	await main.shot("u8_harita")
	Menus.pause(main)
	await get_tree().create_timer(0.8).timeout
	await main.shot("u9_duraklat")
	Menus.settings(func(): Menus.pause(main))
	await get_tree().create_timer(0.6).timeout
	await main.shot("u9b_ayarlar")
	main.resume()
	main.to_main_menu()
	await get_tree().create_timer(1.5).timeout
	await main.shot("u10_anamenu")
	Menus.slot_select(main, true)
	await get_tree().create_timer(0.8).timeout
	await main.shot("u11_yuva")
	main.start_creator(3)
	await get_tree().create_timer(1.2).timeout
	await main.shot("u12_yaratici")
	get_tree().quit()
