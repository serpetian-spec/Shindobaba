class_name SpecialBuildings
extends RefCounted
## Köyün özel binaları (Konoha): her biri kendi kimliğiyle — hastane (giriş kulesi, saçaklı kat bantları, kanopi, çatı korkuluğu,
## bahçe), ANBU karargâhı (karanlık sur, ağır kapı, meşaleler, maske arması), dükkân cepheleri (noren perde, kanji tabela,
## fenerler, sundurma ve dükkâna özel vitrin: ilaç kavanozları, silah rafı, manken, şemsiyeli çay bankı, mangal bacası, han kapısı).

static func _g(b: Builder, x: float, n: float) -> float:
	return Game.terrain_height(b.origin.x + x, b.origin.z - n) - b.origin.y


## Dükkân cephesi. nf: cephe düzlemi (yerel n), dn: caddeye doğru yön (+1 kuzey / -1 güney), w: cephe genişliği
static func shop_front(b: Builder, decor: Node3D, x: float, nf: float, dn: float, kind: String, col: Color, w: float) -> void:
	var yo = b.yoff
	b.yoff = _g(b, x, nf + dn * 2.0)
	var yaw = 0.0 if dn < 0.0 else 180.0
	var wood = Color(0.38, 0.25, 0.15)
	var cream = Color(0.97, 0.94, 0.86)
	var kj = {"pharmacy": "薬", "weapon_shop": "武器", "tailor": "呉服", "teahouse": "茶屋", "bbq": "焼肉", "inn": "宿"}.get(kind, "店")
	var f = func(d: float) -> float: return nf + dn * d   # cepheden caddeye d metre
	# sundurma: eğik saçak + iki direk
	b.box(Vector3(x, 3.6, f.call(1.3)), Vector3(w * 0.8, 0.14, 2.8), col.darkened(0.25), yaw, false, Vector3(12, 0, 0))
	for sx in [-1.0, 1.0]:
		b.box(Vector3(x + sx * w * 0.38, 1.7, f.call(2.5)), Vector3(0.2, 3.4, 0.2), wood, yaw)
	# kanji tabela (ahşap levha üstünde)
	b.box(Vector3(x, 4.7, f.call(0.15)), Vector3(minf(w * 0.6, 1.6 + kj.length() * 1.3), 1.4, 0.2), wood, yaw, false)
	b.box(Vector3(x, 4.7, f.call(0.27)), Vector3(minf(w * 0.6, 1.6 + kj.length() * 1.3) - 0.25, 1.15, 0.05), cream, yaw, false)
	b.kanji(Vector3(x, 4.7, f.call(0.33)), kj, 0.95, Color(0.12, 0.1, 0.1), yaw)
	# noren: kapı üstünde 4 kumaş şerit + ortada kanji
	for k in 4:
		b.box(Vector3(x - 1.35 + k * 0.9, 2.55, f.call(0.4)), Vector3(0.84, 1.0, 0.04), col, yaw, false)
	b.box(Vector3(x, 3.08, f.call(0.38)), Vector3(3.8, 0.08, 0.08), wood, yaw, false)
	b.kanji(Vector3(x, 2.6, f.call(0.44)), kj.substr(0, 1), 0.6, cream, yaw)
	# kapı yanlarında fenerler (gece yanar)
	for sx in [-1.0, 1.0]:
		var lp = Vector3(x + sx * 2.6, 2.9, f.call(0.5))
		b.cyl(lp + Vector3(0, 0.42, 0), 0.08, 0.2, wood, false, 6)
		b.sphere(lp, Vector3(0.55, 0.7, 0.55), Color(0.9, 0.22, 0.16) if kind in ["bbq", "teahouse"] else Color(1.0, 0.93, 0.8), 10)
		Lights.add(b.w(lp))
	# dükkâna özel vitrin
	match kind:
		"pharmacy":
			b.box(Vector3(x + w * 0.3, 0.5, f.call(1.0)), Vector3(2.4, 1.0, 0.8), wood, yaw)
			for k in 6:
				b.cyl(Vector3(x + w * 0.3 - 1.0 + k * 0.4, 1.2, f.call(1.0)), 0.3, 0.4, [Color(0.45, 0.7, 0.45), Color(0.85, 0.75, 0.4), Color(0.6, 0.4, 0.3)][k % 3], false, 8)
			for k in 3:
				b.cyl(Vector3(x - w * 0.3 + k * 0.7, 0.3, f.call(1.2)), 0.6, 0.6, Color(0.6, 0.48, 0.3), false, 8)
				b.sphere(Vector3(x - w * 0.3 + k * 0.7, 0.65, f.call(1.2)), Vector3(0.55, 0.3, 0.55), Color(0.35, 0.6, 0.3), 8)
		"weapon_shop":
			# silah rafı: iki direk + kirişler + çapraz kılıçlar; dev shuriken tabela
			var rx = x + w * 0.3
			for sx in [-0.9, 0.9]:
				b.box(Vector3(rx + sx, 1.0, f.call(1.0)), Vector3(0.15, 2.0, 0.15), wood, yaw)
			for yy in [0.8, 1.6]:
				b.box(Vector3(rx, yy, f.call(1.0)), Vector3(2.0, 0.08, 0.12), wood, yaw, false)
			for k in 4:
				b.box(Vector3(rx - 0.6 + k * 0.4, 1.25, f.call(1.08)), Vector3(0.06, 1.5, 0.03), Color(0.75, 0.78, 0.82), yaw, false, Vector3(0, 0, 14 if k % 2 else -14))
			var sp = Vector3(x - w * 0.3, 5.2, f.call(0.3))
			for k in 4:
				b.box(sp, Vector3(0.5, 2.0, 0.08), Color(0.25, 0.27, 0.3), yaw, false, Vector3(0, 0, 45.0 + k * 90.0 / 2.0))
			b.cyl(sp, 0.5, 0.12, Color(0.6, 0.62, 0.66), false, 10)
			for sx in [-1.0, 1.0]:  # kunai kütükleri
				b.cyl(Vector3(x + sx * (w * 0.42), 0.5, f.call(1.8)), 0.6, 1.0, Color(0.5, 0.35, 0.2), true, 8)
		"tailor":
			for k in 2:
				var mx = x + w * 0.25 + k * 1.4
				b.cyl(Vector3(mx, 0.75, f.call(1.2)), 0.12, 1.5, wood, false, 6)
				b.box(Vector3(mx, 1.45, f.call(1.2)), Vector3(0.7, 0.8, 0.35), [Color(0.2, 0.3, 0.6), Color(0.75, 0.25, 0.3)][k], yaw, false)
				b.sphere(Vector3(mx, 2.05, f.call(1.2)), Vector3(0.28, 0.32, 0.28), Color(0.9, 0.85, 0.75), 8)
			for k in 4:  # kumaş topları
				b.cyl(Vector3(x - w * 0.3 + k * 0.45, 0.4, f.call(1.0)), 0.36, 0.8, [Color(0.85, 0.3, 0.3), Color(0.3, 0.5, 0.75), Color(0.9, 0.8, 0.4), Color(0.4, 0.65, 0.4)][k], false, 8)
		"teahouse":
			for sx in [-1.0, 1.0]:  # kırmızı bank + büyük şemsiye
				var bx0 = x + sx * w * 0.3
				b.box(Vector3(bx0, 0.45, f.call(1.8)), Vector3(2.4, 0.12, 0.8), Color(0.82, 0.16, 0.14), yaw)
				b.box(Vector3(bx0, 0.22, f.call(1.8)), Vector3(2.2, 0.44, 0.6), wood, yaw, false)
				b.cyl(Vector3(bx0 + 0.9 * sx, 1.6, f.call(2.4)), 0.08, 3.2, wood, false, 6)
				b.cone(Vector3(bx0 + 0.9 * sx, 3.2, f.call(2.4)), 3.0, 0.8, Color(0.85, 0.18, 0.16), 14)
			# dango tabelası: şiş üstünde üç renkli top
			for k in 3:
				b.sphere(Vector3(x + 2.2, 5.4 - k * 0.42, f.call(0.4)), Vector3(0.4, 0.4, 0.4), [Color(1.0, 0.7, 0.75), Color(0.97, 0.95, 0.9), Color(0.55, 0.8, 0.45)][k], 8)
			b.box(Vector3(x + 2.2, 5.0, f.call(0.4)), Vector3(0.05, 1.8, 0.05), wood, yaw, false)
		"bbq":
			b.box(Vector3(x + w * 0.35, 6.0, f.call(-1.0)), Vector3(0.9, 4.0, 0.9), Color(0.4, 0.36, 0.34), yaw)  # baca
			b.box(Vector3(x + w * 0.35, 8.1, f.call(-1.0)), Vector3(1.2, 0.3, 1.2), Color(0.25, 0.22, 0.2), yaw, false)
			CityDecor.lantern_string(decor, b.w(Vector3(x - w * 0.4, 3.9, f.call(2.6))), b.w(Vector3(x + w * 0.4, 3.9, f.call(2.6))), 6, [Color(0.95, 0.25, 0.2), Color(1.0, 0.85, 0.5)])
			b.box(Vector3(x - w * 0.3, 0.5, f.call(1.2)), Vector3(1.4, 1.0, 0.9), Color(0.3, 0.3, 0.32), yaw)  # mangal
			b.box(Vector3(x - w * 0.3, 1.02, f.call(1.2)), Vector3(1.2, 0.04, 0.7), Color(0.85, 0.35, 0.15), yaw, false)
		"inn":
			# han kapısı: iki direk + kiremit çatı, saksı bambular, uzun fenerler
			var gn = f.call(4.0)
			for sx in [-1.0, 1.0]:
				b.box(Vector3(x + sx * 2.4, 1.8, gn), Vector3(0.35, 3.6, 0.35), wood, yaw)
				b.cyl(Vector3(x + sx * 3.4, 0.35, gn - dn * 0.3), 0.7, 0.7, Color(0.4, 0.3, 0.22), false, 8)
				for k in 4:
					b.cyl(Vector3(x + sx * 3.4 + (k % 2) * 0.15 - 0.07, 1.9, gn - dn * 0.3 + (k / 2) * 0.15 - 0.07), 0.08, 3.0, Color(0.45, 0.65, 0.3), false, 5)
			b.roof(Vector3(x, 3.6, gn), Vector3(6.2, 1.0, 1.4), Color(0.22, 0.3, 0.42), yaw + 90.0)
			b.box(Vector3(x, 3.3, gn), Vector3(5.2, 0.3, 0.3), wood, yaw, false)
	b.yoff = yo


## Konoha Hastanesi: geniş beyaz blok, öne çıkan giriş kulesi (kırmızı haç + 病院), kat bantları, pencere sıraları, giriş kanopisi,
## çatı korkuluğu + su depoları, yan kanat ve bağlantı koridoru, ön bahçe (saksılar, banklar, fenerler)
static func hospital(b: Builder, decor: Node3D, hx: float, hn: float, rng: RandomNumberGenerator) -> void:
	var yo = b.yoff
	b.yoff = _g(b, hx, hn)
	var white = Color(0.96, 0.95, 0.92)
	var grey = Color(0.78, 0.78, 0.8)
	var red = Color(0.78, 0.2, 0.17)
	var glass = Color(0.5, 0.7, 0.85)
	var fn = hn - 21.0
	b.box(Vector3(hx, 15, hn), Vector3(76, 30, 42), white)
	b.box(Vector3(hx, 30.6, hn), Vector3(79, 1.4, 45), red)
	for fl in 4:
		var y = 4.5 + fl * 7.0
		b.box(Vector3(hx, y + 3.2, fn - 0.35), Vector3(76.4, 0.4, 0.9), grey, 0, false)
		for i in 12:
			var wx = hx - 33.0 + i * 6.0
			if absf(wx - hx) < 9.0:
				continue
			b.box(Vector3(wx, y, fn - 0.12), Vector3(3.6, 2.8, 0.3), grey.darkened(0.2), 0, false)
			b.box(Vector3(wx, y, fn - 0.25), Vector3(3.1, 2.4, 0.2), glass, 0, false)
	# giriş kulesi
	b.box(Vector3(hx, 18, fn - 3.0), Vector3(16, 36, 6), white.darkened(0.03))
	b.box(Vector3(hx, 36.4, fn - 3.0), Vector3(17, 0.8, 7), red)
	for fl in 3:
		b.box(Vector3(hx, 11.0 + fl * 7.0, fn - 6.15), Vector3(10, 4.6, 0.3), glass.darkened(0.05), 0, false)
		b.box(Vector3(hx, 13.5 + fl * 7.0, fn - 6.2), Vector3(16.2, 0.4, 0.5), grey, 0, false)
	b.disc(Vector3(hx, 31.0, fn - 6.3), 8.0, 0.4, red, 0.0, 24)
	b.box(Vector3(hx, 31.0, fn - 6.55), Vector3(1.6, 5.0, 0.2), Color(1, 1, 1), 0, false)
	b.box(Vector3(hx, 31.0, fn - 6.55), Vector3(5.0, 1.6, 0.2), Color(1, 1, 1), 0, false)
	b.box(Vector3(hx + 9.6, 18.0, fn - 3.0), Vector3(2.4, 12.0, 0.3), Color(0.96, 0.94, 0.88), 0, false)
	b.kanji(Vector3(hx + 9.6, 20.2, fn - 3.2), "病", 2.0, red.darkened(0.2), 0.0)
	b.kanji(Vector3(hx + 9.6, 17.6, fn - 3.2), "院", 2.0, red.darkened(0.2), 0.0)
	# giriş: cam kapılar + kanopi (4 sütun)
	b.box(Vector3(hx, 2.2, fn - 6.2), Vector3(7.0, 4.4, 0.3), glass.lightened(0.15), 0, false)
	b.box(Vector3(hx, 2.2, fn - 6.3), Vector3(0.2, 4.4, 0.3), grey.darkened(0.3), 0, false)
	b.box(Vector3(hx, 5.2, fn - 10.5), Vector3(18.0, 0.5, 9.0), white, 0, false)
	b.box(Vector3(hx, 5.55, fn - 15.0), Vector3(18.0, 0.3, 0.3), red, 0, false)
	for sx in [-1.0, 1.0]:
		for sn in [-8.0, -14.5]:
			b.cyl(Vector3(hx + sx * 8.0, 2.5, fn + sn), 0.5, 5.0, grey, true, 8)
	b.box(Vector3(hx, 0.08, fn - 10.5), Vector3(16.0, 0.16, 9.0), Color(0.72, 0.7, 0.68), 0, false)
	# çatı: korkuluk + su depoları + çamaşır ipi (hastane çatısı)
	var rt = 31.3
	for i in 26:
		var px = hx - 37.5 + i * 3.0
		b.box(Vector3(px, rt + 0.6, hn - 21.8), Vector3(0.12, 1.2, 0.12), grey.darkened(0.2), 0, false)
		b.box(Vector3(px, rt + 0.6, hn + 21.8), Vector3(0.12, 1.2, 0.12), grey.darkened(0.2), 0, false)
	for sz in [-1.0, 1.0]:
		b.box(Vector3(hx, rt + 1.2, hn + sz * 21.8), Vector3(76.0, 0.12, 0.12), grey.darkened(0.2), 0, false)
	for t in 3:
		var tx = hx - 24.0 + t * 12.0
		b.cyl(Vector3(tx, rt + 2.3, hn + 8.0), 4.4, 4.0, Color(0.82, 0.84, 0.86), true, 14)
		b.cone(Vector3(tx, rt + 4.9, hn + 8.0), 5.0, 1.2, Color(0.6, 0.62, 0.66), 14)
	for k in 6:
		b.box(Vector3(hx + 14.0 + k * 1.6, rt + 1.6, hn - 4.0), Vector3(1.2, 1.4, 0.03), Color(0.97, 0.97, 0.97), 0, false)
	b.box(Vector3(hx + 18.0, rt + 2.35, hn - 4.0), Vector3(11.0, 0.04, 0.04), grey.darkened(0.4), 0, false)
	# yan kanat + bağlantı koridoru
	b.box(Vector3(hx + 50, 11, hn + 4), Vector3(22, 22, 30), white.darkened(0.02))
	b.box(Vector3(hx + 50, 22.6, hn + 4), Vector3(24, 1.2, 32), red)
	b.box(Vector3(hx + 40.0, 12.0, hn - 4.0), Vector3(6.0, 4.0, 5.0), glass.lightened(0.1))
	for fl in 3:
		for i in 3:
			b.box(Vector3(hx + 43.0 + i * 7.0, 5.0 + fl * 6.5, hn - 11.15), Vector3(3.6, 2.6, 0.3), glass, 0, false)
	# ön avlu: taş döşeme, derzler, giriş yolu, ortada yuvarlak çiçeklik + ağaç
	var pav = Color(0.82, 0.8, 0.76)
	b.box(Vector3(hx, -0.5, fn - 21.0), Vector3(66.0, 1.12, 42.0), pav, 0, false)
	for k in 12:
		b.box(Vector3(hx - 30.0 + k * 5.5, 0.065, fn - 21.0), Vector3(0.1, 0.03, 41.0), pav.darkened(0.12), 0, false)
	b.box(Vector3(hx, 0.08, fn - 30.0), Vector3(7.0, 0.05, 24.0), pav.lightened(0.1), 0, false)
	b.cyl(Vector3(hx, 0.4, fn - 32.0), 9.0, 0.8, Color(0.7, 0.68, 0.66), true, 24)
	b.cyl(Vector3(hx, 0.75, fn - 32.0), 8.2, 0.1, Color(0.36, 0.26, 0.18), false, 24)
	for k in 10:
		var a = k * 36.0
		var q = Builder.rot(0, 3.4, a)
		b.sphere(Vector3(hx + q.x, 1.1, fn - 32.0 + q.y), Vector3(1.3, 0.9, 1.3), Color(0.26, 0.52, 0.26), 8)
	KageHall.tree(b, hx, fn - 32.0, 0.7, "green", rng, 1.1)
	if b.has_method("add_solid"):
		b.add_solid(b.w(Vector3(hx, 0, fn - 21.0)), 33.0, 21.0, 0.0)
	# ön bahçe: iki saksı (budanmış çalı + ağaç), banklar, fener
	for sx in [-1.0, 1.0]:
		KageHall.planter(b, hx + sx * 24.0, fn - 14.0, 18.0, 7.0, Color(0.7, 0.68, 0.66), "green", rng, 2)
		b.prop("bench", Vector3(hx + sx * 12.5, 0.0, fn - 19.0), 0.0, 0.0, 0.0)
		b.lantern(hx + sx * 11.0, fn - 22.0, 3.2)
	CityDecor.banner(decor, KageHall._gp(b, hx - 10.5, fn - 16.0), 0.0, Color(0.95, 0.95, 0.95), red)
	b.yoff = yo


## ANBU karargâhı: kalın koyu sur, demir çivili ağır kapı (暗部), meşaleler, iki katlı siyah çatılı ana bina, gözetleme kulesi,
## maske arması (beyaz disk + kırmızı çizgiler)
static func anbu(b: Builder, decor: Node3D, ax: float, an: float) -> void:
	var yo = b.yoff
	b.yoff = _g(b, ax, an)
	var wall = Color(0.24, 0.24, 0.27)
	var dark = Color(0.12, 0.12, 0.14)
	var tile = Color(0.08, 0.08, 0.1)
	# sur (güneyde kapı)
	b.wall_rect(ax, an + 2.0, 72.0, 52.0, 7.0, wall, 12.0)
	for sz in [-1.0, 1.0]:  # sur üstü kiremit
		b.box(Vector3(ax, 7.3, an + 2.0 + sz * 26.0), Vector3(73.0, 0.5, 2.0), tile, 0, false)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(ax + sx * 36.0, 7.3, an + 2.0), Vector3(2.0, 0.5, 53.0), tile, 0, false)
	# kapı: iki kule direk + üst kiriş + çatı + ağır kapı kanatları (açık)
	var gn = an + 2.0 - 26.0
	for sx in [-1.0, 1.0]:
		b.box(Vector3(ax + sx * 7.5, 5.0, gn), Vector3(3.0, 10.0, 3.0), wall.darkened(0.1))
		b.roof(Vector3(ax + sx * 7.5, 10.0, gn), Vector3(4.2, 1.6, 4.2), tile)
		b.box(Vector3(ax + sx * 4.6, 3.5, gn - 2.2), Vector3(0.4, 7.0, 4.6), Color(0.22, 0.14, 0.1), sx * 10.0)
		for k in 3:
			for j in 3:
				b.sphere(Vector3(ax + sx * 4.85, 1.6 + k * 2.0, gn - 0.8 - j * 1.2), Vector3(0.18, 0.18, 0.18), Color(0.5, 0.5, 0.52), 6)
		# meşale
		var tp = Vector3(ax + sx * 9.5, 3.4, gn - 1.8)
		b.cyl(tp, 0.15, 2.0, Color(0.3, 0.2, 0.12), false, 6)
		b.cone(tp + Vector3(0, 1.3, 0), 0.6, 0.8, Color(1.0, 0.55, 0.15), 8)
		Lights.add(b.w(tp + Vector3(0, 1.3, 0)))
	b.box(Vector3(ax, 9.4, gn), Vector3(18.0, 1.2, 2.4), dark, 0, false)
	b.roof(Vector3(ax, 10.0, gn), Vector3(20.0, 2.2, 3.4), tile)
	b.box(Vector3(ax, 8.0, gn - 1.3), Vector3(4.6, 1.6, 0.2), Color(0.9, 0.88, 0.84), 0, false)
	b.kanji(Vector3(ax, 8.0, gn - 1.45), "暗部", 1.3, Color(0.1, 0.1, 0.12), 0.0)
	# ana bina: iki kat, siyah kiremit çatılar, maske arması
	b.box(Vector3(ax, 5.0, an + 8.0), Vector3(40, 10, 24), wall)
	b.box(Vector3(ax, 10.4, an + 8.0), Vector3(44, 0.8, 28), dark, 0, false)
	b.box(Vector3(ax, 14.0, an + 10.0), Vector3(30, 7, 16), wall.lightened(0.04))
	b.roof(Vector3(ax, 17.5, an + 10.0), Vector3(34, 5, 20), tile)
	for i in 8:
		b.box(Vector3(ax - 17.5 + i * 5.0, 5.0, an - 4.15), Vector3(1.0, 2.6, 0.3), Color(0.05, 0.05, 0.06), 0, false)
	b.disc(Vector3(ax, 14.0, an + 1.9), 4.4, 0.3, Color(0.95, 0.95, 0.93), 0.0, 20)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(ax + sx * 0.8, 13.6, an + 1.7), Vector3(0.2, 1.4, 0.06), Color(0.75, 0.1, 0.12), 0, false, Vector3(0, 0, 25 * sx))
		b.box(Vector3(ax + sx * 0.9, 14.6, an + 1.7), Vector3(0.9, 0.3, 0.06), Color(0.1, 0.1, 0.12), 0, false, Vector3(0, 0, -12 * sx))
	b.box(Vector3(ax, 3.0, an - 4.15), Vector3(4.0, 6.0, 0.3), Color(0.08, 0.08, 0.09), 0, false)
	# gözetleme kulesi (köşe)
	var tx = ax + 30.0; var tn = an + 22.0
	b.box(Vector3(tx, 9.0, tn), Vector3(6, 18, 6), wall.darkened(0.06))
	b.box(Vector3(tx, 18.5, tn), Vector3(8, 1.0, 8), dark, 0, false)
	b.roof(Vector3(tx, 21.0, tn), Vector3(9, 3, 9), tile)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(tx + sx * 3.6, 19.8, tn), Vector3(0.25, 1.6, 7.6), dark, 0, false)
	# avlu: çakıl zemin, antrenman kütükleri, hedef tahtaları
	b.box(Vector3(ax, 0.05, an - 13.0), Vector3(60, 0.1, 16), Color(0.5, 0.5, 0.52), 0, false)
	for k in 4:
		b.cyl(Vector3(ax - 20.0 + k * 3.0, 0.9, an - 16.0), 0.6, 1.8, Color(0.4, 0.28, 0.18), true, 8)
	for k in 3:
		b.disc(Vector3(ax + 14.0 + k * 4.0, 1.6, an - 8.0), 1.6, 0.2, Color(0.9, 0.88, 0.84), 0.0, 14)
		b.disc(Vector3(ax + 14.0 + k * 4.0, 1.6, an - 8.12), 0.7, 0.2, Color(0.75, 0.15, 0.12), 0.0, 12)
	b.yoff = yo
