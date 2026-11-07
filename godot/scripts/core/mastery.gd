class_name Mastery
extends RefCounted
## YAPTIKÇA GELİŞME (seviye sistemi yerine). profile["mastery"] = {anahtar: 0..∞} — ÜST SINIR YOK.
## Her şey kullanılarak gelişir; azalan getiri (yükseldikçe yavaşlar ama hiç durmaz). Görünen "seviye" yok:
## eski seviye kontrolleri (jutsu şartı, düşman ölçeği) ustalıklardan türeyen GÜÇ değerini (profile["level"]) kullanır.

const KEYS := ["ninjutsu", "taijutsu", "kenjutsu", "chakra", "dayaniklilik", "hiz", "genjutsu", "fuinjutsu", "iryo", "senjutsu", "kuchiyose", "shurikenjutsu"]
const NAMES := {"ninjutsu": "Ninjutsu", "taijutsu": "Taijutsu", "kenjutsu": "Kenjutsu", "chakra": "Chakra Kontrolü", "dayaniklilik": "Dayanıklılık", "hiz": "Hız",
	"genjutsu": "Genjutsu", "fuinjutsu": "Fūinjutsu", "iryo": "Iryō Ninjutsu (Tıbbi)", "senjutsu": "Senjutsu", "kuchiyose": "Kuchiyose", "shurikenjutsu": "Shurikenjutsu"}
## Teknik kategorisi -> ustalık dalı (yapıldıkça o dal gelişir; yapabilme şartı da o dala bakar)
const BRANCH := {"genjutsu": "genjutsu", "fuinjutsu": "fuinjutsu", "medical": "iryo", "senjutsu": "senjutsu", "summoning": "kuchiyose",
	"kenjutsu": "kenjutsu", "taijutsu": "taijutsu"}


static func branch_of(j: Dictionary) -> String:
	return String(BRANCH.get(String(j.get("category", "ninjutsu")), "ninjutsu"))
const SP_PER := 4.0   # her 4 toplam ustalık puanında 1 yetenek puanı
## Gelişme hızı (kullanıcı 2026-11-05: "30-40 dk'da rahat jōnin oluyorsun, en az 3-4 saat sürmeli"): bütün kazanımlar x0.17 (~6 kat yavaş;
## dv/dt = miktar x _rate(v) olduğundan aynı ustalığa varış süresi tam 1/0.17 katı uzar)
const SPEED := 0.17


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
	amount *= 1.0 + Stats.skill(p, "xp")   # eski "tecrübe" yetenekleri ustalık hızına
	amount *= SPEED
	amount *= Exams.xp_mult()   # Akademi Eğitmeni uzmanlığı: ustalık +%15 (eski XP bonusu)
	var nv = v + amount * _rate(v)
	m[key] = nv
	if int(nv) > int(v):
		Hud.float_text("%s %d" % [NAMES.get(key, key), int(nv)], Color(0.6, 0.95, 1.0))
		Sfx.play("pickup", null, 1.3, 0.35)
		if int(nv) % 10 == 0:
			Hud.banner(NAMES.get(key, key).to_upper(), "Ustalık %d" % int(nv), Color(0.6, 0.95, 1.0))
	elif int(nv * 4.0) > int(v * 4.0):   # yavaş gelişimde de artış görünsün: her çeyrek puanda küçük yazı (6 kat yavaşlatmadan sonra tam sayı çok seyrek geliyordu)
		if Game.player and is_instance_valid(Game.player):
			Combat.popup_text(Game.player.global_position + Vector3.UP * 2.1, "%s %.2f" % [NAMES.get(key, key), nv], Color(0.55, 0.85, 0.95))
	# ikinci / üçüncü chakra doğası: ninjutsu 40 / 75'te seçim (eski yetenek ağacı düğümü yerine)
	if key == "ninjutsu":
		var els: Array = p.get("elements", [])
		if (v < 40.0 and nv >= 40.0 and els.size() < 2) or (v < 75.0 and nv >= 75.0 and els.size() < 3):
			Menus._pick_element.call_deferred(null)
	# can/chakra/stamina sınırını doğrudan büyüten ustalıklar: artış hemen statlara yansısın (eskiden yalnız Güç atlayınca
	# yenileniyordu — dayak yiyip dayanıklılık artsa da can barı aynı kalıyordu)
	if key in ["dayaniklilik", "chakra", "taijutsu"] and int(nv * 4.0) > int(v * 4.0) and Game.player and is_instance_valid(Game.player) and Game.player.has_method("apply_profile_stats"):
		Game.player.apply_profile_stats()
	var old_lv = int(p.get("level", 1))
	refresh_level(p)
	if int(p["level"]) != old_lv:
		Progress.on_power_changed()


## kazanım hızı: 0'da tam, 50'de ~%40, 100'de ~%14, 200'de ~%4 (eski eğriyle 60'a kadar benzer, sonra durmak yerine yavaşlar)
static func _rate(v: float) -> float:
	return 1.0 / (1.0 + pow(v / 45.0, 2.2))


static func total(p: Dictionary) -> float:
	var t = 0.0
	for k in KEYS:
		t += get_v(p, k)
	return t


## GÜÇ (eski seviyenin yerine geçen iç değer, 1..100): ninjutsu, en iyi dövüş dalı, chakra, dayanıklılık ortalaması
static func power(p: Dictionary) -> int:
	var fight = maxf(get_v(p, "taijutsu"), get_v(p, "kenjutsu"))
	var avg = (get_v(p, "ninjutsu") + fight + get_v(p, "chakra") + get_v(p, "dayaniklilik")) / 4.0
	# eğri: başta hızlı yükselir (ustalık ort. 10 -> güç ~20, 50 -> ~62); dünya ölçeği: köy jōnin'i ~60-85, ANBU ~80-100, Bingo S 110-200, efsaneler 200+
	return maxi(1, int(round(100.0 * pow(avg / 100.0, 0.7))))   # üst sınır yok


static func refresh_level(p: Dictionary) -> void:
	p["level"] = power(p)
	p["xp"] = 0


## Ninjutsu yeterliliği: jutsunun rütbe şartına göre (j.level 1..100). "" = atabilir, "fail:x" = x olasılıkla mühür bozulur, aksi engel
static func cast_check(p: Dictionary, j: Dictionary) -> String:
	var cat = String(j.get("category", "ninjutsu"))
	if cat == "taijutsu" or String(j.get("virtual", "")) != "":
		return ""
	var need = float(j.get("level", 1))
	var br = branch_of(j)
	# kendi dalının ustalığı; ninjutsu ustalığının %80'i taban (eski kayıtlar, dallar yeni eklendi)
	var nin = maxf(get_v(p, br), get_v(p, "ninjutsu") * (0.8 if br != "ninjutsu" else 1.0))
	if need <= 3.0:
		return ""
	if nin < need * 0.55:
		return "%s ustalığın yetersiz (%d / %d) — bu tekniği yapamazsın" % [NAMES.get(br, "Ninjutsu"), int(nin), int(need)]
	if nin < need:
		return "fail:%.3f" % clampf((need - nin) / (need * 0.45), 0.05, 0.85)
	return ""


## Mühür hızı çarpanı (1 = normal yavaş ve okunur; usta ninjada 0.45'e kadar hızlanır)
static func seal_speed(p: Dictionary) -> float:
	return lerpf(1.35, 0.45, minf(1.0, get_v(p, "ninjutsu") / 100.0)) / (1.0 + maxf(0.0, get_v(p, "ninjutsu") - 100.0) / 300.0)
