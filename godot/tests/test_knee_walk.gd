extends Node
## ANBU bacak parçaları yürürken uzuyor mu: koşu animasyonunda dizi yakından çek + köşe uzaklığı ölç
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
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.fov = 35.0
	for sid in OS.get_environment("SETS").split(",", false):
		Gear.grant(Game.profile, sid, "set")
		Gear.apply_look(Game.profile)
		pl.rebuild_model()
		await _w(3.5)
		for mm in get_tree().current_scene.find_children("*", "GeometryInstance3D", true, false):
			if mm is MultiMeshInstance3D:
				mm.queue_free()
		for nd in get_tree().current_scene.find_children("*", "GPUParticles3D", true, false):
			if not pl.is_ancestor_of(nd):
				nd.queue_free()
		pl.set_physics_process(false)
		pl.model.rotation.y = 0.0
		pl.model.play("run", 0.0)
		for k in 6:
			await _w(0.13)
			var p = pl.model.global_position
			# en uzak köşe: diz/bacak parçalarının köşeleri kemiklerden ne kadar uzak (uzayan sivri uç testi)
			var worst = 0.0
			for mi in pl.model.skel.get_children():
				if mi is MeshInstance3D and mi.mesh and mi.skin:
					pass
			cam.global_position = p + Vector3(-0.9, 0.55, -1.3)
			cam.look_at(p + Vector3(0, 0.5, 0))
			await main.shot("kw_%s_%d" % [sid, k])
			cam.global_position = p + Vector3(-1.0, 1.25, -0.9)
			cam.look_at(p + Vector3(0, 1.05, 0))
			await main.shot("ke_%s_%d" % [sid, k])
	get_tree().quit()
