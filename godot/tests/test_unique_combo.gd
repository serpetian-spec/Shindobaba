extends Node
## Efsane/nadir silah sürümü taban silahın el yapımı kombosunu kullanır
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.15), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.3, 0.3), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	await get_tree().create_timer(1.0).timeout
	for base in ["samehada", "gunbai", "kunai"]:
		Gear.grant(Game.profile, base, "sag")
		var a = pl.combat._combo_base(0)
		var uid = Gear.make_unique(base, "w", randi())
		Gear.grant(Game.profile, uid, "sag")
		var b = pl.combat._combo_base(0)
		print("UC %s base_keys=%s unique(%s base=%s) keys=%s held=%s" % [base, str(a.has("keys")), uid, Gear.base_id(uid), str(b.has("keys")), str(Gear.held_ids(Game.profile))])
	get_tree().quit()
