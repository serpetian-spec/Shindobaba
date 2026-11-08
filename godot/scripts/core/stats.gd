class_name Stats
extends RefCounted
## Profil (sözlük) üzerinden türetilmiş değerler.


## Klan pasif bonusu (data/clans.json "bonus": hp, chakra düz; melee, jutsu, speed oran)
static func clan_bonus(p: Dictionary, key: String) -> float:
	return float(Data.clans.get(p.get("clan", "none"), {}).get("bonus", {}).get(key, 0.0))


# ------------------------------------------------------------------ yetenek ağacı (data/skills.json)
## Öğrenilen düğümlerin bir etkisinin toplamı (ör. "melee", "seal_speed", "leap")
## Yetenek ağacı kaldırıldı (2026-11-02): eski düğüm etkileri artık USTALIKTAN türer (yaptıkça gelişme) + Efsane Yolu bonusları
static func skill(p: Dictionary, key: String) -> float:
	var M = func(k: String) -> float: return Mastery.get_v(p, k)
	var v = 0.0
	match key:
		"guard": v = M.call("taijutsu") * 0.004
		"def": v = M.call("dayaniklilik") * 0.004
		"regen_chakra": v = M.call("chakra") * 0.01
		"regen_hp": v = M.call("dayaniklilik") * 0.01
		"poison_resist": v = M.call("dayaniklilik") * 0.004
		"wall_run", "leap": v = M.call("hiz") * 0.004
		"throw_dmg": v = M.call("kenjutsu") * 0.005
		"gen_resist", "sense", "stealth": v = M.call("chakra") * 0.004
		"gen_power": v = M.call("ninjutsu") * 0.004
		"combo": v = maxf(M.call("taijutsu"), M.call("kenjutsu")) * 0.002
	return v + LegendPaths.passive(p, key)


## Öğrenilen düğümler bu bayrağı açıyor mu (ör. "genjutsu", "gentle_fist", "elem2")
## Açılımlar: hikâye bayrakları (profile.skills: sage, gates, jinchuriki...) ya da ustalık eşiği (yaptıkça gelişme)
const UNLOCK_AT := {"kai": ["chakra", 20.0], "sensor": ["chakra", 35.0], "multi_throw": ["kenjutsu", 25.0], "genjutsu": ["ninjutsu", 30.0],
	"elem2": ["ninjutsu", 40.0], "elem3": ["ninjutsu", 75.0], "strong_fist": ["taijutsu", 40.0], "wire": ["kenjutsu", 30.0],
	"barrier": ["ninjutsu", 50.0], "shape": ["ninjutsu", 50.0], "scroll_store": ["ninjutsu", 20.0], "gen_reflect": ["ninjutsu", 60.0],
	"scalpel": ["chakra", 45.0], "mark_teleport": ["ninjutsu", 80.0], "byakugou": ["chakra", 90.0]}
static func has_unlock(p: Dictionary, flag: String) -> bool:
	if flag in p.get("skills", []):
		return true
	if flag == "gentle_fist":
		return String(p.get("clan", "")) == "hyuga" and Mastery.get_v(p, "taijutsu") >= 15.0
	var u = UNLOCK_AT.get(flag)
	return u != null and Mastery.get_v(p, u[0]) >= float(u[1])


## Element bonusu: el_main (ana doğa), el_all, el_<doğa>
static func element_bonus(p: Dictionary, el: String) -> float:
	if el == "":
		return 0.0
	var v = skill(p, "el_all") + skill(p, "el_" + el)
	var els: Array = p.get("elements", [])
	if not els.is_empty() and els[0] == el:
		v += skill(p, "el_main")
	return v


## Silah stili bonusu (w_<stil> + w_all)
static func weapon_bonus(p: Dictionary, style: String) -> float:
	return skill(p, "w_all") + skill(p, "w_" + style)


## Düğüm öğrenilebilir mi? "" = evet, değilse Türkçe sebep
static func skill_block(p: Dictionary, sid: String) -> String:
	var n = Data.skills.get("nodes", {}).get(sid)
	if n == null:
		return "Bilinmeyen yetenek"
	if sid in p.get("skills", []):
		return "Zaten öğrenildi"
	if int(p.get("level", 1)) < int(n["level"]):
		return "Ustalık gücü %d gerekli" % int(n["level"])
	if int(p.get("sp", 0)) < int(n["cost"]):
		return "%d yetenek puanı gerekli" % int(n["cost"])
	for r in n["req"]:
		if not r in p.get("skills", []):
			return "Önce: %s" % Data.skills["nodes"].get(r, {}).get("name", r)
	var need: Dictionary = n.get("need", {})
	if need.get("clanless", false) and String(p.get("clan", "none")) != "none":
		return "Yalnızca klansız ninjalar"
	if need.has("rank") and Gear.eff_rank(p) < int(need["rank"]):
		return "%s rütbesi gerekli" % Data.RANKS[mini(int(need["rank"]), Data.RANKS.size() - 1)]
	if need.get("eye", false) and p.get("look", {}).get("eye_r") == null and p.get("look", {}).get("eye_l") == null:
		return "Bir dōjutsu gözü gerekli"
	if need.has("clan_any") and not String(p.get("clan", "")) in need["clan_any"]:
		var ek = int(need.get("or_eye", 0))
		var has_eye = false
		for k in ["eye_r", "eye_l"]:
			var e = p.get("look", {}).get(k)
			if e != null and int(e.get("kind", 0)) == ek:
				has_eye = true
		if not has_eye:
			return "Klan şartı: %s" % ", ".join(need["clan_any"])
	if need.get("kg", false) and p.get("natures", []).is_empty() and not Data.clans.get(String(p.get("clan", "")), {}).has("kg_natures"):
		return "Bir kekkei genkai gerekli"
	return ""


## Öğren: puanı düşer, etkileri uygular. elem2/elem3 için doğa seçimi çağıranın işidir.
static func learn_skill(p: Dictionary, sid: String) -> bool:
	if skill_block(p, sid) != "":
		return false
	p["sp"] = int(p["sp"]) - int(Data.skills["nodes"][sid]["cost"])
	p["skills"].append(sid)
	return true


## Sıfırlama: ağaç düğümlerinin puanı geri verilir (sennin, jinchūriki gibi hikâye bayrakları kalır)
static func respec(p: Dictionary) -> int:
	var nodes: Dictionary = Data.skills.get("nodes", {})
	var back = 0
	var keep = []
	for sid in p.get("skills", []):
		if nodes.has(sid) and not sid in ["elem2", "elem3", "genjutsu"]:
			back += int(nodes[sid]["cost"])
		else:
			keep.append(sid)
	p["skills"] = keep
	p["sp"] = int(p.get("sp", 0)) + back
	return back


## Dükkân fiyatı (Pazarlıkçı, Tüccar Dostu, Diplomat): en fazla %35 indirim
## Kekkei genkai doğaları (kg düğümü bunlara güç verir)
const KG_NATURES := ["mokuton", "hyoton", "yoton", "futton", "ranton", "shakuton", "bakuton", "jiton", "shoton", "jinton", "jinton_swift", "koton"]


## Oyuncu kaynaklı jutsunun kategori/doğa çarpanı (genjutsu, fūinjutsu, kekkei genkai)
static func jutsu_cat_mult(p: Dictionary, category: String, el: String) -> float:
	var m = 1.0
	if category == "genjutsu":
		m += skill(p, "gen_power")
	if category == "fuinjutsu":
		m += skill(p, "fuin")
	if el in KG_NATURES:
		m += skill(p, "kg")
	return m


## Algılama yarıçapı (minimap/pusula düşman gösterimi): temel 70 m
static func sense_radius(p: Dictionary) -> float:
	if has_unlock(p, "sensor"):
		return 600.0
	return 70.0 * (1.0 + skill(p, "sense") * 4.0)


## Sarf malzemesi istif sınırı: merhem/hap 10, atılabilir 40; "carry" ile artar
static func carry_cap(p: Dictionary, id: String) -> int:
	var base = 40 if id in ["kunai", "shuriken", "senbon"] else (20 if id in ["tag", "smoke"] else 10)
	return int(base * (1.0 + skill(p, "carry")))


static func price(base: int) -> int:
	return int(round(base * clampf(1.0 + skill(Game.profile, "shop"), 0.65, 1.0)))


## Ninja can eğrisi (NPC ninjalarla ORTAK): Güç/seviye L olan bir ninjanın tabanı. Sınav rakipleri ve köy ninjaları
## (events._rival_enemy 180 + L*18, Enemy.setup x(0.75 + L*0.004)) bununla aynı; oyuncu da aynı kuralla — eskiden oyuncu
## 100 + dayanıklılık*8 ile aynı Güç'teki NPC'nin 1/3'ü kadar candaydı.
static func ninja_hp(lv: float) -> float:
	return (180.0 + lv * 18.0) * (0.75 + lv * 0.004)


## NPC ninja eğrisi (TEK KAYNAK): Güç L olan bir ninjanın canı ve gücü. Rol çarpanı yalnız elitler için küçük pay
## (köy muhafızı 1.1, köy jōnin takımı 1.2, ANBU/av-ninjası 1.35). Eskiden her kaynak kendi formülünü kullanıyordu:
## aynı rütbedeki yol jōnin'i ile köy jōnin'i arasında 3-4 kat fark vardı (biri çok kolay, öteki kesilemiyordu).
## Can: Enemy.setup ninja türlerinde ayrıca x(0.75 + L*0.004) uygular (oyuncunun ninja_hp'siyle aynı eğri).
static func npc_ninja(a: Dictionary, lv: int, role := 1.0) -> void:
	a["level"] = lv
	a["hp"] = (180.0 + lv * 18.0) * role
	a["power"] = npc_power(lv) * lerpf(1.0, role, 0.5)
	a["npc_curve"] = true   # Enemy.setup ayrıca seviye çarpanı uygulamaz (oyuncuda karşılığı yok)


## Aynı Güç = aynı vuruş: Güç L'deki oyuncunun ustalık ortalaması (Mastery.power'ın tersi) -> oyuncunun hasar çarpanı
## (1 + ustalık x 0.045). Eskiden NPC Güç'le doğrusal (1.3 + L x 0.035) ve üstüne x(1 + L x 0.003) "yetenek ağacı"
## çarpanı alıyordu; oyuncunun yetenek puanları hasara bir şey katmadığı için aynı Güç'te NPC %27 (Güç 60) .. %13 (Güç 100) sert vuruyordu.
static func npc_power(lv: float) -> float:
	var avg = 100.0 * pow(maxf(lv, 1.0) / 100.0, 1.0 / 0.7)
	return 1.0 + avg * 0.045


## [C] chakra toplama hızı (/sn): chakra ustalığıyla büyür — eskiden hep 32/sn (ustalık 50'de havuz 430: 13 sn); şimdi
## ustalık 50'de 80/sn (~5 sn), havuz büyüdükçe doldurma süresi kısalır (gelişim hissedilsin)
static func charge_rate(p: Dictionary) -> float:
	return 32.0 * (1.0 + Mastery.get_v(p, "chakra") * 0.03)


static func max_hp(p: Dictionary) -> float:
	var v = ninja_hp(float(Mastery.power(p))) + Mastery.get_v(p, "dayaniklilik") * 8.0   # Güç tabanı (NPC ile aynı) + dayanıklılık idmanı
	return v + Gear.stat(p, "hp") + clan_bonus(p, "hp") + skill(p, "hp")


## Stamina (beden gücü): taijutsu chakra değil stamina harcar (anime: taijutsu chakrasız beden tekniği).
## Dayanıklılık ve taijutsu ustalığıyla büyür (yaptıkça gelişme), ekipman "stamina" ekleyebilir
static func max_stamina(p: Dictionary) -> float:
	return 100.0 + Mastery.get_v(p, "dayaniklilik") * 6.0 + Mastery.get_v(p, "taijutsu") * 2.0 + Gear.stat(p, "stamina")


## Taijutsu stamina bedeli (oyuncu + NPC ortak): verideki maliyet x2.5 — eskiden 14-22 stamina, 5-7 sn beklemede
## stamina tamamen doluyordu (neredeyse bedava). Dolu barla art arda 2-3 teknik.
const TAI_STAMINA := 2.5
static func tai_stamina_cost(j: Dictionary) -> float:
	return float(j.get("cost", 0)) * TAI_STAMINA


static func is_taijutsu(j: Dictionary) -> bool:
	return String(j.get("category", "")) == "taijutsu"


static func max_chakra(p: Dictionary) -> float:
	var v = 80.0 + Mastery.get_v(p, "chakra") * 7.0   # chakra kontrolü ustalığı
	return v + Gear.stat(p, "chakra") + clan_bonus(p, "chakra") + skill(p, "chakra")


static func melee_mult(p: Dictionary) -> float:
	# yumruk taijutsu, silah kenjutsu ustalığı
	var armed = String(Gear.weapon(p).get("style", "fist")) != "fist" and bool(p.get("weapon_drawn", false))
	# ustalık başına %4.5: aynı Güç'teki NPC'nin vuruş eğrisiyle (1.3 + Güç x 0.035) eşit — eskiden %2.5 ile aynı Güç'teki
	# NPC oyuncudan %50 sert vuruyordu, ustalık kasmak hissedilmiyordu (ustalık 50 -> x3.25, NPC Güç 62 -> x3.47)
	var m = 1.0 + Mastery.get_v(p, "kenjutsu" if armed else "taijutsu") * 0.045
	m += skill(p, "melee")
	m += clan_bonus(p, "melee")
	m *= Buffs.mod("melee") * (1.0 + Gear.stat(p, "melee") * 0.6)
	return m


static func jutsu_mult(p: Dictionary, branch := "ninjutsu") -> float:
	# tekniğin kendi dalının ustalığı (genjutsu, fūinjutsu, iryō, senjutsu, kuchiyose, kenjutsu, taijutsu); ninjutsunun yarısı taban
	var mv = Mastery.get_v(p, "ninjutsu")
	if branch != "ninjutsu":
		mv = maxf(Mastery.get_v(p, branch), mv * 0.5)
	var m = 1.0 + mv * 0.045   # yakın dövüşle aynı eğri (NPC gücüyle eşit)
	m += skill(p, "jutsu")
	m += clan_bonus(p, "jutsu")
	m *= Buffs.mod("jutsu")
	return m
