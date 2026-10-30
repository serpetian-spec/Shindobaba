extends Node
## Kage sistemi (autoload "Kage"):
##  Kage adaylığı ve seçimi (konsey oyları + daimyō desteği + rakip aday + köy savunma denemesi + yemin töreni),
##  Kage olarak köy yönetimi (ninja takımlarına görev dağıtma, bütçe, akademi/hastane/savunma/pazar/istihbarat yatırımları —
##  köyde görünür değişiklikler), diplomasi (diğer köylerle ilişki/ittifak/gerilim), köy olayları, Beş Kage Zirvesi.

signal relations_changed()
signal became_kage()

const GREAT := ["konoha", "suna", "kiri", "kumo", "iwa"]
const DAY_LEN := 240.0          # Kage masasında 1 gün (gerçek saniye)
const RANK_POWER := {"D": 25, "C": 50, "B": 90, "A": 140, "S": 210}
const RANK_PAY := {"D": 4000, "C": 12000, "B": 30000, "A": 70000, "S": 160000}
const UPGRADES := {
	"akademi": ["Akademi", "Her seviye yeni bir genin takımı ve daha güçlü mezunlar.", "book"],
	"hastane": ["Hastane", "Yaralı takımlar daha hızlı iyileşir, görevlerde ölüm riski azalır.", "heart"],
	"savunma": ["Savunma", "Sur gözcü kuleleri, istila ve baskınlarda daha az kayıp.", "rock"],
	"pazar": ["Pazar ve Ticaret", "Günlük gelir artar, tüccarlar köye akın eder.", "coin"],
	"istihbarat": ["İstihbarat", "Görev başarı şansı ve Bingo Kitabı ipuçları artar.", "eye"],
}
const SQUAD_NAMES := ["Takım Hayabusa", "Takım Kagerō", "Takım Tsubaki", "Takım Raijin", "Takım Kurenai-ha", "Takım Iwatsuki", "Takım Mizuchi", "Takım Shirasagi"]
const MEMBER_NAMES := ["Arata", "Benika", "Chōji-ro", "Daigo", "Emi", "Fuyuki", "Genma-ro", "Hikari", "Isamu", "Jun", "Kaede", "Ryūsei", "Mai", "Nobu", "Otoha", "Riku", "Sakon", "Tamaki", "Ukyō", "Yae"]
const CLIENTS := ["Daimyō Sarayı", "Tüccar Loncası", "Ateş Tapınağı Rahipleri", "Köy Çiftçileri", "Liman Kaptanı", "Demir Ülkesi Elçisi", "Kaplıca Kasabası Muhtarı", "Sınır Köyü Muhtarı"]
const JOBS := {"D": ["Kayıp kedi", "Tarla işi", "Tapınak temizliği"], "C": ["Kervan eskortu", "Haydut temizliği", "Köprü inşaatı koruması"],
	"B": ["Casus avı", "Sınır devriyesi", "Kaçakçı baskını"], "A": ["Daimyō muhafızlığı", "Kaçak jōnin takibi", "Gizli belge teslimi"], "S": ["Akatsuki istihbaratı", "Savaş önleme müzakeresi", "Kuyruklu canavar takibi"]}
const KAGE_NAMES := {"konoha": "Hokage Hōjō Akitsugu", "suna": "Kazekage Sabaku-ha Raiden", "kiri": "Mizukage Kirisame Utsuho", "kumo": "Raikage Ikazuchi Gōki", "iwa": "Tsuchikage Iwanaga Dosan"}
const KAGE_LOOKS := {"konoha": Color(0.85, 0.15, 0.12), "suna": Color(0.2, 0.45, 0.4), "kiri": Color(0.2, 0.4, 0.8), "kumo": Color(0.95, 0.85, 0.2), "iwa": Color(0.45, 0.3, 0.2)}

var _decor: Node3D
var _decor_sig := ""
var _reign_t := 900.0
const REIGN_CHECK := 1500.0    # gerçek sn: her ~25 dk'da bir Kage değişimi zarı
const REIGN_REASONS := ["yaşlandı ve şapkasını bıraktı", "bir savaşta şehit düştü", "konsey tarafından görevden alındı", "bir suikaste kurban gitti", "ağır bir hastalığa yenik düştü"]


## ---------------------------------------------------------------- dinamik Kage (her oyunda farklı)
## Kage'ler zamanla değişir: emeklilik, savaş, suikast... Halef o köyün Elit Jōnin dostlarından biri olabilir
## (Friends: rank 3) ya da köyün klanlarından rastgele bir ninja. Yeni Kage'nin sana bakışı köyler arası ilişkiyi etkiler.
func reign(vid: String) -> Dictionary:
	if Game.profile.is_empty():
		return {}
	return p().get("reigns", {}).get(vid, {})


func kage_name(vid: String) -> String:
	if is_kage() and vid == Progress.home():
		return "%s %s" % [Progress.kage_title(vid), String(p().get("name", ""))]
	var r = reign(vid)
	if not r.is_empty():
		return "%s %s" % [Progress.kage_title(vid), String(r["name"])]
	return KAGE_NAMES.get(vid, Progress.kage_title(vid))


## KageAttire.look için kişilik (saç/cinsiyet/ten); yoksa boş -> sabit kişilik
func kage_persona(vid: String) -> Dictionary:
	var r = reign(vid)
	if r.is_empty():
		return {}
	var out = {}
	for k in r.get("persona", {}):
		var v = r["persona"][k]
		out[k] = Color(float(v[0]), float(v[1]), float(v[2])) if v is Array else v
	return out


func _reign_tick(dt: float) -> void:
	_reign_t -= dt
	if _reign_t > 0.0:
		return
	_reign_t = REIGN_CHECK * randf_range(0.7, 1.3)
	var cands = GREAT.filter(func(v): return not (is_kage() and v == Progress.home()))
	if cands.is_empty() or randf() > 0.45:
		return
	succeed(String(cands.pick_random()))


func succeed(vid: String) -> void:
	if not p().has("reigns"):
		p()["reigns"] = {}
	var old = kage_name(vid)
	var title = Progress.kage_title(vid)
	var gen = int(reign(vid).get("gen", 4)) + 1
	var who = ""
	var persona = {}
	var fid = ""
	# o köyün Elit Jōnin dostları önce düşünülür
	var fs: Dictionary = Friends.all()
	var elite = fs.keys().filter(func(k): return String(fs[k].get("village", "")) == vid and int(fs[k].get("rank", 0)) >= 3 and Friends.available(fs[k]))
	if not elite.is_empty() and randf() < 0.6:
		fid = String(elite.pick_random())
		var f: Dictionary = fs[fid]
		who = String(f["name"])
		var lk = Friends.look_of(f)
		for k in ["gender", "hair", "hair_style", "skin"]:
			if lk.has(k):
				persona[k] = [lk[k].r, lk[k].g, lk[k].b] if lk[k] is Color else lk[k]
		f["kage"] = vid
		f["party"] = false
		Friends.log_event(f, "%s oldu!" % title)
		f["news"] = "İnanabiliyor musun? Artık %s benim. Kapım sana her zaman açık." % title
	else:
		var clans: Array = []
		for c in Data.clans:
			if c != "none" and vid in Data.clans[c].get("villages", []) and not c in Progress.UNPLAYABLE_CLANS:
				clans.append(c)
		var fem = randf() < 0.3
		who = ClanWorld.person_name(clans.pick_random(), fem) if not clans.is_empty() else "%s %s" % [String(Missions.BB_FAMILY.pick_random()), (ClanWorld.GIVEN_F if fem else ClanWorld.GIVEN_M).pick_random()]
		var hc = [Color(0.1, 0.1, 0.12), Color(0.82, 0.82, 0.84), Color(0.35, 0.22, 0.12), Color(0.6, 0.2, 0.15), Color(0.85, 0.8, 0.5)].pick_random()
		persona = {"gender": "f" if fem else "m", "hair": [hc.r, hc.g, hc.b], "hair_style": ["geriye", "kısa", "uzun", "diken", "topuz", "savas_yelesi", "bilge_yelesi"].pick_random(),
			"beard": not fem and randf() < 0.5}
	p()["reigns"][vid] = {"name": who, "gen": gen, "persona": persona, "friend": fid}
	var vn = String(Game.village(vid).get("name", vid))
	Hud.banner("YENİ %s: %s" % [title.to_upper(), who.to_upper()], "%s %s. %s'in %d. %s'i yemin etti." % [old, REIGN_REASONS.pick_random(), vn, gen, title], Color(1, 0.8, 0.45))
	if is_kage():
		add_log("%s: %s yeni %s oldu." % [vn, who, title])
	# yeni liderin sana bakışı köyler arası ilişkiyi kaydırır
	if vid != Progress.home() and not Game.profile.is_empty():
		if fid != "":
			var b = int(Friends.all()[fid]["bond"])
			change_relation(vid, 20 if b >= 30 else (-25 if b <= -30 else 0))
		else:
			change_relation(vid, randi_range(-15, 15))


func p() -> Dictionary:
	return Game.profile


func is_kage() -> bool:
	return not Game.profile.is_empty() and int(p().get("rank", 0)) >= 6


func st() -> Dictionary:
	if not p().has("kage") or not p()["kage"] is Dictionary:
		p()["kage"] = {"funds": 60000, "day": 1, "t": 0.0, "squads": [], "requests": [], "upg": {"akademi": 0, "hastane": 0, "savunma": 0, "pazar": 0, "istihbarat": 0},
			"rel": {}, "events": [], "log": [], "summit": "none", "trade": {}, "alliance": {}}
		for v in GREAT:
			if v != Progress.home():
				p()["kage"]["rel"][v] = 10
	return p()["kage"]


func relation(vid: String) -> int:
	if Game.profile.is_empty():
		return 0
	return int(st()["rel"].get(vid, 0))


## Gerilimli köy: sınır muhafızları düşmanca davranır (diğer sistemler sorabilir)
func hostile_to(vid: String) -> bool:
	return relation(vid) <= -40


func change_relation(vid: String, n: int) -> void:
	if vid == Progress.home() or Game.profile.is_empty():
		return
	st()["rel"][vid] = clampi(relation(vid) + n, -100, 100)
	relations_changed.emit()


func add_log(text: String) -> void:
	var lg: Array = st()["log"]
	lg.push_front("Gün %d — %s" % [int(st()["day"]), text])
	if lg.size() > 30:
		lg.resize(30)


# ================================================================== adaylık ve seçim
func candidacy_ready() -> String:
	var pr = p()
	if int(pr["rank"]) < 3:
		return "En az Jōnin olmalısın."
	if int(pr["level"]) < 90:
		return "Kage adaylığı için Seviye 90 gerekli (şu an %d)." % int(pr["level"])
	if Missions.rep(Progress.home()) < 150:
		return "Köyünde 150 itibar gerekli (şu an %d)." % Missions.rep(Progress.home())
	if int(pr["missions_done"].get("S", 0)) < 3:
		return "3 S-rank görev gerekli (şu an %d)." % int(pr["missions_done"].get("S", 0))
	if Orgs.is_rogue():
		return "Kaçak bir ninja Kage olamaz."
	return ""


func offer_candidacy() -> void:
	var why = candidacy_ready()
	var kt = Progress.home_info()["kage"]
	if why != "":
		Hud.dialog(kt, "Bir gün bu koltuğa oturacağına inanıyorum. Ama henüz değil: %s" % why, [])
		return
	if Missions.active().get("hook", "") == "Kage.selection_done":
		Hud.dialog(kt, "Seçim süreci devam ediyor.", [])
		return
	Hud.dialog(kt, "Yaşlandım %s. Konsey ve daimyō yeni bir %s arıyor; adın herkesin dilinde. Aday olmak, konseyin, daimyōnun ve jōninlerin güvenini kazanmak; rakip adayla yüzleşmek ve köyü bir krizde korumak demek. Hazır mısın?" % [p()["name"], kt], [
		{"label": "Adaylığımı koyuyorum", "cb": _start_selection},
		{"label": "Henüz değil", "cb": func(): pass}])


func _start_selection() -> void:
	Progress.promote(5)
	Missions.accept(_selection_mission())


func _selection_mission() -> Dictionary:
	var vid = Progress.home()
	var kt = Progress.home_info()["kage"]
	var e1 = Missions._npc("danisman1", "Danışman Tsugumi", "elder")
	var e2 = Missions._npc("danisman2", "Danışman Gonza", "elder")
	var dm = Missions._npc("elci", "Daimyō'nun Elçisi Matsudaira", "vip")
	var rival = Missions._npc("rakip", "Rakip Aday Kurogane Daisuke", "ninja")
	var cur_kage = Missions._npc("kage", kage_name(vid), "elder")
	cur_kage["look"]["top"] = Missions._hex(Color(0.95, 0.94, 0.9))
	var gate = Missions._inside(vid, 0.85, 0.95)
	return {"title": "%s Seçimi" % kt, "rank": "S", "village": vid, "hook": "Kage.selection_done", "giver": "Köy Konseyi",
		"brief": "Konseyin iki danışmanını, daimyōnun elçisini ikna et; rakip adayla yüzleş ve köy kapısına yapılan saldırıyı püskürterek liderliğini kanıtla. Toplanan oylar kararı belirler.",
		"steps": [
			{"kind": "talk", "at": Missions._inside(vid, 0.05, 0.2), "npc": e1, "text": "Danışman Tsugumi ile konuş.", "say": "Bir Kage'nin ilk görevi nedir sence?",
				"choices": [{"label": "Köyün çocuklarını, geleceği korumak", "ok": true, "vote": 2, "reply": "Ateşin İradesi... doğru cevap. Oyum seninle."},
					{"label": "Köyü en güçlü köy yapmak", "ok": true, "vote": 1, "reply": "Güç önemlidir ama tek başına yetmez."},
					{"label": "Düşmanları cezalandırmak", "ok": false, "vote": 0, "reply": "İntikam bir köyü yönetemez."}]},
			{"kind": "talk", "at": Missions._inside(vid, 0.05, 0.2), "npc": e2, "text": "Danışman Gonza ile konuş.", "say": "Bütçe kısıtlı: akademiye mi, sınır savunmasına mı yatırım yaparsın?",
				"choices": [{"label": "İkisine dengeli; önce yaralı ninjaların bakımı", "ok": true, "vote": 2, "reply": "Pragmatik ve vicdanlı. Beğendim."},
					{"label": "Tamamen savunmaya", "ok": true, "vote": 1, "reply": "Temkinli... savaş zamanında işe yarar."},
					{"label": "Kendi birliğime", "ok": false, "vote": 0, "reply": "Bu bir Kage'nin değil, bir hizip liderinin cevabı."}]},
			{"kind": "talk", "at": Missions._inside(vid, 0.1, 0.3), "npc": dm, "text": "Daimyō'nun elçisi ile konuş.", "say": "Daimyō köyünüzden ne bekleyebileceğini bilmek istiyor. Ülkenin askeri gücü sizsiniz.",
				"choices": [{"label": "Ülkeyi koruruz ama köy kendi kararlarını verir", "ok": true, "vote": 2, "reply": "Onurlu bir denge. Daimyō'ya olumlu rapor vereceğim."},
					{"label": "Daimyō ne isterse yaparız", "ok": true, "vote": 1, "reply": "Sadakat güzel... ama köy ninjalarına haksızlık olabilir."},
					{"label": "Bize karışmasın", "ok": false, "vote": 0, "reply": "Bu sözler sarayda iyi karşılanmaz."}]},
			{"kind": "talk", "at": Missions._inside(vid, 0.3, 0.5), "npc": rival, "text": "Rakip aday Kurogane ile yüzleş.", "say": "Konsey seni seviyor ama ben bu köyü yıllardır savunuyorum. Bir Kage'nin gücünü görmeden çekilmem.",
				"choices": [{"label": "Seni yardımcım olarak istiyorum; birlikte daha güçlüyüz", "ok": true, "vote": 2, "reply": "...Bunu beklemiyordum. Yine de gücünü göster, sonra elini sıkarım."},
					{"label": "O halde dövüşelim", "ok": true, "vote": 1, "reply": "Güzel! Arenada görüşürüz."}]},
			{"kind": "kill", "at_npc": "rakip", "at": Missions._inside(vid, 0.3, 0.5), "enemy": "rogue", "n": 1,
				"boss": {"name": "Kurogane Daisuke (rakip aday)", "hp": 4200.0, "level": maxi(35, int(p()["level"])), "power": 2.6}, "text": "Rakip adayı onurlu bir düelloda yen."},
			{"kind": "defend", "at": gate, "enemy": "rogue", "waves": [4, 5, 6], "text": "KRİZ: Köy kapısına saldırı! Adaylığını savunmayla kanıtla."},
			{"kind": "talk", "at": Missions._inside(vid, 0.0, 0.1), "npc": cur_kage, "text": "%s'in huzuruna çık." % kt, "say": "Konsey toplandı, oylar sayıldı..."}]}


func selection_done(m: Dictionary, ok: bool) -> void:
	var kt = Progress.home_info()["kage"]
	if not ok:
		Progress.promote(3)
		Hud.dialog("Köy Konseyi", "Seçim süreci yarıda kaldı. Adaylığın düştü; hazır olduğunda yeniden başvurabilirsin.", [])
		return
	var votes = int(m.get("flags", {}).get("votes", 0)) + int(Missions.rep(Progress.home()) / 100)
	if votes >= 6:
		if int(p()["level"]) >= 100:
			inaugurate()
		else:
			Exams.flags()["kage_elect"] = true
			Hud.dialog("Köy Konseyi", "Konsey oybirliğiyle seni seçti! Ancak gelenek gereği yemin, ancak ninjalığın zirvesinde (Seviye 100) edilebilir. O güne kadar Seçilmiş %s olarak köyün en önemli görevlerini üstleneceksin." % kt, [])
			return
	else:
		Progress.promote(3)
		Hud.dialog("Köy Konseyi", "Oylar yetersiz (%d/6). Konsey seni henüz hazır görmüyor; itibarını artır ve tekrar dene." % votes, [])


func inaugurate() -> void:
	var kt = Progress.home_info()["kage"]
	var vn = String(Game.village(Progress.home()).get("name", ""))
	Progress.promote(6)
	var pr = p()
	Gear.ensure(pr)
	Gear.grant(pr, "kage_cubbesi", "dis")
	Gear.grant(pr, "kage_sapkasi", "kafa", Progress.home_info()["band"].lerp(Color.WHITE, 0.6))
	Gear.apply_look(pr)
	if Game.player:
		Game.player.rebuild_model()
		for i in 6:
			var a = TAU * i / 6.0
			FX.ring(Game.player.global_position + Vector3(cos(a) * 6, 4 + i, sin(a) * 6), Color(1, 0.75, 0.3), 5.0, 0.8, false)
	st()
	add_log("%s yemin etti. Yeni dönem başladı." % pr["name"])
	_ensure_squads()
	_gen_requests()
	became_kage.emit()
	Hud.banner("%s %s" % [String(Game.village(Progress.home()).get("name", "")).to_upper(), kt.to_upper()], "Yemin töreni: köy halkı tezahürat yapıyor!", Color(1, 0.75, 0.3))
	Hud.dialog("Köy Halkı", "%s! %s! Yeni %s'imiz %s!" % [kt, kt, kt, pr["name"]], [{"label": "Kage masasına geç", "cb": func(): KageDesk.open()}])
	decorate()


# ================================================================== takımlar ve görev dağıtımı
func _new_squad(i: int, power_bonus := 0) -> Dictionary:
	var names = MEMBER_NAMES.duplicate()
	names.shuffle()
	var members = []
	var lvl = int(st()["upg"].get("akademi", 0))
	for k in 3 + (1 if i % 2 == 0 else 0):
		var rk = ("Jōnin" if i % 2 == 0 else "Chūnin") if k == 0 else ("Chūnin" if k == 1 and lvl >= 2 else "Genin")
		members.append({"name": names[k], "rank": rk, "pow": {"Genin": 15, "Chūnin": 30, "Jōnin": 55}[rk] + randi_range(-4, 6) + lvl * 4})
	var pw = power_bonus
	for mm in members:
		pw += int(mm["pow"])
	return {"name": SQUAD_NAMES[i % SQUAD_NAMES.size()], "members": members, "power": pw, "morale": 70, "status": "hazır", "busy": 0.0, "job": {}, "missions": 0}


func _ensure_squads() -> void:
	var sq: Array = st()["squads"]
	var want = 4 + int(st()["upg"].get("akademi", 0))
	while sq.size() < want:
		sq.append(_new_squad(sq.size()))


func _gen_requests() -> void:
	var rq: Array = st()["requests"]
	while rq.size() < 5:
		var r = ["D", "C", "C", "B", "B", "A", "S"].pick_random()
		var job: String = JOBS[r].pick_random()
		rq.append({"id": randi(), "rank": r, "title": job, "client": CLIENTS.pick_random(), "pay": int(RANK_PAY[r] * randf_range(0.8, 1.25) / 100) * 100,
			"diff": int(RANK_POWER[r] * randf_range(0.85, 1.2)), "days": {"D": 1, "C": 1, "B": 2, "A": 2, "S": 3}[r]})


func success_chance(squad: Dictionary, req: Dictionary) -> float:
	var c = 0.5 + (float(squad["power"]) - float(req["diff"])) / (float(req["diff"]) * 1.4)
	c += (float(squad["morale"]) - 50.0) * 0.003 + int(st()["upg"].get("istihbarat", 0)) * 0.06 + Stats.skill(p(), "squad") * 0.5
	return clampf(c, 0.05, 0.97)


func assign(squad_i: int, req_id: int) -> void:
	var sq: Dictionary = st()["squads"][squad_i]
	var req = {}
	for r in st()["requests"]:
		if int(r["id"]) == req_id:
			req = r
	if req.is_empty() or sq["status"] != "hazır":
		return
	st()["requests"].erase(req)
	sq["status"] = "görevde"
	sq["busy"] = float(req["days"]) * DAY_LEN
	sq["job"] = req
	add_log("%s → %s (%s-rank, %s)" % [sq["name"], req["title"], req["rank"], req["client"]])
	Sfx.play("seal", null, 1.2)


func _finish_job(sq: Dictionary) -> void:
	var req: Dictionary = sq["job"]
	var ok = randf() < success_chance(sq, req)
	var k = st()
	if ok:
		k["funds"] = int(k["funds"]) + int(req["pay"])
		sq["morale"] = mini(100, int(sq["morale"]) + 8)
		sq["missions"] = int(sq["missions"]) + 1
		for mm in sq["members"]:
			mm["pow"] = int(mm["pow"]) + 1
		sq["power"] = _sum_pow(sq)
		Missions._rep(Progress.home(), {"D": 1, "C": 2, "B": 4, "A": 7, "S": 12}[req["rank"]])
		sq["status"] = "hazır"
		add_log("✔ %s başarıyla döndü: %s (+%d Ryō)" % [sq["name"], req["title"], int(req["pay"])])
		Hud.msg("Kage masası: %s görevi başardı (+%d Ryō)" % [sq["name"], int(req["pay"])], UI.GOOD)
	else:
		sq["morale"] = maxi(10, int(sq["morale"]) - 20)
		var heal_days = maxf(0.5, 2.0 - int(k["upg"].get("hastane", 0)) * 0.5)
		sq["status"] = "yaralı"
		sq["busy"] = heal_days * DAY_LEN
		var lost = ""
		if randf() < (0.25 - int(k["upg"].get("hastane", 0)) * 0.07) and (sq["members"] as Array).size() > 2:
			var who = (sq["members"] as Array).pop_back()
			lost = " — %s şehit düştü. Adı Anıt Taşı'na yazıldı." % who["name"]
		sq["power"] = _sum_pow(sq)
		Missions._rep(Progress.home(), -3)
		add_log("✘ %s başarısız: %s%s" % [sq["name"], req["title"], lost])
		Hud.msg("Kage masası: %s görevde başarısız oldu%s" % [sq["name"], lost], UI.BAD)
	sq["job"] = {}


func _sum_pow(sq: Dictionary) -> int:
	var pw = 0
	for mm in sq["members"]:
		pw += int(mm["pow"])
	return pw


# ================================================================== yatırımlar
func upgrade_cost(id: String) -> int:
	return 25000 * (int(st()["upg"].get(id, 0)) + 1)


func buy_upgrade(id: String) -> bool:
	var k = st()
	var lv = int(k["upg"].get(id, 0))
	if lv >= 3 or int(k["funds"]) < upgrade_cost(id):
		return false
	k["funds"] = int(k["funds"]) - upgrade_cost(id)
	k["upg"][id] = lv + 1
	add_log("Yatırım: %s seviye %d" % [UPGRADES[id][0], lv + 1])
	if id == "akademi":
		_ensure_squads()
	Missions._rep(Progress.home(), 5)
	decorate()
	Sfx.play("coin")
	return true


func daily_income() -> int:
	var k = st()
	var inc = 9000 + int(k["upg"].get("pazar", 0)) * 5000
	for v in k.get("trade", {}):
		if k["trade"][v]:
			inc += 3500
	inc -= (k["squads"] as Array).size() * 600
	return inc


# ================================================================== diplomasi
func diplomacy(vid: String, action: String) -> String:
	var k = st()
	var vn = String(Game.village(vid).get("name", vid))
	match action:
		"hediye":
			if int(k["funds"]) < 8000:
				return "Hazine yetersiz."
			k["funds"] = int(k["funds"]) - 8000
			change_relation(vid, 12)
			add_log("%s'e hediye gönderildi (+12 ilişki)." % vn)
			return "Hediye gönderildi."
		"ticaret":
			if relation(vid) < 30:
				return "%s ile ilişkiler ticaret anlaşması için yeterli değil (30 gerekli)." % vn
			k["trade"][vid] = true
			add_log("%s ile ticaret anlaşması imzalandı (+3.500 Ryō/gün)." % vn)
			return "Ticaret anlaşması imzalandı."
		"ittifak":
			if relation(vid) < 70 or String(k.get("summit", "none")) != "done":
				return "İttifak için 70 ilişki ve Beş Kage Zirvesi gerekir."
			k["alliance"][vid] = true
			add_log("%s ile resmi ittifak kuruldu." % vn)
			return "İttifak kuruldu!"
		"tatbikat":
			change_relation(vid, -15)
			k["upg"]["savunma"] = int(k["upg"].get("savunma", 0))
			Missions._rep(Progress.home(), 6)
			add_log("%s sınırında gövde gösterisi (−15 ilişki, +6 itibar)." % vn)
			return "Sınır tatbikatı yapıldı."
	return ""


# ================================================================== köy olayları
func _gen_event() -> void:
	var k = st()
	var types = ["mektup", "festival", "afet", "baskin"]
	var worst = ""
	for v in k["rel"]:
		if relation(v) < -20:
			worst = v
	if worst != "":
		types.append("istila")
	var t = types.pick_random()
	var ev = {"id": randi(), "type": t}
	match t:
		"mektup":
			var v = (k["rel"] as Dictionary).keys().pick_random()
			ev["village"] = v
			ev["title"] = "%s'den diplomatik mektup" % Game.village(v).get("name", v)
			ev["text"] = ["Sınırdaki ortak devriyeler için asker talep ediyorlar.", "Çalınan bir parşömenin iadesi için arabuluculuk istiyorlar.", "Ortak bir Chūnin sınavına ev sahipliği teklif ediyorlar."].pick_random()
		"festival":
			ev["title"] = "Bahar Festivali"
			ev["text"] = "Halk festival istiyor. Masrafı köy karşılarsa moral ve itibar artar."
		"afet":
			ev["title"] = ["Sel baskını", "Orman yangını", "Kum fırtınası"].pick_random()
			ev["text"] = "Mahalleler zarar gördü. Yardım ekibi ve para gerekiyor."
		"baskin":
			ev["title"] = "Mezraya haydut baskını"
			ev["text"] = "Köyün dışındaki bir mezra haydutların saldırısı altında."
		"istila":
			ev["village"] = worst
			ev["title"] = "%s ordusu sınırda!" % Game.village(worst).get("name", worst)
			ev["text"] = "Gerilim savaşa dönüştü. Öncü birlikler köy kapısına ilerliyor."
	k["events"].append(ev)
	Hud.msg("Kage masası: yeni olay — %s" % ev["title"], Color(1, 0.8, 0.4))


func resolve_event(ev_id: int, choice: String) -> String:
	var k = st()
	var ev = {}
	for e in k["events"]:
		if int(e["id"]) == ev_id:
			ev = e
	if ev.is_empty():
		return ""
	k["events"].erase(ev)
	var out = ""
	match [ev["type"], choice]:
		["mektup", "kabul"]:
			change_relation(String(ev["village"]), 15)
			k["funds"] = int(k["funds"]) - 5000
			out = "Teklif kabul edildi (+15 ilişki, −5.000 Ryō)."
		["mektup", "ret"]:
			change_relation(String(ev["village"]), -12)
			out = "Teklif reddedildi (−12 ilişki)."
		["festival", "kabul"]:
			k["funds"] = int(k["funds"]) - 12000
			Missions._rep(Progress.home(), 12)
			for sq in k["squads"]:
				sq["morale"] = mini(100, int(sq["morale"]) + 15)
			out = "Festival düzenlendi! Moral ve itibar arttı."
		["festival", "ret"]:
			Missions._rep(Progress.home(), -4)
			out = "Festival iptal edildi. Halk biraz kırgın."
		["afet", "kabul"]:
			k["funds"] = int(k["funds"]) - 15000
			Missions._rep(Progress.home(), 10)
			out = "Yardım ekipleri gönderildi; halk minnettar."
		["afet", "ret"]:
			Missions._rep(Progress.home(), -15)
			out = "Yardım gönderilmedi. Halk öfkeli (−15 itibar)."
		["baskin", "kabul"], ["istila", "kabul"]:
			_personal_defense(ev)
			out = "Bizzat savunmaya gidiyorsun!"
		["baskin", "takim"], ["istila", "takim"]:
			var best = null
			for sq in k["squads"]:
				if sq["status"] == "hazır" and (best == null or int(sq["power"]) > int(best["power"])):
					best = sq
			if best == null:
				out = "Hazır takım yok! Savunma zayıf kaldı."
				Missions._rep(Progress.home(), -10)
			else:
				var diff = 90 if ev["type"] == "baskin" else 200 - int(k["upg"].get("savunma", 0)) * 35
				var fake = {"rank": "B" if ev["type"] == "baskin" else "S", "title": ev["title"], "client": "Köy", "pay": 0, "diff": diff, "days": 1}
				best["status"] = "görevde"
				best["busy"] = DAY_LEN * 0.5
				best["job"] = fake
				out = "%s savunmaya gönderildi." % best["name"]
	add_log("%s: %s" % [ev["title"], out])
	return out


func _personal_defense(ev: Dictionary) -> void:
	var vid = Progress.home()
	var kind = String(ev.get("village", "")) if String(ev.get("village", "")) in ["kumo", "kiri", "iwa", "suna"] else "bandit"
	var at = Missions._inside(vid, 0.85, 0.95) if ev["type"] == "istila" else Missions._spot(vid, 250, 600)
	var waves = [5, 6, 7] if ev["type"] == "istila" else [3, 4]
	Missions.accept({"title": ev["title"], "rank": "S" if ev["type"] == "istila" else "B", "village": vid, "giver": "Kage", "brief": ev["text"],
		"steps": [{"kind": "defend", "at": at, "enemy": kind, "waves": waves, "text": "Saldırıyı püskürt."}]})


# ================================================================== Beş Kage Zirvesi
func summit_ready() -> bool:
	return is_kage() and String(st().get("summit", "none")) == "none" and int(st()["day"]) >= 3


func start_summit() -> void:
	st()["summit"] = "active"
	var home = Progress.home()
	var tetsu = Game.village("tetsu")
	# zirve: kalenin önündeki açık salon (kalenin merkezi içi dolu taş kaide — NPC'ler gömülüyordu)
	var hall = [float(tetsu.get("x", 0)), float(tetsu.get("y", 0)) - 101.0] if not tetsu.is_empty() else Missions._spot(home, 1500, 2500)
	var gen = Missions._npc("general", "Samuray Generali Takenouchi", "ninja")
	gen["look"]["vest"] = Missions._hex(Color(0.55, 0.57, 0.6))
	var steps = [{"kind": "goto", "at": hall, "r": 22.0, "name": "Demir Ülkesi — Zirve Salonu", "text": "Demir Ülkesi'ndeki zirve salonuna git."},
		{"kind": "talk", "at": [hall[0], hall[1] - 10.0], "npc": gen, "text": "Arabulucu samuray generaliyle konuş.", "say": "Beş Kage Zirvesi'ne hoş geldiniz. Burada silahlar kınında kalır. Gündem: kuyruklu canavarları avlayan Akatsuki."}]
	var i = 0
	for v in GREAT:
		if v == home:
			continue
		var nm = kage_name(v)
		var k = Missions._npc("kage_" + v, nm, "elder")
		k["look"]["top"] = Missions._hex(Color(0.95, 0.94, 0.9))
		k["look"]["village"] = v
		var rel = relation(v)
		var say = ["Senin köyün de bu tehdide karşı mı, yoksa Akatsuki'yi kendi çıkarına mı kullanıyor?", "Kumo kimseye güvenmez. Neden seninle birleşelim?", "Sis köyü yalnızlığa alışkındır. Teklifin ne?", "Yaşlı bir adam olarak çok savaş gördüm. Bu sefer farklı olacak mı?"][i % 4]
		var ka = TAU * (i + 1) / 5.0
		steps.append({"kind": "talk", "at": [hall[0] + sin(ka) * 9.5, hall[1] - cos(ka) * 9.5], "npc": k, "text": "%s ile görüş." % nm,
			"say": say + ("  (İlişki: %d)" % rel),
			"choices": [{"label": "Birleşik bir ordu kuralım; komutayı paylaşalım", "ok": true, "vote": 1, "reply": "...Makul. Destekliyorum."},
				{"label": "Önce eski anlaşmazlıklarımızı çözelim", "ok": true, "vote": 1 if rel > 0 else 0, "reply": "Geçmişi konuşmak cesaret ister."},
				{"label": "Kendi köyümü korurum, siz de kendinizinkini", "ok": false, "vote": 0, "reply": "O halde neden geldin?"}]})
		i += 1
	var lead = Orgs.AKATSUKI[0]
	steps.append({"kind": "kill", "at": [hall[0], hall[1] - 26], "enemy": "rogue", "n": 2, "boss": {"name": "%s «%s»" % [lead["name"], lead["alias"]], "hp": 3600.0, "level": maxi(45, int(p()["level"])), "power": 3.0, "look": Orgs.akatsuki_look(lead)},
		"text": "Zirveye sızan Akatsuki üyesini durdur!"})
	steps.append({"kind": "talk", "npc_id": "general", "text": "Zirveyi sonuçlandır.", "say": "Saldırı her şeyi netleştirdi. Kage'ler ne karar verdi?"})
	Missions.accept({"title": "Beş Kage Zirvesi", "rank": "S", "village": home, "hook": "Kage.summit_done", "giver": "Samuray Generali", "brief": "Demir Ülkesi'nde dört Kage ile buluş. Akatsuki'ye karşı birleşik bir ordu kur — ya da köyünü yalnız bırak.", "steps": steps})


## Eski sürümde kabul edilen zirve görevi: adımlar kalenin merkezini (içi dolu kaide, tepede görünür) gösteriyordu —
## hepsini kalenin önündeki salona kaydır (bir kez)
func fix_summit_steps(m: Dictionary) -> void:
	if m.get("summit_v2", false):
		return
	m["summit_v2"] = true
	var t = Game.village("tetsu")
	if t.is_empty():
		return
	var cx = float(t["x"])
	var cy = float(t["y"])
	var hall = [cx, cy - 101.0]
	var i = 0
	for st in m.get("steps", []):
		if not st.has("at"):
			continue
		var a: Array = st["at"]
		if Vector2(float(a[0]), float(a[1])).distance_to(Vector2(cx, cy)) > 60.0:
			continue   # zaten yeni yerinde ya da başka yer
		match String(st.get("kind", "")):
			"goto":
				st["at"] = hall
				st["r"] = 22.0
			"talk":
				if st.get("npc", {}).get("id", "") == "general":
					st["at"] = [hall[0], hall[1] - 10.0]
				else:
					var ka = TAU * (i + 1) / 5.0
					st["at"] = [hall[0] + sin(ka) * 9.5, hall[1] - cos(ka) * 9.5]
					i += 1
			"kill":
				st["at"] = [hall[0], hall[1] - 26.0]
	Missions.target_marker = Missions._w(hall)


func summit_done(m: Dictionary, ok: bool) -> void:
	if not ok:
		st()["summit"] = "none"
		return
	var votes = int(m.get("flags", {}).get("votes", 0))
	st()["summit"] = "done"
	Orgs.state()["summit"] = true
	var gain = 30 if votes >= 3 else (15 if votes >= 2 else 5)
	for v in GREAT:
		change_relation(v, gain)
	add_log("Beş Kage Zirvesi: %s (ilişkiler +%d)" % ["Müttefik Shinobi Kuvvetleri kuruldu" if votes >= 3 else "kısmi uzlaşı", gain])
	Hud.banner("BEŞ KAGE ZİRVESİ", "Müttefik Shinobi Kuvvetleri kuruldu!" if votes >= 3 else "Kısmi bir uzlaşı sağlandı.", Color(1, 0.8, 0.4))
	if not Orgs.is_hunting():
		Orgs.start_beast_hunt()


# ================================================================== köyde görünür değişiklikler
func decorate() -> void:
	if Game.profile.is_empty() or not is_kage():
		return
	var k = st()
	var sig = str(k["upg"])
	if sig == _decor_sig and is_instance_valid(_decor):
		return
	_decor_sig = sig
	if is_instance_valid(_decor):
		_decor.queue_free()
	_decor = Node3D.new()
	_decor.name = "KageDecor"
	get_tree().current_scene.add_child(_decor)
	var vid = Progress.home()
	var v = Game.village(vid)
	var c = Vector2(float(v["x"]), float(v["y"]))
	var r = float(v["r"])
	var band: Color = Progress.home_info()["band"]
	var tower = Exams.find_point(["mission_board"])
	var mb = MB.new()
	# savunma: surda gözcü kuleleri
	var nt = int(k["upg"].get("savunma", 0)) * 6
	for i in nt:
		var a = TAU * i / maxf(1, nt)
		var q = Game.from_map(c + Vector2(cos(a), sin(a)) * r * 0.93)
		var g = Game.ground_height(q.x, q.z)
		var base = Vector3(q.x, g, q.z)
		mb.add("box", base + Vector3(0, 9, 0), Vector3(5, 18, 5), Color(0.5, 0.42, 0.32))
		mb.add("box", base + Vector3(0, 19, 0), Vector3(7, 3, 7), Color(0.4, 0.33, 0.26))
		mb.add("cone", base + Vector3(0, 22.5, 0), Vector3(9, 4, 9), band.darkened(0.2), Vector3.ZERO, 4)
	# akademi: avluda köy sancakları
	var acad = Exams.find_point(["academy"])
	for i in int(k["upg"].get("akademi", 0)) * 3:
		var q = acad + Vector3(-12 + i * 4, 0, 14)
		q.y = Game.ground_height(q.x, q.z)
		mb.add("cyl", q + Vector3(0, 4, 0), Vector3(0.3, 8, 0.3), Color(0.35, 0.25, 0.18), Vector3.ZERO, 6)
		mb.add("box", q + Vector3(0.9, 6.5, 0), Vector3(1.6, 3.0, 0.08), band)
	# hastane: yeni kanat
	var hosp = Exams.find_point(["hospital"])
	for i in int(k["upg"].get("hastane", 0)):
		var q = hosp + Vector3(22 + i * 14, 0, -6)
		q.y = Game.ground_height(q.x, q.z)
		mb.add("box", q + Vector3(0, 5, 0), Vector3(12, 10, 10), Color(0.92, 0.92, 0.9))
		mb.add("box", q + Vector3(0, 10.4, 0), Vector3(13, 0.8, 11), Color(0.7, 0.2, 0.2))
	# pazar: kulenin önünde yeni tezgâhlar
	for i in int(k["upg"].get("pazar", 0)) * 4:
		var a = PI + (i - 6) * 0.18
		var q = tower + Vector3(cos(a), 0, sin(a)) * 40.0
		q.y = Game.ground_height(q.x, q.z)
		mb.add("box", q + Vector3(0, 0.6, 0), Vector3(3, 1.2, 1.6), Color(0.55, 0.38, 0.22))
		mb.add("box", q + Vector3(0, 2.4, 0), Vector3(3.4, 0.15, 2.2), [Color(0.8, 0.25, 0.2), Color(0.25, 0.5, 0.75), Color(0.85, 0.7, 0.3)][i % 3])
	# istihbarat: kulenin tepesinde anten-bayrak
	if int(k["upg"].get("istihbarat", 0)) > 0:
		mb.add("cyl", tower + Vector3(0, 40, 0), Vector3(0.4, 14, 0.4), Color(0.3, 0.3, 0.32), Vector3.ZERO, 6)
		mb.add("box", tower + Vector3(1.5, 45, 0), Vector3(3, 2, 0.1), band)
	var mi = MeshInstance3D.new()
	mi.mesh = mb.build(Props.toon())
	_decor.add_child(mi)


# ================================================================== güncelleme
func _process(dt: float) -> void:
	if Game.player == null or Game.profile.is_empty() or Game.paused:
		return
	_reign_tick(dt)
	if not is_kage():
		if Exams.flags().get("kage_elect", false) and int(p().get("level", 1)) >= 100:
			Exams.flags().erase("kage_elect")
			inaugurate()
		return
	var k = st()
	_ensure_squads()
	if not is_instance_valid(_decor):
		decorate()
	k["t"] = float(k["t"]) + dt
	for sq in k["squads"]:
		if sq["status"] == "hazır":
			continue
		sq["busy"] = float(sq["busy"]) - dt
		if float(sq["busy"]) > 0.0:
			continue
		if sq["status"] == "görevde":
			_finish_job(sq)
		else:
			sq["status"] = "hazır"
	if float(k["t"]) >= DAY_LEN:
		k["t"] = 0.0
		k["day"] = int(k["day"]) + 1
		k["funds"] = int(k["funds"]) + daily_income()
		_gen_requests()
		if randf() < 0.45 and (k["events"] as Array).size() < 4:
			_gen_event()
		# gerilim yavaşça normale döner
		for v in k["rel"]:
			k["rel"][v] = int(k["rel"][v]) - signi(int(k["rel"][v])) if absi(int(k["rel"][v])) > 50 else int(k["rel"][v])
		if summit_ready():
			Hud.msg("Demir Ülkesi'nden davet: Beş Kage Zirvesi! (Kage masası > Olaylar)", Color(1, 0.8, 0.4))
