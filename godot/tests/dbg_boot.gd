extends Node
## Deri çizme: koşu animasyonunda iki yandan yakın çekim (ayak bükülünce halka / dikiş)
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.2, 0.45), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	Hud.show_game_hud(false)
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	pl.set_process(false)
	var cam = get_viewport().get_camera_3d()
	var v = Villager.new()
	v.role = "guard"
	v.look_extra = {"foot_style": "cizme", "sandal": Color(0.28, 0.2, 0.14), "weapon_r": null, "back_item": null}
	main.actors.add_child(v)
	var base = pl.global_position + Vector3(30, 0, 30)
	base.y = Game.ground_height(base.x, base.z)
	v.global_position = base
	v.set_physics_process(false)
	v.set_process(false)
	await get_tree().create_timer(0.4).timeout
	v.model.rotation.y = 0.0
	for an in ["run", "idle"]:
		v.model.play(an, 0.0)
		for k in 3:
			await get_tree().create_timer(0.17).timeout
			var ang = [90.0, -90.0, 30.0][k]
			var dir = Vector3(sin(deg_to_rad(ang)), 0.2, cos(deg_to_rad(ang))).normalized()
			var sk: Skeleton3D = v.model.skel
			var fp = (sk.global_transform * sk.get_bone_global_pose(sk.find_bone("LeftLowerLeg"))).origin
			cam.global_position = fp + dir * 1.1
			cam.look_at(fp, Vector3.UP)
			await get_tree().process_frame
			await main.shot("boot_%s_%d" % [an, k])
	get_tree().quit()
