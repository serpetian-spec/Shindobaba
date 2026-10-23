class_name DoorKit
extends RefCounted
## Detaylı kapılar (düz dikdörtgen yerine): taş basamak, kasa + lento, köy tarzına göre kapı kanatları
## (sürgülü shoji / ahşap tahta / demir kuşaklı / kemerli), kulp, küçük saçak veya tente, kapı feneri, noren.
## Builder evleri için door() (hücre MB'lerine birleşir), HouseKit şablonları için jp_template() (şablon paylaşılır, MultiMesh).

const WOOD := Color(0.42, 0.28, 0.18)
const DARK := Color(0.2, 0.15, 0.12)
const IRON := Color(0.28, 0.28, 0.3)
const SHOJI := Color(0.96, 0.93, 0.84)
const STONE := Color(0.6, 0.58, 0.55)
const NOREN := [Color(0.15, 0.25, 0.55), Color(0.75, 0.15, 0.12), Color(0.2, 0.38, 0.26), Color(0.5, 0.2, 0.45), Color(0.85, 0.55, 0.15)]


## Builder evine kapı. (x, n): duvar yüzeyindeki kapı ortası (yerel), y: kapı eşiği yüksekliği, yaw: cephe yönü
## (dışarısı Builder.rot(0, -1, yaw) yönünde). style: jp | suna | kiri | iwa | kumo | snow | ame
static func door(b: Builder, x: float, n: float, y: float, yaw: float, style: String, rng: RandomNumberGenerator, accent := Color(0.75, 0.2, 0.15)) -> void:
	var P = func(lx: float, out: float) -> Vector3:
		var o = Builder.rot(lx, -out, yaw)
		return Vector3(x + o.x, 0.0, n + o.y)
	var at = func(lx: float, yy: float, out: float) -> Vector3:
		var q: Vector3 = P.call(lx, out)
		return Vector3(q.x, y + yy, q.z)
	match style:
		"suna":
			var trim = Color(0.72, 0.58, 0.4)
			b.box(at.call(0, -0.12, 0.9), Vector3(3.0, 0.24, 1.6), trim.darkened(0.1), yaw, false)          # basamak
			b.disc(at.call(0, 2.5, 0.06), 2.9, 0.16, trim, yaw, 14)                                      # kemer çerçevesi
			b.box(at.call(0, 1.25, 0.08), Vector3(2.9, 2.5, 0.14), trim, yaw, false)
			b.box(at.call(0, 1.3, 0.14), Vector3(2.0, 2.6, 0.1), Color(0.48, 0.32, 0.2), yaw, false)        # ahşap kanat
			b.disc(at.call(0, 2.6, 0.12), 2.0, 0.1, Color(0.48, 0.32, 0.2), yaw, 12)
			for k in 2:
				b.box(at.call(0, 0.7 + k * 1.2, 0.2), Vector3(2.0, 0.1, 0.04), IRON, yaw, false)          # demir kuşaklar
			b.box(at.call(0, 3.0, 0.26), Vector3(2.4, 0.5, 0.04), NOREN[rng.randi() % NOREN.size()], yaw, false)  # kumaş perde
			b.sphere(at.call(0.55, 1.3, 0.22), Vector3(0.12, 0.12, 0.08), Color(0.8, 0.65, 0.3), 6)
		"kiri":
			var blue = Color(0.26, 0.42, 0.58)
			b.box(at.call(0, -0.1, 0.7), Vector3(2.6, 0.2, 1.2), STONE.darkened(0.1), yaw, false)
			b.box(at.call(0, 1.3, 0.05), Vector3(2.3, 2.8, 0.14), Color(0.45, 0.5, 0.55), yaw, false)       # kasa
			b.box(at.call(0, 1.25, 0.1), Vector3(1.8, 2.5, 0.08), Color(0.3, 0.36, 0.42), yaw, false)       # metal kanat
			b.disc(at.call(0, 1.9, 0.15), 0.6, 0.06, Color(0.6, 0.78, 0.9), yaw, 10)                        # lombar pencere
			b.disc(at.call(0, 1.9, 0.14), 0.75, 0.05, IRON, yaw, 10)
			b.box(at.call(0.6, 1.2, 0.16), Vector3(0.08, 0.4, 0.06), IRON, yaw, false)
			b.box(at.call(0, 2.95, 0.7), Vector3(2.8, 0.12, 1.4), blue, yaw, false, Vector3(-12, 0, 0))   # mavi saçak
			for sx in [-1.0, 1.0]:
				b.box(at.call(sx * 1.2, 2.7, 0.55), Vector3(0.08, 0.6, 0.08), IRON, yaw, false, Vector3(35, 0, 0))
		"iwa":
			var st = Color(0.5, 0.42, 0.34)
			for k in 2:
				b.box(at.call(0, -0.15 - k * 0.25, 0.6 + k * 0.6), Vector3(2.8 + k * 0.6, 0.3, 1.2), st.darkened(0.08 * k), yaw, false)
			for sx in [-1.0, 1.0]:
				b.box(at.call(sx * 1.2, 1.4, 0.15), Vector3(0.5, 2.8, 0.4), st.darkened(0.15), yaw, false)  # taş söveler
			b.box(at.call(0, 2.95, 0.2), Vector3(3.2, 0.5, 0.6), st.darkened(0.22), yaw, false)               # lento
			b.box(at.call(0, 1.3, 0.08), Vector3(1.9, 2.6, 0.1), Color(0.4, 0.25, 0.15), yaw, false)
			for k in 3:
				for j in 2:
					b.sphere(at.call(-0.5 + j * 1.0, 0.6 + k * 0.8, 0.14), Vector3(0.1, 0.1, 0.06), IRON, 5)  # demir çiviler
			b.box(at.call(0, 3.35, 0.35), Vector3(3.6, 0.3, 0.9), Color(0.55, 0.22, 0.16), yaw, false)       # kırmızı saçak
		"kumo":
			var blue = Color(0.22, 0.45, 0.72)
			b.box(at.call(0, -0.1, 0.7), Vector3(2.6, 0.2, 1.2), Color(0.8, 0.8, 0.78), yaw, false)
			b.disc(at.call(0, 2.6, 0.06), 2.5, 0.12, blue, yaw, 14)
			b.box(at.call(0, 1.3, 0.08), Vector3(2.5, 2.6, 0.12), blue, yaw, false)
			b.box(at.call(0, 1.3, 0.13), Vector3(1.8, 2.5, 0.08), Color(0.92, 0.92, 0.9), yaw, false)
			b.disc(at.call(0, 2.55, 0.13), 1.8, 0.06, Color(0.92, 0.92, 0.9), yaw, 12)
			b.box(at.call(0, 1.3, 0.18), Vector3(0.06, 2.4, 0.04), blue.darkened(0.2), yaw, false)
			for sx in [-1.0, 1.0]:
				b.box(at.call(sx * 0.25, 1.25, 0.2), Vector3(0.05, 0.35, 0.05), Color(0.85, 0.7, 0.25), yaw, false)
		"snow":
			b.box(at.call(0, -0.1, 0.7), Vector3(2.4, 0.2, 1.2), STONE, yaw, false)
			b.box(at.call(0, 1.25, 0.05), Vector3(2.0, 2.6, 0.14), DARK, yaw, false)
			b.box(at.call(0, 1.2, 0.1), Vector3(1.6, 2.3, 0.08), Color(0.55, 0.38, 0.24), yaw, false)
			b.box(at.call(0, 1.2, 0.15), Vector3(0.12, 2.6, 0.04), DARK, yaw, false, Vector3(0, 0, 34))      # çapraz destek
			b.box(at.call(0.55, 1.2, 0.16), Vector3(0.06, 0.3, 0.06), IRON, yaw, false)
			b.box(at.call(0, 2.75, 0.6), Vector3(2.6, 0.14, 1.3), DARK, yaw, false, Vector3(-18, 0, 0))     # saçak
			b.box(at.call(0, 2.9, 0.6), Vector3(2.7, 0.16, 1.35), Color(0.95, 0.97, 1.0), yaw, false, Vector3(-18, 0, 0))
			var lp: Vector3 = at.call(1.3, 2.2, 0.35)
			b.sphere(lp, Vector3(0.3, 0.4, 0.3), Color(1.0, 0.85, 0.55), 8)
			Lights.add(b.w(lp))
		"ame":
			b.box(at.call(0, 1.3, 0.05), Vector3(2.2, 2.7, 0.14), IRON, yaw, false)
			b.box(at.call(0, 1.25, 0.1), Vector3(1.8, 2.5, 0.08), Color(0.22, 0.24, 0.27), yaw, false)
			for k in 5:
				b.box(at.call(0, 0.35 + k * 0.45, 0.15), Vector3(1.8, 0.05, 0.03), Color(0.32, 0.34, 0.37), yaw, false)
			b.box(at.call(0, 2.85, 0.5), Vector3(2.6, 0.1, 1.0), IRON, yaw, false, Vector3(-10, 0, 0))
		_:
			_jp(b, at, yaw, rng, accent)


## Japon/Konoha kapısı: basamak, kasa + lento, sürgülü iki kanat (shoji ya da ahşap), kafes, kulp, saçak + destekler, fener
static func _jp(b: Builder, at: Callable, yaw: float, rng: RandomNumberGenerator, accent: Color) -> void:
	var shoji = rng.randf() < 0.55
	b.box(at.call(0, -0.12, 0.75), Vector3(2.6, 0.24, 1.3), STONE, yaw, false)
	for sx in [-1.0, 1.0]:
		b.box(at.call(sx * 1.12, 1.25, 0.08), Vector3(0.2, 2.5, 0.2), WOOD, yaw, false)
	b.box(at.call(0, 2.55, 0.08), Vector3(2.6, 0.22, 0.22), WOOD, yaw, false)
	var pc = SHOJI if shoji else WOOD.lightened(0.18)
	for sx in [-1.0, 1.0]:
		b.box(at.call(sx * 0.5, 1.2, 0.06 + (0.03 if sx > 0 else 0.0)), Vector3(1.04, 2.3, 0.05), pc, yaw, false)
	if shoji:
		for k in 3:
			b.box(at.call(0, 0.55 + k * 0.6, 0.12), Vector3(2.0, 0.04, 0.02), DARK, yaw, false)
		b.box(at.call(0, 0.25, 0.11), Vector3(2.04, 0.5, 0.04), WOOD, yaw, false)
	else:
		for k in 4:
			b.box(at.call(-0.75 + k * 0.5, 1.2, 0.11), Vector3(0.03, 2.3, 0.02), DARK, yaw, false)
	b.box(at.call(0, 1.2, 0.12), Vector3(0.06, 2.3, 0.03), DARK, yaw, false)
	b.box(at.call(0.3, 1.15, 0.13), Vector3(0.05, 0.28, 0.04), DARK, yaw, false)
	b.box(at.call(0, 2.95, 0.55), Vector3(3.0, 0.12, 1.2), Color(0.3, 0.3, 0.34), yaw, false, Vector3(-16, 0, 0))
	for sx in [-1.0, 1.0]:
		b.box(at.call(sx * 1.2, 2.72, 0.42), Vector3(0.1, 0.1, 0.7), WOOD, yaw, false, Vector3(30, 0, 0))
	if rng.randf() < 0.4:
		var lp: Vector3 = at.call(1.55, 2.0, 0.3)
		b.sphere(lp, Vector3(0.32, 0.42, 0.32), Color(1.0, 0.9, 0.7) if rng.randf() < 0.6 else accent, 8)


## HouseKit şablonu için (şablon uzayı: ön cephe -Z, taban y0). shop: noren + fener + tabela ayrıca eklenir
static func jp_template(det: MB, fz: float, y0: float, shop: bool, rng: RandomNumberGenerator) -> void:
	var at = func(lx: float, yy: float, out: float) -> Vector3: return Vector3(lx, y0 + yy, fz - out)
	var shoji = shop or rng.randf() < 0.55
	det.add("box", at.call(0, -0.12, 0.8), Vector3(2.8, 0.24, 1.3), STONE)
	det.add("box", at.call(0, -0.32, 1.5), Vector3(2.2, 0.2, 0.7), STONE.darkened(0.08))
	for sx in [-1.0, 1.0]:
		det.add("box", at.call(sx * 1.22, 1.3, 0.1), Vector3(0.22, 2.6, 0.22), WOOD)
	det.add("box", at.call(0, 2.68, 0.1), Vector3(2.9, 0.24, 0.26), WOOD)
	var pc = SHOJI if shoji else WOOD.lightened(0.18)
	det.add("box", at.call(-0.55, 1.25, 0.06), Vector3(1.12, 2.4, 0.05), pc)
	det.add("box", at.call(0.55, 1.25, 0.09), Vector3(1.12, 2.4, 0.05), pc)
	if shoji:
		for k in 4:
			det.add("box", at.call(0, 0.55 + k * 0.5, 0.13), Vector3(2.2, 0.035, 0.02), DARK)
		for k in 5:
			det.add("box", at.call(-0.88 + k * 0.44, 1.45, 0.13), Vector3(0.035, 1.9, 0.02), DARK)
		det.add("box", at.call(0, 0.25, 0.12), Vector3(2.24, 0.5, 0.04), WOOD)
	else:
		for k in 5:
			det.add("box", at.call(-0.88 + k * 0.44, 1.25, 0.12), Vector3(0.03, 2.4, 0.02), DARK)
		det.add("box", at.call(-0.55, 1.6, 0.11), Vector3(0.5, 0.6, 0.03), SHOJI)   # küçük ışıklık
		det.add("box", at.call(0.55, 1.6, 0.14), Vector3(0.5, 0.6, 0.03), SHOJI)
	det.add("box", at.call(0, 1.25, 0.14), Vector3(0.07, 2.4, 0.03), DARK)
	det.add("box", at.call(0.35, 1.2, 0.15), Vector3(0.05, 0.3, 0.04), DARK)
	det.add("box", at.call(-0.25, 1.2, 0.12), Vector3(0.05, 0.3, 0.04), DARK)
	# saçak (hisashi): koyu kiremit + ahşap destekler (dükkânlarda tente zaten var)
	if not shop:
		det.add("box", at.call(0, 3.1, 0.62), Vector3(3.4, 0.14, 1.35), Color(0.28, 0.28, 0.32), Vector3(-16, 0, 0))
		det.add("box", at.call(0, 3.2, 0.62), Vector3(3.4, 0.05, 1.35), Color(0.36, 0.36, 0.4), Vector3(-16, 0, 0))
		for sx in [-1.0, 1.0]:
			det.add("box", at.call(sx * 1.3, 2.85, 0.45), Vector3(0.1, 0.1, 0.75), WOOD, Vector3(32, 0, 0))
	if not shop and rng.randf() < 0.5:
		det.add("sphere", at.call(1.7, 2.15, 0.3), Vector3(0.34, 0.46, 0.34), Color(1.0, 0.92, 0.72), Vector3.ZERO, 8)
		det.add("box", at.call(1.7, 2.45, 0.3), Vector3(0.2, 0.06, 0.2), DARK)
	if not shop and rng.randf() < 0.45:  # ev noreni (kısa)
		var nc = NOREN[rng.randi() % NOREN.size()]
		for k in 2:
			det.add("box", at.call(-0.5 + k * 1.0, 2.3, 0.2), Vector3(0.95, 0.55, 0.03), nc)
