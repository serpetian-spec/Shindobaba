extends Node
## Göz evrim zincirleri: Byakugan ustalığı -> Tenseigan, EMS -> Rinnegan, Rinnegan -> Rinne-Sharingan, Uzumaki Jōgan; göz teknikleri öğrenimi
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "hyuga", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var ey: Eyes = pl.combat.modes.eyes
	var pr = Game.profile
	pr["level"] = 45
	print("EVO start kinds=", ey._kind("sag"), ey._kind("sol"))
	# Byakugan ustalığı + Tenseigan
	for s in ["sag_goz", "sol_goz"]:
		Gear.equipped(pr, s)["lvl"] = 3
	ey.toggle()
	Game.world.env.time_of_day = 0.05
	for i in 70:
		ey.evolve_tick(1.0)
	print("EVO tenseigan kinds=", ey._kind("sag"), ey._kind("sol"))
	Progress.clan_unlocks(false)
	print("EVO tenseigan jutsu=", ["tenseigan_chakura_modo", "kinrin_tensei_baku"].filter(func(j): return j in pr["learned"]))
	# EMS -> Rinnegan (Sv.60, can düşük, düşman yakında)
	pr["level"] = 60
	Gear.grant(pr, "goz_ems", "sag_goz"); Gear.grant(pr, "goz_ems", "sol_goz")
	Gear.apply_look(pr)
	var e = Enemy.new()
	main.add_child(e)
	e.global_position = pl.global_position + Vector3(0, 0, -4)
	await get_tree().create_timer(0.3).timeout
	pl.hp = pl.max_hp * 0.1
	ey._evo_cd = 0.0
	ey.evolve_tick(0.1)
	print("EVO rinnegan kinds=", ey._kind("sag"), ey._kind("sol"))
	# Rinne-Sharingan
	if not "rikudo_sennin_modo" in pr["learned"]:
		pr["learned"].append("rikudo_sennin_modo")
	ey._evo_cd = 0.0
	ey.evolve_tick(0.1)
	print("EVO rinne_sharingan=", pr["flags"].get("rinne_sharingan", false), " has_eye=", Progress.has_eye("rinne_sharingan"))
	Progress.clan_unlocks(false)
	print("EVO rinne jutsu=", ["mugen_tsukuyomi", "amenominaka", "daikokuten"].filter(func(j): return j in pr["learned"]))
	print("EVO ms jutsu (needs mangekyo)=", ["tsukuyomi", "kamui", "kotoamatsukami"].filter(func(j): return j in pr["learned"]))
	# kamera: alındaki üçüncü göz
	if not ey.active:
		ey.toggle()
	ey.refresh_visual()
	Hud.show_game_hud(false)
	pl.set_process(false)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.fov = 25
	Game.world.env.time_of_day = 0.5
	var eye_n: Node3D = ey._third.get_child(0) if is_instance_valid(ey._third) else null
	print("EVO third_eye_node=", eye_n != null)
	var hp = eye_n.global_position if eye_n else pl.global_position + Vector3.UP * 1.62
	var headc = ey._third.global_position if eye_n else hp
	var fwd = (hp - headc)
	fwd.y = 0
	fwd = fwd.normalized() if fwd.length() > 0.001 else Vector3.FORWARD
	cam.global_position = hp + fwd * 0.45 - Vector3.UP * 0.02
	cam.look_at(hp)
	cam.current = true
	await get_tree().create_timer(4.0).timeout
	await main.shot("third_eye")
	get_tree().quit()
