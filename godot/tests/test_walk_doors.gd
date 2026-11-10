extends Node
## Gerçek yürüyüşle giriş testi: oyuncu kapının 10 m önünden ileri tuşuyla yürür; kapı etkileşimine ulaşıyor mu
## WD_V = "kumo,kiri,..." ; her köyde o köyün "enter"/"mission_board"/"oto_lair" etkileşimleri denenir
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 98, "name": "T", "gender": "m", "clan": "none", "element": "katon", "hair_style": "s2", "hair": Color(0.2, 0.2, 0.2), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(3.0)
	Hud.close_dialog()
	var pl = main.player
	var vs = get_tree().current_scene.find_child("VillageStream", true, false)
	for vid in OS.get_environment("WD_V").split(",", false):
		var v = Game.village(vid)
		var c = Game.from_map(Vector2(v["x"], v["y"]))
		pl.respawn(c + Vector3(0, 2, 0))
		if vid != "konoha":
			var rec = vs.request(vid)
			var t = 0.0
			while not rec.get("done", false) and t < 200.0:
				await _w(0.5)
				t += 0.5
		await _w(2.0)
		var targets = []
		var kinds = {}
		for it in Interact.items:
			var p0: Vector3 = it["pos"]
			if Vector2(p0.x - c.x, p0.z - c.z).length() < 200.0:
				kinds[String(it.get("kind", "")) + "/" + String(it.get("room", ""))] = true
		print("WDBG %s n=%d near=%s" % [vid, Interact.items.size(), kinds.keys()])
		for it in Interact.items:
			var k = String(it.get("kind", ""))
			var p: Vector3 = it["pos"]
			if Vector2(p.x - c.x, p.z - c.z).length() > float(v["r"]) * 0.6:
				continue
			if (k == "enter" and String(it.get("room", "")) == "kage") or k in ["mission_board", "oto_lair", "onsen"]:
				targets.append(it)
		for it in targets:
			var dp: Vector3 = it["pos"]
			var out = Vector3(dp.x - c.x, 0, dp.z - c.z)
			out = Vector3(0, 0, 1) if out.length() < 1.0 else out.normalized()
			var start = dp + out * 10.0
			start.y = Game.ground_height(start.x, start.z) + 0.5
			var reached = false
			var best = 1e9
			for flip in [0.0, 180.0]:
				pl.respawn(start)
				await _w(0.6)
				var to = dp - start
				pl.yaw = rad_to_deg(atan2(-to.x, -to.z)) + flip
				Input.action_press("forward")
				var d0 = pl.global_position.distance_to(dp)
				for s in 30:
					await _w(0.1)
					best = minf(best, pl.global_position.distance_to(dp))
					if Interact.nearest(pl.global_position) == it:
						reached = true
						break
				Input.action_release("forward")
				if reached or pl.global_position.distance_to(dp) < d0 - 1.0:
					break
			print("WALK %s %s '%s' ulaştı=%s en_yakın=%.1f r=%.1f" % [vid, it.get("kind"), String(it.get("label", "")).left(30), reached, best, float(it.get("radius", 0))])
	get_tree().quit()
