extends Node
## Sınavlar + Kage sistemi + örgütler: her aşamanın ekran görüntüsü ve durum çıktısı.
var main: Node


func _shot(n: String) -> void:
	await get_tree().create_timer(0.6, true, false, true).timeout
	await main.shot(n)


func _wait(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout


func _start(vid := "konoha") -> void:
	main.creator_state = {"slot": 3, "name": "Kaito", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12),
		"top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8), "village": vid}
	main._start_new_game()
	await _wait(2.0)


func _ready() -> void:
	await get_tree().process_frame
	await _start()
	var pr = Game.profile
	Hud.close_dialog()
	# ---- AKADEMİ: yazılı
	Progress.set_story(3)
	pr["level"] = 5
	Exams.academy_written()
	await _shot("k01_akademi_yazili")
	# cevapla: ilk şık doğruysa
	for i in 8:
		var b = _first_ink_button()
		if b:
			b.pressed.emit()
		await _wait(0.1)
	await _wait(0.4)
	print("ACADEMY written=", Exams.data.get("written"))
	Hud.close_dialog()
	Exams.academy_practical()
	Exams.on_technique("bunshin_no_jutsu")
	Exams.on_technique("henge")
	await _wait(5.0)
	Exams.on_technique("kawarimi")
	await _wait(0.5)
	print("ACADEMY practical=", Exams.data.get("practical"), " cur=", Exams.cur)
	await _shot("k02_akademi_hedefler")
	for d in Exams.nodes.duplicate():
		if is_instance_valid(d) and d.has_meta("exam_target"):
			Exams.on_dummy_broken(d)
	await _wait(0.5)
	await _shot("k03_akademi_sonuc")
	_press_primary()
	await _wait(0.4)
	print("academy_passed=", Exams.flags().get("academy_passed", false))
	# ---- ZİL TESTİ
	Game.player.respawn(Exams.find_point(["training"]) + Vector3(0, 0.5, 6))
	await _wait(1.0)
	Exams.bell_start()
	await _wait(1.0)
	Hud.close_dialog()
	await _wait(1.5)
	await _shot("k04_zil_testi")
	var s = Exams.data.get("sensei")
	for i in 18:
		Exams.on_hit(s)
	Exams.data["t"] = 0.1
	await _wait(0.6)
	await _shot("k05_zil_ikilem")
	Exams._bell_result(true, "share")
	await _wait(0.4)
	print("RANK after bell=", pr["rank"], " story=", Progress.story())
	Hud.close_dialog()
	# ---- CHŪNİN: yazılı
	pr["level"] = 16
	Progress.set_story(9)
	ChuninExam.host = "konoha"
	ChuninExam._register()
	if ChuninExam.stage == 9:
		Game.player.respawn(ChuninExam.stadium_pos() + Vector3(0, 0.5, 60))
		await _wait(1.0)
	await _wait(0.5)
	Hud.close_dialog()
	ChuninExam._written()
	await _wait(0.4)
	var d = Hud.dialog_layer.find_children("*", "Button", true, false)
	for b in d:
		if (b as Button).text.contains("Kâğıdı"):
			b.pressed.emit()
	await _wait(0.5)
	await _shot("k06_chunin_yazili")
	for i in 9:
		var b = _first_ink_button()
		if b:
			b.pressed.emit()
		await _wait(0.1)
	await _shot("k07_chunin_10soru")
	var b10 = _first_ink_button()
	if b10:
		b10.pressed.emit()
	await _wait(0.5)
	await _shot("k08_chunin_yazili_sonuc")
	Hud.close_dialog()
	ChuninExam._forest()
	await _wait(2.5)
	await _shot("k09_olum_ormani")
	# parşömenleri ver, kuleye ışınla
	pr["inventory"]["scroll_heaven"] = 1
	pr["inventory"]["scroll_earth"] = 1
	Game.player.respawn(ChuninExam.st["tower"] + Vector3(0, 0.5, 5))
	await _wait(1.5)
	print("CHUNIN stage after tower=", ChuninExam.stage)
	for bb in Hud.dialog_layer.find_children("*", "Button", true, false):
		if (bb as Button).text.contains("Eşleşmeleri"):
			bb.pressed.emit()
	await _wait(0.6)
	await _shot("k10_on_eleme_tablo")
	_press_primary()
	await _wait(2.0)
	await _shot("k11_on_eleme_duello")
	for i in 2:
		var e = ChuninExam.st.get("duel")
		if e and is_instance_valid(e):
			e.hp = 0
			e.die({})
		await _wait(3.5)
	print("CHUNIN stage after prelims=", ChuninExam.stage)
	Hud.close_dialog()
	Game.player.respawn(ChuninExam.stadium_pos() + Vector3(0, 0.5, 20))
	await _wait(2.0)
	print("CHUNIN stage at stadium=", ChuninExam.stage)
	await _shot("k12_final_tablo")
	_press_primary()
	await _wait(2.0)
	await _shot("k13_final_stadyum")
	var fe = ChuninExam.st.get("duel")
	if fe and is_instance_valid(fe):
		fe.hp = 0
		fe.die({})
	await _wait(1.0)
	await _shot("k14_istila_uyari")
	for bb in Hud.dialog_layer.find_children("*", "Button", true, false):
		if (bb as Button).text.contains("Savaş"):
			bb.pressed.emit()
	await _wait(2.5)
	await _shot("k15_istila")
	for e in Orgs._invasion.get("enemies", []):
		if is_instance_valid(e):
			if e is Summon:
				e.take_hit({"dmg": 999999.0, "knock": 0.0, "kind": "heavy", "dir": Vector3.FORWARD})
			else:
				e.hp = 0
				e.die({})
	await _wait(1.5)
	for bb in Hud.dialog_layer.find_children("*", "Button", true, false):
		if (bb as Button).text.contains("Kararı"):
			bb.pressed.emit()
	await _wait(0.8)
	await _shot("k16_juri_karari")
	_press_primary()
	await _wait(0.5)
	print("RANK after chunin=", pr["rank"])
	# ---- Kage: doğrudan yemin
	pr["rank"] = 4
	pr["level"] = 40
	Hud.close_dialog()
	Kage.inaugurate()
	await _wait(1.5)
	Hud.close_dialog()
	await _wait(0.5)
	var k = Kage.st()
	k["funds"] = 200000
	Kage.buy_upgrade("savunma")
	Kage.buy_upgrade("pazar")
	Kage.buy_upgrade("hastane")
	k["events"].append({"id": 7, "type": "mektup", "village": "suna", "title": "Sunagakure'den diplomatik mektup", "text": "Ortak sınır devriyesi öneriyorlar."})
	k["day"] = 4
	KageDesk.picked_squad = 0
	KageDesk.open("gorev")
	await _shot("k17_kage_masasi_gorev")
	KageDesk.open("koy")
	await _shot("k18_kage_masasi_koy")
	KageDesk.open("diplomasi")
	await _shot("k19_kage_masasi_diplomasi")
	KageDesk.open("olay")
	await _shot("k20_kage_masasi_olay")
	ExamUI._resume()
	Kage.assign(0, int(k["requests"][0]["id"]))
	k["squads"][0]["busy"] = 0.1
	await _wait(1.0)
	print("KAGE log=", k["log"].slice(0, 4))
	# kule önü görünür değişiklik
	var tw = Exams.find_point(["mission_board"])
	Game.player.respawn(tw + Vector3(0, 0.5, 60))
	Game.player.yaw = 180.0
	await _wait(2.0)
	await _shot("k21_kage_koy_degisim")
	# ---- Zirve
	Kage.start_summit()
	await _wait(1.0)
	var tz = Game.village("tetsu")
	if not tz.is_empty():
		Game.player.respawn(Game.from_map(Vector2(tz["x"], tz["y"])) + Vector3(0, 1, 0))
	await _wait(3.0)
	await _shot("k22_zirve")
	print("SUMMIT active=", Missions.active().get("title", ""), " step=", Missions.active().get("step", -1))
	# ---- kaçak ninja
	Missions.abandon()
	Orgs.defect()
	await _wait(1.0)
	var own = Orgs.own_bingo_entry()
	print("ROGUE bingo bounty=", own.get("bounty"), " band=", Game.profile["look"].get("band_style"))
	await _shot("k23_kacak")
	get_tree().quit()


func _first_ink_button() -> Button:
	for b in Hud.dialog_layer.find_children("*", "Button", true, false):
		if (b as Button).text.begins_with("A)") or (b as Button).text.begins_with("Soruyu alıyorum"):
			return b
	return null


func _press_primary() -> void:
	for b in Hud.dialog_layer.find_children("*", "Button", true, false):
		var t = (b as Button).text
		if t in ["Devam", "Tamam", "Arenaya çık"]:
			b.pressed.emit()
			return
