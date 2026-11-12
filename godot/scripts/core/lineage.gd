class_name Lineage
extends RefCounted
## Soy: çocukların ve torunların kendi hayatı (hepsi Friends kaydı + dünyanın gerçek ninjaları üstünde, kalıp yok).
## · Mezun çocuğun büyür; yetişkin olunca köyün gerçek bir ninjasıyla evlenir, çocukları olur (torunların).
## · Torun akademi çağına gelince mezun olur ve gerçek bir tanıdık kaydı olur ("Torunun"); o da büyür, evlenir, çocuğu olur.
## · Yol mirasçıya geçince (tören ya da yaşlılıktan ölüm) onun ailesi SENİN ailen olur: eşi eşin, küçükleri evdeki çocukların,
##   mezun torunların çocukların; öteki çocuklarının soyu yeğenlerin.

const WED_AGE := 19.0
const KID_MAX_AGE := 46.0


static func fs() -> Dictionary:
	return Friends.all()


## 0: soydan değil, 1: çocuğun, 2: torunun, 3+: torununun çocuğu...
static func gen_of(f: Dictionary) -> int:
	return 1 if f.get("child", false) else int(f.get("gen", 0))


static func fem(f: Dictionary) -> bool:
	return String((f.get("look", {}) as Dictionary).get("gender", "m")) == "f"


static func title(g: int, female: bool) -> String:
	if g <= 1:
		return "Senin %s" % ("kızın" if female else "oğlun")
	if g == 2:
		return "Torunun"
	return "Torununun %s" % ("kızı" if female else "oğlu")


static func spouse_entry(f: Dictionary) -> Dictionary:
	for m in f.get("family", []):
		if String(m["rel"]) in ["Karısı", "Kocası"] and m.get("alive", true):
			return m
	return {}


static func kid_entries(f: Dictionary) -> Array:
	return (f.get("family", []) as Array).filter(func(m): return String(m["rel"]) in ["Oğlu", "Kızı"] and m.get("alive", true))


static func _word(f: Dictionary) -> String:
	var g = gen_of(f)
	var w = "kızın" if fem(f) else "oğlun"
	return w if g <= 1 else "torunun" if g == 2 else "torununun %s" % ("kızı" if fem(f) else "oğlu")


## Soyun bir adımı (Friends'in yaşam olayı döngüsü çağırır): uygun olan biri evlenir ya da çocuğu olur
static func step() -> void:
	var c = fs().keys().filter(func(k): return gen_of(fs()[k]) >= 1 and String(fs()[k].get("status", "")) == "")
	c.shuffle()
	for id in c:
		var f: Dictionary = fs()[id]
		var y = Aging.person_years(f)
		if y < WED_AGE:
			continue
		var sp = spouse_entry(f)
		if sp.is_empty():
			if Friends.romance_of(id) == "" and randf() < 0.5:
				marry(id)
				return
		elif y < KID_MAX_AGE and kid_entries(f).size() < 3 and randf() < 0.4:
			birth(id)
			return


## Eş: aynı köyün bekâr, hayatta, karşı cins gerçek bir dünya ninjası (yaşı yakın olan öne); o artık başkasıyla evlenmez
static func marry(id: String) -> bool:
	var f: Dictionary = fs()[id]
	if not f.has("family"):
		f["family"] = []
	var vid = String(f.get("village", Progress.home()))
	var y = Aging.person_years(f)
	var c = WorldPeople.all().values().filter(func(q): return WorldKin._ok(q) and String(q["village"]) == vid and bool(q["female"]) != fem(f) and String(q.get("spouse", "")) == "" and int(q.get("rank", 0)) >= 1 and Aging.person_years(q) >= WED_AGE - 1.0 and absf(Aging.person_years(q) - y) < 9.0)
	var e = {"rel": "Kocası" if fem(f) else "Karısı", "alive": true}
	if not c.is_empty():
		var q: Dictionary = c.pick_random()
		q["spouse"] = "fam:" + id
		e["name"] = String(q["name"])
		e["clan"] = String(q.get("clan", ""))
		e["wid"] = String(q["id"])
		WorldPeople.log_event(q, "%s ile evlendi" % String(f["name"]))
	else:
		var sc = ""
		e["name"] = "%s %s" % [String(Missions.BB_FAMILY.pick_random()), (ClanWorld.GIVEN_M if fem(f) else ClanWorld.GIVEN_F).pick_random()]
		e["clan"] = sc
	(f["family"] as Array).append(e)
	Friends.log_event(f, "%s ile evlendi" % String(e["name"]))
	f["news"] = "%s ile evlendim. Yuvamızı kurduk; bir akşam yemeğe gel, tanış." % String(e["name"])
	Hud.banner("AİLEDE DÜĞÜN", "%s %s, %s ile evlendi." % [_word(f).capitalize(), String(f["name"]).split(" ")[-1], String(e["name"])], Color(1, 0.85, 0.6))
	Journal.add("%s %s, %s ile evlendi." % [_word(f).capitalize(), String(f["name"]), String(e["name"])], "milestone")
	return true


static func _spouse_look(e: Dictionary, vid: String, female: bool) -> Dictionary:
	var q = WorldPeople.get_p(String(e.get("wid", "")))
	var lk: Dictionary
	if not q.is_empty():
		lk = WorldPeople.look_of(q)
		for k in ["keep_hair", "years", "fat", "mus", "old", "lines", "hair0", "skin0", "aged", "age"]:
			lk.erase(k)
	else:
		lk = ClanWorld.clan_look(String(e.get("clan", "")), "chunin", vid, female, "adult")
	lk["gender"] = "f" if female else "m"
	return Friends._ser(lk)


static func birth(id: String) -> void:
	var f: Dictionary = fs()[id]
	var sp = spouse_entry(f)
	if sp.is_empty():
		return
	var kf = randf() < 0.5
	var vid = String(f.get("village", Progress.home()))
	var my_clan = String(f.get("clan", ""))
	var sp_clan = String(sp.get("clan", ""))
	var clan = my_clan if my_clan != "" and (sp_clan == "" or randf() < 0.55) else sp_clan
	var sur = String(f["name"]).split(" ")[0] if " " in String(f["name"]) else String(Missions.BB_FAMILY.pick_random())
	var nm = ClanWorld.person_name(clan, kf) if clan != "" else "%s %s" % [sur, (ClanWorld.GIVEN_F if kf else ClanWorld.GIVEN_M).pick_random()]
	# görünüş iki ebeveynden: saç / göz / ten
	var a: Dictionary = f.get("look", {})
	var b: Dictionary = _spouse_look(sp, vid, not fem(f))
	var lk = {}
	for key in ["hair", "eye", "skin"]:
		var src: Dictionary = a if randf() < 0.55 else b
		if src.has(key):
			lk[key] = src[key]
		elif a.has(key):
			lk[key] = a[key]
	lk["face_cut"] = CharacterModel.face_cut_of(a if randf() < 0.5 else b)   # yüz hatları anne ya da babadan
	var same: Dictionary = a if fem(f) == kf else b
	if same.has("hair_style") and randf() < 0.6:
		lk["hair_style"] = same["hair_style"]
	var kid = {"rel": "Kızı" if kf else "Oğlu", "name": nm, "alive": true, "born": Time.get_unix_time_from_system(), "clan": clan, "look": lk,
		"el": String(f.get("element", "katon"))}
	if sp_clan != "" and my_clan != "" and sp_clan != my_clan:
		kid["mix"] = "%s × %s melezi" % [ClanWorld.clan_name(my_clan), ClanWorld.clan_name(sp_clan)]
	(f["family"] as Array).append(kid)
	var g = gen_of(f)
	Friends.log_event(f, "%s adında bir %s oldu" % [nm, "kızı" if kf else "oğlu"])
	f["news"] = "Bir %s oldu! Adını %s koyduk. Gel, kucağına al." % ["kızımız" if kf else "oğlumuz", nm.split(" ")[-1]]
	if g == 1:
		Hud.banner("TORUNUN OLDU", "%s'in bir %s oldu: %s." % [String(f["name"]).split(" ")[-1], "kızı" if kf else "oğlu", nm], Color(1, 0.85, 0.6))
		Journal.add("Torunum oldu: %s." % nm, "milestone")
	else:
		Hud.msg("Haber: %s %s'in bir %s oldu." % [_word(f), String(f["name"]).split(" ")[-1], "kızı" if kf else "oğlu"], Color(1, 0.85, 0.6), 6.0)


## Mezuniyet günü: soyundakilerin akademi çağına gelen çocukları gerçek tanıdık kaydı olur. Dönüş: duyuru adları
static func graduate_all(now: float, grow: float) -> Array:
	var names = []
	for id in fs().keys():
		var f: Dictionary = fs()[id]
		var g = gen_of(f)
		if g < 1:
			continue
		for m in f.get("family", []):
			if not String(m["rel"]) in ["Oğlu", "Kızı"] or not m.get("alive", true) or m.get("grad", false) or now - float(m.get("born", now)) < grow:
				continue
			m["grad"] = true
			var kf = String(m["rel"]) == "Kızı"
			var vid = String(f.get("village", Progress.home()))
			var clan = String(m.get("clan", f.get("clan", "")))
			var lk = Friends._ser(ClanWorld.clan_look(clan, "genin", vid, kf, "teen"))
			for key in (m.get("look", {}) as Dictionary):
				lk[key] = m["look"][key]
			lk["gender"] = "f" if kf else "m"
			var nid = Friends._make_friend(String(m["name"]), clan, lk, 55, title(g + 1, kf))
			var n: Dictionary = fs()[nid]
			n["gen"] = g + 1
			n["parent_fid"] = id
			n["village"] = vid
			n["loyalty"] = 90
			n["element"] = String(m.get("el", f.get("element", "katon")))
			n["pupil_lv"] = float(randi_range(8, 16))
			n["family"] = [{"rel": "Annesi" if fem(f) else "Babası", "name": String(f["name"]), "alive": true, "fid": id}]
			Aging.set_years(n, 12.0)
			m["fid"] = nid
			Friends.log_event(n, "Akademiden mezun oldu")
			Friends.log_event(f, "%s akademiden mezun oldu" % String(m["name"]))
			names.append("%s (%s)" % [String(m["name"]), "torunun" if g == 1 else "soyundan"])
	return names


## Yol mirasçıya geçerken (Legacy.inherit, mirasçının kaydı silinmeden hemen önce): onun ailesi senin ailen olur
static func on_inherit(hid: String, cf: Dictionary) -> void:
	var p: Dictionary = Game.profile
	var all = fs()
	var vid = String(cf.get("village", Progress.home()))
	# --- eşi: eşin
	var sp = spouse_entry(cf)
	if not sp.is_empty():
		var sid = String(sp.get("fid", ""))
		if sid == "" or not all.has(sid):
			sid = Friends._make_friend(String(sp["name"]), String(sp.get("clan", "")), _spouse_look(sp, vid, not fem(cf)), 85, "Eşin")
			var q = WorldPeople.get_p(String(sp.get("wid", "")))
			var s: Dictionary = all[sid]
			s["rank"] = clampi(int(q.get("rank", 1)), 1, 3) if not q.is_empty() else 1
			s["village"] = vid
			if not q.is_empty():
				Aging.set_years(s, Aging.person_years(q))
				s["element"] = String((q.get("els", ["katon"]) as Array)[0])
				WorldPeople.all().erase(String(q["id"]))   # artık senin eşin olarak yaşıyor: dünyada ikinci kopyası dolaşmaz
		var sf: Dictionary = all[sid]
		sf["romance"] = "eş"
		sf["title"] = "Eşin"
		sf["bond"] = maxi(int(sf.get("bond", 0)), 85)
		sf["love"] = maxi(int(sf.get("love", 0)), 80)
		sf.erase("kin")
		sf.erase("elder_kin")
		p["spouse"] = sid
	# --- soy: mirasçının altındakiler bir kuşak yaklaşır, ötekiler yeğen
	for id in all.keys():
		var f: Dictionary = all[id]
		if id == hid or int(f.get("gen", 0)) < 2:
			continue
		var d = 0
		var cur = String(f.get("parent_fid", ""))
		var hit = false
		while cur != "" and d < 8:
			d += 1
			if cur == hid:
				hit = true
				break
			cur = String((all.get(cur, {}) as Dictionary).get("parent_fid", ""))
		if hit and d == 1:
			f.erase("gen")
			f["child"] = true
			f["title"] = title(1, fem(f))
			f["bond"] = maxi(int(f.get("bond", 0)), 70)
			f["family"] = [{"rel": "Ebeveyni", "name": "%s (sen)" % String(cf["name"]), "alive": true}]
		elif hit:
			f["gen"] = d
			f["title"] = title(d, fem(f))
		else:
			f.erase("gen")
			f.erase("parent_fid")
			f["title"] = "Yeğenin"
	# --- evdeki küçükleri: senin çocukların (KidLife kaydı)
	if not p.has("children"):
		p["children"] = []
	for m in kid_entries(cf):
		if m.get("grad", false):
			continue
		var kid = {"name": String(m["name"]), "gender": "f" if String(m["rel"]) == "Kızı" else "m", "born": float(m.get("born", Time.get_unix_time_from_system())),
			"clans": [String(m["clan"])] if String(m.get("clan", "")) != "" else []}
		p["children"].append(kid)


## Yaşlılıktan ölümde yolu alabilecekler: mezun, hayatta, köyde çocukların
static func heirs() -> Array:
	var o = fs().keys().filter(func(k): return fs()[k].get("child", false) and String(fs()[k].get("status", "")) == "")
	o.sort_custom(func(a, b): return int(fs()[a].get("bond", 0)) > int(fs()[b].get("bond", 0)))
	return o
