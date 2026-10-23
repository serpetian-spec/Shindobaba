extends Node
## Sonun Vadisi: hayran modeli heykeller + kendi taş büstlerimiz; oyuncu ölçek için kadrajda
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.4
	Game.world.env.weather_t = 9999.0
	Game.world.env.region_weather = "açık"
	var ve = Game.village("valley_end")
	var P = func(lx: float, ly: float, ln: float) -> Vector3:
		var w = Game.from_map(Vector2(ve["x"] + lx, ve["y"] + ln))
		return Vector3(w.x, ly, w.z)
	var pl = main.player
	# 1) nehir kıyısı: oyuncu suda, iki heykel ve şelale karşıda
	pl.respawn(P.call(0, 2, 360))
	await get_tree().create_timer(6.0).timeout
	var cam = Camera3D.new()
	cam.far = 6000.0
	get_tree().current_scene.add_child(cam)
	var shots = [
		[P.call(0, 8, 330), P.call(0, 70, 480), "v1_nehir"],
		[P.call(-60, 150, 300), P.call(0, 150, 480), "v2_yukari"],
		[P.call(-113, 140, 420), P.call(-113, 200, 480), "v3_sol_yakin"],
		[P.call(113, 140, 420), P.call(113, 200, 480), "v4_sag_yakin"],
		[P.call(-30, 215, 430), P.call(-113, 205, 480), "v5_bust_sol"],
		[P.call(30, 215, 430), P.call(113, 205, 480), "v6_bust_sag"],
		[P.call(0, 420, 470), P.call(0, 130, 480), "v7_tepe"],
		[P.call(0, 200, 650), P.call(0, 180, 480), "v8_yukari_akis"],
	]
	for s in shots:
		cam.global_position = s[0]
		cam.look_at(s[1])
		cam.current = true
		pl.global_position = s[0] + (s[1] - s[0]).normalized() * 12.0
		pl.reset_physics_interpolation()
		await get_tree().create_timer(1.5).timeout
		await main.shot(s[2])
	# 2) ölçek: oyuncu sol heykelin ayağının dibinde
	pl.respawn(P.call(-150, 140, 455))
	await get_tree().create_timer(3.0).timeout
	cam.global_position = pl.global_position + Vector3(-14, 6, 26)
	cam.look_at(pl.global_position + Vector3(10, 30, -20))
	cam.current = true
	await get_tree().create_timer(1.0).timeout
	await main.shot("v9_olcek")
	# 3) oyuncu heykelin omzunda durabiliyor mu
	pl.respawn(P.call(-113, 230, 480))
	await get_tree().create_timer(3.0).timeout
	print("OMUZ y=", pl.global_position.y, " zemin? ", pl.is_on_floor())
	get_tree().quit()
