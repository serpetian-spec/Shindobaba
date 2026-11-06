extends Node
## Kaçak Sığınağı: içeri gir, NPC'lerin duvara/kayaya gömülü olmadığını ölç, 6 açıdan çek
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.5).timeout
	Hud.close_dialog()
	Hud.show_game_hud(false)
	var pl = main.player
	Interiors.inst.enter({"pos": pl.global_position, "room": "rogue_hideout", "label": "x"})
	await get_tree().create_timer(3.0).timeout
	var it = Interiors.inst
	var o: Vector3 = it.origin
	var space = get_viewport().world_3d.direct_space_state
	var bad = 0
	var n = 0
	for v in get_tree().get_nodes_in_group("villagers") if get_tree().has_group("villagers") else []:
		pass
	for v in it.room.get_children():
		if v is Villager or (v.get_script() and String(v.get_script().resource_path).ends_with("villager.gd")):
			n += 1
			var lp = v.global_position - o
			# kişinin göğüs hizasında küçük küre: statik çarpışmanın içinde mi?
			var q = PhysicsShapeQueryParameters3D.new()
			var sh = SphereShape3D.new()
			sh.radius = 0.25
			q.shape = sh
			q.transform = Transform3D(Basis(), v.global_position + Vector3.UP * 1.1)
			q.collision_mask = 1
			var hits = space.intersect_shape(q, 4)
			hits = hits.filter(func(h): return not (h["collider"] is CharacterBody3D))
			var in_wall = absf(lp.x) > 15.0 - 2.0 or -lp.z > 52.0 - 1.5
			if not hits.is_empty() or in_wall:
				bad += 1
				print("CAVE GÖMÜLÜ %s x=%.1f d=%.1f çarpışma=%d" % [v.get("display_name") if v.get("display_name") else v.name, lp.x, -lp.z, hits.size()])
	print("CAVE NPC=%d gömülü=%d" % [n, bad])
	# oyun içi: oyuncu boyutunda kapsül girişten koridora, oradan her etkileşim noktasına yürür (takılırsa yeri yazılır)
	var probe = CharacterBody3D.new()
	var pcs = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	pcs.shape = cap
	pcs.position.y = 0.9
	probe.add_child(pcs)
	probe.collision_mask = 1
	it.room.add_child(probe)
	var walk = func(path: Array) -> String:
		probe.global_position = o + Vector3(0, 0.05, -2.4)
		await get_tree().physics_frame
		for wp in path:
			var goal: Vector3 = o + Vector3(wp[0], 0.05, -wp[1])
			for step in 400:
				var dv = goal - probe.global_position
				dv.y = 0
				if dv.length() < 0.3:
					break
				var col = probe.move_and_collide(dv.normalized() * minf(0.15, dv.length()))
				if col:
					# eğimde/engelde kay (rampa yukarı çıkar)
					var slide = dv.normalized().slide(col.get_normal()) * 0.15
					probe.move_and_collide(slide)
				if step == 399:
					var lp = probe.global_position - o
					return "TAKILDI x=%.1f d=%.1f (hedef %s)" % [lp.x, -lp.z, str(wp)]
		return "ok"
	var acts = it.items.filter(func(x): return x["kind"] != "exit")
	for a in acts:
		var lp = (a["pos"] as Vector3) - o
		var stand = Vector2(lp.x + (2.4 if lp.x < -3 else 0.0), -lp.z - (3.6 if absf(lp.x) < 3 else 0.0))   # tezgâhın önü / masanın önü
		var r = await walk.call([[0.0, 9.0], [0.0, stand.y], [stand.x, stand.y]])
		Hud.close_dialog()
		Menus.clear()
		Game.ui_open = false
		Progress.interact(a)
		await get_tree().create_timer(0.2).timeout
		var reach = probe.global_position.distance_to(Vector3(a["pos"].x, probe.global_position.y, a["pos"].z))
		var near = Interact.nearest(probe.global_position)
		print("CAVE ETK %s: yürüme=%s  menzil=%.1f/%.1f  [F] buluyor=%s" % [a["kind"], r, reach, float(a["radius"]), String(near.get("kind", "-")) == a["kind"]])
		Hud.close_dialog()
		Menus.clear()
		Game.ui_open = false
	probe.queue_free()
	pl.set_process(false)
	pl.set_physics_process(false)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.current = true
	cc.fov = 70
	var L = func(x, y, d): return o + Vector3(x, y, -d)
	var views = {
		"giris": [L.call(0, 2.2, 3.0), L.call(0, 2.5, 25.0)],
		"salon": [L.call(10, 7.0, 9.0), L.call(-2, 1.0, 30.0)],
		"ates": [L.call(3.5, 1.8, 18.5), L.call(0, 0.6, 23.0)],
		"pazar": [L.call(-3.0, 2.2, 10.0), L.call(-9.5, 1.2, 22.0)],
		"yatak": [L.call(6.0, 2.2, 10.0), L.call(11.4, 0.5, 18.0)],
		"simsar": [L.call(0, 2.0, 38.0), L.call(0, 1.6, 47.5)],
	}
	for k in views:
		cc.global_position = views[k][0]
		cc.look_at(views[k][1])
		await get_tree().create_timer(0.3).timeout
		await main.shot("cave_" + k)
	get_tree().quit()
