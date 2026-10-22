extends Node
## Canlı şehir + iç mekân testi: pazar (öğlen), antrenman, inşaat, akşam sokak, gece fenerleri, her iç mekân.
var main: Node


func _at(x: float, n: float) -> Vector3:
	var v = Game.village("konoha")
	var p = Game.from_map(Vector2(float(v["x"]) + x, float(v["y"]) + n))
	p.y = Game.terrain_height(p.x, p.z)
	return p


func _go(x: float, n: float, yaw: float, pitch := -12.0, dist := 7.0) -> void:
	var pl = main.player
	pl.global_position = _at(x, n)
	pl.velocity = Vector3.ZERO
	pl.reset_physics_interpolation()
	pl.yaw = yaw
	pl.pitch = pitch
	pl.cam_dist = dist


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var env = Game.world.env
	env.time_of_day = 0.5
	await get_tree().create_timer(1.0).timeout
	# pazar öğlen
	_go(-20, -6, 90.0, -14.0, 9.0)
	await get_tree().create_timer(9.0).timeout
	await main.shot("c1_pazar_oglen")
	print("npc pazar=", get_tree().get_nodes_in_group("talkers").size())
	var vl = main.actors.get_node("VillageLife")
	for key in vl.active_sites:
		var info = vl.active_sites[key]
		for n in info["nodes"]:
			if is_instance_valid(n):
				print(key, " ", info["site"]["type"], " ", n.get("role"), " pos=", n.global_position, " pl=", main.player.global_position)
	_go(-20, -2, 0.0, -10.0, 5.0)
	await get_tree().create_timer(1.0).timeout
	await main.shot("c1b_tezgah")
	_go(-14, 10, 90.0, -8.0, 4.0)
	await get_tree().create_timer(1.0).timeout
	await main.shot("c1c_satici")
	print("sites=", vl.sites.get("konoha", []).size(), " active=", vl.active_sites.size(), " q=", vl.queue.size(), " phase=", vl.phase)
	# antrenman alanı
	_go(1050, 545, 0.0, -10.0, 9.0)
	await get_tree().create_timer(6.0).timeout
	await main.shot("c2_antrenman")
	# inşaat
	_go(520, -640, 0.0, -10.0, 9.0)
	await get_tree().create_timer(5.0).timeout
	await main.shot("c3_insaat")
	# akademi avlusu (top oynayan çocuklar, güvercinler)
	_go(-510, 520, 0.0, -14.0, 9.0)
	await get_tree().create_timer(6.0).timeout
	await main.shot("c4_avlu")
	# ramen tezgâhı
	_go(70, -22, 180.0, -10.0, 6.0)
	await get_tree().create_timer(5.0).timeout
	await main.shot("c5_ramen")
	# akşam sokak
	env.time_of_day = 0.72
	_go(0, -700, 0.0, -8.0, 8.0)
	await get_tree().create_timer(7.0).timeout
	await main.shot("c6_aksam_cadde")
	# gece fenerler
	env.time_of_day = 0.93
	_go(0, -400, 0.0, -6.0, 8.0)
	await get_tree().create_timer(6.0).timeout
	await main.shot("c7_gece_cadde")
	_go(-30, -4, 90.0, -8.0, 8.0)
	await get_tree().create_timer(3.0).timeout
	await main.shot("c8_gece_pazar")
	env.time_of_day = 0.5
	# genel görünümler: güney kapısı, kule meydanı, Hokage Kayası
	_go(0, -1400, 0.0, -6.0, 9.0)
	await get_tree().create_timer(3.0).timeout
	await main.shot("k1_guney_kapi")
	_go(0, 520, 0.0, -4.0, 9.0)
	await get_tree().create_timer(3.0).timeout
	await main.shot("k2_kule")
	_go(0, 760, 0.0, 12.0, 10.0)
	await get_tree().create_timer(3.0).timeout
	await main.shot("k3_hokage_kayasi")
	main.player.global_position.y += 240.0
	_go(0, -900, 0.0, -25.0, 12.0)
	main.player.global_position.y += 260.0
	main.player.reset_physics_interpolation()
	await get_tree().create_timer(0.3).timeout
	await main.shot("k4_kus_bakisi")
	# iç mekânlar
	for r in ["academy", "hokage", "weapon_shop", "pharmacy", "tailor", "bbq", "hospital", "home_player", "home", "teahouse", "inn"]:
		var pl = main.player
		Interiors.inst.enter({"room": r, "pos": pl.global_position, "seed": 3, "kind": "enter", "label": "", "radius": 2})
		await get_tree().create_timer(3.0).timeout
		pl.pitch = -18.0
		pl.cam_dist = 4.0
		pl.yaw = 0.0
		await get_tree().create_timer(0.6).timeout
		await main.shot("i_" + r)
		Interiors.inst.exit()
		await get_tree().create_timer(1.2).timeout
	print("TEST BITTI")
	get_tree().quit()
