extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pr = Game.profile
	Gear.grant(pr, "alin_koruyucu", "kafa", Color(0.15, 0.22, 0.55))
	Gear.apply_look(pr)
	var def0 = Gear.stat(pr, "def")
	print("HEAD shown band_style=%s def=%s" % [pr["look"].get("band_style"), def0])
	pr["hide_look"] = {"kafa": true}
	Gear.apply_look(pr)
	print("HEAD hidden band_style=%s def=%s" % [pr["look"].get("band_style"), Gear.stat(pr, "def")])
	get_tree().quit()
