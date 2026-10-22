class_name Gear
extends RefCounted
## Ekipman: kafa, üst/alt kıyafet, ayak, yelek, sağ el / sol el silahı.
## profile["gear"] = sahip olunan parçalar [{uid, id, c1, c2}], profile["equip"] = {yuva: uid}

const SLOTS := [["kafa", "Kafa"], ["govde", "Üst Kıyafet"], ["bacak", "Alt Kıyafet"], ["ayak", "Ayak"], ["zirh", "Yelek / Zırh"], ["sag", "Sağ El"], ["sol", "Sol El"]]
## Boş bırakılamayan yuvalar (çıplak kalınmaz)
const REQUIRED := ["govde", "bacak", "ayak"]

## stats: def (hasar azaltma puanı), hp, chakra, speed (oran), melee (oran)
## silah: dmg (oran), reach (m), style: blade | sword | fist | fan
const ITEMS := {
	# --- kafa
	"alin_koruyucu": {"name": "Alın Koruyucu", "slot": "kafa", "price": 0, "rank": 1, "desc": "Köyünün sembolü. Genin olunca verilir.", "stats": {"def": 2}, "look": {"band_style": "head"}, "c1": Color(0.15, 0.22, 0.55)},
	"alin_boyun": {"name": "Alın Koruyucu (Boyunda)", "slot": "kafa", "price": 0, "rank": 1, "desc": "Alın koruyucuyu boynuna bağlarsın.", "stats": {"def": 2}, "look": {"band_style": "neck"}, "c1": Color(0.15, 0.22, 0.55)},
	"bez_maske": {"name": "Bez Maske", "slot": "kafa", "price": 90, "rank": 0, "desc": "Yüzün alt yarısını örter. Kimliğini gizler.", "stats": {"def": 1, "chakra": 10}, "look": {"mask": "cloth"}, "c1": Color(0.15, 0.15, 0.2)},
	"anbu_maske": {"name": "ANBU Maskesi", "slot": "kafa", "price": 900, "rank": 4, "desc": "Gizli birliklerin hayvan maskesi.", "stats": {"def": 6, "melee": 0.05}, "look": {"mask": "anbu"}, "c1": Color(0.95, 0.95, 0.95)},
	# --- üst
	"tisort": {"name": "Kısa Kollu Tişört", "slot": "govde", "price": 40, "rank": 0, "desc": "Hafif ve rahat.", "stats": {"speed": 0.03}, "look": {"top_style": "tisort"}, "c1": Color(0.75, 0.2, 0.25), "c2": Color(0.12, 0.12, 0.14)},
	"uzun_gomlek": {"name": "Uzun Kollu Ninja Gömleği", "slot": "govde", "price": 120, "rank": 0, "desc": "Klasik shinobi gömleği.", "stats": {"def": 2}, "look": {"top_style": "uzun"}, "c1": Color(0.15, 0.2, 0.33), "c2": Color(0.12, 0.12, 0.14)},
	"ceket": {"name": "Fermuarlı Ceket", "slot": "govde", "price": 200, "rank": 0, "desc": "İki renkli, yüksek yakalı eğitim ceketi.", "stats": {"def": 3, "hp": 10}, "look": {"top_style": "ceket"}, "c1": Color(0.95, 0.5, 0.12), "c2": Color(0.12, 0.12, 0.14)},
	"yakali": {"name": "Yüksek Yakalı Gömlek", "slot": "govde", "price": 180, "rank": 0, "desc": "Bilek sargılı, kısa kollu. Chakra akışını rahatlatır.", "stats": {"def": 2, "chakra": 15}, "look": {"top_style": "yakali"}, "c1": Color(0.15, 0.2, 0.33), "c2": Color(0.12, 0.12, 0.14)},
	"zirhli_gomlek": {"name": "Zırh Örgülü Gömlek", "slot": "govde", "price": 450, "rank": 1, "desc": "İçine ince zincir örgü dikilmiş uzun kollu gömlek.", "stats": {"def": 6, "speed": -0.02}, "look": {"top_style": "uzun"}, "c1": Color(0.2, 0.22, 0.24), "c2": Color(0.12, 0.12, 0.14)},
	# --- alt
	"ninja_pant": {"name": "Ninja Pantolonu", "slot": "bacak", "price": 100, "rank": 0, "desc": "Baldırdan sargılı, hareket kısıtlamaz.", "stats": {"def": 2}, "look": {"pants_style": "ninja"}, "c1": Color(0.15, 0.2, 0.33)},
	"sort": {"name": "Diz Altı Şort", "slot": "bacak", "price": 80, "rank": 0, "desc": "Hafif. Koşu hızı biraz artar.", "stats": {"speed": 0.04}, "look": {"pants_style": "sort"}, "c1": Color(0.15, 0.15, 0.17)},
	"sivil_pant": {"name": "Uzun Pantolon", "slot": "bacak", "price": 40, "rank": 0, "desc": "Sivil kıyafeti.", "stats": {}, "look": {"pants_style": "sivil"}, "c1": Color(0.35, 0.3, 0.28)},
	# --- ayak
	"sandalet": {"name": "Ninja Sandaleti", "slot": "ayak", "price": 60, "rank": 0, "desc": "Açık burunlu shinobi sandaleti ve baldır sargıları.", "stats": {"speed": 0.03}, "look": {}, "c1": Color(0.15, 0.2, 0.32), "c2": Color(0.92, 0.92, 0.9)},
	"takviyeli_sandalet": {"name": "Takviyeli Sandalet", "slot": "ayak", "price": 260, "rank": 1, "desc": "Metal tabanlı, tekmeler daha sert.", "stats": {"def": 2, "melee": 0.06}, "look": {}, "c1": Color(0.12, 0.12, 0.14), "c2": Color(0.92, 0.92, 0.9)},
	# --- yelek
	"chunin_yelek": {"name": "Taktik Yelek", "slot": "zirh", "price": 0, "rank": 2, "desc": "Chunin ve Jonin'lerin parşömen cepli yeleği.", "stats": {"def": 10, "hp": 20}, "look": {}, "c1": Color(0.38, 0.48, 0.28)},
	"anbu_zirh": {"name": "ANBU Zırhı", "slot": "zirh", "price": 0, "rank": 4, "desc": "Hafif metal göğüs zırhı.", "stats": {"def": 14, "speed": 0.03}, "look": {}, "c1": Color(0.75, 0.75, 0.78)},
	"deri_yelek": {"name": "Deri Yelek", "slot": "zirh", "price": 350, "rank": 1, "desc": "Paralı askerlerin sevdiği kalın yelek.", "stats": {"def": 6}, "look": {}, "c1": Color(0.4, 0.3, 0.2)},
	# --- silahlar
	"kunai": {"name": "Kunai", "slot": "el", "price": 30, "rank": 0, "desc": "Her ninjanın yakın dövüş bıçağı.", "stats": {}, "weapon": {"dmg": 1.15, "reach": 0.15, "style": "blade"}, "c1": Color(0.6, 0.62, 0.66)},
	"tanto": {"name": "Tantō", "slot": "el", "price": 320, "rank": 1, "desc": "Kısa kılıç. Hızlı ve keskin.", "stats": {}, "weapon": {"dmg": 1.35, "reach": 0.35, "style": "blade"}, "c1": Color(0.75, 0.77, 0.8)},
	"katana": {"name": "Katana", "slot": "sag", "price": 900, "rank": 2, "desc": "Uzun kılıç. Geniş kesişler, yüksek hasar.", "stats": {"speed": -0.02}, "weapon": {"dmg": 1.7, "reach": 0.9, "style": "sword"}, "c1": Color(0.78, 0.8, 0.84)},
	"musta": {"name": "Muşta Bıçağı", "slot": "el", "price": 450, "rank": 1, "desc": "Parmak korumalı çift bıçak. Rüzgar chakrası akıtılabilir.", "stats": {"melee": 0.1}, "weapon": {"dmg": 1.3, "reach": 0.25, "style": "blade"}, "c1": Color(0.55, 0.57, 0.6)},
	"tonfa": {"name": "Tonfa", "slot": "el", "price": 220, "rank": 0, "desc": "Savunma sopası. Gelen hasarı azaltır.", "stats": {"def": 4}, "weapon": {"dmg": 1.2, "reach": 0.3, "style": "blade"}, "c1": Color(0.35, 0.25, 0.15)},
	"yelpaze": {"name": "Savaş Yelpazesi", "slot": "sag", "price": 700, "rank": 2, "desc": "Büyük demir yelpaze. Fuuton jutsularını güçlendirir.", "stats": {"chakra": 30}, "weapon": {"dmg": 1.4, "reach": 0.8, "style": "sword"}, "c1": Color(0.85, 0.82, 0.75)},
}

## Mağazada satılanlar
const SHOP_CLOTHES := ["tisort", "uzun_gomlek", "ceket", "yakali", "zirhli_gomlek", "ninja_pant", "sort", "sivil_pant", "sandalet", "takviyeli_sandalet", "deri_yelek", "bez_maske", "anbu_maske"]
const SHOP_WEAPONS := ["kunai", "tanto", "tonfa", "musta", "katana", "yelpaze"]


static func item(id: String) -> Dictionary:
	return ITEMS.get(id, {})


static func fits(id: String, slot: String) -> bool:
	var s: String = item(id).get("slot", "")
	return s == slot or (s == "el" and slot in ["sag", "sol"])


static func _hex(c) -> String:
	return Color(c).to_html(false)


## Envantere parça ekler, uid döner
static func grant(p: Dictionary, id: String, equip_slot := "", c1 = null, c2 = null) -> int:
	var it = item(id)
	if it.is_empty():
		return -1
	var uid = int(p.get("gear_uid", 0)) + 1
	p["gear_uid"] = uid
	var g = {"uid": uid, "id": id, "c1": _hex(c1 if c1 != null else it.get("c1", Color.WHITE)), "c2": _hex(c2 if c2 != null else it.get("c2", it.get("c1", Color.WHITE)))}
	p["gear"].append(g)
	if equip_slot != "":
		p["equip"][equip_slot] = uid
	return uid


static func find(p: Dictionary, uid) -> Dictionary:
	for g in p.get("gear", []):
		if int(g["uid"]) == int(uid):
			return g
	return {}


static func equipped(p: Dictionary, slot: String) -> Dictionary:
	return find(p, p.get("equip", {}).get(slot, -1))


static func owned_for(p: Dictionary, slot: String) -> Array:
	var out = []
	for g in p.get("gear", []):
		if fits(g["id"], slot) and int(item(g["id"]).get("rank", 0)) <= int(p.get("rank", 0)):
			out.append(g)
	return out


## Eski kayıtlar / yeni karakter: görünümden başlangıç ekipmanı üretir
static func ensure(p: Dictionary) -> void:
	if p.has("gear") and p.has("equip"):
		return
	p["gear"] = []
	p["equip"] = {}
	var L: Dictionary = p.get("look", {})
	var top_id = {"tisort": "tisort", "uzun": "uzun_gomlek", "ceket": "ceket", "yakali": "yakali"}.get(L.get("top_style", "ceket"), "ceket")
	grant(p, top_id, "govde", L.get("top", null), L.get("top2", null))
	grant(p, {"sort": "sort", "sivil": "sivil_pant"}.get(L.get("pants_style", "ninja"), "ninja_pant"), "bacak", L.get("pants", null))
	grant(p, "sandalet", "ayak", L.get("sandal", null), L.get("wraps", null))
	grant(p, "kunai", "sag")
	if L.get("band") != null:
		grant(p, "alin_koruyucu", "kafa", L["band"])
		grant(p, "alin_boyun", "", L["band"])
	if L.get("vest") != null:
		grant(p, "anbu_zirh" if int(p.get("rank", 0)) >= 4 else "chunin_yelek", "zirh", L["vest"])
	apply_look(p)


## Takılı parçalardan görünüm sözlüğünü yeniden kurar
static func apply_look(p: Dictionary) -> void:
	var L: Dictionary = p["look"]
	for k in ["band", "vest", "mask", "weapon_r", "weapon_l"]:
		L[k] = null
	L["band_style"] = "none"
	for s in SLOTS:
		var g = equipped(p, s[0])
		if g.is_empty():
			continue
		var it = item(g["id"])
		var c1 = Color.html(g["c1"]); var c2 = Color.html(g["c2"])
		for k in it.get("look", {}):
			L[k] = it["look"][k]
		match s[0]:
			"kafa":
				if it["look"].has("band_style"):
					L["band"] = c1
			"govde":
				L["top"] = c1
				L["top2"] = c2
				L["sleeves"] = it["look"]["top_style"] != "tisort"
			"bacak":
				L["pants"] = c1
			"ayak":
				L["sandal"] = c1
				L["wraps"] = c2
			"zirh":
				L["vest"] = c1
			"sag":
				L["weapon_r"] = g["id"]
			"sol":
				L["weapon_l"] = g["id"]


## Takılı parçaların toplam istatistiği
static func stat(p: Dictionary, key: String) -> float:
	var v = 0.0
	for s in SLOTS:
		var g = equipped(p, s[0])
		if not g.is_empty():
			v += float(item(g["id"]).get("stats", {}).get(key, 0.0))
	return v


## Sağ el (yoksa sol el) silahı: {dmg, reach, style}
static func weapon(p: Dictionary) -> Dictionary:
	for s in ["sag", "sol"]:
		var g = equipped(p, s)
		if not g.is_empty() and item(g["id"]).has("weapon"):
			var w: Dictionary = item(g["id"])["weapon"].duplicate()
			# iki elde de silah varsa küçük bonus
			var other = equipped(p, "sol" if s == "sag" else "sag")
			if not other.is_empty() and item(other["id"]).has("weapon"):
				w["dmg"] = float(w["dmg"]) + 0.15
			return w
	return {"dmg": 1.0, "reach": 0.0, "style": "fist"}


static func stats_text(id: String) -> String:
	var it = item(id)
	var parts = []
	var names = {"def": "Savunma", "hp": "Can", "chakra": "Chakra", "speed": "Hız", "melee": "Yakın dövüş"}
	for k in it.get("stats", {}):
		var v = float(it["stats"][k])
		if k in ["speed", "melee"]:
			parts.append("%s %+d%%" % [names[k], int(round(v * 100))])
		else:
			parts.append("%s %+d" % [names[k], int(v)])
	if it.has("weapon"):
		parts.push_front("Hasar x%.2f, menzil +%.1fm" % [it["weapon"]["dmg"], it["weapon"]["reach"]])
	return ", ".join(parts) if not parts.is_empty() else "—"
