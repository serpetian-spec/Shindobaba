extends Node
## Yaşlılıktan ölüm: uyarı -> son nefes -> mezun çocuğa geçiş (yaş, ad, eski kaydın ölümü)
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test Baba", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.1, 0.1, 0.12), "skin": Color(0.95, 0.8, 0.68), "eye": Color(0.2, 0.4, 0.8)}
	main._start_new_game()
	await _w(3.0)
	Hud.close_dialog()
	var pl: Player = main.player
	var p: Dictionary = Game.profile
	p["rank"] = 3
	pl.global_position = Missions.open_ground(pl.global_position + Vector3(0, 0, 30), 30.0) + Vector3.UP * 0.2
	var life = Aging.lifespan()
	print("OA omur=%.1f varis_yokken=%s" % [life, Legacy.heir()])
	# 1) çocuk yokken ömür dolar: ölmez
	Aging.set_years(p, life + 0.5)
	pl.rebuild_model()
	await _w(6.0)
	print("OA cocuksuz: ad=%s yas=%d sahne=%s" % [p["name"], int(Aging.player_years()), str(is_instance_valid(Legacy.cur))])
	# 2) mezun çocuk var, ömrün son yılları: uyarı
	var kid = Friends._make_friend("Test Kenta", "", {"gender": "m", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12)}, 80, "Oğlun")
	var kf: Dictionary = Friends.all()[kid]
	kf["child"] = true
	kf["rank"] = 1
	kf["element"] = "katon"
	p["flags"].erase("old_warned")
	Aging.set_years(p, life - 1.0)
	await _w(6.0)
	print("OA uyari=%s varis=%s cocuk_yas=%d" % [str(p["flags"].get("old_warned", false)), Legacy.heir(), int(Aging.person_years(kf))])
	# 3) ömür doldu
	Hud.close_dialog()
	Aging.set_years(p, life + 0.2)
	var t0 = 0.0
	while not is_instance_valid(Legacy.cur) and t0 < 12.0:
		await _w(0.5); t0 += 0.5
	print("OA sahne basladi=%s (%.1f sn)" % [str(is_instance_valid(Legacy.cur)), t0])
	await _w(5.0)
	await main.shot("oa_son_nefes")
	t0 = 0.0
	while is_instance_valid(Legacy.cur) and t0 < 40.0:
		await _w(0.5); t0 += 0.5
	await main.shot("oa_yeni_nesil")
	var dead = ""
	for fid in Friends.all():
		var f: Dictionary = Friends.all()[fid]
		if String(f.get("name", "")) == "Test Baba":
			dead = "%s / %s / yas %d" % [String(f.get("title", "")), String(f.get("status", "")), int(Aging.person_years(f))]
	print("OA sonra: ad=%s yas=%d rutbe=%d kilit=%.1f eski=%s cocuk_kaydi=%s atalar=%s" % [p["name"], int(Aging.player_years()), int(p["rank"]), float(pl.input_locked), dead, str(Friends.all().has(kid)), str(p.get("ancestors", []))])
	get_tree().quit()
