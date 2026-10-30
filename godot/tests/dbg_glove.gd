extends Node
## Eldiven plakası: 4 yerleşim denemesi, el yakın çekim
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	pl.set_process(false)
	var cam = get_viewport().get_camera_3d()
	var vars = [[0, 0]]
	for k in vars.size():
		var v = Villager.new()
		v.role = "guard"
		v.look_extra = {"gloves": true, "arm_wraps": true, "acc": Color(0.6, 0.62, 0.66), "top_style": "kolsuz", "weapon_r": null, "back_item": null}
		main.actors.add_child(v)
		var base = pl.global_position + Vector3(30 + k * 3, 0, 30)
		base.y = Game.ground_height(base.x, base.z)
		v.global_position = base
		v.set_physics_process(false)
		v.set_process(false)
		await get_tree().create_timer(0.4).timeout
		v.model.play("idle", 0.0)
		v.model.rotation.y = 0.0
		await get_tree().create_timer(0.4).timeout
		var sk: Skeleton3D = v.model.skel
		var bi = sk.find_bone("RightHand")
		var hp = sk.global_transform * sk.get_bone_global_pose(bi)
		for ang in [-60.0, 0.0, 60.0, 120.0]:
			var dir = Vector3(sin(deg_to_rad(ang)), 0.15, cos(deg_to_rad(ang))).normalized()
			cam.global_position = hp.origin + dir * 0.32
			cam.look_at(hp.origin, Vector3.UP)
			await get_tree().process_frame
			await get_tree().process_frame
			await main.shot("gv%d_%d" % [k, int(ang)])
		v.queue_free()
	get_tree().quit()
