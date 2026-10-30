extends Node
## Sengoku Yoroi: dört renk, önden / yandan / arkadan + koşu pozu
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	Hud.show_game_hud(false)
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	pl.set_process(false)
	var cam = get_viewport().get_camera_3d()
	var cols = [Color(0.55, 0.14, 0.11), Color(0.16, 0.22, 0.38)]
	var k = 0
	for c in cols:
		var v = Villager.new()
		v.role = "guard"
		v.look_extra = {"vest": c, "vest_style": 6, "armor_style": "sengoku", "weapon_r": "katana", "back_item": null, "top": Color(0.12, 0.12, 0.14), "pants": Color(0.12, 0.12, 0.14)}
		main.actors.add_child(v)
		var base = Missions.open_ground(pl.global_position + Vector3(30 + k * 6, 0, 30), 80.0)
		v.global_position = base
		v.set_physics_process(false)
		v.set_process(false)
		await get_tree().create_timer(0.5).timeout
		v.model.rotation.y = 0.0
		for an in ["idle", "run"]:
			v.model.play(an, 0.0)
			await get_tree().create_timer(0.25).timeout
			for ang in [0.0, 90.0, 200.0]:
				var dir = Vector3(sin(deg_to_rad(ang)), 0.15, cos(deg_to_rad(ang))).normalized()
				var hb = v.model.global_position
				cam.global_position = hb + Vector3(0, 1.1, 0) + dir * 2.6
				cam.look_at(hb + Vector3(0, 1.0, 0), Vector3.UP)
				await get_tree().process_frame
				await main.shot("arm%d_%s_%d" % [k, an, int(ang)])
		k += 1
	get_tree().quit()
