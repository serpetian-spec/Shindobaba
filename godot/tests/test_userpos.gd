extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.load_slot(97)
	await get_tree().create_timer(8.0).timeout
	Hud.close_dialog()
	var pl = main.player
	var v = Game.village("kumo")
	var c = Game.from_map(Vector2(v["x"], v["y"]))
	print("UP pos=", pl.global_position, " kumo_c=", c, " local=", pl.global_position - c)
	for yaw in [0.0, 90.0, 180.0, 270.0]:
		pl.yaw = yaw
		await get_tree().create_timer(0.6).timeout
		await main.shot("up_%d" % int(yaw))
	get_tree().quit()
