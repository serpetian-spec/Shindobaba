extends Node
## Kaçak S-rank: köylü selamı rütbesiz, jōnin ekipmanı/jutsu rütbe kilidi Bingo sınıfıyla açılır
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.15), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.3, 0.3), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.0).timeout
	Game.profile["rank"] = 2
	print("RR village chunin: jonin set -> '%s'" % Gear.req_text("set_jonin", Game.profile))
	Orgs.flags()["rogue"] = true
	for inf in [0, 300, 900, 2000]:
		Orgs.flags()["infamy"] = inf
		print("RR rogue %s eff=%d jonin set -> '%s' anbu -> '%s'" % [Orgs.rogue_rank_name(), Gear.eff_rank(Game.profile), Gear.req_text("set_jonin", Game.profile), Gear.req_text("set_anbu", Game.profile)])
	var v = null
	for n in get_tree().get_nodes_in_group("villagers"):
		v = n
		break
	if v == null:
		for n in main.find_children("*", "Villager", true, false):
			v = n
			break
	if v:
		v.role = "walk"
		for k in 3:
			print("RR greet: ", v._greeting())
	get_tree().quit()
