extends Node
## Tab: Kuyruklu Canavarlar + Kuchiyose sekmeleri
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var ids = BeastModels.INFO.keys()
	TailedBeasts.make_jinchuriki(ids[1])
	TailedBeasts.make_jinchuriki(ids[2])
	TailedBeasts.beasts()[ids[3]] = {"state": "sealed_jar", "trust": 0.0}
	Contracts.sign("kurbağa")
	await get_tree().create_timer(0.5).timeout
	Game.paused = true
	Menus.ninja_menu(main, "beasts")
	await get_tree().create_timer(0.6).timeout
	await main.shot("tab_beasts")
	TailedBeasts.transfer_from_jar(ids[3])
	TailedBeasts.set_active(ids[1])
	print("BEAST held=%s active=%s jar=%s" % [TailedBeasts.held(), TailedBeasts.player_jinchuriki(), TailedBeasts.jarred()])
	Menus.ninja_menu(main, "summons")
	await get_tree().create_timer(0.6).timeout
	await main.shot("tab_summons")
	get_tree().quit()
