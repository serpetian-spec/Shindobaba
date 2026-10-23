extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var pl = main.player
	Game.world.env.weather_t = 9999.0
	Game.world.env.region_weather = "açık"
	var v = Game.village("konoha")
	var R = float(v["r"])
	var vp = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	for spot in [["kapı", Vector2(0, -R - 120)], ["orman", Vector2(-300, -R - 600)], ["orman2", Vector2(-900, -R - 200)], ["orman3", Vector2(-700, -R - 500)], ["orman4", Vector2(0, -R - 420)]]:
		pl.respawn(Game.from_map(Vector2(v["x"], v["y"]) + spot[1]))
		await get_tree().create_timer(12.0).timeout
		await main.shot("ff_" + spot[0])
		var t = 0.0; var n = 0; var gpu = 0.0; var cpu = 0.0
		var t0 = Time.get_ticks_usec()
		for i in 120:
			await get_tree().process_frame
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
			cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp) + RenderingServer.get_frame_setup_time_cpu()
		var ft = (Time.get_ticks_usec() - t0) / 120000.0
		print("ORMAN ", spot[0], " kare=%.1f ms gpu=%.1f render_cpu=%.1f proc=%.1f phys=%.1f draw=%d obj=%d prim=%d chunks=%d" % [ft, gpu / 120.0, cpu / 120.0,
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), Game.world.vegetation.chunks.size()])
		# vegetation kapatınca
		Game.world.vegetation.visible = false
		await get_tree().create_timer(0.5).timeout
		t0 = Time.get_ticks_usec(); gpu = 0.0
		for i in 60:
			await get_tree().process_frame
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
		print("   bitkisiz kare=%.1f gpu=%.1f" % [(Time.get_ticks_usec() - t0) / 60000.0, gpu / 60.0])
		Game.world.vegetation.visible = true
		Game.world.vegetation.set_process(false)
		await get_tree().create_timer(0.3).timeout
		t0 = Time.get_ticks_usec()
		for i in 60:
			await get_tree().process_frame
		print("   bitki _process kapalı kare=%.1f" % [(Time.get_ticks_usec() - t0) / 60000.0])
		Game.world.vegetation.set_process(true)
	get_tree().quit()
