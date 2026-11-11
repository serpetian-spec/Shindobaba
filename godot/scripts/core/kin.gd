class_name Kin
extends RefCounted
## Kendi ailen: baban, annen ve bir kardeşin köyde yaşar (kalıcı Friends kaydı; "kin" alanı: baba / anne / kardeş).
## · Bekârken aynı evde yaşarsınız: annen evin sahibidir (karşılar, yemek yapar, sofra kurar), baban ve kardeşin akşam evdedir.
## · Baban: bildiğini öğretir (klan tekniği, yoksa avuçlarına taijutsu çalışması) — KinScene.lesson
## · Annen: yolda görürse bento verir, sarılır — KinScene.bento / hug
## · Kardeşin: kendi hızında güçlenir; kapışmaların skoru tutulur (idman maçı sistemi)

const LESSON_CD := 600.0
const BENTO_CD := 600.0


static func pr() -> Dictionary:
	return Game.profile


static func id_of(rel: String) -> String:
	var ids: Dictionary = pr().get("kin_ids", {})
	var id = String(ids.get(rel, ""))
	return id if id != "" and Friends.all().has(id) else ""


static func alive(rel: String) -> bool:
	var id = id_of(rel)
	return id != "" and String(Friends.all()[id].get("status", "")) != "ölü"


static func rel_of(id: String) -> String:
	return String(Friends.all().get(id, {}).get("kin", ""))


## Hitap: kardeş için ağabey / abla
static func call_name(id: String) -> String:
	var f: Dictionary = Friends.all().get(id, {})
	match String(f.get("kin", "")):
		"baba": return "Baba"
		"anne": return "Anne"
		"kardeş":
			if f.get("elder", false):
				return "Abla" if String(f.get("look", {}).get("gender", "m")) == "f" else "Ağabey"
			return String(f.get("name", "")).split(" ")[-1]
	return String(f.get("name", ""))


static func _col(v, def: Color) -> Color:
	return KidLife._col(v, def)


## Aile bir kez kurulur (eski kayıtlarda da): görünüşleri senden türetilir
static func ensure() -> void:
	if pr().is_empty() or pr().get("kin_made", false):
		return
	pr()["kin_made"] = true
	var me: Dictionary = pr().get("look", {})
	var d = CharacterModel.default_look()
	var clan = String(pr().get("clan", "none"))
	if clan == "none":
		clan = ""
	var vid = Progress.home()
	var sur = ClanWorld.clan_name(clan) if clan != "" else ""
	var hair = _col(me.get("hair"), d["hair"])
	var eye = _col(me.get("eye"), d["eye"])
	var skin = _col(me.get("skin"), d["skin"])
	var hair_dad = randf() < 0.5   # saçın babandan, gözün annenden (ya da tersi)
	var ids = {}
	var elder = randf() < 0.5
	var sib_f = randf() < 0.5
	var defs = [["baba", false, "jonin", 2, 85, "Baban"], ["anne", true, "chunin", 1, 90, "Annen"],
		["kardeş", sib_f, "genin", 0, 60, ("Ablan" if sib_f else "Ağabeyin") if elder else "Kardeşin"]]
	for df in defs:
		var fem: bool = df[1]
		var lk = ClanWorld.clan_look(clan, String(df[2]), vid, fem, "adult")
		lk["skin"] = skin.lerp(_col(lk.get("skin"), skin), 0.25)
		match String(df[0]):
			"baba":
				if hair_dad:
					lk["hair"] = hair
				else:
					lk["eye"] = eye
				lk["beard"] = randf() < 0.6
			"anne":
				if hair_dad:
					lk["eye"] = eye
				else:
					lk["hair"] = hair
			"kardeş":
				lk["hair"] = hair if randf() < 0.7 else hair.darkened(0.25)
				lk["eye"] = eye
		var given = String((ClanWorld.GIVEN_F if fem else ClanWorld.GIVEN_M).pick_random())
		var id = Friends._make_friend(("%s %s" % [sur, given]) if sur != "" else given, clan, lk, int(df[4]), String(df[5]))
		var f: Dictionary = Friends.all()[id]
		f["kin"] = String(df[0])
		f["rank"] = int(df[3])
		f["loyalty"] = 95
		if String(df[0]) == "kardeş":
			f["elder"] = elder
			f["pupil_lv"] = 12.0 if elder else 6.0
			f["taught"] = []
		f["family"] = [{"rel": "Çocuğu" if String(df[0]) != "kardeş" else "Kardeşi", "name": "%s (sen)" % pr().get("name", ""), "alive": true}]
		ids[String(df[0])] = id
	pr()["kin_ids"] = ids
	pr()["sib_score"] = [0, 0]


## Kardeşin kendi hızında gelişir (sana göre değil)
static func tick(dt: float) -> void:
	var id = id_of("kardeş")
	if id == "":
		return
	var f: Dictionary = Friends.all()[id]
	f["pupil_lv"] = float(f.get("pupil_lv", 6.0)) + dt / 700.0


static func on_spar(id: String, player_won: bool) -> void:
	if rel_of(id) != "kardeş":
		return
	var sc: Array = pr().get("sib_score", [0, 0])
	sc[0 if player_won else 1] = int(sc[0 if player_won else 1]) + 1
	pr()["sib_score"] = sc
	var f: Dictionary = Friends.all()[id]
	if player_won:
		f["pupil_lv"] = float(f.get("pupil_lv", 6.0)) + 0.6   # yenilen kardeş hırslanır, daha çok çalışır
		f["news"] = "Geçen sefer şanslıydın. Gece gündüz çalışıyorum, rövanşı alacağım!"
	else:
		f["news"] = "Skor %d–%d. Babam bile gördü nasıl yendiğimi, hehe." % [int(sc[1]), int(sc[0])]


## Aile üyesiyle konuşurken çıkan seçenekler
static func opts(id: String, v: Node) -> Array:
	var f: Dictionary = Friends.all().get(id, {})
	var rel = String(f.get("kin", ""))
	if rel == "" or String(f.get("status", "")) != "":
		return []
	var now = Time.get_unix_time_from_system()
	var o = []
	var inside = v != null and v.get("interior") == true
	match rel:
		"baba":
			if not inside and now - float(f.get("kin_lesson", 0.0)) >= LESSON_CD:
				o.append({"label": "Baba, bana bir şey öğret", "cb": func(): KinScene.start("lesson", id, v)})
		"anne":
			o.append_array(HomeLife.spouse_opts(id))   # evdeyse: sofra, sarılma, iyi geceler
			if not inside:
				if now - float(f.get("kin_bento", 0.0)) >= BENTO_CD:
					o.append({"label": "Anne, acıktım...", "cb": func(): KinScene.start("bento", id, v)})
				o.append({"label": "Sarıl", "cb": func(): KinScene.start("hug", id, v)})
		"kardeş":
			var sc: Array = pr().get("sib_score", [0, 0])
			if not inside:
				o.append({"label": "Kapışalım! (skor: sen %d – %d %s)" % [int(sc[0]), int(sc[1]), call_name(id)], "cb": func(): Friends.begin_activity(id, "train")})
	return o


## Aile menüsü satırları: [[başlık, id], ...]
static func rows() -> Array:
	var o = []
	for rel in ["baba", "anne", "kardeş"]:
		var id = id_of(rel)
		if id != "":
			o.append(["%s: %s" % [String(Friends.all()[id].get("title", rel)), Friends.all()[id]["name"]], id])
	return o
