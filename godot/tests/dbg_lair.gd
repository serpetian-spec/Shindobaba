extends Node
var main: Node
func _flat(p: Vector3) -> float:
	var h0 = Game.terrain_height(p.x, p.z)
	var m = 0.0
	for k in 8:
		var a = TAU * k / 8.0
		var q = p + Vector3(cos(a), 0, sin(a)) * 120.0
		m = maxf(m, absf(Game.terrain_height(q.x, q.z) - h0))
	return m
func _ready() -> void:
	await get_tree().process_frame
	for id in ["kokuo", "saiken", "chomei"]:
		var l: Vector2 = TailedBeasts.LAIRS[id]
		var best = Vector2.ZERO; var bs = 1e9
		for r in range(0, 9000, 300):
			for k in 24:
				var a = TAU * k / 24.0
				var m = l + Vector2(cos(a), sin(a)) * r
				var p = Game.from_map(m)
				var b = Game.biome_at(p.x, p.z)
				if b in [0, 2, 1, 11, 4] or Game.terrain_height(p.x, p.z) < 3.0:
					continue
				var ok = true
				for kk in 8:
					var q = p + Vector3(cos(TAU * kk / 8.0), 0, sin(TAU * kk / 8.0)) * 150.0
					if Game.biome_at(q.x, q.z) in [0, 2, 11] or Game.terrain_height(q.x, q.z) < 3.0:
						ok = false
				if not ok:
					continue
				var f = _flat(p)
				var score = r * 0.002 + f
				if f < 12.0 and score < bs:
					bs = score; best = m
			if bs < 1e8 and r > 1500:
				break
		var bp = Game.from_map(best)
		print("NEWLAIR ", id, " ", best, " biome=", Game.biome_at(bp.x, bp.z), " flat=", _flat(bp))
	get_tree().quit()
