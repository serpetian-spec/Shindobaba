extends Node
## Tek Susanoo kademesi: yan ve ön çekim (TIER ortam değişkeni)
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
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.5).timeout
	var eyes = pl.combat.modes.eyes
	eyes.toggle()
	var t = int(OS.get_environment("TIER"))
	var c = Susanoo.config(pr)
	c["tier_pref"] = t
	c["color"] = [0.55, 0.35, 1.0]
	c.erase("rim_color")
	if OS.get_environment("WEAPON") != "":
		c["weapon"] = OS.get_environment("WEAPON")
	eyes._start_susanoo()
	await get_tree().create_timer(0.9).timeout
	pl.set_process(false)
	var sn = eyes.susanoo_node
	var ab := AABB(); var first = true
	for mi in sn.find_children("*", "MeshInstance3D", true, false):
		if not mi.is_visible_in_tree(): continue
		var w = mi.global_transform * mi.get_aabb()
		ab = w if first else ab.merge(w)
		first = false
	var pab := AABB(); first = true
	for mi in pl.model.find_children("*", "MeshInstance3D", true, false):
		if not mi.is_visible_in_tree(): continue
		var w2 = mi.global_transform * mi.get_aabb()
		pab = w2 if first else pab.merge(w2)
		first = false
	print("SUSAABB t=%d sn_center=%s size=%s pl_model_center=%s pl=%s skel=%s" % [t, ab.get_center(), ab.size, pab.get_center(), pl.global_position, sn.body.skel.global_position])
	var h = Susanoo.TIER_HEIGHT[t]
	var fwd = pl.face_dir()
	var rt = fwd.cross(Vector3.UP)
	var p0 = pl.global_position
	var mid = p0 + Vector3.UP * h * (0.3 if t == 3 else 0.5)
	for s in [["on", fwd * h * 1.25 + rt * h * 0.35], ["yan", rt * h * 1.4 + fwd * h * 0.2]]:
		pl.cam.global_position = mid + s[1] + Vector3.UP * h * 0.1
		pl.cam.look_at(mid)
		await get_tree().create_timer(0.3).timeout
		await main.shot("sus_t%d_%s" % [t, s[0]])
	# düz vuruş: Susanoo kullanıcının önüne vurmalı, ileri kaymamalı
	pl.cam.global_position = mid + rt * h * 1.4 + Vector3.UP * h * 0.1
	pl.cam.look_at(mid)
	sn.rotation.y = pl.facing
	var hb0 = sn.body.skel.find_bone("Hips")
	var hip_before = (sn.body.skel.global_transform * sn.body.skel.get_bone_global_pose(hb0)).origin
	sn.swipe(pl, fwd)
	await get_tree().create_timer(0.3).timeout
	var hip_after = (sn.body.skel.global_transform * sn.body.skel.get_bone_global_pose(hb0)).origin
	print("HIPDRIFT %s" % (hip_after - hip_before))
	print("SWING body_off=%s" % sn.body.position)
	await main.shot("sus_t%d_vurus" % t)
	eyes._end_susanoo()
	await get_tree().create_timer(0.5).timeout
	# gardırop önizlemesi
	Menus._eq_slot = "susanoo"
	Menus.ninja_menu(main, "wardrobe")
	await get_tree().create_timer(0.8).timeout
	await main.shot("sus_t%d_onizleme" % t)
	get_tree().quit()
