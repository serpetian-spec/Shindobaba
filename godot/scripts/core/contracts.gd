class_name Contracts
extends RefCounted
## Çağırma sözleşmeleri (Kuchiyose), boy kademeleri, ortak jutsular, ters çağırma ve sözleşmeye özel Sennin Modları.
## profile["contracts"] = {id: {"mastery": sn, "sage": bool, "sage_trials": n}}, profile["summon"] = aktif sözleşme
## Kademe: 0 küçük (haberci/izci), 1 orta (savaşçı), 2 dev (binek/boss). Chakra ve ustalıkla açılır.

const TIER_NAMES := ["Küçük", "Orta", "Dev"]
const TIER_COST := [12.0, 40.0, 90.0]
const TIER_UPKEEP := [0.0, 1.2, 3.0]          # chakra/sn
const TIER_LIFE := [90.0, 60.0, 45.0]
const TIER_MASTERY := [0.0, 20.0, 90.0]       # kademe için gereken ustalık (sn çağrılı kalma)
const TIER_LEVEL := [1, 8, 18]

## Sözleşmeler. realm: gizli yer (sennin eğitimi + sözleşme), sage: sennin modu var mı
const DEFS := {
	"kurbağa": {"name": "Kurbağa Sözleşmesi", "animal": "Kurbağalar", "realm": "Gamayama: Kurbağa Dağı", "sage": true, "color": Color(1.0, 0.55, 0.15),
		"sage_name": "Kurbağa Sennin Modu", "elder": "Bilge Gerotora", "realm_target": Vector2(6500, -7500),
		"intro": "Dev mantarların ve kurbağa yağı şelalelerinin dağına hoş geldin, yavrum. Sözleşmeyi kanınla imzalarsan kurbağalar sana yoldaş olur.",
		"tiers": {
			0: {"name": "Haberci Kurbağa Kero", "model": "toad_small", "h": 0.55, "hp": 60.0, "role": "scout", "dmg": 8.0, "speed": 8.0,
				"lines": ["Kero kero! Atıştırmalık getirdin mi?", "Etrafa bakarım, düşman görünce bağırırım!", "Yine mi işe çağırdın beni?"]},
			1: {"name": "Savaşçı Kurbağa Gamaken", "model": "toad_mid", "h": 3.6, "hp": 420.0, "role": "fighter", "dmg": 28.0, "speed": 9.0,
				"lines": ["Bıçaklarım hazır, ortak!", "Arkanı ben kollarım.", "Kurbağa onuru için!"]},
			2: {"name": "Kurbağa Reisi Gamaō", "model": "toad_boss", "h": 17.0, "hp": 2400.0, "role": "giant", "dmg": 90.0, "speed": 11.0, "mount": true,
				"lines": ["BENİ NE DİYE ÇAĞIRDIN VELET!", "Kafama çık, şunu ezelim!", "Yağımı ateşinle birleştir, görsünler!"]},
		}},
	"yılan": {"name": "Yılan Sözleşmesi", "animal": "Yılanlar", "realm": "Hebiana: Yılan Mağarası", "sage": true, "color": Color(0.65, 0.35, 0.85),
		"sage_name": "Yılan Sennin Modu", "elder": "Ak Yılan Bilge Shiramiya", "realm_target": Vector2(4300, 7600),
		"intro": "Ssss... Mağarama cesaretle giren azdır. Güç istiyorsan bedelini ödersin. Sözleşmeyi imzala, yılanlar seni kuşatsın.",
		"tiers": {
			0: {"name": "Yılan Sürüsü", "model": "snake_swarm", "h": 0.6, "hp": 80.0, "role": "binder", "dmg": 10.0, "speed": 9.0,
				"lines": ["Ssss...", "Avımız nerede?"]},
			1: {"name": "Dev Yılan Kuromaru", "model": "snake_giant", "h": 3.0, "len": 14.0, "hp": 600.0, "role": "fighter", "dmg": 34.0, "speed": 12.0,
				"lines": ["Bana kurban mı getirdin?", "Zehrim hazır.", "Ssss... Sabrım sınırsız değil."]},
			2: {"name": "Yılan Hükümdarı Orochigane", "model": "snake_boss", "h": 11.0, "len": 70.0, "hp": 3200.0, "role": "giant", "dmg": 110.0, "speed": 14.0, "mount": true,
				"lines": ["Karşılığında yüz kurban isterim!", "Böyle küçük bir iş için mi uyandırdın beni?!", "Ezilin!"]},
		}},
	"sümüklü": {"name": "Sümüklüböcek Sözleşmesi", "animal": "Sümüklüböcekler", "realm": "Namekumori: Sisli Sümüklüböcek Ormanı", "sage": true, "color": Color(0.55, 0.85, 0.55),
		"sage_name": "Sümüklüböcek Sennin Modu", "elder": "Bilge Ana Namekura", "realm_target": Vector2(10500, -11000),
		"intro": "Yavaş ama sabırlı olan yaşar, çocuğum. Şifanın yolunu öğrenmek istersen sözleşmemize katıl.",
		"tiers": {
			0: {"name": "Şifa Parçacıkları", "model": "slug_frag", "h": 0.35, "hp": 50.0, "role": "healer", "dmg": 0.0, "speed": 7.0,
				"lines": ["Yaralarını iyileştiriyorum...", "Sakin ol, buradayız."]},
			1: {"name": "Asit Sümüklüböceği", "model": "slug_acid", "h": 3.5, "len": 9.0, "hp": 520.0, "role": "fighter", "dmg": 26.0, "speed": 6.0,
				"lines": ["Asidim zırhları eritir.", "Yanından ayrılmam."]},
			2: {"name": "Sümüklüböcek Kraliçesi Katsume", "model": "slug_queen", "h": 14.0, "len": 34.0, "hp": 3000.0, "role": "giant_healer", "dmg": 70.0, "speed": 7.0, "mount": true,
				"lines": ["Bölünüp herkesi iyileştireceğim.", "Asit dalgası geliyor, çekil!", "Merak etme, kimse ölmeyecek."]},
		}},
	"şahin": {"name": "Şahin Sözleşmesi", "animal": "Şahinler", "realm": "", "sage": false, "color": Color(0.8, 0.65, 0.45), "keeper": "kumo",
		"intro": "Gökyüzü sınır tanımaz. Şahinler seni taşır.",
		"tiers": {
			0: {"name": "Haberci Şahin", "model": "hawk_small", "h": 0.7, "hp": 50.0, "role": "scout", "dmg": 8.0, "speed": 14.0, "fly": true, "lines": ["Kiii!"]},
			1: {"name": "Binek Şahin Kazamaru", "model": "hawk_mount", "h": 4.0, "hp": 380.0, "role": "fighter", "dmg": 22.0, "speed": 22.0, "fly": true, "mount": true,
				"lines": ["Sırtıma atla!", "Rüzgar bizimle."]},
			2: {"name": "Savaş Şahini Tengumaru", "model": "hawk_giant", "h": 9.0, "hp": 1600.0, "role": "giant", "dmg": 60.0, "speed": 28.0, "fly": true, "mount": true,
				"lines": ["Kanatlarımla kasırga kopartırım!", "Tut sıkı!"]},
		}},
	"köpek": {"name": "Ninken Sözleşmesi", "animal": "Ninja Köpekleri", "realm": "", "sage": false, "color": Color(0.55, 0.45, 0.35), "keeper": "konoha",
		"intro": "Burnumuz hiçbir izi kaçırmaz.",
		"tiers": {
			0: {"name": "İz Süren Ninken Hana", "model": "dog_small", "h": 0.5, "hp": 70.0, "role": "tracker", "dmg": 10.0, "speed": 13.0, "lines": ["Kokuyu aldım!", "Hav! Bu taraftan!"]},
			1: {"name": "Ninken Sürüsü", "model": "dog_pack", "h": 0.9, "hp": 120.0, "role": "pack", "dmg": 14.0, "speed": 13.0, "count": 6,
				"lines": ["Hepimiz buradayız!", "Isır ve tut!"]},
			2: {"name": "Çift Başlı Kurt Futago", "model": "wolf_giant", "h": 9.0, "hp": 1800.0, "role": "giant", "dmg": 70.0, "speed": 18.0, "mount": true,
				"lines": ["İki kafa bir karardan iyidir.", "Avı görüyorum."]},
		}},
	"maymun": {"name": "Maymun Sözleşmesi", "animal": "Maymunlar", "realm": "", "sage": false, "color": Color(0.7, 0.5, 0.3), "keeper": "konoha",
		"intro": "Maymun Kral'ın soyu bir silaha dönüşmeyi bilir.",
		"tiers": {
			0: {"name": "Genç Maymun Kibi", "model": "monkey_small", "h": 1.3, "hp": 140.0, "role": "fighter", "dmg": 14.0, "speed": 12.0, "lines": ["Hiii! Dövüşelim!"]},
			1: {"name": "Maymun Kral Kongō", "model": "monkey_king", "h": 2.4, "hp": 600.0, "role": "staff", "dmg": 30.0, "speed": 12.0,
				"lines": ["Elmas asaya dönüşüyorum, sağlam tut!", "Beni boşa sallama evlat."]},
		}},
	"karga": {"name": "Karga Sözleşmesi", "animal": "Kargalar", "realm": "", "sage": false, "color": Color(0.2, 0.2, 0.25), "keeper": "kiri",
		"intro": "Kargalar gölgelerde fısıldar; gözleri yanıltır.",
		"tiers": {
			0: {"name": "Karga Sürüsü", "model": "crow_flock", "h": 0.5, "hp": 60.0, "role": "genjutsu", "dmg": 6.0, "speed": 16.0, "fly": true, "lines": ["Gaak!"]},
		}},
	"semender": {"name": "Semender Sözleşmesi", "animal": "Semenderler", "realm": "", "sage": false, "color": Color(0.35, 0.3, 0.45), "keeper": "kiri",
		"intro": "Zehirli sis, bataklığın efendisinin nefesidir.",
		"tiers": {
			2: {"name": "Zehirli Semender Ibuse", "model": "salamander", "h": 6.0, "len": 26.0, "hp": 2600.0, "role": "giant", "dmg": 60.0, "speed": 9.0, "mount": true,
				"lines": ["Zehirli sisimi koklayan uyur.", "Rüzgarınla sisimi yay!"]},
		}},
	"kaplumbağa": {"name": "Kaplumbağa Sözleşmesi", "animal": "Kaplumbağalar", "realm": "", "sage": false, "color": Color(0.35, 0.55, 0.4), "keeper": "kiri",
		"intro": "Sabırlı kabuk her darbeyi taşır.",
		"tiers": {
			0: {"name": "Ninja Kaplumbağa Kame", "model": "turtle_small", "h": 0.9, "hp": 300.0, "role": "tank", "dmg": 10.0, "speed": 6.0, "lines": ["Kabuğumun arkasına geç!"]},
			2: {"name": "Ada Kaplumbağası Shimagame", "model": "turtle_giant", "h": 12.0, "len": 30.0, "hp": 4000.0, "role": "giant", "dmg": 50.0, "speed": 8.0, "mount": true,
				"lines": ["Sırtımda bir köy taşıyabilirim.", "Sabır, genç ninja."]},
		}},
	"gelincik": {"name": "Orak Gelincik Sözleşmesi", "animal": "Orak Gelincikler", "realm": "", "sage": false, "color": Color(0.85, 0.8, 0.7), "keeper": "suna",
		"intro": "Rüzgar orakla keser.",
		"tiers": {
			1: {"name": "Kamaitachi Üçlüsü", "model": "weasel_trio", "h": 0.8, "hp": 160.0, "role": "wind", "dmg": 24.0, "speed": 16.0, "count": 3,
				"lines": ["Rüzgar orağı!", "Hızlıyız, çok hızlı!"]},
		}},
	"kedi": {"name": "Ninneko Sözleşmesi", "animal": "Ninja Kedileri", "realm": "", "sage": false, "color": Color(0.35, 0.45, 0.8), "keeper": "kumo",
		"intro": "Kediler sadık değildir... ama doğru mamayla belki.",
		"tiers": {
			0: {"name": "Ninneko Tora", "model": "cat_small", "h": 0.6, "hp": 90.0, "role": "fighter", "dmg": 12.0, "speed": 14.0, "lines": ["Miyav! Önce mama."]},
			2: {"name": "İki Kuyruklu Kedi Ruhu Ayakashi", "model": "cat_giant", "h": 9.0, "len": 16.0, "hp": 2000.0, "role": "giant", "dmg": 75.0, "speed": 16.0, "mount": true,
				"lines": ["Mavi alevlerim yakar.", "Sırtıma bin, uçar gibi koşarım."]},
		}},
	"örümcek": {"name": "Örümcek Sözleşmesi", "animal": "Örümcekler", "realm": "", "sage": false, "color": Color(0.3, 0.25, 0.2), "keeper": "iwa",
		"intro": "Ağlarımızdan kaçış yoktur.",
		"tiers": {
			1: {"name": "Dev Örümcek Kumome", "model": "spider", "h": 4.0, "hp": 700.0, "role": "binder", "dmg": 26.0, "speed": 11.0,
				"lines": ["Ağımı örüyorum...", "Takıldın mı sinekçik?"]},
		}},
}


static func p() -> Dictionary:
	return Game.profile


static func signed(id: String) -> bool:
	return p().get("contracts", {}).has(id)


static func active() -> String:
	var a = String(p().get("summon", ""))
	if signed(a):
		return a
	for k in p().get("contracts", {}):
		return k
	return ""


static func mastery(id: String) -> float:
	return float(p().get("contracts", {}).get(id, {}).get("mastery", 0.0))


## Eski kayıtlar: kuchiyose bilip sözleşmesi olmayanlara kurbağa sözleşmesi
static func ensure() -> void:
	var pr = p()
	if pr.is_empty():
		return
	if not pr.has("contracts"):
		pr["contracts"] = {}
		if "kuchiyose" in pr.get("learned", []) or "contract" in pr.get("skills", []):
			pr["contracts"][String(pr.get("summon", "kurbağa"))] = {"mastery": 0.0}
		if "sage" in pr.get("skills", []) and pr["contracts"].has("kurbağa"):
			pr["contracts"]["kurbağa"]["sage"] = true


## Sözleşmeyi kanla imzala
static func sign(id: String) -> void:
	var pr = p()
	ensure()
	if signed(id):
		return
	pr["contracts"][id] = {"mastery": 0.0, "sage": false, "sage_trials": 0}
	pr["summon"] = id
	if not "contract" in pr["skills"]:
		pr["skills"].append("contract")
	for jid in ["kuchiyose", "reverse_summoning_technique"]:
		if Data.jutsu.has(jid) and not jid in pr["learned"]:
			Progress.learn(jid, false)
	if Data.jutsu.has("zofuku_kuchiyose_no_jutsu") and int(pr["level"]) >= 18 and not "zofuku_kuchiyose_no_jutsu" in pr["learned"]:
		Progress.learn("zofuku_kuchiyose_no_jutsu", false)
	Hud.banner("SÖZLEŞME İMZALANDI", "%s — Kuchiyose no Jutsu öğrenildi" % DEFS[id]["name"], DEFS[id]["color"])
	Sfx.play("seal", null, 0.7)
	Game.save_game()


## Mevcut chakra/ustalık/seviyeye göre çağrılabilecek en büyük kademe
static func best_tier(id: String, chakra: float, force_giant := false) -> int:
	var d: Dictionary = DEFS[id]["tiers"]
	var lv = int(p().get("level", 1))
	var m = mastery(id)
	var best = -1
	for t in [0, 1, 2]:
		if not d.has(t):
			continue
		if lv < TIER_LEVEL[t] or m < TIER_MASTERY[t] or chakra < TIER_COST[t]:
			continue
		best = t
	if best < 0:
		for t in [0, 1, 2]:
			if d.has(t):
				return t
	return best


## Kuchiyose: çağırma çemberi + duman, kademe seçimi, NPC çağrıları için de kullanılır
static func summon(c: Node3D, jd: Dictionary) -> void:
	var tree = c.get_tree()
	var id = "kurbağa"
	var tier = 1
	var giant = String(jd.get("id", "")).begins_with("zofuku")
	if c is Player:
		ensure()
		id = active()
		if id == "":
			Hud.msg("Hiçbir hayvanla sözleşmen yok. Gizli bilgelerin yerlerini bul ya da köy sözleşme ustalarına danış.", Color(1, 0.7, 0.5))
			return
		tier = best_tier(id, c.chakra + float(jd.get("cost", 0)), giant)
		if giant and DEFS[id]["tiers"].has(2) and int(p()["level"]) >= TIER_LEVEL[2]:
			tier = 2
		var extra = maxf(0.0, TIER_COST[tier] - float(jd.get("cost", 0)))
		c.chakra = maxf(0.0, c.chakra - extra)
		# aynı sözleşmenin eski çağrısını geri gönder
		for s in tree.get_nodes_in_group("summons"):
			if s.owner_f == c:
				s.dismiss()
	else:
		id = String(c.get_meta("contract", ["kurbağa", "yılan", "köpek"].pick_random()))
		tier = 1 if DEFS[id]["tiers"].has(1) else DEFS[id]["tiers"].keys()[0]
		if c.has_meta("contract_tier") and DEFS[id]["tiers"].has(int(c.get_meta("contract_tier"))):
			tier = int(c.get_meta("contract_tier"))   # boss: dev çağrı
	var sd: Dictionary = DEFS[id]["tiers"][tier]
	var pos: Vector3
	if c is Player:
		pos = Jutsu._aim_ground(c, null, 3.0 + sd["h"] * 0.4, 6.0 + sd["h"] * 0.6)
	else:
		pos = c.global_position + c.face_dir() * (3.0 + sd["h"] * 0.4)
	pos.y = Game.ground_height(pos.x, pos.z)
	# avuç yere çarpar: mühür avucun altından doğar, yazı çizgileri çağrının çıkacağı yere kadar yayılır
	var palm = c.global_position + c.face_dir() * 0.75
	palm.y = Game.ground_height(palm.x, palm.z)
	var col: Color = DEFS[id]["color"]
	_slam(c, palm, col, sd["h"])
	_circle(c, palm, maxf(2.6, palm.distance_to(pos) + maxf(1.2, sd["h"] * 0.45)), col)
	var count = int(sd.get("count", 1))
	var t0 = tree.create_timer(0.35)
	t0.timeout.connect(func():
		if not is_instance_valid(c):
			return
		FX.smoke_puff(pos + Vector3.UP * sd["h"] * 0.5, maxf(1.5, sd["h"] * 0.35), 30 + int(sd["h"] * 3))
		if Game.world:
			Game.world.env.add_shake(clampf(sd["h"] * 0.08, 0.1, 2.0))
		Sfx.play("poof" if sd["h"] < 3.0 else "boom", pos, clampf(1.6 - sd["h"] * 0.04, 0.5, 1.6))
		for i in count:
			var s = Summon.new()
			s.contract = id
			s.tier = tier
			s.def = sd
			s.owner_f = c
			s.team = c.team
			s.scale_m = 1.0 + clampf(mastery(id) / 600.0, 0.0, 0.15)
			tree.current_scene.add_child(s)
			var off = Vector3.ZERO if count == 1 else Vector3(cos(i * TAU / count), 0, sin(i * TAU / count)) * 1.6
			s.global_position = pos + off
			s.facing = c.facing
			if i == 0:
				s.say(sd["lines"].pick_random(), 3.0))


## Avuç yere vurur: çatlak, toz, yerden kalkan halka, hafif sarsıntı (çağrı büyüdükçe güçlenir)
static func _slam(c: Node3D, palm: Vector3, col: Color, h: float) -> void:
	var k = clampf(0.6 + h * 0.08, 0.6, 2.5)
	FX.impact(palm + Vector3.UP * 0.1, col.lightened(0.3), 0.8 * k)
	FX.ring(palm + Vector3.UP * 0.06, Color(0.08, 0.06, 0.05), 3.0 * k, 0.4)
	FX.ring(palm + Vector3.UP * 0.08, col, 1.8 * k, 0.3)
	FX.dust(palm, 0.9 * k)
	VFX.cracks(palm, 1.6 * k, Color(0.1, 0.07, 0.05, 0.9), 2.5)
	Sfx.play("earth", palm, 1.3, 0.6)
	if c == Game.player and Game.world:
		Game.world.env.add_shake(0.25 + h * 0.02)


## Yere yayılan mürekkep çağırma çemberi (avuçtan yayılan çizgiler + yazılar)
static func _circle(c: Node3D, pos: Vector3, r: float, col: Color) -> void:
	var mi = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = Vector2(r * 2.0, r * 2.0)
	q.orientation = PlaneMesh.FACE_Y
	mi.mesh = q
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/summon_circle.gdshader")
	m.set_shader_parameter("col", Color(0.05, 0.04, 0.06))
	m.set_shader_parameter("glow", col)
	m.set_shader_parameter("seed", randf() * 100.0)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	c.get_tree().current_scene.add_child(mi)
	mi.global_position = pos + Vector3.UP * 0.06
	var tw = mi.create_tween()
	tw.tween_method(func(x): m.set_shader_parameter("grow", x), 0.0, 1.0, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_interval(1.6)
	tw.tween_method(func(x): m.set_shader_parameter("fade", x), 0.0, 1.0, 0.8)
	tw.tween_callback(mi.queue_free)


# ------------------------------------------------------------------ ortak jutsular (oyuncu + çağrı)
## Oyuncu bir element jutsusu atınca yakındaki çağrısı ona katılır
static func on_player_cast(pl: Node3D, jid: String) -> void:
	var j: Dictionary = Data.jutsu.get(jid, {})
	var el = String(j.get("element", ""))
	if el == "":
		var els: Array = j.get("elements", [])
		el = String(els[0]) if not els.is_empty() else ""
	if el == "":
		return
	for s in pl.get_tree().get_nodes_in_group("summons"):
		if s.owner_f != pl or s.dead or s.global_position.distance_to(pl.global_position) > 60.0:
			continue
		s.combo(el)


# ------------------------------------------------------------------ gizli yerler: sözleşme + sennin eğitimi
static func realm_interact(it: Dictionary) -> void:
	var id = String(it.get("contract", "kurbağa"))
	var d: Dictionary = DEFS[id]
	var pr = p()
	ensure()
	var opts = []
	if not signed(id):
		opts.append({"label": "Sözleşme parşömenini kanınla imzala", "cb": func():
			if int(pr["level"]) < 6:
				Hud.dialog(d["elder"], "Henüz çok gençsin. Seviye 6 olduğunda gel.", [])
				return
			_blood_sign(id)})
	else:
		var c: Dictionary = pr["contracts"][id]
		if d["sage"] and not c.get("sage", false):
			opts.append({"label": "Sennin eğitimi: doğa enerjisini topla (%d/3 deneme başarılı)" % int(c.get("sage_trials", 0)), "cb": func():
				if int(pr["level"]) < 16:
					Hud.dialog(d["elder"], "Bedenin doğa enerjisini taşıyamaz. Seviye 16 ol, sonra gel.", [])
					return
				if Game.player and Game.player.combat and Game.player.combat.modes:
					Game.player.combat.modes.start_sage_training(id)})
		if c.get("sage", false):
			opts.append({"label": "Sennin sanatlarını öğren", "cb": func(): _teach_sage_arts(id)})
		opts.append({"label": "Aktif sözleşme yap", "cb": func():
			pr["summon"] = id
			Hud.msg("Aktif sözleşme: %s" % d["name"], d["color"])})
	if pr.has("realm_return"):
		opts.append({"label": "Ters çağırma ile geri dön", "cb": func(): return_from_realm()})
	Hud.dialog(d["elder"], d["intro"] if not signed(id) else "Tekrar hoş geldin. Ustalığın: %d" % int(mastery(id)), opts)


static func _blood_sign(id: String) -> void:
	var pl = Game.player
	if pl:
		pl.model.play("interact", 0.1, 1.0, true)
		FX.burst(pl.global_position + Vector3.UP * 1.0 + pl.face_dir() * 0.4, {"amount": 6, "life": 0.5, "add": false, "size": 0.12, "vmin": 0.5, "vmax": 1.5,
			"gravity": Vector3(0, -9, 0), "colors": [Color(0.75, 0.05, 0.05, 1), Color(0.5, 0.0, 0.0, 0)]})
	# köy ustalarının sözleşmelerinde bilge yok ("elder" alanı yalnız dağlı sözleşmelerde): imzada çöküyordu, para gidip sözleşme imzalanmıyordu
	Hud.dialog(String(DEFS[id].get("elder", "Sözleşme Ustası")), "Başparmağını ısır, adını kanınla yaz... Artık bizdensin.", [])
	Contracts.sign(id)   # (çıplak "sign(id)" Godot'nun matematik fonksiyonuna gidiyordu: hiçbir sözleşme imzalanmıyordu)


## Köy sözleşme ustaları: dağsız sözleşmeler (şahin, ninken, maymun, karga, semender, kaplumbağa, gelincik, kedi, örümcek)
static func keeper_interact(it: Dictionary) -> void:
	var vid = String(it.get("village", "konoha"))
	var pr = p()
	ensure()
	var opts = []
	for id in DEFS:
		var d: Dictionary = DEFS[id]
		if d["realm"] != "" or d.get("keeper", "") != vid:
			continue
		if signed(id):
			opts.append({"label": "%s (imzalı) — aktif yap" % d["name"], "cb": func():
				pr["summon"] = id
				Hud.msg("Aktif sözleşme: %s" % d["name"], d["color"])})
		else:
			var price = 800 + 400 * DEFS[id]["tiers"].size()
			opts.append({"label": "%s — %d Ryō, Chunin" % [d["name"], price], "tip": d["intro"], "cb": func():
				if int(pr["rank"]) < 2:
					Hud.msg("Bu sözleşme için Chunin olmalısın.", Color(1, 0.6, 0.4))
				elif int(pr["ryo"]) < price:
					Hud.msg("Yeterli Ryō yok.", Color(1, 0.5, 0.4))
				else:
					Progress.add_ryo(-price)
					_blood_sign(id)})
	if opts.is_empty():
		opts.append({"label": "Burada sözleşme yok", "cb": func(): pass})
	Hud.dialog("Sözleşme Ustası", "Hayvanlarla kan bağı kurmak isteyen ninja... Hangi sözleşmeyi istersin?", opts)


static func _teach_sage_arts(id: String) -> void:
	var pr = p()
	var n = 0
	for jid in Data.jutsu:
		var j: Dictionary = Data.jutsu[jid]
		if String(j.get("learn", "")) == "sage:any" and not jid in pr["learned"] and int(pr["level"]) >= int(j.get("level", 1)):
			if _sage_art_for(jid) in ["", id]:
				Progress.learn(jid, false)
				n += 1
	Hud.dialog(DEFS[id]["elder"], ("%d sennin sanatı öğrendin." % n) if n > 0 else "Şimdilik sana öğretebileceğim yeni bir şey yok. Güçlendikçe gel.", [])


## Sennin sanatlarının hangi sözleşmeye ait olduğu (boş = hepsi)
static func _sage_art_for(jid: String) -> String:
	if jid in ["kawazu_kumite", "kawazu_tataki", "zessenbaku", "zessenzan", "mizuame_teppo", "katon_dai_endan", "senpo_ryosei_no_jutsu", "senpo_gokashin_ensen", "sennin_modo"]:
		return "kurbağa"
	if jid in ["daijatsuki", "senpo_muki_tensei", "senpo_hakugeki_no_jutsu"]:
		return "yılan"
	if jid in ["rikudo_sennin_modo", "rikudo_senjutsu", "gudodama", "gudokasa", "senpo_myojinmon"]:
		return "_rikudo"
	return ""


# ------------------------------------------------------------------ ters çağırma
static func reverse_summon(c: Node3D) -> void:
	if not c is Player:
		return
	var id = active()
	if id == "" or DEFS[id]["realm"] == "":
		Hud.msg("Ters çağırma için gizli diyarı olan bir sözleşme gerekli (kurbağa, yılan, sümüklüböcek).", Color(1, 0.7, 0.5))
		return
	var rp = ContractRealms.realm_pos(id)
	if rp == Vector3.ZERO:
		return
	var pr = p()
	pr["realm_return"] = [c.global_position.x, c.global_position.y, c.global_position.z]
	FX.smoke_puff(c.global_position + Vector3.UP, 1.4, 24)
	Sfx.play("poof", c.global_position)
	c.respawn(rp + Vector3(0, 0.5, 0))
	Hud.banner(DEFS[id]["realm"], "Ters çağırma", DEFS[id]["color"])


static func return_from_realm() -> void:
	var pr = p()
	if not pr.has("realm_return") or Game.player == null:
		return
	var a: Array = pr["realm_return"]
	pr.erase("realm_return")
	FX.smoke_puff(Game.player.global_position + Vector3.UP, 1.4, 24)
	Game.player.respawn(Vector3(a[0], a[1], a[2]))
	Sfx.play("poof", Game.player.global_position)
