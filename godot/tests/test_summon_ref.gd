extends Node
## Çağrı modelini referans açılarından çeker: MODEL, H, LEN, VER ortam değişkenleri
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.42
	var pl = main.player
	var a = Game.world_info["landmarks"].filter(func(l): return l.get("id", "") == "arena_earth")[0]
	var base = Game.from_map(Vector2(a["x"], a["y"]))
	pl.respawn(base)
	await get_tree().create_timer(2.5).timeout
	pl.set_process(false)
	TailedBeasts.set_process(false)
	for bb in get_tree().get_nodes_in_group("tailed_beasts"):
		bb.queue_free()
	var model = OS.get_environment("MODEL")
	var h = float(OS.get_environment("H"))
	var ln = float(OS.get_environment("LEN")) if OS.get_environment("LEN") != "" else h
	var ver = OS.get_environment("VER")
	var d = SummonModels.build(model, h, ln)
	var root: Node3D = d["root"]
	main.add_child(root)
	var p = base + Vector3(0, 0, -h * 3.0)
	p.y = Game.terrain_height(p.x, p.z)
	root.global_position = p
	await get_tree().create_timer(0.5).timeout
	var ab := AABB(); var first = true
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var w = mi.global_transform * mi.get_aabb()
		ab = w if first else ab.merge(w)
		first = false
	var L = maxf(ab.size.x, maxf(ab.size.y, ab.size.z))
	var ctr = ab.get_center()
	var fwd = Vector3(0, 0, -1)
	var right = Vector3(1, 0, 0)
	var top = Vector3(ctr.x, ab.position.y + ab.size.y * 0.75, ab.position.z + ab.size.z * 0.15)
	var shots = [
		["front", ctr + fwd * L * 1.1 + Vector3.UP * L * 0.1, ctr],
		["face", top + fwd * L * 0.55 + right * L * 0.18, top],
		["side", ctr + right * L * 1.2 + Vector3.UP * L * 0.15, ctr],
		["back", ctr - fwd * L * 1.0 + right * L * 0.4 + Vector3.UP * L * 0.4, ctr],
		["top", ctr + Vector3.UP * L * 1.3 + fwd * L * 0.15, ctr],
	]
	for s in shots:
		pl.cam.global_position = s[1]
		pl.cam.look_at(s[2])
		await get_tree().create_timer(0.25).timeout
		await main.shot("%s_%s_%s" % [model, ver, s[0]])
	get_tree().quit()
