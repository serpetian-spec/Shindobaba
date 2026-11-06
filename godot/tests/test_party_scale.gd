extends Node
## Düşman grup boyu takım sayısına göre: yalnız -> 1, bir dostla -> 2; haydutlar kalabalık kalır
var main: Node

func _count(meta := "") -> int:
	var n = 0
	var names = []
	for f in get_tree().get_nodes_in_group("fighters"):
		if f is Enemy and f.team != "player" and not f.is_dead() and not f.is_queued_for_deletion() and (meta == "" or f.has_meta(meta)) and f.global_position.distance_to(main.player.global_position) < 150.0:
			n += 1
			names.append(f.display_name)
	print("   sayılan: ", names)
	return n

func _clear() -> void:
	for f in get_tree().get_nodes_in_group("fighters"):
		if f is Enemy and f.team != "player":
			f.queue_free()
	await get_tree().create_timer(0.3).timeout

func _round(tag: String) -> void:
	await _clear()
	var pl = main.player
	var vs = Game.village("suna")
	var base = Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 500, vs["y"]))
	pl.global_position = base
	print("PARTY %s party_size=%d" % [tag, Combat.party_size()])
	# av-ninjaları
	Game.profile["flags"]["rogue"] = true
	Orgs._hunter_t = 99999.0
	Orgs._hunter_tick(0.1)
	await get_tree().create_timer(0.3).timeout
	print("PARTY %s av-ninjası=%d" % [tag, _count("hunter_nin")])
	await _clear()
	# kaçak devriyesi (kaçak değilken)
	Game.profile["flags"]["rogue"] = false
	Encounters.finish(0.0)
	Encounters.start("patrol")
	await get_tree().create_timer(0.5).timeout
	print("PARTY %s kaçak_devriyesi=%d" % [tag, _count()])
	Encounters.finish(0.0)
	await _clear()
	Encounters.start("toll")
	await get_tree().create_timer(0.5).timeout
	print("PARTY %s haraççı_haydut=%d (kalabalık kalmalı)" % [tag, _count()])
	Encounters.finish(0.0)

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.5).timeout
	Hud.close_dialog()
	main.player.max_hp = 1e9
	main.player.hp = 1e9
	await _round("yalnız")
	# bir takım arkadaşı ekle
	var a = Enemy.archetype("kumo", 0)
	var ally = Enemy.new()
	ally.setup(a)
	ally.team = "player"
	ally.set_meta("teammate", true)
	main.actors.add_child(ally)
	ally.global_position = main.player.global_position + Vector3(2, 0, 0)
	await get_tree().create_timer(0.3).timeout
	await _round("1 dostla")
	get_tree().quit()
