extends Node
## Duvara/ağaca yapışıkken C ile chakra toplanır, toplarken olduğu yerde tutunur
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
	await _w(1.0)
	# önüne yüksek bir duvar
	var wall = StaticBody3D.new()
	var cs = CollisionShape3D.new()
	var bx = BoxShape3D.new()
	bx.size = Vector3(10, 30, 1)
	cs.shape = bx
	wall.add_child(cs)
	get_tree().current_scene.add_child(wall)
	var g: Vector3 = pl.global_position
	wall.global_position = g + Vector3(0, 15, -1.0)
	await _w(0.2)
	pl.global_position = g + Vector3(0, 5, -0.1)
	pl.wall_n = Vector3(0, 0, 1)
	pl.velocity = Vector3.ZERO
	await get_tree().physics_frame
	pl.chakra = 10.0
	var y0 = pl.global_position.y
	Input.action_press("charge")
	await _w(0.3)
	print("WCD pressed=%s ui=%s grounded=%s action=[%s] wall=%s" % [str(Input.is_action_pressed("charge")), str(Game.ui_open), str(pl.grounded), pl.combat.action, str(pl.wall_n)])
	await _w(0.7)
	print("WC on_wall=%s action=%s chakra 10->%.0f dy=%.2f" % [str(pl.wall_n != Vector3.ZERO), pl.combat.action, pl.chakra, pl.global_position.y - y0])
	Input.action_release("charge")
	get_tree().quit()
