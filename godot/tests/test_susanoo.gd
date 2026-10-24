extends Node
## Susanoo kademeleri + özel Mangekyō gözleri
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "dağınık", "hair": Color(0.08, 0.08, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.1, 0.1, 0.1)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var pr = Game.profile
	Gear.grant(pr, "goz_ems", "sag_goz", null, null, {"lvl": 3, "origin": "dogustan"})
	Gear.grant(pr, "goz_ems", "sol_goz", null, null, {"lvl": 3, "origin": "dogustan"})
	Gear.apply_look(pr)
	pl.rebuild_model()
	pl.chakra = 99999
	pl.max_chakra = 99999
	Susanoo.config(pr)["mastery"] = 999.0
	var v = Game.village("suna")   # açık çöl: binalar görüntüyü kapatmasın
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.5).timeout
	var eyes = pl.combat.modes.eyes
	eyes.toggle()
	await get_tree().create_timer(0.4).timeout
	pl.set_process(false)
	var em: MeshInstance3D = pl.model.eyes_mesh
	var hp = em.global_transform * em.get_aabb().get_center()
	pl.cam.global_position = hp + pl.face_dir() * 0.55 + Vector3(0, 0.05, 0)
	pl.cam.look_at(hp)
	await get_tree().create_timer(0.3).timeout
	await main.shot("s0_ems_gozler")
	var cfgs = [{"color": Susanoo.COLORS[0], "armor": 0, "face": 0, "weapon": "kilic"}, {"color": Susanoo.COLORS[1], "armor": 1, "face": 1, "weapon": "yay"},
		{"color": Susanoo.COLORS[2], "armor": 2, "face": 2, "weapon": "kalkan"}, {"color": Susanoo.COLORS[3], "armor": 0, "face": 1, "weapon": "mizrak"}, {"color": Susanoo.COLORS[0], "armor": 2, "face": 0, "weapon": "kilic"}]
	for t in range(1, 6):
		Susanoo.config(pr).merge(cfgs[t - 1], true)
		Susanoo.config(pr)["tier_pref"] = t
		eyes._start_susanoo()
		await get_tree().create_timer(0.8).timeout
		var h = Susanoo.TIER_HEIGHT[t]
		var cd = (h * 1.3 + 3.0) if t > 1 else 3.2
		pl.cam.global_position = pl.global_position + pl.face_dir() * cd + Vector3(h * 0.4 if t > 1 else 1.4, h * 0.55, 0)
		pl.cam.look_at(pl.global_position + Vector3.UP * h * 0.5)
		await get_tree().create_timer(0.3).timeout
		await main.shot("s%d_susanoo" % t)
		if t >= 3:   # Susanoo içindeki kullanıcı yakın
			var mp = pl.model.global_position + Vector3.UP * 1.2
			pl.cam.global_position = mp + pl.face_dir() * 6.0 + Vector3(2.0, 1.0, 0)
			pl.cam.look_at(mp)
			await get_tree().create_timer(0.2).timeout
			await main.shot("s%d_icinde" % t)
		eyes._end_susanoo()
		await get_tree().create_timer(0.5).timeout
	get_tree().quit()
