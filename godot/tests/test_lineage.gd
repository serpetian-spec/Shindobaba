extends Node
## Soy: çocuk evlenir, torun doğar + mezun olur, yaş kapısı, mirasçı seçimi, geçişte aile sana geçer
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _kid(nm: String, fem: bool, yrs: float) -> String:
	var id = Friends._make_friend(nm, "", {"gender": "f" if fem else "m", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12)}, 80, "Senin %s" % ("kızın" if fem else "oğlun"))
	var f: Dictionary = Friends.all()[id]
	f["child"] = true
	f["rank"] = 2
	f["element"] = "katon"
	Aging.set_years(f, yrs)
	return id

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
	Aging.set_years(p, 60.0)
	var fs = Friends.all()
	var a = _kid("Test Kenta", false, 30.0)
	var b = _kid("Test Aiko", true, 27.0)
	var c = _kid("Test Mini", false, 13.0)
	# yaş kapısı: 13 yaşındaki evlenmez
	for i in 40:
		Lineage.step()
	print("LN adim sonrasi: Kenta es=%s cocuk=%d | Aiko es=%s cocuk=%d | Mini(13) es=%s" % [str(Lineage.spouse_entry(fs[a]).get("name", "-")), Lineage.kid_entries(fs[a]).size(), str(Lineage.spouse_entry(fs[b]).get("name", "-")), Lineage.kid_entries(fs[b]).size(), str(Lineage.spouse_entry(fs[c]).get("name", "-"))])
	var spa = Lineage.spouse_entry(fs[a])
	var wq = WorldPeople.get_p(String(spa.get("wid", "")))
	print("LN Kenta esi: dunya ninjasi=%s koy=%s yas=%d kayit=%s" % [str(not wq.is_empty()), str(wq.get("village", "?")), int(Aging.person_years(wq)) if not wq.is_empty() else -1, str(wq.get("spouse", ""))])
	WorldKin.life(wq) if not wq.is_empty() else null
	print("LN dunya turu sonrasi es kaydi=%s" % str(wq.get("spouse", "")))
	# torunlar mezun olur: Kenta'nın ilk çocuğu ve Aiko'nun ilk çocuğu akademi çağında
	var now = Time.get_unix_time_from_system()
	var ka = Lineage.kid_entries(fs[a])
	var kb = Lineage.kid_entries(fs[b])
	if not ka.is_empty():
		ka[0]["born"] = now - 6000.0
	if not kb.is_empty():
		kb[0]["born"] = now - 6000.0
	var names = Lineage.graduate_all(now, 5400.0)
	print("LN mezun torunlar: %s" % str(names))
	for id in fs:
		if int(fs[id].get("gen", 0)) >= 2:
			print("LN   torun kaydi: %s | %s | yas %d | ebeveyn=%s | selam: %s" % [fs[id]["name"], fs[id]["title"], int(Aging.person_years(fs[id])), str(fs[id].get("parent_fid", "")), Talk._fill(Talk.hello(fs[id]))])
	# ömür dolar: 3 çocuk -> seçim penceresi
	Aging.set_years(p, Aging.lifespan() + 0.2)
	var t0 = 0.0
	while not Hud.dialog_open() and t0 < 12.0:
		await _w(0.5); t0 += 0.5
	print("LN secim penceresi=%s sahne=%s secenek=%d" % [str(Hud.dialog_open()), str(is_instance_valid(Legacy.cur)), Lineage.heirs().size()])
	await main.shot("ln_secim")
	Hud.close_dialog()
	Legacy._die_with(a)   # Kenta'yı seç
	t0 = 0.0
	while is_instance_valid(Legacy.cur) and t0 < 40.0:
		await _w(0.5); t0 += 0.5
	var sid = Friends.spouse_id()
	print("LN sonra: ad=%s yas=%d es=%s (%s) evdeki_cocuk=%d" % [p["name"], int(Aging.player_years()), str(fs.get(sid, {}).get("name", "-")), str(fs.get(sid, {}).get("romance", "-")), (p.get("children", []) as Array).size()])
	for id in fs:
		var f: Dictionary = fs[id]
		if String(f.get("title", "")) != "" and (f.get("child", false) or int(f.get("gen", 0)) > 0 or String(f.get("title", "")) in ["Yeğenin", "Kardeşin", "Eşin"] or String(f.get("status", "")) == "öldü"):
			print("LN   %s | %s | %s | yas %d" % [f["name"], f["title"], String(f.get("status", "")), int(Aging.person_years(f))])
	get_tree().quit()
