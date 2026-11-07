extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "gekko", "element": "fuuton", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl = main.player
	await get_tree().create_timer(2.0).timeout
	var d = TrainingDummy.new()
	main.actors.add_child(d)
	d.global_position = pl.global_position + pl.face_dir() * 8.0
	await get_tree().create_timer(0.5).timeout
	var y0 = pl.global_position.y
	Jutsu.execute(pl, "mikazuki_no_mai", d)
	for i in 12:
		await get_tree().create_timer(0.05).timeout
		var cl = get_tree().get_nodes_in_group("fighters").filter(func(f): return f is ShadowClone)
		print("MK t=%.2f pl_dy=%.2f pl_d=%.1f clones=%d %s" % [i * 0.05, pl.global_position.y - y0, pl.global_position.distance_to(d.global_position), cl.size(), cl.map(func(c): return snappedf(c.global_position.y - y0, 0.1))])
	get_tree().quit()
