extends Node
## NPC takılma testi: Konoha sokaklarında öğlen, hareket eden köylüleri izler.
## "donmuş": yürümek isterken 3 sn'de 0.4 m'den az ilerleme; "duvar": duvara sürtünme süresi.
## --old: NpcNav kapalı (eski davranış) karşılaştırması.
var main: Node
var stick := 0  # 1.5 sn'den uzun duvara yapışma olayı
var last := {}
var hug := {}  # id -> kesintisiz statik duvar teması (sn)


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	NpcNav.enabled = not OS.get_cmdline_user_args().has("--old")
	main._start_new_game()
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.5
	var v = Game.village("konoha")
	var pl = main.player
	var frozen = 0
	var samples = 0
	var wall_t = 0.0
	var move_t = 0.0
	stick = 0
	for q in [Vector2(-20, -6), Vector2(-60, -320), Vector2(300, -260), Vector2(-380, 260), Vector2(200, 200), Vector2(-250, -600)]:
		var p = Game.from_map(Vector2(v["x"], v["y"]) + q)
		p.y = Game.ground_height(p.x, p.z) + 0.2
		pl.respawn(p)
		pl.cam_dist = 14.0
		pl.pitch = -30.0
		await get_tree().create_timer(6.0).timeout
		last.clear()
		for sec in 40:
			for k in 10:
				await get_tree().create_timer(0.1).timeout
				for n in get_tree().get_nodes_in_group("talkers"):
					if n is Villager and n.role in ["walker", "kid", "shopper", "patrol", "drunk"] and n.global_position.distance_to(pl.global_position) < 60.0 and n.wait <= 0.0 and not n.fading:
						move_t += 0.1
						var id2 = n.get_instance_id()
						var stat = false
						if n.is_on_wall():
							for ci in n.get_slide_collision_count():
								if n.get_slide_collision(ci).get_collider() is StaticBody3D:
									stat = true
						if stat:
							wall_t += 0.1
							hug[id2] = float(hug.get(id2, 0.0)) + 0.1
							if absf(hug[id2] - 1.5) < 0.05:
								stick += 1
						else:
							hug[id2] = 0.0
			if sec % 3 == 2:
				for n in get_tree().get_nodes_in_group("talkers"):
					if not (n is Villager) or n.role not in ["walker", "kid", "shopper", "patrol", "drunk"]:
						continue
					if n.global_position.distance_to(pl.global_position) > 60.0:
						continue
					var id = n.get_instance_id()
					if last.has(id) and n.wait <= 0.0 and Vector2(n.goal.x - n.global_position.x, n.goal.z - n.global_position.z).length() > 2.0:
						samples += 1
						if n.global_position.distance_to(last[id]) < 0.4:
							frozen += 1
					last[id] = n.global_position
		await main.shot("npc_%d_%s" % [int(q.x), "eski" if not NpcNav.enabled else "yeni"])
	print("NPC SONUC %s: donmus=%d/%d (%.1f%%) duvar=%.1f/%.1f sn (%.1f%%) yapisma(>1.5sn)=%d takilma=%d isin=%d" % ["eski" if not NpcNav.enabled else "yeni",
		frozen, samples, 100.0 * frozen / maxf(1, samples), wall_t, move_t, 100.0 * wall_t / maxf(0.1, move_t), stick, NpcNav.stuck_events, NpcNav.rays])
	get_tree().quit()
