extends Node
## Gece ormanında siyah lekeli/haleli bozuk piksel avı: birkaç açıdan kare alır.
## Kullanım: --test=res://tests/test_night_forest.gd

var main: Node
var pl: Player


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12),
		"top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	pl = main.player
	Game.world.env.time_of_day = 0.02
	Game.world.env.weather_t = 9999.0
	Game.world.env.region_weather = "açık"
	var v = Game.village("konoha")
	var n := 0
	for off in [Vector2(0, float(v["r"]) + 250), Vector2(float(v["r"]) + 300, 0), Vector2(-float(v["r"]) - 350, 100)]:
		pl.respawn(Game.from_map(Vector2(v["x"] + off.x, v["y"] + off.y)))
		await get_tree().create_timer(5.0).timeout
		print("konum ", pl.global_position, " saat ", Game.world.env.time_of_day)
		var cam = Camera3D.new()
		get_tree().current_scene.add_child(cam)
		cam.current = true
		cam.fov = 70.0
		for k in 4:
			var a = k * PI * 0.5 + 0.3
			cam.global_position = pl.global_position + Vector3(cos(a) * 7.0, 4.0, sin(a) * 7.0)
			cam.look_at(pl.global_position + Vector3.UP * 1.0)
			for fr in 3:
				await get_tree().create_timer(0.7).timeout
				get_viewport().get_texture().get_image().save_png((ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir() + "/_tmp/kv/nf_%d_%d_%d.png") % [n, k, fr])
		cam.queue_free()
		n += 1
	print("NF BITTI")
	get_tree().quit()
