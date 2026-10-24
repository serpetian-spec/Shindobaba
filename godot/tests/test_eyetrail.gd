extends Node
## Sharingan açıkken göz ışık izi: kafa dönerken yakın çekim
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken", "hair": Color(0.05, 0.05, 0.08), "top": Color(0.1, 0.12, 0.22), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.1, 0.1, 0.12)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	Hud.show_game_hud(false)
	var pl = main.player
	pl.combat.modes.eyes.toggle()
	await get_tree().create_timer(0.3).timeout
	var cam = Camera3D.new()
	get_tree().current_scene.add_child(cam)
	cam.fov = 35
	var c = pl.global_position + Vector3(0, 1.5, 0)
	cam.global_position = c + Vector3(1.6, 0.25, -2.2)
	cam.look_at(c)
	cam.current = true
	for i in 12:
		pl.facing += 0.12
		pl.global_position += Vector3(0.08, 0, 0)
		await get_tree().process_frame
		await get_tree().process_frame
	await main.shot("eyetrail_move")
	await get_tree().create_timer(0.6).timeout
	await main.shot("eyetrail_still")
	# yakın çekim: Sharingan deseni görünüyor mu
	var hc = pl.model.skel.get_bone_global_pose(pl.model.skel.find_bone("Head")).origin
	var head = pl.model.skel.global_transform * hc + Vector3(0, 0.06, 0)
	var fwd = Basis(Vector3.UP, pl.facing) * Vector3(0, 0, -1)
	cam.fov = 20
	cam.global_position = head + fwd * 0.75 + Vector3(0, 0.02, 0)
	cam.look_at(head)
	await get_tree().create_timer(0.4).timeout
	await main.shot("eyetrail_close")
	get_tree().quit()
