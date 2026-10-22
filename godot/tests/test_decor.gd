extends Node
## Dünya dekorasyonu turu: yol kenarı noktaları, çiftlik, mezra, orman, çöl, kuzey
var main: Node


## hedefe bakan konum: hedefin güneybatısından
func _look(target: Vector2, back := 38.0, pitch := -16.0) -> void:
	var from := target + Vector2(-0.7, -0.7) * back
	var d := Vector3(target.x - from.x, 0, -(target.y - from.y))
	_go(from, rad_to_deg(atan2(-d.x, -d.z)), pitch, 10.0)


func _go(m: Vector2, yaw: float, pitch := -14.0, dist := 16.0) -> void:
	var pl = main.player
	var p := Vector3(m.x, 0, -m.y)
	p.y = Game.terrain_height(p.x, p.z) + 0.3
	pl.global_position = p
	pl.velocity = Vector3.ZERO
	pl.reset_physics_interpolation()
	pl.yaw = yaw
	pl.pitch = pitch
	pl.cam_dist = dist


func _slot_of(t: String, skip := 0) -> Dictionary:
	var i := 0
	for k in Roadside.slots_by_region:
		for s in Roadside.slots_by_region[k]:
			if s["t"] == t:
				if i >= skip:
					return s
				i += 1
	return {}


func _road_point(bio_want: Array) -> Vector2:
	for rl in Game.roads:
		if rl["kind"] != "road":
			continue
		var pts: PackedVector2Array = rl["pts"]
		for i in range(1, pts.size() - 1, 3):
			var q := pts[i]
			if Game.biome_at(q.x, -q.y) in bio_want and Roadside._village_near(q.x, q.y) > 400.0:
				return q
	return Vector2.INF


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.42
	main.world.env.weather = "açık"
	main.world.env.region_weather = "açık"
	main.world.env.weather_t = 9999.0
	var counts := {}
	for k in Roadside.slots_by_region:
		for s in Roadside.slots_by_region[k]:
			counts[s["t"]] = counts.get(s["t"], 0) + 1
	var paths := 0
	for rl in Game.roads:
		if rl["kind"] == "path":
			paths += 1
	print("DECOR slots=", counts, " paths=", paths)
	var shots := []
	for t in ["farm", "campfire", "stall", "giant_tree", "battlefield", "shrine", "ruin_tower", "statue", "teahouse", "bridge", "cave", "rest", "haystack", "torii"]:
		var s := _slot_of(t)
		if not s.is_empty():
			shots.append([Vector2(s["x"], s["y"]), 70.0 if t in ["farm", "bridge"] else 26.0, "d_" + t, true])
	for p in Game.pois:
		if p["t"] == "hamlet":
			shots.append([Vector2(p["x"], p["y"]), 80.0, "d_mezra", true])
			break
	var fr := _road_point([2])
	if fr != Vector2.INF:
		shots.append([fr, 30.0, "d_orman_yolu"])
	var gr := _road_point([7, 6])
	if gr != Vector2.INF:
		shots.append([gr, 60.0, "d_cayir_yolu"])
	var de := _road_point([3])
	if de != Vector2.INF:
		shots.append([de, 90.0, "d_col_yolu"])
	var no := _road_point([8, 9])
	if no != Vector2.INF:
		shots.append([no, 120.0, "d_kuzey_yolu"])
	for sh in shots:
		if sh.size() > 3:
			_look(sh[0], sh[1])
		else:
			_go(sh[0], sh[1])
		await get_tree().create_timer(7.0).timeout
		await main.shot(sh[2])
	get_tree().quit()
