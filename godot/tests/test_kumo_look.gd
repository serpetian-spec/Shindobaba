extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 98, "name": "T", "gender": "m", "clan": "none", "element": "katon", "village": "kumo", "hair_style": "s2", "hair": Color(0.2, 0.2, 0.2), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	var v = Game.village("kumo")
	var c = Game.from_map(Vector2(v["x"], v["y"]))
	var pl = main.player
	var offs = [Vector3(-818, 0, 374), Vector3(-689, 0, 665)] if OS.get_environment("KL_USER") != "" else [Vector3(0, 0, 0), Vector3(120, 0, 0), Vector3(-120, 0, 60), Vector3(0, 0, 150), Vector3(60, 0, -150)]
	var i = 0
	for o in offs:
		var p = c + o
		p.y = Game.terrain_height(p.x, p.z)
		pl.respawn(p)
		await get_tree().create_timer(5.0).timeout
		for yaw in [0.0, 90.0, 180.0, 270.0]:
			pl.yaw = yaw
			await get_tree().create_timer(0.5).timeout
			await main.shot("kumo_%d_%d" % [i, int(yaw)])
		i += 1
	get_tree().quit()
