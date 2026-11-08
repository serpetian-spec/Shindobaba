extends Node
## SETS=id1,id2 → her set için ön/arka/yan/çapraz + yakın çekim
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": OS.get_environment("SV_G") if OS.get_environment("SV_G") != "" else "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.5)
	Hud.close_dialog()
	Hud.visible = false
	var pl = main.player
	var sp = Missions._spot("konoha", 600, 900)
	var base = Missions.open_ground(Game.from_map(Vector2(sp[0], sp[1])) + Vector3(25, 0, 25), 60.0)
	pl.respawn(base + Vector3(0, 0.5, 0))
	await _w(1.0)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.fov = 40.0
	for sid in OS.get_environment("SETS").split(",", false):
		Gear.grant(Game.profile, sid, "set")
		Gear.apply_look(Game.profile)
		pl.rebuild_model()
		await _w(3.0)
		pl.facing = 0.0
		pl.model.rotation.y = 0.0
		for mm in get_tree().current_scene.find_children("*", "GeometryInstance3D", true, false):
			if mm is MultiMeshInstance3D or "rass" in String(mm.name) or "imen" in String(mm.name):
				mm.visible = false
				mm.set_process(false)
				mm.set_physics_process(false)
				mm.queue_free()
		for nd in get_tree().current_scene.find_children("*", "GPUParticles3D", true, false):
			if not pl.is_ancestor_of(nd):
				nd.queue_free()
		var p = pl.model.global_position
		print("SV pos ", p, " pl ", pl.global_position)
		var views = [Vector3(0, 1.0, -3.2), Vector3(0, 1.0, 3.2), Vector3(-3.2, 1.0, 0.0), Vector3(-1.9, 1.3, -1.9), Vector3(0, 1.3, -1.2), Vector3(0, 0.5, -1.4), Vector3(-1.1, 1.0, -0.6), Vector3(1.1, 1.0, -0.6)]
		var looks = [0.95, 0.95, 0.95, 0.95, 1.3, 0.45, 1.0, 1.0]
		for k in views.size():
			cam.global_position = p + views[k]
			cam.look_at(p + Vector3(0, looks[k], 0))
			await _w(0.25)
			await main.shot("sv_%s_%d" % [sid, k])
	get_tree().quit()
