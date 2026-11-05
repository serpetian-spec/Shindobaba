extends Node
## Köyden kaçan dost: Nukenin rütbesi, köy haberi/akademi sohbeti yok; takım hocası hain olamaz (sadakat >= 65)
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.0).timeout
	Game.profile["rank"] = 1
	var pl = main.player
	var pr = Game.profile
	var h0 = pl.max_hp
	var s0 = pl.max_stamina
	for k in 200:
		Mastery.gain(pr, "dayaniklilik", 0.05)
	print("DAY dayanıklılık=%.2f  max_hp %.0f -> %.0f  max_stamina %.0f -> %.0f" % [Mastery.get_v(pr, "dayaniklilik"), h0, pl.max_hp, s0, pl.max_stamina])
	get_tree().quit()
