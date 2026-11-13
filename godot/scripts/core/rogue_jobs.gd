class_name RogueJobs
extends RefCounted
## Kaçak hayatı: yeraltı iş panosu ("kacak" panosu). İşler gerçek nesne + mekânla (MissionWork) yürür;
## bir kısmı dünyada o an olanlardan doğar (WorldNews: firari köyünden önce bulunur).

const BOARD := "kacak"
const CHEST_RYO := 450
const SACK_RYO := 160
## İz: işlerin geride bıraktığı ipucu birikimi (0-100). Yüksekse av takımı çabuk gelir, barakayı bulur. Zamanla soğur.
const TRAIL_BASE := {"heist": 30, "decoy": 12, "jail": 26, "smuggle": 0, "poach": 8, "suikast": 24, "harac": 14}
static var _hot := false


static func trail() -> float:
	return float(Orgs.flags().get("trail", 0.0))


static func add_trail(n: float) -> void:
	Orgs.flags()["trail"] = clampf(trail() + n, 0.0, 100.0)


static func tick(dt: float) -> void:
	if not Orgs.is_rogue():
		return
	var t = trail()
	if t > 0.0:
		Orgs.flags()["trail"] = maxf(0.0, t - dt / 45.0)   # dakikada ~1,3 soğur
	if t >= 60.0 and not _hot:
		_hot = true
		Orgs._hunter_next = minf(Orgs._hunter_next, Orgs._hunter_t + 150.0)
		Hud.msg("İzlerin birikti: köyün iz sürücüleri kokunu aldı.", Color(1, 0.6, 0.5), 6.0)
	elif t < 40.0:
		_hot = false


## Kaçak av: daimyō'nun korusunda avlan, eti kara kasaba sat; korucu yakalarsa kese ya da kılıç
static func job_poach(rk: String) -> Dictionary:
	var camp = Missions._near_spot(_hide(), 350.0, 650.0)
	var b = Missions._npc("kasap", ["Kara Kasap Dengo", "Kara Kasap Shikazō", "Kara Kasap Inokichi"].pick_random(), "merchant")
	var k = Missions._npc("korucu", ["Korucu Yahei", "Korucu Sandayū", "Korucu Matabei"].pick_random(), "ninja")
	var cost = int({"C": 120, "B": 300, "A": 700, "S": 1500}.get(rk, 120))
	return _base(rk, "poach").merged({"title": "Kaçak Av",
		"brief": "Bu koru Daimyō'nun; içinde avlanmak yasak, eti de o yüzden pahalı. Kara kasap kampını kurmuş, av bekliyor: iki hayvan vur, omuzla, askısına as. Korucu dolaşıyor; askıda eti görürse hesap sorar.",
		"steps": [
			{"kind": "talk", "at": camp, "npc": b, "busy": "fold", "site": "hunt_camp", "text": "Kara kasapla kampında konuş.", "say": "Daimyō'nun geyiği köylünün geyiğinden yağlıdır; kimse dokunmuyor çünkü. İki tane getir, askıya as. Koşma, hayvan ayak sesini duyar; korucu da duyar."},
			{"kind": "points", "at": Missions._near_spot(camp, 45, 70), "n": 2, "work": "hunt", "label": "[F] Avı askıya as", "text": "Koruda avlan, avı omuzla ve askıya as (2)."},
			{"kind": "talk", "at": Missions._near_spot(camp, 6, 9), "npc": k, "from": Missions._near_spot(camp, 34, 44), "text": "Korucu geliyor: onunla konuş.", "say": "Kıpırdama! Bu askıdaki Daimyō'nun malı. Koruda av yasak, cezası el kesmek. Kimsin sen?",
				"choices": [
					{"label": "Şu keseyi al, bugün koruyu gezmedin. (%d Ryō)" % cost, "cost": cost, "pass_flag": "passed", "reply": "...Bu yıl sayım eksik çıkacak demek. Bir daha buraya gelme.", "reply_bad": "Bu bozuklukla mı? Ellerini uzat, bağlayacağım."},
					{"label": "Koru kimin, onu ok söyler.", "fight": true, "reply_bad": "Kaçak avcı! Borum nerede... Buraya, buraya!"}]},
			{"kind": "kill", "at": camp, "at_npc": "korucu", "enemy": "samurai", "n": _n(rk), "ename": "Korucu", "skip_if": "passed", "text": "Korucuyu savuştur."},
			{"kind": "talk", "npc_id": "kasap", "pay": "pouch", "setup": "traces", "text": "Kara kasaptan paranı al.", "say": "İkisi de yağlı. Derisini de alırım. Al paranı; beni tanımıyorsun, ben de seni."}]})


## Mal okutma: barakadaki sandık ve çuvalları takasçıya sat (örnek sandığı omzunda götür)
static func job_fence() -> Dictionary:
	var l = RogueHut.loot()
	var total = int(l.get("chest", 0)) * CHEST_RYO + int(l.get("sack", 0)) * SACK_RYO
	var hut: Array = RogueHut.d()["at"]
	var meet = Missions._near_spot(hut, 300.0, 500.0)
	var f = Missions._npc("takasci", ["Takasçı Zenigata", "Takasçı Kuroemon", "Takasçı Fukusuke"].pick_random(), "merchant")
	return _base("C", "fence").merged({"title": "Malı Okut", "no_pay": true,
		"brief": "Barakanda %d sandık, %d çuval çalıntı mal duruyor; durdukça iz, satıldıkça para. Takasçı ormanda bekliyor: bir sandığı örnek diye omzunda götür, beğenirse hepsine %d Ryō sayar, gerisini gece adamları alır." % [int(l.get("chest", 0)), int(l.get("sack", 0)), total],
		"steps": [
			{"kind": "points", "at": hut, "n": 1, "work": "haul", "label": "[F] Örnek sandığı omuzla", "name": "Barakan", "text": "Barakandan örnek sandığı omuzla (1)."},
			{"kind": "talk", "at": meet, "npc": f, "busy": "fold", "on_ok": "fence", "text": "Sandığı takasçıya götür.", "say": "Mührü Daimyō'nun... Güzel. Mühür ne kadar büyükse soran o kadar az olur. İndir şunu, bir bakayım."}]})


static func _hide() -> Array:
	Orgs.hideout_pos()   # yeri henüz seçilmediyse seçer
	return Orgs.flags().get("hideout", [0, 0])


static func _back() -> Dictionary:
	return {"kind": "goto", "at": _hide(), "r": 14.0, "name": "Kaçak Sığınağı", "setup": "traces", "text": "Sığınağa dön (istersen önce olay yerindeki izlerini sil)."}


static func _base(rk: String, kind: String) -> Dictionary:
	return {"rank": rk, "village": BOARD, "giver": "Yeraltı Simsarı", "hook": "RogueJobs.done", "rjob": kind}


static func _n(rk: String) -> int:
	return int({"C": 2, "B": 3, "A": 4, "S": 5}.get(rk, 2))


## Pano: rütbene açık işler + dünyadaki olaylardan doğanlar
static func board(refresh := false) -> Array:
	var M = Missions
	var now = Time.get_ticks_msec()
	var stamp = hash(_deserters().map(func(x): return x["id"]))
	if not refresh and M._boards.has(BOARD) and now - int(M._boards[BOARD]["t"]) < 600000 and int(M._boards[BOARD].get("stamp", 0)) == stamp and int(M._boards[BOARD].get("rr", -1)) == Orgs.rogue_rank():
		return M._boards[BOARD]["list"]
	var top = "CBAS".find(String(Orgs.ROGUE_RANKS[Orgs.rogue_rank()][2]))
	var ranks = []
	for i in top + 1:
		ranks.append("CBAS"[i])
	var out = []
	if RogueHut.state() in ["", "burnt"]:
		out.append(job_hut())
	elif int(RogueHut.loot().get("chest", 0)) + int(RogueHut.loot().get("sack", 0)) > 0:
		out.append(job_fence())
	for inc in _deserters():
		var dm = _job_deserter(inc)
		if not dm.is_empty():
			out.append(dm)
	var kinds = ["heist", "smuggle", "jail", "decoy", "poach", "suikast", "harac"]
	kinds.shuffle()
	kinds = kinds.slice(0, 5)
	for i in kinds.size():
		# en yüksek rütbeden hep bir iş olsun, kalanı rütbelere dağılsın
		var rk: String = ranks[ranks.size() - 1] if i == 0 else ranks[randi() % ranks.size()]
		var j = {}
		match String(kinds[i]):
			"heist":
				j = job_heist(rk)
			"smuggle":
				j = job_smuggle(rk)
			"jail":
				j = job_jail(rk)
			"decoy":
				j = job_decoy(rk)
			"poach":
				j = job_poach(rk)
			_:
				j = Orgs._rogue_job(rk, String(kinds[i]))
				j["hook"] = "RogueJobs.done"
		if not j.is_empty():
			out.append(j)
	for m in out:
		M._board_seq += 1
		m["id"] = "b%d" % M._board_seq
		m["objectives"] = m["steps"].map(func(x): return x["text"])
		var rw: Array = M.REWARD[m["rank"]]
		m["rewards"] = {"ryo": rw[0], "xp": rw[1], "gear_chance": M.GEAR_CHANCE[m["rank"]], "rep": M.REP_GAIN[m["rank"]]}
		if String(m.get("rjob", "")) == "fence":
			m["rewards"] = {"ryo": 0, "xp": rw[1], "gear_chance": 0.0, "rep": 0}   # para takasçının saydığıdır
	M._boards[BOARD] = {"t": now, "list": out, "rank": int(Game.profile["rank"]), "ranks": ranks, "stamp": stamp, "rr": Orgs.rogue_rank()}
	return out


static func _deserters() -> Array:
	return (WorldNews.D()["list"] as Array).filter(func(x): return String(x["kind"]) == "deserter" and String(x["state"]) == "open")


## Sığınağın çevresinde, köylerin dışında bir yol noktası (dünya koordinatı); yoksa ZERO
static func road_spot(dmin: float, dmax: float) -> Vector3:
	var c = Missions._w(_hide())
	var a0 = randf() * TAU
	for ring in 18:
		var rr = lerpf(dmin, dmax, ring / 17.0)
		var n = int(maxf(12.0, TAU * rr / 14.0))
		for k in n:
			var a = a0 + TAU * k / n
			var p = c + Vector3(cos(a), 0, sin(a)) * rr
			if Game.road_at(p.x, p.z) <= 0.0 or Game.terrain_height(p.x, p.z) < 0.4 or Game.in_village_wall(p.x, p.z):
				continue
			var mp = Game.to_map(p)
			var near_v = false
			for v in Game.world_info["villages"]:
				if mp.distance_to(Vector2(v["x"], v["y"])) < float(v["r"]) + 150.0:
					near_v = true
					break
			if near_v:
				continue
			# yolun ortasına otur
			var dir = MissionWork.road_dir(p)
			if dir == Vector3.ZERO:
				continue
			var side = Vector3(dir.z, 0, -dir.x)
			var lo := 0.0
			var hi := 0.0
			for s in range(1, 14):
				if Game.road_at(p.x + side.x * s, p.z + side.z * s) > 0.0:
					hi = s
				else:
					break
			for s in range(1, 14):
				if Game.road_at(p.x - side.x * s, p.z - side.z * s) > 0.0:
					lo = s
				else:
					break
			p += side * (hi - lo) * 0.5
			p.y = Game.ground_height(p.x, p.z)
			return p
	return Vector3.ZERO


static func _m(p: Vector3) -> Array:
	var mp = Game.to_map(p)
	return [mp.x, mp.y]


## Kervan soygunu: yola kütük çek, kervan durunca muhafızları indir, sandıkları zulaya taşı
static func job_heist(rk: String) -> Dictionary:
	var p = road_spot(350.0, 2400.0)
	if p == Vector3.ZERO:
		return {}
	var dir = MissionWork.road_dir(p)
	# kervan yolun öbür ucundan gelir: yol boyunca geriye yürü
	var from = p
	var d = dir
	for i in 11:
		var best = Vector3.ZERO
		for da in [0.0, 0.3, -0.3, 0.6, -0.6]:
			var q = from + d.rotated(Vector3.UP, da) * 6.0
			if Game.road_at(q.x, q.z) > 0.0:
				best = q
				break
		if best == Vector3.ZERO:
			break
		d = (best - from).normalized()
		from = best
	if from.distance_to(p) < 30.0:
		return {}
	var at = _m(p)
	return _base(rk, "heist").merged({"title": "Kervan Soygunu",
		"brief": "Daimyō'nun vergi kervanı bu yoldan geçecek: bir öküz arabası, bir kâhya, yanında muhafızlar. Yol kenarındaki devrik kütükleri yola çek ki araba dursun; çalılığın ardında bekle, durduklarında bas. Sandıkları sırtlayıp ormandaki oyuk kütüğe, zulaya taşı. Köy bunu duyacak; peşine takım salarlar.",
		"steps": [
			{"kind": "points", "at": at, "n": 2, "site": "ambush", "work": "block", "label": "[F] Kütüğü yola sürükle", "name": "Pusu Yeri", "text": "Kütükleri yola çek (2)."},
			{"kind": "kill", "at": _m(from), "enemy": "samurai", "n": _n(rk), "ename": "Kervan Muhafızı", "setup": "caravan", "name": "Vergi Kervanı", "text": "Kervan durunca muhafızları indir."},
			{"kind": "points", "at": at, "n": 2, "work": "stash", "label": "[F] Sandığı omuzla", "name": "Zula", "text": "Sandıkları zulaya taşı (2)."},
			_back()]})


## Kaçakçılık: malı küfeye yükle (istersen pirinçle ört), karakoldan geç, alıcıya teslim et
static func job_smuggle(rk: String) -> Dictionary:
	var h = _hide()
	var load_at = _m(Orgs.hideout_spawn() + Vector3(3.5, 0, 2.0))
	var post = Missions._near_spot(h, 450.0, 800.0)
	var drop = Missions._near_spot(post, 250.0, 450.0)
	var guard = Missions._npc("nobetci", ["Karakol Çavuşu Tetsuo", "Karakol Çavuşu Monzaemon", "Karakol Çavuşu Hanbei"].pick_random(), "ninja")
	var buyer = Missions._npc("alici", ["Alıcı Kuromaru", "Alıcı Zeniba", "Alıcı Sukezō"].pick_random(), "merchant")
	var cost = int({"C": 150, "B": 400, "A": 900, "S": 2000}.get(rk, 150))
	return _base(rk, "smuggle").merged({"title": "Kaçak Mal",
		"brief": "Bir paket patlayıcı mühür sınırın öte yanındaki alıcıya gidecek. Yol üstünde karakol var; küfeni açtırırlar. Malın üstünü pirinç çuvalıyla örtersen arama temiz çıkar. Örtmezsen ya keseni açarsın ya kılıcını çekersin.",
		"steps": [
			{"kind": "points", "at": load_at, "n": 1, "site": "contraband", "work": "pack", "label": "[F] Malı küfeye yükle", "name": "Yük", "text": "Sığınağın önünde malı küfeye yükle (1)."},
			{"kind": "talk", "at": post, "npc": guard, "busy": "fold", "site": "checkpoint", "keep_load": true, "text": "Karakoldan geç.", "say": "Dur bakalım. Bu yoldan geçen her küfe açılır; emir böyle. Sırtındaki ne?",
				"choices": [
					{"label": "Pirinç. Aç bak.", "inspect": true, "pass_flag": "passed", "reply": "Pirinç... Köylüye benzemiyorsun ama mal temiz. Geç.", "reply_bad": "Bu ne?! Patlayıcı mühür! Kaçakçı bu, yakalayın!"},
					{"label": "Şu keseyi al, küfeyi görmedin. (%d Ryō)" % cost, "cost": cost, "pass_flag": "passed", "reply": "...Bugün yol sakin. Kimseyi görmedim. Yürü.", "reply_bad": "Boş keseyle mi rüşvet veriyorsun? Küfeyi indir, hemen!"},
					{"label": "Yolumdan çekil.", "fight": true, "reply_bad": "Demek öyle. Nöbetçiler, silah başına!"}]},
			{"kind": "kill", "at": post, "at_npc": "nobetci", "enemy": "samurai", "n": _n(rk), "ename": "Karakol Nöbetçisi", "skip_if": "passed", "text": "Karakol nöbetçilerini savuştur."},
			{"kind": "talk", "at": drop, "npc": buyer, "busy": "fold", "pay": "pouch", "text": "Malı alıcıya teslim et.", "say": "Geç kaldın sandım. Küfeyi şuraya indir... Mühürler kuru, sayı tam. Simsara selam söyle; bu da senin payın."},
			_back()]})


## Tutsak kurtarma: karakol kafesindeki kaçağı çıkar
static func job_jail(rk: String) -> Dictionary:
	var at = Missions._near_spot(_hide(), 500.0, 1000.0)
	var spec = _prisoner()
	var nm = String(spec.get("name", "Tutsak"))
	return _base(rk, "jail").merged({"title": "Kafesteki Kaçak",
		"brief": "%s yakalanmış; sabah köye götürülüp sorguya çekilecek. Konuşursa sığınağın yeri de gider. Karakol kafesinde tutuluyor: nöbetçileri indir, kilidi kır, iplerini kes, sığınağa getir." % nm,
		"steps": [
			{"kind": "kill", "at": at, "enemy": "samurai", "n": _n(rk), "ename": "Karakol Nöbetçisi", "site": "jail", "setup": "jail", "prisoner": spec, "name": "Karakol Kafesi", "text": "Kafesin nöbetçilerini indir."},
			{"kind": "points", "at": at, "n": 1, "work": "cage", "label": "[F] Kilidi kır", "name": "Karakol Kafesi", "text": "Kafesin kilidini kır (1)."},
			{"kind": "talk", "npc_id": "tutsak", "then": "follow", "text": "Tutsağın iplerini kes.", "say": "Sabaha sorgucu gelecekti... Bir gece daha dayanamazdım. Simsar mı yolladı seni? Çöz şu ipleri, gidelim."},
			{"kind": "goto", "at": _hide(), "r": 14.0, "name": "Kaçak Sığınağı", "followers": true, "setup": "traces", "text": "Tutsağı sığınağa götür (seni takip ediyor; istersen önce izlerini sil)."}]})


## Sahte işaret: sınır ateşini yak, depo nöbetçileri ateşe koşarken depoyu soy
static func job_decoy(rk: String) -> Dictionary:
	var beacon = Missions._near_spot(_hide(), 500.0, 900.0)
	var depot = Missions._near_spot(beacon, 200.0, 280.0)
	return _base(rk, "decoy").merged({"title": "Sahte İşaret",
		"brief": "Sınırdaki erzak deposunu iki nöbetçi bekliyor; dövüşmeden almanın yolu var. Yakındaki işaret ateşi yanarsa talimat gereği ikisi de ateşe koşar. Gece ateşi yak, nöbetçiler yoldan geçerken görünme, depo boş kalınca çuvalı sırtla.",
		"steps": [
			{"kind": "points", "at": beacon, "n": 1, "site": "beacon0", "work": "decoy", "setup": "decoy", "night": true, "label": "[F] İşaret ateşini yak", "name": "İşaret Ateşi", "text": "Gece işaret ateşini yak (1)."},
			{"kind": "points", "at": depot, "n": 1, "site": "depot", "work": "rob", "label": "[F] Erzak çuvalını omuzla", "name": "Erzak Deposu", "text": "Nöbetçiler ateşteyken depodan çuvalı al (1)."},
			_back()]})


## Kendi barakan: kaçak dülgerle birlikte sığınağın yakınına kur (yakıldıysa aynı yere yeniden)
static func job_hut() -> Dictionary:
	var h = RogueHut.d()
	var again = String(h.get("state", "")) == "burnt"
	var at = h["at"] if again else Missions._near_spot(_m(Orgs.hideout_spawn()), 32.0, 48.0)
	var u = Missions._npc("usta", "Kaçak Dülger Gonta", "merchant")
	return _base("C", "hut").merged({"title": "Barakayı Yeniden Kur" if again else "Kendi Barakan", "fixed_site": again,
		"brief": ("Av takımı barakanı kül etti. Temel taşları yerinde duruyor; dülger Gonta aynı yere yenisini çakmaya hazır. Tomrukları yine sen taşıyacaksın." if again else "Mağara kalabalık, malın gözü önünde. Simsar bir şey demez ama herkes sayar. Eski köyünde marangozluk yapmış bir kaçak var, Gonta: tomruğu sen taşırsan sığınağın yakınına sana ait bir baraka çakar. Çaldığın sandıklar ve çuvallar orada durur, içinde dinlenirsin."),
		"steps": [
			{"kind": "talk", "at": at, "npc": u, "busy": "fold", "site": "build_lot", "text": "Dülger Gonta ile baraka yerinde konuş.", "say": ("Yakmışlar ha. Direkleri ben dikmiştim, içim sızladı. Neyse; taş duruyor, kol duruyor. Tomruğu getir." if again else "Köyde ambar yapardım, şimdi kaçaklara baraka. Tahta aynı tahta. Temel taşlarını koydum; sen tomruğu omuzla, ben çakarım. Direk, kiriş, duvar, çatı.")},
			{"kind": "points", "at": at, "n": 4, "work": "build", "label": "[F] Tomruk getir", "text": "Barakayı kur: direk, kiriş, duvar, çatı (4)."},
			{"kind": "talk", "npc_id": "usta", "text": "Gonta ile işi bitir.", "say": "Oldu. Kapısı yok, kaçağın kapısı olmaz; duyunca çıkabilmelisin. Malını arka duvarın dibine diz. Bir de: büyük iş çevirdiğin gece burada uyuma. Köyün iz sürücüleri dumanı sever."}]})


## Kafesteki kişi: dünyada gerçekten yaşayan bir kaçak varsa o; yoksa adsız bir yeraltı adamı
static func _prisoner() -> Dictionary:
	var c = []
	var all = WorldPeople.all()
	for k in (all.keys() if all is Dictionary else range((all as Array).size())):
		var p = all[k]
		if p is Dictionary and WorldPeople.alive(p) and WorldPeople.is_rogue(p) and not p.get("missing", false):
			c.append(p)
	if not c.is_empty():
		var p2: Dictionary = c.pick_random()
		var sp = WorldNews._person_npc("tutsak", p2)
		sp["person"] = String(p2["id"])
		return sp
	return Missions._npc("tutsak", ["Kaçak Jūbei", "Kaçak Okiku", "Kaçak Rokusuke"].pick_random(), "civ")


## Dünyadan doğan iş: köyünden yeni kaçan ninjayı köyün takımından önce bul, sığınağa getir
static func _job_deserter(inc: Dictionary) -> Dictionary:
	var p = WorldPeople.get_p(String(inc["who"]))
	if p.is_empty() or not WorldPeople.alive(p) or not WorldPeople.is_rogue(p):
		return {}
	var vid = String(inc["vid"])
	var hide = Missions._near_spot(Missions._spot(vid, 60, 120), 450, 800)
	var spec = WorldNews._person_npc("firari", p)
	var nm = String(p["name"])
	return _base(WorldNews.rank_of(inc) if WorldNews.rank_of(inc) in ["C", "B", "A", "S"] else "C", "deserter").merged({"title": "Firariye El Uzat", "dyn": true, "news": String(inc["id"]),
		"brief": "%s dün gece %s köyünden kaçtı. Köy peşine iz süren bir takım saldı; önce onlar bulursa işi biter. Önce sen bul, sığınağa getir: simsar yeni kaçağa iş verir, sana da pay." % [nm, WorldPeople.vname(vid)],
		"steps": [
			{"kind": "talk", "at": hide, "npc": spec, "then": "follow", "text": "%s köyün takımından önce bul." % WorldNews.sfx(nm, "i"), "say": "Yaklaşma! ...Bandın çizik. Sen de onlardansın. Köpeklerin sesini duyuyorum, iz sürücüler yakında. Gidecek bir yer biliyor musun?"},
			{"kind": "goto", "at": _hide(), "r": 14.0, "name": "Kaçak Sığınağı", "followers": true, "text": "Firariyi sığınağa götür (seni takip ediyor)."}]})


## Kaçak işi bitti: şöhret + dünyaya yansıması
static func done(m: Dictionary, ok: bool) -> void:
	var kind = String(m.get("rjob", ""))
	if kind == "hut":
		if ok and m.has("hut_at"):
			RogueHut.built(m["hut_at"])
			Hud.msg("Baraka artık senin. Çaldığın mallar burada durur; içinde dinlenebilirsin.", Color(0.8, 1, 0.8), 6.0)
		return
	if kind == "fence":
		return
	Orgs.rogue_job_done(m, ok)
	if not ok:
		return
	if kind == "fence":
		return
	# ganimet barakaya
	match kind:
		"heist":
			RogueHut.add_loot("chest", 2)
		"decoy":
			RogueHut.add_loot("sack", 1)
	# geride kalan iz: işin türü + nasıl yapıldığı - sildiğin izler; av takımı ve baraka baskını buna bakar
	var fl: Dictionary = m.get("flags", {})
	var base = float(TRAIL_BASE.get(kind, 20))
	if fl.get("detected", false):
		base += 25.0
	if kind in ["smuggle", "poach"] and not fl.get("passed", false):
		base += 28.0   # dövüşerek geçtin: yerde nöbetçi var
	var wiped = int(fl.get("wiped", 0))
	var left = maxf(0.0, base - wiped * 13.0)
	add_trail(left)
	if left > 0.0 or wiped > 0:
		Hud.msg("Geride bıraktığın iz: +%d%s  •  toplam iz %d/100" % [int(left), (" (%d iz sildin)" % wiped) if wiped > 0 else "", int(trail())], Color(1, 0.8, 0.6), 6.0)
	RogueHut.heat(clampf((trail() - 45.0) / 160.0, 0.0, 0.35))   # iz 60'ın altındaysa baraka bulunmaz; 60'ta ~%9, 100'de %34
	var me = String(Game.profile.get("name", "Bir kaçak"))
	var vid = String(Orgs.flags().get("rogue_from", Progress.home()))
	var vn = WorldPeople.vname(vid)
	match String(m.get("rjob", "")):
		"heist":
			# köy soygunu duyar: av takımı beklenenden erken yola çıkar
			WorldNews.headline("%s: Daimyō'nun vergi kervanı yolda soyuldu. Sandıklar kayıp; köy, kaçak %s için takım çıkardı." % [vn, me], Color(1, 0.6, 0.5))
		"smuggle":
			if not m.get("flags", {}).get("passed", false):
				WorldNews.headline("%s: sınır karakolu basıldı, nöbetçiler yerde bulundu. Kaçak mal sınırı geçti." % vn, Color(1, 0.6, 0.5))
		"decoy":
			WorldNews.headline("%s: sınır işaret ateşi boş yere yandı; nöbetçiler döndüğünde erzak deposu soyulmuştu." % vn, Color(1, 0.6, 0.5))
		"jail":
			WorldNews.headline("%s: karakol kafesi kırıldı, tutsak sorgudan önce kaçırıldı." % vn, Color(1, 0.6, 0.5))
		"deserter":
			var inc = WorldNews.find(String(m.get("news", "")))
			if not inc.is_empty():
				WorldNews._close(inc)
				var p = WorldPeople.get_p(String(inc["who"]))
				WorldNews.headline("%s: firari %s izini kaybettirdi. İz sürücüler eli boş döndü." % [WorldPeople.vname(String(inc["vid"])), String(p.get("name", "ninja"))], Color(1, 0.6, 0.5))
