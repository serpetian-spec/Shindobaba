extends Node
## Dövüş tarzları: her tarzın 6 kombo adımı, vuruş anında kare (yan ve ön açı); kemik kılıç, büyüme, el pozları
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	var styles = Array(OS.get_environment("STYLES").split(",", false)) if OS.get_environment("STYLES") != "" else ["juken", "akimichi", "inuzuka", "kaguya", "uchiha", "hozuki", "aburame", "jugo"]
	var clan_of = {"juken": "hyuga", "akimichi": "akimichi", "inuzuka": "inuzuka", "kaguya": "kaguya", "uchiha": "uchiha", "hozuki": "hozuki", "aburame": "aburame", "jugo": "jugo", "yuki": "yuki", "sabaku": "sabaku", "uzumaki": "uzumaki", "yotsuki": "yotsuki", "kamizuru": "kamizuru", "iburi": "iburi", "kurosuki": "kurosuki", "senju": "senju", "sarutobi": "sarutobi", "hatake": "hatake", "nara": "nara"}
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": clan_of.get(styles[0], "none"), "element": "katon", "hair_style": "diken",
		"hair": Color(0.25, 0.2, 0.15), "top": Color(0.85, 0.85, 0.8), "pants": Color(0.2, 0.2, 0.25), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	Game.set_meta("sandbox", true)
	var vs = Game.village("suna")
	var base = Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"]))
	pl.respawn(base)
	await _w(1.5)
	Hud.close_dialog()
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	var n = 0
	for st in styles:
		Game.profile["clan"] = clan_of.get(st, "none")
		if st.begins_with("jin_"):   # jinchūriki tarzı
			Game.profile["jinchuriki"] = st.substr(4)
		elif not clan_of.has(st):   # yol tarzı: o yolda ol
			if not Game.profile.has("paths"):
				Game.profile["paths"] = {}
			Game.profile["paths"][st] = {"s": 4}
		if st == "rinnegan":   # göz tarzı: Rinnegan tak
			Gear.grant(Game.profile, "goz_rinnegan", "sag_goz", null, null, {"lvl": 3, "origin": "uyanis"})
		if st == "jashin" and not "uc_tirpan" in Gear.owned_ids(Game.profile):
			Gear.grant(Game.profile, "uc_tirpan")
		Game.profile["fight_style"] = st
		Game.profile["equip"]["sag"] = 0   # tarz silahsız oynar (klan yadigârı silahı kaldır: Hatake tantōsu vb.)
		Gear.apply_look(Game.profile)
		pl.rebuild_model()
		await _w(0.6)
		print("STY %s key=%s avail=%s" % [st, FightingStyles.player_key(Game.profile), str(FightingStyles.available(Game.profile))])
		var b0 = base + Vector3(40.0 * n, 0, 0)
		n += 1
		b0.y = Game.ground_height(b0.x, b0.z)
		pl.global_position = b0
		pl.facing = 0.0
		var e := Enemy.new()
		e.setup(Enemy.archetype("rogue", 1))
		main.actors.add_child(e)
		e.global_position = b0 + Vector3(0, 0, -FightingStyles.stop_dist("style_" + st) - 0.6)
		e.max_hp = 1e9; e.hp = 1e9
		e.set_physics_process(false)
		await _w(0.5)
		if OS.get_environment("JUHO") != "":
			Jutsu.execute(pl, "juho_soshiken", e)
			await _w(1.2)
		for k in 6:
			pl.global_position = b0
			pl.facing = 0.0
			pl.combat.attack()
			var c = pl.combat._combo(pl.combat.step)
			var ht = float(c.get("hit", 0.2))
			await _w(maxf(0.02, ht - 0.02) + float(OS.get_environment("LATE")) if OS.get_environment("LATE") != "" else maxf(0.02, ht - 0.02))
			var co = Vector3(3.6, 1.6, -1.2)
			if OS.get_environment("CAM") != "":
				var q = OS.get_environment("CAM").split(",")
				co = Vector3(float(q[0]), float(q[1]), float(q[2]))
			cc.global_position = pl.global_position + co
			cc.look_at(pl.global_position + Vector3(0, 1.1, -FightingStyles.stop_dist("style_" + st) * 0.5 if OS.get_environment("CAM") != "" else -0.9))
			cc.current = true
			var skx: Skeleton3D = pl.model.skel
			var rh = skx.find_bone("RightHand")
			print("STY %s %d grow=%s fist=%s rh_scale=%s" % [st, k, str(pl.model.overlay.grow), str(pl.model.overlay.fist), str(skx.get_bone_pose_scale(rh)) if rh >= 0 else "yok"])
			await main.shot("sty_%s_%d" % [st, k])
			await _w(maxf(0.05, float(c.get("dur", 0.5)) - ht - 0.05))
		pl.cam.current = true
		e.queue_free()
		await _w(1.6)
	get_tree().quit()
