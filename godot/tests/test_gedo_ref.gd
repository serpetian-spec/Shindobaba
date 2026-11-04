extends Node
## Gedō Mazō referans açıları (VER: sürüm etiketi, POSE: crouch/stand/rise, EYES: açık göz sayısı)
## g_front: önden alçak (Hanzō savaşı karesi), g_face: yüz yakın (çağırma karesi), g_side: yandan siluet, g_back: arkadan,
## g_scale: oyuncu ölçek karşılaştırması
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var a = Game.world_info["landmarks"].filter(func(l): return l.get("id", "") == "arena_earth")[0]
	var base = Game.from_map(Vector2(a["x"], a["y"]))
	pl.respawn(base)
	await get_tree().create_timer(3.0).timeout
	pl.set_process(false)
	TailedBeasts.set_process(false)
	for b in get_tree().get_nodes_in_group("tailed_beasts"):
		b.queue_free()
	await get_tree().process_frame
	var ver = OS.get_environment("VER")
	var pose = OS.get_environment("POSE")
	if pose == "":
		pose = "crouch"
	var p = base + Vector3(0, 0, -45.0)
	p.y = Game.terrain_height(p.x, p.z)
	var g = GedoMazo.spawn(main, p, 0.0, int(OS.get_environment("EYES")) if OS.get_environment("EYES") != "" else 2)
	g.set_pose(pose, 0.0)
	g.open_mouth(1.0 if OS.get_environment("MOUTH") == "1" else 0.0)
	await get_tree().create_timer(0.8).timeout
	var ab := AABB(); var first = true
	for mi in g.find_children("*", "MeshInstance3D", true, false):
		var w = mi.global_transform * mi.get_aabb()
		ab = w if first else ab.merge(w)
		first = false
	print("GEDO AABB size=", ab.size, " top=", ab.end.y - p.y)
	for aa in g.arms:
		var hand: Vector3 = aa["wr"].global_transform * Vector3(0, -0.9, 0)
		print("GEDO wrist y=%.1f handtip y=%.1f z=%.1f x=%.1f" % [aa["wr"].global_position.y - p.y, hand.y - p.y, hand.z - p.z, hand.x - p.x])
	print("GEDO head y=%.1f z=%.1f mouth y=%.1f" % [g.head.global_position.y - p.y, g.head.global_position.z - p.z, g.mouth_pos().y - p.y])
	var L = maxf(ab.size.x, maxf(ab.size.y, ab.size.z))
	var ctr = ab.get_center()
	var fwd = Vector3(0, 0, -1)
	var right = Vector3(1, 0, 0)
	var hp: Vector3 = g.head.global_transform * Vector3(0, 0.5, 0)
	var shots = [
		["front", ctr + fwd * L * 1.0 + Vector3.UP * (-ab.size.y * 0.25), ctr + Vector3.UP * ab.size.y * 0.08],
		["face", hp + fwd * 16.0 + right * 4.0 + Vector3.UP * 1.0, hp - Vector3.UP * 2.0],
		["side", ctr + right * L * 1.0 + Vector3.UP * L * 0.05, ctr],
		["back", ctr - fwd * L * 0.8 + right * L * 0.35 + Vector3.UP * L * 0.25, ctr],
		["scale", pl.global_position + Vector3(4, 2.0, 10), ctr + Vector3.UP * ab.size.y * 0.1],
	]
	for s in shots:
		pl.cam.global_position = s[1]
		pl.cam.look_at(s[2])
		await get_tree().create_timer(0.25).timeout
		await main.shot("g_%s_%s" % [ver, s[0]])
	get_tree().quit()
