class_name WorldNews
extends RefCounted
## Dinamik görev panosu: görevler dünyada GERÇEKTEN olanlardan doğar (WorldPeople / WorldKin yaşantısı).
## · Görevden dönmeyen ninja  -> "Kayıp Ninja" (kurtarılırsa yaşar, yakınıyla kavuşur; kimse gitmezse başka takım gider, o da başaramazsa ölür)
## · Kaçağın soyduğu kervan   -> "Soyulan Kervan" (kamp reisi o kaçağın kendisi)
## · Köyden kaçan ninja       -> "Firari" (sınırı geçmeden iz sür; süre dolarsa Bingo Kitabı'nda kalır)
## · Ölen ninjanın ailesi     -> "Son Yadigâr" (alın bandını bul, yas tutan yakınına elden ver)
## · Kaçağın kundakladığı ev  -> "Yangın" (kuyudan su taşı, içeride kalanı çıkar)
## Her olayın süresi var: sen almazsan köyün başka bir takımı (gerçek insanlar) gider; sonucu haber olur, hayatlarına yazılır.
## Kayıt: Game.profile["world_news"] = {"seq", "list": [olay], "news": [son haberler]}

const LIFE := {"missing": 1500.0, "robbed": 1800.0, "deserter": 900.0, "band": 2400.0, "fire": 480.0}
const MAX_OPEN := 3      # köy başına açık olay
const RANK_OF_PERSON := ["C", "B", "A", "A"]


static func D() -> Dictionary:
	var pr: Dictionary = Game.profile
	if not pr.has("world_news") or not pr["world_news"] is Dictionary:
		pr["world_news"] = {"seq": 0, "list": [], "news": []}
	return pr["world_news"]


static func open_for(vid: String) -> Array:
	return (D()["list"] as Array).filter(func(x): return String(x["vid"]) == vid and String(x["state"]) == "open")


static func find(id: String) -> Dictionary:
	for x in D()["list"]:
		if String(x["id"]) == id:
			return x
	return {}


## Pano önbelleği: köyün açık olayları değişince pano yenilenir
static func stamp(vid: String) -> int:
	return hash(open_for(vid).map(func(x): return x["id"]))


static func left_min(id: String) -> int:
	var x = find(id)
	return int(ceil(float(x.get("left", 0.0)) / 60.0)) if not x.is_empty() else 0


static func recent() -> Array:
	return D()["news"]


static func headline(text: String, col := Color(1, 0.85, 0.6)) -> void:
	var nw: Array = D()["news"]
	nw.append(text)
	while nw.size() > 6:
		nw.pop_front()
	Hud.msg("Haber: " + text, col, 6.0)


static func add(kind: String, vid: String, who := "", extra := {}) -> Dictionary:
	if Game.village(vid).is_empty() or open_for(vid).size() >= MAX_OPEN:
		return {}
	if (D()["list"] as Array).any(func(x): return String(x["kind"]) == kind and String(x["who"]) == who and String(x["state"]) != "closed"):
		return {}
	var d = D()
	d["seq"] = int(d["seq"]) + 1
	var inc = {"id": "n%d" % int(d["seq"]), "kind": kind, "vid": vid, "who": who, "left": float(LIFE.get(kind, 1200.0)), "state": "open"}
	inc.merge(extra)
	(d["list"] as Array).append(inc)
	if vid == Progress.home():
		var t = _title(inc)
		if t != "":
			Hud.msg("Görev masasına yeni ilan asıldı: %s" % t, Color(1, 0.9, 0.55), 6.0)
	return inc


# ====================================================================== dünyadan gelen olaylar (WorldPeople çağırır)
## Görevden dönmedi: hemen ölmez; bir süre kayıptır, kurtarılabilir. true: kayıp olarak işlendi
static func went_missing(p: Dictionary) -> bool:
	if int(p["rank"]) > 2 or randf() > 0.6:
		return false
	var inc = add("missing", String(p["village"]), String(p["id"]))
	if inc.is_empty():
		return false
	p["missing"] = true
	WorldPeople.log_event(p, "Bir görevden dönmedi; kayıp listesine yazıldı")
	return true


static func on_crime(p: Dictionary, idx: int, near: String, crime: String) -> void:
	if idx == 0:
		add("robbed", near, String(p["id"]), {"crime": crime})
	elif idx == 4:
		add("fire", near, String(p["id"]), {"crime": crime})


static func on_defect(p: Dictionary) -> void:
	add("deserter", String(p["village"]), String(p["id"]))


static func on_death(p: Dictionary, why: String) -> void:
	if not why.begins_with("Bir görevden dönmedi") or randf() > 0.6:
		return
	var rel = _kin(p)
	if rel.is_empty():
		return
	add("band", String(p["village"]), String(p["id"]), {"kin": String(rel[0]["id"]), "rel": String(rel[1])})


## Köyde yaşayan (ölmemiş, kaçmamış, kayıp olmayan) ilk yakını: [kişi, "eşi"/"oğlu"/...]
static func _kin(p: Dictionary) -> Array:
	for r in WorldKin.relatives(p):
		var q: Dictionary = r[0]
		if WorldPeople.alive(q) and not WorldPeople.is_rogue(q) and not q.get("missing", false):
			return r
	return []


# ====================================================================== süre + başka takım
static func tick(dt: float) -> void:
	var mine = String(Missions.active().get("news", ""))
	var lst: Array = D()["list"]
	for inc in lst:
		if String(inc["state"]) == "closed":
			continue
		if String(inc["id"]) == mine:
			inc["state"] = "mine"
			continue
		if String(inc["state"]) == "mine":
			inc["state"] = "open"   # görev bırakıldı: ilan panoya döner
		inc["left"] = float(inc["left"]) - dt
		if float(inc["left"]) <= 0.0:
			_resolve(inc)
	D()["list"] = lst.filter(func(x): return String(x["state"]) != "closed")


static func _team_text(team: Array) -> String:
	if team.is_empty():
		return "bir takım"
	return "%s takımı" % sfx(String(team[0]["name"]), "in")


static func _close(inc: Dictionary) -> void:
	inc["state"] = "closed"


## Süresi doldu: köyün başka bir takımı gider (gerçek insanlar); sonuç hayatlarına yazılır
static func _resolve(inc: Dictionary) -> void:
	_close(inc)
	var vid = String(inc["vid"])
	var p = WorldPeople.get_p(String(inc["who"]))
	var team = WorldPeople.team_people(vid, true, {})
	var vn = WorldPeople.vname(vid)
	match String(inc["kind"]):
		"missing":
			if p.is_empty() or not WorldPeople.alive(p):
				return
			p["missing"] = false
			var avg = 60.0
			if not team.is_empty():
				avg = 0.0
				for t in team:
					avg += float(t["level"]) / team.size()
			if randf() < clampf(0.35 + avg / 300.0, 0.35, 0.8):
				WorldPeople.log_event(p, "Kayıpken %s tarafından kurtarıldı" % _team_text(team))
				for t in team:
					WorldPeople.log_event(t, "Kayıp %s kurtardı" % sfx(String(p["name"]), "i"))
				headline("%s: kayıp %s %s tarafından sağ getirildi." % [vn, String(p["name"]), _team_text(team)], Color(0.7, 1.0, 0.7))
			else:
				WorldPeople._die(p, "Bir görevden dönmedi; arayan takım eli boş döndü")
				headline("%s: %s için gönderilen takım eli boş döndü. Adı anıt taşına yazıldı." % [vn, String(p["name"])], Color(1, 0.6, 0.55))
		"robbed", "fire":
			if p.is_empty() or not WorldPeople.alive(p):
				return
			var what = "soyulan kervanın mallarını geri aldı" if String(inc["kind"]) == "robbed" else "yangını söndürdü"
			if team.is_empty() or randf() < 0.7:
				for t in team:
					WorldPeople.log_event(t, "%s yakınında «%s» adlı kaçağın peşine düştü" % [vn, String(p.get("alias", p["name"]))])
				headline("%s: %s %s; «%s» izini kaybettirdi." % [vn, _team_text(team), what, String(p.get("alias", p["name"]))])
			else:
				var lost: Dictionary = team[team.size() - 1]
				WorldPeople._die(lost, "«%s» adlı kaçağın pususunda öldü" % String(p.get("alias", p["name"])))
				WorldPeople.log_event(p, "Peşine düşen %s ninjası %s öldürdü" % [vn, sfx(String(lost["name"]), "i")])
				headline("%s: «%s» peşindeki takım pusuya düştü; %s geri dönmedi." % [vn, String(p.get("alias", p["name"])), String(lost["name"])], Color(1, 0.6, 0.55))
		"deserter":
			if p.is_empty() or not WorldPeople.alive(p):
				return
			headline("%s: firari %s sınırı geçti. Artık Bingo Kitabı'nda «%s»." % [vn, String(p["name"]), String(p.get("alias", "?"))], Color(1, 0.7, 0.55))
		"band":
			var q = WorldPeople.get_p(String(inc.get("kin", "")))
			if not q.is_empty() and WorldPeople.alive(q):
				WorldPeople.log_event(q, "%s bandı hiç bulunamadı" % sfx(String(p.get("name", "Yakını")), "in"))


## Görev bitti (Missions kancası "WorldNews.mission_done")
func mission_done(m: Dictionary, ok: bool) -> void:
	var inc = find(String(m.get("news", "")))
	if inc.is_empty():
		return
	if not ok:
		inc["left"] = 0.0
		inc["state"] = "open"
		_resolve(inc)
		return
	_close(inc)
	var me = String(Game.profile.get("name", "Bir ninja"))
	var vn = WorldPeople.vname(String(inc["vid"]))
	var p = WorldPeople.get_p(String(inc["who"]))
	match String(inc["kind"]):
		"missing":
			if not p.is_empty() and WorldPeople.alive(p):
				p["missing"] = false
				p["saved_by_player"] = true
				WorldPeople.log_event(p, "Kayıpken %s tarafından kurtarıldı" % me)
				headline("%s: kayıp %s %s tarafından sağ getirildi." % [vn, String(p["name"]), me], Color(0.7, 1.0, 0.7))
		"robbed":
			headline("%s: soyulan kervanın malları %s sayesinde sahibine döndü." % [vn, me], Color(0.7, 1.0, 0.7))
		"deserter":
			headline("%s: firari %s sınırı geçemeden durduruldu." % [vn, String(p.get("name", "ninja"))], Color(0.7, 1.0, 0.7))
		"band":
			var q = WorldPeople.get_p(String(inc.get("kin", "")))
			if not q.is_empty() and WorldPeople.alive(q):
				q["grief"] = false   # yasını tutabildi: acısı köyüne öfkeye dönmez
				q["band_by_player"] = true
				WorldPeople.log_event(q, "%s alın bandı %s tarafından geri getirildi" % [sfx(String(p.get("name", "Yakını")), "in"), me])
		"fire":
			headline("%s: yangın %s sayesinde büyümeden söndürüldü." % [vn, me], Color(0.7, 1.0, 0.7))


# ====================================================================== olaydan görev
static func rank_of(inc: Dictionary) -> String:
	var p = WorldPeople.get_p(String(inc["who"]))
	match String(inc["kind"]):
		"missing":
			return RANK_OF_PERSON[clampi(int(p.get("rank", 0)), 0, 3)] if not p.is_empty() else "C"
		"robbed", "deserter":
			return WorldPeople.rank_letter(int(p.get("level", 40))) if not p.is_empty() else "B"
		"band":
			return "C"
	return "D"


static func _title(inc: Dictionary) -> String:
	var p = WorldPeople.get_p(String(inc["who"]))
	if p.is_empty():
		return ""
	match String(inc["kind"]):
		"missing":
			return "Kayıp Ninja: %s" % String(p["name"])
		"robbed":
			return "Soyulan Kervan: «%s»" % String(p.get("alias", p["name"]))
		"deserter":
			return "Firari: %s" % String(p["name"])
		"band":
			return "Son Yadigâr: %s" % String(p["name"])
		"fire":
			return "Yangın!"
	return ""


## Türkçe ek (ünlü uyumu): sfx(ad, "i") -> Riku'yu, sfx(ad, "e") -> Gaku'ya, sfx(ad, "in") -> Fuyuko'nun
static func sfx(name: String, kind: String) -> String:
	var low = name.to_lower()
	var last = ""
	for i in range(low.length() - 1, -1, -1):
		var ch = low[i]
		if ch in "aıoueiöüāīūēō":
			last = ch
			break
	var back = last in "aıouāūō"
	var rounded = last in "ouöüūō"
	var v = ("u" if rounded else "ı") if back else ("ü" if rounded else "i")
	var ends_v = low != "" and low[low.length() - 1] in "aıoueiöüāīūēō"
	match kind:
		"i":
			return "%s'%s%s" % [name, "y" if ends_v else "", v]
		"e":
			return "%s'%s%s" % [name, "y" if ends_v else "", "a" if back else "e"]
		"in":
			return "%s'%s%sn" % [name, "n" if ends_v else "", v]
	return name


static func _first(name: String) -> String:
	var parts = name.split(" ")
	return parts[parts.size() - 1]


static func _person_npc(id: String, p: Dictionary, title := "") -> Dictionary:
	return {"id": id, "name": ("%s %s" % [title, String(p["name"])]).strip_edges(), "look": (p.get("look", {}) as Dictionary).duplicate(true)}


## Olayın görevi (panoya asılır). Boş: olay artık geçersiz (kişi öldü vb.) -> kapanır
static func mission_for(inc: Dictionary) -> Dictionary:
	var vid = String(inc["vid"])
	var p = WorldPeople.get_p(String(inc["who"]))
	var M = Missions
	var q = {}
	var vn = WorldPeople.vname(vid)
	match String(inc["kind"]):
		"missing":
			if p.is_empty() or not WorldPeople.alive(p) or not p.get("missing", false):
				return {}
			var rank = rank_of(inc)
			var camp = M._spot(vid, 300, 800)
			var h = _person_npc("rehine", p)
			var rel = _kin(p)
			var kin: Dictionary
			var k1 = "Kaptan!"
			var k2 = "%s! Adını kayıp listesinden kendi elimle sileceğim. Hoş geldin." % _first(String(p["name"]))
			var who_txt = "takım lideri"
			if rel.is_empty():
				var lead = WorldPeople.all().values().filter(func(x): return String(x["village"]) == vid and WorldPeople.alive(x) and not WorldPeople.is_rogue(x) and not x.get("missing", false) and int(x["rank"]) >= 2 and String(x["id"]) != String(p["id"]))
				if lead.is_empty():
					kin = M._npc("yakin", "%s Nöbetçisi" % vn, "ninja")
					k1 = "Döndüm!"
				else:
					kin = _person_npc("yakin", lead.pick_random(), "Takım Lideri")
			else:
				var rq: Dictionary = rel[0]
				kin = _person_npc("yakin", rq)
				who_txt = String(rel[1])
				k1 = String({"oğlu": "Oğlum!", "kızı": "Kızım!", "babası": "Baba!", "annesi": "Anne!", "kardeşi": "Kardeşim!"}.get(String(rel[1]), "%s!" % _first(String(rq["name"]))))
				k2 = "%s! Döndün... Her gece kapıya baktım." % _first(String(p["name"]))
			var foe = "bandit" if rank == "C" else "rogue"
			q = {"title": _title(inc), "rank": rank,
				"brief": "%s ninjası %s görevinden dönmedi. Takımından haber yok; son işaret köyün dışından geldi. İzini sür, tutulduğu yeri bul ve onu sağ getir. Köyde %s bekliyor." % [vn, String(p["name"]), who_txt],
				"steps": [
					{"kind": "collect", "at": M._near_spot(camp, 60, 90), "item": "ipucu", "n": 3, "spread": 16, "work": "clue", "label": "[F] İzi incele", "clues": ["prints", "bandana", "ash"],
						"finds": ["Ayak izleri... birkaç kişi; biri sürüklenmiş. İzler ileride bir kampa gidiyor.", "Dala takılmış kanlı bir bez. %s yaralı ama yürütülmüş." % _first(String(p["name"])), "Sönmüş ateş, kül daha ılık. Kampları uzakta değil."],
						"text": "%s izini sür (3)." % sfx(_first(String(p["name"])), "in")},
					{"kind": "kill", "at": camp, "enemy": foe, "n": {"C": 3, "B": 4, "A": 5}.get(rank, 4), "camp": true, "hostage": h, "text": "%s tutanları yen." % sfx(_first(String(p["name"])), "i")},
					{"kind": "talk", "npc_id": "rehine", "text": "%s iplerini çöz." % sfx(_first(String(p["name"])), "in"), "say": "%s bandı... Beni aramaya mı geldin? Pusuya düştük. Takımımdan ayrı düştüm, günlerdir buradayım." % vn, "then": "follow"},
					{"kind": "talk", "at": M._inside(vid, 0.0, 0.3), "npc": kin, "followers": true, "reunion": "rehine", "reunion_say": [k1, k2], "pay": "pouch",
						"text": "%s köyde bekleyen %s ile buluştur (seni takip ediyor)." % [sfx(_first(String(p["name"])), "i"), String(kin["name"])],
						"say": "Onu bize geri getirdin. Bu köy bunu unutmaz; al, lütfen."}]}
		"robbed":
			if p.is_empty() or not WorldPeople.alive(p) or not WorldPeople.is_rogue(p):
				return {}
			var rng = RandomNumberGenerator.new()
			rng.seed = hash(String(inc["id"]))
			var mer = M._npc("tuccar", "Tüccar %s" % MissionGen._name(rng), "merchant")
			var road = M._spot(vid, 30, 110)
			var camp2 = M._near_spot(road, 350, 650)
			var alias = String(p.get("alias", p["name"]))
			q = {"title": _title(inc), "rank": rank_of(inc),
				"brief": "Bingo Kitabı'ndaki «%s» (%s) %s yolunda bir kervanı soydu. Tüccar yol kenarında boş arabasının başında bekliyor. İzleri sür, kaçağın kampını bul, malları geri getir." % [alias, String(p["name"]), vn],
				"steps": [
					{"kind": "talk", "at": road, "npc": mer, "cart": true, "text": "Soyulan tüccarla konuş.", "say": "Tek kişiydi! Alnındaki bandın üstü çizikti. Adamlarım daha kılıç çekemeden yere serildi, malların hepsini götürdü. Şu yöne gitti."},
					{"kind": "collect", "at": M._near_spot(camp2, 60, 90), "item": "ipucu", "n": 3, "spread": 16, "work": "clue", "label": "[F] İzi incele", "clues": ["prints", "bag", "ash"],
						"finds": ["Tek kişinin izi; yükü ağır, adımları derin.", "Kervandan düşmüş yırtık bir çanta. Değerli ne varsa alınmış.", "Sönmüş ateş. «%s» burada mola vermiş; kampı yakında." % alias], "text": "Kaçağın izini sür (3)."},
					{"kind": "kill", "at": camp2, "enemy": "rogue", "n": 1, "camp": true, "boss": {"name": "%s «%s»" % [String(p["name"]), alias], "person": String(p["id"])}, "text": "«%s» lakaplı kaçağı durdur." % alias},
					{"kind": "collect", "at": camp2, "item": "ganimet", "n": 1, "spread": 4, "work": "sack", "label": "[F] Çalınan malları omuzla", "text": "Çalınan malları al (1)."},
					{"kind": "talk", "npc_id": "tuccar", "give": "sack", "pay": "pouch", "text": "Malları tüccara geri götür.", "say": "Mallarım! Hepsi burada... Yollar senin gibiler sayesinde açık kalıyor. Al, bunu hak ettin."}]}
		"deserter":
			if p.is_empty() or not WorldPeople.alive(p) or not WorldPeople.is_rogue(p):
				return {}
			var start = M._spot(vid, 20, 80)
			var hide = M._near_spot(start, 450, 800)
			var scout = M._npc("izci", "İzci Ninja", "ninja")
			var why = String((p.get("crimes", ["Köyünden kaçtı"]) as Array)[0])
			q = {"title": _title(inc), "rank": rank_of(inc),
				"brief": "%s dün gece %s köyünden kaçtı. Sebep: %s. Sınırı geçerse köyün sırları da onunla gider. Ninken izi buldu; sınırı geçmeden yetiş." % [String(p["name"]), vn, why.to_lower()],
				"steps": [
					{"kind": "talk", "at": start, "npc": scout, "text": "Kapı dışındaki izciyle buluş.", "say": "%s tanırdım. Aynı masada yemek yedik... Köpeğim kokusunu aldı. Sen önden git; ben Kage'ye haber vereceğim." % sfx(_first(String(p["name"])), "i")},
					{"kind": "track", "from": start, "to": hide, "text": "Firarinin izini takip et."},
					{"kind": "kill", "at": hide, "enemy": "rogue", "n": 1, "boss": {"name": String(p["name"]), "person": String(p["id"])}, "text": "%s durdur." % sfx(String(p["name"]), "i")},
					{"kind": "goto", "at": M._inside(vid, 0.0, 0.2), "r": 18.0, "name": "Köy", "text": "Köye dön ve rapor ver."}]}
		"band":
			var kq = WorldPeople.get_p(String(inc.get("kin", "")))
			if p.is_empty() or kq.is_empty() or not WorldPeople.alive(kq) or WorldPeople.is_rogue(kq):
				return {}
			var site = M._spot(vid, 400, 900)
			var rel2 = String(inc.get("rel", "yakını"))
			var kin2 = _person_npc("yakin", kq)
			q = {"title": _title(inc), "rank": "C",
				"brief": "%s görevden dönmedi; adı anıt taşına yazıldı. %s %s, mezarına koyacak bir şey istiyor: düştüğü yerde kalan alın bandını. Bölgede leş yağmacıları dolaşıyor." % [String(p["name"]), rel2.capitalize(), String(kq["name"])],
				"steps": [
					{"kind": "collect", "at": site, "item": "alın bandı", "n": 1, "spread": 5, "guard": {"enemy": "bandit", "n": 2, "ename": "Leş Yağmacısı"}, "text": "%s düştüğü yerde alın bandını bul (1)." % sfx(_first(String(p["name"])), "in")},
					{"kind": "talk", "at": M._inside(vid, 0.1, 0.45), "npc": kin2, "busy": "fret", "give": "band", "text": "Bandı %s elden ver." % sfx(String(kq["name"]), "e"),
						"say": "Bu... onun bandı. Çizik bile yok üstünde; sonuna kadar köyü için dövüşmüş. Teşekkür ederim. Artık onu uğurlayabilirim."}]}
		"fire":
			var house = M._inside(vid, 0.2, 0.6)
			var owner = M._npc("evsahibi", "Ev Sahibi", "civ")
			owner["look"]["gender"] = "f"
			var kid = M._npc("icerdeki", "İçeride Kalan Çocuk", "kid")
			q = {"title": "Yangın!", "rank": "D",
				"brief": "%s'de bir ev alev aldı! Kundakçı kaçtı ama ev hâlâ yanıyor ve içeride biri kalmış. Kuyudan su taşı, alevleri söndür, içeridekini çıkar." % vn,
				"steps": [
					{"kind": "points", "at": house, "n": 4, "spread": 3, "label": "[F] Su taşı ve alevi söndür", "work": "douse", "text": "Kuyudan su taşıyıp alevleri söndür (4)."},
					{"kind": "talk", "at": house, "npc": kid, "text": "İçeride kalan çocuğu çıkar.", "say": "Öhö, öhö... Kapı açılmadı, çok korktum!", "then": "follow"},
					{"kind": "talk", "at": house, "npc": owner, "followers": true, "reunion": "icerdeki", "reunion_say": ["Anne!", "Yavrum! Sağsın, sağsın..."], "pay": "pouch", "text": "Çocuğu annesine götür.", "say": "Evim yandı ama çocuğum sağ. Bunun karşılığı olmaz; yine de al."}]}
	if q.is_empty():
		return {}
	q["village"] = vid
	q["type"] = "quest"
	q["giver"] = "%s Görev Masası" % vn
	q["news"] = String(inc["id"])
	q["dyn"] = true
	q["hook"] = "WorldNews.mission_done"
	return q
