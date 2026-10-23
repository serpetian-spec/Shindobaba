extends Node
var main: Node
func _gpu(vp, n := 40) -> float:
	var g = 0.0
	for i in n:
		await get_tree().process_frame
		g += RenderingServer.viewport_get_measured_render_time_gpu(vp)
	return g / n
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var pl = main.player
	var veg = Game.world.vegetation
	var vp = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var v = Game.village("konoha")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"]) + Vector2(-300, -float(v["r"]) - 600)))
	await get_tree().create_timer(12.0).timeout
	veg.set_process(false)
	await main.shot("vt_base")
	print("TEMEL gpu=%.1f" % await _gpu(vp))
	var sun = Game.world.env.sun
	sun.shadow_enabled = false
	print("gölgesiz gpu=%.1f" % await _gpu(vp))
	sun.shadow_enabled = true
	Game.world.env.post.visible = false
	print("çizgisiz gpu=%.1f" % await _gpu(vp))
	Game.world.env.post.visible = true
	# mesh başına gizle
	var groups = {}
	for k in veg.chunks:
		for mmi in veg.chunks[k]["node"].get_children():
			if mmi is MultiMeshInstance3D:
				var key = mmi.multimesh.mesh.get_instance_id()
				if not groups.has(key):
					groups[key] = []
				groups[key].append(mmi)
	var res = []
	for key in groups:
		for m in groups[key]:
			m.visible = false
		var g = await _gpu(vp, 20)
		for m in groups[key]:
			m.visible = true
		res.append([g, key, groups[key].size(), int(groups[key][0].visibility_range_begin), groups[key][0].cast_shadow, groups[key][0].multimesh.mesh.get_surface_count()])
	res.sort_custom(func(a, b): return a[0] < b[0])
	for r in res.slice(0, 8):
		print("GİZLE mesh=%d n=%d b=%d sh=%d surf=%d -> gpu=%.1f" % [r[1] % 10000, r[2], r[3], r[4], r[5], r[0]])
	# grass
	var grass = Game.world.get_node_or_null("Grass")
	if grass:
		grass.visible = false
		print("çimsiz gpu=%.1f" % await _gpu(vp))
		grass.visible = true
	Game.world.terrain.visible = false
	print("arazisiz gpu=%.1f" % await _gpu(vp))
	get_tree().quit()
