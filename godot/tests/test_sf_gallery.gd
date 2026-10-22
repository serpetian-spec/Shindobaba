extends Node
## Sketchfab model galerisi: her model 6 m yüksekliğe ölçeklenip tek tek çekilir
var main: Node
func _aabb(n: Node3D) -> AABB:
	var ab = AABB(); var first = true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var a = mi.global_transform * mi.get_aabb()
		ab = a if first else ab.merge(a)
		first = false
	return ab
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.42
	main.world.env.region_weather = "açık"
	main.world.env.weather_t = 9999.0
	var pl = main.player
	await get_tree().create_timer(2.0).timeout
	pl.set_process(false)
	TailedBeasts.set_process(false)
	var base = pl.global_position + Vector3(0, 0, -20)
	var names = OS.get_environment("SF").split(",") if OS.get_environment("SF") != "" else ["aoda", "battle_toad", "crow", "eagle", "froggy_knight", "gyuki", "kurama_jdavid", "kurama_kyubi", "monkey_king", "monkey_rigged", "naruto_frog", "pakkun", "sea_slug", "shepherd", "shukaku", "slug_arion", "snake_anim", "susanoo_skeleton", "toad_rogue", "susanoo_perfect"]
	for nm in names:
		var path = "res://assets/sketchfab/%s/%s.glb" % [nm, nm]
		if not ResourceLoader.exists(path):
			continue
		var t0 = Time.get_ticks_msec()
		var n: Node3D = (load(path) as PackedScene).instantiate()
		main.add_child(n)
		var p = base
		p.y = Game.terrain_height(p.x, p.z)
		n.global_position = p
		await get_tree().process_frame
		var ab = _aabb(n)
		var k = 6.0 / maxf(ab.size.y, 0.001)
		n.scale = Vector3.ONE * k
		await get_tree().process_frame
		ab = _aabb(n)
		n.global_position += Vector3(p.x - ab.get_center().x, p.y - ab.position.y, p.z - ab.get_center().z)
		var ap: AnimationPlayer = n.find_child("AnimationPlayer", true, false)
		if ap and ap.get_animation_list().size() > 0:
			ap.play(ap.get_animation_list()[0])
		print("SF ", nm, " size=", ab.size / k, " load_ms=", Time.get_ticks_msec() - t0)
		for side in [0, 1]:
			var dir = Vector3(0, 0, -1) if side == 0 else Vector3(0, 0, 1)
			pl.cam.global_position = p + Vector3(3.0, 4.0, 0) + dir * 9.0
			pl.cam.look_at(p + Vector3.UP * 3.0)
			await get_tree().create_timer(0.3).timeout
			await main.shot("sf_%s_%d" % [nm, side])
		n.queue_free()
		await get_tree().process_frame
	get_tree().quit()
