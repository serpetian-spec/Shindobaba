class_name BuildSites
extends RefCounted
## Konoha dışındaki köyler ve önemli yerler. Her biri kendi mimari tarzıyla.


static func build_all(parent: Node3D) -> void:
	for v in Game.world_info["villages"]:
		match v["id"]:
			"konoha": BuildKonoha.build(parent, v)
			"suna": suna(parent, v)
			"kiri": kiri(parent, v)
			"kumo": kumo(parent, v)
			"iwa": iwa(parent, v)
			"ame": ame(parent, v)
			"oto": oto(parent, v)
			"kusa": kusa(parent, v)
			"taki": taki(parent, v)
			"yu": yu(parent, v)
			"shimo": small_town(parent, v, "snow")
			"tani": tani(parent, v)
			"nami": nami(parent, v)
			"uzushio": uzushio(parent, v)
			"tetsu": tetsu(parent, v)
	for l in Game.world_info["landmarks"]:
		match l["id"]:
			"valley_end": valley_end(parent, l)
			"forest_death": forest_death(parent, l)
			"sage_falls": sage_falls(parent, l)
			"naruto_bridge": naruto_bridge(parent, l)
			"hideout": hideout(parent, l)
			"bandit_camp": camp(parent, l, "bandit")
			"border_post": outpost(parent, l)
			"storm_canyon": storm_canyon(parent, l)


static func _rng(s: int) -> RandomNumberGenerator:
	var r = RandomNumberGenerator.new()
	r.seed = s
	return r


static func _fill(b: Builder, r: float, inner: float, spacing: float, style: String, rng: RandomNumberGenerator, keep_clear: Array = []) -> void:
	var x = -r
	while x <= r:
		var n = -r
		while n <= r:
			var px = x + rng.randf_range(-3, 3); var pn = n + rng.randf_range(-3, 3)
			n += spacing
			var d = Vector2(px, pn).length()
			if d > r or d < inner or rng.randf() < 0.18:
				continue
			var ok = true
			for k in keep_clear:
				if Vector2(px - k[0], pn - k[1]).length() < k[2]:
					ok = false
			if absf(px) < 8 or absf(pn) < 8:
				ok = false
			if not ok:
				continue
			var yaw = rad_to_deg(atan2(px, pn)) + 180.0
			b.house(px, pn, rng.randf_range(8, 13), rng.randf_range(7, 11), [1, 1, 2, 2, 3].pick_random(), yaw, style, rng)
		x += spacing


# ------------------------------------------------------------------ Sunagakure: kraterde kubbe şehir
static func suna(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Suna")
	var rng = _rng(2)
	var sand = Color(0.84, 0.7, 0.5)
	# krater duvarları (doğuda kanyon girişi)
	var a = 0.0
	while a < 360.0:
		if absf(fmod(a - 90.0 + 540.0, 360.0) - 180.0) > 7.0:
			var rad = deg_to_rad(a)
			var hh = rng.randf_range(55, 75)
			b.box(Vector3(285 * sin(rad), hh * 0.5 - 2, 285 * cos(rad)), Vector3(32, hh, 36), sand.darkened(rng.randf_range(0.05, 0.18)), a)
		a += 5.0
	# Kazekage kulesi (büyük kubbe) + "風"
	b.cyl(Vector3(0, 14, 0), 60, 28, sand.lightened(0.05), true, 32)
	b.dome(Vector3(0, 28, 0), 60, 22, sand.lightened(0.1), 32)
	b.cyl(Vector3(0, 30, -29.5), 10, 10, Color(0.35, 0.55, 0.35), false, 16)
	b.interact(Vector3(0, 0, -34), 7, "mission_board", "[F] Kazekage Ofisi (görevler)")
	_fill(b, 240, 50, 22, "suna", rng)
	b.interact(Vector3(60, 0, 20), 5, "shop_items", "[F] Suna Pazarı")
	b.finish()


# ------------------------------------------------------------------ Kirigakure: sisli, kubbeli kuleler
static func kiri(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Kiri")
	var rng = _rng(3)
	b.cyl(Vector3(0, 20, 0), 36, 40, Color(0.58, 0.66, 0.7), true, 24)
	b.dome(Vector3(0, 40, 0), 38, 14, Color(0.3, 0.42, 0.55), 24)
	b.cyl(Vector3(0, 30, -17.8), 8, 8, Color(0.25, 0.45, 0.65), false, 16)  # "水"
	b.interact(Vector3(0, 0, -21), 6, "mission_board", "[F] Mizukage Ofisi (görevler)")
	_fill(b, 230, 35, 20, "kiri", rng)
	# kanallar ve köprüler
	for k in 4:
		var a = k * 90.0 + 45.0
		var o = Builder.rot(0, 120, a)
		b.box(Vector3(o.x, 0.4, o.y), Vector3(6, 0.8, 30), Color(0.4, 0.33, 0.25), a)
	b.finish()


# ------------------------------------------------------------------ Kumogakure: kaya sütunları üstünde şehir (duvar koşusu cenneti)
static func kumo(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Kumo")
	var rng = _rng(4)
	var rock = Color(0.55, 0.57, 0.55)
	var pillars = []
	for k in 18:
		var a = rng.randf() * TAU; var r = rng.randf_range(30, 240)
		var px = r * sin(a); var pn = r * cos(a)
		var d = rng.randf_range(18, 34); var h = rng.randf_range(40, 120)
		b.cyl(Vector3(px, h * 0.5 - 2, pn), d, h, rock.darkened(rng.randf_range(0, 0.15)), true, 14)
		pillars.append([px, pn, d, h])
		# tepede bina
		b.cyl(Vector3(px, h + 4, pn), d * 0.6, 8, Color(0.85, 0.85, 0.82), true, 14)
		b.dome(Vector3(px, h + 8, pn), d * 0.62, 4, Color(0.3, 0.5, 0.7), 14)
	# sütunlar arası köprüler
	for i in pillars.size() - 1:
		var p0: Array = pillars[i]; var p1: Array = pillars[i + 1]
		var mid = Vector3((p0[0] + p1[0]) * 0.5, minf(p0[3], p1[3]) - 4, (p0[1] + p1[1]) * 0.5)
		var L = Vector2(p1[0] - p0[0], p1[1] - p0[1]).length()
		if L < 140:
			b.box(mid, Vector3(3, 0.6, L), Color(0.45, 0.35, 0.25), rad_to_deg(atan2(p1[0] - p0[0], p1[1] - p0[1])))
	# Raikage kulesi
	b.cyl(Vector3(0, 70, 0), 40, 140, rock, true, 20)
	b.cyl(Vector3(0, 146, 0), 30, 12, Color(0.9, 0.9, 0.88), true, 20)
	b.dome(Vector3(0, 152, 0), 32, 12, Color(0.25, 0.45, 0.7), 20)
	b.interact(Vector3(0, 0, -22), 6, "mission_board", "[F] Raikage Ofisi (görevler) — tepeye duvardan koş!")
	_fill(b, 200, 40, 26, "rock", rng)
	b.finish()


# ------------------------------------------------------------------ Iwagakure: kaya kuleler ve taş köprüler
static func iwa(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Iwa")
	var rng = _rng(5)
	for k in 14:
		var a = rng.randf() * TAU; var r = rng.randf_range(40, 230)
		var px = r * sin(a); var pn = r * cos(a)
		var h = rng.randf_range(30, 70)
		b.box(Vector3(px, h * 0.5, pn), Vector3(rng.randf_range(14, 24), h, rng.randf_range(14, 24)), Color(0.52, 0.42, 0.32), rng.randf() * 90)
		for f in int(h / 10):
			b.box(Vector3(px, f * 10 + 5, pn - 9), Vector3(3, 2, 0.4), Color(0.25, 0.2, 0.15), 0, false)
	b.cone(Vector3(0, 0, 0), 60, 90, Color(0.5, 0.4, 0.3), 12, true)
	b.box(Vector3(0, 30, -18), Vector3(8, 8, 1), Color(0.35, 0.28, 0.2), 0, false)  # "土"
	b.interact(Vector3(0, 0, -26), 6, "mission_board", "[F] Tsuchikage Ofisi (görevler)")
	_fill(b, 220, 45, 24, "iwa", rng)
	b.finish()


# ------------------------------------------------------------------ Amegakure: sanayi kuleleri, boru hatları, sürekli yağmur
static func ame(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Ame")
	var rng = _rng(6)
	var metal = Color(0.38, 0.4, 0.43)
	b.box(Vector3(0, 60, 0), Vector3(22, 120, 22), metal.darkened(0.1))
	b.cyl(Vector3(0, 125, 0), 16, 10, metal, true, 12)
	for k in 6:
		b.cyl(Vector3(0, 100 - k * 15, 12), 2.5, 2.5, metal.lightened(0.1), false, 8)
	b.interact(Vector3(0, 0, -14), 6, "mission_board", "[F] Ame Kulesi (görevler)")
	for k in 20:
		var a = rng.randf() * TAU; var r = rng.randf_range(35, 220)
		var h = rng.randf_range(25, 70)
		var px = r * sin(a); var pn = r * cos(a)
		b.box(Vector3(px, h * 0.5, pn), Vector3(rng.randf_range(10, 16), h, rng.randf_range(10, 16)), metal.darkened(rng.randf_range(0, 0.15)))
		b.cyl(Vector3(px + 7, h * 0.4, pn), 1.8, h * 0.8, metal.lightened(0.05), false, 8)
	_fill(b, 220, 40, 22, "ame", rng)
	b.finish()


# ------------------------------------------------------------------ Otogakure: gizli sığınaklar
static func oto(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Oto")
	var rng = _rng(7)
	for k in 6:
		var a = k * 60.0
		var o = Builder.rot(0, 60, a)
		b.dome(Vector3(o.x, 0, o.y), 20, 8, Color(0.42, 0.4, 0.36), 12)
		b.box(Vector3(o.x, 2, o.y - 9), Vector3(4, 4, 2), Color(0.15, 0.13, 0.12), a, false)
	b.box(Vector3(0, 6, 0), Vector3(26, 12, 26), Color(0.32, 0.3, 0.33))
	b.box(Vector3(0, 9, -13.2), Vector3(4, 4, 0.4), Color(0.5, 0.35, 0.6), 0, false)
	b.interact(Vector3(0, 0, -16), 6, "oto_lair", "[F] Ses Sığınağı")
	_fill(b, 140, 70, 24, "rock", rng)
	b.finish()


# ------------------------------------------------------------------ Kusagakure: dev mantar ormanı + çimen köyü
static func kusa(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Kusa")
	var rng = _rng(8)
	for k in 30:
		var a = rng.randf() * TAU; var r = rng.randf_range(20, 180)
		var px = r * sin(a); var pn = r * cos(a)
		var h = rng.randf_range(8, 22)
		b.cyl(Vector3(px, h * 0.5, pn), h * 0.12, h, Color(0.9, 0.88, 0.8), true, 10)
		var cap = [Color(0.75, 0.3, 0.25), Color(0.85, 0.6, 0.3), Color(0.55, 0.4, 0.6)][k % 3]
		b.dome(Vector3(px, h - 1, pn), h * 0.9, h * 0.25, cap, 14)
		b.box(Vector3(px, h - 0.6, pn), Vector3(h * 0.8, 0.5, h * 0.8), cap.darkened(0.2))  # üstünde durulabilir
	b.box(Vector3(0, 5, 0), Vector3(24, 10, 18), Color(0.6, 0.5, 0.32))
	b.roof(Vector3(0, 10, 0), Vector3(27, 5, 21), Color(0.35, 0.5, 0.28))
	b.interact(Vector3(0, 0, -11), 6, "mission_board", "[F] Kusa Köy Meclisi (görevler)")
	_fill(b, 160, 30, 20, "wood", rng)
	b.finish()


# ------------------------------------------------------------------ Takigakure: göl ortasında dev ağaç + şelaleler
static func taki(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Taki")
	var rng = _rng(9)
	b.box(Vector3(0, -1.5, 0), Vector3(150, 0.2, 150), Color(0.25, 0.5, 0.6), 0, false)
	b.cyl(Vector3(0, 45, 0), 26, 90, Color(0.4, 0.28, 0.18), true, 16)
	for k in 6:
		b.cyl(Vector3(0, 6, 0), 8, 18, Color(0.4, 0.28, 0.18), false, 8)
	b.sphere(Vector3(0, 98, 0), Vector3(110, 40, 110), Color(0.22, 0.48, 0.24), 14)
	b.sphere(Vector3(30, 88, 20), Vector3(60, 25, 60), Color(0.26, 0.52, 0.26), 12)
	for k in 6:  # ağaç gövdesine sarılı platformlar
		var a = k * 60.0
		var o = Builder.rot(0, 18, a)
		b.box(Vector3(o.x, 15 + k * 10, o.y), Vector3(12, 1, 10), Color(0.55, 0.4, 0.25), a)
	# şelale duvarları
	for k in 3:
		var a = k * 120.0 + 30.0
		var o = Builder.rot(0, 200, a)
		b.box(Vector3(o.x, 30, o.y), Vector3(80, 60, 30), Color(0.5, 0.48, 0.44), a)
		Waterfalls.add(b.w(Vector3(o.x, 0, o.y)) + Vector3(0, 0, 0), 60.0, 20.0, a)
	b.interact(Vector3(0, 0, -16), 6, "mission_board", "[F] Taki Liderleri (görevler)")
	_fill(b, 200, 90, 24, "wood", rng)
	b.finish()


# ------------------------------------------------------------------ Yugakure: kaplıcalar
static func yu(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Yu")
	var rng = _rng(10)
	for k in 8:
		var a = k * 45.0
		var o = Builder.rot(0, 55, a)
		b.cyl(Vector3(o.x, -0.6, o.y), 18, 1.2, Color(0.55, 0.52, 0.48), false, 16)
		b.cyl(Vector3(o.x, 0.05, o.y), 16, 0.1, Color(0.55, 0.78, 0.82), false, 16)
		Steam.add(b.w(Vector3(o.x, 0.3, o.y)))
	b.box(Vector3(0, 6, 0), Vector3(30, 12, 20), Color(0.58, 0.4, 0.26))
	b.roof(Vector3(0, 12, 0), Vector3(34, 6, 24), Color(0.25, 0.25, 0.3))
	b.interact(Vector3(0, 0, -12), 6, "onsen", "[F] Kaplıcaya gir (tam iyileşme)")
	_fill(b, 160, 75, 20, "wood", rng)
	b.finish()


static func small_town(parent: Node3D, v: Dictionary, style: String) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], v["id"])
	var rng = _rng(hash(v["id"]))
	b.box(Vector3(0, 5, 0), Vector3(22, 10, 16), Color(0.6, 0.5, 0.4))
	b.roof(Vector3(0, 10, 0), Vector3(25, 5, 19), Color(0.9, 0.92, 0.95) if style == "snow" else Color(0.3, 0.3, 0.35))
	b.interact(Vector3(0, 0, -10), 6, "mission_board", "[F] Köy Meclisi (görevler)")
	_fill(b, float(v["r"]) - 20, 25, 20, style, rng)
	b.finish()


# ------------------------------------------------------------------ Tanigakure: kanyon duvarlarına oyulmuş
static func tani(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Tani")
	var rng = _rng(11)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(60 * sx, 30, 0), Vector3(40, 60, 300), Color(0.55, 0.45, 0.35))
		for k in 10:
			var n = -120.0 + k * 26.0
			b.box(Vector3(39 * sx, 8 + (k % 3) * 12, n), Vector3(3, 6, 8), Color(0.62, 0.5, 0.36))
			b.box(Vector3(37 * sx, 5 + (k % 3) * 12, n), Vector3(5, 0.5, 9), Color(0.45, 0.33, 0.22))
	b.interact(Vector3(0, 0, -20), 6, "mission_board", "[F] Tani Muhtarı (görevler)")
	_fill(b, 30, 0, 18, "wood", rng)
	b.finish()


# ------------------------------------------------------------------ Dalga Kasabası: iskeleler
static func nami(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Nami")
	var rng = _rng(12)
	_fill(b, 150, 10, 18, "wood", rng)
	for k in 6:
		var a = k * 25.0 + 120.0
		var o = Builder.rot(0, 175, a)
		b.box(Vector3(o.x, -3.5, o.y), Vector3(4, 0.4, 40), Color(0.5, 0.38, 0.25), a)
	b.interact(Vector3(0, 0, 0), 6, "mission_board", "[F] Kasaba Halkı (görevler)")
	b.finish()


static func uzushio(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Uzushio")
	var rng = _rng(13)
	for k in 30:
		var a = rng.randf() * TAU; var r = rng.randf_range(10, 130)
		var h = rng.randf_range(1, 9)
		b.box(Vector3(r * sin(a), h * 0.5, r * cos(a)), Vector3(rng.randf_range(4, 12), h, rng.randf_range(1, 3)), Color(0.55, 0.5, 0.45), rng.randf() * 180)
	b.cyl(Vector3(0, 1, 0), 14, 2, Color(0.6, 0.25, 0.22), false, 20)  # girdap arması zemini
	b.interact(Vector3(0, 0, 0), 8, "ruins", "[F] Harabeleri incele")
	b.finish()


# ------------------------------------------------------------------ Demir Kalesi: samuray şatosu
static func tetsu(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Tetsu")
	var rng = _rng(14)
	b.box(Vector3(0, 6, 0), Vector3(70, 12, 70), Color(0.5, 0.5, 0.52))
	for t in 4:
		var s = 50.0 - t * 10.0
		b.box(Vector3(0, 14 + t * 8, 0), Vector3(s, 8, s), Color(0.95, 0.95, 0.95))
		b.roof(Vector3(0, 18 + t * 8, 0), Vector3(s + 8, 4, s + 8), Color(0.25, 0.3, 0.35))
	b.interact(Vector3(0, 0, -38), 6, "mission_board", "[F] Samuray Generali (görevler)")
	_fill(b, 200, 60, 24, "snow", rng)
	b.finish()


# ------------------------------------------------------------------ Sonun Vadisi
static func valley_end(parent: Node3D, l: Dictionary) -> void:
	var b = Builder.new(parent, l["x"], l["y"], 0.0, "SonunVadisi")
	var rock = Color(0.58, 0.55, 0.5)
	# iki dev heykel (yüzsüz, el mühürlü genel shinobi heykelleri) nehrin iki yakasında
	for sx in [-1.0, 1.0]:
		var x = 75.0 * sx
		b.box(Vector3(x, 30, 40), Vector3(30, 60, 30), rock.darkened(0.1))
		b.box(Vector3(x, 80, 40), Vector3(20, 40, 14), rock)           # gövde
		b.box(Vector3(x, 108, 40), Vector3(11, 14, 11), rock.lightened(0.05))  # kafa
		b.box(Vector3(x - 7 * sx, 86, 33), Vector3(5, 18, 5), rock, 0, true, Vector3(0, 0, 25 * sx))
		b.box(Vector3(x - 2 * sx, 92, 28), Vector3(4, 6, 6), rock.lightened(0.05))  # el mühürü
		b.box(Vector3(x, 64, 40), Vector3(10, 10, 12), rock)
	Waterfalls.add(b.w(Vector3(0, 0, 60)), 34.0, 60.0, 0.0)
	b.interact(Vector3(0, 0.5, 10), 10, "valley", "[F] Sonun Vadisi'nde meditasyon yap")
	b.finish()


# ------------------------------------------------------------------ Ölüm Ormanı: çit + merkez kule
static func forest_death(parent: Node3D, l: Dictionary) -> void:
	var b = Builder.new(parent, l["x"], l["y"], l["base"], "OlumOrmani")
	b.wall_ring_at(0, 0, float(l["r"]), 6.0, Color(0.35, 0.3, 0.25), [[270.0, 8.0]], 4.0)
	b.box(Vector3(-float(l["r"]), 7, 0), Vector3(2, 2, 10), Color(0.6, 0.15, 0.12), 0, false)
	b.cyl(Vector3(0, 20, 0), 40, 40, Color(0.75, 0.7, 0.62), true, 16)
	b.cone(Vector3(0, 40, 0), 46, 14, Color(0.4, 0.4, 0.45), 16, true)
	b.interact(Vector3(0, 0, -22), 6, "fod_tower", "[F] Merkez Kule")
	b.interact(Vector3(-float(l["r"]) + 4, 0, 0), 6, "fod_gate", "[F] 44. Alan Kapısı")
	b.finish()


static func sage_falls(parent: Node3D, l: Dictionary) -> void:
	var b = Builder.new(parent, l["x"], l["y"], 0.0, "GizliSelale")
	Waterfalls.add(b.w(Vector3(0, -2, 60)), 55.0, 26.0, 0.0)
	for k in 7:
		b.box(Vector3(-30 + k * 10, 0.5, 0 + (k % 2) * 6), Vector3(5, 1.5 + (k % 3), 5), Color(0.5, 0.5, 0.48))
	b.interact(Vector3(0, 0.5, 20), 10, "sage", "[F] Doğa enerjisini hisset (Sennin eğitimi)")
	b.finish()


static func naruto_bridge(parent: Node3D, l: Dictionary) -> void:
	# Ateş kıyısından Dalga adasına uzun köprü (kuzey-güney)
	var b = Builder.new(parent, l["x"], l["y"], 0.0, "NarutoKoprusu")
	var L = 520.0
	b.box(Vector3(0, 6, 0), Vector3(14, 1.2, L), Color(0.72, 0.68, 0.6))
	for sx in [-1.0, 1.0]:
		b.box(Vector3(6.8 * sx, 7.2, 0), Vector3(0.4, 1.4, L), Color(0.6, 0.55, 0.48))
	var k = -L * 0.5
	while k <= L * 0.5:
		b.box(Vector3(0, -10, k), Vector3(4, 32, 4), Color(0.6, 0.57, 0.5))
		k += 40.0
	b.interact(Vector3(0, 6.6, -L * 0.5 + 10), 8, "bridge", "[F] Büyük Naruto Köprüsü")
	b.finish()


static func hideout(parent: Node3D, l: Dictionary) -> void:
	var b = Builder.new(parent, l["x"], l["y"], l["base"], "Siginak")
	b.box(Vector3(0, 25, 20), Vector3(70, 50, 40), Color(0.42, 0.4, 0.38))
	b.box(Vector3(0, 7, -0.5), Vector3(14, 14, 1.5), Color(0.3, 0.29, 0.28))  # taş kapı
	b.box(Vector3(0, 12, -1.4), Vector3(4, 1, 0.2), Color(0.7, 0.1, 0.12), 0, false)
	b.interact(Vector3(0, 0, -5), 7, "hideout", "[F] Mühürlü taş kapı")
	b.finish()


static func camp(parent: Node3D, l: Dictionary, kind: String) -> void:
	var b = Builder.new(parent, l["x"], l["y"], l["base"], "Kamp")
	var rng = _rng(21)
	for k in 7:
		var a = k * 51.0
		var o = Builder.rot(0, 22, a)
		b.roof(Vector3(o.x, 0, o.y), Vector3(6, 3.5, 7), Color(0.55, 0.45, 0.32).darkened(rng.randf() * 0.2), a)
	b.cyl(Vector3(0, 0.3, 0), 3, 0.6, Color(0.3, 0.25, 0.2), false, 8)
	Spawner.camp(b.w(Vector3.ZERO), kind, 6)
	b.finish()


static func outpost(parent: Node3D, l: Dictionary) -> void:
	var b = Builder.new(parent, l["x"], l["y"], l["base"], "Karakol")
	b.wall_rect(0, 0, 50, 50, 5.0, Color(0.55, 0.45, 0.32))
	for sx in [-1.0, 1.0]:
		for sn in [-1.0, 1.0]:
			b.box(Vector3(25 * sx, 7, 25 * sn), Vector3(5, 14, 5), Color(0.5, 0.4, 0.28))
	b.interact(Vector3(0, 0, -20), 6, "mission_board", "[F] Sınır Komutanı (görevler)")
	b.finish()


static func storm_canyon(parent: Node3D, l: Dictionary) -> void:
	var b = Builder.new(parent, l["x"], l["y"], l["base"], "FirtinaKanyonu")
	var rng = _rng(31)
	for k in 16:
		var a = k * 22.5
		var o = Builder.rot(0, 150, a)
		var h = rng.randf_range(50, 90)
		b.box(Vector3(o.x, h * 0.5, o.y), Vector3(40, h, 30), Color(0.4, 0.42, 0.45), a)
	b.interact(Vector3(0, 0, 0), 12, "raiju", "[F] Fırtınanın kalbi... (S-rank)")
	b.finish()
