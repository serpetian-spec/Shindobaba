class_name KgPaths
extends RefCounted
## Kekkei genkai animedeki gibi kanla gelir, eğitimle öğrenilmez. Klan dışı yollar yalnız kanonda olanlar:
## - Klansız kan soyu (SOY): Darui'nin Ranton'u, Pakura'nın Shakuton'u gibi klan adı olmayan soylar (karakter yaratırken)
## - Jinchūriki: Son Gokū -> Yōton, Kokuō -> Futton (TailedBeasts.BEAST_NATURE)
## - Hücre nakli: Kök laboratuvarında Senju hücresi (Yamato / Danzō) -> Mokuton; Hashirama seviyesi teknikler yalnız Senju kanı
## - Usta-çırak: Jinton (kekkei tōta) Iwa'da Tsuchikage soyundan ustadan çırağa geçer
## - Göz nakli: Eyes (nakil göz çok chakra yer)

const RECIPES := {
	"hyoton": ["suiton", "fuuton"], "yoton": ["katon", "doton"], "futton": ["katon", "suiton"], "ranton": ["raiton", "suiton"],
	"shakuton": ["katon", "fuuton"], "bakuton": ["doton", "raiton"], "jiton": ["doton", "fuuton"],
}
const JINTON := ["fuuton", "katon", "doton"]
const NAMES := {"hyoton": "Hyōton (Buz)", "yoton": "Yōton (Lav)", "futton": "Futton (Kaynar Buhar)", "ranton": "Ranton (Fırtına)",
	"shakuton": "Shakuton (Kavurucu)", "bakuton": "Bakuton (Patlama)", "jiton": "Jiton (Mıknatıs)", "jinton": "Jinton (Toz — Kekkei Tōta)"}
## Klansız kan soyları: doğa, uyanış seviyesi (kan doğuştan gelir: baştan uyanık, klanlardaki gibi), hangi köylerde doğar
const SOY := {
	"ranton": {"name": "Ranton Soyu", "nature": "ranton", "level": 1, "villages": ["kumo"], "desc": "Kumo'da Darui gibi klan adı olmayan bir soy: su ve şimşeği tek chakrada taşır."},
	"yoton": {"name": "Yōton Soyu", "nature": "yoton", "level": 1, "villages": ["iwa"], "desc": "Iwa'da Kurotsuchi gibi ateş ve toprağı eriten kan."},
	"bakuton": {"name": "Bakuton Soyu", "nature": "bakuton", "level": 1, "villages": ["iwa"], "desc": "Iwa Patlama Birliği'nin kanı (Gari gibi): chakra dokunduğu yerde patlar."},
	"shakuton": {"name": "Shakuton Soyu", "nature": "shakuton", "level": 1, "villages": ["suna"], "desc": "Suna'da Pakura gibi nadir bir kan: ateş ve rüzgâr kavurucu kürelere döner."},
	"shoton": {"name": "Shōton Soyu", "nature": "shoton", "level": 1, "villages": ["konoha", "suna", "kiri", "kumo", "iwa"], "desc": "Guren gibi nadir doğan kristal kanı: chakra kristale dönüşür."},
}
## Kök laboratuvarı (Senju hücresi nakli) şartları
const LAB_LEVEL := 30
const LAB_COST_MULT := 1.3   # nakil hücreyle Mokuton chakrayı daha çok yer (beden yabancı hücreyle savaşır)
## Özel yerler (dünya harita koordinatı ülke merkezine göre)
const SITES := {
	"dust": {"country": "earth", "off": Vector2(2200, -4200), "nature": "jinton", "level": 70, "title": "Tozun Ustası"},
	"lab": {"country": "fire", "off": Vector2(3100, -2300), "nature": "mokuton", "level": LAB_LEVEL, "title": "Kök'ün Terk Edilmiş Laboratuvarı"},
	# Ay Mabedi (Tenseigan) Ōtsutsuki bölümüne kadar kapalı: "moon": {"country": "north", "off": Vector2(1500, 1200), "nature": "", "level": 40, "title": "Ay Mabedi"},
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


static func _here() -> Array:
	var m = Game.to_map(Game.player.global_position)
	return [m.x, m.y]


static func _near(at: Array, d: float) -> Array:
	var a = randf() * TAU
	return [float(at[0]) + cos(a) * d, float(at[1]) + sin(a) * d]


## Keşiş / volkan / toz tapınağı görevleri
static func site_quest(kind: String, at: Array) -> Dictionary:
	match kind:
		"lab":
			return {"title": "Senju Hücresi", "rank": "A", "village": Progress.home(), "hook": "Progress.kg_quest_done", "kg": "mokuton_nakil",
				"brief": "Kök'ün terk edilmiş laboratuvarında Shodai'nin hücreleriyle yapılan deneylerin kayıtları ve son hücre kabı duruyor. Altmış denekten yalnız biri sağ çıkmış. Kayıtları topla, kaçan deneği durdur ve nakle dayan.",
				"steps": [
					{"kind": "goto", "at": at, "r": 10.0, "name": "Laboratuvar Girişi", "text": "Laboratuvarın girişini bul."},
					{"kind": "collect", "at": _near(at, 90.0), "item": "deney kaydı", "n": 5, "spread": 22, "text": "Dağılmış deney kayıtlarını topla (5)."},
					{"kind": "kill", "at": _near(at, 260.0), "enemy": "rogue", "n": 3, "camp": true,
						"boss": {"name": "Kaçak Denek: Kırk Yedi Numara", "hp": 2600.0, "level": 34, "power": 2.8}, "text": "Bedeni ağaca dönmeye başlamış kaçak deneği durdur."},
					{"kind": "points", "at": at, "n": 1, "spread": 2, "label": "[F] Hücre kabını aç ve nakle gir", "fx": "seal", "text": "Son hücre kabıyla nakle gir."},
					{"kind": "defend", "at": at, "enemy": "rogue", "waves": [2, 3, 3], "text": "Hücreler bedeninde kök salarken laboratuvarı basan Kök ajanlarına dayan."}]}
		"moon":
			return {"title": "Ay Mabedi (Gizli S-Rank)", "rank": "S", "village": Progress.home(), "hook": "Progress.kg_quest_done", "kg": "tenseigan",
				"brief": "Mabedin taşlarında, gökten inen eski bir soyun ay chakrası mühürlü. Byakugan'ın onu görebiliyor: mühür taşlarını aç, mabedin bekçisini yen ve chakrayı gözlerine al.",
				"steps": [
					{"kind": "points", "at": at, "n": 5, "spread": 22, "label": "[F] Ay mühürünü çöz", "fx": "seal", "text": "Byakugan ile gördüğün ay mühürlerini çöz (5)."},
					{"kind": "kill", "at": _near(at, 260.0), "enemy": "rogue", "n": 3, "camp": true,
						"boss": {"name": "Ay Mabedi Bekçisi", "hp": 3800.0, "level": 50, "power": 3.8}, "text": "Mühürleri koruyan bekçiyi yen."},
					{"kind": "goto", "at": at, "r": 10.0, "name": "Ay Sunağı", "text": "Sunağa dön ve ay chakrasını gözlerine al."}]}
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
	if kind == "moon":
		_moon_site(it, s)
		return
	if Progress.has_nature(nat):
		Hud.dialog(s["title"], "Kan ve hücre zaten bedeninde. Ustalaşmaya devam et." if kind == "lab" else "Tozun sırrı artık senin. Ustalaşmaya devam et.", [])
		return
	var at = [Game.to_map(it["pos"]).x, Game.to_map(it["pos"]).y]
	var need = ""
	if kind == "dust":
		# Jinton yalnız Iwa'da, Tsuchikage soyunun ustasından çırağına geçer (Mū -> Ōnoki)
		if Progress.home() != "iwa":
			need = "Usta sırrını yalnız Iwa'nın shinobisine, kendi çırağına verir."
		for n in JINTON:
			if need == "" and not knows(n):
				need = "Üç doğayı bilmelisin: Fūton, Katon ve Doton."
		if need == "" and Gear.eff_rank(p) < 3:
			need = "Bu sır yalnızca Jōnin ve üstüne açılır."
		if need == "" and int(p["missions_done"].get("S", 0)) < 1:
			need = "En az bir S-rank görevi başarmış olmalısın."
	elif kind == "lab":
		if String(p.get("clan", "")) == "senju":
			need = "Senju kanı zaten bu hücreleri taşıyor."
		elif Gear.eff_rank(p) < 2:
			need = "Kayıtlara bakılırsa denekler en az Chūnin seviyesindeymiş. Bedenin henüz dayanamaz."
	if need == "" and int(p.get("level", 1)) < int(s["level"]):
		need = "Henüz hazır değilsin (Güç %d gerekli)." % int(s["level"])
	var intro = {"lab": "Paslı demir kapının ardında kırık cam tüpler ve kurumuş kökler var. Duvardaki kayıt: \"Denek 60/60... yalnız biri hayatta. Hücreler yabancı bedeni reddediyor.\"

Nakil Mokuton'u açar ama bedenin hücrelerle savaşır: Mokuton teknikleri %30 fazla chakra yer, Hashirama seviyesi teknikler (Mokujin, Mokuryū, Shin Sūsenju...) hiç açılmaz.",
		"dust": "Kayalara oyulmuş kulübede yaşlı bir Iwa ustası seni süzüyor: \"Üç doğayı tek küpte birleştiren, her şeyi toza çevirir. Bu sırrı ustam bana, ben de yalnız bir çırağa veririm.\""}.get(kind, "")
	if need != "":
		Hud.dialog(s["title"], intro + "\n\n" + need, [])
		return
	if not Missions.active().is_empty():
		Hud.dialog(s["title"], intro + "\n\nÖnce elindeki görevi bitir.", [])
		return
	Hud.dialog(s["title"], intro, [{"label": "Sınavı kabul et", "cb": func(): Missions.accept(site_quest(kind, at))}])


## Ay Mabedi: ustalaşmış (3/3) iki Byakugan + Sv.40, yalnız gece açılır
static func _moon_site(it: Dictionary, s: Dictionary) -> void:
	var p = pr()
	var intro = "Taş sunakta soluk mavi bir ay oyulmuş. Gözlerin olmadan bakınca sadece taş görüyorsun."
	var both = true
	for slot in ["sag_goz", "sol_goz"]:
		var g = Gear.equipped(p, slot)
		if g.is_empty() or g["id"] != "goz_byakugan" or int(g.get("lvl", 1)) < 3:
			both = false
	var have = Gear.equipped(p, "sag_goz").get("id", "") == "goz_tenseigan"
	if have:
		Hud.dialog(s["title"], "Sunaktaki ay artık senin gözlerinde parlıyor.", [])
		return
	var need = ""
	if not both:
		need = "Mühürleri yalnızca iki gözünde de tam ustalaşmış (3/3) Byakugan olan görebilir."
	elif int(p.get("level", 1)) < int(s["level"]):
		need = "Henüz hazır değilsin (Güç %d gerekli)." % int(s["level"])
	else:
		var tod = float(Game.world.env.time_of_day) if Game.world and Game.world.get("env") else 0.5
		if not (tod < 0.2 or tod > 0.8):
			need = "Mühürler yalnız ay ışığında görünür. Gece geri gel."
	if need == "":
		intro = "Byakugan'ınla bakınca taşın içinde dönen eski bir chakra görüyorsun: ayın chakrası. Mühürler gözlerini çağırıyor."
	if need != "":
		Hud.dialog(s["title"], intro + "

" + need, [])
		return
	if not Missions.active().is_empty():
		Hud.dialog(s["title"], intro + "

Önce elindeki görevi bitir.", [])
		return
	var at = [Game.to_map(it["pos"]).x, Game.to_map(it["pos"]).y]
	Hud.dialog(s["title"], intro, [{"label": "Mühürleri çöz", "cb": func(): Missions.accept(site_quest("moon", at))}])


## Görev bitince: uyanış
static func quest_done(m: Dictionary, ok: bool) -> void:
	if not ok:
		return
	var kg: String = m.get("kg", "")
	if kg == "":
		return
	if kg == "tenseigan":
		var ey = Game.player.combat.modes.eyes if Game.player and Game.player.combat and Game.player.combat.modes else null
		if ey:
			ey._replace_eyes("goz_tenseigan", ["sag_goz", "sol_goz"], 3)
		Hud.banner("TENSEIGAN", "Ayın eski chakrası Byakugan'ını mavi ay gözüne dönüştürdü", Color(0.55, 0.8, 1.0))
		Sfx.play("chakra", Game.player.global_position, 0.6)
		FX.aura(Game.player, Color(0.55, 0.8, 1.0), 2.0)
		return
	if kg == "mokuton_nakil":   # Senju hücresi nakli: Mokuton açılır, beden hücreyle savaşır (chakra bedeli)
		pr()["flags"]["senju_cells"] = true
		Progress.awaken_nature("mokuton")
		Hud.msg("Senju hücreleri bedeninde kök saldı. Mokuton artık senin — ama bedelini chakranla ödeyeceksin.", Color(0.55, 0.85, 0.45), 5.0)
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
			"lab":
				# yamaca gömülü beton sığınak, paslı kapı, kırık deney tüpleri ve kapıdan taşmış kurumuş kökler
				var y = g.call(0, 0)
				var stone = Color(0.42, 0.42, 0.4)
				b.box(Vector3(0, y + 2.2, 4), Vector3(12, 4.4, 9), stone)
				b.box(Vector3(0, y + 4.6, 4), Vector3(12.6, 0.5, 9.6), stone.darkened(0.2))
				b.box(Vector3(0, y + 1.5, -0.55), Vector3(2.6, 3.0, 0.2), Color(0.32, 0.2, 0.14), 0.0, false)   # paslı kapı
				b.kanji(Vector3(0, y + 3.7, -0.5), "根", 1.2, Color(0.15, 0.12, 0.1), 0)
				for k in 5:   # kırık cam tüpler
					var x = -5.0 + k * 2.5
					b.cyl(Vector3(x, g.call(x, -5) + 0.9, -5), 0.45, 1.8, Color(0.55, 0.7, 0.65), true, 10)
					b.cyl(Vector3(x, g.call(x, -5) + 1.9, -5), 0.5, 0.15, Color(0.3, 0.3, 0.3), true, 10)
				for k in 7:   # kapıdan ve çatlaklardan taşmış kurumuş Mokuton kökleri
					var a2 = -0.9 + k * 0.3
					b.cyl(Vector3(sin(a2) * 3.0, y + 0.25, -1.0 - cos(a2) * 2.0), 0.18, 0.5, Color(0.36, 0.26, 0.17), true, 6)
				b.lantern(-3.0, -2.0)
				b.interact(Vector3(0, y, -2.5), 7, "kg_site", "[F] Laboratuvar kapısını incele", {"site": "lab"})
			"dust":
				var y = g.call(0, 0)
				for i in 8:
					var a = TAU * i / 8.0
					b.box(Vector3(cos(a) * 14, y + 3.5, sin(a) * 14), Vector3(1.6, 7.0 if i % 3 != 0 else 3.0, 1.6), Color(0.78, 0.68, 0.5))
				b.box(Vector3(0, y + 0.6, 0), Vector3(9, 1.2, 9), Color(0.7, 0.6, 0.45))
				b.box(Vector3(0, y + 2.2, 0), Vector3(2.2, 2.2, 2.2), Color(0.95, 0.92, 0.85))  # toz küpü sunağı
				b.interact(Vector3(0, y, -6), 7, "kg_site", "[F] Yaşlı ustayla konuş", {"site": "dust"})
			"moon":
				var y = g.call(0, 0)
				b.cyl(Vector3(0, y + 0.4, 0), 18.0, 0.8, Color(0.82, 0.84, 0.9), true, 24)   # ay biçimli taş kaide
				for i in 6:   # hilal sütunları
					var a = TAU * i / 6.0
					b.box(Vector3(cos(a) * 7.5, y + 3.0, sin(a) * 7.5), Vector3(1.1, 5.2, 1.1), Color(0.75, 0.78, 0.88))
					b.box(Vector3(cos(a) * 7.5, y + 5.75, sin(a) * 7.5), Vector3(1.6, 0.3, 1.6), Color(0.6, 0.65, 0.8))
				b.box(Vector3(0, y + 1.5, 0), Vector3(2.4, 1.4, 1.2), Color(0.88, 0.9, 0.95))   # sunak
				b.cyl(Vector3(0, y + 3.2, 0), 1.8, 0.25, Color(0.6, 0.8, 1.0), false, 20)   # oyulmuş ay diski
				b.lantern(3.0, -6.0)
				b.lantern(-3.0, -6.0)
				b.interact(Vector3(0, y, -4.5), 7, "kg_site", "[F] Ay sunağına bak", {"site": "moon"})
		b.finish()
