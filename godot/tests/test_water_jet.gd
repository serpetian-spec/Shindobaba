extends Node
## WaterArt.jet: yatay su hortumu doğru yönde uzanıyor mu (yan açı)
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(1.5)
	var a = pl.global_position + Vector3(0, 1.4, 0)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.global_position = a + Vector3(2.0, 0.6, 6.0)
	cc.look_at(a + Vector3(2.0, 0, 0))
	cc.current = true
	WaterArt.jet(a, a + Vector3(4.0, -0.4, 0.0), 0.22, 0.4)
	await _w(0.2)
	await main.shot("jet")
	get_tree().quit()
