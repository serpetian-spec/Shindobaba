class_name Outfits
extends RefCounted
## NPC kıyafet setleri: her arketip kendi parça havuzundan rastgele giyinir (kalabalıklar çeşitli, rütbeler/gruplar ayırt edilir).
## roll(arketip, köy) -> görünüm (look) üstüne yazılacak anahtarlar. Görev kayıtları için roll_hex (renkler html dizesi).
## Arketipler: genin, chunin, jonin, anbu, kok, rogue, bandit, samurai, akatsuki, org, civ, merchant, monk, farmer, worker,
## medic, elder, kid, student, guard, noble, traveler, sennin, hunter

## Köy üniformaları: yelek rengi, yelek stili, alt giysi tonları, alın bandı kumaşı
const VILLAGE := {
	"konoha": {"vest": Color(0.38, 0.48, 0.28), "vs": 0, "base": [Color(0.15, 0.2, 0.33), Color(0.13, 0.17, 0.27)], "band": Color(0.15, 0.22, 0.55)},
	"suna": {"vest": Color(0.72, 0.62, 0.45), "vs": 1, "base": [Color(0.45, 0.36, 0.26), Color(0.3, 0.3, 0.32), Color(0.55, 0.45, 0.32)], "band": Color(0.25, 0.25, 0.3)},
	"kiri": {"vest": Color(0.45, 0.52, 0.46), "vs": 2, "base": [Color(0.28, 0.33, 0.4), Color(0.22, 0.27, 0.33)], "band": Color(0.2, 0.22, 0.3)},
	"kumo": {"vest": Color(0.88, 0.88, 0.84), "vs": 3, "base": [Color(0.2, 0.22, 0.26), Color(0.15, 0.16, 0.2)], "band": Color(0.1, 0.1, 0.12)},
	"iwa": {"vest": Color(0.62, 0.18, 0.15), "vs": 4, "base": [Color(0.38, 0.3, 0.25), Color(0.3, 0.26, 0.24)], "band": Color(0.45, 0.15, 0.13)},
	"oto": {"vest": null, "vs": 0, "base": [Color(0.42, 0.38, 0.48), Color(0.3, 0.28, 0.33)], "band": Color(0.3, 0.3, 0.35)},
	"ame": {"vest": Color(0.45, 0.48, 0.52), "vs": 2, "base": [Color(0.3, 0.32, 0.36), Color(0.22, 0.24, 0.28)], "band": Color(0.25, 0.27, 0.32)},
	"kusa": {"vest": Color(0.3, 0.45, 0.25), "vs": 0, "base": [Color(0.25, 0.32, 0.22), Color(0.2, 0.25, 0.2)], "band": Color(0.2, 0.35, 0.2)},
	"taki": {"vest": Color(0.42, 0.55, 0.6), "vs": 2, "base": [Color(0.2, 0.3, 0.38)], "band": Color(0.2, 0.3, 0.45)},
}

const VIVID := [Color(0.95, 0.5, 0.12), Color(0.2, 0.35, 0.65), Color(0.75, 0.15, 0.18), Color(0.2, 0.5, 0.3), Color(0.55, 0.3, 0.6),
	Color(0.95, 0.8, 0.25), Color(0.15, 0.15, 0.18), Color(0.9, 0.9, 0.88), Color(0.25, 0.6, 0.7), Color(0.85, 0.45, 0.6)]
const EARTH := [Color(0.48, 0.38, 0.28), Color(0.55, 0.42, 0.3), Color(0.4, 0.34, 0.26), Color(0.5, 0.25, 0.18), Color(0.35, 0.33, 0.25),
	Color(0.6, 0.5, 0.32), Color(0.3, 0.26, 0.22), Color(0.45, 0.2, 0.15)]
## Haydutların uyumsuz, solgun ama farklı renkleri
const RAGS := [Color(0.55, 0.18, 0.15), Color(0.32, 0.4, 0.25), Color(0.28, 0.33, 0.45), Color(0.6, 0.5, 0.32), Color(0.45, 0.45, 0.42),
	Color(0.5, 0.25, 0.4), Color(0.7, 0.55, 0.3), Color(0.2, 0.2, 0.22), Color(0.48, 0.38, 0.28), Color(0.62, 0.35, 0.2)]
const SOFT := [Color(0.5, 0.6, 0.45), Color(0.6, 0.35, 0.3), Color(0.8, 0.75, 0.55), Color(0.4, 0.45, 0.6), Color(0.7, 0.55, 0.65),
	Color(0.85, 0.85, 0.85), Color(0.55, 0.3, 0.45), Color(0.9, 0.6, 0.3), Color(0.35, 0.5, 0.55), Color(0.75, 0.68, 0.5), Color(0.62, 0.42, 0.5)]
const KIMONO := [Color(0.25, 0.3, 0.55), Color(0.65, 0.2, 0.3), Color(0.3, 0.45, 0.35), Color(0.85, 0.65, 0.75), Color(0.5, 0.35, 0.6),
	Color(0.9, 0.85, 0.75), Color(0.75, 0.45, 0.2), Color(0.2, 0.2, 0.25)]


static func _p(a: Array):
	return a[randi() % a.size()]


static func _ch(p: float) -> bool:
	return randf() < p


## Tüm kıyafet anahtarlarını sıfırlayan temel (önceki rol görünümü sızmasın)
static func _blank() -> Dictionary:
	return {"vest": null, "vest_style": 0, "outer_style": null, "outer": null, "outer_pattern": 0, "outer_accent": null, "head_style": null, "headgear": null,
		"face_style": null, "facegear": null, "mask": null, "cloak": null, "guards": null, "acc": null, "back_item": null, "backc": null, "gloves": false, "arm_wraps": false,
		"hakama": false, "wear": 0.0, "rope_belt": false, "top_pattern": 0, "foot_style": "sandal", "band": null, "band_style": "none"}


static func roll(arch: String, village := "") -> Dictionary:
	if village == "" or not VILLAGE.has(village):
		village = "konoha" if village == "" else village
	var V: Dictionary = VILLAGE.get(village, VILLAGE["konoha"])
	var L = _blank()
	L["village"] = village
	match arch:
		"genin", "kid", "student":
			var t: Color = _p(VIVID)
			L["top_style"] = _p(["uzun", "tisort", "ceket", "ceket", "yakali", "kolsuz", "gi", "tek_kol", "yakali_uzun"])
			L["top"] = t; L["top2"] = _p(VIVID) if _ch(0.6) else t.darkened(0.3)
			L["top_pattern"] = _p([0, 0, 0, 2, 3, 3, 5, 6])
			L["pants"] = _p([Color(0.15, 0.15, 0.17), Color(0.2, 0.25, 0.4), Color(0.3, 0.3, 0.33), Color(0.35, 0.3, 0.25), t.darkened(0.45)])
			L["pants_style"] = _p(["ninja", "sort", "sort", "kapri", "kisa_sort", "bol"])
			L["foot_style"] = _p(["sandal", "sandal", "yuksek_sandal", "tabi"])
			L["sandal"] = _p([Color(0.15, 0.2, 0.32), Color(0.12, 0.12, 0.14), Color(0.35, 0.3, 0.28)])
			if arch == "genin":
				L["band"] = V["band"]; L["band_style"] = _p(["head", "head", "head", "neck", "bandana"]) if arch == "genin" else "none"
				if L["band_style"] == "bandana":
					L["head_style"] = "bandana"; L["headgear"] = V["band"]; L["band_style"] = "none"
				L["arm_wraps"] = _ch(0.3); L["gloves"] = _ch(0.25)
				L["back_item"] = _p([null, null, "kemer", "kemer_canta", "parsomen", "atki"])
				if L["back_item"] == "atki":
					L["back_item"] = null; L["outer_style"] = "atki"; L["outer"] = _p(VIVID)
				L["backc"] = Color(0.32, 0.26, 0.18)
			elif _ch(0.25):
				L["face_style"] = "goggles"; L["facegear"] = _p(VIVID)
		"chunin", "guard", "jonin", "hunter":
			var b: Color = _p(V["base"])
			L["top"] = b; L["top2"] = b; L["pants"] = b
			L["top_style"] = "uzun"
			if village == "kumo":
				L["top_style"] = _p(["uzun", "tek_kol", "kolsuz"])
			elif village == "suna" and _ch(0.3):
				L["top_style"] = "yakali_uzun"
			L["pants_style"] = _p(["ninja", "ninja", "ninja", "sargi"])
			L["vest"] = V["vest"]; L["vest_style"] = V["vs"]
			if V["vest"] == null:
				L["rope_belt"] = true; L["top_style"] = "yakali_uzun"
			L["band"] = V["band"]; L["band_style"] = _p(["head", "head", "head", "head", "neck"])
			if _ch(0.18):
				L["head_style"] = "bandana"; L["headgear"] = V["band"]; L["band_style"] = "none"
			L["sandal"] = _p([Color(0.15, 0.2, 0.32), Color(0.12, 0.12, 0.14)])
			L["foot_style"] = _p(["sandal", "sandal", "sandal", "tabi"])
			L["guards"] = _p([null, null, "kol", "bacak", "ikisi"]) if arch != "guard" else _p(["kol", "ikisi"])
			L["acc"] = Color(0.55, 0.58, 0.62)
			L["gloves"] = _ch(0.3)
			L["back_item"] = _p([null, "kemer", "kemer_canta", "parsomen", "bel_parsomen", "kin"])
			L["backc"] = _p([Color(0.32, 0.26, 0.18), Color(0.85, 0.78, 0.6)])
			if village == "suna" and _ch(0.35):
				L["head_style"] = "sarik"; L["headgear"] = Color(0.85, 0.76, 0.58)
				if _ch(0.5):
					L["face_style"] = "pece"; L["facegear"] = Color(0.82, 0.74, 0.58)
			if village == "kiri" and _ch(0.3):
				L["face_style"] = "cloth"; L["facegear"] = Color(0.2, 0.22, 0.28)
			if village == "ame" and _ch(0.5):
				L["outer_style"] = _p(["panco", "mino"]); L["outer"] = Color(0.35, 0.37, 0.42)
			if arch == "jonin":
				# jōnin: daha ağır teçhizat, bazen uzun haori / maske / koyu yelek
				L["gloves"] = _ch(0.6)
				if _ch(0.3):
					L["face_style"] = "cloth"; L["facegear"] = b.darkened(0.3)
				if _ch(0.25):
					L["outer_style"] = _p(["haori_uzun", "haori", "kisa"]); L["outer"] = _p([Color(0.42, 0.36, 0.3), Color(0.3, 0.38, 0.3), b.darkened(0.2)])   # beyaz + alev etek yalnız Kage'nin cübbesi
					L["outer_pattern"] = _p([0, 1]); L["outer_accent"] = _p([Color(0.75, 0.15, 0.12), V["band"]])
				if _ch(0.25):
					L["top_pattern"] = 1  # file ağ
			if arch == "hunter":
				L["face_style"] = _p(["anbu_kedi", "anbu_kurt", "anbu_kus"]); L["facegear"] = Color(0.95, 0.95, 0.94)
				L["outer_style"] = "kisa"; L["outer"] = b.darkened(0.2)
		"anbu", "kok":
			var dk = Color(0.1, 0.1, 0.13) if arch == "anbu" else Color(0.07, 0.07, 0.09)
			L["top"] = dk; L["top2"] = dk; L["pants"] = dk
			L["top_style"] = _p(["yakali_uzun", "kolsuz", "kolsuz"]) if arch == "anbu" else "yakali_uzun"
			L["pants_style"] = "ninja"
			L["vest"] = Color(0.78, 0.78, 0.8) if arch == "anbu" else Color(0.1, 0.1, 0.12)
			L["vest_style"] = 5 if arch == "anbu" else 7
			L["face_style"] = _p(["anbu_kedi", "anbu_kurt", "anbu_kus", "anbu_ayi", "anbu_tilki", "anbu_kaplan", "anbu_yilan", "anbu_maymun"]) if arch == "anbu" else "anbu_kus"
			L["facegear"] = Color(0.96, 0.96, 0.95) if arch == "anbu" else Color(0.88, 0.88, 0.86)
			L["guards"] = "ikisi"; L["acc"] = Color(0.8, 0.8, 0.82); L["gloves"] = true
			L["arm_wraps"] = arch == "kok"
			L["foot_style"] = "tabi"; L["sandal"] = Color(0.08, 0.08, 0.1)
			L["back_item"] = "kin"; L["backc"] = Color(0.12, 0.1, 0.1)
			if _ch(0.2):
				L["outer_style"] = "kisa"; L["outer"] = Color(0.15, 0.15, 0.18)
		"rogue":
			var b: Color = _p([Color(0.2, 0.2, 0.24), Color(0.3, 0.28, 0.26), Color(0.25, 0.22, 0.28), Color(0.18, 0.22, 0.2), Color(0.35, 0.15, 0.15)])
			L["top"] = b; L["top2"] = b.darkened(0.25); L["pants"] = _p([Color(0.18, 0.18, 0.2), b.darkened(0.3), Color(0.25, 0.22, 0.2)])
			L["top_style"] = _p(["uzun", "yakali", "yakali_uzun", "kolsuz", "tek_kol", "ceket"])
			L["top_pattern"] = _p([0, 0, 1, 4])
			L["pants_style"] = _p(["ninja", "sargi", "bol", "ninja"])
			L["band"] = V["band"].darkened(0.2); L["band_style"] = _p(["slashed", "slashed", "slashed", "neck"])
			L["wear"] = randf_range(0.35, 0.65)
			# eski köy yeleği, yıpranmış
			if _ch(0.35) and V["vest"] != null:
				L["vest"] = Color(V["vest"]).darkened(0.25); L["vest_style"] = V["vs"]
			elif _ch(0.3):
				L["vest"] = Color(0.32, 0.22, 0.14); L["vest_style"] = _p([9, 10])
			if _ch(0.55):
				L["outer_style"] = _p(["yirtik", "yirtik", "panco", "pelerin", "kisa", "org_pelerin"])
				L["outer"] = _p([Color(0.25, 0.22, 0.2), Color(0.18, 0.18, 0.2), Color(0.35, 0.3, 0.24), Color(0.3, 0.12, 0.12)])
				L["outer_pattern"] = 5 if L["outer_style"] != "org_pelerin" else 1
				L["outer_accent"] = Color(0.4, 0.12, 0.12)
			if _ch(0.35):
				L["head_style"] = _p(["kasa", "kapuson", "basortu", "hachimaki"]); L["headgear"] = _p([Color(0.48, 0.4, 0.28), Color(0.15, 0.15, 0.17), Color(0.4, 0.15, 0.12)])
			var fr = randf()
			if fr < 0.3:
				L["face_style"] = "cloth"; L["facegear"] = _p([Color(0.15, 0.15, 0.2), Color(0.4, 0.1, 0.1)])
			elif fr < 0.42:
				L["face_style"] = "goz_bandi"
			L["guards"] = _p([null, "kol", "omuz", "bacak", "ikisi"]); L["acc"] = Color(0.45, 0.47, 0.5)
			L["gloves"] = _ch(0.5); L["arm_wraps"] = _ch(0.4)
			L["foot_style"] = _p(["sandal", "cizme", "yuksek_sandal", "tabi"]); L["sandal"] = Color(0.18, 0.15, 0.12)
			L["back_item"] = _p([null, "kin", "ip_kangal", "canta", "sake", "shuriken"]); L["backc"] = Color(0.3, 0.24, 0.16)
		"bandit":
			var t: Color = _p(RAGS)
			L["top"] = t; L["top2"] = t.darkened(0.2)
			L["top_style"] = _p(["kolsuz", "atlet", "tisort", "uzun", "tek_kol", "kolsuz"])
			L["top_pattern"] = _p([4, 4, 4, 0, 2])
			L["pants"] = _p(RAGS).darkened(0.25)
			L["pants_style"] = _p(["sivil", "bol", "kapri", "bol", "kisa_sort"])
			L["wear"] = randf_range(0.55, 0.95)
			var vr = randf()
			if vr < 0.35:
				L["vest"] = Color(0.35, 0.24, 0.15); L["vest_style"] = 9
			elif vr < 0.55:
				L["vest"] = Color(0.42, 0.3, 0.2); L["vest_style"] = 10
			elif vr < 0.65:
				L["vest"] = Color(0.5, 0.52, 0.55); L["vest_style"] = 11
			var hr = randf()
			if hr < 0.45:
				L["head_style"] = "basortu"; L["headgear"] = _p([Color(0.55, 0.2, 0.15), Color(0.25, 0.3, 0.45), Color(0.6, 0.5, 0.3), Color(0.15, 0.15, 0.15)])
			elif hr < 0.6:
				L["head_style"] = "hachimaki"; L["headgear"] = _p([Color(0.85, 0.82, 0.75), Color(0.6, 0.15, 0.12)])
			elif hr < 0.72:
				L["head_style"] = "kasa"; L["headgear"] = Color(0.45, 0.38, 0.26)
			var fr = randf()
			if fr < 0.35:
				L["face_style"] = "cloth"; L["facegear"] = _p([Color(0.4, 0.3, 0.2), Color(0.15, 0.15, 0.15), Color(0.5, 0.15, 0.12)])
			elif fr < 0.5:
				L["face_style"] = "goz_bandi"
			L["guards"] = _p([null, null, "omuz", "dizlik", "kol", "bacak"]); L["acc"] = Color(0.4, 0.38, 0.36)
			L["arm_wraps"] = _ch(0.5); L["gloves"] = _ch(0.3)
			L["foot_style"] = _p(["cizme", "zori", "sandal", "cizme"]); L["sandal"] = Color(0.3, 0.22, 0.15); L["wraps"] = Color(0.75, 0.7, 0.6)
			L["back_item"] = _p([null, "ip_kangal", "sake", "canta", "kemer_canta"]); L["backc"] = _p([Color(0.7, 0.62, 0.45), Color(0.4, 0.3, 0.2)])
			if _ch(0.2):
				L["outer_style"] = "yirtik"; L["outer"] = Color(0.32, 0.27, 0.22); L["outer_pattern"] = 5
		"samurai":
			var lac: Color = _p([Color(0.55, 0.1, 0.1), Color(0.15, 0.15, 0.18), Color(0.2, 0.25, 0.4), Color(0.35, 0.22, 0.15)])
			L["top"] = _p([Color(0.22, 0.24, 0.3), Color(0.3, 0.3, 0.32), Color(0.85, 0.85, 0.8)]); L["top2"] = Color(0.85, 0.75, 0.45)
			L["top_style"] = _p(["kimono", "gi"])
			L["pants"] = _p([Color(0.2, 0.22, 0.28), Color(0.3, 0.28, 0.3)]); L["pants_style"] = "sivil"; L["hakama"] = true
			L["vest"] = lac; L["vest_style"] = 6
			if _ch(0.65):
				L["head_style"] = _p(["kabuto", "kabuto", "jingasa"]); L["headgear"] = lac.darkened(0.2)
			if _ch(0.45):
				L["face_style"] = "mempo"; L["facegear"] = lac.darkened(0.3)
			L["guards"] = _p(["agir", "kol", "ikisi", "omuz"]); L["acc"] = lac.lightened(0.1)
			L["gloves"] = true
			L["foot_style"] = _p(["cizme", "tabi"]); L["sandal"] = Color(0.12, 0.1, 0.1)
			L["back_item"] = _p([null, "sashimono", "kin", null]); L["backc"] = _p([Color(0.85, 0.85, 0.82), lac])
			if _ch(0.3):
				L["outer_style"] = "jinbaori"; L["outer"] = _p([Color(0.15, 0.15, 0.22), Color(0.85, 0.82, 0.75)]); L["outer_pattern"] = 1; L["outer_accent"] = Color(0.85, 0.68, 0.25)
		"akatsuki", "org":
			L["top"] = Color(0.12, 0.12, 0.14); L["top2"] = Color(0.12, 0.12, 0.14); L["pants"] = Color(0.12, 0.12, 0.14)
			L["top_style"] = "yakali_uzun"; L["pants_style"] = "ninja"
			L["outer_style"] = "org_pelerin"; L["outer"] = Color(0.05, 0.05, 0.07)
			L["outer_pattern"] = 6 if arch == "akatsuki" else 3
			L["outer_accent"] = Color(0.78, 0.08, 0.1)
			L["band"] = V["band"]; L["band_style"] = "slashed"
			if _ch(0.25):
				L["head_style"] = "kasa"; L["headgear"] = Color(0.78, 0.66, 0.42)
			L["foot_style"] = "sandal"; L["sandal"] = Color(0.3, 0.3, 0.35)
			L["gloves"] = _ch(0.3)
		"monk":
			L["top"] = Color(0.9, 0.55, 0.15); L["top2"] = Color(0.7, 0.35, 0.1); L["top_style"] = "gi"
			L["pants"] = Color(0.85, 0.8, 0.7); L["pants_style"] = _p(["sivil", "bol"])
			var mr = randf()
			if mr < 0.5:
				L["outer_style"] = "kesa"; L["outer"] = _p([Color(0.85, 0.45, 0.12), Color(0.65, 0.2, 0.12)])
			else:
				L["outer_style"] = "cuppe"; L["outer"] = _p([Color(0.3, 0.28, 0.35), Color(0.25, 0.25, 0.25)]); L["outer_pattern"] = 1; L["outer_accent"] = Color(0.9, 0.55, 0.15)
			if _ch(0.4):
				L["head_style"] = "tengai"; L["headgear"] = Color(0.72, 0.6, 0.38)
			L["back_item"] = "tespih"; L["backc"] = Color(0.35, 0.22, 0.12)
			L["foot_style"] = "zori"; L["sandal"] = Color(0.78, 0.68, 0.45)
			L["rope_belt"] = _ch(0.5)
		"farmer":
			var t: Color = _p(EARTH + SOFT)
			L["top"] = t; L["top2"] = t.darkened(0.15); L["top_style"] = _p(["tisort", "uzun", "atlet", "gi"])
			L["top_pattern"] = _p([0, 4, 4])
			L["pants"] = _p([Color(0.35, 0.3, 0.28), Color(0.25, 0.28, 0.38)]); L["pants_style"] = _p(["kapri", "sivil", "bol"])
			L["wear"] = randf_range(0.2, 0.45)
			if _ch(0.65):
				L["head_style"] = "kasa"; L["headgear"] = Color(0.78, 0.66, 0.42)
			if _ch(0.2):
				L["outer_style"] = "mino"; L["outer"] = Color(0.68, 0.58, 0.36); L["outer_pattern"] = 4
			L["back_item"] = _p([null, "sepet", "sepet"]); L["backc"] = Color(0.7, 0.58, 0.35)
			L["foot_style"] = "zori"; L["sandal"] = Color(0.78, 0.68, 0.45); L["arm_wraps"] = _ch(0.3)
		"worker":
			var t: Color = _p(EARTH)
			L["top"] = t; L["top2"] = t; L["top_style"] = _p(["atlet", "tisort", "tisort"])
			L["pants"] = Color(0.3, 0.27, 0.24); L["pants_style"] = _p(["kapri", "bol", "sivil"])
			L["wear"] = 0.3
			L["head_style"] = _p(["hachimaki", "hachimaki", "basortu"]); L["headgear"] = Color(0.9, 0.88, 0.85)
			L["gloves"] = _ch(0.4); L["arm_wraps"] = _ch(0.4)
			L["foot_style"] = _p(["zori", "cizme"]); L["sandal"] = Color(0.3, 0.22, 0.15)
			L["back_item"] = _p([null, "ip_kangal", "kemer_canta"]); L["backc"] = Color(0.6, 0.5, 0.35)
		"merchant":
			var t: Color = _p(KIMONO)
			L["top"] = t; L["top2"] = _p(KIMONO); L["top_style"] = _p(["kimono", "uzun", "kimono"]); L["top_pattern"] = _p([0, 6, 2])
			L["pants"] = _p([Color(0.25, 0.22, 0.2), Color(0.3, 0.3, 0.35)]); L["pants_style"] = "sivil"; L["hakama"] = _ch(0.3)
			if _ch(0.45):
				L["outer_style"] = "haori"; L["outer"] = _p([Color(0.15, 0.15, 0.2), Color(0.35, 0.25, 0.18), Color(0.25, 0.3, 0.22)])
			if _ch(0.3):
				L["head_style"] = "kasa"; L["headgear"] = Color(0.78, 0.66, 0.42)
			L["back_item"] = _p([null, "sepet", "canta", "sake"]); L["backc"] = Color(0.7, 0.58, 0.35)
			L["foot_style"] = "zori"; L["sandal"] = Color(0.3, 0.22, 0.15)
		"noble":
			var t: Color = _p([Color(0.55, 0.12, 0.15), Color(0.2, 0.25, 0.5), Color(0.4, 0.15, 0.45), Color(0.9, 0.88, 0.82)])
			L["top"] = t; L["top2"] = Color(0.85, 0.7, 0.3); L["top_style"] = "kimono"; L["top_pattern"] = 6
			L["pants"] = t.darkened(0.35); L["pants_style"] = "sivil"; L["hakama"] = true
			L["outer_style"] = _p(["haori", "haori_uzun"]); L["outer"] = _p([Color(0.12, 0.12, 0.15), Color(0.85, 0.82, 0.75)]); L["outer_pattern"] = 1; L["outer_accent"] = Color(0.85, 0.7, 0.3)
			L["foot_style"] = "tabi"; L["sandal"] = Color(0.95, 0.95, 0.92)
		"medic":
			L["top"] = Color(0.96, 0.96, 0.97); L["top2"] = Color(0.85, 0.2, 0.2); L["top_style"] = _p(["uzun", "yakali_uzun"]); L["top_pattern"] = 6
			L["pants"] = Color(0.9, 0.9, 0.92); L["pants_style"] = "ninja"
			L["band"] = V["band"]; L["band_style"] = "head"
			L["foot_style"] = "sandal"; L["sandal"] = Color(0.85, 0.85, 0.88)
			L["back_item"] = "kemer_canta"; L["backc"] = Color(0.85, 0.85, 0.88)
		"elder":
			var t: Color = _p([Color(0.35, 0.3, 0.28), Color(0.3, 0.35, 0.3), Color(0.45, 0.38, 0.3), Color(0.25, 0.25, 0.35)])
			L["top"] = t; L["top2"] = t.darkened(0.2); L["top_style"] = _p(["kimono", "kimono", "uzun"])
			L["pants"] = t.darkened(0.3); L["pants_style"] = "sivil"; L["hakama"] = _ch(0.5)
			if _ch(0.5):
				L["outer_style"] = "haori"; L["outer"] = _p([Color(0.2, 0.2, 0.22), Color(0.4, 0.32, 0.24)])
			if _ch(0.3):
				L["head_style"] = "kasa"; L["headgear"] = Color(0.7, 0.6, 0.4)
			L["foot_style"] = "zori"; L["sandal"] = Color(0.78, 0.68, 0.45)
		"traveler":
			var t: Color = _p(EARTH + SOFT)
			L["top"] = t; L["top2"] = t.darkened(0.2); L["top_style"] = _p(["uzun", "tunik", "gi", "uzun"])
			if L["top_style"] == "tunik":
				L["top_style"] = "uzun"; L["top_pattern"] = 6
			L["pants"] = _p([Color(0.35, 0.3, 0.28), Color(0.3, 0.3, 0.33)]); L["pants_style"] = _p(["sivil", "bol", "kapri"])
			L["outer_style"] = _p(["pelerin", "panco", "mino", "pelerin", null]); L["outer"] = _p([Color(0.4, 0.32, 0.24), Color(0.5, 0.42, 0.3), Color(0.3, 0.32, 0.3)])
			L["outer_pattern"] = 4 if L["outer_style"] == "mino" else _p([0, 1])
			L["outer_accent"] = _p([Color(0.7, 0.3, 0.15), Color(0.25, 0.35, 0.55)])
			L["head_style"] = _p(["kasa", "kasa", "kapuson", null]); L["headgear"] = Color(0.78, 0.66, 0.42) if L["head_style"] == "kasa" else Color(0.35, 0.3, 0.25)
			L["back_item"] = _p(["canta", "sepet", "sake", "canta"]); L["backc"] = Color(0.45, 0.35, 0.22)
			L["foot_style"] = _p(["zori", "sandal", "cizme"]); L["sandal"] = Color(0.35, 0.25, 0.15)
		"sennin":
			L["top"] = Color(0.3, 0.45, 0.3); L["top2"] = Color(0.2, 0.3, 0.2); L["top_style"] = "gi"
			L["pants"] = Color(0.3, 0.45, 0.3); L["pants_style"] = "bol"
			L["outer_style"] = "haori_uzun"; L["outer"] = Color(0.88, 0.2, 0.15); L["outer_pattern"] = 2; L["outer_accent"] = Color(0.98, 0.85, 0.3)
			L["back_item"] = "parsomen"; L["backc"] = Color(0.85, 0.78, 0.6)
			L["foot_style"] = "yuksek_sandal"
			L["band"] = V["band"]; L["band_style"] = "head"
		_:  # civ: sivil halk, çok çeşitli
			var r = randf()
			var t: Color = _p(SOFT)
			L["top"] = t; L["top2"] = t.darkened(0.12)
			if r < 0.3:
				L["top_style"] = "kimono"; L["top"] = _p(KIMONO); L["top2"] = _p(KIMONO); L["top_pattern"] = _p([0, 2, 6])
				L["hakama"] = _ch(0.2)
			else:
				L["top_style"] = _p(["uzun", "tisort", "tisort", "gi", "atlet", "uzun"]); L["top_pattern"] = _p([0, 0, 0, 2, 6, 4])
			L["pants"] = _p([Color(0.35, 0.3, 0.28), Color(0.2, 0.22, 0.3), Color(0.4, 0.35, 0.25), Color(0.3, 0.3, 0.33)])
			L["pants_style"] = _p(["sivil", "sivil", "kapri", "bol", "kisa_sort"])
			L["foot_style"] = _p(["zori", "zori", "sandal"]); L["sandal"] = _p([Color(0.3, 0.22, 0.15), Color(0.78, 0.68, 0.45)])
			if _ch(0.15):
				L["head_style"] = _p(["kasa", "hachimaki", "basortu"]); L["headgear"] = _p([Color(0.78, 0.66, 0.42), Color(0.9, 0.88, 0.85), Color(0.3, 0.35, 0.5)])
			if _ch(0.15):
				L["outer_style"] = _p(["haori", "atki", "kisa"]); L["outer"] = _p(SOFT)
			if _ch(0.12):
				L["back_item"] = _p(["sepet", "canta", "sake"]); L["backc"] = Color(0.6, 0.5, 0.35)
	# köy ninjaları (chūnin/jōnin/muhafız) oyuncuyla aynı köy setlerini giyer; köylüler ve diğerleri aynı kalır
	if arch in ["chunin", "guard", "jonin", "hunter"] and village in ["konoha", "suna", "kiri", "kumo", "iwa"]:
		var vk = {"konoha": "", "suna": "suna_", "kiri": "kiri_", "kumo": "kumo_", "iwa": "iwa_"}[village]
		var sid = "set_%s%s" % [vk, "jonin" if arch in ["jonin", "hunter"] else "chunin"]
		for k in ["guards", "guard_stripes", "knee_wraps", "pants_flap", "gloves", "outer_style", "rope_belt"]:
			L[k] = null if not k in ["knee_wraps", "gloves", "rope_belt"] else false
		L["outer_style"] = null
		Gear.preview_set_look(L, sid)
		L["thigh_holster"] = true
	L["sleeves"] = not L.get("top_style", "uzun") in ["tisort", "kolsuz", "atlet"]
	if L.get("top_style", "") in ["kimono"] and L["top_pattern"] == 0 and _ch(0.3):
		L["top_pattern"] = 6
	return L


## Kayda (JSON) girecek görünümler için: renkler html dizesi
static func roll_hex(arch: String, village := "") -> Dictionary:
	var L = roll(arch, village)
	for k in L:
		if L[k] is Color:
			L[k] = (L[k] as Color).to_html(false)
	return L


## Oyuncunun bulunduğu (ya da verilen konuma) en yakın köy
static func village_near(pos = null) -> String:
	if pos == null:
		pos = Game.player.global_position if Game.player and is_instance_valid(Game.player) else null
	if pos == null or Game.world_info.is_empty():
		return "konoha"
	var m = Game.to_map(pos)
	var best = "konoha"
	var bd = 1e18
	for v in Game.world_info.get("villages", []):
		var d = Vector2(v["x"], v["y"]).distance_squared_to(m)
		if d < bd:
			bd = d; best = String(v["id"])
	return best if VILLAGE.has(best) else "konoha"
