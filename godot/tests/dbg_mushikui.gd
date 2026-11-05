extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "aburame", "element": "doton", "hair_style": "diken", "hair": Color(0.15, 0.12, 0.1), "top": Color(0.35, 0.45, 0.38), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl = main.player
	Hud.show_game_hud(false)
	await get_tree().create_timer(1.5).timeout
	var a = Enemy.archetype("rogue", 1)
	a["respawn"] = false
	var e = Enemy.new()
	e.setup(a)
	main.actors.add_child(e)
	e.global_position = pl.global_position + pl.face_dir() * 2.0
	e.max_hp = 1e6
	e.hp = 1e6
	await get_tree().create_timer(0.4).timeout
	Jutsu.execute(pl, "kidaichu_mushikui", e)
	e.apply_status("bind", 9.0)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	for t in [1.0, 1.15, 4.0]:
		await get_tree().create_timer(1.0 if t == 1.0 else (0.15 if t < 2 else 2.85)).timeout
		cc.global_position = e.global_position - e.global_position.direction_to(pl.global_position) * -1.3 + Vector3.UP * 1.3
		cc.look_at(e.global_position + Vector3.UP * 1.0)
		cc.current = true
		await main.shot("mk_%d" % int(t * 100))
	get_tree().quit()
