extends Node
## Kurbağa çağrılarının imza teknikleri: küçük su tükürüğü, dev: su topu / yağ / kılıç
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.0).timeout
	Hud.show_game_hud(false)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	for tr in [0, 2]:
		var s = Summon.new()
		s.contract = "kurbağa"; s.tier = tr; s.def = Contracts.DEFS["kurbağa"]["tiers"][tr]
		s.owner_f = pl; s.team = pl.team
		get_tree().current_scene.add_child(s)
		s.global_position = pl.global_position + Vector3(0, 0, -6 - tr * 6)
		s.set_physics_process(false)
		var e = Enemy.new()
		var a = Enemy.archetype("bandit", 0)
		a["hp"] = 5000.0
		e.setup(a)
		get_tree().current_scene.add_child(e)
		e.global_position = s.global_position + Vector3(0, 0, -6 - tr * 4)
		e.set_physics_process(false)
		s.tgt = e
		s.facing = PI
		for n in (3 if tr == 2 else 1):
			var hp0 = e.hp
			s._special()
			await get_tree().create_timer(0.15).timeout
			if n == 1 or tr == 0:
				cam.global_position = s.global_position + Vector3(14 + tr * 6, 6 + tr * 3, -6)
				cam.look_at(s.global_position + Vector3(0, 2, -6 - tr * 2))
				await main.shot("toad_%d_%d" % [tr, n])
			await get_tree().create_timer(0.8).timeout
			print("TS tier=%d n=%d model=%s dmg=%.0f" % [tr, n, s.def.get("model", ""), hp0 - e.hp])
		s.queue_free(); e.queue_free()
		await get_tree().create_timer(0.3).timeout
	get_tree().quit()
