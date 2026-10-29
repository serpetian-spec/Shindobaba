extends Node
## Jutsu spamı: ortak bekleme + chakra yorgunluğu
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var c = pl.combat
	pl.max_chakra = 1000.0
	pl.chakra = 1000.0
	var ids = ["katon_goukakyuu", "katon_housenka", "katon_goukakyuu", "katon_endan", "katon_housenka"]
	for i in ids.size():
		c.cooldowns.clear()
		var before = pl.chakra
		c.begin_cast(ids[i])
		print("GCD try %d %s cast=%s cost=%.0f gcd=%.2f strain=%d" % [i, ids[i], c.action == "cast", before - pl.chakra, c.jutsu_gcd, c.strain])
		await get_tree().create_timer(0.3 if i == 1 else 1.4).timeout
	get_tree().quit()
