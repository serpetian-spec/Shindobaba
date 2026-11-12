class_name WorldDay
extends RefCounted
## Dünya ninjalarının GÜNÜ: arka planda yaşanan hayat köyde görünür olur (WorldPeople / WorldKin üstünde, kalıp yok).
## · Herkesin günün her diliminde bir işi var; iş kişinin kendi verisinden çıkar (rütbe, rütbesine göre Güç açığı,
##   yas, aile, bağlılık, yaş): antrenman, nöbet, devriye, çatı, yemek, pazar, bank, gezi, mezar, meyhane, ev.
## · Köy hayatı (village_life) bir rol doğururken o an O İŞİ yapan gerçek kişiyi sahneye koyar: antrenman sahasında
##   dövüşen, kapıda nöbet tutan, ramen yiyen kişi kayıttaki ninjanın kendisidir (adı, yüzü, saçı, sözleri kendi hayatı).
## · Görevler yaşanır: köyler takım çıkarır (yakın bağlar birlikte), takım kapıdan çıkarken ve dönerken görünür, yolda
##   rastlanır; dönüşte biri yaralı olabilir (hastanede yatar), biri dönmeyebilir (kayıp ilanı / ölüm — eski zar yerine).
## Kayıt: Game.profile["world_day"] = {"seq", "runs": [takım], "next": {köy: saat}}; kişide "run" (takım kimliği), "hurt_t".

const ROLE_ACT := {"spar": "antrenman", "guard": "nobet", "patrol": "devriye", "roof": "cati", "customer": "yemek",
	"shopper": "pazar", "sitter": "bank", "drunk": "meyhane", "walker": "gezi", "chat": "gezi"}
const RANKS := ["D", "C", "B", "A", "S"]
const DAY := 1200.0

static var vl: Node            # köy hayatı yöneticisi (sahneye koyma)
static var auto := true        # test: kendi kendine takım çıkarma kapatılır
static var _stage := {}        # kişi -> WeakRef(sahnedeki düğüm)
static var _groups: Array = [] # sahnedeki takımlar: {"nodes", "line", "said"}
static var _t := 4.0
static var _road_t := 200.0
static var _seen := {}         # kişi -> gün (aynı gün bir kez kayda yazılır)


static func D() -> Dictionary:
	var pr: Dictionary = Game.profile
	if not pr.has("world_day") or not pr["world_day"] is Dictionary:
		pr["world_day"] = {"seq": 0, "runs": [], "next": {}}
	return pr["world_day"]


static func phase() -> String:
	var tod = float(Game.world.env.time_of_day) if Game.world and Game.world.get("env") else 0.5
	if tod < 0.24 or tod > 0.8:
		return "gece"
	if tod < 0.42:
		return "sabah"
	if tod < 0.62:
		return "oglen"
	return "aksam"


static func _h(id: String, salt: String) -> float:
	return float(absi(hash(id + "|" + salt)) % 10007) / 10007.0


static func hurt(p: Dictionary) -> bool:
	return float(p.get("hurt_t", 0.0)) > Aging.clock()


static func away(p: Dictionary) -> bool:
	return p.has("run")


static func _free(p: Dictionary) -> bool:
	return WorldPeople.alive(p) and not WorldPeople.is_rogue(p) and not p.get("missing", false)


static func staged(id: String) -> Node:
	var w = _stage.get(id)
	if w is WeakRef:
		var n = w.get_ref()
		if n != null and is_instance_valid(n) and not n.is_queued_for_deletion():
			return n
	_stage.erase(id)
	return null


# ====================================================================== günün işi
## Kişinin şu dilimdeki işi (gün + dilim boyunca sabit; iki yerde birden olmaz)
static func act_of(p: Dictionary, ph := "") -> String:
	if away(p):
		return "gorev"
	if hurt(p):
		return "hasta"
	if ph == "":
		ph = phase()
	var rank = int(p["rank"])
	var lr: Array = WorldPeople.RANK_LV[rank]
	# rütbesinin altlarında olan daha çok çalışır (hırs = Güç açığı)
	var hungry = 1.0 - clampf((float(p["level"]) - float(lr[0])) / maxf(1.0, float(lr[1]) - float(lr[0])), 0.0, 1.0)
	var grief = 1.0 if p.get("grief", false) else 0.0
	var fam = 1.0 if (not WorldKin.spouse_of(p).is_empty() or not WorldKin.kids_of(p).is_empty()) else 0.0
	var loyal = float(p.get("loyalty", 60)) / 100.0
	var old = clampf((Aging.person_years(p) - 50.0) / 20.0, 0.0, 1.0)
	var duty = 1.0 if rank >= 1 else 0.15
	var w := {}
	match ph:
		"sabah":
			w = {"antrenman": 1.6 + 2.0 * hungry + (1.0 if rank == 0 else 0.0), "nobet": 2.0 * duty, "devriye": (1.0 + loyal) * duty, "cati": 1.0 * duty,
				"mezar": 3.0 * grief, "gezi": 0.8 + fam, "bank": 2.0 * old, "ev": 0.5}
		"oglen":
			w = {"yemek": 3.0, "antrenman": 1.0 + 1.8 * hungry, "nobet": 1.6 * duty, "devriye": (0.8 + loyal) * duty, "cati": 0.8 * duty,
				"gezi": 1.2 + 1.5 * fam, "pazar": 1.0 + fam, "bank": 2.5 * old}
		"aksam":
			w = {"yemek": 2.5, "gezi": 1.2 + 2.0 * fam, "antrenman": 0.5 + 1.6 * hungry, "nobet": 1.4 * duty, "devriye": 1.0 * duty,
				"meyhane": 2.5 * grief + (1.0 - loyal) * 1.6, "mezar": 2.0 * grief, "ev": 1.0 + 1.5 * fam, "bank": 1.5 * old}
		_:
			w = {"ev": 5.0 + 3.0 * fam, "nobet": 2.2 * duty, "devriye": 1.6 * duty, "meyhane": 2.0 * grief + (1.0 - loyal) * 1.4,
				"antrenman": 1.4 * hungry, "cati": (1.0 if rank >= 2 else 0.0)}
	var tot = 0.0
	for k in w:
		tot += float(w[k])
	var r = _h(String(p["id"]), "%s%d" % [ph, int(Aging.clock() / DAY)]) * tot
	for k in w:
		r -= float(w[k])
		if r <= 0.0:
			return String(k)
	return "ev"


static func village_of(pos: Vector3) -> String:
	var m = Game.to_map(pos)
	for v in Game.world_info.get("villages", []):
		if m.distance_to(Vector2(v["x"], v["y"])) < float(v["r"]) * 1.05:
			return String(v["id"])
	return ""


## Köyde şu an bu işi yapan, sahnede olmayan gerçek kişi (yoksa boş: sıradan biri doğar)
static func cast(vid: String, act: String, near = null) -> Dictionary:
	if vid == "" or Game.profile.is_empty() or not WorldPeople.data().get("init", false):
		return {}
	var ph = phase()
	# antrenman eşi: yanında çalışan kişinin yakını (takım arkadaşı / eşi / kardeşi) önce
	if act == "antrenman" and near is Vector3:
		for id in _stage.keys():
			var n = staged(String(id))
			if n == null or not n is Node3D or (n as Node3D).global_position.distance_to(near) > 4.5:
				continue
			var a = WorldPeople.get_p(String(id))
			for q in _bonds(a):
				if _free(q) and not away(q) and not hurt(q) and staged(String(q["id"])) == null and String(q["village"]) == vid and act_of(q, ph) in ["antrenman", "gezi", "ev", "yemek"]:
					return q
	var c = []
	for p in WorldPeople.all().values():
		if String(p["village"]) != vid or not _free(p) or staged(String(p["id"])) != null:
			continue
		if act_of(p, ph) == act:
			c.append(p)
	return c.pick_random() if not c.is_empty() else {}


## Hastanedeki k. yatak: köyün yaralı dönen ninjalarından biri (yoksa boş)
static func patient(vid: String, k: int) -> Dictionary:
	if Game.profile.is_empty() or not WorldPeople.data().get("init", false):
		return {}
	var c = WorldPeople.all().values().filter(func(p): return String(p["village"]) == vid and _free(p) and hurt(p))
	c.sort_custom(func(a, b): return String(a["id"]) < String(b["id"]))
	return c[k] if k < c.size() else {}


## Yakın bağları: dünya kaydındaki yakını + ailesi
static func _bonds(p: Dictionary) -> Array:
	var o = []
	if p.is_empty():
		return o
	var c = WorldPeople.get_p(String(p.get("close", "")))
	if not c.is_empty():
		o.append(c)
	for r in WorldKin.relatives(p):
		if not r[0] in o:
			o.append(r[0])
	return o


static func tag_text(p: Dictionary) -> String:
	return "%s\n%s" % [String(p["name"]), WorldPeople.RANK_NAMES[clampi(int(p["rank"]), 0, 3)]]


## Sahneye koyma bilgisi (Villager alanları)
static func dress(p: Dictionary, act: String) -> Dictionary:
	var lk = WorldPeople.look_of(p)
	lk["age"] = "adult"
	lk["whole"] = true
	return {"look_extra": lk, "display_override": String(p["name"]), "lines_override": lines(p, act)}


static func on_stage(p: Dictionary, n: Node, act: String) -> void:
	_stage[String(p["id"])] = weakref(n)
	n.set_meta("world_person", String(p["id"]))
	n.set_meta("world_act", act)
	var fid = friend_of(String(p["id"]))
	if fid != "":
		n.set_meta("friend_id", fid)
		Friends.tag(n)
	elif n.has_method("set_name_tag"):
		n.set_name_tag(tag_text(p), Color(0.93, 0.93, 0.88))
	# görülen iş hayatına yazılır (günde bir kez): antrenman gerçekten güçlendirir
	var day = int(Aging.clock() / DAY)
	if act == "antrenman" and int(_seen.get(String(p["id"]), -1)) != day:
		_seen[String(p["id"])] = day
		var cap = int(WorldPeople.RANK_LV[int(p["rank"])][1]) + 25
		p["level"] = mini(cap, int(p["level"]) + 1)


## Antrenman eşleşince: ikisinin kaydına da yazılır
static func paired(a: Node, b: Node) -> void:
	var pa = WorldPeople.get_p(String(a.get_meta("world_person", "")))
	var pb = WorldPeople.get_p(String(b.get_meta("world_person", "")))
	if pa.is_empty() or pb.is_empty():
		return
	var key = "s" + String(pa["id"])
	var day = int(Aging.clock() / DAY)
	if int(_seen.get(key, -1)) == day:
		return
	_seen[key] = day
	WorldPeople.log_event(pa, "Antrenman sahasında %s ile çalıştı" % String(pb["name"]))
	WorldPeople.log_event(pb, "Antrenman sahasında %s ile çalıştı" % String(pa["name"]))
	a.lines_override = lines(pa, "antrenman", pb)
	b.lines_override = lines(pb, "antrenman", pa)


## Hâlâ o işi mi yapıyor (dilim değişince sahneden çekilir)
static func still(n: Node) -> bool:
	var p = WorldPeople.get_p(String(n.get_meta("world_person", "")))
	if p.is_empty() or not _free(p):
		return false
	var act = String(n.get_meta("world_act", ""))
	return act == "takim" or act_of(p) == act


static func _first(nm: String) -> String:
	return nm.split(" ")[-1]


## Kendi ağzından: şu an ne yaptığı + ailesi + son yaşadığı
static func lines(p: Dictionary, act: String, mate := {}) -> Array:
	var o = []
	var rk = int(p["rank"])
	match act:
		"antrenman":
			if not mate.is_empty():
				o.append("%s ile çalışıyoruz. O bırakmadan ben bırakmam." % _first(String(mate["name"])))
			if rk < 3:
				o.append("%s olmadan durmak yok. Daha çok yolum var." % WorldPeople.RANK_NAMES[rk + 1])
			else:
				o.append("Rütbe insanı korumaz. Her gün baştan çalışırım.")
		"nobet":
			o.append("Bugün nöbet bende. Kapıdan geçen herkesi görürüm.")
		"devriye":
			o.append("Devriyedeyim. Köyün sokaklarını ezbere bilirim artık.")
		"cati":
			o.append("Haber taşıyorum; çatılar en kısa yol.")
		"yemek":
			o.append("Görev aralarında sıcak bir kase... başka ne ister insan.")
		"pazar":
			o.append("Eve bir şeyler alıyorum. Görevden dönünce dolap hep boş oluyor.")
		"bank":
			o.append("Bu yaşta biraz oturmak da görev sayılır.")
		"meyhane":
			o.append("Bu gece içmem lazım. Sorma." if p.get("grief", false) else "Nöbet bitti. Bir kadeh hakkım var.")
		"gezi":
			o.append("Bugün boşum. Köyde dolaşmak iyi geliyor.")
		"hasta":
			o.append("Son görevden yaralı döndüm. Birkaç güne ayağa kalkarım.")
	var run = run_of(p)
	if not run.is_empty():
		o.clear()
		o.append("%s-rütbe görevdeyiz: %s." % [String(run["rank"]), String(run["what"])])
	for l in WorldKin.lines_of(p):
		if not String(l).begins_with("Köy bugün sakin"):
			o.append(l)
	var lg: Array = p.get("log", [])
	if not lg.is_empty():
		o.append("Geçenlerde: %s." % String(lg[-1]).trim_suffix("."))
	return o


# ====================================================================== seni tanırlar
## Bu kişinin SANA bakışı (yaşananlardan): {"k", "line", "act"} — act: "bow" eğilir, "turn" sırtını döner, "" yalnız söz.
## Sıra: kan davası > seni kurtaran / yakınını kurtardığın / bandını getirdiğin > Kage'si olduğun > rütbe farkı > yabancı köy
static func regard(p: Dictionary) -> Dictionary:
	if p.is_empty() or Game.profile.is_empty():
		return {}
	var me = String(Game.profile.get("name", ""))
	var mine = {"eşi": "eşimi", "oğlu": "oğlumu", "kızı": "kızımı", "babası": "babamı", "annesi": "annemi", "kardeşi": "kardeşimi"}
	if String(p.get("vendetta", "")) != "":
		return {"k": "nefret", "act": "turn", "line": "%s... %s kanı elinde. Benimle konuşma." % [me, WorldNews.sfx(String(p["vendetta"]), "in")]}
	var cl = WorldPeople.get_p(String(p.get("close", "")))
	if not cl.is_empty() and cl.get("slain_by_player", false):
		return {"k": "nefret", "act": "turn", "line": "%s senin elinden öldü. Yüzüne bakmam." % String(cl["name"])}
	if Orgs.is_rogue():
		return {}   # kaçaksın: köy ninjasının tepkisi zaten ayrı (korku / saldırı)
	if p.get("saved_by_player", false):
		return {"k": "minnet", "act": "bow", "line": "%s! Kayıpken beni sen getirdin. Hayatımı sana borçluyum." % me}
	for r in WorldKin.relatives(p):
		var q: Dictionary = r[0]
		if q.get("saved_by_player", false) and WorldPeople.alive(q):
			return {"k": "minnet", "act": "bow", "line": "%s sağ getiren sensin. Ailemiz bunu unutmaz." % String(mine.get(String(r[1]), "yakınımı")).capitalize()}
	if p.get("band_by_player", false):
		return {"k": "minnet", "act": "bow", "line": "O alın bandını bana sen getirdin. Onunla vedalaşabildim. Sağ ol."}
	var vid = String(p["village"])
	var home = vid == Progress.home()
	if home and Kage.is_kage():
		return {"k": "kage", "act": "bow", "line": "%s-sama." % Progress.kage_title(vid)}
	if not home:
		return {"k": "yabanci", "act": "", "line": "%s ninjası değilsin. Burada misafirsin; ona göre davran." % WorldPeople.vname(vid).replace("gakure", "")}
	var mine_rank = int(Game.profile.get("rank", 0))
	var his = int(p["rank"]) + 1
	if mine_rank > his:
		return {"k": "ust", "act": "bow", "line": "%s-san. Kolay gelsin." % me}
	if mine_rank < his:
		return {"k": "ast", "act": "", "line": ["%s, antrenmanı aksatma.", "%s. Görevde başını belaya sokma.", "Seni izliyorum %s. Fena gitmiyorsun."][absi(hash(String(p["id"]))) % 3] % me}
	return {"k": "denk", "act": "", "line": ["%s. Bir gün seninle bir tur atalım.", "%s, bugün nöbet kimde biliyor musun?", "Selam %s."][absi(hash(String(p["id"]))) % 3] % me}


static func regard_node(n: Node) -> Dictionary:
	return regard(WorldPeople.get_p(String(n.get_meta("world_person", ""))))


# ====================================================================== tanışma (Friends ile köprü)
static func friend_of(wid: String) -> String:
	if wid == "":
		return ""
	var fs = Friends.all()
	for id in fs:
		if String(fs[id].get("wid", "")) == wid:
			return String(id)
	return ""


## "Kendini tanıt": dünya ninjası gerçek kimliğiyle tanıdığın olur (adı, klanı, gözü, rütbesi, ailesi kayıttan)
static func meet(v: Node) -> void:
	var p = WorldPeople.get_p(String(v.get_meta("world_person", "")))
	if p.is_empty():
		return
	var keep_site = v.has_meta("site_key")
	if keep_site:
		v.remove_meta("site_key")   # sabit yere bağlanmaz: günü neredeyse orada olur
	Friends._meet(v, String(p["name"]))
	var fid = String(v.get_meta("friend_id", ""))
	var fs = Friends.all()
	if fid == "" or not fs.has(fid):
		return
	var f: Dictionary = fs[fid]
	f["wid"] = String(p["id"])
	f["clan"] = String(p["clan"])
	f["eye"] = (p.get("eye", [0, 0]) as Array).duplicate()
	f["rank"] = clampi(int(p["rank"]), 0, 2)
	f["element"] = String((p["els"] as Array)[0])
	f["village"] = String(p["village"])
	f["born_t"] = Aging.clock() - Aging.person_years(p) * Aging.YEAR
	f["title"] = ("%s klanı" % ClanWorld.clan_name(String(p["clan"]))) if String(p["clan"]) != "" else "%s ninjası" % WorldPeople.vname(String(p["village"]))
	var fam = []
	for r in WorldKin.relatives(p):
		var q: Dictionary = r[0]
		fam.append({"rel": String(r[1]).capitalize(), "name": String(q["name"]), "alive": WorldPeople.alive(q)})
	f["family"] = fam
	Friends.tag(v)


## Dünyadaki kişi öldü / kaçtı: tanıdığınsa haberi sana da gelir
static func on_death(p: Dictionary, why: String) -> void:
	var fid = friend_of(String(p["id"]))
	if fid == "":
		return
	var f: Dictionary = Friends.all()[fid]
	if String(f.get("status", "")) != "":
		return
	f["status"] = "öldü"
	f["party"] = false
	f["news"] = why
	Hud.msg("Acı haber: tanıdığın %s öldü. (%s)" % [String(p["name"]), why], Color(1, 0.6, 0.55), 8.0)


# ====================================================================== görevler (takımlar)
static func run_of(p: Dictionary) -> Dictionary:
	var id = String(p.get("run", ""))
	if id == "":
		return {}
	for r in D()["runs"]:
		if String(r["id"]) == id:
			return r
	return {}


## Görevin ne olduğu: köyün çevresindeki GERÇEK yerlerden (kamp, harabe, tapınak, komşu köy)
static func _what(vid: String, ri: int) -> String:
	var v = Game.village(vid)
	var c = Vector2(float(v.get("x", 0.0)), float(v.get("y", 0.0)))
	var reach = 2500.0 + ri * 1800.0
	var near = Game.pois.filter(func(q): return String(q.get("name", "")) != "" and Vector2(float(q["x"]), float(q["y"])).distance_to(c) < reach)
	var others = (Game.world_info.get("villages", []) as Array).filter(func(o): return String(o["id"]) != vid)
	others.sort_custom(func(a, b): return Vector2(a["x"], a["y"]).distance_to(c) < Vector2(b["x"], b["y"]).distance_to(c))
	var r = randf()
	if not near.is_empty() and r < 0.6:
		var q: Dictionary = near.pick_random()
		var nm = String(q["name"])
		match String(q.get("t", "")):
			"camp", "bandit":
				return "%s baskını" % nm
			"ruin":
				return "%s keşfi" % nm
			"shrine", "monument":
				return "%s nöbeti" % nm
			"onsen":
				return "%s yolunda yolcu koruma" % nm
		return "%s çevresinde keşif" % nm
	if not others.is_empty():
		var o: Dictionary = others[randi() % mini(3, others.size())]
		var on = String(o.get("name", o["id"]))
		return ["%s yolunda kervan eskortu", "%s köyüne mühürlü mektup", "%s sınırında devriye", "%s yönünde kaçak takibi"][clampi(ri + randi() % 2 - 1, 0, 3)] % on
	return "sınır devriyesi"


## Köy bir takım çıkarır: lider + yakın bağı + boşta olanlar (genin yalnız gitmez). Dönen: takım kaydı ya da boş
static func dispatch(vid: String, force := false) -> Dictionary:
	var pool = WorldPeople.all().values().filter(func(p): return String(p["village"]) == vid and _free(p) and not away(p) and not hurt(p) and (force or staged(String(p["id"])) == null))
	var leads = pool.filter(func(p): return int(p["rank"]) >= 1)
	if leads.is_empty():
		return {}
	var lead: Dictionary = leads.pick_random()
	var team = [lead]
	for q in _bonds(lead):
		if q in pool and not q in team and team.size() < 3 and randf() < 0.7:
			team.append(q)
	var rest = pool.filter(func(p): return not p in team and int(p["rank"]) <= int(lead["rank"]))
	rest.shuffle()
	var want = 3 if int(lead["rank"]) < 3 else randi_range(1, 3)   # elit jōnin tek başına da gider
	for q in rest:
		if team.size() >= want:
			break
		team.append(q)
	if team.size() < 2 and int(lead["rank"]) < 2:
		return {}
	var avg = 0.0
	for q in team:
		avg += float(q["level"]) / team.size()
	var ri = 0 if avg < 35.0 else (1 if avg < 70.0 else (2 if avg < 110.0 else (3 if avg < 150.0 else 4)))
	if ri > 0 and randf() < 0.3:
		ri -= 1
	var d = D()
	d["seq"] = int(d["seq"]) + 1
	var run = {"id": "r%d" % int(d["seq"]), "vid": vid, "team": team.map(func(q): return String(q["id"])), "rank": RANKS[ri], "ri": ri,
		"what": _what(vid, ri), "t0": Aging.clock(), "t1": Aging.clock() + 240.0 + ri * 80.0 + randf_range(0.0, 150.0), "need": avg}
	(d["runs"] as Array).append(run)
	for q in team:
		q["run"] = String(run["id"])
	_show(run, true)
	return run


## Takım döndü: sonuç hayatlarına yazılır (başarı, yara, dönmeyen)
static func resolve(run: Dictionary) -> void:
	(D()["runs"] as Array).erase(run)
	var ri = int(run["ri"])
	var team = []
	for id in run["team"]:
		var q = WorldPeople.get_p(String(id))
		if q.is_empty():
			continue
		q.erase("run")
		if _free(q):
			team.append(q)
	if team.is_empty():
		return
	var names = team.map(func(q): return String(q["name"]))
	var back = []
	var lost = []
	for q in team:
		var risk = [0.004, 0.009, 0.016, 0.028, 0.05][ri] * clampf(float(run["need"]) / maxf(8.0, float(q["level"])), 0.5, 2.0)
		var r = randf()
		if r < risk:
			lost.append(q)
			continue
		back.append(q)
		var mates = names.filter(func(n): return n != String(q["name"]))
		var with = (" (%s ile)" % ", ".join(mates)) if not mates.is_empty() else ""
		if r < risk * 4.0 + 0.05:
			q["hurt_t"] = Aging.clock() + randf_range(300.0, 700.0)
			WorldPeople.log_event(q, "%s-rütbe görevden yaralı döndü: %s%s" % [String(run["rank"]), String(run["what"]), with])
		else:
			WorldPeople.log_event(q, "%s-rütbe görevi tamamladı: %s%s" % [String(run["rank"]), String(run["what"]), with])
			var cap = int(WorldPeople.RANK_LV[int(q["rank"])][1]) + 25
			q["level"] = mini(cap, int(q["level"]) + randi_range(1, 2 + ri))
	for q in lost:
		if not WorldNews.went_missing(q):
			WorldPeople._die(q, "Bir görevden dönmedi (%s)" % String(run["what"]))
			if String(run["vid"]) == Progress.home() and not back.is_empty():
				WorldNews.headline("%s: %s takımı görevden döndü; %s aralarında yok." % [WorldPeople.vname(String(run["vid"])), WorldNews.sfx(String(team[0]["name"]), "in"), String(q["name"])], Color(1, 0.6, 0.55))
	run["back"] = back.map(func(q): return String(q["id"]))
	if not back.is_empty():
		_show(run, false)


# ====================================================================== her kare (WorldPeople._process çağırır)
static func tick(dt: float) -> void:
	if Game.player == null or Game.profile.is_empty():
		return
	_bubbles()
	_t -= dt
	if _t > 0.0:
		return
	_t = 4.0
	var now = Aging.clock()
	for run in (D()["runs"] as Array).duplicate():
		if now >= float(run["t1"]):
			resolve(run)
	if auto:
		var nx: Dictionary = D()["next"]
		for v in Game.world_info.get("villages", []):
			var vid = String(v["id"])
			var major = vid in WorldPeople.MAJOR
			if not major and not vid in WorldPeople.MINOR:
				continue
			if not nx.has(vid):
				nx[vid] = now + randf_range(20.0, 240.0)
			if now < float(nx[vid]):
				continue
			nx[vid] = now + (randf_range(150.0, 320.0) if major else randf_range(420.0, 800.0))
			dispatch(vid)
		_road(4.0)
	# uzaklaşan takım sahneden çekilir (yolculuk kayıtta sürer)
	for g in _groups:
		var ln = (g["nodes"] as Array)[0]
		if not is_instance_valid(ln) or ln.global_position.distance_to(Game.player.global_position) > 115.0:
			for n in g["nodes"]:
				if is_instance_valid(n):
					n.queue_free()
	_groups = _groups.filter(func(g): return (g["nodes"] as Array).any(func(n): return is_instance_valid(n) and not n.is_queued_for_deletion()))


static func _outdoors() -> bool:
	return Interiors.inst != null and Interiors.inst.inside == "" and not Missions.quiet() and not int(ChuninExam.stage) in [2, 3, 4, 5]


## Köyün kapıları (dünya konumu, surun hemen dışı) — builder ile aynı açı düzeni
static func gates(vid: String) -> Array:
	var v = Game.village(vid)
	var o = []
	if v.is_empty():
		return o
	var c = Game.from_map(Vector2(float(v["x"]), float(v["y"])))
	var r = (float(v["r"]) - 40.0) if vid == "konoha" else float(v["r"]) * 0.95   # sur çizgisi (bitki örtüsünün sur şeridiyle aynı sayılar)
	for a in v.get("gates", []):
		var ar = deg_to_rad(float(a))
		var q = c + Vector3(sin(ar), 0, -cos(ar)) * (r - 16.0)   # kapının hemen içi (kapı dikmeleri / kanatları yürüyüş hattını kesmesin)
		q.y = Game.ground_height(q.x, q.z)
		o.append(q)
	return o


## Görev masası / Kage binası önü: merkeze yakın nöbetçi noktası (yoksa köy merkezi)
static func hall(vid: String) -> Vector3:
	var v = Game.village(vid)
	var c = Game.from_map(Vector2(float(v["x"]), float(v["y"])))
	if vl != null and is_instance_valid(vl):
		var best = Vector3.INF
		for s in vl.sites.get(vid, []):
			if String(s["type"]) == "guard" and (s["pos"] as Vector3).distance_to(c) < float(v["r"]) * 0.5:
				if best == Vector3.INF or (s["pos"] as Vector3).distance_to(c) < best.distance_to(c):
					best = s["pos"]
		if best != Vector3.INF:
			return best
	return Missions.open_ground(c, 30.0)


## Takımın çıkışı / dönüşü: oyuncu o köydeyse sokaktan geçerler (kapıya ya da görev masasına yürürler)
static func _show(run: Dictionary, leaving: bool) -> Array:
	if vl == null or not is_instance_valid(vl) or Game.player == null or not _outdoors():
		return []
	var vid = String(run["vid"])
	var pp = Game.player.global_position
	if village_of(pp) != vid:
		return []
	var gs = gates(vid)
	if gs.is_empty():
		return []
	gs.sort_custom(func(a, b): return a.distance_to(pp) < b.distance_to(pp))
	var gate: Vector3 = gs[0]
	var to: Vector3 = gate if leaving else hall(vid)
	# yolun OYUNCUYA YAKIN kesimi sahnelenir (uzaktaki köylü zaten donuk): görüş dışındaki bir sokak noktasından geçerler;
	# dönüşte kapı yakınsa kapıdan girerler
	var from = Vector3.INF
	var cam = Game.player.get_viewport().get_camera_3d()
	if not leaving and gate.distance_to(pp) > 22.0 and gate.distance_to(pp) < 62.0:
		from = gate
	else:
		var pts: Array = vl._streets(Game.village(vid)).filter(func(q): return q.distance_to(pp) > 30.0 and q.distance_to(pp) < 56.0 and q.distance_to(to) > 40.0)
		if pts.is_empty():
			# yakında sokak noktası yok (meydan, park): çevredeki açık zemin
			for k in 8:
				var a = randf() * TAU
				var q = Missions.open_ground(pp + Vector3(cos(a), 0, sin(a)) * randf_range(34.0, 50.0), 10.0)
				if q.distance_to(pp) > 28.0 and q.distance_to(pp) < 58.0 and Game.terrain_height(q.x, q.z) > 0.3:
					pts.append(q)
		if pts.is_empty():
			return []
		# yolları oyuncunun yanından geçsin: oyuncu, çıkış noktasıyla hedefin arasında kalsın; mümkünse görüş dışında doğsunlar
		var tw = func(q: Vector3) -> float:
			var u = pp - q
			var w = to - q
			u.y = 0
			w.y = 0
			return u.normalized().dot(w.normalized())
		pts.sort_custom(func(a, b): return tw.call(a) > tw.call(b))
		from = pts[0]
		for q in pts.slice(0, 8):
			if cam == null or not cam.is_position_in_frustum(q + Vector3.UP):
				from = q
				break
	var ids: Array = run["team"] if leaving else run.get("back", [])
	var people = []
	for id in ids:
		var q = WorldPeople.get_p(String(id))
		if not q.is_empty() and WorldPeople.alive(q) and staged(String(id)) == null:
			people.append(q)
	if people.is_empty():
		return []
	var line = ""
	if leaving:
		line = "%s-rütbe görev: %s. Gidiyoruz." % [String(run["rank"]), String(run["what"])]
	elif people.any(func(q): return hurt(q)):
		line = "Döndük... Önce hastaneye."
	elif (run["team"] as Array).size() > people.size():
		line = "Döndük. Hepimiz değil."
	else:
		line = "Görev tamam. Rapor verip dinleneceğiz."
	return stage_team(people, from, to, line, people.any(func(q): return hurt(q)) and not leaving)


## Takımı sahneye koy: lider hedefe yürür, diğerleri arkasında; varınca kaybolurlar
static func stage_team(people: Array, from: Vector3, to: Vector3, line: String, slow := false) -> Array:
	var nodes = []
	var lead: Node3D = null
	for i in people.size():
		var q: Dictionary = people[i]
		var ex = dress(q, "takim")
		ex["speed"] = 2.1 if slow else 3.3
		var at = from + Vector3(0.9 * (i % 2 * 2 - 1) * (1 if i > 0 else 0), 0, 1.2 * i)
		var n = vl._villager("team", at, vl.street_cache.get(village_of(from), []), ex)
		vl.npcs.erase(n)
		on_stage(q, n, "takim")
		if lead == null:
			lead = n
			n.dest = to
		else:
			n.follow = lead
			n.follow_off = Vector3(0.85 * (i % 2 * 2 - 1), 0, 0.9 + 0.5 * i)
		nodes.append(n)
	_groups.append({"nodes": nodes, "line": line, "said": false})
	return nodes


static func _bubbles() -> void:
	if Game.player == null:
		return
	for g in _groups:
		if g["said"]:
			continue
		var n = (g["nodes"] as Array)[0]
		if is_instance_valid(n) and n.global_position.distance_to(Game.player.global_position) < 16.0:
			g["said"] = true
			n.say(String(g["line"]), 4.0)


## Yolda: görevdeki bir takımla karşılaşma (en yakın köyün sahadaki takımı; köyüne doğru ya da köyünden uzağa yürür)
static func _road(dt: float) -> void:
	_road_t -= dt
	if _road_t > 0.0 or vl == null or not is_instance_valid(vl) or not _outdoors():
		return
	var pp = Game.player.global_position
	if village_of(pp) != "" or Game.player.hp <= 0.0 or Game.player.get("scene_hold"):
		return
	_road_t = 30.0
	var pm = Game.to_map(pp)
	var best = {}
	var bd = 3500.0
	for run in D()["runs"]:
		var v = Game.village(String(run["vid"]))
		if v.is_empty():
			continue
		var d = pm.distance_to(Vector2(float(v["x"]), float(v["y"])))
		if d < bd:
			bd = d
			best = run
	if best.is_empty() or randf() > 0.35:
		return
	if not road_meet(best).is_empty():
		_road_t = randf_range(360.0, 600.0)


static func road_meet(run: Dictionary) -> Array:
	var pl = Game.player
	var pp = pl.global_position
	var people = []
	for id in run["team"]:
		var q = WorldPeople.get_p(String(id))
		if not q.is_empty() and _free(q) and staged(String(id)) == null:
			people.append(q)
	if people.is_empty():
		return []
	var v = Game.village(String(run["vid"]))
	var home = Game.from_map(Vector2(float(v["x"]), float(v["y"])))
	var out = float(run["t1"]) - Aging.clock() > (float(run["t1"]) - float(run["t0"])) * 0.5   # ilk yarı: gidiyorlar
	var fwd: Vector3 = pl.face_dir() if pl.has_method("face_dir") else Vector3.FORWARD
	var from = Missions.open_ground(pp + fwd.rotated(Vector3.UP, randf_range(-0.5, 0.5)) * randf_range(44.0, 58.0), 16.0)
	var dir = (home - from)
	dir.y = 0
	dir = dir.normalized() * (-1.0 if out else 1.0)
	var to = from + dir * 260.0
	var line = ("%s-rütbe görev: %s. Yolumuz uzun." if out else "%s-rütbe görev bitti (%s). Köye dönüyoruz.") % [String(run["rank"]), String(run["what"])]
	return stage_team(people, from, to, line)
