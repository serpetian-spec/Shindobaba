extends Node
## Oyuncu üzerinde gerçek akış: Ctrl şarjı (çömelme) -> süper zıplama (takla + süzülme) -> iniş; koşarken ani vuruş
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Kaito", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12),
		"top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8), "village": "konoha"}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	Menus.clear()
	main.world.env.time_of_day = 0.42
	var p: Player = main.player
	var base = Exams.find_point(["training"])
	base.y = Game.terrain_height(base.x, base.z)
	p.global_position = base
	p.velocity = Vector3.ZERO
	await get_tree().create_timer(1.0).timeout
	p.leap_charge = 0.0
	await get_tree().create_timer(0.35).timeout
	await main.shot("lp_1_sarj_yarim")
	await get_tree().create_timer(0.8).timeout
	await main.shot("lp_2_sarj_dolu")
	var ch = p.leap_charge
	p.leap_charge = -1.0
	p._leap(ch)
	var t = 0.0
	var i = 0
	var land_shot = false
	while t < 4.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		if int(t / 0.35) > i:
			i = int(t / 0.35)
			await main.shot("lp_3_hava_%02d" % i)
			print("hava t=%.2f vy=%.1f leap=%.2f land=%.2f grounded=%s" % [t, p.velocity.y, p.model.overlay.weights.get("leap", 0.0), p.model.overlay.glide_land, p.grounded])
		if p.grounded and t > 0.3:
			break
	await main.shot("lp_4_inis")
	# koşarken ani vuruş
	p.model.overlay.set_pose("ninja_run", 1.0)
	await get_tree().create_timer(0.3).timeout
	p.combat.attack()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	print("vurus ninja_run=%.2f current=%s" % [p.model.overlay.weights.get("ninja_run", 0.0), p.model.current])
	await main.shot("lp_5_vurus")
	get_tree().quit()
