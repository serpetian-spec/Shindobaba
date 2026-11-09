extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 98, "name": "T", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "s2", "hair": Color(0.2, 0.2, 0.2), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	# test: görünmez kutu koy, tarama bulsun
	var b = StaticBody3D.new()
	var c = CollisionShape3D.new()
	var bs = BoxShape3D.new(); bs.size = Vector3(2, 3, 2)
	c.shape = bs
	b.add_child(c)
	get_tree().current_scene.add_child(b)
	b.global_position = main.player.global_position + Vector3(6, 1.5, 0)
	var t0 = Time.get_ticks_msec()
	await preload("res://scripts/core/inv_check.gd").run(get_tree(), main.player.global_position)
	print("IC ms=", Time.get_ticks_msec() - t0)
	print("IC ", FileAccess.get_file_as_string("user://gorunmez_rapor.txt").right(600))
	get_tree().quit()
