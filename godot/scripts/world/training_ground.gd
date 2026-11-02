extends RefCounted
## Konoha 3. Antrenman Alanı (yeniden): kanondaki üç çan-testi kütüğü ve Anıt Taşı korunur; çevresine şelaleli gölet, dere +
## kırmızı kemerli köprü, kunai'li hedef tahtaları, sütun atlama parkuru, tırmanma ağaçları (kunai izli), silah rafı, tabela,
## sakura halkası (dökülen pembe yapraklar), taş fenerler, banklar, çiçekler, ipli çit ve küçük torii giriş.
## Zemin örtüsü YOK (eskiden araziden 9 cm yüksek çarpışmasız yeşil kutu vardı: ayaklar içine giriyor, kan altında kalıyordu).

const WOOD := Color(0.48, 0.34, 0.2)
const WOOD_D := Color(0.34, 0.23, 0.13)
const STONE := Color(0.56, 0.55, 0.52)
const RED := Color(0.78, 0.18, 0.14)
static var road_check: Callable   # yolun üstüne ağaç dikilmesin


static func build(b: Builder, decor: Node3D, cx: float, cn: float, rng: RandomNumberGenerator, gy: Callable, act: Callable, site: Callable) -> void:
	var G = func(x: float, n: float) -> float: return float(gy.call(x, n))
	_bell_posts(b, cx, cn + 18.0, G)
	_memorial(b, cx - 35.0, cn + 30.0, G)
	_pond_falls(b, decor, cx + 42.0, cn + 28.0, G, rng)
	_stream(b, decor, cx, cn, G, rng)
	_targets(b, cx + 8.0, cn - 44.0, G)
	_pillars(b, cx - 30.0, cn - 34.0, G, rng)
	_climb_trees(b, cx, cn, G, rng)
	_entrance(b, cx - 70.0, cn, G)
	_fence(b, cx, cn, 70.0, 55.0, G)
	_garden(b, cx, cn, G, rng)
	# eylemler / NPC yerleri (eskisi gibi)
	act.call(b, cx - 35.0, cn + 27.0, 4.0, "memorial", "[F] Anıt Taşı")
	act.call(b, cx, cn + 12.0, 6.0, "training", "[F] Antrenman yap (chakra kontrolü)")
	act.call(b, cx + 14.0, cn + 12.0, 3.5, "trainer", "[F] Jonin eğitmen: jutsu öğren", {"village": "konoha"})
	site.call(b, "trainer", cx + 14.0, cn + 14.0, {"face": PI})
	site.call(b, "spar", cx - 12.0, cn - 2.0)
	site.call(b, "spar", cx + 22.0, cn - 4.0)
	for i in 4:
		var p = Vector3(cx - 20.0 + i * 13.0, 0, cn - 15.0)
		p.y = G.call(p.x, p.z)
		Spawner.dummy(b.w(p))


# ------------------------------------------------------------------ çan testi kütükleri (kanon: üç kalın kütük, ipli)
static func _bell_posts(b: Builder, x0: float, n0: float, G: Callable) -> void:
	for i in 3:
		var x = x0 - 6.0 + i * 6.0
		var g = G.call(x, n0)
		b.cyl(Vector3(x, g + 1.15, n0), 0.95, 2.3, WOOD, true, 12)
		b.cyl(Vector3(x, g + 2.32, n0), 0.9, 0.06, Color(0.72, 0.58, 0.4), false, 12)   # kesik tepe (açık yıllık halkalar)
		for h in [0.55, 1.45]:   # aşınmış ip bantları
			b.cyl(Vector3(x, g + h, n0), 1.0, 0.12, Color(0.85, 0.8, 0.62), false, 12)
		for k in 4:   # tekme/yumruk izleri
			var a = TAU * k / 4.0 + i
			b.box(Vector3(x + cos(a) * 0.47, g + 0.9 + k * 0.18, n0 + sin(a) * 0.47), Vector3(0.05, 0.22, 0.14), WOOD_D, rad_to_deg(-a), false)
		_kunai(b, Vector3(x + 0.46, g + 1.7, n0), 90.0)
	# kütüklerin önünde çiğnenmiş toprak (zemine yapışık ince disk değil: düz kutu çok ince, kan/ayak sorunu olmaz)
	b.box(Vector3(x0, G.call(x0, n0 - 5.0) + 0.012, n0 - 5.0), Vector3(17.0, 0.02, 9.0), Color(0.52, 0.42, 0.3), 0, false)


# ------------------------------------------------------------------ Anıt Taşı (kanon: koyu, cilalı, eğik tepeli dikili taş, isimler)
static func _memorial(b: Builder, x: float, n: float, G: Callable) -> void:
	var g = G.call(x, n)
	b.box(Vector3(x, g + 0.2, n), Vector3(5.2, 0.4, 3.4), STONE.darkened(0.1))          # alt basamak
	b.box(Vector3(x, g + 0.55, n), Vector3(3.8, 0.35, 2.4), STONE)                     # üst basamak
	var dark = Color(0.18, 0.2, 0.24)
	b.box(Vector3(x, g + 2.55, n), Vector3(2.1, 3.7, 0.75), dark)                      # dikili taş
	b.box(Vector3(x, g + 4.55, n), Vector3(2.1, 0.5, 0.75), dark, 0, false, Vector3(0, 0, 14))   # eğik tepe
	b.box(Vector3(x, g + 2.6, n - 0.38), Vector3(1.7, 3.2, 0.02), Color(0.26, 0.29, 0.34), 0, false)   # cilalı yüz
	b.kanji(Vector3(x, g + 3.9, n - 0.41), "慰霊碑", 0.38, Color(0.75, 0.78, 0.82), 0.0)
	var names = ["木ノ葉", "英雄", "忍", "火影", "仲間", "勇者", "志"]
	for c in 3:
		for r in 2:
			b.kanji(Vector3(x - 0.55 + c * 0.55, g + 2.9 - r * 0.9, n - 0.41), names[(c * 2 + r) % names.size()], 0.17, Color(0.62, 0.65, 0.7), 0.0)
	# adaklar: çiçek demetleri, tütsü, kunai (yas tutanların bıraktığı)
	for sx in [-1.0, 1.0]:
		b.cyl(Vector3(x + sx * 1.3, g + 0.95, n - 0.9), 0.32, 0.45, STONE.darkened(0.25), false, 10)   # vazo
		for k in 5:
			var a = TAU * k / 5.0
			b.sphere(Vector3(x + sx * 1.3 + cos(a) * 0.12, g + 1.3, n - 0.9 + sin(a) * 0.12), Vector3(0.18, 0.16, 0.18), [Color(0.95, 0.95, 0.9), Color(0.98, 0.85, 0.3), Color(0.9, 0.4, 0.5)][k % 3], 6)
	b.cyl(Vector3(x, g + 0.85, n - 1.0), 0.4, 0.25, Color(0.4, 0.3, 0.18), false, 10)   # tütsü kabı
	for k in 3:
		b.box(Vector3(x - 0.1 + k * 0.1, g + 1.1, n - 1.0), Vector3(0.015, 0.4, 0.015), Color(0.5, 0.15, 0.12), 0, false)
	# kutsal ip (shimenawa) direkleri
	for sx in [-1.0, 1.0]:
		b.cyl(Vector3(x + sx * 2.9, g + 0.7, n - 1.8), 0.22, 1.4, STONE, true, 8)
	b.box(Vector3(x, g + 1.25, n - 1.8), Vector3(5.8, 0.09, 0.09), Color(0.88, 0.82, 0.62), 0, false)
	for k in 4:
		b.box(Vector3(x - 1.8 + k * 1.2, g + 1.05, n - 1.8), Vector3(0.16, 0.34, 0.02), Color(0.97, 0.97, 0.95), 0, false)   # shide kâğıtları


# ------------------------------------------------------------------ şelaleli gölet
static func _pond_falls(b: Builder, decor: Node3D, x: float, n: float, G: Callable, rng: RandomNumberGenerator) -> void:
	var g = G.call(x, n)
	var r = 9.0
	# gölet: koyu taban + su yüzeyi + kıyı taşları + nilüferler
	b.box(Vector3(x, g + 0.01, n), Vector3(r * 2.1, 0.02, r * 1.7), Color(0.22, 0.3, 0.32), 0, false)
	_water_plane(b, decor, Vector3(x, g + 0.06, n), Vector2(r * 2.0, r * 1.6))
	var ns = 30
	for i in ns:
		var a = TAU * i / ns
		var px = x + cos(a) * r * 1.02
		var pn = n + sin(a) * r * 0.82
		b.boulder(Vector3(px, G.call(px, pn) + 0.25, pn), Vector3(1.2, 0.6, 1.0) * rng.randf_range(0.7, 1.3), STONE.darkened(rng.randf_range(0.0, 0.25)), i, false)
	for i in 7:
		var a = rng.randf() * TAU
		var rr = rng.randf_range(0.2, 0.7) * r
		b.pack_mesh(CityLandscape.mesh("lily"), Vector3(x + cos(a) * rr, g + 0.08, n + sin(a) * rr * 0.8), rng.randf() * 360.0, rng.randf_range(0.8, 1.3))
	# şelale kaya yığını (göletin arkasında) + düşen su + köpük
	var fx = x + 2.0
	var fn = n + r * 0.8 + 3.0
	var fg = G.call(fx, fn)
	b.crag(Vector3(fx, fg, fn + 2.5), 9.0, 7.5, Color(0.45, 0.44, 0.42), 3, true)
	b.crag(Vector3(fx - 6.0, fg, fn + 1.0), 6.0, 5.0, Color(0.5, 0.48, 0.45), 7, true)
	b.crag(Vector3(fx + 6.5, fg, fn + 1.5), 6.5, 5.6, Color(0.48, 0.46, 0.44), 11, true)
	for k in 8:
		var mi = MeshInstance3D.new()
		var q = QuadMesh.new()
		q.size = Vector2(3.2 + k * 0.08, 7.0 / 8.0 + 0.3)
		mi.mesh = q
		mi.material_override = Canal._water()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		decor.add_child(mi)
		mi.global_position = b.w(Vector3(fx, fg + 7.0 * (1.0 - (k + 0.5) / 8.0), fn - 3.2 - k * 0.1))   # kaya yüzünün önünde
	for k in 6:   # şelale dibinde köpük
		var a = rng.randf() * PI
		b.sphere(Vector3(fx + cos(a) * 1.6, fg + 0.15, fn - 4.0 + sin(a) * 0.5), Vector3(1.0, 0.25, 0.8), Color(0.92, 0.96, 1.0), 8)
	# kıyıda sazlar
	for i in 10:
		var a = rng.randf_range(-0.6, 3.5)
		b.pack_mesh(CityLandscape.veg(16), Vector3(x + cos(a) * (r + 1.0), G.call(x, n), n + sin(a) * (r * 0.8 + 1.0)), rng.randf() * 360.0, 0.9)
	# kıyıda bank (şelaleye bakar)
	b.pack_mesh(CityLandscape.mesh("bench"), Vector3(x - r - 3.0, G.call(x - r - 3.0, n), n), 270.0, 1.0)


static func _water_plane(b: Builder, decor: Node3D, p: Vector3, size: Vector2, yaw := 0.0) -> void:
	var mi = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = size
	mi.mesh = pm
	mi.material_override = Canal._water()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	decor.add_child(mi)
	mi.global_position = b.w(p)
	mi.rotation.y = deg_to_rad(-yaw)


# ------------------------------------------------------------------ dere + kırmızı kemerli köprü + basamak taşları
static func _stream(b: Builder, decor: Node3D, cx: float, cn: float, G: Callable, rng: RandomNumberGenerator) -> void:
	# göletten güneydoğuya kıvrılarak alanın dışına akar
	var pts = [Vector2(cx + 50.0, cn + 22.0), Vector2(cx + 56.0, cn + 8.0), Vector2(cx + 52.0, cn - 8.0), Vector2(cx + 58.0, cn - 26.0), Vector2(cx + 66.0, cn - 44.0), Vector2(cx + 74.0, cn - 60.0)]
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var e: Vector2 = pts[i + 1]
		var mid = (a + e) * 0.5
		var L = a.distance_to(e)
		var yaw = rad_to_deg(atan2(e.x - a.x, e.y - a.y))
		var g = G.call(mid.x, mid.y)
		b.box(Vector3(mid.x, g + 0.01, mid.y), Vector3(4.4, 0.02, L + 1.0), Color(0.24, 0.3, 0.3), yaw, false)
		_water_plane(b, decor, Vector3(mid.x, g + 0.05, mid.y), Vector2(3.6, L + 1.0), yaw)
		for k in 4:   # kıyı çakılları
			var t = (k + rng.randf()) / 4.0
			var q = a.lerp(e, t)
			var side = Vector2(e.y - a.y, -(e.x - a.x)).normalized() * (2.4 if k % 2 == 0 else -2.4)
			b.boulder(Vector3(q.x + side.x, G.call(q.x, q.y) + 0.15, q.y + side.y), Vector3(0.8, 0.4, 0.7) * rng.randf_range(0.7, 1.3), STONE, k + i * 4, false)
	# kırmızı kemerli köprü (3. ve 4. nokta arası)
	var bp: Vector2 = (pts[2] + pts[3]) * 0.5
	var dirv: Vector2 = (pts[3] - pts[2]).normalized()
	var across = Vector2(dirv.y, -dirv.x)
	var byaw = rad_to_deg(atan2(across.x, across.y))
	var g0 = G.call(bp.x, bp.y)
	for k in 9:
		var t = (k - 4) / 4.0
		var q = bp + across * t * 3.4
		var h = 0.75 * (1.0 - t * t)
		b.box(Vector3(q.x, g0 + 0.25 + h, q.y), Vector3(2.6, 0.14, 0.82), WOOD, byaw, true)
	for side in [-1.0, 1.0]:
		var off = dirv * side * 1.3
		for k in 5:
			var t = (k - 2) / 2.0
			var q = bp + across * t * 3.2 + off
			var h = 0.75 * (1.0 - t * t)
			b.box(Vector3(q.x, g0 + 0.85 + h, q.y), Vector3(0.14, 1.1, 0.14), RED, byaw, false)
		for k in 4:
			var t0 = (k - 2) / 2.0
			var t1 = (k - 1) / 2.0
			var q = bp + across * (t0 + t1) * 0.5 * 3.2 + off
			var h = 0.75 * (1.0 - ((t0 + t1) * 0.5) * ((t0 + t1) * 0.5))
			b.box(Vector3(q.x, g0 + 1.35 + h, q.y), Vector3(0.1, 0.1, 1.7), RED, byaw, false, Vector3(-(t0 + t1) * 12.0, 0, 0))
	# yukarıda basamak taşları ile geçit
	var sp: Vector2 = (pts[0] + pts[1]) * 0.5
	for k in 4:
		var q = sp + Vector2(-2.2 + k * 1.45, rng.randf_range(-0.3, 0.3))
		b.pack_mesh(CityLandscape.mesh("step"), Vector3(q.x, G.call(q.x, q.y) + 0.12, q.y), rng.randf() * 360.0, 1.3)


# ------------------------------------------------------------------ hedef tahtaları (kunai/shuriken saplı)
static func _targets(b: Builder, x0: float, n0: float, G: Callable) -> void:
	for i in 5:
		var x = x0 - 16.0 + i * 8.0
		var g = G.call(x, n0)
		for sx in [-0.7, 0.7]:
			b.box(Vector3(x + sx, g + 1.0, n0 + 0.3), Vector3(0.14, 2.0, 0.14), WOOD_D, 0, true)
		var rings = [[1.6, Color(0.92, 0.88, 0.78)], [1.25, RED], [0.9, Color(0.92, 0.88, 0.78)], [0.55, RED], [0.22, Color(0.15, 0.12, 0.1)]]
		for k in rings.size():
			b.disc(Vector3(x, g + 1.65, n0 + 0.04 + k * 0.035), rings[k][0], 0.03, rings[k][1], 0.0, 24)   # ön yüz atış çizgisine (+n); halkalar üst üste öne
		for k in 3:
			var a = TAU * (k + i * 0.37) / 3.0
			_kunai(b, Vector3(x + cos(a) * 0.4, g + 1.65 + sin(a) * 0.4, n0 + 0.32), 0.0)
	# atış çizgisi + uzaklık taşları
	var ln = n0 + 14.0
	b.box(Vector3(x0, G.call(x0, ln) + 0.012, ln), Vector3(42.0, 0.02, 0.35), Color(0.92, 0.9, 0.84), 0, false)
	for i in 5:
		var x = x0 - 16.0 + i * 8.0
		b.box(Vector3(x, G.call(x, ln + 1.0) + 0.25, ln + 1.0), Vector3(0.6, 0.5, 0.4), STONE, 0, true)
		b.kanji(Vector3(x, G.call(x, ln + 1.0) + 0.52, ln + 0.79), str(i + 1), 0.3, Color(0.2, 0.15, 0.1), 180.0)


static func _kunai(b: Builder, p: Vector3, yaw: float) -> void:
	var steel = Color(0.62, 0.64, 0.68)
	var d = Builder.rot(0, -0.18, yaw)
	b.box(p + Vector3(d.x, 0, d.y), Vector3(0.05, 0.05, 0.3), Color(0.14, 0.13, 0.13), yaw, false)        # sap
	b.box(p + Vector3(d.x * 2.0, 0, d.y * 2.0) * 0.95, Vector3(0.12, 0.12, 0.02), steel, yaw, false)       # halka (kare)


# ------------------------------------------------------------------ sütun atlama parkuru (farklı boylarda dikmeler)
static func _pillars(b: Builder, x0: float, n0: float, G: Callable, rng: RandomNumberGenerator) -> void:
	for r in 3:
		for c in 4:
			var x = x0 + c * 3.2 + (r % 2) * 1.6
			var n = n0 + r * 3.2
			var h = 1.2 + rng.randf_range(0.0, 2.8)
			var g = G.call(x, n)
			b.cyl(Vector3(x, g + h * 0.5, n), 0.55, h, WOOD.darkened(rng.randf_range(0.0, 0.15)), true, 8)
			b.cyl(Vector3(x, g + h + 0.02, n), 0.5, 0.04, Color(0.72, 0.58, 0.4), false, 8)
	# denge kütükleri (yatay)
	for k in 2:
		var x = x0 + 4.8
		var n = n0 - 4.0 - k * 2.4
		b.box(Vector3(x, G.call(x, n) + 0.8 + k * 0.4, n), Vector3(9.0, 0.32, 0.32), WOOD, 0, true)
		for sx in [-4.0, 4.0]:
			b.box(Vector3(x + sx, G.call(x + sx, n) + 0.4 + k * 0.2, n), Vector3(0.3, 0.8 + k * 0.4, 0.3), WOOD_D, 0, true)


# ------------------------------------------------------------------ tırmanma ağaçları (dev, kunai çentikli)
static func _climb_trees(b: Builder, cx: float, cn: float, G: Callable, rng: RandomNumberGenerator) -> void:
	for p in [Vector2(cx + 26.0, cn - 28.0), Vector2(cx + 38.0, cn - 16.0), Vector2(cx - 50.0, cn + 30.0)]:
		var g = G.call(p.x, p.y)
		b.tree(p.x, p.y, 2.3, rng, g)
		for k in 4:   # gövdeye çizilmiş yükseklik çentikleri (tırmanma antrenmanı)
			b.box(Vector3(p.x, g + 2.0 + k * 1.6, p.y - 0.75), Vector3(0.5, 0.06, 0.04), Color(0.95, 0.92, 0.85), 0, false)


# ------------------------------------------------------------------ giriş: küçük torii, tabela, silah rafı
static func _entrance(b: Builder, x: float, n: float, G: Callable) -> void:
	var g = G.call(x, n)
	b.prop("torii_small", Vector3(x, g, n), 90.0, 6.0)
	var sx = x + 4.0
	var sn = n - 6.0
	var sg = G.call(sx, sn)
	for k in [-0.9, 0.9]:
		b.box(Vector3(sx, sg + 1.2, sn + k), Vector3(0.18, 2.4, 0.18), WOOD_D, 0, true)
	b.box(Vector3(sx, sg + 2.2, sn), Vector3(0.12, 0.9, 2.3), Color(0.82, 0.72, 0.52), 0, false)
	b.kanji(Vector3(sx - 0.08, sg + 2.2, sn), "第三演習場", 0.36, Color(0.15, 0.1, 0.08), 90.0)
	# silah rafı: dikmeler, raflar, kunai ve shuriken
	var rx = x + 4.0
	var rn = n + 7.0
	var rg = G.call(rx, rn)
	for k in [-1.2, 1.2]:
		b.box(Vector3(rx, rg + 0.9, rn + k), Vector3(0.12, 1.8, 0.12), WOOD_D, 0, true)
	for h in [0.6, 1.2, 1.7]:
		b.box(Vector3(rx, rg + h, rn), Vector3(0.12, 0.08, 2.5), WOOD, 0, false)
	for k in 6:
		_kunai(b, Vector3(rx + 0.12, rg + 1.0, rn - 0.9 + k * 0.36), 90.0)
	for k in 4:
		var q = Vector3(rx + 0.1, rg + 1.48, rn - 0.75 + k * 0.5)
		b.disc(q, 0.26, 0.03, Color(0.6, 0.62, 0.66), 90.0, 4)


# ------------------------------------------------------------------ ipli ahşap çit (girişte boşluk)
static func _fence(b: Builder, cx: float, cn: float, hw: float, hd: float, G: Callable) -> void:
	var sides = [[Vector2(cx - hw, cn - hd), Vector2(cx + hw, cn - hd)], [Vector2(cx + hw, cn - hd), Vector2(cx + hw, cn + hd)],
		[Vector2(cx + hw, cn + hd), Vector2(cx - hw, cn + hd)], [Vector2(cx - hw, cn + hd), Vector2(cx - hw, cn - hd)]]
	for s in sides:
		var a: Vector2 = s[0]
		var e: Vector2 = s[1]
		var L = a.distance_to(e)
		var nposts = int(L / 6.0)
		for k in nposts + 1:
			var q = a.lerp(e, float(k) / nposts)
			if absf(q.x - (cx - hw)) < 0.5 and absf(q.y - cn) < 6.0:
				continue   # giriş
			if Vector2(q.x - (cx + 56.0), q.y - (cn - 47.0)).length() < 9.0:
				continue   # dere çıkışı
			var g = G.call(q.x, q.y)
			b.box(Vector3(q.x, g + 0.6, q.y), Vector3(0.2, 1.2, 0.2), WOOD_D, 0, true)
			if k < nposts:
				var q2 = a.lerp(e, float(k + 1) / nposts)
				if absf(q2.x - (cx - hw)) < 0.5 and absf(q2.y - cn) < 6.0:
					continue
				var m = (q + q2) * 0.5
				var yaw = rad_to_deg(atan2(q2.x - q.x, q2.y - q.y))
				b.box(Vector3(m.x, G.call(m.x, m.y) + 0.95, m.y), Vector3(0.06, 0.06, q.distance_to(q2)), Color(0.82, 0.74, 0.55), yaw, false)


# ------------------------------------------------------------------ bahçe: sakura halkası, fenerler, çiçekler, çalılar, bambu
static func _garden(b: Builder, cx: float, cn: float, G: Callable, rng: RandomNumberGenerator) -> void:
	var sak = Props.village_tree_mesh(1)
	var spots = [Vector2(-60, -44), Vector2(-40, -50), Vector2(-62, 40), Vector2(-20, 48), Vector2(5, 50), Vector2(60, -50),
		Vector2(62, 46), Vector2(-62, -20), Vector2(-30, 44), Vector2(28, 48), Vector2(-48, -40), Vector2(64, 0)]
	for s in spots:
		var x = cx + s.x
		var n = cn + s.y
		var g = G.call(x, n)
		var sc = rng.randf_range(1.1, 1.45)
		b.pack_mesh(sak, Vector3(x, g, n), rng.randf() * 360.0, sc, 1.0)
		b.leaf_spots.append([b.w(Vector3(x, g + Props.VILLAGE_TREE_TOP[1] * sc, n)), Props.VILLAGE_TREE_LEAF[1], 3.4 * sc])   # dökülen pembe yapraklar
		for k in 5:   # ağacın altına düşmüş pembe yaprak öbekleri
			var a = rng.randf() * TAU
			var rr = rng.randf_range(0.8, 3.2) * sc
			b.box(Vector3(x + cos(a) * rr, g + 0.012, n + sin(a) * rr), Vector3(0.9, 0.02, 0.6) * rng.randf_range(0.6, 1.3), Color(1.0, 0.78, 0.86), rng.randf() * 180.0, false)
	# taş fenerler (gece yanar) — patika boyunca
	for p in [Vector2(-60, 8), Vector2(-60, -8), Vector2(-24, 10), Vector2(-24, -10), Vector2(-42, 22), Vector2(30, 20)]:
		b.lantern(cx + p.x, cn + p.y, 3.2 + G.call(cx + p.x, cn + p.y))
	# girişten merkeze basamak taşı patikası
	for k in 18:
		var t = k / 17.0
		var x = lerpf(cx - 64.0, cx - 6.0, t)
		var n = cn + sin(t * 3.0) * 3.0
		b.pack_mesh(CityLandscape.mesh("step"), Vector3(x, G.call(x, n) + 0.06, n), rng.randf() * 360.0, rng.randf_range(1.0, 1.25))
	# çiçek öbekleri (anıtın çevresi + patika kenarı)
	for i in 26:
		var a = rng.randf() * TAU
		var p = Vector2(cx - 35.0 + cos(a) * rng.randf_range(4.0, 8.0), cn + 30.0 + sin(a) * rng.randf_range(3.0, 6.0)) if i < 14 else Vector2(lerpf(cx - 62.0, cx - 10.0, rng.randf()), cn + rng.randf_range(4.0, 7.0) * (1.0 if i % 2 == 0 else -1.0))
		b.pack_mesh(CityLandscape._flower(rng.randi() % Props.FLOWER_KINDS), Vector3(p.x, G.call(p.x, p.y), p.y), rng.randf() * 360.0, rng.randf_range(0.9, 1.3))
	# çalılar + bambu köşesi
	for i in 14:
		var p = Vector2(cx + rng.randf_range(-66.0, 66.0), cn + (52.0 if i % 2 == 0 else -52.0) + rng.randf_range(-2.0, 2.0))
		b.pack_mesh(CityLandscape.mesh("bush"), Vector3(p.x, G.call(p.x, p.y), p.y), rng.randf() * 360.0, rng.randf_range(0.9, 1.4))
	for i in 9:
		var p = Vector2(cx - 62.0 + rng.randf_range(-3.0, 3.0), cn + 30.0 + i * 2.2)
		b.prop("bamboo", Vector3(p.x, G.call(p.x, p.y), p.y), rng.randf() * 360.0, rng.randf_range(5.0, 7.5))
	# kütüklerin karşısında banklar (izleyen akademi öğrencileri)
	for k in 2:
		var x = cx - 8.0 + k * 16.0
		var n = cn + 26.0
		b.pack_mesh(CityLandscape.mesh("bench"), Vector3(x, G.call(x, n), n), 180.0, 1.0)
	# dış halka ağaçları (orman sınırı)
	for k in 26:
		var a = rng.randf() * TAU
		var tr = rng.randf_range(84.0, 120.0)
		var tx = cx + cos(a) * tr
		var tn = cn + sin(a) * tr * 0.8
		if road_check.is_valid() and road_check.call(tx, tn):
			continue
		b.tree(tx, tn, rng.randf_range(1.3, 1.9), rng, G.call(tx, tn))
