extends Node
## Konoha caddesinde: zemin ışını (çarpan) vs arazi yüksekliği, yol maskesi değeri
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.2, 0.15, 0.1), "top": Color(0.2, 0.3, 0.5), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var v = Game.village("konoha")
	for off in [Vector2(20, -300), Vector2(300, 250)]:
		pl.respawn(Game.from_map(Vector2(v["x"] + off.x, v["y"] + off.y)))
		await get_tree().create_timer(8.0).timeout
		var c0 = pl.global_position
		var found = {}
		var stack = [get_tree().current_scene]
		while not stack.is_empty():
			var n = stack.pop_back()
			for ch in n.get_children():
				stack.append(ch)
			if n is MeshInstance3D and n.mesh and n.is_visible_in_tree():
				var ab: AABB = n.global_transform * n.mesh.get_aabb()
				if ab.has_point(Vector3(c0.x, c0.y + 0.03, c0.z)) or ab.has_point(Vector3(c0.x, c0.y - 0.1, c0.z)):
					found[str(n.get_path())] = ab
		for k in found:
			print("MESHAT ", k.right(90), " ", found[k])
		var rm = Game.world.get("road_map")
		var img: Image = rm.texture.get_image() if rm and rm.texture else null
		for dx in [-6, 0, 6]:
			for dz in [-6, 0, 6]:
				var p = pl.global_position + Vector3(dx, 0, dz)
				var q = PhysicsRayQueryParameters3D.create(p + Vector3.UP * 6, p - Vector3.UP * 6)
				q.exclude = [pl.get_rid()]
				var r = pl.get_world_3d().direct_space_state.intersect_ray(q)
				var th = Game.ground_height(p.x, p.z)
				var rv = -1.0
				if img:
					var uv = (Vector2(p.x, p.z) - Vector2(rm.rect.x, rm.rect.y)) / rm.rect.z
					rv = img.get_pixel(int(uv.x * img.get_width()), int(uv.y * img.get_height())).r
				print("LANES ", preload("res://scripts/world/road_map.gd").lanes.size(), " ver ", rm.version)
				print("PROBE off=%s d=(%d,%d) terrain=%.2f hit=%s y=%.2f road_at=%.2f street=%.2f tex=%.2f" % [off, dx, dz, th, (r.collider.name + "/" + r.collider.get_parent().name) if r else "-", r.position.y if r else 0.0, Game.road_at(p.x, p.z), Game.road_at(p.x, p.z, "street"), rv])
	get_tree().quit()
