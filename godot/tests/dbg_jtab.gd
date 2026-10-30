extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	for jid in ["katon_goukakyuu_no_jutsu", "shi_wan", "bakuha_rensa", "suiton_suiryudan_no_jutsu"]:
		if Data.jutsu.has(jid):
			Game.profile["learned"].append(jid)
	Game.profile["slots"][0] = "shi_wan"
	Menus.jutsu_skills(main)
	await get_tree().create_timer(1.0).timeout
	var n = 0
	for b in Hud.dialog_layer.find_children("*", "Button", true, false):
		if (b as Button).tooltip_text.contains("Hasar"):
			if n < 3:
				print("TIP ", (b as Button).tooltip_text.replace("\n", " | "))
			n += 1
	print("TIP count=", n)
	await main.shot("jtab")
	get_tree().quit()
