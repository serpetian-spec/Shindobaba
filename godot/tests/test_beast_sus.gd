extends Node
## Bijū + Susanoo: her canavar tam dönüşümde Susanoo'yu giyer. IDS=kurama,shukaku... CFG=zırh,yüz,silah,renk,kenar,kademe
var main: Node
var pl
func _process(_dt: float) -> void:
	if pl:
		pl.chakra = pl.max_chakra
		pl.hp = pl.max_hp
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "dağınık", "hair": Color(0.08, 0.08, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.1, 0.1, 0.1)}
	main._start_new_game()
	Hud.show_game_hud(false)
	pl = main.player
	var pr = Game.profile
	Gear.grant(pr, "goz_ems", "sag_goz", null, null, {"lvl": 3, "origin": "dogustan"})
	Gear.grant(pr, "goz_ems", "sol_goz", null, null, {"lvl": 3, "origin": "dogustan"})
	Gear.apply_look(pr)
	pl.rebuild_model()
	pl.max_chakra = 9999999
	Susanoo.config(pr)["mastery"] = 99999.0
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	var eyes = pl.combat.modes.eyes
	eyes.toggle()
	await get_tree().create_timer(0.4).timeout
	var cf = OS.get_environment("CFG").split(",") if OS.get_environment("CFG") != "" else PackedStringArray(["0", "0", "kilic", "0", "0", "5"])
	Susanoo.config(pr).merge({"color": Susanoo.COLORS[int(cf[3])], "rim_color": Susanoo.COLORS[int(cf[4])], "armor": int(cf[0]), "face": int(cf[1]), "weapon": cf[2], "wings": false, "tier_pref": int(cf[5])}, true)
	var ver = OS.get_environment("VER")
	var cc = Camera3D.new()
	main.add_child(cc)
	cc.fov = 50.0
	cc.far = 6000.0
	for id in OS.get_environment("IDS").split(","):
		TailedBeasts.make_jinchuriki(id)
		TailedBeasts.beasts()[id]["trust"] = 100.0
		var cl: BeastCloak = pl.combat.modes.cloak
		cl.set_level(6)
		await get_tree().create_timer(1.0).timeout
		eyes._start_susanoo()
		await get_tree().create_timer(1.2).timeout
		var h = cl.rig.height_m
		var bs = cl.rig.get_node_or_null("BeastSus")
		print("BSUS %s: giyildi=%s parca=%d sirt_kolu=%d kol=%d bacak=%d susanoo_gizli=%s" % [id, bs != null, (bs.made.size() if bs else 0), (bs.back_arms.size() if bs else 0), cl.rig.arms.size(), cl.rig.legs.size(), not eyes.susanoo_node.visible])
		var g = pl.global_position
		var f = pl.face_dir()
		var r = f.cross(Vector3.UP).normalized()
		var ctr = g + Vector3.UP * h * 0.5
		pl.set_process(false)
		pl.set_physics_process(false)
		for s in [["on", ctr + (f + r * 0.6).normalized() * h * 3.3 + Vector3.UP * h * 0.2], ["yan", ctr + r * h * 3.3], ["arka", ctr - (f - r * 0.5).normalized() * h * 3.3 + Vector3.UP * h * 0.5]]:
			cc.make_current()
			cc.global_position = s[1]
			cc.look_at(ctr)
			await get_tree().create_timer(0.25).timeout
			await main.shot("bs_%s_%s_%s" % [ver, id, s[0]])
		pl.set_process(true)
		pl.set_physics_process(true)
		eyes._end_susanoo()
		await get_tree().create_timer(0.6).timeout
		print("BSUS %s: susanoo kapaninca zirh kalkti=%s" % [id, cl.rig.get_node_or_null("BeastSus") == null])
		cl.set_level(0)
		await get_tree().create_timer(0.8).timeout
	get_tree().quit()
