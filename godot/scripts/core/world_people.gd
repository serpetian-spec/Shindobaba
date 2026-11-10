class_name WorldPeople
extends Node
## Dünya nüfusu (kullanıcı 2026-11-11: "oyun spontane gelişmeli; Bingo Book'taki karakterler bile aynı geliyor").
## Her köyde kalıcı ninjalar yaşar: adı, klanı, kan soyu, element(ler)i, rütbesi, Güç'ü, gözü, öğrendiği jutsular, hayat kaydı.
## Oyuncudan bağımsız zamanla gelişirler (antrenman, terfi, görev, kayıp, uyanış, kaçış). Bingo Kitabı'nın kaçakları zar değil,
## bu insanlardan çıkar: kaçışın sebebi ve suçları gerçekten yaşadıklarıdır; yetenekleri de kendi öğrendikleri.
## Kayıt: Game.profile["world_people"] = {"seq", "list": {id: kişi}, "init": bool}

const MAJOR := ["konoha", "suna", "kiri", "kumo", "iwa"]
const MINOR := ["ame", "kusa", "taki", "oto"]
const PER_MAJOR := 22
const PER_MINOR := 8
const TICK := 90.0            # sn (gerçek zaman) — her turda birkaç kişinin hayatında bir şey olur
const EVENTS_PER_TICK := 4
const ELS := ["katon", "suiton", "fuuton", "doton", "raiton"]
const VIL_EL := {"konoha": "katon", "suna": "fuuton", "kiri": "suiton", "kumo": "raiton", "iwa": "doton", "ame": "suiton", "kusa": "doton", "taki": "suiton", "oto": "fuuton"}
## rütbe -> Güç aralığı (dünya ölçeği: Güç 60 = başı-ortası, jōnin ~90, Kage 200)
const RANK_LV := [[12, 40], [35, 75], [75, 125], [120, 175]]
const RANK_NAMES := ["Genin", "Chūnin", "Jōnin", "Elit Jōnin"]
const BIG_CLANS := {"uchiha": 3.0, "hyuga": 3.0, "nara": 2.0, "akimichi": 2.0, "yamanaka": 2.0, "inuzuka": 2.0, "aburame": 2.0, "sarutobi": 1.5,
	"hozuki": 2.0, "yuki": 1.5, "kaguya": 1.5, "yotsuki": 2.0, "kamizuru": 1.5, "sabaku": 1.0}
const ALIAS := ["Kızıl Tilki", "Sessiz Çekiç", "Sis Hayaleti", "Kemik Kıran", "Gece Kargası", "Kum Akrebi", "Fırtına Dişi", "Zehirli Gül",
	"Kara Kanat", "Yalnız Kurt", "Kırık Bant", "Dönek", "Kayıp Gölge", "Gümüş Diken", "Kanlı Ay", "Kül Yürüyüşçüsü", "Taş Kalp", "Ölü Rüzgâr"]

var _t := 20.0


static func data() -> Dictionary:
	var pr: Dictionary = Game.profile
	if not pr.has("world_people") or not pr["world_people"] is Dictionary:
		pr["world_people"] = {"seq": 0, "list": {}, "init": false}
	return pr["world_people"]


static func all() -> Dictionary:
	return data()["list"]


static func get_p(id: String) -> Dictionary:
	return all().get(id, {})


func _process(dt: float) -> void:
	if Game.profile.is_empty() or Game.world_info.is_empty():
		return
	var d = data()
	if not d.get("init", false):
		populate()
		return
	if Game.paused:
		return
	_t -= dt
	if _t > 0.0:
		return
	_t = TICK
	world_tick()


# ------------------------------------------------------------------ nüfus
static func populate() -> void:
	var d = data()
	d["init"] = true
	for v in Game.world_info.get("villages", []):
		var vid = String(v["id"])
		var n = PER_MAJOR if vid in MAJOR else (PER_MINOR if vid in MINOR else 0)
		for i in n:
			var r = randf()
			var rank = 0 if r < 0.38 else (1 if r < 0.74 else (2 if r < 0.95 else 3))
			new_person(vid, rank)


## Köyde doğup büyümüş biri: klanı köyün klanlarından (ya da klansız), kan soyu köyün soylarından nadiren, elementi köyün eğilimiyle
static func new_person(vid: String, rank: int) -> Dictionary:
	var d = data()
	d["seq"] = int(d["seq"]) + 1
	var id = "w%d" % int(d["seq"])
	var female = randf() < 0.4
	var clan = ""
	if randf() < 0.42:
		var cands = []
		for c in Data.clans:
			if c != "none" and not c in Progress.UNPLAYABLE_CLANS and vid in Data.clans[c].get("villages", []):
				cands.append(c)
		if not cands.is_empty():
			# kanonda kalabalık klanlar (Uchiha, Hyūga, Nara, Akimichi...) daha sık; küçük klanlar nadir
			var wsum = 0.0
			for c in cands:
				wsum += float(BIG_CLANS.get(c, 1.0))
			var rr = randf() * wsum
			for c in cands:
				rr -= float(BIG_CLANS.get(c, 1.0))
				if rr <= 0.0:
					clan = String(c)
					break
	var nat = []
	for k in KgPaths.SOY:
		var s: Dictionary = KgPaths.SOY[k]
		if vid in s.get("villages", []) and randf() < 0.07:   # klansız kan soyu: köyünde nadiren doğar (Darui, Kurotsuchi, Pakura gibi)
			nat.append(String(s["nature"]))
			break
	var el = String(VIL_EL.get(vid, ELS.pick_random())) if randf() < 0.5 else String(ELS.pick_random())
	var lr: Array = RANK_LV[rank]
	var lv = randi_range(int(lr[0]), int(lr[1]))
	var given = (ClanWorld.GIVEN_F if female else ClanWorld.GIVEN_M).pick_random()
	var name = ClanWorld.person_name(clan, female) if clan != "" else "%s %s" % [String(Missions.BB_FAMILY.pick_random()), given]
	var p = {"id": id, "name": name, "female": female, "village": vid, "clan": clan, "nat": nat, "els": [el], "rank": rank, "level": lv,
		"eye": [0, 0], "jutsu": [], "status": "", "log": [], "born": Time.get_unix_time_from_system(), "close": "", "loyalty": randi_range(25, 95)}
	# klan gözü (Uchiha'nın hepsinde değil: uyanmamış olanlar var)
	var ek = int(ClanWorld.EYE_KIND.get(clan, 0))
	if ek == 2 or ek == 3:
		p["eye"] = [ek, clampi(1 + lv / 50, 1, 3)]
	elif ek == 1 and randf() < (0.35 + rank * 0.18):
		p["eye"] = [1, clampi(1 + lv / 45, 1, 3)]
	if lv >= 90 and randf() < 0.45:
		_second_element(p)
	p["look"] = _make_look(p)
	_learn(p)
	all()[id] = p
	# köyde biri ona yakın olur (takım arkadaşı/kardeş): kayıp ve uyanış olayları bu bağla işler
	var same = all().keys().filter(func(k): return k != id and String(all()[k]["village"]) == vid and String(all()[k].get("close", "")) == "")
	if not same.is_empty() and randf() < 0.6:
		var o = String(same.pick_random())
		p["close"] = o
		all()[o]["close"] = id
	return p


static func _second_element(p: Dictionary) -> void:
	var els: Array = p["els"]
	var rest = ELS.filter(func(e): return not e in els)
	if not rest.is_empty():
		els.append(rest.pick_random())


static func _make_look(p: Dictionary) -> Dictionary:
	var vid = String(p["village"])
	var arch = ["genin", "chunin", "jonin", "jonin"][int(p["rank"])]
	var lk: Dictionary
	if String(p["clan"]) != "":
		lk = ClanWorld.clan_look(String(p["clan"]), arch, vid, bool(p["female"]))
	else:
		lk = CharacterModel.default_look()
		lk.merge(Outfits.roll(arch, vid), true)
		lk["hair"] = [Color(0.08, 0.07, 0.07), Color(0.3, 0.2, 0.12), Color(0.55, 0.35, 0.18), Color(0.85, 0.7, 0.4), Color(0.55, 0.55, 0.6), Color(0.6, 0.15, 0.12), Color(0.2, 0.25, 0.4)].pick_random()
	lk["gender"] = "f" if p["female"] else "m"
	var hs = CharacterModel.hair_styles_for(lk["gender"]).filter(func(h): return CharacterModel.AnimeHair.has(h))
	if not hs.is_empty():
		lk["hair_style"] = hs.pick_random()   # kalıcı kimlik: her karşılaşmada aynı saç
	lk["face_id"] = randi() % 64
	lk["village"] = vid
	lk.erase("age")
	return _ser(lk)


static func _ser(lk: Dictionary) -> Dictionary:
	var o = {}
	for k in lk:
		var v = lk[k]
		o[k] = Missions._hex(v) if v is Color else v
	return o


static func look_of(p: Dictionary) -> Dictionary:
	var lk = Missions._bb_look({"look": p.get("look", {})})
	lk["keep_hair"] = true
	return lk


## Öğrendikleri: klan teknikleri, kan soyu, element(ler)inden Güç'üne yakışan rütbede jutsular (sıradan havuzla sınırlı değil:
## S rütbe, iki element, kan soyu jutsuları dahil) — önceki bildiklerini unutmaz
static func _learn(p: Dictionary) -> void:
	var lv = int(p["level"])
	var cap = Enemy._lv_cap(lv) + (1 if lv >= 110 else 0)
	var js: Array = (p.get("jutsu", []) as Array).duplicate()
	if String(p["clan"]) != "":
		for j in ClanWorld.clan_jutsu(String(p["clan"]), lv, 2 + int(p["rank"])):
			if not j in js:
				js.append(j)
	for n in p.get("nat", []):
		var pool = []
		for id in Data.jutsu:
			var j = Data.jutsu[id]
			if j is Dictionary and (String(j.get("learn", "")) == "kg:" + String(n) or String(j.get("element", "")) == String(n)):
				if int(Enemy.RANK_I.get(String(j.get("canon_rank", "")), 2)) <= cap:
					pool.append(id)
		pool.shuffle()
		for id in pool.slice(0, 1 + int(p["rank"])):
			if not id in js:
				js.append(id)
	for el in p["els"]:
		for id in Enemy.auto_jutsu("rogue", String(el), lv).slice(0, 2):
			if not id in js:
				js.append(id)
	# en güçlüler önde, en fazla 7
	js.sort_custom(func(a, b): return int(Enemy.RANK_I.get(String(Data.jutsu.get(a, {}).get("canon_rank", "")), 0)) > int(Enemy.RANK_I.get(String(Data.jutsu.get(b, {}).get("canon_rank", "")), 0)))
	p["jutsu"] = js.slice(0, 7)


static func log_event(p: Dictionary, text: String) -> void:
	var lg: Array = p["log"]
	lg.append(text)
	if lg.size() > 12:
		lg.pop_front()


static func alive(p: Dictionary) -> bool:
	return String(p.get("status", "")) != "öldü"


static func is_rogue(p: Dictionary) -> bool:
	return String(p.get("status", "")) == "kaçak"


static func vname(vid: String) -> String:
	return String(Game.village(vid).get("name", vid))


# ------------------------------------------------------------------ dünya döngüsü
func world_tick() -> void:
	var ids = all().keys().filter(func(k): return alive(all()[k]))
	if ids.is_empty():
		return
	ids.shuffle()
	for id in ids.slice(0, EVENTS_PER_TICK):
		_life(all()[id])
	# nüfus azalırsa köyde yeni nesil yetişir (akademiden mezun genin)
	for vid in MAJOR:
		var n = all().values().filter(func(p): return String(p["village"]) == vid and alive(p) and not is_rogue(p)).size()
		if n < PER_MAJOR - 4 and not Game.village(vid).is_empty():
			var np = new_person(vid, 0)
			log_event(np, "Akademiden mezun oldu")


static func _life(p: Dictionary) -> void:
	var r = randf()
	var rank = int(p["rank"])
	if is_rogue(p):
		_rogue_life(p, r)
		return
	# antrenman: herkes zamanla güçlenir (Güç tavanı rütbesinin biraz üstü; elit jōnin Kage seviyesine yaklaşabilir)
	var cap = int(RANK_LV[rank][1]) + 25
	if int(p["level"]) < cap:
		p["level"] = mini(cap, int(p["level"]) + randi_range(1, 4))
	if r < 0.22 and rank < 3 and int(p["level"]) >= int(RANK_LV[rank + 1][0]):
		p["rank"] = rank + 1
		log_event(p, "%s oldu" % RANK_NAMES[rank + 1])
		p["look"] = _make_look_keep(p)
		_learn(p)
	elif r < 0.30:
		_learn(p)
		if int(p["level"]) >= 90 and (p["els"] as Array).size() < 2 and randf() < 0.3:
			_second_element(p)
			_learn(p)
			log_event(p, "İkinci doğasını uyandırdı (%s)" % ", ".join(p["els"]))
	elif r < 0.33:
		_die(p, "Bir görevden dönmedi")
	elif r < 0.33 + _defect_p(p):
		defect(p, _defect_reason(p))
	elif r < 0.45:
		log_event(p, ["Bir A-rütbe görevi tamamladı", "Sınırda bir çatışmadan sağ döndü", "Bir daimyo kervanını korudu", "Genin takımı eğitti"][randi() % 4])


static func _make_look_keep(p: Dictionary) -> Dictionary:
	# terfide kıyafet rütbesine göre değişir, kimlik (yüz, saç, ten) aynı kalır
	var old: Dictionary = p.get("look", {})
	var nw = _make_look(p)
	for k in ["gender", "hair", "hair_style", "skin", "eye", "face", "face_id", "beard", "face_mark"]:
		if old.has(k):
			nw[k] = old[k]
	return nw


static func _defect_p(p: Dictionary) -> float:
	var x = 0.012 + (0.05 if p.get("grief", false) else 0.0) + (0.03 if int(p.get("loyalty", 50)) < 35 else 0.0)
	return x


static func _defect_reason(p: Dictionary) -> String:
	if p.get("grief", false):
		return "Kaybının acısıyla köyüne sırt çevirdi"
	if int(p.get("loyalty", 50)) < 35:
		return "Köyün emirlerine itaat etmeyi reddetti"
	return ["Yasak bir parşömen için köyünü terk etti", "Güç peşinde köyünden kaçtı", "Bir görevde takımını bırakıp kaçtı"][randi() % 3]


## Ölüm: yakını yasa boğulur; Uchiha ise en yakınını kaybetmek Mangekyō'yu uyandırabilir (kanon şartı: Sharingan'ı tam açık olmalı)
static func _die(p: Dictionary, why: String) -> void:
	p["status"] = "öldü"
	log_event(p, why)
	var cid = String(p.get("close", ""))
	if cid == "" or not all().has(cid):
		return
	var c: Dictionary = all()[cid]
	if not alive(c):
		return
	c["grief"] = true
	log_event(c, "Yakını %s'yi kaybetti" % String(p["name"]))
	var eye: Array = c.get("eye", [0, 0])
	if int(eye[0]) == 1 and int(eye[1]) >= 3 and randf() < 0.6:
		c["eye"] = [4, 3]
		log_event(c, "%s'nin ölümüyle Mangekyō Sharingan'ı uyandı" % String(p["name"]))
		if randf() < 0.5:
			Hud.msg("Söylenti: %s köyünde bir Uchiha'nın gözleri değişmiş..." % vname(String(c["village"])), Color(0.95, 0.4, 0.4), 6.0)


## Kaçak hayatı: güçlenir, suç işler; suçları Bingo kaydına da yazılır
static func _rogue_life(p: Dictionary, r: float) -> void:
	p["level"] = mini(int(p["level"]) + randi_range(1, 5), 260)
	if r < 0.4:
		var near = String(Game.world_info["villages"].pick_random()["id"])
		var crime = ["%s yakınında bir kervanı soydu" % vname(near), "%s sınır karakoluna saldırdı" % vname(near), "%s'den bir ninjayı öldürdü" % vname(near),
			"%s'de bir yasak parşömenin izini sürdü" % vname(near)][randi() % 4]
		log_event(p, crime)
		var cr: Array = p.get("crimes", [])
		cr.append(crime)
		p["crimes"] = cr.slice(maxi(0, cr.size() - 5))
		var e = bingo_of(p)
		if not e.is_empty():
			(e["crimes"] as Array).append(crime)
			if (e["crimes"] as Array).size() > 5:
				(e["crimes"] as Array).pop_front()
			_sync_bingo(p, e)
	elif r < 0.55:
		_learn(p)
		var e2 = bingo_of(p)
		if not e2.is_empty():
			_sync_bingo(p, e2)


# ------------------------------------------------------------------ kaçış ve Bingo Kitabı
static func defect(p: Dictionary, why: String) -> Dictionary:
	if is_rogue(p) or not alive(p):
		return {}
	p["status"] = "kaçak"
	log_event(p, why)
	p["crimes"] = [why, "%s köyünden kaçtı" % vname(String(p["village"]))]
	var lk: Dictionary = p["look"]
	var rog = Outfits.roll("rogue", String(p["village"]))
	var keep = {}
	for k in ["gender", "hair", "hair_style", "skin", "eye", "face", "face_id", "beard", "face_mark"]:
		if lk.has(k):
			keep[k] = lk[k]
	var nl = CharacterModel.default_look()
	nl.merge(rog, true)
	nl = _ser(nl)
	nl.merge(keep, true)
	nl["band_style"] = "slashed"
	nl["vest"] = null
	nl["village"] = String(p["village"])
	p["look"] = nl
	p["alias"] = ALIAS.pick_random()
	var e = make_bingo(p)
	Missions._bingo()["list"].append(e)
	if randf() < 0.6:
		Hud.msg("Haber: %s köyünden %s kaçtı — Bingo Kitabı'nda «%s»" % [vname(String(p["village"])), String(p["name"]), String(p["alias"])], Color(1, 0.6, 0.5), 6.0)
	return e


static func rank_letter(lv: int) -> String:
	return "C" if lv < 70 else ("B" if lv < 120 else ("A" if lv < 175 else "S"))


static func make_bingo(p: Dictionary) -> Dictionary:
	var bb = Missions._bingo()
	var lv = int(p["level"])
	var rank = rank_letter(lv)
	var rd: Array = Missions.BB_RANKS[rank]
	var near: String = Game.world_info["villages"].pick_random()["id"]
	var hide = Missions._spot(near, 250, 1100)
	var e = {"id": int(bb["next"]), "name": String(p["name"]), "alias": String(p.get("alias", ALIAS.pick_random())), "village": String(p["village"]),
		"rank": rank, "bounty": int(randi_range(int(rd[0]), int(rd[1])) / 50) * 50, "crimes": [],
		"element": String((p["els"] as Array)[0]), "hide": hide, "area": [hide[0] + randf_range(-300, 300), hide[1] + randf_range(-300, 300)],
		"known": 450.0, "status": "alive", "tracked": false, "level": lv, "hp": 260.0 + lv * 24.0, "power": Stats.npc_power(lv),
		"escorts": int(rd[4]), "escort_kind": rd[5], "look": (p["look"] as Dictionary).duplicate(), "person_id": String(p["id"])}
	bb["next"] = int(bb["next"]) + 1
	# suçları: gerçekten yaptıkları (kaçış sebebi + kaçaklıkta işledikleri); kaçışın arka planı (yas) sebepte zaten var
	for line in (p.get("crimes", []) as Array).slice(-4):
		(e["crimes"] as Array).append(line)
	_sync_bingo(p, e)
	return e


## Bingo kaydı kişinin güncel hâlini taşır (Güç, jutsu, göz, klan, kan soyu)
static func _sync_bingo(p: Dictionary, e: Dictionary) -> void:
	var lv = int(p["level"])
	e["level"] = lv
	e["hp"] = 260.0 + lv * 24.0
	e["power"] = Stats.npc_power(lv)
	var rk = rank_letter(lv)
	if rk != String(e.get("rank", "C")):
		e["rank"] = rk
		var rd: Array = Missions.BB_RANKS[rk]
		e["bounty"] = int(randi_range(int(rd[0]), int(rd[1])) / 50) * 50
	e["jutsu"] = (p["jutsu"] as Array).duplicate()
	if (p.get("nat", []) as Array).size() > 0:
		e["nat"] = (p["nat"] as Array).duplicate()
	if String(p["clan"]) != "":
		e["clan"] = String(p["clan"])
	var eye: Array = p.get("eye", [0, 0])
	if int(eye[0]) > 0:
		e["eye"] = int(eye[0])


static func bingo_of(p: Dictionary) -> Dictionary:
	for e in Missions._bingo()["list"]:
		if String(e.get("person_id", "")) == String(p["id"]) and e["status"] == "alive":
			return e
	return {}


## Bingo Kitabı yeni bir ad istediğinde: kalıp kaçak yerine dünyadan gerçek biri. Henüz listede olmayan bir kaçak varsa o;
## yoksa köyünden kaçmaya en yatkın kişi (yaslı, sadakatsiz) şimdi kaçar. Kimse yoksa {} (eski kalıp devreye girer).
static func bingo_from_world(vid := "") -> Dictionary:
	if not data().get("init", false):
		return {}
	for id in all():
		var p: Dictionary = all()[id]
		if is_rogue(p) and alive(p) and bingo_of(p).is_empty() and (vid == "" or String(p["village"]) == vid):
			var e = make_bingo(p)
			Missions._bingo()["list"].append(e)
			return e
	var cands = all().values().filter(func(p): return alive(p) and not is_rogue(p) and int(p["rank"]) >= 1 and (vid == "" or String(p["village"]) == vid))
	if cands.is_empty():
		return {}
	cands.sort_custom(func(a, b): return (100 - int(a.get("loyalty", 50)) + (40 if a.get("grief", false) else 0)) > (100 - int(b.get("loyalty", 50)) + (40 if b.get("grief", false) else 0)))
	var pick: Dictionary = cands[randi() % mini(4, cands.size())]
	return defect(pick, _defect_reason(pick))


## Bingo hedefi öldürüldü: kişi de ölür (yakını yasa girer — o da kaçabilir, uyanabilir)
static func on_bingo_killed(e: Dictionary) -> void:
	var pid = String(e.get("person_id", ""))
	if pid == "" or not all().has(pid):
		return
	_die(all()[pid], "Bingo avcısı tarafından öldürüldü")


# ------------------------------------------------------------------ sahaya çıkış (köy takımı, düello, karşılaşma)
## Kişinin dövüş kalıbı: kendi Güç'ü, klanı, element(ler)i ve öğrendiği jutsular (AI eşitliği: aynı jutsu sistemi)
static func arch_of(p: Dictionary, outfit := "") -> Dictionary:
	var lv = int(p["level"])
	var a: Dictionary
	var vid = String(p["village"])
	if String(p["clan"]) != "":
		a = ClanWorld.make_enemy(String(p["clan"]), lv, {"outfit": outfit if outfit != "" else ("rogue" if is_rogue(p) else "chunin"), "village": vid, "female": bool(p["female"])})
	else:
		a = Enemy.archetype("rogue", 0)
		a["no_clan"] = true
	a["element"] = String((p["els"] as Array)[0])
	var js: Array = (p["jutsu"] as Array).filter(func(j): return Data.jutsu.has(j))
	if not js.is_empty():
		a["jutsu"] = js.slice(0, 6)
		a.erase("auto_jutsu")
	a["name"] = String(p["name"])
	a["respawn"] = false
	Stats.npc_ninja(a, lv)
	a["look"] = look_of(p)
	a["world_person"] = String(p["id"])
	return a


## Sahneye çıktıktan sonra: gözleri (Sharingan, uyanmış Mangekyō...) ve klan davranışı
static func after_spawn(e: Node, p: Dictionary) -> void:
	var eye: Array = p.get("eye", [0, 0])
	if String(p["clan"]) != "" or int(eye[0]) > 0:
		ClanWorld.after_spawn_enemy(e, String(p["clan"]), int(p["level"]), int(eye[0]))
	e.set_meta("world_person", String(p["id"]))


## Köy takımı için gerçek insanlar: jōnin hoca + 3 genin / chūnin üçlüsü (yoksa boş: eski üretim)
static func team_people(vid: String, chunin: bool, used: Dictionary) -> Array:
	if not data().get("init", false):
		return []
	var pool = all().values().filter(func(p): return String(p["village"]) == vid and alive(p) and not is_rogue(p) and not used.has(String(p["id"])))
	var out = []
	var need = [1, 1, 1] if chunin else [2, 0, 0, 0]
	for rk in need:
		var c = pool.filter(func(p): return int(p["rank"]) == rk and not used.has(String(p["id"])))
		if c.is_empty():
			return []
		var p: Dictionary = c.pick_random()
		used[String(p["id"])] = true
		out.append(p)
	return out
