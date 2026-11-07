extends Node
## Temari no Ōōgi: elde kapalı, sırtta, kombo adımlarında 1/2/3 ay açık; Kirikiri Mai yelpazeyle
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _shot(cc: Camera3D, pl: Node3D, name: String, off: Vector3, look_h := 1.1) -> void:
	# oyuncu kamerası: yaw/pitch/uzaklık (off yönünden bakar)
	pl.cam.current = true
	var h = Vector2(off.x, off.z)
	pl.yaw = rad_to_deg(atan2(off.x, off.z))
	pl.cam_dist = 4.0
	await _w(0.35)
	print("OGI _shot %s yaw=%.1f cam=%s camz=%s" % [name, pl.yaw, pl.cam.global_position - pl.global_position, pl.cam.global_transform.basis.z])
	await main.shot(name)


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "f", "clan": "none", "element": "fuuton", "hair_style": "ikiz_topuz", "hair": Color(0.9, 0.78, 0.4), "top": Color(0.9, 0.88, 0.85), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.4, 0.35)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	#Hud.show_game_hud(false)
	var pl = main.player
	pl.max_hp = 1e9
	pl.hp = 1e9
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(1.0)
	await main.shot("ogi_pre")
	Gear.grant(Game.profile, "temari_ogi")
	var has = (Game.profile["gear"] as Array).any(func(g): return g["id"] == "temari_ogi")
	print("OGI granted(test)=%s" % has)
	var uid = 0
	for g in Game.profile["gear"]:
		if g["id"] == "temari_ogi":
			uid = int(g["uid"])
	Game.profile["equip"]["sag"] = uid
	Gear.apply_look(Game.profile)
	pl.rebuild_model()
	await _w(1.5)
	Hud.close_dialog()
	await main.shot("ogi_post_rebuild")
	pl = main.player
	print("OGI pos=%s ground=%.1f model=%s" % [pl.global_position, Game.ground_height(pl.global_position.x, pl.global_position.z), pl.model])
	var fw: Vector3 = pl.face_dir()
	var rt = fw.cross(Vector3.UP)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.global_transform = pl.cam.global_transform
	cc.current = true
	await _w(0.1)
	await main.shot("ogi_cccopy")
	print("OGI cam far=%s near=%s env=%s" % [cc.far, cc.near, pl.cam.environment if pl.cam else null])
	pl.cam.current = true
	await _w(0.3)
	await main.shot("dbg1_plcam")
	Game.profile["weapon_drawn"] = false
	pl.model.set_drawn(false, false)
	await _w(0.3)
	await main.shot("dbg2_stowed")
	print("OGI dbg pl=%s cam=%s" % [pl.global_position, pl.cam.global_position])
	# sırtta (kında)
	Game.profile["weapon_drawn"] = false
	pl.model.set_drawn(false, false)
	await _w(0.5)
	await _shot(cc, pl, "ogi_back", -fw * 3.2 + rt * 1.2 + Vector3.UP * 1.6)
	Game.profile["weapon_drawn"] = true
	pl.model.set_drawn(true, false)
	await _w(0.6)
	await _shot(cc, pl, "ogi_hand", fw * 3.0 + rt * 1.5 + Vector3.UP * 1.4)
	# kombo adımları
	var KC = preload("res://scripts/combat/keyed_combos.gd")
	for st in [1, 2, 3]:
		KC._ogi_stage(pl, st, 3.0)
		await _w(0.1)
		await _shot(cc, pl, "ogi_open%d" % st, fw * 3.2 + rt * 1.6 + Vector3.UP * 1.4)
	# gerçek kombo: 6 vuruş
	var e = Enemy.new()
	var a = Enemy.archetype("rogue", 0)
	a["hp"] = 1e7
	a["respawn"] = false
	e.setup(a)
	get_tree().current_scene.add_child(e)
	e.global_position = pl.global_position + fw * 3.0
	e.home = e.global_position
	pl.combat.lock_target = e
	var shots_at = {1: 0.45, 2: 0.5, 5: 0.75}
	for i in 6:
		pl.combat.attack()
		await _w(shots_at.get(i, 0.3))
		if shots_at.has(i):
			pl.yaw = 90.0
			pl.pitch = -15.0
			pl.cam_dist = 5.0
			await main.shot("ogi_combo%d" % i)
		await _w(0.6)
	print("OGI enemy_hp_lost=%.0f" % (1e7 - e.hp))
	# Kirikiri Mai
	await _w(1.0)
	var blk = "held=%s" % str("temari_ogi" in Gear.held_ids(Game.profile))
	print("OGI kirikiri block=%s" % blk)
	Jutsu.execute(pl, "kuchiyose_kirikiri_mai", e)
	await _w(0.4)
	await _shot(cc, pl, "ogi_kirikiri", fw * 4.0 + rt * 3.0 + Vector3.UP * 2.0, 1.6)
	get_tree().quit()
