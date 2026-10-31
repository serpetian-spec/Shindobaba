extends Node
## Beceri deneme modu (ShinobiYolu_SKILLTEST.exe): menüsüz başlar; bütün jutsular öğrenilmiş, bütün doğalar,
## gözler, sözleşmeler, kuyruklu canavarlar ve yollar açık; can/chakra sınırsız, bekleme yok; çevrede hedef kuklalar.
## F5: düşman grubu çağır  •  F6: bekleme süreleri aç/kapa  •  F7: ölümsüzlük aç/kapa
var main: Node
var no_cd := true
var god := true


func _ready() -> void:
	Game.set_meta("sandbox", true)   # SkillTest: chakra maliyeti kontrolü atlanır (seviyeyle büyüyen maliyet azami chakrayı aşabiliyordu)
	await get_tree().process_frame
	main.creator_state = {"slot": 9, "name": "Deneme", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken",
		"hair": Color(0.15, 0.12, 0.1), "top": Color(0.2, 0.25, 0.35), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(1.5).timeout
	var pr = Game.profile
	pr["level"] = 80
	pr["rank"] = 5
	pr["ryo"] = 9999999
	pr["elements"] = ["katon", "suiton", "fuuton", "doton", "raiton"]
	# kekkei genkai doğaları: jutsularda geçen bütün doğalar
	var nat = []
	for jid in Data.jutsu:
		var j = Data.jutsu[jid]
		if j is Dictionary:
			for el in j.get("elements", []):
				if not el in pr["elements"] and not el in nat:
					nat.append(el)
	pr["natures"] = nat
	# bütün gerçek jutsular öğrenilmiş
	for jid in Data.jutsu:
		var j = Data.jutsu[jid]
		if not j is Dictionary or String(jid).begins_with("_") or j.has("virtual"):
			continue
		if not jid in pr["learned"]:
			pr["learned"].append(jid)
	for sk in ["sage", "gates", "contract", "jinchuriki"]:
		if not sk in pr["skills"]:
			pr["skills"].append(sk)
	# gözler: iki gözde Ebedi Mangekyō (tam Susanoo); diğer bütün gözler kavanozda (Tab > Gözler)
	Gear.grant(pr, "goz_ems", "sag_goz", null, null, {"lvl": 3, "origin": "dogustan"})
	Gear.grant(pr, "goz_ems", "sol_goz", null, null, {"lvl": 3, "origin": "dogustan"})
	for gid in ["goz_sharingan", "goz_byakugan", "goz_ketsuryugan", "goz_mangekyo", "goz_rinnegan", "goz_tenseigan", "goz_jogan"]:
		for i in 2:
			Gear.grant(pr, gid, "", null, null, {"lvl": 3, "origin": "dogustan"})
	# bütün ekipmanlar (kıyafet, silah, aksesuar, göz...) çantada — Tab > Ekipman'dan tek tek denenebilir
	var have = {}
	for g in pr["gear"]:
		have[String(g["id"])] = true
	for gid in Gear.ITEMS:
		if not have.has(gid):
			Gear.grant(pr, gid, "", null, null, {"lvl": 3, "origin": "dogustan"})
	# bütün kullanılabilir eşyalar (hap, merhem, parşömen, klan eşyaları...)
	for iid in Data.items:
		pr["inventory"][iid] = maxi(int(pr["inventory"].get(iid, 0)), 20)
	Susanoo.config(pr)["mastery"] = 9999.0
	# sözleşmeler ve sennin
	Contracts.ensure()
	for cid in Contracts.DEFS:
		Contracts.sign(cid)
		pr["contracts"][cid]["mastery"] = 999.0
		pr["contracts"][cid]["sage"] = true
	# kuyruklu canavarlar: hepsi içinde (Tab > Canavarlar: aktif olanı seç)
	for bid in BeastModels.INFO.keys():
		if bid == "raiju":
			continue
		TailedBeasts.make_jinchuriki(bid)
		TailedBeasts.beasts()[bid]["trust"] = 100.0
	# efsane yolları
	for pid in LegendPaths.PATHS:
		LegendPaths.set_state(pid, LegendPaths.JOINED)
	Progress.clan_unlocks(false)
	SpecialSlots.refresh(pr)
	Gear.apply_look(pr)
	if Game.player:
		Game.player.rebuild_model()
	await get_tree().create_timer(0.5).timeout
	_dummies()
	Hud.banner("BECERİ DENEME MODU", "Bütün jutsular ve eşyalar hazır (K: jutsular, Tab: ekipman/çanta). F5 düşman • F6 bekleme aç/kapa • F7 ölümsüzlük", Color(1, 0.8, 0.3))
	Game.save_game()


func _dummies() -> void:
	var c = Game.player.global_position
	for i in 8:
		var a = TAU * i / 8.0
		var q = Missions.open_ground(c + Vector3(cos(a), 0, sin(a)) * 12.0, 8.0)
		Spawner.dummy(q)


func _spawn_foes() -> void:
	var c = Game.player.global_position + Game.player.face_dir() * 18.0
	for i in 3:
		var e = Enemy.new()
		var a = Enemy.archetype(["rogue", "kumo", "kiri", "iwa", "suna"].pick_random(), i)
		a["respawn"] = false
		a["level"] = 40
		a["hp"] = 2000.0
		e.setup(a)
		get_tree().current_scene.add_child(e)
		var q = Missions.open_ground(c + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6)), 10.0)
		e.global_position = q
		e.home = q
	Hud.msg("3 düşman çağrıldı.", Color(1, 0.6, 0.5))


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_F5:
				_spawn_foes()
			KEY_F6:
				no_cd = not no_cd
				Hud.msg("Bekleme süreleri %s" % ("KAPALI" if no_cd else "AÇIK"), Color(1, 0.9, 0.5))
			KEY_F7:
				god = not god
				Hud.msg("Ölümsüzlük %s" % ("AÇIK" if god else "KAPALI"), Color(1, 0.9, 0.5))


func _process(_dt: float) -> void:
	var pl = Game.player
	if pl == null or Game.profile.is_empty():
		return
	pl.chakra = pl.max_chakra
	if god:
		pl.hp = pl.max_hp
	if no_cd and pl.combat:
		for k in pl.combat.cooldowns.keys():
			pl.combat.cooldowns[k] = 0.0
		pl.combat.jutsu_gcd = 0.0
		pl.combat.strain = 0
