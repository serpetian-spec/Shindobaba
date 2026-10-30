extends Node
## Yol-kapı uyumu: her köyde yolun sur çizgisini kestiği açıların hepsinde kapı var mı + Konoha kapılarından havadan görüntü
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	for v in Game.world_info["villages"]:
		var c = Vector2(v["x"], v["y"])
		var rg = float(v["r"]) * 0.95
		var hits = []
		for rd in Game.roads:
			if rd["kind"] != "road":
				continue
			var p: PackedVector2Array = rd["pts"]
			for i in p.size() - 1:
				var da = p[i].distance_to(c) - rg
				var db = p[i + 1].distance_to(c) - rg
				if da * db < 0.0:
					var h = p[i].lerp(p[i + 1], da / (da - db))
					hits.append(snappedf(fposmod(rad_to_deg(atan2(h.x - c.x, h.y - c.y)), 360.0), 0.1))
		var miss = hits.filter(func(a): return (v.get("gates", []) as Array).filter(func(g): return absf(fposmod(a - float(g) + 180.0, 360.0) - 180.0) < 6.0).is_empty())
		print("GATES ", v["id"], " gates=", v.get("gates", []), " hits=", hits, " MISSING=", miss)
	main.world.env.time_of_day = 0.42
	var cam = Camera3D.new()
	cam.far = 6000.0
	main.add_child(cam)
	cam.current = true
	main.world.env.attach_post(cam)
	var v = Game.village("konoha")
	var R = float(v["r"]) - 40.0
	for ga in v["gates"]:
		var a = deg_to_rad(float(ga))
		var gp = Vector2(v["x"], v["y"]) + Vector2(sin(a), cos(a)) * R
		var g3 = Game.from_map(gp)
		g3.y = Game.terrain_height(g3.x, g3.z)
		var out = Vector3(sin(a), 0, -cos(a))
		for st in [["in", -60.0], ["out", 70.0]]:
			var cp = g3 + out * st[1]
			cp.y = Game.terrain_height(cp.x, cp.z) + 4.0
			cam.global_position = cp
			cam.look_at(g3 + out * (-st[1]) * 0.5 + Vector3(0, 6, 0))
			await get_tree().create_timer(2.0).timeout
			await main.shot("gate_konoha_%d_%s" % [int(ga), st[0]])
	get_tree().quit()
