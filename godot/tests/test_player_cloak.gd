extends Node
## Oyuncu jinchūriki pelerini: kuyruk sayısı canavara göre (Shukaku 1, Matatabi 2, Kurama 4), Sürüm 2 rengi

var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uzumaki", "element": "katon", "hair_style": "diken",
		"hair": Color(0.9, 0.7, 0.2), "top": Color(0.9, 0.45, 0.1), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.4, 0.9)}
	main._start_new_game()
	var pl: Player = main.player
	await _wait(1.5)
	var cl = pl.combat.modes.cloak
	for bid in ["shukaku", "matatabi", "kurama"]:
		Game.profile["jinchuriki"] = bid
		var seq = []
		for k in 8:
			if cl.level >= cl.max_level():
				break
			cl._tap()
			await _wait(0.2)
			seq.append("%d(%dt)" % [cl.level, cl.tails.size()])
		print("PCLOAK %s -> %s" % [bid, seq])
		cl.deactivate()
		await _wait(0.5)
	get_tree().quit()
