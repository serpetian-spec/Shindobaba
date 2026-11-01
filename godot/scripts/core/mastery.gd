class_name Mastery
extends RefCounted
## YAPTIKÇA GELİŞME (seviye sistemi yerine). profile["mastery"] = {anahtar: 0..100}.
## Her şey kullanılarak gelişir; azalan getiri (100'e yaklaştıkça yavaşlar). Görünen "seviye" yok:
## eski seviye kontrolleri (jutsu şartı, düşman ölçeği) ustalıklardan türeyen GÜÇ değerini (profile["level"]) kullanır.

const KEYS := ["ninjutsu", "taijutsu", "kenjutsu", "chakra", "dayaniklilik", "hiz"]
const NAMES := {"ninjutsu": "Ninjutsu", "taijutsu": "Taijutsu", "kenjutsu": "Kenjutsu", "chakra": "Chakra Kontrolü", "dayaniklilik": "Dayanıklılık", "hiz": "Hız"}
const SP_PER := 4.0   # her 4 toplam ustalık puanında 1 yetenek puanı


static func get_v(p: Dictionary, key: String) -> float:
	return float(p.get("mastery", {}).get(key, 0.0))


## Ustalık kazan: azalan getiri; tam puan eşiklerinde bildirim, toplamdan yetenek puanı, güç değeri güncellenir
static func gain(p: Dictionary, key: String, amount: float) -> void:
	if p.is_empty() or amount <= 0.0:
		return
	if not p.has("mastery"):
		p["mastery"] = {}
	var m: Dictionary = p["mastery"]
	var v = float(m.get(key, 0.0))
	if v >= 100.0:
		return
	amount *= 1.0 + Stats.skill(p, "xp")   # eski "tecrübe" yetenekleri ustalık hızına
	var nv = minf(100.0, v + amount * pow(1.0 - v / 100.0, 1.6) * 1.0)
	m[key] = nv
	if int(nv) > int(v):
		Hud.float_text("%s %d" % [NAMES.get(key, key), int(nv)], Color(0.6, 0.95, 1.0))
		Sfx.play("pickup", null, 1.3, 0.35)
		if int(nv) % 10 == 0:
			Hud.banner(NAMES.get(key, key).to_upper(), "Ustalık %d" % int(nv), Color(0.6, 0.95, 1.0))
	# yetenek puanı: toplam ustalıktan
	var tot = total(p)
	var earned = int(tot / SP_PER)
	var had = int(p.get("sp_earned", 0))
	if earned > had:
		p["sp"] = int(p.get("sp", 0)) + (earned - had)
		p["sp_earned"] = earned
		Hud.msg("+%d yetenek puanı  [Tab > Yetenekler]" % (earned - had), Color(1, 0.85, 0.35))
	var old_lv = int(p.get("level", 1))
	refresh_level(p)
	if int(p["level"]) != old_lv:
		Progress.on_power_changed()


static func total(p: Dictionary) -> float:
	var t = 0.0
	for k in KEYS:
		t += get_v(p, k)
	return t


## GÜÇ (eski seviyenin yerine geçen iç değer, 1..100): ninjutsu, en iyi dövüş dalı, chakra, dayanıklılık ortalaması
static func power(p: Dictionary) -> int:
	var fight = maxf(get_v(p, "taijutsu"), get_v(p, "kenjutsu"))
	return clampi(1 + int(round((get_v(p, "ninjutsu") + fight + get_v(p, "chakra") + get_v(p, "dayaniklilik")) / 4.0)), 1, 100)


static func refresh_level(p: Dictionary) -> void:
	p["level"] = power(p)
	p["xp"] = 0


## Ninjutsu yeterliliği: jutsunun rütbe şartına göre (j.level 1..100). "" = atabilir, "fail:x" = x olasılıkla mühür bozulur, aksi engel
static func cast_check(p: Dictionary, j: Dictionary) -> String:
	var cat = String(j.get("category", "ninjutsu"))
	if cat == "taijutsu" or String(j.get("virtual", "")) != "":
		return ""
	var need = float(j.get("level", 1))
	var nin = get_v(p, "ninjutsu")
	if need <= 3.0:
		return ""
	if nin < need * 0.55:
		return "Ninjutsu ustalığın yetersiz (%d / %d) — bu tekniği yapamazsın" % [int(nin), int(need)]
	if nin < need:
		return "fail:%.3f" % clampf((need - nin) / (need * 0.45), 0.05, 0.85)
	return ""


## Mühür hızı çarpanı (1 = normal yavaş ve okunur; usta ninjada 0.45'e kadar hızlanır)
static func seal_speed(p: Dictionary) -> float:
	return lerpf(1.35, 0.45, get_v(p, "ninjutsu") / 100.0)
