class_name KgPaths
extends RefCounted
## Klan dışı kekkei genkai yolları:
## - "Doğa Dönüşümü" eğitimi (her köy eğitmeni): iki ana doğayı ustalıkla bilen birleşik doğayı görevle uyandırır
## - Dağ keşişi (Don Ülkesi): Hyōton  •  Volkan sınavı (Toprak Ülkesi): Yōton
## - Rüzgar Ülkesi'nde gömülü tapınak: Jinton (kekkei tōta, üç doğa + gizli S-rank görev)
## Mokuton yalnızca Senju soyuna özgüdür.

const RECIPES := {
	"hyoton": ["suiton", "fuuton"], "yoton": ["katon", "doton"], "futton": ["katon", "suiton"], "ranton": ["raiton", "suiton"],
	"shakuton": ["katon", "fuuton"], "bakuton": ["doton", "raiton"], "jiton": ["doton", "fuuton"],
}
const JINTON := ["fuuton", "katon", "doton"]
const NAMES := {"hyoton": "Hyōton (Buz)", "yoton": "Yōton (Lav)", "futton": "Futton (Kaynar Buhar)", "ranton": "Ranton (Fırtına)",
	"shakuton": "Shakuton (Kavurucu)", "bakuton": "Bakuton (Patlama)", "jiton": "Jiton (Mıknatıs)", "jinton": "Jinton (Toz — Kekkei Tōta)"}
## Eğitmenle birleştirme için şartlar
const TRAIN_LEVEL := 30
const TRAIN_JUTSU_PER_PARENT := 2
const TRAIN_PRICE := 5000
## Özel yerler (dünya harita koordinatı ülke merkezine göre)
const SITES := {
	"hermit": {"country": "frost", "off": Vector2(1400, 900), "nature": "hyoton", "level": 35, "title": "Buz Keşişi"},
	"volcano": {"country": "earth", "off": Vector2(2200, -4200), "nature": "yoton", "level": 35, "title": "Kızıl Krater"},
	"dust": {"country": "wind", "off": Vector2(-3800, -2600), "nature": "jinton", "level": 70, "title": "Gömülü Toz Tapınağı"},
}


static func pr() -> Dictionary:
	return Game.profile


## Oyuncunun bir doğadaki ustalığı: o doğadan öğrendiği jutsu sayısı
static func mastery(n: String) -> int:
	var c = 0
	for jid in pr().get("learned", []):
		var jv = Data.jutsu.get(jid, {})
		if not jv is Dictionary:
			continue
		var j: Dictionary = jv
		if String(j.get("element", "")) == n or n in j.get("elements", []):
			c += 1
	return c


static func knows(n: String) -> bool:
	return n in pr().get("elements", [])


## Eğitmen için "Doğa Dönüşümü" seçenekleri (Progress.interact "trainer" ekler)
static func trainer_options() -> Array:
	var opts = []
	var p = pr()
	if p.is_empty() or int(p.get("level", 1)) < TRAIN_LEVEL:
		return opts
	if not String(p.get("active_mission", {}).get("title", "")).is_empty():
		return opts
	for kg in RECIPES:
		if Progress.has_nature(kg):
			continue
		var par: Array = RECIPES[kg]
		if not (knows(par[0]) and knows(par[1])):
			continue
		var ok = mastery(par[0]) >= TRAIN_JUTSU_PER_PARENT and mastery(par[1]) >= TRAIN_JUTSU_PER_PARENT
		var k = kg
		opts.append({"label": "Doğa Dönüşümü: %s (%d Ryō)" % [NAMES[kg], TRAIN_PRICE] + ("" if ok else "  — her iki doğadan %d jutsu gerekli" % TRAIN_JUTSU_PER_PARENT),
			"tip": "%s + %s doğalarını tek chakrada birleştir." % [par[0].capitalize(), par[1].capitalize()],
			"cb": func():
				if not ok:
					Hud.msg("Önce her iki doğada da en az %d jutsu öğrenmelisin." % TRAIN_JUTSU_PER_PARENT, Color(1, 0.7, 0.4))
					return
				if int(pr()["ryo"]) < TRAIN_PRICE:
					Hud.msg("Yeterli Ryō yok.", Color(1, 0.5, 0.4))
					return
				Progress.add_ryo(-TRAIN_PRICE)
				Missions.accept(_q_fusion(k))})
	return opts


static func _here() -> Array:
	var m = Game.to_map(Game.player.global_position)
	return [m.x, m.y]


static func _near(at: Array, d: float) -> Array:
	var a = randf() * TAU
	return [float(at[0]) + cos(a) * d, float(at[1]) + sin(a) * d]


## Eğitmen yolu: meditasyon (iki chakrayı dengele) + kontrol sınavı (dalgalar)
static func _q_fusion(kg: String) -> Dictionary:
	var at = _here()
	var spot = _near(at, 120.0)
	var par: Array = RECIPES[kg]
	return {"title": "Doğa Dönüşümü: %s" % NAMES[kg], "rank": "A", "village": Progress.home(), "hook": "Progress.kg_quest_done", "kg": kg,
		"brief": "%s ve %s chakralarını aynı anda yoğurmayı öğren. Önce dengeyi bul, sonra yeni doğanı savaşta kontrol et." % [par[0].capitalize(), par[1].capitalize()],
		"steps": [
			{"kind": "goto", "at": spot, "r": 10.0, "name": "Meditasyon Alanı", "text": "Sakin bir açıklığa git."},
			{"kind": "points", "at": spot, "n": 5, "spread": 10, "label": "[F] İki doğayı dengele", "fx": "seal", "text": "Chakra düğümlerinde iki doğayı dengele (5)."},
			{"kind": "defend", "at": spot, "enemy": "rogue", "waves": [2, 3, 3], "text": "Kararsız chakrayı savaşta kontrol et: dalgaları püskürt."}]}


## Keşiş / volkan / toz tapınağı görevleri
static func site_quest(kind: String, at: Array) -> Dictionary:
	match kind:
		"hermit":
			return {"title": "Buz Keşişinin Sınavı", "rank": "A", "village": Progress.home(), "hook": "Progress.kg_quest_done", "kg": "hyoton",
				"brief": "Dağdaki yaşlı keşiş, su ve rüzgârı donduran soyu kayıp bir tekniği öğretebilir. Ama önce buz kristallerini topla ve kaçak buz ninjasını durdur.",
				"steps": [
					{"kind": "collect", "at": _near(at, 160.0), "item": "buz kristali", "n": 6, "spread": 30, "text": "Kar tepelerinden buz kristali topla (6)."},
					{"kind": "kill", "at": _near(at, 420.0), "enemy": "kiri", "n": 3, "camp": true,
						"boss": {"name": "Kaçak Buz Ninjası Fuyumi", "hp": 1600.0, "level": 40, "power": 3.0}, "text": "Kaçak buz ninjasını yen."},
					{"kind": "goto", "at": at, "r": 12.0, "name": "Keşişin Kulübesi", "text": "Kristallerle keşişe dön."}]}
		"volcano":
			return {"title": "Kızıl Krater Sınavı", "rank": "A", "village": Progress.home(), "hook": "Progress.kg_quest_done", "kg": "yoton",
				"brief": "Krater bekçileri, ateşi ve toprağı tek bedende eritmeyi yalnızca lavın ortasında ayakta kalana öğretir.",
				"steps": [
					{"kind": "goto", "at": _near(at, 60.0), "r": 12.0, "name": "Krater Kenarı", "text": "Kraterin kenarına in."},
					{"kind": "points", "at": at, "n": 6, "spread": 26, "label": "[F] Lav ağzını mühürle", "fx": "seal", "text": "Taşan lav ağızlarını chakranla mühürle (6)."},
					{"kind": "defend", "at": at, "enemy": "iwa", "waves": [3, 3, 4], "text": "Krater muhafızlarının sınavına dayan."}]}
		"dust":
			return {"title": "Toz Tapınağı (Gizli S-Rank)", "rank": "S", "village": Progress.home(), "hook": "Progress.kg_quest_done", "kg": "jinton",
				"brief": "Kumların altındaki tapınak, üç doğayı tek bir küpte birleştiren yasak tekniği saklıyor. Muhafızı geçen, tozun sırrını öğrenir.",
				"steps": [
					{"kind": "track", "from": at, "to": _near(at, 700.0), "text": "Kumdaki eski izleri takip et."},
					{"kind": "kill", "at": _near(at, 700.0), "enemy": "rogue", "n": 4, "camp": true,
						"boss": {"name": "Toz Tapınağı Muhafızı", "hp": 4500.0, "level": 75, "power": 4.2}, "text": "Tapınak muhafızını yen."},
					{"kind": "goto", "at": at, "r": 12.0, "name": "Tapınak Sunağı", "text": "Sunağa dön ve tozun sırrını öğren."}]}
	return {}


## Özel yer etkileşimi (Progress.interact "kg_site")
static func interact_site(it: Dictionary) -> void:
	var kind: String = it.get("site", "")
	var s: Dictionary = SITES.get(kind, {})
	var p = pr()
	var nat: String = s.get("nature", "")
	if Progress.has_nature(nat):
		Hud.dialog(s["title"], "Bu doğa zaten kanında akıyor. Ustalaşmaya devam et.", [])
		return
	var at = [Game.to_map(it["pos"]).x, Game.to_map(it["pos"]).y]
	var need = ""
	if kind == "dust":
		for n in JINTON:
			if not knows(n):
				need = "Üç doğayı bilmelisin: Fūton, Katon ve Doton."
		if need == "" and int(p.get("rank", 0)) < 3:
			need = "Bu sır yalnızca Jōnin ve üstüne açılır."
		if need == "" and int(p["missions_done"].get("S", 0)) < 1:
			need = "En az bir S-rank görevi başarmış olmalısın."
	else:
		var par: Array = RECIPES[nat]
		if not (knows(par[0]) and knows(par[1])):
			need = "Bu tekniği öğrenmek için %s ve %s doğalarını bilmelisin." % [par[0].capitalize(), par[1].capitalize()]
	if need == "" and int(p.get("level", 1)) < int(s["level"]):
		need = "Henüz hazır değilsin (Seviye %d gerekli)." % int(s["level"])
	var intro = {"hermit": "Yaşlı keşiş karların içinden sana bakıyor: \"Su ve rüzgâr... ikisini de taşıyorsun. Donmayı öğrenmek ister misin?\"",
		"volcano": "Krater bekçisi: \"Ateşin ve toprağın var. Lav, ikisinin çocuğudur. Kraterde ayakta kalabilir misin?\"",
		"dust": "Kumların altındaki sunakta eski yazılar parlıyor: \"Üç doğayı birleştiren, her şeyi toza çevirir.\""}.get(kind, "")
	if need != "":
		Hud.dialog(s["title"], intro + "\n\n" + need, [])
		return
	if not Missions.active().is_empty():
		Hud.dialog(s["title"], intro + "\n\nÖnce elindeki görevi bitir.", [])
		return
	Hud.dialog(s["title"], intro, [{"label": "Sınavı kabul et", "cb": func(): Missions.accept(site_quest(kind, at))}])


## Görev bitince: uyanış
static func quest_done(m: Dictionary, ok: bool) -> void:
	if not ok:
		return
	var kg: String = m.get("kg", "")
	if kg == "":
		return
	Progress.awaken_nature(kg)
	if kg == "jinton":
		Hud.msg("Kekkei Tōta: üç doğa artık tek bir küpte birleşiyor.", Color(0.95, 0.9, 0.7), 4.0)


## Dünyaya keşiş kulübesi, krater ve toz tapınağı yerleştir (World.build -> Sites)
static func build_all(parent: Node3D) -> void:
	for kind in SITES:
		var s: Dictionary = SITES[kind]
		var c = {}
		for cc in Game.world_info["countries"]:
			if cc["id"] == s["country"]:
				c = cc
		if c.is_empty():
			continue
		var p = Vector2(float(c["x"]), float(c["y"])) + s["off"]
		var base = Game.terrain_height(p.x, -p.y)
		if base < 1.0:
			p = Vector2(float(c["x"]), float(c["y"])) + s["off"] * 0.5
			base = Game.terrain_height(p.x, -p.y)
		var b = Builder.new(parent, p.x, p.y, base, "KG_%s" % kind)
		var g = func(x: float, n: float) -> float:
			return Game.terrain_height(p.x + x, -(p.y + n)) - base
		match kind:
			"hermit":
				var y = g.call(0, 0)
				b.box(Vector3(0, y + 1.6, 0), Vector3(7, 3.2, 6), Color(0.45, 0.35, 0.28))
				b.roof(Vector3(0, y + 4.2, 0), Vector3(8.5, 2.2, 7.5), Color(0.92, 0.95, 1.0))
				b.box(Vector3(0, y + 1.2, -3.05), Vector3(1.4, 2.4, 0.2), Color(0.25, 0.18, 0.12), 0.0, false)
				for i in 7:
					var a = TAU * i / 7.0
					b.cone(Vector3(cos(a) * 12, g.call(cos(a) * 12, sin(a) * 12) + 1.8, sin(a) * 12), 1.6, 3.6, Color(0.7, 0.88, 1.0))
				b.lantern(3.5, -4.5)
				b.interact(Vector3(0, y, -5), 7, "kg_site", "[F] Buz Keşişi ile konuş", {"site": "hermit"})
			"volcano":
				var y = g.call(0, 0)
				b.cyl(Vector3(0, y + 6, 0), 70.0, 12.0, Color(0.32, 0.22, 0.18), true, 24)  # krater duvarı
				b.cyl(Vector3(0, y + 12.1, 0), 46.0, 0.3, Color(1.0, 0.45, 0.1), false, 24)  # lav gölü
				for i in 5:
					var a = TAU * i / 5.0 + 0.3
					b.cone(Vector3(cos(a) * 40, y + 15, sin(a) * 40), 10.0, 14.0, Color(0.28, 0.2, 0.17))
				# dışarıda bekçi kulübesi + krater ağzına çıkan taş merdiven
				var oy = g.call(0, -44)
				b.box(Vector3(0, oy + 1.5, -46), Vector3(6, 3, 5), Color(0.35, 0.25, 0.2))
				b.roof(Vector3(0, oy + 3.8, -46), Vector3(7, 1.8, 6), Color(0.5, 0.18, 0.12))
				for k in 12:
					b.box(Vector3(8, oy + 0.5 + k * 1.0, -42 + k * 0.6), Vector3(3, 1.0, 1.2), Color(0.4, 0.32, 0.26))
				b.lantern(-4, -43)
				b.interact(Vector3(0, oy, -42), 7, "kg_site", "[F] Krater bekçisiyle konuş", {"site": "volcano"})
				Steam.add(b.w(Vector3(0, 12.4, 0)))
			"dust":
				var y = g.call(0, 0)
				for i in 8:
					var a = TAU * i / 8.0
					b.box(Vector3(cos(a) * 14, y + 3.5, sin(a) * 14), Vector3(1.6, 7.0 if i % 3 != 0 else 3.0, 1.6), Color(0.78, 0.68, 0.5))
				b.box(Vector3(0, y + 0.6, 0), Vector3(9, 1.2, 9), Color(0.7, 0.6, 0.45))
				b.box(Vector3(0, y + 2.2, 0), Vector3(2.2, 2.2, 2.2), Color(0.95, 0.92, 0.85))  # toz küpü sunağı
				b.interact(Vector3(0, y, -6), 7, "kg_site", "[F] Sunaktaki yazıları oku", {"site": "dust"})
		b.finish()
