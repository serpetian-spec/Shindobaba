extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	print("uchiha gözler: ", Game.profile["look"].get("eye_r"), " / ", Game.profile["look"].get("eye_l"))
	var pp = main.player.global_position
	for n in get_tree().root.find_children("*", "GeometryInstance3D", true, false):
		if not n.is_visible_in_tree():
			continue
		var gp: Vector3 = n.global_position
		var g = Game.terrain_height(gp.x, gp.z)
		if gp.y - g > 3.0 and gp.distance_to(pp) < 3000.0 and not String(n.get_path()).contains("Ambience") and not String(n.get_path()).contains("Vegetation"):
			print("HAVADA: ", n.get_path(), " ", n.get_class(), " h=", int(gp.y - g), " d=", int(gp.distance_to(pp)), " mesh=", (n.mesh.get_class() if n is MeshInstance3D and n.mesh else ""), " par=", n.get_parent().get_class())
	get_tree().quit()
