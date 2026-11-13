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
	var cc = Camera3D.new()
	main.add_child(cc)
	cc.fov = 45.0
	cc.far = 4000.0
	cc.current = true
	# LIST: "kademe,zırh,yüz,silah,renk,kenar,açılar(on+yuz+arka)" ; ile ayrılır
	for item in OS.get_environment("LIST").split(";"):
		var q = item.split(",")
		var t = int(q[0])
		Susanoo.config(pr).merge({"color": Susanoo.COLORS[int(q[4])], "rim_color": Susanoo.COLORS[int(q[5])], "armor": int(q[1]), "face": int(q[2]), "weapon": q[3], "wings": false}, true)
		Susanoo.config(pr)["tier_pref"] = t
		eyes._start_susanoo()
		await get_tree().create_timer(0.9).timeout
		var sn = eyes.susanoo_node
		var h = Susanoo.TIER_HEIGHT[t]
		var vis = h * (0.5 if t in [2, 3] else 1.0)
		var f = pl.face_dir()
		var r = f.cross(Vector3.UP).normalized()
		var g = pl.global_position
		var ctr = g + Vector3.UP * vis * 0.55
		var d = vis * 1.75 + 2.0
		await get_tree().process_frame
		var hd = sn.bone_at("Head")
		var views = {"on": [ctr + (f + r * 0.25).normalized() * d, ctr], "arka": [ctr - (f - r * 0.4).normalized() * d + Vector3.UP * vis * 0.15, ctr],
			"yuz": [hd + (f - r * 0.4).normalized() * h * 0.3 + Vector3.UP * h * 0.08, hd + Vector3.UP * h * 0.06],
			"ayak": [g + (f + r * 0.5).normalized() * vis * 1.6 + Vector3.UP * vis * 0.3, g + Vector3.UP * vis * 0.2]}
		pl.set_process(false)
		pl.set_physics_process(false)
		for vn in q[6].split("+"):
			cc.make_current()
			cc.global_position = views[vn][0]
			cc.look_at(views[vn][1])
			await get_tree().create_timer(0.2).timeout
			await main.shot("g_%s_t%d_a%s_f%s_%s_%s" % [ver, t, q[1], q[2], q[3], vn])
		pl.set_process(true)
		pl.set_physics_process(true)
		eyes._end_susanoo()
		await get_tree().create_timer(0.35).timeout
	get_tree().quit()
