extends Node
## Tüm köyler: kurulur (ve pişirilir), sonra önbellekten yüklenmiş haliyle ev MultiMesh'leri dolu mu, oyuncunun çevresinde ev var mı
## + oyuncu kamerasından kare. İki kez çalıştır: 1. kurar+pişirir, 2. önbellekten yükler.
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
	var vs = get_tree().current_scene.find_child("VillageStream", true, false)
	for v in Game.world_info["villages"]:
		var id = String(v["id"])
		var node: Node3D = null
		if id == "konoha":
			node = get_tree().current_scene.find_child("Konoha", true, false)
		else:
			var rec = vs.request(id)
			var t = 0.0
			while not rec.get("done", false) and t < 240.0:
				await _w(0.5)
				t += 0.5
			node = rec.get("node")
		var rp: Array = Builder.roof_points.get(id.to_lower(), [])
		var mm = 0
		var zero = 0
		if node:
			for m in node.find_children("*", "MultiMeshInstance3D", true, false):
				if m.multimesh and m.multimesh.instance_count > 0:
					mm += 1
					if m.multimesh.get_aabb().size.length() < 0.001:
						zero += 1
		var cover = 0
		if not rp.is_empty() and node:
			var c = rp[rp.size() / 2]
			var cpos: Vector3 = c if c is Vector3 else Vector3(c[0], c[1], c[2])
			var p = cpos + Vector3(14, 0, 6)
			p.y = Game.ground_height(p.x, p.z) + 0.2
			pl.global_position = p
			pl.velocity = Vector3.ZERO
			pl.yaw = rad_to_deg(atan2(p.x - cpos.x, p.z - cpos.z))
			for m in node.find_children("*", "MultiMeshInstance3D", true, false):
				if m.multimesh and m.multimesh.instance_count > 0 and m.visibility_range_begin == 0.0:
					var ab: AABB = m.global_transform * m.get_aabb()
					if ab.grow(5.0).has_point(Vector3(p.x, ab.get_center().y, p.z)):
						cover += 1
			await _w(1.5)
			await main.shot("vil_%s" % id)
		print("VIL %s roofs=%d mm=%d zero_aabb=%d near_mm=%d" % [id, rp.size(), mm, zero, cover])
	get_tree().quit()
