class_name WorldFolk
## Kalıcı siviller: köyün sokağındaki köylü artık her seferinde yeniden uydurulmaz. İlk görüldüğü an kayda geçer
## (adı, yaşı, görünüşü), sonra hep aynı kişidir; yaşlanır, yaşlılıktan ölür. Bir kısmı köyün gerçek ninjalarının
## yakınıdır (anne, baba, kardeş): sözü yakınının O ANKİ durumundan çıkar (görevde, yaralı, kayıp, terfi etti, öldü).
## Kayıt: profile["world_folk"][köy][id] = {id, name, f, born_t, look, kin, rel, met, site}

const ROLES := ["walker", "chat", "shopper", "customer", "sitter", "kid", "ball", "drunk", "vendor", "keeper", "worker"]
const CAP_BIG := 64
const CAP_SMALL := 28
static var _stage := {}   # id -> WeakRef(düğüm): aynı kişi aynı anda iki yerde olmasın


static func D() -> Dictionary:
	if Game.profile.is_empty():
		return {}
	if not Game.profile.has("world_folk"):
		Game.profile["world_folk"] = {}
	return Game.profile["world_folk"]


static func of(vid: String) -> Dictionary:
	var d = D()
	if not d.has(vid):
		d[vid] = {}
	return d[vid]


static func get_f(vid: String, id: String) -> Dictionary:
	return of(vid).get(id, {}) if not Game.profile.is_empty() else {}


static func staged(id: String) -> bool:
	var w = _stage.get(id)
	if w is WeakRef:
		var n = w.get_ref()
		return n != null and is_instance_valid(n) and not n.is_queued_for_deletion()
	return false


static func _cat(role: String) -> String:
	return "child" if role in ["kid", "ball"] else ("elder" if role == "sitter" else "adult")


static func _cat_of(f: Dictionary) -> String:
	var y = Aging.years(f)
	return "child" if y < 12.0 else ("elder" if y >= 62.0 else "adult")


static func _h(id: String, salt: String) -> float:
	return float(absi(hash(id + ":" + salt)) % 10000) / 10000.0


## Bu rol için köyün kayıtlı bir sivili (sahnede olmayan, yaşı role uyan). Boşsa: yeni biri doğar (Villager kayda geçirir).
## site: sabit mekânın kişisi (aynı tezgâhta hep aynı satıcı).
static func cast(vid: String, role: String, site := "") -> Dictionary:
	if vid == "" or Game.profile.is_empty() or not role in ROLES:
		return {}
	var folk = of(vid)
	var cat = _cat(role)
	var c = []
	for id in folk.keys():
		var f: Dictionary = folk[id]
		var y = Aging.years(f)
		if y > 76.0 + _h(id, "omur") * 12.0 and not staged(id):
			_pass_away(vid, f)
			continue
		if staged(id):
			continue
		if site != "":
			if String(f.get("site", "")) == site:
				return f
			continue
		if String(f.get("site", "")) != "" or _cat_of(f) != cat:
			continue
		if role == "drunk" and (f.get("f", false) or y < 20.0):
			continue
		c.append(f)
	if site != "":
		return {}
	if c.is_empty():
		return {}
	# kayıt dolmadıysa bazen yeni yüz (köy bir günde tanınmaz; nüfus zamanla oturur)
	var cap = CAP_BIG if vid in WorldPeople.MAJOR else CAP_SMALL
	if folk.size() < cap and randf() < 0.5:
		return {}
	return c.pick_random()


static func room(vid: String) -> bool:
	return of(vid).size() < (CAP_BIG if vid in WorldPeople.MAJOR else CAP_SMALL) + 12


## Kayıtlı sivilin görünüşü (bugünkü yaşıyla)
static func dress(f: Dictionary) -> Dictionary:
	var lk: Dictionary = Missions._bb_look({"look": f.get("look", {})})
	var y = Aging.years(f)
	lk["years"] = y
	lk["age"] = Aging.stage(y)
	lk.erase("aged")
	lk["npc"] = true
	lk["whole"] = true
	return {"look_extra": lk, "display_override": String(f["name"])}


## Villager._ready (görünüş kurulmadan hemen önce): yeni sivil kayda geçer. Dönen: adı.
static func adopt(vid: String, role: String, lk: Dictionary, site := "") -> Dictionary:
	if Game.profile.is_empty() or vid == "" or not room(vid):
		return {}
	Game.profile["world_folk_seq"] = int(Game.profile.get("world_folk_seq", 0)) + 1
	var id = "c%d" % int(Game.profile["world_folk_seq"])
	var female = String(lk.get("gender", "m")) == "f"
	var f = {"id": id, "f": female, "look": WorldPeople._ser(lk), "met": 0, "vid": vid}
	(f["look"] as Dictionary).erase("whole")
	Aging.set_years(f, float(lk.get("years", 30.0)))
	if site != "":
		f["site"] = site
	var fam = String(Missions.BB_FAMILY.pick_random())
	var kin = _find_kin(vid, f)
	if not kin.is_empty():
		f["kin"] = String(kin[0]["id"])
		f["rel"] = String(kin[1])
		fam = String(kin[0]["name"]).get_slice(" ", 0)   # yakınının soyadı
	f["name"] = "%s %s" % [fam, (ClanWorld.GIVEN_F if female else ClanWorld.GIVEN_M).pick_random()]
	of(vid)[id] = f
	return f


## Köyün gerçek ninjalarından yakın: yaşı tutuyorsa anne / baba (17+ yaş büyük), yakın yaştaysa kardeş. Bir ninjanın en çok 2 sivil yakını olur.
static func _find_kin(vid: String, f: Dictionary) -> Array:
	if not WorldPeople.data().get("init", false) or randf() < 0.45:
		return []
	var y = Aging.years(f)
	var used := {}
	for g in of(vid).values():
		var k = String(g.get("kin", ""))
		if k != "":
			used[k] = int(used.get(k, 0)) + 1
	var c = []
	for p in WorldPeople.all().values():
		if String(p["village"]) != vid or not WorldPeople.alive(p) or WorldPeople.is_rogue(p) or int(used.get(String(p["id"]), 0)) >= 2:
			continue
		var py = Aging.person_years(p)
		if y >= py + 17.0 and y <= py + 45.0:
			# aynı ninjaya iki anne / iki baba olmasın
			var dup = false
			for g in of(vid).values():
				if String(g.get("kin", "")) == String(p["id"]) and String(g.get("rel", "")) == "parent" and bool(g.get("f", false)) == bool(f["f"]):
					dup = true
			if not dup:
				c.append([p, "parent"])
		elif absf(y - py) < 10.0 and y >= 6.0 and String(p["clan"]) == "":
			c.append([p, "sibling"])   # klanlı ninjanın kardeşi de ninja olur; sivil kardeş klansızlara
	return c.pick_random() if not c.is_empty() else []


static func on_stage(f: Dictionary, n: Node) -> void:
	_stage[String(f["id"])] = weakref(n)
	n.set_meta("folk", String(f["id"]))
	n.set_meta("folk_vid", String(f["vid"]))
	if int(f.get("met", 0)) > 0 and n.has_method("set_name_tag"):
		n.set_name_tag(String(f["name"]), Color(0.86, 0.84, 0.76))   # tanıştığın sivilin adı başında


static func of_node(n: Node) -> Dictionary:
	if n == null or not n.has_meta("folk"):
		return {}
	return get_f(String(n.get_meta("folk_vid", "")), String(n.get_meta("folk")))


## Yaşlılıktan ölüm: kayıttan çıkar, yakını olan ninjanın hayatına yazılır
static func _pass_away(vid: String, f: Dictionary) -> void:
	var p = WorldPeople.get_p(String(f.get("kin", "")))
	if not p.is_empty() and WorldPeople.alive(p):
		var w = ("annesi" if f.get("f", false) else "babası") if String(f.get("rel", "")) == "parent" else "kardeşi"
		WorldPeople.log_event(p, "%s %s yaşlılıktan öldü" % [w.capitalize(), String(f["name"])])
	of(vid).erase(String(f["id"]))


# ====================================================================== sözler
## Yakınına nasıl seslenir
static func kin_word(f: Dictionary, p: Dictionary) -> String:
	var pf = bool(p.get("female", false))
	if String(f.get("rel", "")) == "parent":
		return "kızım" if pf else "oğlum"
	if Aging.person_years(p) > Aging.years(f):
		return "ablam" if pf else "ağabeyim"
	return "kardeşim"


## Sana bakışı: yakınını sen öldürdüysen sırtını döner; kurtardıysan eğilir
static func regard(f: Dictionary) -> Dictionary:
	var p = WorldPeople.get_p(String(f.get("kin", "")))
	if p.is_empty():
		return {}
	var pn = String(p["name"]).get_slice(" ", 1)
	if not WorldPeople.alive(p) and p.get("slain_by_player", false):
		return {"k": "nefret", "act": "turn", "line": "%s... %s senin elinden öldü. Yüzüne bakmak istemiyorum." % [pn, kin_word(f, p).capitalize()]}
	if WorldPeople.alive(p) and (p.get("saved_by_player", false) or p.get("band_by_player", false)):
		return {"k": "minnet", "act": "bow", "line": "%s eve döndüyse senin sayende. Bu borç ödenmez." % [kin_word(f, p).capitalize() + " " + pn]}
	return {}


## Konuşunca söylediği (base: rolün sıradan sözü)
static func line(f: Dictionary, n: Node, base: String) -> String:
	var rg = regard(f)
	if not rg.is_empty():
		return String(rg["line"])
	var me = String(Game.profile.get("name", ""))
	var met = int(f.get("met", 0))
	var y = Aging.years(f)
	var o = []
	var p = WorldPeople.get_p(String(f.get("kin", "")))
	if not p.is_empty():
		var kw = kin_word(f, p).capitalize()
		var pn = String(p["name"]).get_slice(" ", 1)
		var who = "%s %s" % [kw, pn]
		var rk = String(WorldPeople.RANK_NAMES[clampi(int(p["rank"]), 0, 3)])
		if not WorldPeople.alive(p):
			o.append("%s artık yok. Adı anıt taşında yazıyor; her sabah oraya gidiyorum." % who)
			o.append("%s bir görevden dönmedi. Ninja ailesi olmak budur derler... alışılmıyor." % who)
		elif WorldPeople.is_rogue(p):
			o.append("%s köyü terk etti. Komşular yüzüme bakmıyor artık." % who)
		elif p.get("missing", false):
			o.append("%s görevden dönmedi. Görev masası 'arıyoruz' diyor, başka bir şey demiyor." % who)
		elif String(p.get("kage", "")) != "":
			o.append("%s %s oldu! Bizim evden bir Kage çıktı, inanabiliyor musun?" % [who, Progress.kage_title(String(p["kage"]))])
		elif WorldDay.hurt(p):
			o.append("%s hastanede yatıyor. Görevden yaralı döndü; yemeğini ben götürüyorum." % who)
		elif WorldDay.away(p):
			o.append("%s görevde. Dönene kadar gözüme uyku girmez." % who)
		else:
			if y < 12.0:
				o.append("%s bir %s! Ben de büyüyünce ninja olacağım." % [who, rk.to_lower()])
			else:
				o.append("%s bu köyün %s'i. Eve geç gelir ama gelir, şükür." % [who, rk.to_lower()])
			var lg: Array = p.get("log", [])
			if not lg.is_empty():
				o.append("%s için diyorlar ki: %s. Evde hiç anlatmaz." % [who, String(lg.back())])
			var dr = WorldDay.dream(p)
			if dr == "kage":
				o.append("%s 'bir gün şapkayı takacağım' diyor. Ben sağ dönsün, yeter diyorum." % who)
			elif dr == "intikam":
				o.append("%s değişti. Gözünde eski ışık yok; içinde bir hesap büyütüyor." % who)
			elif dr == "rakip":
				o.append("%s sabah akşam antrenmanda. Biri onu geçmiş, onu yiyip bitiriyor." % who)
	if met == 0:
		var intro = "Ben %s." % String(f["name"])
		if String(f.get("site", "")) != "":
			intro += " Bu tezgâh yıllardır bizim."
		elif y >= 62.0:
			intro += " Bu köyde doğdum, burada yaşlandım."
		elif y < 12.0:
			intro = "Benim adım %s!" % String(f["name"]).get_slice(" ", 1)
		return intro + (" " + String(o.pick_random()) if not o.is_empty() else " " + base)
	if met >= 6:
		o.append("%s! Seni görmeden gün geçmiyor artık." % me)
	elif met >= 2:
		o.append("Yine karşılaştık %s." % me)
	if o.is_empty() or randf() < 0.35:
		return base
	return String(o.pick_random())


## Konuşma bitti: artık tanışıksınız (adı başında görünür)
static func talked(f: Dictionary, n: Node) -> void:
	f["met"] = int(f.get("met", 0)) + 1
	if n.has_method("set_name_tag"):
		n.set_name_tag(String(f["name"]), Color(0.86, 0.84, 0.76))
