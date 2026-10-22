extends Node
## Kuyruklu canavar dövüşü + jinchūriki: doğma, saldırılar, tırmanma, mühürleme, pelerin seviyeleri, tam dönüşüm, zihin dünyası
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uzumaki", "element": "katon", "hair_style": "diken", "hair": Color(0.95, 0.8, 0.25), "top": Color(0.95, 0.5, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	var pr = Game.profile
	pr["level"] = 35
	pr["rank"] = 3
	var pl = main.player
	pl.apply_profile_stats()
	pl.max_chakra = 999.0
	var id = "shukaku"
	var lair: Vector2 = TailedBeasts.LAIRS[id]
	var start = Game.from_map(lair + Vector2(0, -170))
	pl.respawn(start)
	await get_tree().create_timer(4.0).timeout
	var b: TailedBeast = TailedBeasts.spawned.get(id)
	print("BEAST spawned=", b != null)
	if b == null:
		get_tree().quit()
		return
	pl.yaw = rad_to_deg(atan2(-(b.global_position - pl.global_position).x, -(b.global_position - pl.global_position).z))
	pl.pitch = -2.0
	await get_tree().create_timer(3.0).timeout
	print("aggro=", b.aggro, " hp=", b.hp, "/", b.max_hp)
	await main.shot("f1_baslangic")
	b.atk = ""
	b._begin("ball", 0.0)
	await get_tree().create_timer(2.2).timeout
	await main.shot("f2_top_sarj")
	await get_tree().create_timer(1.6).timeout
	await main.shot("f3_top_patlama")
	b.atk = ""
	b._begin("stomp", 0.0)
	await get_tree().create_timer(0.95).timeout
	await main.shot("f4_tepme")
	# tırmanma: başa yakın zayıf noktaya
	var w: Node3D = b.rig.weak_points[0]
	b.atk = ""
	b.set_physics_process(false)
	b.atk_cd = 99.0   # test: tırmanırken canavar saldırmasın (oyunda saldırır ve düşürebilir)
	pl.respawn(w.global_position + Vector3.UP * 1.5)
	print("test_move down collides=", pl.test_move(pl.global_transform, Vector3.DOWN * 8.0))
	for ch in pl.get_children():
		if ch is CollisionShape3D:
			print("  shape ", ch.shape, " disabled=", ch.disabled, " pos=", ch.position)
	print("mask=", pl.collision_mask, " layer=", pl.collision_layer, " shapes=", pl.get_child_count())
	var q2 = PhysicsRayQueryParameters3D.create(pl.global_position + Vector3.UP, pl.global_position + Vector3.DOWN * 40.0, pl.collision_mask, [pl.get_rid()])
	print("ray below player: ", pl.get_world_3d().direct_space_state.intersect_ray(q2).get("position", "YOK"))
	for i in 15:
		await get_tree().create_timer(0.1).timeout
		var hb = b.rig.colliders[1].get_meta("body")
		var rel = hb.global_transform.affine_inverse() * pl.global_position
		print("  t=%.1f y=%.1f vy=%.1f floor=%s headbody=%s rel=%s size=%s" % [i * 0.1, pl.global_position.y, pl.velocity.y, pl.is_on_floor(), hb.global_position, rel, hb.get_child(0).shape.size])
	print("tırmanma: oyuncu y=", pl.global_position.y, " zayıf nokta y=", w.global_position.y, " yerde=", pl.grounded or pl.is_on_floor())
	await main.shot("f5_tirmanma")
	b.set_physics_process(true)
	var hp0 = b.hp
	Combat.hit_sphere(pl, pl.global_position + Vector3.UP, 3.0, {"dmg": 100.0, "kind": "light"})
	print("zayıf nokta hasarı: ", hp0 - b.hp)
	# boyun eğdir + mühürle
	b.take_hit({"dmg": 1e7, "attacker": pl})
	await get_tree().create_timer(2.5).timeout
	pl.respawn(b.global_position + Vector3(0, 0, b.height * 0.5))
	await get_tree().create_timer(1.0).timeout
	print("subdued=", b.subdued, " seal item=", not b.seal_item.is_empty(), " interact=", Interact.nearest(pl.global_position).get("kind", ""))
	await main.shot("f6_diz_coktu")
	TailedBeasts._finish_seal(b, "player")
	await get_tree().create_timer(2.5).timeout
	print("jinchuriki=", TailedBeasts.player_jinchuriki())
	await main.shot("f7_muhur")
	# pelerin seviyeleri
	var cl: BeastCloak = pl.combat.modes.cloak
	TailedBeasts.add_trust(100.0)
	pl.cam_dist = 3.6
	pl.pitch = -8.0
	for lv in [1, 4, 5]:
		cl.set_level(lv)
		await get_tree().create_timer(1.2).timeout
		await main.shot("f8_pelerin_%d" % lv)
	cl.set_level(6)
	await get_tree().create_timer(2.0).timeout
	await main.shot("f9_tam_donusum")
	cl.bomb_cd = 0.0
	cl._bomb()
	await get_tree().create_timer(1.6).timeout
	await main.shot("f10_canavar_topu")
	cl.set_level(0)
	await get_tree().create_timer(0.6).timeout
	TailedBeasts.enter_mindscape()
	await get_tree().create_timer(2.5).timeout
	pl.cam_dist = 6.0
	pl.yaw = 0.0
	pl.pitch = -4.0
	await get_tree().create_timer(0.6).timeout
	await main.shot("f11_zihin")
	print("zihin: oyuncu y=", pl.global_position.y, " yerde=", pl.is_on_floor())
	TailedBeasts.exit_mindscape()
	await get_tree().create_timer(2.0).timeout
	print("dönüş y=", pl.global_position.y)
	get_tree().quit()
