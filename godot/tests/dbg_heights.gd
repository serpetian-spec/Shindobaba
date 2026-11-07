extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl = main.player
	await get_tree().create_timer(1.5).timeout
	for rk in [0, 1, 2, 3]:
		Game.profile["rank"] = rk
		pl.rebuild_model()
		await get_tree().create_timer(0.6).timeout
		var aabb = AABB()
		var first = true
		for mi in pl.model.find_children("*", "MeshInstance3D", true, false):
			if mi.is_visible_in_tree() and mi.mesh:
				var b = mi.global_transform * mi.get_aabb()
				aabb = b if first else aabb.merge(b)
				first = false
		print("H rank=%d age=%s scale=%.2f boy=%.2f m" % [rk, pl.model.look.get("age", "?"), pl.model.scale.x, aabb.end.y - pl.global_position.y])
	get_tree().quit()
