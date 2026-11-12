class_name KidLife
extends RefCounted
## Çocuk büyütme (veri tarafı). Sahneler HomeLife'ta oynanır.
## Evreler: bebek (beşikte) → çocuk (evde, ders verilir) → akademi öğrencisi (gündüz okulda, dersler daha verimli) → mezun (genin, dost kaydı).
## Kalıtım (doğumda bir kez): saç / ten / göz iki ebeveynden, klan iki klandan biri (baskın ebeveyn), doğa iki ebeveynin doğalarından biri.
## Eğitim: verdiğin dersler (shuriken / taijutsu / chakra) birikir; mezun olduğunda Gücünü belirler, göz kalıtımı klanına göre açılır.

const BABY := 1500.0      # ilk 25 dk: bebek
const ACADEMY := 3600.0   # 60. dk: akademiye başlar (mezuniyet Friends.CHILD_GROW)
const LESSON_CD := 300.0
const PLAY_CD := 120.0
const LESSONS := {"shuriken": "Shuriken", "taijutsu": "Taijutsu", "chakra": "Chakra kontrolü"}


static func pr() -> Dictionary:
	return Game.profile


static func age_of(kid: Dictionary) -> float:
	return Time.get_unix_time_from_system() - float(kid.get("born", 0.0))


static func stage(kid: Dictionary) -> String:
	if kid.get("grad", false):
		return "mezun"
	var a = age_of(kid)
	return "bebek" if a < BABY else ("çocuk" if a < ACADEMY else "akademi")


## Akademi öğrencisi gündüz okuldadır (evde yok)
static func at_school(kid: Dictionary) -> bool:
	return stage(kid) == "akademi" and not HomeLife.night()


static func _col(v, def: Color) -> Color:
	if v is Color:
		return v
	if v is Array and v.size() >= 3:
		return Color(float(v[0]), float(v[1]), float(v[2]))
	if v is String and String(v).begins_with("("):
		return str_to_var("Color" + v)
	return def


## Doğumda kalıtım (eski kayıtlardaki çocuklar için ilk bakışta tamamlanır)
static func ensure(kid: Dictionary) -> void:
	if kid.has("look"):
		return
	var sp: Dictionary = Friends.all().get(Friends.spouse_id(), {})
	var me: Dictionary = pr().get("look", {})
	var ot: Dictionary = sp.get("look", {})
	var fem = String(kid.get("gender", "m")) == "f"
	var my_clan = String(pr().get("clan", "none"))
	var sp_clan = String(sp.get("clan", ""))
	# baskın ebeveyn: klanı ve yüz hatlarının çoğu ondan
	var dom_me = randf() < 0.5
	if my_clan in ["", "none"] and sp_clan != "":
		dom_me = randf() < 0.3
	elif sp_clan == "" and not my_clan in ["", "none"]:
		dom_me = randf() < 0.7
	var cl: Array = []
	for c in ([my_clan, sp_clan] if dom_me else [sp_clan, my_clan]):
		if c != "" and c != "none" and not c in cl:
			cl.append(c)
	kid["clans"] = cl
	var a: Dictionary = me if dom_me else ot
	var b: Dictionary = ot if dom_me else me
	var d = CharacterModel.default_look()
	var pick = func(key: String, w: float) -> Color:
		var ca = _col(a.get(key), d[key])
		var cb = _col(b.get(key), d[key])
		var r = randf()
		return ca if r < w else (cb if r < w + (1.0 - w) * 0.7 else ca.lerp(cb, 0.5))
	var lk = {"gender": "f" if fem else "m"}
	var fsrc: Dictionary = a if randf() < 0.6 else b   # yüz hatları anne ya da babadan
	if fsrc.get("face_v") is Array:
		lk["face_v"] = fsrc["face_v"]
	else:
		lk["face_cut"] = CharacterModel.face_cut_of(fsrc)
	lk["hair"] = pick.call("hair", 0.6)
	lk["eye"] = pick.call("eye", 0.6)
	lk["skin"] = _col(me.get("skin"), d["skin"]).lerp(_col(ot.get("skin"), d["skin"]), randf())
	# saç modeli: kendi cinsiyetindeki ebeveynden (yoksa klanın / köyün çocuk saçı)
	var same: Dictionary = me if String(me.get("gender", "m")) == lk["gender"] else ot
	if String(same.get("gender", "m")) == lk["gender"] and same.has("hair_style") and randf() < 0.6:
		lk["hair_style"] = String(same["hair_style"])
	else:
		lk["hair_style"] = String(ClanWorld.clan_look(String(cl[0]) if not cl.is_empty() else "", "genin", Progress.home(), fem, "child").get("hair_style", "diken"))
	kid["look"] = Friends._ser(lk)
	var els: Array = []
	for e in pr().get("elements", []):
		els.append(String(e))
	if sp.has("element"):
		els.append(String(sp["element"]))
	kid["element"] = String(els.pick_random()) if not els.is_empty() else "katon"
	kid["from"] = "sana" if dom_me else ("annesine" if String(ot.get("gender", "m")) == "f" else "babasına")
	if not kid.has("tr"):
		kid["tr"] = {}


## Evdeki / köydeki görünüşü (age: "child" | "teen")
static func look(kid: Dictionary, age: String) -> Dictionary:
	ensure(kid)
	var cl: Array = kid.get("clans", [])
	var fem = String(kid.get("gender", "m")) == "f"
	var lk: Dictionary
	if age == "child":
		lk = CharacterModel.default_look()
		lk.merge(Outfits.roll("kid", Progress.home()), true)
		if not cl.is_empty() and CharacterModel.CLAN_FACE_PAINT.has(String(cl[0])):
			lk["face_paint"] = CharacterModel.CLAN_FACE_PAINT[String(cl[0])]
	else:
		lk = ClanWorld.clan_look(String(cl[0]) if not cl.is_empty() else "", "genin", Progress.home(), fem, age)
	lk.merge(Friends._look_raw(kid), true)
	lk["age"] = age
	lk["keep_hair"] = true
	return lk


static func skill(kid: Dictionary, key: String) -> float:
	return float(kid.get("tr", {}).get(key, 0.0))


## Ders işlendi: akademi çağında daha çok şey kapar
static func train(kid: Dictionary, key: String, good: bool) -> float:
	if not kid.has("tr"):
		kid["tr"] = {}
	var amt = (1.5 if stage(kid) == "akademi" else 1.0) * (1.0 if good else 0.6)
	kid["tr"][key] = skill(kid, key) + amt
	if not kid.has("last"):
		kid["last"] = {}
	kid["last"]["lesson"] = Time.get_unix_time_from_system()
	return amt


static func cd_left(kid: Dictionary, what: String) -> float:
	var cd = float({"lesson": LESSON_CD, "bento": 600.0, "watch": 300.0}.get(what, PLAY_CD))
	return maxf(0.0, cd - (Time.get_unix_time_from_system() - float(kid.get("last", {}).get(what, 0.0))))


static func mark(kid: Dictionary, what: String) -> void:
	if not kid.has("last"):
		kid["last"] = {}
	kid["last"][what] = Time.get_unix_time_from_system()


## Mezun olduğunda Gücü: hiç ders almamış çocuk sıradan bir genin (6); her ders üstüne koyar
static func power(kid: Dictionary) -> float:
	return 6.0 + (skill(kid, "shuriken") + skill(kid, "taijutsu") + skill(kid, "chakra")) * 0.9 + skill(kid, "bond") * 0.2


static func stage_text(kid: Dictionary) -> String:
	ensure(kid)
	var s = stage(kid)
	var t = {"bebek": "bebek (beşikte)", "çocuk": "evde, ders verebilirsin", "akademi": "akademi öğrencisi (gündüz okulda)" if not HomeLife.night() else "akademi öğrencisi (evde)"}.get(s, "")
	var parts = []
	for k in LESSONS:
		if skill(kid, k) > 0.0:
			parts.append("%s %d" % [LESSONS[k], int(skill(kid, k))])
	var el = String(Elements.NAMES.get(String(kid.get("element", "")), ""))
	return "%s%s%s  •  %s benziyor" % [t, ("  •  doğası " + el) if el != "" and s != "bebek" else "", ("  •  " + ", ".join(parts)) if not parts.is_empty() else "", String(kid.get("from", "sana"))]


## Mezuniyet: dost kaydına kalıtım ve eğitim işlenir
static func graduate_into(kid: Dictionary, f: Dictionary) -> void:
	ensure(kid)
	f["element"] = String(kid.get("element", f.get("element", "katon")))
	f["pupil_lv"] = power(kid)
	f["taught"] = []
	f["child"] = true
	var cl: Array = kid.get("clans", [])
	var kind = int(ClanWorld.EYE_KIND.get(String(cl[0]), 0)) if not cl.is_empty() else 0
	if kind == 2 or kind == 3:
		f["eye"] = [kind, 1]
	elif kind == 1 and skill(kid, "chakra") >= 3.0:
		f["eye"] = [1, 1]   # chakra çalışması iyi olan Uchiha çocuğu tek tomoe ile mezun olur


static func note_text() -> String:
	var o = ""
	for kid in pr().get("children", []):
		if at_school(kid):
			o += "\n\n%s akademide; akşam eve döner." % String(kid["name"]).split(" ")[-1]
	return o


## Çocuğun sana seslenişi: anne / baba; miras sonrası evdeki küçükler için abla / ağabey
static func parent_word(kid: Dictionary) -> String:
	var fem = String(pr().get("gender", "m")) == "f"
	if kid.get("sib", false):
		return "Abla" if fem else "Ağabey"
	return "Anne" if fem else "Baba"
