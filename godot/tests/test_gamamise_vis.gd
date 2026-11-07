extends Node
## Gama Mise modeli: dükkân ve dükkân kurbağası (ölçek için oyuncu)
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.9, 0.9, 0.9), "top": Color(0.3, 0.5, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
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
	var at = b0 + Vector3(0, 0, -6.0)
	at.y = Game.ground_height(at.x, at.z)
	pl.global_position = at + Vector3(2.8, 0, 3.5)
	var g = GamaMise.spawn(get_tree().current_scene, at, PI)   # ön kameraya
	await _w(0.3)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.global_position = at + Vector3(-1.5, 2.6, 11.0)
	cc.look_at(at + Vector3.UP * 2.2)
	cc.current = true
	await _w(0.1)
	await main.shot("gm_house")
	g.morph(0.3)
	await _w(0.6)
	cc.global_position = at + Vector3(0, 2.2, 9.0)
	cc.look_at(at + Vector3.UP * 1.4)
	await _w(0.1)
	await main.shot("gm_toad")
	get_tree().quit()
