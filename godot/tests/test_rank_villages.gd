extends Node
## Terfi kıyafeti: Chūnin olunca köyün Chūnin seti kuşanılıyor mu (yeni terfi + eski kayıt telafisi), ekran görüntüsü

var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "akimichi", "element": "katon", "hair_style": "diken",
		"hair": Color(0.45, 0.25, 0.15), "top": Color(0.55, 0.15, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pr = Game.profile
	var pl: Player = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _wait(2.0)
	for vid in ["konoha", "suna", "kiri", "kumo", "iwa"]:
		pr["village"] = vid
		pr["home"] = vid
		pr["rank"] = 1
		Progress.promote(2)
		var c2 = Gear.equipped(pr, "set").get("id", "YOK")
		Progress.promote(3)
		print("VILLAGE %s home=%s chunin=%s jonin=%s" % [vid, Progress.home(), c2, Gear.equipped(pr, "set").get("id", "YOK")])
	get_tree().quit()
