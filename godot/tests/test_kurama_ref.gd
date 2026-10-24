extends Node
## Kurama'yı referans görüntülerin açılarından çeker (VER ortam değişkeni: sürüm etiketi)
## k_front: önden alçak (Kurama2), k_face: yüz yakın, yarı profil (Kurama Stares Down), k_side: yandan siluet, k_back: arkadan
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
	var r = BeastModels.build("kurama")
	main.add_child(r)
	var p = base + Vector3(0, 0, -r.height_m * 1.2)
	p.y = Game.terrain_height(p.x, p.z)
	r.global_position = p
	r.rotation.y = 0.0   # -Z'ye (kameraya doğru, kamera -Z tarafında) değil: model önü -Z, kamera önünde
	await get_tree().create_timer(0.8).timeout
	var h = r.height_m
	var fwd = Basis(Vector3.UP, r.rotation.y) * Vector3(0, 0, -1)
	var right = fwd.cross(Vector3.UP)
	var hp: Vector3 = r.head.global_position
	# modelin gerçek kapladığı alan (kuyruklar dahil)
	var ab := AABB(); var first = true
	for mi in r.find_children("*", "MeshInstance3D", true, false):
		var w = mi.global_transform * mi.get_aabb()
		ab = w if first else ab.merge(w)
		first = false
	var L = maxf(ab.size.x, maxf(ab.size.y, ab.size.z))
	var ctr = ab.get_center()
	var shots = [
		["front", hp + fwd * h * 1.25 + Vector3.UP * h * 0.05, hp + Vector3.UP * h * 0.08 - fwd * h * 0.3],
		["face", hp + fwd * h * 0.42 + right * h * 0.2 - Vector3.UP * h * 0.02, hp + Vector3.UP * h * 0.04],
		["side", ctr + right * L * 0.8 + Vector3.UP * L * 0.05, ctr],
		["back", ctr - fwd * L * 0.7 + right * L * 0.3 + Vector3.UP * L * 0.3, ctr],
	]
	for s in shots:
		pl.cam.global_position = s[1]
		pl.cam.look_at(s[2])
		await get_tree().create_timer(0.25).timeout
		await main.shot("k_%s_%s" % [ver, s[0]])
	get_tree().quit()
