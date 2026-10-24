extends Node
## Göz ve kuyruklu canavar teknikleri slottan: gerekli durum yokken atmaz, varken atar
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.1, 0.1, 0.1)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var pr = Game.profile
	Gear.grant(pr, "goz_mangekyo", "sag_goz", null, null, {"lvl": 3, "origin": "dogustan"})
	Gear.grant(pr, "goz_mangekyo", "sol_goz", null, null, {"lvl": 3, "origin": "dogustan"})
	TailedBeasts.make_jinchuriki("kurama")
	pl.chakra = 9999
	pl.max_chakra = 9999
	var ids = SpecialSlots.refresh(pr)
	print("SPECIAL %s" % [ids.map(func(x): return "%s=%s" % [x, Data.jutsu[x]["name"]])])
	pr["slots"][0] = "goz_sag"
	pr["slots"][1] = "bijuu_t0"
	var ey = pl.combat.modes.eyes
	var cl = pl.combat.modes.cloak
	pl.combat.begin_cast("goz_sag")
	print("EYE_CLOSED cd=%s" % ey.cd["sag"])
	ey.toggle()
	await get_tree().create_timer(0.2).timeout
	pl.combat.begin_cast("goz_sag")
	print("EYE_OPEN cd=%s" % ey.cd["sag"])
	pl.combat.begin_cast("bijuu_t0")
	print("BIJUU_OFF cd=%s" % [cl.tech_cd])
	cl.set_level(1)
	await get_tree().create_timer(0.2).timeout
	pl.combat.begin_cast("bijuu_t0")
	print("BIJUU_ON cd=%s hudcd=%s" % [cl.tech_cd, SpecialSlots.cooldown(pl, "bijuu_t0")])
	get_tree().quit()
