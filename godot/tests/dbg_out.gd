extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	for p in Game.pois:
		if p["t"] == "hamlet":
			var x = float(p["x"]); var y = float(p["y"])
			print("HAMLET bio=", Game.biome_at(x, -y), " country=", p.get("country"))
			break
	for rl in Game.roads:
		if rl["kind"] != "road": continue
		var pts: PackedVector2Array = rl["pts"]
		for i in range(1, pts.size() - 1, 3):
			var q = pts[i]
			var b = Game.biome_at(q.x, -q.y)
			if b in [8, 9] and Roadside._village_near(q.x, q.y) > 400.0:
				var cnt = {}
				for k in 200:
					var bb = Game.biome_at(q.x + randf_range(-200, 200), -q.y + randf_range(-200, 200))
					cnt[bb] = cnt.get(bb, 0) + 1
				print("NORTH ", q, " bio=", b, " around=", cnt, " clear=", Game._wh_vn(q.x / 260.0, -q.y / 260.0, 11))
				get_tree().quit()
				return
	get_tree().quit()
