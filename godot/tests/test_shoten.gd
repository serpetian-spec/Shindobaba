extends Node
## Shōten no Jutsu uçtan uca: geçersiz kurbanda reddeder; ağır yaralı kurban kopyaya döner (takım, görünüş, teknik, chakra);
## chakra bitince kurban geri gelir ve ölür. Kullanım: --test=res://tests/test_shoten.gd --shots=<dizin>
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "s6",
		"hair": Color(0.1, 0.1, 0.12), "top": Color(0.85, 0.35, 0.2), "pants": Color(0.15, 0.15, 0.2), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	var vs = Game.village("suna")
	var base = Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"]))
	pl.respawn(base)
	Game.profile["level"] = 60
	Game.set_meta("sandbox", true)
	await _w(1.5)
	Hud.close_dialog()
	pl.facing = 0.0
	pl.yaw = 0.0
	var e := Enemy.new()
	e.setup(Enemy.archetype("rogue", 1))
	main.actors.add_child(e)
	e.global_position = pl.global_position + Vector3(0, 0, -5.0)
	e.home = e.global_position
	e.lose_target(999)
	e.state = "idle"
	e.set_physics_process(false)
	await _w(0.5)
	Game.profile["learned"].append("shoten_no_jutsu")
	Game.profile["slots"] = ["katon_goukakyuu", "katon_housenka", "shoten_no_jutsu"]
	pl.max_chakra = 300.0
	pl.chakra = 300.0
	var pj = null
	for n in get_tree().root.find_children("*", "", true, false):
		if n.has_method("p_shoten_no_jutsu"):
			pj = n
			break
	print("SHOTEN pj=%s" % [pj != null])
	# 1) sağlam kurban: reddedilmeli
	pj.p_shoten_no_jutsu(pl, e)
	await _w(1.6)
	var copies = get_tree().get_nodes_in_group("fighters").filter(func(f): return is_instance_valid(f) and f.has_meta("shoten_copy"))
	print("SHOTEN sağlam kurban: kopya=%d (0 beklenir) chakra=%.0f (300 beklenir)" % [copies.size(), pl.chakra])
	# 2) ağır yaralı kurban
	e.hp = e.max_hp * 0.3
	print("SHOTEN dbg: mesafe=%.1f hp=%.2f ninja=%s takım=%s/%s boss=%s tg=%s canlı=%s" % [e.global_position.distance_to(pl.global_position), e.hp / e.max_hp, e._is_ninja(), e.team, pl.team, e is Boss, pj.tg(pl, e, 8.0), pj.live(e)])
	pj.p_shoten_no_jutsu(pl, e)
	await _w(1.6)
	copies = get_tree().get_nodes_in_group("fighters").filter(func(f): return is_instance_valid(f) and f.has_meta("shoten_copy"))
	print("SHOTEN yaralı kurban: kopya=%d chakra=%.0f (210 beklenir) kurban görünür=%s" % [copies.size(), pl.chakra, e.visible])
	if copies.is_empty():
		print("SHOTEN BASARISIZ")
		get_tree().quit()
		return
	var cp: Enemy = copies[0]
	print("SHOTEN kopya: takım=%s ad=%s chakra=%.0f/%.0f teknik=%s saç=%s (oyuncu saçı %s) can=%.0f güç=%.2f" % [cp.team, cp.display_name, cp.chakra, cp.max_chakra,
		cp.arch.get("jutsu", []), cp.look.get("hair_style", "?"), pl.model.look.get("hair_style", "?"), cp.max_hp, cp.power])
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.current = true
	cc.global_position = pl.global_position + Vector3(3.5, 2.0, 2.5)
	cc.look_at(pl.global_position + Vector3(0, 1.1, -2.5))
	await get_tree().process_frame
	await main.shot("shoten_1_kopya")
	# 3) düşman çıkar: kopya ona saldırmalı
	var e2 := Enemy.new()
	e2.setup(Enemy.archetype("rogue", 1))
	main.actors.add_child(e2)
	e2.global_position = pl.global_position + Vector3(4, 0, -12.0)
	e2.home = e2.global_position
	e2.max_hp = 1e6
	e2.hp = 1e6
	var h0 = e2.hp
	await _w(3.0)
	var ok_cp = is_instance_valid(cp) and not cp.is_queued_for_deletion()
	print("SHOTEN dövüş: düşmana hasar=%.0f kopya duruyor=%s chakra=%.0f" % [h0 - e2.hp, ok_cp, cp.chakra if ok_cp else 0.0])
	if ok_cp:
		cc.global_position = cp.global_position + Vector3(4.0, 2.2, 3.0)
		cc.look_at(cp.global_position + Vector3(0, 1.1, 0))
		await get_tree().process_frame
		await main.shot("shoten_2_dovus")
		cp.chakra = 0.0
	# 4) chakra biter: kurban geri gelir ve ölür
	await _w(1.2)
	print("SHOTEN bitiş: kopya geçerli=%s kurban görünür=%s kurban ölü=%s konum y=%.1f" % [is_instance_valid(cp) and not cp.is_queued_for_deletion() if true else false, e.visible, e.is_dead(), e.global_position.y - pl.global_position.y])
	cc.global_position = e.global_position + Vector3(3.0, 2.0, 3.0)
	cc.look_at(e.global_position + Vector3(0, 0.6, 0))
	await get_tree().process_frame
	await main.shot("shoten_3_bitis")
	print("SHOTEN BITTI")
	get_tree().quit()
