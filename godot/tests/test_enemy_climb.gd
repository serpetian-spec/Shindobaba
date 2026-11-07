extends Node
## Oyuncu 6 m ve 12 m yüksek bloğun üstündeyken: yakıncı haydut/ninja zıplayıp yanına çıkar, uzakçı aşağıdan atar
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _block(at: Vector3, h: float) -> void:
	var sb = StaticBody3D.new()
	var cs = CollisionShape3D.new()
	var bx = BoxShape3D.new()
	bx.size = Vector3(5, h, 5)
	cs.shape = bx
	sb.add_child(cs)
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = bx.size
	mi.mesh = bm
	sb.add_child(mi)
	get_tree().current_scene.add_child(sb)
	sb.global_position = at + Vector3.UP * h * 0.5

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl: Player = main.player
	pl.max_hp = 1e9
	pl.hp = 1e9
	var vs = Game.village("suna")
	var base = Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"]))
	for h in [6.0, 12.0]:
		for kind in ["bandit", "rogue"]:
			var g = Game.ground_height(base.x, base.z)
			var at = Vector3(base.x, g, base.z)
			_block(at, h)
			pl.respawn(at + Vector3.UP * (h + 1.0))
			await _w(1.0)
			var a = Enemy.archetype(kind, 0)
			a["respawn"] = false
			a["hp"] = 99999.0
			if kind == "rogue":
				a["jutsu"] = []   # yakıncı varyant
				a["tools"] = false
			var e = Enemy.new()
			e.setup(a)
			get_tree().current_scene.add_child(e)
			e.global_position = at + Vector3(9, 0.2, 0)
			e.home = e.global_position
			e.target = pl
			e.state = "chase"
			var top_t = -1.0
			for k in 60:
				await _w(0.1)
				if not is_instance_valid(e):
					break
				pl.combat.invuln = 5.0
				pl.global_position = at + Vector3.UP * h
				pl.velocity = Vector3.ZERO
				if h == 12.0 and kind == "bandit" and (k == 22 or k == 27):
					var cc = Camera3D.new()
					get_tree().current_scene.add_child(cc)
					cc.global_position = at + Vector3(14, h * 0.6, 10)
					cc.look_at(at + Vector3(2.5, h * 0.5, 0))
					cc.current = true
					await _w(0.02)
					await main.shot("climb_%d" % k)
					pl.cam.current = true
					cc.queue_free()
				if false:
					var r = e.global_position - at
					print("   t=%.1f rel=(%.1f,%.1f,%.1f) st=%s vel=%s fl=%s" % [k * 0.1, r.x, r.y, r.z, e.state, e.velocity.snapped(Vector3.ONE * 0.1), e.is_on_floor()])
				if top_t < 0 and e.global_position.y > at.y + h - 0.5 and Vector2(e.global_position.x - at.x, e.global_position.z - at.z).length() < 3.0:
					top_t = k * 0.1
			print("  pl_dy=%.1f" % (pl.global_position.y - at.y))
			print("  dbg floor=%s vel=%s grounded=%s state_t=%.1f" % [e.is_on_floor(), e.velocity, e.grounded, e.state_t])
			print("CLIMB h=%.0f %s reached_top=%s t=%.1f final_dy=%.1f state=%s" % [h, kind, top_t >= 0, top_t, e.global_position.y - at.y, e.state])
			e.queue_free()
			base += Vector3(40, 0, 0)
	# uzakçı: jutsu/alet varsa aşağıdan atar
	var g2 = Game.ground_height(base.x, base.z)
	var at2 = Vector3(base.x, g2, base.z)
	_block(at2, 8.0)
	pl.respawn(at2 + Vector3.UP * 9.0)
	await _w(1.0)
	var a2 = Enemy.archetype("rogue", 0)
	a2["respawn"] = false
	a2["hp"] = 99999.0
	a2["tools"] = true
	var e2 = Enemy.new()
	e2.setup(a2)
	get_tree().current_scene.add_child(e2)
	e2.global_position = at2 + Vector3(10, 0.2, 0)
	e2.home = e2.global_position
	e2.target = pl
	e2.state = "chase"
	var states = {}
	for k in 50:
		await _w(0.1)
		states[e2.state] = int(states.get(e2.state, 0)) + 1
	print("RANGED states=%s jutsu=%s" % [states, a2.get("jutsu", [])])
	get_tree().quit()
