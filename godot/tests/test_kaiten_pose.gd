extends Node
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "hyuga", "element": "katon", "hair_style": "uzun", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.9, 0.88, 0.85), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.9, 0.9, 0.95)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(1.0)
	pl.chakra = 999.0
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.global_position = pl.global_position + Vector3(5, 2.5, 5)
	cc.look_at(pl.global_position + Vector3.UP * 1.0)
	cc.current = true
	Jutsu.execute(pl, "kaiten", null)
	for k in 3:
		await _w(0.22)
		await main.shot("kaiten_%d" % k)
	get_tree().quit()
