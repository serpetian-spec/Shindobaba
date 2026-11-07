extends Node
## Shinigami modeli (ref karşılaştırma): çağıranın arkasında, yarı saydam
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "sarutobi", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.3, 0.3), "top": Color(0.2, 0.2, 0.25), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	Hud.show_game_hud(false)
	var pl = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(1.0)
	pl.set_physics_process(false)
	var b0: Vector3 = pl.global_position
	pl.facing = PI
	var sg = Shinigami.spawn(get_tree().current_scene, b0 + Vector3(0, 0, -1.2), PI)
	sg.fade(0.78, 0.01)
	sg.show_seal(true)
	await _w(0.3)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.global_position = b0 + Vector3(0, 3.2, 9.5)
	cc.look_at(b0 + Vector3.UP * 3.2)
	cc.current = true
	await _w(0.1)
	await main.shot("sg_front")
	cc.global_position = b0 + Vector3(0.6, 5.3, 2.6)
	cc.look_at(b0 + Vector3(0, 5.3, -1.2))
	await _w(0.1)
	await main.shot("sg_face")
	get_tree().quit()
