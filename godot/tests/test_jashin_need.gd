extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pr = Game.profile
	pr["paths"] = {"jashin": {"s": 4}}
	print("JN no_scythe avail=", FightingStyles.available(pr), " need=", Data.jutsu["jashin_sanjin_kama"].get("need"), " shiji=", Data.jutsu["jujutsu_shiji_hyoketsu"].get("need"))
	Gear.grant(pr, "uc_tirpan")
	print("JN with_scythe avail=", FightingStyles.available(pr))
	var pj = PathJutsu.get_pinst()
	var sc = pj._tri_scythe()
	print("JN tri_scythe children=", sc.get_child_count())
	sc.free()
	get_tree().quit()
