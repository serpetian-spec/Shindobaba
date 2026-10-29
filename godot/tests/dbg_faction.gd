extends Node
## Taraflar: köy ninjası kaçağa ve canavara saldırır, haydut-kaçak barışık
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var mk = func(kind):
		var e = Enemy.new()
		e.setup(Enemy.archetype(kind, 0))
		get_tree().current_scene.add_child(e)
		return e
	var k = mk.call("kumo"); var r = mk.call("rogue"); var b = mk.call("bandit")
	print("FA kumo-rogue=%s rogue-bandit=%s kumo-bandit=%s kumo-player=%s" % [Combat.hostile(k, r), Combat.hostile(r, b), Combat.hostile(k, b), Combat.hostile(k, pl)])
	k.global_position = pl.global_position + Vector3(60, 0, 0)
	r.global_position = pl.global_position + Vector3(66, 0, 0)
	k.home = k.global_position; r.home = r.global_position
	b.queue_free()
	await get_tree().create_timer(3.0).timeout
	print("FA kumo_target_is_rogue=%s rogue_hp=%.0f/%.0f" % [k.target == r, r.hp, r.max_hp])
	get_tree().quit()
