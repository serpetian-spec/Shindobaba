extends Node
## Susanoo kademelerini referans açılarından çeker. VER: etiket, TIERS: "1,2,3,4,5", CFG: zırh,yüz,silah,renk (ör. "0,0,kilic,0")
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
	pl.chakra = 9999999
	pl.max_chakra = 9999999
	Susanoo.config(pr)["mastery"] = 99999.0
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.5).timeout
	Hud.close_dialog()
	if OS.get_environment("TOD") != "":
		main.world.env.time_of_day = float(OS.get_environment("TOD"))
	var eyes = pl.combat.modes.eyes
	eyes.toggle()
	await get_tree().create_timer(0.4).timeout
	var ver = OS.get_environment("VER")
	var tiers = OS.get_environment("TIERS").split(",") if OS.get_environment("TIERS") != "" else PackedStringArray(["1", "2", "3", "4", "5"])
	var cf = OS.get_environment("CFG").split(",") if OS.get_environment("CFG") != "" else PackedStringArray(["0", "0", "kilic", "0"])
	var cc = Camera3D.new()
	main.add_child(cc)
	cc.fov = 45.0
	cc.far = 4000.0
	cc.current = true
	for ts in tiers:
		var t = int(ts)
		Susanoo.config(pr).merge({"color": Susanoo.COLORS[int(cf[3])], "armor": int(cf[0]), "face": int(cf[1]), "weapon": cf[2], "wings": true}, true)
		Susanoo.config(pr)["tier_pref"] = t
		eyes._start_susanoo()
		await get_tree().create_timer(1.2).timeout
		var sn = eyes.susanoo_node
		if t == 1:
			for c in sn.body.skel.get_children():
				if c is MeshInstance3D and c.material_override == sn.mat:
					var sp = c.global_transform * Vector3(0, 1, -0.58)
					print("SPINE omurga-oyuncu . yuz_yonu = %.2f | model ileri . yuz_yonu = %.2f" % [(sp - pl.global_position).dot(pl.face_dir()), pl.model.global_transform.basis.z.normalized().dot(pl.face_dir())])
		var h = Susanoo.TIER_HEIGHT[t]
		var vis = h * (0.5 if t in [2, 3] else 1.0)   # yerden görünen boy
		var f = pl.face_dir()
		var r = f.cross(Vector3.UP).normalized()
		var g = pl.global_position
		var ctr = g + Vector3.UP * vis * 0.52
		var d = vis * 2.3 + 2.0
		var hd = sn.bone_at("Head")
		await get_tree().process_frame
		hd = sn.bone_at("Head")
		var shots = [["on", ctr + f * d, ctr], ["cap", ctr + (f + r * 0.75).normalized() * d + Vector3.UP * vis * 0.15, ctr],
			["yan", ctr + r * d, ctr], ["arka", ctr - (f - r * 0.5).normalized() * d + Vector3.UP * vis * 0.2, ctr],
			["yuz", hd + (f - r * 0.45).normalized() * h * 0.36 + Vector3.UP * h * 0.1, hd + Vector3.UP * h * 0.07],
			["alt", g + (f + r * 0.4).normalized() * vis * 1.1 + Vector3.UP * 1.6, ctr + Vector3.UP * vis * 0.25]]
		pl.set_process(false)
		pl.set_physics_process(false)
		for s in shots:
			cc.make_current()
			cc.global_position = s[1]
			cc.look_at(s[2])
			await get_tree().create_timer(0.25).timeout
			await main.shot("sus_%s_t%d_%s" % [ver, t, s[0]])
		pl.set_process(true)
		pl.set_physics_process(true)
		eyes._end_susanoo()
		await get_tree().create_timer(0.5).timeout
	get_tree().quit()
