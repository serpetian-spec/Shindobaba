extends Node
## Köyü saran dağlar katı mı: merkezden dışa 36 yönde ışın, r*1.1 ötesinde kayaya çarpan yön sayısı
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 98, "name": "T", "gender": "m", "clan": "none", "element": "katon", "hair_style": "s2", "hair": Color(0.2, 0.2, 0.2), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	var pl = main.player
	var vs = get_tree().current_scene.find_child("VillageStream", true, false)
	for vid in ["kiri", "iwa", "kumo"]:
		var v = Game.village(vid)
		var c = Game.from_map(Vector2(v["x"], v["y"]))
		pl.respawn(c + Vector3(0, 2, 0))
		var rec = vs.request(vid)
		var t = 0.0
		while not rec.get("done", false) and t < 200.0:
			await get_tree().create_timer(0.5).timeout
			t += 0.5
		await get_tree().create_timer(2.0).timeout
		var r = float(v["r"])
		var hits = 0
		var near = 0.0
		for k in 36:
			var a = TAU * k / 36.0
			var dir = Vector3(sin(a), 0, -cos(a))
			var from = c + Vector3(0, float(v["base"]) - c.y + 60.0, 0) + dir * r * 1.05
			var q = PhysicsRayQueryParameters3D.create(from, from + dir * r * 0.8)
			q.exclude = [pl.get_rid()]
			var hit = pl.get_world_3d().direct_space_state.intersect_ray(q)
			if not hit.is_empty():
				hits += 1
				near += from.distance_to(hit["position"])
		print("ROCK %s dış_yön_çarpma=%d/36 ort_mesafe=%.0f" % [vid, hits, near / maxf(1, hits)])
	get_tree().quit()
