extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 98, "name": "T", "gender": "f", "clan": "none", "element": "fuuton", "village": "suna", "hair_style": "f9", "hair": Color(0.8, 0.7, 0.3), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var p = main.player
	print("FAN none kamaitachi=[", CanonRules.block(p, "kamaitachi_no_jutsu"), "] kirikiri=[", CanonRules.block(p, "kuchiyose_kirikiri_mai"), "] katon=[", CanonRules.block(p, "katon_gokakyu_no_jutsu"), "]")
	Gear.grant(Game.profile, "yelpaze", "sag")
	Gear.apply_look(Game.profile)
	print("FAN yelpaze kamaitachi=[", CanonRules.block(p, "kamaitachi_no_jutsu"), "] kirikiri=[", CanonRules.block(p, "kuchiyose_kirikiri_mai"), "]")
	Gear.grant(Game.profile, "temari_ogi", "sag")
	print("FAN temari kamaitachi=[", CanonRules.block(p, "kamaitachi_no_jutsu"), "] kirikiri=[", CanonRules.block(p, "kuchiyose_kirikiri_mai"), "]")
	get_tree().quit()
