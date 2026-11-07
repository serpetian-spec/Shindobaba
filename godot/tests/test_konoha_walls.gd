extends Node
## Konoha duvarları: binaya doğru yürüyen oyuncu içinden geçmemeli
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(3.0)
	Hud.close_dialog()
	var pl = main.player
	var rp: Array = Builder.roof_points.get("konoha", [])
	print("WALL roofs=%d" % rp.size())
	var passed = 0
	var tested = 0
	for k in range(0, mini(rp.size(), 60), 6):
		var c = rp[k]
		var cpos: Vector3 = c if c is Vector3 else Vector3(c[0], c[1], c[2])
		var start = cpos + Vector3(7, 0, 0)
		start.y = Game.ground_height(start.x, start.z) + 0.2
		pl.global_position = start
		pl.velocity = Vector3.ZERO
		pl.yaw = -90.0   # kamera ileri = -x (binaya doğru)
		await _w(0.3)
		Input.action_press("forward")
		await _w(1.6)
		Input.action_release("forward")
		var d = Vector2(pl.global_position.x - cpos.x, pl.global_position.z - cpos.z).length()
		tested += 1
		if d < 1.0:
			passed += 1
	print("WALL tested=%d walked_into_center=%d" % [tested, passed])
	get_tree().quit()
