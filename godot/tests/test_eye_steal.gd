extends Node
## Uchiha düşmanı öldür, yanına git, F (interact) ile gözleri al -> kavanozda 2 Sharingan
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	var v = Game.village("konoha")
	main.player.respawn(Game.from_map(Vector2(v["x"] + 400, v["y"] - float(v["r"]) - 300)))
	await get_tree().create_timer(2.0).timeout
	var a = Enemy.archetype("rogue", 0)
	var e = Enemy.new()
	e.setup(a)
	get_tree().current_scene.add_child(e)
	e.global_position = main.player.global_position + Vector3(2.0, 0, 0)
	Eyes.give_enemy_eyes(e, 1, 3)
	await get_tree().create_timer(0.5).timeout
	e.take_hit({"dmg": 99999.0, "knock": 0.0, "kind": "light", "dir": Vector3.FORWARD, "element": ""})
	await get_tree().create_timer(1.5).timeout
	var before = Game.profile["gear"].filter(func(g): return String(g["id"]).begins_with("goz_")).size()
	var ev = InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().create_timer(0.5).timeout
	var after = Game.profile["gear"].filter(func(g): return String(g["id"]).begins_with("goz_")).size()
	print("EYES before=", before, " after=", after, " dead=", e.is_dead())
	get_tree().quit()
