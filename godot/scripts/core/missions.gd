extends Node
## Görev sistemi (autoload "Missions"). Rank: D C B A S.
## Görevler çok adımlıdır: her adımın türü (goto, talk, kill, collect, escort, stealth, chase, defend, track, points, babysit, cat, boss),
## kendi hedef işareti (pusula/ışık sütunu/mini harita) ve metni vardır. Konumlar procedural: görev masasının köyü çevresinden seçilir.
## Ayrıca Bingo Kitabı (Aranıyor listesi): ödüllü kaçak ninjalar, saklandıkları bölge, muhbirler.

const REWARD := {"D": [80, 110], "C": [240, 260], "B": [600, 380], "A": [1600, 900], "S": [6000, 2500]}
const RANK_FOR := {0: ["D"], 1: ["D", "C"], 2: ["C", "B"], 3: ["B", "A", "S"], 4: ["A", "S"], 5: ["A", "S"], 6: ["A", "S"]}
const RANK_IDX := {"D": 0, "C": 1, "B": 2, "A": 3, "S": 4}
const REP_GAIN := {"D": 2, "C": 5, "B": 10, "A": 20, "S": 40}
const GEAR_CHANCE := {"D": 0.15, "C": 0.35, "B": 0.6, "A": 0.9, "S": 1.0}

var board: Array = []
var board_village = ""
var pickups: Array = []       # görev boyunca yaşayan düğümler
var step_nodes: Array = []    # yalnız bu adımın düğümleri
var npcs := {}                # görev NPC'leri: id -> QuestNPC
var st := {}                  # adımın çalışma durumu (sayaçlar)
var target_marker = Vector3.ZERO
var has_marker = false
var target_name = ""          # hedef okunun yanında yazan isim
var story_target = false      # hedef görevden değil hikâye adımından geliyor

## Hikâye adımı -> hedef: [etkileşim türü | "village" | "story_camp", "", gösterilen isim]
const STORY_TARGETS := {
	0: ["academy", "", "Ninja Akademisi"], 1: ["academy", "", "Akademi Avlusu"], 2: ["academy", "", "Akademi Hocası"],
	3: ["academy", "", "Akademi Avlusu"], 4: ["lookout", "", "Gözetleme Yeri (tırman)"], 5: ["training", "", "Antrenman Alanı"],
	6: ["mission_board", "", "Görev Masası"], 7: ["mission_board", "", "Kage Kulesi"], 8: ["story_camp", "", "Haydut Kampı"],
	9: ["chunin_exam", "", "Stadyum — Chunin Sınavı"], 10: ["chunin_exam", "", "Chunin Sınavı"], 11: ["sage", "", "Gizli Şelale"],
	12: ["mission_board", "", "Görev Masası (A-rank)"], 13: ["anbu", "", "ANBU Karargâhı"],
}
var _story_cache := {}


func active() -> Dictionary:
	return Game.profile.get("active_mission", {})


func _vpos(id: String, dx := 0.0, dy := 0.0) -> Vector3:
	var v = Game.village(id)
	return Game.from_map(Vector2(float(v["x"]) + dx, float(v["y"]) + dy))


## [x, y] harita noktası -> dünya
func _w(p) -> Vector3:
	return Game.from_map(Vector2(float(p[0]), float(p[1])))


static func _hex(c: Color) -> String:
	return c.to_html(false)


# ------------------------------------------------------------------ konum seçimi
## Köyün dışında karada, başka köyün içinde olmayan rastgele bir nokta (harita [x, y])
func _spot(vid: String, dmin: float, dmax: float) -> Array:
	var v = Game.village(vid)
	if v.is_empty():
		v = Game.village("konoha")
	var c = Vector2(float(v["x"]), float(v["y"]))
	var r = float(v.get("r", 200))
	var wr: Vector4 = Game.world_rect()
	for i in 30:
		var a = randf() * TAU
		var q = c + Vector2(cos(a), sin(a)) * (r + randf_range(dmin, dmax))
		if q.x < wr.x + 50 or q.x > wr.x + wr.z - 50 or -q.y < wr.y + 50 or -q.y > wr.y + wr.w - 50:
			continue
		if Game.terrain_height(q.x, -q.y) < 0.8:
			continue
		var bad = false
		for o in Game.world_info["villages"]:
			if q.distance_to(Vector2(o["x"], o["y"])) < float(o["r"]) * 1.1:
				bad = true
		if not bad:
			return [q.x, q.y]
	return [c.x + r + dmin, c.y]


## Köy içinde (sokakta) bir nokta
func _inside(vid: String, frac_min := 0.25, frac_max := 0.7) -> Array:
	var v = Game.village(vid)
	var c = Vector2(float(v["x"]), float(v["y"]))
	var r = float(v.get("r", 200))
	var a = randf() * TAU
	var d = r * randf_range(frac_min, frac_max)
	return [c.x + cos(a) * d, c.y + sin(a) * d]


## Dünyada adı belli türden bir yer (hamlet, camp, inn, ruin ...) — yoksa null
func _poi(words: Array, near: Array, maxd: float):
	var best = null
	var bd = maxd
	var c = Vector2(near[0], near[1])
	for l in Game.world_info.get("landmarks", []):
		var id = String(l.get("id", "")) + " " + String(l.get("type", ""))
		var ok = false
		for w in words:
			if id.contains(w):
				ok = true
		if not ok:
			continue
		var d = c.distance_to(Vector2(l["x"], l["y"]))
		if d < bd:
			bd = d
			best = [float(l["x"]) + randf_range(-10, 10), float(l["y"]) + randf_range(-10, 10)]
	return best


func _near_spot(p: Array, dmin: float, dmax: float) -> Array:
	for i in 20:
		var a = randf() * TAU
		var d = randf_range(dmin, dmax)
		var q = [p[0] + cos(a) * d, p[1] + sin(a) * d]
		if Game.terrain_height(q[0], -q[1]) > 0.5:
			return q
	return [p[0] + dmin, p[1]]


# ------------------------------------------------------------------ görev şablonları
func _npc(id: String, name: String, kind := "civ") -> Dictionary:
	var tops = [Color(0.6, 0.45, 0.3), Color(0.5, 0.6, 0.45), Color(0.45, 0.4, 0.6), Color(0.7, 0.55, 0.4), Color(0.6, 0.35, 0.35)]
	var t: Color = tops.pick_random()
	var lk = {"gender": ["m", "f"].pick_random(), "top": _hex(t), "top2": _hex(t.darkened(0.15)), "pants": _hex(Color(0.32, 0.28, 0.25)),
		"pants_style": "sivil", "hair_style": ["kısa", "uzun", "kase", "atkuyruğu"].pick_random(),
		"hair": _hex([Color(0.1, 0.08, 0.06), Color(0.35, 0.22, 0.12), Color(0.6, 0.6, 0.62)].pick_random()), "age": "adult"}
	match kind:
		"merchant":
			lk.merge({"top": _hex(Color(0.55, 0.42, 0.25)), "top_style": "uzun", "beard": true, "gender": "m"}, true)
		"elder":
			lk.merge({"hair": _hex(Color(0.85, 0.85, 0.85)), "face_mark": "kırışık"}, true)
		"kid":
			lk["age"] = "child"
		"ninja":
			lk.merge({"top": _hex(Color(0.18, 0.22, 0.3)), "top2": _hex(Color(0.18, 0.22, 0.3)), "pants": _hex(Color(0.18, 0.22, 0.3)),
				"pants_style": "ninja", "vest": _hex(Color(0.38, 0.48, 0.28)), "band": _hex(Color(0.15, 0.22, 0.55))}, true)
		"vip":
			lk.merge({"top": _hex(Color(0.55, 0.12, 0.15)), "top2": _hex(Color(0.85, 0.7, 0.3)), "top_style": "uzun", "pants": _hex(Color(0.2, 0.15, 0.2))}, true)
		"hostage":
			lk.merge({"top": _hex(Color(0.75, 0.72, 0.65))}, true)
	return {"id": id, "name": name, "look": lk}


func _templates(rank: String, here: String) -> Array:
	var t: Array = []
	var vn: String = Game.village(here)["name"]
	var kage = Progress.kage_title(here)
	match rank:
		"D":
			t.append(_q_cat(here))
			t.append(_q_weeds(here))
			t.append(_q_fence(here))
			t.append(_q_babysit(here))
			t.append(_q_herbs(here, false))
		"C":
			t.append(_q_escort(here, "C"))
			t.append(_q_investigate(here))
			t.append(_q_herbs(here, true))
			t.append(_q_track(here, "C"))
			t.append(_q_border(here))
		"B":
			t.append(_q_stealth(here))
			t.append(_q_chase(here))
			t.append(_q_defend(here, "B"))
			t.append(_q_rescue(here))
			t.append(_q_sabotage(here))
		"A":
			t.append(_q_track(here, "A"))
			t.append(_q_escort(here, "A"))
			t.append(_q_defend(here, "A"))
		"S":
			t.append({"title": "Fırtınanın Kalbi: Raijū", "giver": kage, "brief": "Yıldırım Ülkesi'ndeki Fırtına Kanyonu'nda dev bir canavar uyandı. Yen ve mühürle!",
				"steps": [{"kind": "boss", "boss": "raiju", "near": "storm_canyon", "text": "Fırtına Kanyonu'na git ve Raijū'yu yen."}]})
			t.append({"title": "Kuklacı Mukuro", "giver": kage, "brief": "Rüzgar Ülkesi'nde köyleri yağmalayan efsanevi kuklacı. Onu durdur.",
				"steps": [{"kind": "boss", "boss": "puppeteer", "near": "suna", "text": "Rüzgar Ülkesi'ne git ve kuklacıyı yen."}]})
	var out = []
	for x in t:
		if x.is_empty():
			continue
		x["rank"] = rank
		x["village"] = here
		x["type"] = "quest"
		if not x.has("giver"):
			x["giver"] = "%s Görev Masası" % vn
		out.append(x)
	return out


func _q_cat(here: String) -> Dictionary:
	return {"title": "Kayıp Kedi Mikan", "brief": "Daimyo'nun eşinin kedisi Mikan yine kaçtı! Köyde bul ve yakala. Dikkat: tırmalar.",
		"steps": [{"kind": "cat", "village": here, "text": "Kedi Mikan'ı bul ve yakala [F]."}]}


func _q_weeds(here: String) -> Dictionary:
	var farm = _poi(["paddy", "farm", "hamlet"], _inside(here), 700.0)
	if farm == null:
		farm = _spot(here, 30, 120)
	var n = _npc("ciftci", "Çiftçi Tagosaku", "elder")
	return {"title": "Tarla Temizliği", "brief": "Yaşlı çiftçinin tarlasını yabani otlar bastı. Belinden şikâyetçi; yardım et.",
		"steps": [
			{"kind": "talk", "at": farm, "npc": n, "text": "Çiftçi Tagosaku ile konuş.", "say": "Ahh belim... Şu otlar her yeri sardı. 8 tanesini kökünden sök, sana dango ısmarlarım!"},
			{"kind": "collect", "at": farm, "item": "yabani ot", "n": 8, "spread": 18, "text": "Tarladaki yabani otları sök (8)."},
			{"kind": "talk", "npc_id": "ciftci", "text": "Çiftçiye dön.", "say": "Vay be, ninja dediğin böyle olur! Al bakalım, emeğinin karşılığı."}]}


func _q_fence(here: String) -> Dictionary:
	var at = _inside(here, 0.3, 0.75)
	var n = _npc("teyze", "Hana Teyze", "elder")
	n["look"]["gender"] = "f"
	return {"title": "Çit Boyama", "brief": "Hana Teyze'nin bahçe çiti boyanacak. Ninja işi değil mi? Değil. Ama görev görevdir.",
		"steps": [
			{"kind": "talk", "at": at, "npc": n, "text": "Hana Teyze ile konuş.", "say": "Sen mi geldin? Çok küçüksün ama neyse... Çitin altı tahtası boyanacak, damlatmadan!"},
			{"kind": "points", "at": at, "n": 6, "spread": 9, "label": "[F] Çit tahtasını boya", "fx": "paint", "text": "Çit tahtalarını boya (6)."},
			{"kind": "talk", "npc_id": "teyze", "text": "Hana Teyze'ye göster.", "say": "Hmm... Şurası biraz eğri ama idare eder. Al bu da senin, aferin evladım."}]}


func _q_babysit(here: String) -> Dictionary:
	var at = _inside(here, 0.2, 0.6)
	var mom = _npc("anne", "Endişeli Anne Sayo", "civ")
	mom["look"]["gender"] = "f"
	var kid = _npc("cocuk", "Küçük Tetsu", "kid")
	return {"title": "Bebek Bakıcılığı", "brief": "Pazara giden annenin yaramaz oğluna göz kulak ol. Kolay mı? Göreceğiz.",
		"steps": [
			{"kind": "talk", "at": at, "npc": mom, "text": "Sayo ile konuş.", "say": "Çok teşekkürler! Tetsu çok hareketlidir, 45 saniye gözünü ayırma. Hemen dönerim!"},
			{"kind": "babysit", "at": at, "npc": kid, "time": 45.0, "text": "Küçük Tetsu'yu gözden kaçırma (yakınında kal)."},
			{"kind": "talk", "npc_id": "anne", "text": "Sayo'ya çocuğu teslim et.", "say": "Tetsu, ninjayı yordun mu yine? Sağ ol, al bu senin."}]}


func _q_herbs(here: String, dangerous: bool) -> Dictionary:
	var area = _spot(here, 200 if dangerous else 80, 650 if dangerous else 300)
	var hosp = _inside(here, 0.05, 0.3)
	var s = [{"kind": "goto", "at": area, "r": 25.0, "name": "Şifalı Ot Vadisi" if dangerous else "Orman Kenarı", "text": "Şifalı otların yetiştiği yere git."},
		{"kind": "collect", "at": area, "item": "herb", "n": 6, "spread": 35, "text": "Şifalı ot topla (6).", "guard": {"enemy": "bandit", "n": 3} if dangerous else {}},
		{"kind": "goto", "at": hosp, "r": 14.0, "name": "Hastane", "text": "Otları köydeki hastaneye teslim et."}]
	return {"title": "Tehlikeli Vadide Şifalı Ot" if dangerous else "Şifalı Ot Toplama",
		"brief": ("Kaçak avcıların cirit attığı vadiden zehir panzehiri için ot lazım." if dangerous else "Hastane için ormandan şifalı ot topla."), "steps": s}


func _q_escort(here: String, rank: String) -> Dictionary:
	var vip = rank == "A"
	var start = _spot(here, 10, 40)
	var dest = _poi(["hamlet", "inn", "town", "settlement"], start, 2500.0)
	if dest == null or Vector2(dest[0], dest[1]).distance_to(Vector2(start[0], start[1])) < 250:
		dest = _near_spot(start, 450 if not vip else 800, 800 if not vip else 1300)
	var n = _npc("eskort", "Daimyo Elçisi Kanemori" if vip else "Tüccar Gonzō", "vip" if vip else "merchant")
	var amb = [[0.35, "bandit", 3], [0.75, "bandit", 3]]
	if vip:
		amb = [[0.25, "rogue", 3], [0.55, ["kiri", "iwa", "kumo"].pick_random(), 2], [0.85, "samurai", 2]]
	return {"title": "Elçiye Koruma" if vip else "Tüccar Kervanı Eskortu",
		"brief": ("Daimyo'nun elçisini güvenle karşı köye ulaştır. Kiralık suikastçılar peşinde." if vip else "Tüccar Gonzō malıyla birlikte yola çıkacak. Yolda haydut pususu bekleniyor."),
		"steps": [
			{"kind": "talk", "at": start, "npc": n, "text": "%s ile buluş." % n["name"], "say": ("Bu belgeler hayati önemde. Ben yürürüm, sen etrafı kolla. Benden 15 metreden uzaklaşma!" if vip else "Ah, ninja geldi! Yollar artık güvenli değil. Sen önden bak, ben arabamla gelirim.")},
			{"kind": "escort", "npc_id": "eskort", "from": start, "to": dest, "ambush": amb, "text": "%s'i hedefe kadar koru." % n["name"]},
			{"kind": "talk", "npc_id": "eskort", "text": "Teslimi tamamla.", "say": "Sağ salim vardık! Bu yolculuğu unutmayacağım. Ücretini köyüne bildireceğim."}]}


func _q_investigate(here: String) -> Dictionary:
	var victim = _npc("magdur", "Dükkân Sahibi Jubei", "merchant")
	var w1 = _npc("tanik1", "Fırıncı Oharu", "civ")
	w1["look"]["gender"] = "f"
	var w2 = _npc("tanik2", "Bekçi Daisuke", "civ")
	var camp = _spot(here, 120, 500)
	var culprits = [["Sınır dışından gelen haydutlar", true], ["Geceleri çalışan fırıncı", false], ["Köyün bekçisi", false]]
	culprits.shuffle()
	var choices = []
	for c in culprits:
		choices.append({"label": c[0], "ok": c[1], "reply": "Çamurlu sandal izleri ve kamp ateşi kokusu... Mantıklı! Kamplarına baskın yap." if c[1] else "Hmm, ipuçları buna uymuyor ama... madem öyle diyorsun. (Yanlış şüphe!)"})
	return {"title": "Pazar Hırsızlıkları", "brief": "Son haftalarda pazardaki dükkânlar geceleri soyuluyor. Tanıkları dinle, ipuçlarını topla, suçluyu bul.",
		"steps": [
			{"kind": "talk", "at": _inside(here, 0.15, 0.5), "npc": victim, "text": "Dükkân sahibi Jubei ile konuş.", "say": "Üçüncü kez! Kasamı boşalttılar. Fırıncı Oharu gece bir şey görmüş, bekçi Daisuke de devriyedeydi."},
			{"kind": "talk", "at": _inside(here, 0.2, 0.6), "npc": w1, "text": "Tanık: Fırıncı Oharu.", "say": "Gece hamur yoğururken üç gölge gördüm. Kokuları... duman ve at gübresi gibiydi. Köyün dışına doğru koştular."},
			{"kind": "talk", "at": _inside(here, 0.2, 0.6), "npc": w2, "text": "Tanık: Bekçi Daisuke.", "say": "O gece güney yolunda çamurlu ayak izleri vardı, köyden çıkıyordu. Peşlerine düşemedim, yalnızdım."},
			{"kind": "collect", "at": _near_spot(camp, 60, 90), "item": "ipucu", "n": 3, "spread": 25, "text": "Köy dışındaki izlerde ipucu ara (3)."},
			{"kind": "talk", "npc_id": "magdur", "text": "Jubei'ye bulduklarını anlat.", "say": "Çamurlu sandal izi, yanmış odun, yırtık bir haydut bandanası... Sence suçlu kim?", "choices": choices},
			{"kind": "kill", "at": camp, "enemy": "bandit", "n": 4, "camp": true, "text": "Haydut kampına baskın yap (4)."},
			{"kind": "talk", "npc_id": "magdur", "text": "Çalınan malları Jubei'ye geri götür.", "say": "Paralarım! Sen gerçek bir dedektif-ninjasın. Al, bunu hak ettin."}]}


func _q_track(here: String, rank: String) -> Dictionary:
	var hunt = rank == "A"
	var start = _spot(here, 20, 80)
	var hide = _near_spot(start, 380 if not hunt else 700, 600 if not hunt else 1100)
	var n = _npc("izci", "İzci Ninja Kobu", "ninja")
	var boss = {}
	var name = ""
	if hunt:
		name = ["Kurogiri", "Hisame", "Garyu", "Akagane"].pick_random()
		boss = {"name": "Kaçak Jonin %s" % name, "hp": 900.0, "level": 30, "power": 2.6, "flee": true}
	return {"title": "Kaçak Jonin Avı: %s" % name if hunt else "Ninken ile İz Sürme",
		"brief": ("Köyün sırlarını satıp kaçan bir Jonin sınırda görüldü. İz sür ve onu durdur. Yakalanmamak için her şeyi yapar." if hunt else "Kaçak ninjalar bir çiftliği basmış. Ninken izcisiyle izlerini takip et."),
		"steps": [
			{"kind": "talk", "at": start, "npc": n, "text": "İzci Kobu ile buluş.", "say": "Köpeklerim kokuyu aldı. İzler toprağa basılmış, parlayan pati işaretlerini takip et. Ben arkadan gelirim."},
			{"kind": "track", "from": start, "to": hide, "text": "Ayak izlerini takip et."},
			{"kind": "kill", "at": hide, "enemy": "rogue", "n": 3 if hunt else 2, "camp": true, "boss": boss, "text": ("%s'i yen!" % boss["name"]) if hunt else "Kaçak ninjaları yen."},
			{"kind": "goto", "at": _inside(here, 0.0, 0.2), "r": 18.0, "name": "Köy", "text": "Köye dön ve rapor ver."}]}


func _q_border(here: String) -> Dictionary:
	var others = ["konoha", "suna", "kiri", "kumo", "iwa", "ame", "kusa", "taki"].filter(func(x): return x != here and not Game.village(x).is_empty())
	var to: String = others.pick_random()
	var a = Vector2(Game.village(here)["x"], Game.village(here)["y"])
	var b = Vector2(Game.village(to)["x"], Game.village(to)["y"])
	var mid = a.lerp(b, 0.45)
	var cp = _near_spot([mid.x, mid.y], 0, 40)
	var g = _npc("nobetci", "Sınır Nöbetçisi", "ninja")
	var pw = [["Kızıl ay ağaçları yakmaz", true], ["Rüzgar kumları taşır", false], ["Su taşı deler", false]]
	pw.shuffle()
	var choices = []
	for p in pw:
		choices.append({"label": "\"%s\"" % p[0], "ok": p[1], "reply": "Doğru parola. Geçebilirsin, yolun açık olsun." if p[1] else "YANLIŞ! Casus! Yakalayın onu!", "wrong": "ambush"})
	return {"title": "Gizli Mektup: %s" % Game.village(to)["name"], "brief": "Mühürlü mektubu %s'e ulaştır. Sınır karakolunda parola sorulacak: 'Kızıl ay ağaçları yakmaz'. Unutma!" % Game.village(to)["name"],
		"steps": [
			{"kind": "talk", "at": cp, "npc": g, "text": "Sınır karakoluna git, parolayı söyle.", "say": "Dur! Parola?", "choices": choices},
			{"kind": "goto", "at": [b.x, b.y], "r": float(Game.village(to)["r"]) * 0.5, "name": Game.village(to)["name"], "text": "Mektubu %s'e ulaştır." % Game.village(to)["name"]}]}


func _q_stealth(here: String) -> Dictionary:
	var camp = _spot(here, 250, 700)
	return {"title": "Gece Sızması", "brief": "Kaçakçılar köyden çalınan şifre kitabını kamplarında saklıyor. Gece sız, kitabı al. Fark edilirsen alarm çalar!",
		"steps": [
			{"kind": "goto", "at": _near_spot(camp, 70, 90), "r": 10.0, "name": "Kamp Yakını", "night": true, "text": "Gece olunca kampın yakınına git."},
			{"kind": "stealth", "at": camp, "enemy": "rogue", "n": 4, "text": "Fark edilmeden şifre kitabını al [F] (kırmızı görüş alanlarından uzak dur)."},
			{"kind": "goto", "at": _inside(here, 0.0, 0.25), "r": 18.0, "name": "Köy", "text": "Kitapla köye dön."}]}


func _q_chase(here: String) -> Dictionary:
	var market = _inside(here, 0.15, 0.55)
	return {"title": "Çalınan Parşömen", "brief": "Pazarda bir hırsız tapınaktan çalınan mühür parşömenini kaçırıyor! Kaçmadan yakala.",
		"steps": [
			{"kind": "goto", "at": market, "r": 10.0, "name": "Pazar", "text": "Pazara git."},
			{"kind": "chase", "at": market, "time": 75.0, "text": "Hırsızı yakala! (yakına gel / vur)"},
			{"kind": "goto", "at": _inside(here, 0.0, 0.25), "r": 18.0, "name": "Tapınak", "text": "Parşömeni tapınağa geri götür."}]}


func _q_defend(here: String, rank: String) -> Dictionary:
	var a = rank == "A"
	var spot = _poi(["hamlet", "farm", "border", "outpost"], _inside(here), 1500.0)
	if spot == null:
		spot = _spot(here, 200, 600)
	var e = _npc("muhtar", "Köy Muhtarı Genzo" if not a else "Karakol Komutanı Iwao", "elder" if not a else "ninja")
	var enemy = "bandit" if not a else ["kiri", "iwa", "kumo", "suna"].filter(func(x): return x != here).pick_random()
	return {"title": "Sınır Karakolu Savunması" if a else "Köy Savunması",
		"brief": ("Düşman köyün öncü birlikleri karakola saldıracak. Dalgaları geri püskürt, komutanlarını yen." if a else "Bir haydut çetesi küçük bir köyü yağmalamak üzere. Köylüleri koru!"),
		"steps": [
			{"kind": "talk", "at": spot, "npc": e, "text": "%s ile konuş." % e["name"], "say": ("Gözcülerimiz üç birlik gördü. Hazırlan, geliyorlar!" if a else "Ninja! Tanrılara şükür. Haydutlar gün batmadan saldıracak, lütfen bize yardım et!")},
			{"kind": "defend", "at": spot, "enemy": enemy, "waves": [3, 4, 4] if a else [3, 3, 4], "text": "Saldırı dalgalarını püskürt."},
			{"kind": "talk", "npc_id": "muhtar", "text": "%s ile konuş." % e["name"], "say": "Başardın! Bu köy sana minnettar. Hikâyeni çocuklarımıza anlatacağız."}]}


func _q_rescue(here: String) -> Dictionary:
	var camp = _spot(here, 250, 700)
	var h = _npc("rehine", "Kaçırılan Tüccar Kızı Ume", "hostage")
	h["look"]["gender"] = "f"
	return {"title": "Rehine Kurtarma", "brief": "Bir tüccarın kızı fidye için kaçırıldı. Kampı bul, muhafızları etkisiz hale getir ve kızı sağ salim köye getir.",
		"steps": [
			{"kind": "kill", "at": camp, "enemy": "bandit", "n": 5, "camp": true, "night": true, "hostage": h, "text": "Kamptaki muhafızları yen (5)."},
			{"kind": "talk", "npc_id": "rehine", "text": "Rehineyi çöz.", "say": "Kurtarıcım! Bacağım uyuştu ama yürüyebilirim, beni buradan çıkar!", "then": "follow"},
			{"kind": "goto", "at": _inside(here, 0.0, 0.3), "r": 20.0, "followers": true, "name": "Köy", "text": "Ume'yi köye getir (seni takip ediyor)."}]}


func _q_sabotage(here: String) -> Dictionary:
	var camp = _spot(here, 300, 750)
	var safe = _near_spot(camp, 70, 90)
	return {"title": "İkmal Sabotajı", "brief": "Düşman casusların ikmal kampındaki sandıklara patlayıcı mühür yerleştir, uzaklaş ve ateşle.",
		"steps": [
			{"kind": "points", "at": camp, "n": 4, "spread": 14, "label": "[F] Patlayıcı mühür yerleştir", "fx": "tag", "camp": true, "guards": {"enemy": "rogue", "n": 3}, "text": "Sandıklara patlayıcı mühür yerleştir (4)."},
			{"kind": "goto", "at": safe, "r": 10.0, "name": "Güvenli Mesafe", "boom": camp, "text": "Güvenli mesafeye çekil ve mühürleri ateşle!"},
			{"kind": "goto", "at": _inside(here, 0.0, 0.25), "r": 18.0, "name": "Köy", "text": "Köye dön ve rapor ver."}]}


# ------------------------------------------------------------------ köye özgü görevler (MissionLocal.POOL)
func _from_spec(here: String, sp: Dictionary) -> Dictionary:
	var r: String = sp["r"]
	var e: String = sp.get("e", "bandit")
	var en: String = sp.get("en", "")
	var giver = _npc("veren", sp.get("g", "Köylü"), "elder" if r == "D" else "civ")
	var steps = []
	match sp["p"]:
		"escort":
			var start = _spot(here, 10, 40)
			var dest = _poi(["hamlet", "inn", "town", "oasis", "harbor", "port"], start, 2500.0)
			if dest == null or Vector2(dest[0], dest[1]).distance_to(Vector2(start[0], start[1])) < 250:
				dest = _near_spot(start, 450, 900)
			var n = _npc("eskort", sp["npc"], "merchant")
			var amb = [[0.35, e, 3, en], [0.75, e, 3, en]]
			if r in ["A", "S"]:
				amb.append([0.9, e, 3, en])
			steps = [{"kind": "talk", "at": start, "npc": n, "text": "%s ile buluş." % sp["npc"], "say": sp.get("s1", "")},
				{"kind": "escort", "npc_id": "eskort", "from": start, "to": dest, "ambush": amb, "text": "%s'i hedefe kadar koru." % sp["npc"]},
				{"kind": "talk", "npc_id": "eskort", "text": "Teslimi tamamla.", "say": sp.get("s2", "")}]
		"camp":
			var at = _inside(here, 0.2, 0.6)
			var camp = _spot(here, 200, 700)
			var boss = {}
			if sp.has("boss"):
				boss = {"name": sp["boss"], "hp": 500.0 + RANK_IDX[r] * 250.0, "level": 8 + RANK_IDX[r] * 8, "power": 1.6 + RANK_IDX[r] * 0.3, "flee": r in ["A", "S"]}
			steps = [{"kind": "talk", "at": at, "npc": giver, "text": "%s ile konuş." % giver["name"], "say": sp.get("s1", "")},
				{"kind": "kill", "at": camp, "enemy": e, "ename": en, "n": int(sp.get("n", 4)) + (1 if not boss.is_empty() else 0), "camp": true, "boss": boss, "text": "%s kampını dağıt." % (en if en != "" else "Düşman")},
				{"kind": "talk", "npc_id": "veren", "text": "%s'e dön." % giver["name"], "say": sp.get("s2", "")}]
		"collect":
			var area = _spot(here, 120, 600)
			var g = {"enemy": sp["ge"], "n": int(sp.get("gn", 2)), "ename": en} if sp.has("ge") else {}
			steps = [{"kind": "talk", "at": _inside(here, 0.2, 0.6), "npc": giver, "text": "%s ile konuş." % giver["name"], "say": sp.get("s1", "")},
				{"kind": "collect", "at": area, "item": sp["item"], "n": int(sp["n"]), "spread": 30, "guard": g, "text": "%s topla (%d)." % [String(sp["item"]).capitalize(), int(sp["n"])]},
				{"kind": "talk", "npc_id": "veren", "text": "%s'e götür." % giver["name"], "say": sp.get("s2", "")}]
		"defend":
			var spot = _poi(["hamlet", "farm", "oasis", "harbor", "fortress", "outpost"], _inside(here), 1500.0)
			if spot == null:
				spot = _spot(here, 150, 600)
			steps = [{"kind": "talk", "at": spot, "npc": giver, "text": "%s ile konuş." % giver["name"], "say": sp.get("s1", "")},
				{"kind": "defend", "at": spot, "enemy": e, "ename": en, "waves": sp.get("w", [3, 3]), "text": "Saldırıları püskürt."},
				{"kind": "talk", "npc_id": "veren", "text": "%s ile konuş." % giver["name"], "say": sp.get("s2", "")}]
		"rescue":
			var camp = _spot(here, 200, 650)
			var h = _npc("rehine", sp["hostage"], "hostage")
			steps = [{"kind": "kill", "at": camp, "enemy": e, "ename": en, "n": int(sp.get("n", 4)), "camp": true, "hostage": h, "text": "Muhafızları yen (%d)." % int(sp.get("n", 4))},
				{"kind": "talk", "npc_id": "rehine", "text": "%s'i çöz." % sp["hostage"], "say": sp.get("s", ""), "then": "follow"},
				{"kind": "goto", "at": _inside(here, 0.0, 0.3), "r": 20.0, "followers": true, "name": "Köy", "text": "%s'i köye getir (seni takip ediyor)." % sp["hostage"]}]
		"patrol":
			var w1 = _spot(here, 120, 300)
			var w2 = _near_spot(w1, 200, 320)
			var w3 = _near_spot(w2, 200, 320)
			steps = [{"kind": "goto", "at": w1, "r": 12.0, "name": "Devriye Noktası 1", "text": "Devriye noktası 1."},
				{"kind": "goto", "at": w2, "r": 12.0, "name": "Devriye Noktası 2", "text": "Devriye noktası 2."},
				{"kind": "kill", "at": w3, "enemy": e, "ename": en, "n": int(sp.get("n", 2)), "text": "Son noktadaki şüphelileri yakala."},
				{"kind": "goto", "at": _inside(here, 0.0, 0.25), "r": 18.0, "name": "Köy", "text": "Köye dön ve rapor ver."}]
		"duel":
			var at = _spot(here, 30, 150)
			var opp = _npc("rakip", sp.get("g", en), "ninja")
			steps = [{"kind": "talk", "at": at, "npc": opp, "text": "%s ile buluş." % opp["name"], "say": sp.get("s1", "")},
				{"kind": "kill", "at": at, "at_npc": "rakip", "enemy": e, "n": 1, "boss": {"name": en, "hp": float(sp.get("hp", 700.0)), "level": int(sp.get("lv", 22)), "power": 2.0 + RANK_IDX[r] * 0.3}, "text": "Düelloyu kazan: %s" % en},
				{"kind": "goto", "at": _inside(here, 0.0, 0.25), "r": 18.0, "name": "Köy", "say": [en, sp.get("s2", "")], "text": "Köye dön."}]
		"investigate":
			var v = _npc("veren", sp.get("g", "Mağdur"), "merchant")
			var w1 = _npc("tanik1", sp["w1"], "civ")
			var w2 = _npc("tanik2", sp["w2"], "civ")
			var camp = _spot(here, 150, 550)
			var choices = []
			for c in sp["c"]:
				choices.append({"label": c[0], "ok": c[1], "reply": "İpuçları bunu gösteriyor. Peşlerine düş!" if c[1] else "Hmm... ipuçları buna uymuyor ama madem öyle diyorsun. (Yanlış şüphe!)"})
			choices.shuffle()
			steps = [{"kind": "talk", "at": _inside(here, 0.15, 0.5), "npc": v, "text": "%s ile konuş." % v["name"], "say": sp["b"]},
				{"kind": "talk", "at": _inside(here, 0.2, 0.6), "npc": w1, "text": "Tanık: %s." % sp["w1"], "say": sp["w1s"]},
				{"kind": "talk", "at": _inside(here, 0.2, 0.6), "npc": w2, "text": "Tanık: %s." % sp["w2"], "say": sp["w2s"]},
				{"kind": "collect", "at": _near_spot(camp, 60, 90), "item": sp["item"], "n": 3, "spread": 25, "text": "İzleri takip edip ipucu topla (3)."},
				{"kind": "talk", "npc_id": "veren", "text": "%s'e anlat." % v["name"], "say": "Bulduklarına göre suçlu kim?", "choices": choices},
				{"kind": "kill", "at": camp, "enemy": e, "ename": en, "n": int(sp.get("n", 3)), "camp": true, "text": "Suçluları yakala."},
				{"kind": "talk", "npc_id": "veren", "text": "%s'e dön." % v["name"], "say": "Gerçek ortaya çıktı. Köy sana minnettar."}]
			giver = v
		"chase":
			var market = _inside(here, 0.15, 0.55)
			steps = [{"kind": "goto", "at": market, "r": 10.0, "name": "Olay Yeri", "text": "Olay yerine git."},
				{"kind": "chase", "at": market, "time": 75.0, "thief": sp.get("en", "Kaçak"), "text": "Kaçağı yakala!"},
				{"kind": "goto", "at": _inside(here, 0.0, 0.25), "r": 18.0, "name": "Köy", "text": "Köye dön ve teslim et."}]
		"stealth":
			var camp = _spot(here, 250, 700)
			steps = [{"kind": "goto", "at": _near_spot(camp, 70, 90), "r": 10.0, "name": "Hedef Yakını", "night": true, "text": "Gece olunca hedefin yakınına git."},
				{"kind": "stealth", "at": camp, "enemy": e, "ename": en, "n": 4, "goal": String(sp.get("item", "belge")).capitalize(), "text": "Fark edilmeden %s al [F]." % sp.get("item", "belgeyi")},
				{"kind": "goto", "at": _inside(here, 0.0, 0.25), "r": 18.0, "name": "Köy", "text": "Köye dön."}]
	if steps.is_empty():
		return {}
	return {"title": sp["t"], "brief": sp["b"], "giver": giver["name"] if sp.has("g") else "%s Görev Masası" % Game.village(here).get("name", here),
		"steps": steps, "rank": r, "village": here, "type": "quest", "local": true}


# ------------------------------------------------------------------ görev masası (veri API'si + varsayılan diyalog)
var _boards := {}   # köy -> {"t": msec, "list": [...], "rank": int}
var _board_seq := 0


func rep(vid: String) -> int:
	return int(Game.profile.get("rep", {}).get(vid, 0))


## Köy dışından gelenler itibar kazanana kadar az ve düşük rütbeli görev görür
func board_limits(vid: String) -> Dictionary:
	var ranks: Array = RANK_FOR[int(Game.profile["rank"])].duplicate()
	if vid == Progress.home():
		return {"ranks": ranks, "max": 6, "note": ""}
	var rp = rep(vid)
	if rp < 20:
		var low = ranks.filter(func(x): return x in ["D", "C"])
		return {"ranks": low if not low.is_empty() else ["C"], "max": 2, "note": "Yabancısın: itibar 20 olunca daha fazla görev açılır (şu an %d)." % rp}
	if rp < 60:
		return {"ranks": ranks.filter(func(x): return x != "S"), "max": 4, "note": "Tanınıyorsun: itibar 60 olunca S-rank dahil tüm görevler açılır (şu an %d)." % rp}
	return {"ranks": ranks, "max": 6, "note": ""}


## Görev masası verisi: [{id, title, rank, village, giver, brief, objectives, rewards{ryo,xp,gear_chance,rep}, local, steps}]
func board_missions(vid: String, refresh := false) -> Array:
	var now = Time.get_ticks_msec()
	if not refresh and _boards.has(vid) and now - int(_boards[vid]["t"]) < 600000 and int(_boards[vid]["rank"]) == int(Game.profile["rank"]):
		return _boards[vid]["list"]
	var lim = board_limits(vid)
	var ranks: Array = lim["ranks"]
	var out = []
	var local = (MissionLocal.POOL.get(vid, []) as Array).filter(func(x): return x["r"] in ranks)
	local = local.duplicate()
	local.shuffle()
	for sp in local.slice(0, 3):
		var m = _from_spec(vid, sp)
		if not m.is_empty():
			out.append(m)
	var gen = []
	for r in ranks:
		var ts = _templates(r, vid)
		ts.shuffle()
		gen.append_array(ts.slice(0, 2 if r != "S" else 1))
	gen.shuffle()
	for m in gen:
		if out.size() >= int(lim["max"]):
			break
		out.append(m)
	out = out.slice(0, int(lim["max"]))
	for m in out:
		_board_seq += 1
		m["id"] = "b%d" % _board_seq
		m["objectives"] = m["steps"].map(func(x): return x["text"])
		var rw: Array = REWARD[m["rank"]]
		m["rewards"] = {"ryo": rw[0], "xp": rw[1], "gear_chance": GEAR_CHANCE[m["rank"]], "rep": REP_GAIN[m["rank"]]}
	_boards[vid] = {"t": now, "list": out, "rank": int(Game.profile["rank"])}
	return out


static func _script_has(scr, method: String) -> bool:
	if scr == null:
		return false
	for m in scr.get_script_method_list():
		if m["name"] == method:
			return true
	return false


func open_board(it: Dictionary) -> void:
	var here = Progress.home()
	var best = 1e9
	for v in Game.world_info["villages"]:
		var d: float = Game.to_map(it["pos"]).distance_to(Vector2(v["x"], v["y"]))
		if d < best:
			best = d; here = v["id"]
	board_village = here
	var cur = active()
	if not cur.is_empty():
		var opts = [{"label": "Görevi bırak (itibar -%d)" % REP_GAIN.get(cur.get("rank", "D"), 2), "cb": func(): abandon()}]
		Hud.dialog("Görev Masası", "Aktif görevin: %s (%s)\n%s\nAdım: %d/%d" % [cur["title"], cur["rank"], cur["desc"], int(cur.get("progress", 0)) + 1, cur["count"]], opts)
		return
	if Hud.has_method("show_mission_board"):
		Hud.call("show_mission_board", here)
		return
	board = board_missions(here)
	var opts = []
	for m in board:
		var rw: Dictionary = m["rewards"]
		opts.append({"label": "[%s] %s%s — %d Ryō, %d XP%s" % [m["rank"], "★ " if m.get("local", false) else "", m["title"], rw["ryo"], rw["xp"], "  ✦ekipman" if rw["gear_chance"] >= 0.5 else ""],
			"cb": _brief.bind(m), "tip": m["brief"]})
	var lim = board_limits(here)
	Hud.dialog("Görev Masası — %s" % Game.village(here)["name"], "Rütben: %s   •   %s itibarın: %d%s\n★ = köye özgü görev" % [Data.RANKS[int(Game.profile["rank"])], Game.village(here)["name"], rep(here), ("\n" + lim["note"]) if lim["note"] != "" else ""], opts)


func _brief(m: Dictionary) -> void:
	var lines = []
	for i in m["steps"].size():
		lines.append("%d. %s" % [i + 1, m["steps"][i]["text"]])
	Hud.dialog("[%s] %s" % [m["rank"], m["title"]], "%s\n\nGörevi veren: %s\n\n%s" % [m["brief"], m["giver"], "\n".join(lines)],
		[{"label": "Kabul et", "cb": accept.bind(m)}, {"label": "Diğer görevlere bak", "cb": func(): open_board({"pos": _vpos(board_village)})}])


## m: görev sözlüğü ya da board_missions'tan gelen id
func accept(m) -> void:
	if not m is Dictionary:
		var found = {}
		for vid in _boards:
			for x in _boards[vid]["list"]:
				if String(x.get("id", "")) == String(m):
					found = x
		if found.is_empty():
			return
		m = found
	for vid in _boards:
		_boards[vid]["list"] = (_boards[vid]["list"] as Array).filter(func(x): return x.get("id", "") != m.get("id", "?"))
	m = m.duplicate(true)
	if not m.has("steps"):
		m["steps"] = [{"kind": "goto", "at": [0, 0], "text": m.get("desc", "")}]
	m["id"] = "q%d" % Time.get_ticks_msec()
	m["step"] = 0
	m["progress"] = 0
	m["count"] = m["steps"].size()
	m["flags"] = {}
	m["type"] = "quest"
	Game.profile["active_mission"] = m
	Hud.banner("GÖREV: %s" % m["title"], "%s-rank" % m["rank"], Color(1, 0.75, 0.35))
	_setup(m)


func abandon() -> void:
	var m = active()
	if not m.is_empty():
		_rep(m.get("village", Progress.home()), -REP_GAIN.get(m.get("rank", "D"), 2))
	_cleanup()
	Game.profile["active_mission"] = {}
	Hud.objective_changed()


func fail(reason: String) -> void:
	var m = active()
	if m.is_empty():
		return
	Hud.banner("GÖREV BAŞARISIZ", reason, Color(1, 0.4, 0.35))
	Sfx.play("hurt", null, 0.7)
	_call_hook(String(m.get("hook", "")), m.duplicate(true), false)
	_rep(m.get("village", Progress.home()), -REP_GAIN.get(m.get("rank", "D"), 2) * 2)
	_cleanup()
	Game.profile["active_mission"] = {}
	Hud.objective_changed()


func _rep(vid: String, n: int) -> void:
	if not Game.profile.has("rep"):
		Game.profile["rep"] = {}
	Game.profile["rep"][vid] = int(Game.profile["rep"].get(vid, 0)) + n


## Kayıttan yüklenen ya da yeni kabul edilen görevin mevcut adımını kurar
func _setup(m: Dictionary) -> void:
	if m.get("type", "") != "quest":
		_setup_legacy(m)
		return
	_cleanup_nodes()
	_begin_step()


func _cur() -> Dictionary:
	var m = active()
	if m.is_empty() or m.get("type", "") != "quest":
		return {}
	var i = int(m["step"])
	return m["steps"][i] if i < m["steps"].size() else {}


func _key() -> String:
	var m = active()
	return "%s:%d" % [m.get("id", ""), int(m.get("step", 0))]


# ------------------------------------------------------------------ adım başlatma
func _begin_step() -> void:
	var m = active()
	var s = _cur()
	if s.is_empty():
		return
	for n in step_nodes:
		if is_instance_valid(n):
			n.queue_free()
	step_nodes.clear()
	st = {"n": 0, "t": 0.0}
	m["progress"] = int(m["step"])
	m["desc"] = s["text"]
	has_marker = true
	target_name = s.get("name", m["title"])
	Hud.objective_changed()
	Hud.objective_progress("")
	if s.get("night", false) and Game.world:
		var tod: float = Game.world.env.time_of_day
		if tod > 0.25 and tod < 0.78:
			Game.world.env.time_of_day = 0.86
			Hud.msg("Gece çökmesini bekledin...", Color(0.7, 0.8, 1.0))
	var root = get_tree().current_scene
	match s["kind"]:
		"goto":
			target_marker = _w(s["at"])
		"talk":
			var npc = _ensure_npc(s)
			if npc:
				target_marker = npc.global_position
				target_name = npc.display
		"kill":
			var c = _w(s["at"])
			if s.has("at_npc") and npcs.has(s["at_npc"]) and is_instance_valid(npcs[s["at_npc"]]):
				c = npcs[s["at_npc"]].global_position
				npcs[s["at_npc"]].queue_free()
				npcs.erase(s["at_npc"])
			target_marker = c
			if s.get("camp", false):
				step_nodes.append(_camp(c))
			var n = int(s["n"])
			var boss: Dictionary = s.get("boss", {})
			var es = _spawn(s["enemy"], c, n - (1 if not boss.is_empty() else 0), 14.0, s.get("ename", ""))
			if not boss.is_empty():
				var b = _spawn_boss(boss, s["enemy"], c)
				es.append(b)
			if s.has("hostage"):
				var hp = c + Vector3(3, 0, 3)
				var h = _make_npc(s["hostage"], hp)
				h.mode = "cower"
		"collect":
			var c = _w(s["at"])
			target_marker = c
			for i in int(s["n"]) + 2:
				var pk = Pickup.new()
				pk.item = s["item"]
				root.add_child(pk)
				var q = c + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * float(s.get("spread", 20))
				pk.global_position = Vector3(q.x, Game.ground_height(q.x, q.z), q.z)
				step_nodes.append(pk)
			var g: Dictionary = s.get("guard", {})
			if not g.is_empty():
				_spawn(g["enemy"], c, int(g["n"]), 25.0, g.get("ename", ""))
		"escort":
			var npc: QuestNPC = npcs.get(s["npc_id"])
			if npc == null or not is_instance_valid(npc):
				npc = _make_npc(_npc(s["npc_id"], "Eskort"), _w(s["from"]))
			npc.team = "player"
			if not npc.is_in_group("fighters"):
				npc.add_to_group("fighters")
			npc.max_hp = 260.0
			npc.hp = npc.max_hp
			npc.mode = "escort"
			npc.path = _path(_w(s["from"]), _w(s["to"]), 30.0)
			npc.path_i = 0
			st["amb"] = 0
			target_marker = npc.global_position
			target_name = npc.display
		"stealth":
			var c = _w(s["at"])
			target_marker = c
			step_nodes.append(_camp(c))
			var gs = _spawn(s["enemy"], c, int(s["n"]), 16.0, s.get("ename", ""))
			st["guards"] = gs
			st["cones"] = []
			for e in gs:
				e.blind_t = 1e9
				var cone = _cone_mesh()
				root.add_child(cone)
				step_nodes.append(cone)
				st["cones"].append(cone)
			st["detect"] = 0.0
			st["alarm"] = false
			_quest_point(c + Vector3(0, 0, 0), "[F] %s" % s.get("goal", "Şifre kitabını al"), 0)
		"chase":
			var c = _w(s["at"])
			var a = Enemy.archetype("bandit", 1)
			a["name"] = s.get("thief", "Parşömen Hırsızı Nezumi")
			a["speed"] = 9.4
			a["hp"] = 160.0
			a["level"] = 14
			a["respawn"] = false
			var e = Enemy.new()
			e.setup(a)
			e.set_meta("q", _key())
			root.add_child(e)
			var p = c + Vector3(8, 0, 0)
			p.y = Game.ground_height(p.x, p.z)
			e.global_position = p
			e.home = p
			step_nodes.append(e)
			st["thief"] = e
			st["caught"] = false
			Hud.banner("HIRSIZ!", "Peşine düş — %d sn" % int(s["time"]), Color(1, 0.6, 0.3))
		"defend":
			var c = _w(s["at"])
			target_marker = c
			st["wave"] = -1
			st["alive"] = []
			st["next_t"] = 2.0
		"track":
			st["prints"] = _path(_w(s["from"]), _w(s["to"]), 7.0)
			st["idx"] = 0
			st["shown"] = 0
			target_marker = st["prints"][0]
			Hud.msg("Ninken izleri kokluyor... parlayan pati izlerini takip et.", Color(0.8, 0.95, 1.0))
		"points":
			var c = _w(s["at"])
			target_marker = c
			if s.get("camp", false):
				step_nodes.append(_camp(c))
			var gd: Dictionary = s.get("guards", {})
			if not gd.is_empty():
				var gs = _spawn(gd["enemy"], c, int(gd["n"]), 16.0)
				st["guards"] = gs
				st["cones"] = []
				for e in gs:
					e.blind_t = 1e9
					var cone = _cone_mesh()
					root.add_child(cone)
					step_nodes.append(cone)
					st["cones"].append(cone)
				st["detect"] = 0.0
				st["alarm"] = false
			for i in int(s["n"]):
				var a = TAU * float(i) / float(s["n"]) + randf_range(-0.3, 0.3)
				var q = c + Vector3(cos(a), 0, sin(a)) * float(s.get("spread", 10)) * randf_range(0.6, 1.0)
				_quest_point(q, s["label"], i)
		"babysit":
			var kid = _ensure_npc({"at": s["at"], "npc": s["npc"]})
			kid.mode = "kid"
			kid.home = kid.global_position
			st["t"] = 0.0
			st["lost"] = 0.0
			target_marker = kid.global_position
			target_name = kid.display
		"cat":
			var c = CatNPC.new()
			root.add_child(c)
			var at = _inside(s.get("village", Progress.home()), 0.2, 0.8)
			c.global_position = _w(at)
			step_nodes.append(c)
			st["cat"] = c
			target_marker = c.global_position
			target_name = "Kedi Mikan"
		"boss":
			var v = Game.village(s["near"])
			var c = Game.from_map(Vector2(v["x"], v["y"]))
			var b = Boss.new()
			b.setup(Boss.make(s["boss"]))
			root.add_child(b)
			b.global_position = c
			b.home = c
			step_nodes.append(b)
			target_marker = c


func _next_step() -> void:
	var m = active()
	if m.is_empty():
		return
	Sfx.play("levelup", null, 1.6, 0.35)
	m["step"] = int(m["step"]) + 1
	if int(m["step"]) >= m["steps"].size():
		complete()
	else:
		_begin_step()
		Game.save_game()


# ------------------------------------------------------------------ yardımcılar
func _ensure_npc(s: Dictionary) -> QuestNPC:
	var spec: Dictionary = s.get("npc", {})
	var id: String = s.get("npc_id", spec.get("id", ""))
	if npcs.has(id) and is_instance_valid(npcs[id]) and not npcs[id].dead:
		return npcs[id]
	if spec.is_empty():
		spec = _npc(id, id.capitalize())
	var at = s.get("at", [Game.to_map(Game.player.global_position).x + 6, Game.to_map(Game.player.global_position).y])
	return _make_npc(spec, _w(at))


func _make_npc(spec: Dictionary, pos: Vector3) -> QuestNPC:
	var npc = QuestNPC.new()
	var lk = {}
	for k in spec.get("look", {}):
		var v = spec["look"][k]
		lk[k] = Color.html(v) if v is String and v.length() == 6 and v.is_valid_hex_number() else v
	npc.look = lk
	npc.display = spec.get("name", "Köylü")
	npc.team = "neutral"
	npc.quest_tag = spec.get("id", "")
	get_tree().current_scene.add_child(npc)
	pos.y = Game.ground_height(pos.x, pos.z)
	npc.global_position = pos
	npc.home = pos
	npcs[npc.quest_tag] = npc
	pickups.append(npc)
	return npc


func _spawn(kind: String, at: Vector3, n: int, spread: float, nm := "") -> Array:
	var out = []
	for i in n:
		var e = Enemy.new()
		var a = Enemy.archetype(kind, i)
		a["respawn"] = false
		if nm != "":
			a["name"] = nm
		e.setup(a)
		e.set_meta("mission", true)
		e.set_meta("q", _key())
		get_tree().current_scene.add_child(e)
		var p = at + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * spread
		p.y = Game.ground_height(p.x, p.z)
		e.global_position = p
		e.home = p
		e.wander_to = p
		step_nodes.append(e)
		out.append(e)
	return out


func _spawn_boss(b: Dictionary, kind: String, at: Vector3) -> Enemy:
	var e = Enemy.new()
	var a = Enemy.archetype(kind, 0)
	a["respawn"] = false
	a["name"] = b.get("name", a["name"])
	a["hp"] = float(b.get("hp", 600.0))
	a["level"] = int(b.get("level", 20))
	a["power"] = float(b.get("power", 2.0))
	a["guard"] = 0.45
	a["sub"] = 0.3
	a["xp"] = int(b.get("level", 20)) * 25
	a["ryo"] = int(b.get("level", 20)) * 20
	if b.has("look"):
		a["look"] = b["look"]
	e.setup(a)
	e.set_meta("mission", true)
	e.set_meta("q", _key())
	e.set_meta("flee", b.get("flee", false))
	e.set_meta("boss_q", true)
	get_tree().current_scene.add_child(e)
	var p = at
	p.y = Game.ground_height(p.x, p.z)
	e.global_position = p
	e.home = p
	step_nodes.append(e)
	return e


## İki nokta arası zeminde yürünebilir yol noktaları
func _path(a: Vector3, b: Vector3, step: float) -> Array:
	var out = []
	var d = a.distance_to(b)
	var n = maxi(2, int(d / step))
	var side = (b - a).cross(Vector3.UP).normalized()
	var ph = randf() * TAU
	for i in n + 1:
		var t = float(i) / n
		var p = a.lerp(b, t) + side * sin(t * 9.0 + ph) * minf(6.0, d * 0.02) * (1.0 - absf(t * 2.0 - 1.0))
		p.y = Game.ground_height(p.x, p.z)
		out.append(p)
	return out


## Basit haydut kampı: çadırlar, kamp ateşi, sandıklar, kazık çit
func _camp(c: Vector3) -> Node3D:
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = c
	var b = MB.new()
	var rng = RandomNumberGenerator.new()
	rng.seed = int(c.x * 7 + c.z * 13)
	for i in 4:
		var a = TAU * i / 4.0 + 0.4
		var p = Vector3(cos(a), 0, sin(a)) * 9.0
		p.y = Game.ground_height(c.x + p.x, c.z + p.z) - c.y
		b.add("prism", p + Vector3(0, 1.3, 0), Vector3(3.6, 2.6, 4.2), Color(0.55, 0.47, 0.35).darkened(rng.randf() * 0.2), Vector3(0, rad_to_deg(-a), 0))
	for i in 5:
		var a = rng.randf() * TAU
		var p = Vector3(cos(a), 0, sin(a)) * rng.randf_range(3, 6)
		p.y = Game.ground_height(c.x + p.x, c.z + p.z) - c.y
		b.add("box", p + Vector3(0, 0.45, 0), Vector3(0.9, 0.9, 0.9), Color(0.45, 0.32, 0.2), Vector3(0, rng.randf() * 90, 0))
	for i in 28:
		var a = TAU * i / 28.0
		if i % 7 == 0:
			continue
		var p = Vector3(cos(a), 0, sin(a)) * 15.0
		p.y = Game.ground_height(c.x + p.x, c.z + p.z) - c.y
		b.add("cyl", p + Vector3(0, 1.2, 0), Vector3(0.35, 2.4, 0.35), Color(0.4, 0.3, 0.2), Vector3.ZERO, 6)
	for k in 6:
		b.add("cyl", Vector3(0, 0.15, 0), Vector3(0.18, 1.2, 0.18), Color(0.35, 0.25, 0.15), Vector3(80, k * 30, 0), 5)
	b.add("cone", Vector3(0, 0.5, 0), Vector3(0.7, 1.0, 0.7), Color(1.0, 0.55, 0.15), Vector3.ZERO, 7)
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(Props.toon())
	root.add_child(mi)
	var l = OmniLight3D.new()
	l.light_color = Color(1, 0.6, 0.3)
	l.light_energy = 1.1
	l.omni_range = 9.0
	l.position = Vector3(0, 1.2, 0)
	root.add_child(l)
	return root


func _quest_point(pos: Vector3, label: String, idx: int) -> void:
	pos.y = Game.ground_height(pos.x, pos.z)
	var d = {"pos": pos, "radius": 3.0, "kind": "quest", "label": label, "qkey": _key(), "qi": idx}
	Interact.add(d)
	var mk = MeshInstance3D.new()
	var b = MB.new()
	b.add("box", Vector3(0, 0.5, 0), Vector3(0.9, 1.0, 0.9), Color(0.5, 0.38, 0.25))
	b.add("cyl", Vector3(0, 1.6, 0), Vector3(0.12, 1.2, 0.12), Color(1.0, 0.85, 0.3), Vector3.ZERO, 6)
	mk.mesh = b.build(Props.toon())
	get_tree().current_scene.add_child(mk)
	mk.global_position = pos
	mk.set_meta("qp", d)
	step_nodes.append(mk)
	FX.aura(mk, Color(1, 0.85, 0.3), 0.3, Vector3(0, 0.8, 0), 0.0)


func _remove_point(d: Dictionary) -> void:
	Interact.items.erase(d)
	for n in step_nodes:
		if is_instance_valid(n) and n.has_meta("qp") and n.get_meta("qp") == d:
			n.queue_free()


## Görüş konisi: yerde kırmızı yarı saydam yelpaze
func _cone_mesh() -> MeshInstance3D:
	var st2 = SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half = deg_to_rad(38.0)
	var segs = 12
	for i in segs:
		var a0 = -half + 2.0 * half * i / segs
		var a1 = -half + 2.0 * half * (i + 1) / segs
		st2.add_vertex(Vector3.ZERO)
		st2.add_vertex(Vector3(-sin(a0), 0, -cos(a0)))
		st2.add_vertex(Vector3(-sin(a1), 0, -cos(a1)))
	var mi = MeshInstance3D.new()
	mi.mesh = st2.commit()
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1, 0.15, 0.1, 0.22)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _cleanup_nodes() -> void:
	for x in step_nodes:
		if is_instance_valid(x):
			x.queue_free()
	step_nodes.clear()
	var drop = []
	for it in Interact.items:
		if it.get("kind", "") == "quest":
			drop.append(it)
	for it in drop:
		Interact.items.erase(it)


func _cleanup() -> void:
	_cleanup_nodes()
	for x in pickups:
		if is_instance_valid(x):
			x.queue_free()
	pickups.clear()
	npcs.clear()
	st = {}
	has_marker = false
	Hud.objective_progress("")
	var inv: Dictionary = Game.profile.get("inventory", {})
	for k in ["package", "ipucu", "yabani ot"]:
		inv.erase(k)


func complete() -> void:
	var m = active()
	var rw: Array = REWARD[m["rank"]]
	var bonus = 1.0
	if m.get("flags", {}).get("detected", false):
		bonus -= 0.3
	if m.get("flags", {}).get("wrong", false):
		bonus -= 0.25
	var ryo = int(rw[0] * bonus)
	_cleanup()
	Game.profile["active_mission"] = {}
	Game.profile["missions_done"][m["rank"]] = int(Game.profile["missions_done"].get(m["rank"], 0)) + 1
	Hud.banner("GÖREV TAMAMLANDI", "%s  (+%d Ryō)" % [m["title"], ryo], Color(0.5, 1, 0.6))
	Progress.add_ryo(ryo)
	Progress.add_xp(int(rw[1] * (1.0 + float(Game.profile.get("level", 1)) / 20.0)))
	_rep(m.get("village", Progress.home()), int(REP_GAIN[m["rank"]] * (1.5 if m.get("local", false) else 1.0)))
	if randf() < GEAR_CHANCE[m["rank"]]:
		var gid = ""
		if m["rank"] == "S" and randf() < 0.5:
			gid = Gear.random_legendary()
		else:
			gid = Gear.random_reward(RANK_IDX[m["rank"]] + 1)
		if gid != "" and not Gear.item(gid).is_empty():
			Gear.grant(Game.profile, gid)
			Hud.msg("Ödül ekipmanı: %s  [Tab > Ekipman]" % Gear.item(gid)["name"], Color(0.7, 0.9, 1.0))
	if Progress.story() == 6 and int(Game.profile["missions_done"]["D"]) >= 3:
		Progress.set_story(7)
	_call_hook(String(m.get("hook", "")), m, true)
	Hud.objective_changed()
	Game.save_game()


## Sınav/terfi/Kage görevleri bitince sahibine haber ver: "Autoload.metot"
func _call_hook(hk: String, m: Dictionary, ok: bool) -> void:
	if hk == "" or not hk.contains("."):
		return
	var parts = hk.split(".")
	var n = get_node_or_null("/root/" + parts[0])
	if n and n.has_method(parts[1]):
		n.call_deferred(parts[1], m, ok)


# ------------------------------------------------------------------ olaylar
func on_kill(e: Node) -> void:
	if e.has_meta("bingo_id"):
		_bingo_killed(e)
	var m = active()
	if m.is_empty():
		return
	if m.get("type", "") != "quest":
		if m["type"] == "kill" and e.get("arch") != null and e.arch.get("kind", "") == m.get("enemy", ""):
			_legacy_advance()
		elif m["type"] == "boss" and e is Boss:
			_legacy_advance()
		return
	var s = _cur()
	if e.get_meta("q", "") != _key() and not (s.get("kind", "") == "boss" and e is Boss):
		return
	st["n"] = int(st.get("n", 0)) + 1
	match s.get("kind", ""):
		"kill":
			Hud.objective_progress("%s: %d/%d" % [s["text"], st["n"], s["n"]])
			if int(st["n"]) >= int(s["n"]):
				_next_step()
		"chase":
			Hud.msg("Parşömeni geri aldın!", Color(0.6, 1, 0.6))
			_next_step()
		"boss":
			_next_step()


func on_dummy_broken() -> void:
	pass


func on_pickup(item: String) -> void:
	var s = _cur()
	if s.get("kind", "") == "collect" and item == s.get("item", ""):
		st["n"] = int(st.get("n", 0)) + 1
		Hud.objective_progress("%s %d/%d" % [s["text"].split("(")[0], st["n"], s["n"]])
		if int(st["n"]) >= int(s["n"]):
			_next_step()
	var m = active()
	if not m.is_empty() and m.get("type", "") == "collect" and item == "herb":
		_legacy_advance()


func on_cat_caught() -> void:
	var s = _cur()
	if s.get("kind", "") == "cat":
		_next_step()
	var m = active()
	if not m.is_empty() and m.get("type", "") == "cat":
		_legacy_advance()


func on_interact(it: Dictionary) -> void:
	if it.get("kind", "") == "bounty_board":
		open_bingo_dialog()
		return
	if it.get("kind", "") != "quest" or it.get("qkey", "") != _key():
		return
	var s = _cur()
	_remove_point(it)
	if Game.player:
		Game.player.model.play("interact", 0.1, 1.2, true)
	match s.get("kind", ""):
		"stealth":
			Hud.msg("%s alındı!" % s.get("goal", "Şifre kitabı"), Color(0.6, 1, 0.6))
			_next_step()
		"points":
			st["n"] = int(st.get("n", 0)) + 1
			if s.get("fx", "") == "paint":
				FX.burst(it["pos"] + Vector3.UP * 0.8, {"amount": 10, "life": 0.6, "size": 0.25, "vmin": 1, "vmax": 3, "gravity": Vector3(0, -6, 0),
					"colors": [Color(0.9, 0.3, 0.25, 1), Color(0.9, 0.3, 0.25, 0)]})
			else:
				Sfx.play("seal", it["pos"], 1.2)
			Hud.objective_progress("%s %d/%d" % [s["text"].split("(")[0], st["n"], s["n"]])
			if int(st["n"]) >= int(s["n"]):
				_next_step()


## QuestNPC [F] ile konuşulunca; true dönerse diyalog görev tarafından açıldı
func on_quest_talk(npc: QuestNPC) -> bool:
	var s = _cur()
	if s.is_empty():
		return false
	var id = s.get("npc_id", s.get("npc", {}).get("id", ""))
	if s["kind"] == "escort" and npc.quest_tag == s.get("npc_id", ""):
		Hud.dialog(npc.display, s.get("line", "Sen önden bak, ben yetişirim. Uzaklaşma ama!"), [])
		return true
	if s["kind"] == "babysit" and npc.quest_tag == s.get("npc", {}).get("id", ""):
		Hud.dialog(npc.display, ["Ebelemece oynayalım mı?! Yakala beni!", "Annem nerede? Sen ninja mısın? Bir jutsu göster!", "Hihi, beni yakalayamazsın!"].pick_random(), [])
		return true
	if s["kind"] != "talk" or npc.quest_tag != id:
		return false
	var choices: Array = s.get("choices", [])
	var opts = []
	if choices.is_empty():
		opts.append({"label": "Tamam", "cb": func(): _after_talk(npc, s)})
	else:
		for c in choices:
			opts.append({"label": c["label"], "cb": func():
				var m = active()
				if not c.get("ok", true):
					m["flags"]["wrong"] = true
				if c.has("vote"):  # Kage seçimi / konsey oyu
					m["flags"]["votes"] = int(m["flags"].get("votes", 0)) + int(c["vote"])
				Hud.dialog(npc.display, c.get("reply", ""), [{"label": "Devam", "cb": func():
					if not c.get("ok", true) and c.get("wrong", "") == "ambush":
						_spawn("rogue", npc.global_position + Vector3(6, 0, 6), 3, 6.0)
						Hud.banner("PUSU!", "Casus olduğunu sandılar!", Color(1, 0.4, 0.3))
					_after_talk(npc, s)}])})
	Hud.dialog(npc.display, s.get("say", "..."), opts)
	return true


func _after_talk(npc: QuestNPC, s: Dictionary) -> void:
	Hud.close_dialog()
	if s.get("then", "") == "follow":
		npc.mode = "follow"
		npc.team = "player"
	_next_step()


func on_quest_npc_died(npc: QuestNPC) -> void:
	var s = _cur()
	if s.is_empty():
		return
	if s["kind"] == "escort" or s.get("followers", false) or s["kind"] == "babysit":
		if Game.player and Game.player.combat and Game.player.combat.modes and Game.player.combat.modes.eyes:
			Game.player.combat.modes.eyes.on_ally_died(npc)  # Mangekyō uyanışı tetiklenebilir
		fail("%s öldü." % npc.display)


# ------------------------------------------------------------------ adım güncellemesi
func _process(dt: float) -> void:
	if Game.profile.is_empty():
		has_marker = false
		return
	_bingo_tick(dt)
	var m = active()
	if m.is_empty():
		var tb = _tracked_bounty()
		if not tb.is_empty():
			story_target = false
			has_marker = true
			target_marker = Game.from_map(Vector2(tb["area"][0], tb["area"][1]))
			target_name = "Aranan: %s (~%d m)" % [tb["alias"], int(tb["known"])]
			return
		# görev yoksa hikâye adımının hedefini göster
		var t = story_target_for(Progress.story())
		story_target = not t.is_empty()
		has_marker = story_target
		if story_target:
			target_marker = t["pos"]
			target_name = t["name"]
		return
	story_target = false
	if m.get("type", "") != "quest":
		_process_legacy(m)
		return
	has_marker = true
	if Game.paused or Game.player == null:
		return
	var s = _cur()
	if s.is_empty():
		return
	var pl = Game.player
	st["t"] = float(st.get("t", 0.0)) + dt
	match s["kind"]:
		"goto":
			var tp = _w(s["at"])
			target_marker = tp
			if pl.global_position.distance_to(tp) < float(s.get("r", 8.0)):
				if s.get("followers", false):
					for k in npcs:
						var n = npcs[k]
						if is_instance_valid(n) and n.mode == "follow" and n.global_position.distance_to(pl.global_position) > 16.0:
							Hud.objective_progress("Takip edeni bekle!")
							return
				if s.has("say") and s["say"] is Array and String(s["say"][1]) != "":
					Hud.dialog(s["say"][0], s["say"][1], [])
				if s.has("boom"):
					var b = _w(s["boom"])
					FX.explosion(b + Vector3.UP, 3.0)
					Sfx.play("boom", b, 0.7)
					Hud.banner("BOOM!", "İkmal kampı havaya uçtu!", Color(1, 0.6, 0.2))
				_next_step()
		"talk":
			var id = s.get("npc_id", s.get("npc", {}).get("id", ""))
			if npcs.has(id) and is_instance_valid(npcs[id]):
				target_marker = npcs[id].global_position
		"collect":
			var best = 1e9
			for pk in step_nodes:
				if is_instance_valid(pk) and pk is Pickup:
					var d: float = pk.global_position.distance_to(pl.global_position)
					if d < best:
						best = d; target_marker = pk.global_position
		"escort":
			_tick_escort(s)
		"stealth", "points":
			if st.has("guards"):
				_tick_stealth(dt, s)
		"chase":
			_tick_chase(s)
		"defend":
			_tick_defend(dt, s)
		"track":
			_tick_track(s)
		"babysit":
			_tick_babysit(dt, s)
		"cat":
			if st.has("cat") and is_instance_valid(st["cat"]):
				target_marker = st["cat"].global_position
		"kill":
			_tick_flee()


func _tick_escort(s: Dictionary) -> void:
	var npc: QuestNPC = npcs.get(s["npc_id"])
	if npc == null or not is_instance_valid(npc):
		return
	target_marker = npc.global_position
	var n = npc.path.size()
	var frac = float(npc.path_i) / float(maxi(1, n))
	var amb: Array = s.get("ambush", [])
	var ai = int(st.get("amb", 0))
	if ai < amb.size() and frac >= float(amb[ai][0]):
		st["amb"] = ai + 1
		var ahead = npc.path[mini(npc.path_i + 2, n - 1)]
		_spawn(amb[ai][1], ahead, int(amb[ai][2]), 8.0, amb[ai][3] if amb[ai].size() > 3 else "")
		Hud.banner("PUSU!", "Eskortu koru!", Color(1, 0.4, 0.3))
	# düşman yakındayken tüccar siner
	var danger = false
	for e in step_nodes:
		if is_instance_valid(e) and e is Enemy and not e.dead and e.global_position.distance_to(npc.global_position) < 22.0:
			danger = true
	if danger:
		npc.wait = 0.4
	Hud.objective_progress("%s — yol %%%d, can %d" % [npc.display, int(frac * 100), int(npc.hp)])
	if npc.path_i >= n:
		npc.mode = "idle"
		_next_step()


func _tick_stealth(dt: float, s: Dictionary) -> void:
	var pl = Game.player
	var gs: Array = st["guards"]
	var cones: Array = st["cones"]
	var night = Game.world and (Game.world.env.time_of_day < 0.24 or Game.world.env.time_of_day > 0.78)
	var rng = 11.0 if night else 15.0
	var seen = 0.0
	for i in gs.size():
		var e = gs[i]
		var cone: MeshInstance3D = cones[i] if i < cones.size() else null
		if not is_instance_valid(e) or e.dead:
			if cone and is_instance_valid(cone):
				cone.visible = false
			continue
		if cone and is_instance_valid(cone):
			cone.visible = not st["alarm"]
			cone.global_transform = Transform3D(Basis(Vector3.UP, e.facing).scaled(Vector3(rng, 1, rng)), e.global_position + Vector3(0, 0.15, 0))
		if st["alarm"]:
			continue
		var to = pl.global_position - e.global_position
		var d = to.length()
		if d < 2.5:
			seen = 10.0
		elif d < rng and absf(to.y) < 6.0 and e.face_dir().dot(Vector3(to.x, 0, to.z).normalized()) > cos(deg_to_rad(38.0)):
			seen = maxf(seen, (1.0 - d / rng) * 2.2 + 0.6)
	if st["alarm"]:
		return
	if seen > 0.0:
		st["detect"] = float(st["detect"]) + dt * seen
	else:
		st["detect"] = maxf(0.0, float(st["detect"]) - dt * 0.4)
	var bars = int(clampf(st["detect"], 0.0, 1.0) * 10)
	Hud.objective_progress("Fark edilme: [%s%s]" % ["█".repeat(bars), "·".repeat(10 - bars)] if st["detect"] > 0.01 else "Gizlisin.")
	if float(st["detect"]) >= 1.0:
		st["alarm"] = true
		active()["flags"]["detected"] = true
		Hud.banner("ALARM!", "Fark edildin — savaş ya da kaç!", Color(1, 0.3, 0.25))
		Sfx.play("roar", pl.global_position, 1.5, 0.5)
		for e in gs:
			if is_instance_valid(e) and not e.dead:
				e.blind_t = 0.0
				e.target = pl
				e.state = "chase"
				e.home = pl.global_position


func _tick_chase(s: Dictionary) -> void:
	var e = st.get("thief")
	if e == null or not is_instance_valid(e) or e.dead:
		return
	var pl = Game.player
	target_marker = e.global_position
	target_name = e.display_name
	var d = e.global_position.distance_to(pl.global_position)
	var left = float(s["time"]) - float(st["t"])
	if not st["caught"]:
		e.target = pl
		e.blind_t = 0.0
		e.state = "flee"
		e.state_t = 0.0
		Hud.objective_progress("Hırsız %d m ileride — %d sn" % [int(d), int(left)])
		if d < 2.6 or e.hp < e.max_hp * 0.85:
			st["caught"] = true
			e.home = e.global_position
			e.state = "chase"
			Hud.msg("Kıstırdın! Hırsız savaşıyor!", Color(1, 0.8, 0.4))
		elif left <= 0.0 or d > 140.0:
			fail("Hırsız kaçtı.")


func _tick_defend(dt: float, s: Dictionary) -> void:
	var c = _w(s["at"])
	var waves: Array = s["waves"]
	var alive = (st["alive"] as Array).filter(func(e): return is_instance_valid(e) and not e.dead)
	st["alive"] = alive
	if alive.is_empty():
		st["next_t"] = float(st["next_t"]) - dt
		if int(st["wave"]) + 1 >= waves.size():
			if int(st["wave"]) >= 0:
				_next_step()
			return
		if float(st["next_t"]) <= 0.0:
			st["wave"] = int(st["wave"]) + 1
			var w = int(st["wave"])
			var a = randf() * TAU
			var from = c + Vector3(cos(a), 0, sin(a)) * 45.0
			var es = _spawn(s["enemy"], from, int(waves[w]), 8.0, s.get("ename", ""))
			for e in es:
				e.home = c
				e.wander_to = c
			if w == waves.size() - 1 and RANK_IDX.get(active()["rank"], 0) >= 3:
				var b = _spawn_boss({"name": "Öncü Komutan", "hp": 700.0, "level": 26, "power": 2.4}, s["enemy"], from)
				b.home = c
				b.wander_to = c
				es.append(b)
			st["alive"] = es
			st["next_t"] = 3.0
			Hud.banner("DALGA %d/%d" % [w + 1, waves.size()], "Düşmanlar geliyor!", Color(1, 0.5, 0.3))
			target_marker = from
	else:
		target_marker = alive[0].global_position
		Hud.objective_progress("Dalga %d/%d — kalan düşman: %d" % [int(st["wave"]) + 1, waves.size(), alive.size()])


func _tick_track(s: Dictionary) -> void:
	var prints: Array = st["prints"]
	var idx = int(st["idx"])
	var pl = Game.player
	# sıradaki birkaç izi göster
	while int(st["shown"]) < mini(idx + 10, prints.size()):
		var i = int(st["shown"])
		var fp = MeshInstance3D.new()
		var b = MB.new()
		var off = 0.18 if i % 2 == 0 else -0.18
		b.add("sphere", Vector3(off, 0.03, 0), Vector3(0.22, 0.04, 0.32), Color(0.3, 0.9, 1.0))
		b.add("sphere", Vector3(off, 0.03, -0.22), Vector3(0.1, 0.04, 0.1), Color(0.3, 0.9, 1.0))
		fp.mesh = b.build(Props.toon())
		var m = StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(0.4, 0.95, 1.0)
		m.emission_enabled = true
		m.emission = Color(0.3, 0.8, 1.0)
		fp.material_override = m
		get_tree().current_scene.add_child(fp)
		var p: Vector3 = prints[i]
		var nxt: Vector3 = prints[mini(i + 1, prints.size() - 1)]
		fp.global_position = p + Vector3(0, 0.02, 0)
		if nxt.distance_to(p) > 0.1:
			fp.look_at(Vector3(nxt.x, p.y + 0.02, nxt.z), Vector3.UP)
		step_nodes.append(fp)
		st["shown"] = i + 1
	if idx < prints.size():
		target_marker = prints[idx]
		if pl.global_position.distance_to(prints[idx]) < 6.0:
			st["idx"] = idx + 1
		Hud.objective_progress("İz: %d/%d" % [idx, prints.size()])
	else:
		_next_step()


func _tick_babysit(dt: float, s: Dictionary) -> void:
	var kid: QuestNPC = npcs.get(s["npc"]["id"])
	if kid == null or not is_instance_valid(kid):
		return
	target_marker = kid.global_position
	var d = kid.global_position.distance_to(Game.player.global_position)
	if d < 14.0:
		st["t"] = float(st["t"])
		st["lost"] = 0.0
	else:
		st["t"] = float(st["t"]) - dt  # yakında değilsen süre ilerlemez
		st["lost"] = float(st["lost"]) + dt
		if float(st["lost"]) > 8.0:
			st["t"] = maxf(0.0, float(st["t"]) - 10.0)
			st["lost"] = 0.0
			Hud.msg("Tetsu'yu gözden kaçırdın! (-10 sn)", Color(1, 0.6, 0.4))
	var left = float(s["time"]) - float(st["t"])
	Hud.objective_progress("Bakıcılık: %d sn kaldı%s" % [int(maxf(0, left)), "  — YAKININDA KAL!" if d >= 14.0 else ""])
	if left <= 0.0:
		kid.mode = "idle"
		_next_step()


## Kaçabilen boss: canı %30'un altına inince bir kez duman bombasıyla uzaklaşır
func _tick_flee() -> void:
	for e in step_nodes:
		if is_instance_valid(e) and e is Enemy and not e.dead and e.get_meta("flee", false) and not e.get_meta("fled", false) and e.hp < e.max_hp * 0.3:
			_flee(e)


func _flee(e: Enemy) -> void:
	e.set_meta("fled", true)
	FX.smoke_puff(e.global_position + Vector3.UP, 1.4, 20)
	Sfx.play("poof", e.global_position)
	var a = randf() * TAU
	var p = e.global_position + Vector3(cos(a), 0, sin(a)) * randf_range(35, 50)
	p.y = Game.ground_height(p.x, p.z)
	e.global_position = p
	e.home = p
	e.hp = minf(e.max_hp, e.hp + e.max_hp * 0.1)
	Hud.banner("KAÇIYOR!", "%s duman bombasıyla kaçtı — peşine düş!" % e.display_name, Color(1, 0.6, 0.3))
	target_marker = p


# ------------------------------------------------------------------ eski tip görevler (kayıt uyumu)
func _setup_legacy(m: Dictionary) -> void:
	var root = get_tree().current_scene
	has_marker = true
	match m.get("type", ""):
		"cat":
			var c = CatNPC.new()
			root.add_child(c)
			c.global_position = _vpos(Progress.home(), randf_range(-150, 150), randf_range(-150, 150))
			pickups.append(c)
			target_marker = c.global_position
		"boss":
			var v = Game.village(m["near"])
			var c = Game.from_map(Vector2(v["x"], v["y"]))
			var b = Boss.new()
			b.setup(Boss.make(m["boss"]))
			root.add_child(b)
			b.global_position = c
			b.home = c
			pickups.append(b)
			target_marker = c
		_:
			# eski görev türü artık yok: görevi temizle
			if m.get("type", "") != "story":
				Game.profile["active_mission"] = {}
				has_marker = false


func _legacy_advance(n := 1) -> void:
	var m = active()
	m["progress"] = int(m.get("progress", 0)) + n
	if int(m["progress"]) >= int(m.get("count", 1)):
		var rw: Array = REWARD[m["rank"]]
		_cleanup()
		Game.profile["active_mission"] = {}
		Progress.add_ryo(rw[0])
		Progress.add_xp(rw[1])
		Hud.banner("GÖREV TAMAMLANDI", m["title"], Color(0.5, 1, 0.6))
		Hud.objective_changed()


func _process_legacy(m: Dictionary) -> void:
	has_marker = true
	target_name = m.get("title", "Görev Hedefi")
	if m.get("type", "") == "story" and target_marker == Vector3.ZERO:
		var vid = "forest_death" if String(m.get("title", "")).contains("Orman") else "bandit_camp"
		if not Game.village(vid).is_empty():
			target_marker = _vpos(vid)
	if m.get("type", "") == "cat" and not pickups.is_empty() and is_instance_valid(pickups[0]):
		target_marker = pickups[0].global_position


# ------------------------------------------------------------------ hikâye
## Hikâye adımının dünyadaki hedefi: {pos, name} (yoksa boş). Oyuncunun köyündeki noktalar tercih edilir.
func story_target_for(s: int) -> Dictionary:
	var home = Progress.home()
	var ck = "%s|%d" % [home, s]
	if _story_cache.has(ck):
		return _story_cache[ck]
	var spec = STORY_TARGETS.get(s)
	var res = {}
	if spec != null:
		var hv = Game.village(home)
		var hc = Vector2(float(hv.get("x", 0)), float(hv.get("y", 0)))
		if spec[0] == "village":
			if not Game.village(spec[1]).is_empty():
				res = {"pos": _vpos(spec[1]), "name": spec[2]}
		elif spec[0] == "story_camp":
			res = {"pos": story_camp_pos(), "name": spec[2]}
		else:
			# önce oyuncunun köyündeki nokta; köy-dışı tekil yerler (stadyum, şelale) için en yakını
			var limit = float(hv.get("r", 300)) * 1.6 if spec[0] in ["academy", "training", "lookout", "mission_board", "anbu"] else 1e12
			var best = limit
			for it in Interact.items:
				if it.get("interior", false) or (it["kind"] != spec[0] and it.get("alias", "") != spec[0]):
					continue
				var d = Game.to_map(it["pos"]).distance_to(hc)
				if d < best:
					best = d
					res = {"pos": it["pos"], "name": spec[2]}
			if s in [6, 7, 12] and not res.is_empty():
				res["name"] = "%s Kulesi" % Progress.kage_title(home) if s == 7 else spec[2]
			if res.is_empty() and limit < 1e11:
				# köy henüz akışla yüklenmedi: köy merkezine yönlendir (önbelleğe alma)
				return {"pos": Game.from_map(hc), "name": "%s — %s" % [hv.get("name", home), spec[2]]}
	if not res.is_empty():
		_story_cache[ck] = res
	return res


## Yasak Parşömen hikâyesinin haydut kampı: Konoha'da eski kamp, diğer köylerde köyün dışında sabit bir nokta
func story_camp_pos() -> Vector3:
	var home = Progress.home()
	if home == "konoha" and not Game.village("bandit_camp").is_empty():
		return _vpos("bandit_camp")
	var v = Game.village(home)
	var a = float(hash(home) % 360) * PI / 180.0
	var r = float(v.get("r", 250)) + 260.0
	for i in 12:
		var q = Vector2(float(v["x"]) + cos(a) * r, float(v["y"]) + sin(a) * r)
		if Game.terrain_height(q.x, -q.y) > 0.8:
			return Game.from_map(q)
		a += 0.5
	return _vpos(home, r, 0)


func spawn_scroll_thief() -> void:
	var c = story_camp_pos()
	if Progress.home() != "konoha":
		pickups.append(_camp(c))
		_spawn("bandit", c, 3, 12.0)
	var e = Enemy.new()
	var a = Enemy.archetype("rogue", 0)
	a["name"] = "Haydut Lideri Gouzan"
	a["hp"] = 220.0
	a["level"] = 7
	a["respawn"] = false
	a["xp"] = 250
	a["ryo"] = 300
	e.setup(a)
	e.set_meta("scroll_thief", true)
	get_tree().current_scene.add_child(e)
	e.global_position = c
	e.home = c
	target_marker = c
	has_marker = true
	Game.profile["active_mission"] = {"title": "Yasak Parşömen", "desc": "Haydut liderini yen.", "type": "story", "rank": "B", "count": 1, "progress": 0}


# ------------------------------------------------------------------ BINGO KİTABI (Aranıyor listesi)
const BB_GIVEN := ["Raizen", "Kurogiri", "Tsubame", "Gendo", "Hisame", "Akagane", "Somaru", "Kagenari", "Yatsume", "Onibi", "Garyu",
	"Fuyuki", "Benizuru", "Takuro", "Nokaze", "Hagane", "Ibuse", "Kurotetsu", "Shimon", "Ugetsu", "Zanpa", "Rokuro", "Sazame", "Tobimaru"]
const BB_FAMILY := ["Mizoguchi", "Kaneda", "Arashiyama", "Kurobane", "Hoshigane", "Kirisame", "Shirakawa", "Tsukiyama", "Iwakura",
	"Raimon", "Sunagawa", "Kagemura", "Onizuka", "Yamikawa", "Fujimaki", "Kurokage"]
const BB_ALIAS := ["Kızıl Tilki", "Sessiz Çekiç", "Sis Hayaleti", "Kemik Kıran", "Gece Kargası", "Kum Akrebi", "Fırtına Dişi", "Zehirli Gül",
	"Kara Kanca", "Yanık Yüz", "Demir Örümcek", "Kör Kurt", "Çift Bıçak", "Kül Şeytanı", "Gülümseyen Cellat", "Sessiz Yılan", "Kan Yağmuru", "Taş Yürek"]
const BB_CRIMES := ["Köy hazinesini soydu", "Daimyo kervanına pusu kurdu", "Yasak bir parşömen çaldı", "Sınır karakolunu yaktı",
	"Üç Chunin'i öldürdü", "Köyünden kaçıp gizli teknikleri sattı", "Kaçakçılık çetesi yönetiyor", "Tüccarları fidye için kaçırıyor",
	"Kuyu sularını zehirledi", "Bir tapınağı yağmaladı", "Bir Kage muhafızını yaraladı", "Sahte görev ilanlarıyla genin'leri tuzağa düşürüyor"]
const BB_RANKS := {"C": [800, 1500, 8, 12, 2, "bandit"], "B": [2500, 5000, 16, 22, 3, "rogue"], "A": [8000, 15000, 28, 35, 3, "rogue"], "S": [30000, 60000, 40, 50, 4, "rogue"]}
const BB_VILLAGES := ["konoha", "suna", "kiri", "kumo", "iwa", "ame", "kusa", "taki", "oto"]
const BB_ELEM := {"konoha": "katon", "suna": "fuuton", "kiri": "suiton", "kumo": "raiton", "iwa": "doton", "ame": "suiton", "kusa": "doton", "taki": "suiton", "oto": "fuuton"}
var _bb_spawned := {}   # id -> [boss, escorts..., camp]
var _bb_t := 0.0


func _bingo() -> Dictionary:
	var pr = Game.profile
	if not pr.has("bingo") or not pr["bingo"] is Dictionary:
		pr["bingo"] = {"list": [], "next": 1, "refresh": 900.0}
	return pr["bingo"]


func _bb_ranks() -> Array:
	return {0: ["C"], 1: ["C", "B"], 2: ["C", "B", "A"], 3: ["B", "A", "S"], 4: ["A", "S"], 5: ["A", "S"], 6: ["A", "S"]}[int(Game.profile.get("rank", 0))]


func _bb_new() -> Dictionary:
	var bb = _bingo()
	var rank: String = _bb_ranks().pick_random()
	var rd: Array = BB_RANKS[rank]
	var vid: String = BB_VILLAGES.filter(func(x): return not Game.village(x).is_empty()).pick_random()
	var near: String = Game.world_info["villages"].pick_random()["id"]
	var hide = _spot(near, 250, 1100)
	var area = [hide[0] + randf_range(-300, 300), hide[1] + randf_range(-300, 300)]
	var crimes = BB_CRIMES.duplicate()
	crimes.shuffle()
	var lv = randi_range(int(rd[2]), int(rd[3]))
	var e = {
		"id": int(bb["next"]), "name": "%s %s" % [BB_FAMILY.pick_random(), BB_GIVEN.pick_random()], "alias": BB_ALIAS.pick_random(),
		"village": vid, "rank": rank, "bounty": int(randi_range(int(rd[0]), int(rd[1])) / 50) * 50, "crimes": crimes.slice(0, 2 if rank in ["C", "B"] else 3),
		"element": BB_ELEM.get(vid, "katon"), "hide": hide, "area": area, "known": 450.0, "status": "alive", "tracked": false,
		"level": lv, "hp": 260.0 + lv * 24.0, "power": 1.3 + lv * 0.035, "escorts": int(rd[4]), "escort_kind": rd[5],
		"look": {"gender": ["m", "m", "f"].pick_random(), "hair_style": ["uzun", "dağınık", "diken", "kısa", "atkuyruğu"].pick_random(),
			"hair": _hex([Color(0.08, 0.08, 0.1), Color(0.6, 0.6, 0.62), Color(0.55, 0.15, 0.12), Color(0.2, 0.25, 0.4)].pick_random()),
			"top": _hex([Color(0.2, 0.2, 0.24), Color(0.35, 0.15, 0.15), Color(0.25, 0.3, 0.25), Color(0.4, 0.35, 0.3)].pick_random()),
			"top2": _hex(Color(0.12, 0.12, 0.14)), "pants": _hex(Color(0.18, 0.18, 0.2)), "top_style": ["yakali", "uzun", "ceket"].pick_random(),
			"village": vid, "band": _hex(Color(0.2, 0.2, 0.25)), "band_style": "slashed", "mask": ["cloth", null, null].pick_random(),
			"face_mark": ["burun yarası", "yanak çizgisi", "yok"].pick_random(), "age": "adult"},
	}
	bb["next"] = int(bb["next"]) + 1
	return e


func _bingo_tick(dt: float) -> void:
	var bb = _bingo()
	var lst: Array = bb["list"]
	var alive = lst.filter(func(x): return x["status"] == "alive")
	bb["refresh"] = float(bb.get("refresh", 900.0)) - dt
	if alive.size() < 6 or float(bb["refresh"]) <= 0.0:
		if float(bb["refresh"]) <= 0.0:
			bb["refresh"] = 900.0
		if alive.size() < 8:
			lst.append(_bb_new())
	if Game.player == null or Game.paused:
		return
	_bb_t -= dt
	if _bb_t > 0.0:
		return
	_bb_t = 0.5
	var pp = Game.player.global_position
	for e in alive:
		var hp = Game.from_map(Vector2(e["hide"][0], e["hide"][1]))
		var d = Vector2(pp.x, pp.z).distance_to(Vector2(hp.x, hp.z))
		var sp = _bb_spawned.get(int(e["id"]))
		if sp == null and d < 220.0:
			_bb_spawn(e, hp)
		elif sp != null and d > 450.0:
			for n in sp:
				if is_instance_valid(n):
					n.queue_free()
			_bb_spawned.erase(int(e["id"]))
		elif sp != null:
			var boss = sp[0]
			if is_instance_valid(boss) and not boss.dead:
				if not boss.get_meta("fled", false) and boss.hp < boss.max_hp * 0.3 and e["rank"] in ["B", "A", "S"]:
					_flee(boss)
				if boss.global_position.distance_to(pp) < 45.0:
					if Hud.boss == null or not is_instance_valid(Hud.boss):
						Hud.boss_bar(boss)
				if e.get("tracked", false):
					e["area"] = [Game.to_map(boss.global_position).x, Game.to_map(boss.global_position).y]
					e["known"] = 20.0


func _bb_look(e: Dictionary) -> Dictionary:
	var lk = CharacterModel.default_look()
	for k in e["look"]:
		var v = e["look"][k]
		lk[k] = Color.html(v) if v is String and v.length() == 6 and v.is_valid_hex_number() else v
	return lk


func _bb_spawn(e: Dictionary, at: Vector3) -> void:
	var nodes = []
	var root = get_tree().current_scene
	nodes.append(null)
	nodes.append(_camp(at))
	var a = Enemy.archetype("rogue", 0)
	a["respawn"] = false
	a["name"] = "«%s» %s" % [e["alias"], e["name"]]
	a["hp"] = float(e["hp"])
	a["level"] = int(e["level"])
	a["power"] = float(e["power"])
	a["guard"] = 0.45
	a["sub"] = 0.3
	a["xp"] = int(e["level"]) * 30
	a["ryo"] = 0
	a["element"] = e["element"]
	a["jutsu"] = {"suiton": ["suiton_suikoudan", "suiton_suiryuudan"], "doton": ["doton_doryuusou", "doton_doryuheki"], "raiton": ["raiton_nagashi", "raiton_chidori"],
		"katon": ["katon_goukakyuu", "katon_housenka"], "fuuton": ["fuuton_shinkuu", "fuuton_daitoppa"]}.get(e["element"], [])
	a["look"] = _bb_look(e)
	var b = Enemy.new()
	b.setup(a)
	b.set_meta("bingo_id", int(e["id"]))
	root.add_child(b)
	var p = at
	p.y = Game.ground_height(p.x, p.z)
	b.global_position = p
	b.home = p
	nodes[0] = b
	for i in int(e["escorts"]):
		var x = Enemy.new()
		var xa = Enemy.archetype(e["escort_kind"], i)
		xa["respawn"] = false
		x.setup(xa)
		root.add_child(x)
		var q = at + Vector3(randf_range(-12, 12), 0, randf_range(-12, 12))
		q.y = Game.ground_height(q.x, q.z)
		x.global_position = q
		x.home = q
		nodes.append(x)
	_bb_spawned[int(e["id"])] = nodes
	Hud.msg("Bingo Kitabı: «%s» buralarda bir yerde..." % e["alias"], Color(1, 0.75, 0.5))


func _bingo_killed(boss: Node) -> void:
	var id = int(boss.get_meta("bingo_id"))
	for e in _bingo()["list"]:
		if int(e["id"]) == id and e["status"] == "alive":
			e["status"] = "dead"
			e["tracked"] = false
			Hud.banner("ARANAN ETKİSİZ", "«%s» %s — %d Ryō ödül" % [e["alias"], e["name"], int(e["bounty"])], Color(1, 0.8, 0.3))
			Progress.add_ryo(int(e["bounty"]))
			var gid = Gear.random_legendary() if e["rank"] == "S" or (e["rank"] == "A" and randf() < 0.4) else Gear.random_reward(RANK_IDX.get(e["rank"], 1) + 1)
			if gid != "" and not Gear.item(gid).is_empty():
				Gear.grant(Game.profile, gid)
				Hud.msg("Ganimet: %s  [Tab > Ekipman]" % Gear.item(gid)["name"], Color(0.7, 0.9, 1.0))
			_rep(Progress.home(), REP_GAIN.get(e["rank"], 5) * 2)
			Game.save_game()


func _tracked_bounty() -> Dictionary:
	for e in _bingo()["list"]:
		if e.get("tracked", false) and e["status"] == "alive":
			return e
	return {}


## Bingo Kitabı girdileri (menü/diyalog için): look Color'a çevrilmiş kopyalar
func bingo_entries() -> Array:
	var own = Orgs.own_bingo_entry() if has_node("/root/Orgs") else {}
	if not own.is_empty():
		return [own] + _bingo_entries_raw()
	return _bingo_entries_raw()


func _bingo_entries_raw() -> Array:
	var out = []
	for e in _bingo()["list"]:
		var x = e.duplicate(true)
		x["look"] = _bb_look(e)
		x["village_name"] = Game.village(e["village"]).get("name", e["village"])
		x["region"] = Game.region_name(Game.from_map(Vector2(e["area"][0], e["area"][1])))
		out.append(x)
	out.sort_custom(func(a, b): return (a["status"] == "alive") and not (b["status"] == "alive") or (a["status"] == b["status"] and int(a["bounty"]) > int(b["bounty"])))
	return out


## Bir arananı haritada takip et (yalnız biri takip edilir)
func track_bounty(id: int) -> void:
	for e in _bingo()["list"]:
		e["tracked"] = int(e["id"]) == id and e["status"] == "alive"
	var t = _tracked_bounty()
	if not t.is_empty():
		Hud.msg("Takipte: «%s» — tahmini bölge haritada." % t["alias"], Color(1, 0.8, 0.5))


## Muhbire sor: bölge daralır ve gerçek saklanma yerine yaklaşır
func ask_informant(id: int) -> void:
	for e in _bingo()["list"]:
		if int(e["id"]) != id:
			continue
		var cost = maxi(50, int(int(e["bounty"]) * 0.05))
		if int(Game.profile["ryo"]) < cost:
			Hud.msg("Muhbir için %d Ryō lazım." % cost, Color(1, 0.5, 0.4))
			return
		Progress.add_ryo(-cost)
		e["known"] = maxf(40.0, float(e["known"]) * 0.5)
		e["area"] = [lerpf(e["area"][0], e["hide"][0], 0.55), lerpf(e["area"][1], e["hide"][1], 0.55)]
		Hud.dialog("Muhbir", "«%s» en son %s civarında görülmüş. Arayacağın bölge artık ~%d m." % [e["alias"], Game.region_name(Game.from_map(Vector2(e["area"][0], e["area"][1]))), int(e["known"])], [])


## Aranıyor panosu / ninja menüsü için bağımsız Bingo Kitabı diyaloğu
func open_bingo_dialog() -> void:
	var ms = load("res://scripts/ui/menus.gd")
	if _script_has(ms, "bingo_book"):
		ms.call("bingo_book", get_tree().current_scene)
		return
	var opts = []
	for e in bingo_entries():
		if e["status"] != "alive":
			continue
		opts.append({"label": "[%s] «%s» %s — %d Ryō%s" % [e["rank"], e["alias"], e["name"], int(e["bounty"]), "  ◎takipte" if e["tracked"] else ""],
			"cb": _bingo_detail.bind(int(e["id"])), "tip": ", ".join(e["crimes"])})
	var dead = bingo_entries().filter(func(x): return x["status"] != "alive").size()
	Hud.dialog("BINGO KİTABI — Aranıyor", "Ödüllü kaçak ninjalar ve suçlular. Yakalanan: %d" % dead, opts)


func _bingo_detail(id: int) -> void:
	for e in bingo_entries():
		if int(e["id"]) != id:
			continue
		var txt = "Takma ad: «%s»\nKöy: %s (kaçak)\nTehlike: %s-rank  •  Seviye ~%d\nElement: %s\nSuçları: %s\nSon görüldüğü yer: %s (~%d m alan)\nÖdül: %d Ryō%s" % [
			e["alias"], e["village_name"], e["rank"], int(e["level"]), e["element"], ", ".join(e["crimes"]), e["region"], int(e["known"]), int(e["bounty"]),
			"\nDİKKAT: Yenilmek üzereyken kaçmaya çalışır." if e["rank"] in ["B", "A", "S"] else ""]
		var cost = maxi(50, int(int(e["bounty"]) * 0.05))
		Hud.dialog("%s" % e["name"], txt, [
			{"label": "Takip et (haritada işaretle)", "cb": func(): track_bounty(id)},
			{"label": "Muhbire sor (%d Ryō) — bölgeyi daralt" % cost, "cb": func(): ask_informant(id)},
			{"label": "Listeye dön", "cb": open_bingo_dialog}])
