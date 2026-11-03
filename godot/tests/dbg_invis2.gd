extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.2, 0.15, 0.1), "top": Color(0.2, 0.3, 0.5), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var v = Game.village("kusa")
	var c = Game.from_map(Vector2(v["x"], v["y"]))
	main.player.respawn(c)
	await get_tree().create_timer(4.0).timeout
	for cs in get_tree().root.find_children("*", "CollisionShape3D", true, false):
		if cs.shape is BoxShape3D and absf(cs.shape.size.y - 11.3) < 0.01:
			var gp = cs.global_position
			print("BOX at local ", Vector2(gp.x - c.x, gp.z - c.z), " size ", cs.shape.size, " owner ", cs.get_parent().get_path())
			for mm in get_tree().root.find_children("*", "MultiMeshInstance3D", true, false):
				var M: MultiMesh = mm.multimesh
				if M == null:
					continue
				for i in M.instance_count:
					var t = mm.global_transform * M.get_instance_transform(i)
					if Vector2(t.origin.x - gp.x, t.origin.z - gp.z).length() < 2.0:
						print("   mm ", mm.get_path(), " i=", i, " scale=", t.basis.get_scale(), " vis=", mm.is_visible_in_tree(), " vr_end=", mm.visibility_range_end, " mesh_aabb=", M.mesh.get_aabb() if M.mesh else null)
	get_tree().quit()
