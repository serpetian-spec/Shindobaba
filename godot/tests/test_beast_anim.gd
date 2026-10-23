extends Node
## Hayran modelli canavarların (Shukaku, Kurama) canlandırma + zemine oturma testi: yandan sabit kamerayla
## bekleme, yürüyüş, pençe, kükreme, kuyruk süpürmesi kareleri; ölçek için yanında oyuncu. Ayrıca tam dönüşüm.
## Kullanım: --test=res://tests/test_beast_anim.gd --shots=<dizin> [--tag=after]

var main: Node
var pl: Player
var tag := "after"


func _ready() -> void:
	await get_tree().process_frame
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12),
		"top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	Game.world.env.weather_t = 9999.0
	Game.world.env.region_weather = "açık"
	pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(4.0).timeout
	var base = pl.global_position
	for id in ["shukaku", "kurama"]:
		await _beast(id, base)
	await _giant(base)
	print("BEAST ANIM BITTI")
	get_tree().quit()


func _beast(id: String, base: Vector3) -> void:
	var b = TailedBeast.new()
	b.setup(id)
	get_tree().current_scene.add_child(b)
	var p = base + Vector3.FORWARD * b.height * 0.9
	p.y = Game.ground_height(p.x, p.z)
	b.global_position = p
	b.home = p
	b.set_physics_process(false)   # yapay zekâ kapalı: kareleri biz sürüyoruz
	b.facing = PI * 0.5
	b.rig.rotation.y = b.facing
	pl.global_position = p + Vector3(b.height * 0.15, 0, b.height * 0.55)
	pl.global_position.y = Game.ground_height(pl.global_position.x, pl.global_position.z)
	pl.reset_physics_interpolation()
	var cam = Camera3D.new()
	get_tree().current_scene.add_child(cam)
	cam.global_position = p + Vector3(0, b.height * 0.45, b.height * 1.9)
	cam.look_at(p + Vector3.UP * b.height * 0.4)
	cam.far = 4000.0
	cam.current = true
	await get_tree().create_timer(1.5).timeout
	await main.shot("ba_%s_%s_0bekle" % [tag, id])
	await get_tree().create_timer(0.7).timeout
	await main.shot("ba_%s_%s_0bekle_b" % [tag, id])
	# yürüyüş: canavar kameranın önünden geçer
	b.rig.move_speed = 1.0
	var dirv = Vector3(-1, 0, 0)
	for i in 50:
		b.global_position += dirv * 0.4 * b.height / 50.0 * 2.0
		b.global_position.y = Game.ground_height(b.global_position.x, b.global_position.z)
		await get_tree().create_timer(0.03).timeout
		if i == 20 or i == 35:
			await main.shot("ba_%s_%s_1yuru_%d" % [tag, id, i])
	b.rig.move_speed = 0.0
	await get_tree().create_timer(0.6).timeout
	for a in [["swipe_l", 1.2, 0.45], ["roar", 1.6, 0.45], ["tail", 2.0, 0.3], ["charge", 1.6, 0.5]]:
		b.rig.play_action(a[0], a[1])
		await get_tree().create_timer(a[1] * a[2]).timeout
		await main.shot("ba_%s_%s_2_%s" % [tag, id, a[0]])
		await get_tree().create_timer(a[1] * (1.0 - a[2]) + 0.3).timeout
	cam.queue_free()
	b.queue_free()
	await get_tree().create_timer(0.5).timeout


func _giant(base: Vector3) -> void:
	pl.global_position = base
	pl.reset_physics_interpolation()
	TailedBeasts.make_jinchuriki("kurama")
	TailedBeasts.beasts()["kurama"]["trust"] = 100.0
	var cl: BeastCloak = pl.combat.modes.cloak
	cl.set_level(6)
	await get_tree().create_timer(1.2).timeout
	var cam = Camera3D.new()
	get_tree().current_scene.add_child(cam)
	var h = cl.rig.height_m
	cam.global_position = base + Vector3(h * 1.6, h * 0.4, h * 0.6)
	cam.look_at(base + Vector3.UP * h * 0.35)
	cam.far = 4000.0
	cam.current = true
	await main.shot("ba_%s_tam_donusum" % tag)
	cl.rig.play_action("swipe_r", 1.0)
	await get_tree().create_timer(0.45).timeout
	await main.shot("ba_%s_tam_donusum_pence" % tag)
	cl.set_level(0)
	cam.queue_free()
