extends Node
## Köy denetimi: her büyük köyde dükkân/terzi/sözleşme ustası noktaları, erişilebilirlik, gezinen NPC sayısı (+ çekim)
var main: Node

func _blocked(q: Vector3) -> bool:
	var sq = PhysicsShapeQueryParameters3D.new()
	var sph = SphereShape3D.new()
	sph.radius = 0.4
	sq.shape = sph
	sq.collision_mask = 1
	sq.transform = Transform3D(Basis.IDENTITY, q + Vector3.UP * 1.0)
	return not main.player.get_world_3d().direct_space_state.intersect_shape(sq, 1).is_empty()

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var life = main.actors.get_node_or_null("VillageLife")
	for vid in ["konoha", "suna", "kiri", "kumo", "iwa"]:
		var v = Game.village(vid)
		var c = Game.from_map(Vector2(v["x"], v["y"]))
		pl.respawn(Missions.open_ground(c + Vector3(30, 0, 30), 40.0))
		if Game.world:
			Game.world.env.time_of_day = 0.5
		await get_tree().create_timer(14.0).timeout
		var kinds = {}
		for it in Interact.items:
			var p: Vector3 = it.get("pos", Vector3.ZERO)
			if Vector2(p.x - c.x, p.z - c.z).length() < float(v["r"]) * 1.1:
				var k = String(it.get("kind", ""))
				kinds[k] = int(kinds.get(k, 0)) + 1
				if k in ["contract_keeper", "tailor", "shop_weapons", "shop_items"]:
					var gy = Game.ground_height(p.x, p.z)
					print("  %s %s at=%s blocked=%s" % [vid, k, p, _blocked(Vector3(p.x, gy, p.z))])
		var n = 0
		if life:
			for x in life.npcs:
				if is_instance_valid(x):
					n += 1
		print("AUDIT %s npcs=%d queue=%d inv=%s d=%.0f r=%.0f swim=%s cur=%s kinds=%s" % [vid, n, life.queue.size() if life else -1, life._village_at(pl.global_position).get("id", "-"), Game.to_map(pl.global_position).distance_to(Vector2(v["x"], v["y"])), float(v["r"]), pl.get("swimming"), life.current, kinds])
		pl.set_process(false)
		pl.cam.global_position = pl.global_position + Vector3(0, 30, 45)
		pl.cam.look_at(pl.global_position)
		await get_tree().create_timer(0.2).timeout
		await main.shot("audit_" + vid)
		pl.set_process(true)
	get_tree().quit()
