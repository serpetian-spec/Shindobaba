extends Node
## Ekipman vitrini: Gear eşyalarıyla giydirilmiş karakter dizileri (ön/arka/yakın) + silah savuruş anları.
var main: Node

const SETS := [
	# [cinsiyet, yaş, saç, saç rengi, [eşyalar], rütbe]
	[["m", "adult", "kase", Color(0.08, 0.08, 0.1), ["uzun_gomlek", "ninja_pant", "sandalet", "chunin_yelek", "alin_koruyucu", "katana"], 3],
	 ["f", "young", "uzun", Color(0.9, 0.55, 0.7), ["kimono_ust", "hakama", "tabi", "kasa", "wakizashi"], 3],
	 ["m", "adult", "diken", Color(0.9, 0.9, 0.92), ["file_atlet", "sargili_pant", "zori", "uzun_palto", "bez_maske", "alin_koruyucu", "chokuto"], 4],
	 ["m", "young", "dağınık", Color(0.08, 0.08, 0.1), ["kolsuz_yakali", "ninja_pant", "sandalet", "kisa_pelerin", "kolluk", "tanto"], 3],
	 ["f", "teen", "atkuyruğu", Color(0.95, 0.85, 0.4), ["tisort", "sort", "sandalet", "atki", "gozluk", "kunai"], 2],
	 ["m", "adult", "kısa", Color(0.35, 0.22, 0.12), ["zirhli_gomlek", "ninja_pant", "takviyeli_sandalet", "samuray_zirh", "kafa_bandaji", "nodachi"], 4]],
	[["m", "adult", "diken", Color(0.3, 0.2, 0.12), ["uzun_gomlek", "ninja_pant", "sandalet", "suna_yelek", "alin_koruyucu", "sirt_shuriken", "bo"], 3],
	 ["f", "adult", "kısa", Color(0.2, 0.3, 0.6), ["uzun_gomlek", "ninja_pant", "sandalet", "kiri_yelek", "bandana", "kiba"], 4],
	 ["m", "adult", "kase", Color(0.95, 0.8, 0.25), ["kolsuz_yakali", "ninja_pant", "sandalet", "kumo_yelek", "alin_boyun", "eldiven", "samehada"], 4],
	 ["m", "adult", "dağınık", Color(0.6, 0.6, 0.62), ["uzun_gomlek", "ninja_pant", "sandalet", "iwa_yelek", "alin_koruyucu", "savas_cekici"], 3],
	 ["f", "young", "uzun", Color(0.08, 0.08, 0.1), ["uzun_gomlek", "ninja_pant", "tabi", "anbu_zirh", "anbu_kurt", "tam_koruma", "kilic_kini", "ikiz_hancer"], 4],
	 ["m", "adult", "kısa", Color(0.75, 0.25, 0.15), ["yakali", "hakama", "sandalet", "haori", "gaz_maskesi", "aletli_kemer", "kusarigama"], 4]],
	[["m", "adult", "diken", Color(0.25, 0.45, 0.25), ["tisort", "ninja_pant", "sandalet", "seyahat_pelerini", "kapuson", "dev_parsomen", "mizrak"], 3],
	 ["f", "young", "atkuyruğu", Color(0.75, 0.25, 0.15), ["sargili_kolsuz", "sort", "sandalet", "anbu_kus", "pence"], 4],
	 ["m", "young", "kase", Color(0.08, 0.08, 0.1), ["ceket", "ninja_pant", "sandalet", "anbu_ayi", "sirt_cantasi", "kubikiribocho"], 4],
	 ["m", "adult", "dağınık", Color(0.3, 0.2, 0.12), ["uzun_gomlek", "ninja_pant", "sandalet", "deri_yelek", "kol_sargisi", "bacak_koruma", "gunbai"], 4],
	 ["f", "teen", "diken", Color(0.9, 0.55, 0.7), ["yakali", "sargili_pant", "sandalet", "anbu_maske", "fuma_shuriken"], 4],
	 ["m", "adult", "kısa", Color(0.2, 0.2, 0.22), ["uzun_gomlek", "ninja_pant", "sandalet", "chunin_yelek", "alin_koruyucu", "raijin", "ruzgar_bicak"], 4]],
]


func _look_for(c: Array) -> Dictionary:
	var pr = {"rank": c[5], "gear": [], "equip": {}, "look": {"gender": c[0], "age": c[1], "hair_style": c[2], "hair": c[3], "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8), "village": "konoha"}}
	var hands = 0
	for id in c[4]:
		var it = Gear.item(id)
		var slot: String = it["slot"]
		if slot == "el":
			slot = "sag" if hands == 0 else "sol"
			hands += 1
		elif slot == "sag":
			hands += 1
		Gear.grant(pr, id, slot)
		if id == "kiba":
			Gear.grant(pr, id, "sol")
	Gear.apply_look(pr)
	return pr["look"]


func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	main.world.env.time_of_day = 0.42
	var v = Game.village("konoha")
	var base = Game.from_map(Vector2(v["x"] + 20, v["y"] - 120))
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	main.world.env.attach_post(cam)
	var only = OS.get_environment("GEAR_SET")
	for si in SETS.size():
		if only != "" and str(si) != only:
			continue
		var models = []
		var t0 = Time.get_ticks_msec()
		for i in SETS[si].size():
			var m = CharacterModel.new()
			main.add_child(m)
			m.setup(_look_for(SETS[si][i]))
			var p = base + Vector3((i - 2.5) * 1.25, 0, 0)
			p.y = Game.terrain_height(p.x, p.z)
			m.global_position = p
			m.rotation.y = 0.0
			m.play("idle")
			models.append(m)
		print("SET ", si, " kurulum ms=", Time.get_ticks_msec() - t0)
		cam.global_position = base + Vector3(0, 1.25, -5.2)
		cam.look_at(base + Vector3(0, 0.95, 0))
		await get_tree().create_timer(2.0).timeout
		await main.shot("g%d_on" % si)
		for m in models:
			m.rotation.y = PI
		await get_tree().create_timer(0.4).timeout
		await main.shot("g%d_arka" % si)
		for m in models:
			m.rotation.y = 0.0
		for half in 2:
			var cx = (-1.5 + half * 3.0) * 1.25
			cam.global_position = base + Vector3(cx, 1.3, -3.0)
			cam.look_at(base + Vector3(cx, 1.0, 0))
			await get_tree().create_timer(0.35).timeout
			await main.shot("g%d_yakin%d" % [si, half])
		cam.global_position = base + Vector3(0, 1.4, -5.6)
		cam.look_at(base + Vector3(0, 1.0, 0))
		for i in models.size():
			var m: CharacterModel = models[i]
			m.rotation.y = 0.6
			var wid = m.look.get("weapon_r") if m.look.get("weapon_r") != null else m.look.get("weapon_l")
			var st = Gear.item(String(wid)).get("weapon", {}).get("style", "fist") if wid != null else "fist"
			var anims: Array = PlayerCombat.STYLE_COMBOS.get(st, {"anims": ["a/Punch_Jab"]})["anims"]
			var an: String = anims[i % 3] if anims[i % 3] != "" else anims[0]
			m.play(an, 0.05, 1.0, true)
		await get_tree().create_timer(0.3).timeout
		await main.shot("g%d_savurus" % si)
		for m in models:
			m.queue_free()
		await get_tree().process_frame
	get_tree().quit()
