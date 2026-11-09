class_name CanonRules
extends RefCounted
## Animedeki kullanım şartları (oyuncu + düşman aynı). "" = atılabilir, değilse sebep.
##  - Hiraishin ışınlanmaları: hedef senin işaretinle işaretli olmalı ya da yakında işaretli kunain olmalı (Minato: shiki işareti)
##  - Kirin: gökte fırtına bulutu — yağmur/fırtına ya da son 25 sn'de Katon ile ısıtılmış gök (Sasuke: Gōryūka ile bulut)
##  - Büyük Suiton: 30 m içinde su (göl/deniz/nehir) ya da yağmur; yoksa suyu chakradan üretir — yarı güç (Hoshigaki klanı muaf)

const HIRA_TP := ["hiraishin_no_jutsu", "hiraishingiri", "hiraishin_ni_no_dan", "hiraishin_ranbu", "hiraishin_rasengan", "hiraishin_dorai"]
const STORM := ["kirin"]
const WATER := ["suiton_daibakufu_no_jutsu", "suiton_daibakuryu", "suiton_haran_bansho", "suiton_suijinheki", "suiton_bakusui_shoha",
	"suiton_suiryudan_no_jutsu", "suiryudan", "suiton_daikodan_no_jutsu", "raisuiryudan"]


## Yağmur/gök gürültülü fırtına (kum ya da kar fırtınası değil)
static func rainy() -> bool:
	var w = String(Game.world.env.weather) if Game.world and Game.world.get("env") else ""
	if w.contains("kum") or w.contains("kar"):
		return false
	return w.contains("yağmur") or w.contains("fırtına") or w.contains("sağanak")


static func hira_mark_ok(c: Node3D) -> bool:
	if c == null or not is_instance_valid(c):
		return false
	var my = c.get_instance_id()
	for f in c.get_tree().get_nodes_in_group("fighters"):
		if f != c and is_instance_valid(f) and not f.is_dead() and f.has_meta("hiraishin_by") and int(f.get_meta("hiraishin_by")) == my \
				and f.has_method("has_status") and f.has_status("marked") and f.global_position.distance_to(c.global_position) < 60.0:
			return true
	for m in c.get_meta("hira_marks", []):
		if m is Dictionary and Game.now() < float(m["until"]) and (m["pos"] as Vector3).distance_to(c.global_position) < 60.0:
			return true
	return false


static func storm_ok(c: Node3D) -> bool:
	if rainy():
		return true
	return c != null and is_instance_valid(c) and Game.now() - float(c.get_meta("katon_t", -999.0)) < 25.0


static func water_near(c: Node3D) -> bool:
	if c == null or not is_instance_valid(c):
		return false
	if rainy():
		return true
	var p = c.global_position
	for k in 13:
		var q = p if k == 0 else p + Vector3(cos(k * TAU / 12.0), 0, sin(k * TAU / 12.0)) * 30.0
		if Game.water_level(q.x, q.z) > Game.terrain_height(q.x, q.z) + 0.05:
			return true
	return false


static func hoshigaki(c: Node3D) -> bool:
	if c is Player:
		return String(Game.profile.get("clan", "")) == "hoshigaki"
	return c.get("arch") is Dictionary and String(c.arch.get("clan", "")) == "hoshigaki"


## Kanon silah şartı: yelpaze jutsuları elde yelpaze olmadan atılamaz (kullanıcı: "Kamaitachi yelpazesizken atılabiliyor")
const FAN := ["kamaitachi_no_jutsu", "daikamaitachi_no_jutsu", "kyodai_sensu"]   # herhangi bir savaş yelpazesi
const WEAPON_ONLY := {"kuchiyose_kirikiri_mai": ["temari_ogi"], "bashosen_kaze_no_maki": ["bashosen"], "bashosen_hi_no_maki": ["bashosen"],
	"bashosen_rai_no_maki": ["bashosen"], "bashosen_mizu_no_maki": ["bashosen"]}
const FAN_IDS := ["temari_ogi", "yelpaze", "bashosen", "gunbai"]

static func weapon_ids(c: Node3D) -> Array:
	var out = []
	if c is Player:
		for s in ["sag", "sol"]:
			var g = Gear.equipped(Game.profile, s)
			if not g.is_empty():
				out.append(String(g.get("id", "")))
	elif c != null and c.get("look") is Dictionary:
		for k in ["weapon_r", "weapon_l"]:
			if c.look.get(k) != null:
				out.append(String(c.look[k]))
	return out


## Atılabilir mi? "" = evet
static func block(c: Node3D, jid: String) -> String:
	if jid in FAN or WEAPON_ONLY.has(jid):
		var ws = weapon_ids(c)
		var need: Array = WEAPON_ONLY.get(jid, FAN_IDS)
		if not ws.any(func(w): return w in need):
			return "Elinde %s yok — bu teknik onunla savrulur." % ("Temari no Ōōgi" if need == ["temari_ogi"] else ("Bashōsen" if need == ["bashosen"] else "savaş yelpazesi"))
	if jid in HIRA_TP and not hira_mark_ok(c):
		return "Işınlanacak işaret yok — önce Hiraishin kunaisi at ya da hedefe vurup işaretle."
	if jid in STORM and not storm_ok(c):
		return "Gökte fırtına bulutu yok — önce Katon ile göğü ısıt ya da fırtınayı bekle."
	return ""


## Hasar çarpanı (atılabilen ama şartı eksik): su kaynağı yoksa büyük Suiton yarı güç
static func dmg_mult(c: Node3D, jid: String) -> float:
	if jid in WATER and not hoshigaki(c) and not water_near(c):
		return 0.5
	return 1.0
