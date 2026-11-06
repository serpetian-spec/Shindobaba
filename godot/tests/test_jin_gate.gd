extends Node
## Hachibi bijū teknikleri yalnız Sekiz Kuyruk jinchūrikisinde: öğretme + atma şartı
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.15), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.3, 0.3), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	await get_tree().create_timer(1.0).timeout
	pl.max_chakra = 1e9
	pl.chakra = 1e9
	for jid in ["hachibi_lariat", "hachibi_yedi_kilic", "takoashi_bunshin_no_jutsu"]:
		print("JG %s need=%s req='%s'" % [jid, Data.jutsu[jid].get("need", ""), LegendPaths.canon_req(jid)])
	Game.profile["learned"].append("hachibi_lariat")
	pl.combat.begin_cast("hachibi_lariat")
	print("JG cast as non-jin: casting=%s" % str(pl.combat.cast_jutsu))
	await get_tree().create_timer(2.0).timeout
	Game.profile["jinchuriki"] = "gyuki"
	print("JG as gyuki req='%s'" % LegendPaths.canon_req("hachibi_lariat"))
	pl.combat.cooldowns.erase("hachibi_lariat")
	pl.combat.begin_cast("hachibi_lariat")
	print("JG cast as gyuki: casting=%s" % str(pl.combat.cast_jutsu))
	get_tree().quit()
