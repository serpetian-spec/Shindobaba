extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	await get_tree().create_timer(2.0).timeout
	var v = Game.village("konoha")
	var p = Game.from_map(Vector2(v["x"] + 70, v["y"] - 30 - 14))
	main.player.respawn(p)
	main.player.yaw = 0.0
	main.player.pitch = -5.0
	main.player.cam_dist = 9.0
	await get_tree().create_timer(3.0).timeout
	for n in get_tree().root.find_children("*", "Node3D", true, false):
		if String(n.name).to_lower().contains("ichiraku") or (n.get_parent() and String(n.get_parent().name) == "Decor" and n.get_child_count() > 0 and n.global_position.distance_to(p) < 20):
			pass
	var ich = null
	for n in get_tree().root.find_children("*", "MeshInstance3D", true, false):
		if n.global_position.distance_to(p + Vector3(0,0,-14)) < 12 and n.get_aabb().size.length() > 3:
			print("MESH ", n.get_path(), " y=", n.global_position.y, " ground=", Game.terrain_height(n.global_position.x, n.global_position.z), " aabb=", n.global_transform * n.get_aabb())
	await main.shot("ichiraku")
	get_tree().quit()
