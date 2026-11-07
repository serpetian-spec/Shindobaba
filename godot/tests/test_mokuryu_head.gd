extends Node
## Mokuryū başı yakın çekim (ref karşılaştırma)
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "senju", "element": "doton", "hair_style": "uzun", "hair": Color(0.1, 0.08, 0.07), "top": Color(0.6, 0.2, 0.2), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	Hud.show_game_hud(false)
	var pl = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 600, vs["y"])))
	await _w(1.0)
	var at: Vector3 = pl.global_position + Vector3(0, 6, -14)
	var h = Mokuryu.head(3.4)
	get_tree().current_scene.add_child(h)
	h.global_position = at
	h.rotation.y = deg_to_rad(105)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.global_position = at + Vector3(-3, 1.5, 12)
	cc.look_at(at)
	cc.current = true
	await _w(0.2)
	await main.shot("mr_head")
	get_tree().quit()
