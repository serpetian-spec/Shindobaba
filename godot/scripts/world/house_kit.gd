class_name HouseKit
extends RefCounted
## Detaylı Japon/Konoha evleri: başlangıçta N şablon üretilir, MultiMesh ile çoğaltılır.
## Her şablon 3 parça: duvarlar (duvar rengiyle boyanır), çatı (çatı rengiyle), detaylar (kendi renkleri).
## Şablon yerel uzayı: taban merkezi (0,0,0), ön cephe -Z (yerel kuzey değil, "sokağa bakan" taraf).

const WOOD := Color(0.42, 0.28, 0.18)
const DARK := Color(0.2, 0.15, 0.12)
const SHOJI := Color(0.95, 0.92, 0.82)
const GLASS := Color(0.55, 0.72, 0.85)
const STONE := Color(0.55, 0.53, 0.5)

static var templates: Array = []   # her biri: {walls, roof, detail, w, d, h, roof_top}


static func ensure(count := 70) -> void:
	if not templates.is_empty():
		return
	var rng = RandomNumberGenerator.new()
	rng.seed = 4242
	for i in count:
		templates.append(_make(rng, i))


## Şablon türleri (Konoha şehir dokusu): 0-1 kasaba evi (2-4 kat), 2 apartman bloğu (4-6 kat, balkon sıraları, dış merdiven,
## düz çatı + su tankı), 3 dükkân binası (geniş vitrin, tente, yatay tabela), 4 dar uzun ev (4-6 kat, yuvarlak çatı)
static func _make(rng: RandomNumberGenerator, i: int) -> Dictionary:
	var arch = [0, 0, 1, 2, 3, 2, 4, 3, 1, 2, 5, 5, 6, 5][i % 14]
	if arch >= 5:
		return _make_round(rng, i, arch == 6)
	var w: float
	var d: float
	var floors: int
	match arch:
		0, 1:
			w = rng.randf_range(13.0, 20.0); d = rng.randf_range(11.0, 14.5); floors = [2, 2, 3, 3, 4][rng.randi() % 5]
		2:
			w = rng.randf_range(20.0, 30.0); d = rng.randf_range(13.0, 15.0); floors = [3, 4, 5, 5][rng.randi() % 4]
		3:
			w = rng.randf_range(15.0, 22.0); d = rng.randf_range(12.0, 15.0); floors = [2, 2, 3, 3][rng.randi() % 4]
		_:
			w = rng.randf_range(11.0, 14.0); d = rng.randf_range(11.0, 14.0); floors = [3, 4, 5][rng.randi() % 3]
	var fh = 3.6
	var h = floors * fh + 0.5
	var walls = MB.new()
	var roof = MB.new()
	var det = MB.new()
	var cols = []  # ek çarpışmalar: [merkez, boyut, x ekseni eğimi (derece)]
	var white = Color(1, 1, 1)
	var apt = arch == 2
	# temel
	det.add("box", Vector3(0, 0.25, 0), Vector3(w + 0.4, 0.5, d + 0.4), STONE)
	# kat kat duvarlar (kasaba evinde üst katlar hafif içeride) + kat kirişleri
	for f in floors:
		var inset = 0.0 if (f == 0 or apt or arch == 4) else 0.25 * mini(f, 2)
		var y0 = 0.5 + f * fh
		walls.add("box", Vector3(0, y0 + fh * 0.5, 0), Vector3(w - inset, fh, d - inset), white)
		det.add("box", Vector3(0, y0 + fh - 0.12, 0), Vector3(w - inset + 0.22, 0.26, d - inset + 0.22), WOOD if not apt else Color(0.62, 0.6, 0.56))
		if not apt:
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					det.add("box", Vector3(sx * (w - inset) * 0.5, y0 + fh * 0.5, sz * (d - inset) * 0.5), Vector3(0.24, fh, 0.24), WOOD)
		# pencereler: ön ve yanlar (apartmanda her katta düzenli sıra)
		var nwin = maxi(1, int((w - inset) / (2.6 if apt else 3.2)))
		for k in nwin:
			var x = -(w - inset) * 0.5 + (k + 0.5) * (w - inset) / nwin
			if f == 0 and absf(x) < (3.0 if arch == 3 else 1.6):
				continue  # kapı / vitrin alanı
			if f == 0 and arch == 3:
				continue  # dükkânın zemin katı vitrin
			_window(det, Vector3(x, y0 + fh * 0.55, -(d - inset) * 0.5), 0.0, rng)
			if apt or rng.randf() < 0.6:
				_window(det, Vector3(x, y0 + fh * 0.55, (d - inset) * 0.5), 180.0, rng)
		for sx in [-1.0, 1.0]:
			var nside = maxi(1, int(d / 4.0)) if (apt or arch == 4) else 1
			for k in nside:
				if apt or arch == 4 or rng.randf() < 0.7:
					var z = -d * 0.5 + (k + 0.5) * d / nside if nside > 1 else rng.randf_range(-d * 0.2, d * 0.2)
					_window(det, Vector3(sx * (w - inset) * 0.5, y0 + fh * 0.55, z), 90.0 * sx, rng)
	# kapı: sürgülü shoji + noren ya da ahşap kapı
	var shop = arch == 3 or (arch != 2 and rng.randf() < 0.3)
	var drng = RandomNumberGenerator.new()  # ayrı tohum: şablonların geri kalanı değişmesin
	drng.seed = 9000 + i
	DoorKit.jp_template(det, -d * 0.5, 0.5, shop, drng)
	var nc = [Color(0.15, 0.25, 0.55), Color(0.75, 0.15, 0.12), Color(0.2, 0.35, 0.25), Color(0.5, 0.2, 0.45), Color(0.85, 0.55, 0.15)][rng.randi() % 5]
	if shop:
		var span = w * 0.8 if arch == 3 else 2.2
		var nk = maxi(3, int(span / 0.72))
		for k in nk:
			det.add("box", Vector3(-span * 0.5 + (k + 0.5) * span / nk, 0.5 + 2.25, -d * 0.5 - 0.22), Vector3(span / nk - 0.06, 0.8, 0.03), nc)
		if arch == 3:
			# geniş vitrin: tezgâh, raflar, yatay tabela (kanji benzeri koyu işaretler)
			det.add("box", Vector3(0, 0.5 + 0.55, -d * 0.5 - 0.35), Vector3(w * 0.7, 1.1, 0.6), WOOD.lightened(0.1))
			for k in 4:
				det.add("box", Vector3(-w * 0.3 + k * w * 0.2, 0.5 + 1.25, -d * 0.5 - 0.35), Vector3(0.7, 0.3, 0.4), [Color(0.85, 0.3, 0.2), Color(0.9, 0.8, 0.3), Color(0.4, 0.65, 0.3), Color(0.92, 0.9, 0.85)][k])
			var sy = 0.5 + fh + 0.3
			det.add("box", Vector3(0, sy, -d * 0.5 - 0.25), Vector3(w * 0.62, 1.1, 0.16), Color(0.94, 0.9, 0.78))
			det.add("box", Vector3(0, sy, -d * 0.5 - 0.2), Vector3(w * 0.66, 1.3, 0.1), nc.darkened(0.2))
			for k in 4:
				det.add("box", Vector3(-w * 0.21 + k * w * 0.14, sy, -d * 0.5 - 0.35), Vector3(0.6, 0.62, 0.03), DARK)
		else:
			det.add("box", Vector3(w * 0.5 - 0.5, 0.5 + 2.6, -d * 0.5 - 0.3), Vector3(0.7, 2.2, 0.12), Color(0.92, 0.88, 0.75))
			for k in 3:
				det.add("box", Vector3(w * 0.5 - 0.5, 0.5 + 3.3 - k * 0.6, -d * 0.5 - 0.38), Vector3(0.36, 0.3, 0.03), DARK)
		for sx in [-1.0, 1.0]:
			det.add("sphere", Vector3(sx * (w * 0.38 if arch == 3 else 1.6), 0.5 + 2.5, -d * 0.5 - 0.45), Vector3(0.45, 0.6, 0.45), Color(0.9, 0.2, 0.15), Vector3.ZERO, 8)
		# ön tente
		det.add("box", Vector3(0, 0.5 + 3.05, -d * 0.5 - 0.8), Vector3(w * (0.9 if arch == 3 else 0.75), 0.12, 1.6), nc.darkened(0.1), Vector3(-14, 0, 0))
	# dikey tabela (apartman / dar ev cephesinde)
	if (apt or arch == 4) and rng.randf() < 0.6:
		var sx2 = [-1.0, 1.0][rng.randi() % 2]
		det.add("box", Vector3(sx2 * (w * 0.5 + 0.35), 0.5 + fh * 1.6, -d * 0.5 + 1.0), Vector3(0.2, fh * 1.6, 1.1), [Color(0.85, 0.2, 0.15), Color(0.95, 0.92, 0.8), Color(0.2, 0.3, 0.55)][rng.randi() % 3])
		for k in 4:
			det.add("box", Vector3(sx2 * (w * 0.5 + 0.47), 0.5 + fh * 2.2 - k * fh * 0.36, -d * 0.5 + 1.0), Vector3(0.03, 0.5, 0.6), DARK)
	# balkonlar: apartmanda her üst katta sürekli balkon, diğerlerinde bazen tek balkon
	var bfloors = range(1, floors) if apt else ([1] if floors >= 2 and rng.randf() < 0.45 else [])
	for bf in bfloors:
		var by = 0.5 + bf * fh
		var bw = w * (0.92 if apt else 0.6)
		det.add("box", Vector3(0, by, -d * 0.5 - 0.7), Vector3(bw, 0.18, 1.4), WOOD if not apt else Color(0.66, 0.64, 0.6))
		var nr = int(bw / 0.9)
		for k in nr + 1:
			det.add("box", Vector3(-bw * 0.5 + k * bw / nr, by + 0.5, -d * 0.5 - 1.35), Vector3(0.08, 0.9, 0.08), WOOD.lightened(0.1) if not apt else Color(0.5, 0.52, 0.55))
		det.add("box", Vector3(0, by + 0.95, -d * 0.5 - 1.35), Vector3(bw + 0.05, 0.1, 0.1), WOOD if not apt else Color(0.45, 0.47, 0.5))
		if apt and rng.randf() < 0.5:   # balkonda çamaşır / saksı
			var lx = rng.randf_range(-bw * 0.35, bw * 0.35)
			det.add("box", Vector3(lx, by + 1.5, -d * 0.5 - 1.0), Vector3(2.4, 0.03, 0.03), DARK)
			for k in 3:
				det.add("box", Vector3(lx - 0.8 + k * 0.8, by + 1.15, -d * 0.5 - 1.0), Vector3(0.6, 0.7, 0.03), CLOTHES[(i + k + bf) % CLOTHES.size()])
		cols.append([Vector3(0, by, -d * 0.5 - 0.7), Vector3(bw, 0.25, 1.4), 0.0])
	# dış merdiven (yan cephe): apartmanda her kata zikzak
	if (apt and rng.randf() < 0.7) or (not apt and floors >= 2 and rng.randf() < 0.3):
		var nfl = (floors - 1) if apt else 1
		for fl in nfl:
			var dir = 1.0 if fl % 2 == 0 else -1.0
			for k in 10:
				det.add("box", Vector3(w * 0.5 + 0.7, 0.5 + fl * fh + k * fh / 10.0, dir * (-d * 0.3 + k * d * 0.06)), Vector3(1.3, 0.16, 0.7), DARK.lightened(0.15))
			var run = d * 0.54; var rise = fh * 0.9
			var ang = rad_to_deg(atan2(rise, run))
			# ince tırabzan: eğimli küpeşte + üç dikme (kalın levha gibi durmasın)
			det.add("box", Vector3(w * 0.5 + 1.33, 0.5 + fl * fh + rise * 0.5 + 0.95, -d * 0.03 * dir), Vector3(0.07, 0.07, sqrt(run * run + rise * rise)), DARK, Vector3(-ang * dir, 0, 0))
			for j in 3:
				var tz = -0.3 + j * 0.27
				det.add("box", Vector3(w * 0.5 + 1.33, 0.5 + fl * fh + (tz + 0.3) / 0.54 * rise + 0.5, dir * d * tz), Vector3(0.06, 0.95, 0.06), DARK)
			cols.append([Vector3(w * 0.5 + 0.7, 0.5 + fl * fh + rise * 0.5, -d * 0.03 * dir), Vector3(1.3, 0.25, sqrt(run * run + rise * rise)), -ang * dir])
			# merdivenin çıktığı yer: sahanlık + yan duvarda o katın kapısı (merdiven bir yere bağlansın)
			var ly = 0.5 + (fl + 1) * fh
			var lz = dir * (d * 0.3 + 0.8)
			det.add("box", Vector3(w * 0.5 + 0.75, ly - 0.09, lz), Vector3(1.5, 0.18, 2.2), DARK.lightened(0.2))
			det.add("box", Vector3(w * 0.5 + 1.45, ly + 0.5, lz + dir * 0.6), Vector3(0.06, 1.0, 1.0), DARK)
			det.add("box", Vector3(w * 0.5 + 0.06, ly + 1.05, dir * (d * 0.3 + 1.1)), Vector3(0.1, 2.15, 1.05), WOOD.darkened(0.15))   # kapı
			det.add("box", Vector3(w * 0.5 + 0.04, ly + 1.05, dir * (d * 0.3 + 1.1)), Vector3(0.1, 2.35, 1.3), WOOD)                  # kasa
			det.add("box", Vector3(w * 0.5 + 0.13, ly + 1.0, dir * (d * 0.3 + 1.1) + 0.3), Vector3(0.05, 0.25, 0.05), Color(0.8, 0.65, 0.3))
			det.add("box", Vector3(w * 0.5 + 0.5, ly + 2.45, dir * (d * 0.3 + 1.1)), Vector3(1.0, 0.08, 1.6), Color(0.3, 0.26, 0.24), Vector3(0, 0, -12))   # kapı saçağı
			cols.append([Vector3(w * 0.5 + 0.75, ly - 0.09, lz), Vector3(1.5, 0.2, 2.2), 0.0])
	# boru
	if apt or rng.randf() < 0.35:
		det.add("cyl", Vector3(-w * 0.5 - 0.15, h * 0.5, d * 0.25), Vector3(0.22, h, 0.22), Color(0.55, 0.57, 0.6), Vector3.ZERO, 6)
	# klima üniteleri: yan / arka duvarlarda rastgele (kasaba evi ve apartmanlarda)
	if rng.randf() < 0.55:
		for k in rng.randi_range(1, 3 if apt else 2):
			var fl = rng.randi_range(0, floors - 1)
			var cy = 0.5 + fl * fh + rng.randf_range(0.6, 1.1)
			var side = rng.randi() % 3   # 0 sol, 1 sağ, 2 arka
			var p: Vector3
			var yw = 0.0
			if side == 2:
				p = Vector3(rng.randf_range(-w * 0.35, w * 0.35), cy, d * 0.5 + 0.3)
			else:
				var sx = -1.0 if side == 0 else 1.0
				p = Vector3(sx * (w * 0.5 + 0.3), cy, rng.randf_range(-d * 0.3, d * 0.3))
				yw = 90.0
			var r = Basis(Vector3.UP, deg_to_rad(yw))
			det.add_xf("box", Transform3D(r * Basis.from_scale(Vector3(0.95, 0.65, 0.55)), p), Color(0.86, 0.87, 0.85))
			var fwd = r * Vector3(0, 0, 1) * (0.28 if side == 2 else 1.0)
			if side != 2:
				fwd = Vector3(signf(p.x) * 0.28, 0, 0)
			det.add_xf("cyl", Transform3D(r * Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(0.46, 0.04, 0.46)), p + fwd + (r * Vector3(0.15, 0, 0))), Color(0.32, 0.33, 0.35), 12)   # fan ızgarası
			det.add_xf("box", Transform3D(r * Basis.from_scale(Vector3(0.06, 0.06, 0.45)), p + Vector3(0, -0.3, 0) + fwd * 0.5), Color(0.5, 0.5, 0.52))   # ayak
	# kapı önü: her evde aynı üç saksı yerine evine göre farklı küçük ayrıntılar (bazen hiç)
	_front_decor(det, w, d, arch, rng)
	# çatı
	var top_w = w - (0.0 if (apt or arch == 4) else 0.25 * mini(floors - 1, 2))
	var top_d = d - (0.0 if (apt or arch == 4) else 0.25 * mini(floors - 1, 2))
	var rtype = 2 if apt else (1 if arch == 4 else rng.randi() % 3)
	var roof_top = h
	var rcm = MB.new()   # yalnız ana çatı: çarpışma şekli (içinden geçilmesin, eğiminde yürünsün)
	match rtype:
		0:  # Japon beşik çatı, geniş saçak
			var rh = 2.4 + top_d * 0.12
			roof.add("prism", Vector3(0, h + rh * 0.5, 0), Vector3(top_w + 2.0, rh, top_d + 2.0), white)
			rcm.add("prism", Vector3(0, h + rh * 0.5, 0), Vector3(top_w + 2.0, rh, top_d + 2.0), white)
			det.add("box", Vector3(0, h + 0.06, 0), Vector3(top_w + 2.2, 0.16, top_d + 2.2), DARK)
			det.add("box", Vector3(0, h + rh + 0.12, 0), Vector3(0.45, 0.32, top_d + 2.2), DARK)
			for sz in [-1.0, 1.0]:  # mahya uçları
				det.add("box", Vector3(0, h + rh + 0.3, sz * (top_d * 0.5 + 1.0)), Vector3(0.6, 0.5, 0.4), DARK)
			roof_top = h + rh
		1:  # Konoha yuvarlak çatı (yarım silindir)
			var rise = clampf(top_d * 0.16, 1.1, 1.9)
			roof.add_xf("halfcyl", Transform3D(Basis.from_scale(Vector3(top_w + 0.8, rise * 2.0, top_d + 1.2)), Vector3(0, h + 0.1, 0)), white, 16)
			rcm.add_xf("halfcyl", Transform3D(Basis.from_scale(Vector3(top_w + 0.8, rise * 2.0, top_d + 1.2)), Vector3(0, h + 0.1, 0)), white, 10)
			det.add("box", Vector3(0, h + 0.05, 0), Vector3(top_w + 1.0, 0.2, top_d + 1.3), DARK)  # saçak bandı
			roof_top = h + 0.1 + rise
		2:  # düz çatı: korkuluk + su tankı (apartmanda bazen iki tank + anten)
			roof.add("box", Vector3(0, h + 0.2, 0), Vector3(top_w + 0.6, 0.4, top_d + 0.6), white)
			rcm.add("box", Vector3(0, h + 0.2, 0), Vector3(top_w + 0.6, 0.4, top_d + 0.6), white)
			for sx in [-1.0, 1.0]:
				det.add("box", Vector3(sx * (top_w * 0.5 + 0.25), h + 0.75, 0), Vector3(0.15, 0.7, top_d + 0.6), WOOD.lightened(0.2))
				cols.append([Vector3(sx * (top_w * 0.5 + 0.25), h + 0.75, 0), Vector3(0.2, 0.75, top_d + 0.6), 0.0])   # korkuluk
			for sz in [-1.0, 1.0]:
				det.add("box", Vector3(0, h + 0.75, sz * (top_d * 0.5 + 0.25)), Vector3(top_w + 0.6, 0.7, 0.15), WOOD.lightened(0.2))
				cols.append([Vector3(0, h + 0.75, sz * (top_d * 0.5 + 0.25)), Vector3(top_w + 0.6, 0.75, 0.2), 0.0])
			var ntank = 2 if (apt and w > 19.0) else 1
			for tk in ntank:
				var tx = rng.randf_range(-top_w * 0.25, top_w * 0.25) if ntank == 1 else (tk - 0.5) * top_w * 0.5
				for sx in [-1.0, 1.0]:
					for sz in [-1.0, 1.0]:
						det.add("box", Vector3(tx + sx * 0.8, h + 1.0, sz * 0.8), Vector3(0.15, 1.6, 0.15), DARK)
				det.add_grad("cyl", Vector3(tx, h + 2.6, 0), Vector3(2.6, 2.2, 2.6), Color(0.7, 0.74, 0.78), Color(0.5, 0.53, 0.58), Vector3.ZERO, 14)
				cols.append([Vector3(tx, h + 2.2, 0), Vector3(2.7, 3.6, 2.7), 0.0])   # su tankı + ayakları katı (içinden geçilmesin)
				det.add("cyl", Vector3(tx, h + 3.8, 0), Vector3(2.8, 0.25, 2.8), Color(0.45, 0.47, 0.5), Vector3.ZERO, 14)
			if apt and rng.randf() < 0.6:
				det.add("cyl", Vector3(top_w * 0.4, h + 2.4, top_d * 0.3), Vector3(0.08, 4.0, 0.08), DARK, Vector3.ZERO, 5)
				det.add("box", Vector3(top_w * 0.4, h + 3.9, top_d * 0.3), Vector3(1.6, 0.06, 0.06), DARK)
			roof_top = h + 0.4
	# yan ek bina
	var annex_w = 0.0
	if not apt and arch != 4 and rng.randf() < 0.3:
		var aw = w * 0.4; var ad = d * 0.55; var ah = 3.2
		annex_w = aw
		walls.add("box", Vector3(-w * 0.5 - aw * 0.5 + 0.1, 0.5 + ah * 0.5, d * 0.1), Vector3(aw, ah, ad), white)
		roof.add("prism", Vector3(-w * 0.5 - aw * 0.5 + 0.1, 0.5 + ah + 0.6, d * 0.1), Vector3(aw + 1.0, 1.2, ad + 1.0), white)
		_window(det, Vector3(-w * 0.5 - aw * 0.5, 0.5 + ah * 0.55, d * 0.1 - ad * 0.5), 0.0, rng)
		cols.append([Vector3(-w * 0.5 - aw * 0.5 + 0.1, (0.5 + ah + 0.6) * 0.5, d * 0.1), Vector3(aw, 0.5 + ah + 0.6, ad), 0.0])
	return {"walls": walls.build(), "roof": roof.build(), "detail": det.build(), "w": w + annex_w * 2.0, "d": d, "h": h, "roof_top": roof_top, "cols": cols,
		"annex_w": annex_w * 2.0, "arch": arch,   # yerleşim ayak izi tek yandaki ek binayı da simetrik kapsasın
		"roof_shape": _hull(rcm)}


## Konoha simgesi: silindir kule (kat kat yuvarlak, turuncu çizgili kiremit çatı, üstte küçük ikinci kat + tepe) ya da
## kubbeli yapı (yuvarlak gövde, büyük kubbe). Yuvarlak pencere sıraları, kat bantları, giriş saçağı.
static func _make_round(rng: RandomNumberGenerator, i: int, dome: bool) -> Dictionary:
	var D = rng.randf_range(11.0, 15.0)
	var r = D * 0.5
	var floors = [2, 3, 3, 4, 5][rng.randi() % 5] if not dome else [1, 2, 2][rng.randi() % 3]
	var fh = 3.6
	var h = floors * fh + 0.5
	var walls = MB.new()
	var roof = MB.new()
	var det = MB.new()
	var white = Color(1, 1, 1)
	det.add("cyl", Vector3(0, 0.25, 0), Vector3(D + 0.6, 0.5, D + 0.6), STONE, Vector3.ZERO, 20)
	walls.add("cyl", Vector3(0, 0.5 + (h - 0.5) * 0.5, 0), Vector3(D, h - 0.5, D), white, Vector3.ZERO, 24)
	for f in floors:
		var y0 = 0.5 + f * fh
		det.add("cyl", Vector3(0, y0 + fh - 0.1, 0), Vector3(D + 0.3, 0.28, D + 0.3), WOOD, Vector3.ZERO, 24)   # kat bandı
		var nw = maxi(5, int(PI * D / 3.0))
		for k in nw:
			if f == 0 and k == 0:
				continue   # giriş
			var a = TAU * k / nw
			var p = Vector3(sin(a) * -r, y0 + fh * 0.55, cos(a) * -r)
			_window(det, p, rad_to_deg(a), rng)
	# giriş: ön (-z) kapı + saçak
	var drng = RandomNumberGenerator.new()
	drng.seed = 9000 + i
	DoorKit.jp_template(det, -r, 0.5, rng.randf() < 0.3, drng)
	det.add("box", Vector3(0, 0.5 + 3.05, -r - 0.8), Vector3(4.0, 0.12, 1.8), Color(0.3, 0.26, 0.24), Vector3(-14, 0, 0))
	var roof_top: float
	var rcm = MB.new()
	if dome:
		roof.add("sphere", Vector3(0, h, 0), Vector3(D + 0.6, D * 0.85, D + 0.6), white, Vector3.ZERO, 20)
		rcm.add("hemi", Vector3(0, h, 0), Vector3(D + 0.6, D * 0.85, D + 0.6), white, Vector3.ZERO, 12)
		det.add("cyl", Vector3(0, h + 0.05, 0), Vector3(D + 0.9, 0.3, D + 0.9), DARK, Vector3.ZERO, 24)
		det.add("cyl", Vector3(0, h + D * 0.42 + 0.4, 0), Vector3(0.25, 1.2, 0.25), DARK, Vector3.ZERO, 6)
		det.add("sphere", Vector3(0, h + D * 0.42 + 1.1, 0), Vector3(0.5, 0.5, 0.5), Color(0.9, 0.75, 0.3), Vector3.ZERO, 8)
		roof_top = h + D * 0.42
	else:
		# geniş saçaklı alçak koni çatı + çizgiler, üstte küçük ikinci gövde + ikinci koni + tepe
		var rh = D * 0.22
		roof.add("cone", Vector3(0, h + rh * 0.5, 0), Vector3(D + 2.6, rh, D + 2.6), white, Vector3.ZERO, 24)
		rcm.add("cone", Vector3(0, h + rh * 0.5, 0), Vector3(D + 2.6, rh, D + 2.6), white, Vector3.ZERO, 12)
		for k in 3:   # kiremit sıraları (koyu halkalar)
			var t = (k + 1) / 4.0
			var rr = (D + 2.6) * (1.0 - t) * 0.5 + 0.06
			det.add("torus", Vector3(0, h + rh * t, 0), Vector3(rr * 2.0, rr * 0.08, rr * 2.0), Color(0.45, 0.25, 0.12), Vector3.ZERO, 24)
		det.add("cyl", Vector3(0, h + 0.05, 0), Vector3(D + 2.7, 0.22, D + 2.7), DARK, Vector3.ZERO, 24)
		var D2 = D * 0.5
		walls.add("cyl", Vector3(0, h + rh * 0.6 + 1.4, 0), Vector3(D2, 2.8, D2), white, Vector3.ZERO, 16)
		for k in 6:
			var a = TAU * k / 6.0
			_window(det, Vector3(sin(a) * -D2 * 0.5, h + rh * 0.6 + 1.5, cos(a) * -D2 * 0.5), rad_to_deg(a), rng)
		var y2 = h + rh * 0.6 + 2.8
		roof.add("cone", Vector3(0, y2 + D2 * 0.2, 0), Vector3(D2 + 1.6, D2 * 0.4, D2 + 1.6), white, Vector3.ZERO, 18)
		det.add("cyl", Vector3(0, y2 + D2 * 0.4 + 0.5, 0), Vector3(0.2, 1.0, 0.2), DARK, Vector3.ZERO, 6)
		roof_top = y2 + D2 * 0.4
	var cyl = CylinderShape3D.new()
	cyl.radius = r
	cyl.height = h - 0.5
	var extra: Array = []
	if not dome:   # üst küçük gövde + ikinci koni ayrı şekil (koninin üstünde)
		var c2 = MB.new()
		c2.add("cyl", Vector3(0, h + D * 0.22 * 0.6 + 1.4, 0), Vector3(D * 0.5, 2.8, D * 0.5), white, Vector3.ZERO, 10)
		c2.add("cone", Vector3(0, h + D * 0.22 * 0.6 + 2.8 + D * 0.1, 0), Vector3(D * 0.5 + 1.6, D * 0.2, D * 0.5 + 1.6), white, Vector3.ZERO, 10)
		extra.append(_hull(c2))
	return {"walls": walls.build(), "roof": roof.build(), "detail": det.build(), "w": D, "d": D, "h": h, "roof_top": roof_top, "cols": [],
		"roof_shape": _hull(rcm), "body_shape": cyl, "extra_shapes": extra, "arch": 6 if dome else 5}


## Hızlı dışbükey çarpışma: köşe noktaları doğrudan (create_convex_shape'in temizleme/sadeleştirmesi 70 şablonda ~3 sn sürüyordu)
static func _hull(mb: MB) -> ConvexPolygonShape3D:
	var seen := {}
	var pts := PackedVector3Array()
	for v in mb.verts:
		var k = Vector3i(roundi(v.x * 20.0), roundi(v.y * 20.0), roundi(v.z * 20.0))
		if not seen.has(k):
			seen[k] = true
			pts.append(v)
	var sh = ConvexPolygonShape3D.new()
	sh.points = pts
	return sh


const CLOTHES := [Color(0.85, 0.3, 0.25), Color(0.95, 0.95, 0.92), Color(0.3, 0.45, 0.75), Color(0.95, 0.8, 0.3), Color(0.4, 0.62, 0.4)]


## Kapı önü ayrıntısı: kapı alanını (|x| < 1.8) boş bırakarak cephe boyunca 0-2 farklı öge
static func _front_decor(det: MB, w: float, d: float, arch: int, rng: RandomNumberGenerator) -> void:
	var n = [0, 1, 1, 2][rng.randi() % 4]
	var used: Array = []
	for k in n:
		var kind = rng.randi() % 8
		if used.has(kind):
			continue
		used.append(kind)
		var sx = [-1.0, 1.0][rng.randi() % 2]
		var x = sx * rng.randf_range(2.4, maxf(2.6, w * 0.5 - 1.0))
		var z = -d * 0.5 - rng.randf_range(0.5, 0.9)
		var y = 0.5
		match kind:
			0:   # tek büyük saksı bitkisi
				var pc = [Color(0.6, 0.38, 0.25), Color(0.35, 0.4, 0.5), Color(0.75, 0.7, 0.62)][rng.randi() % 3]
				det.add_grad("cyl", Vector3(x, y + 0.3, z), Vector3(0.6, 0.6, 0.6), pc, pc.darkened(0.3), Vector3.ZERO, 10)
				det.add_grad("sphere", Vector3(x, y + 0.95, z), Vector3(0.9, 0.9, 0.9), Color(0.4, 0.66, 0.3), Color(0.18, 0.38, 0.14), Vector3.ZERO, 8)
			1:   # bonsai sehpası
				det.add("box", Vector3(x, y + 0.45, z), Vector3(1.2, 0.08, 0.5), WOOD)
				for lx in [-0.5, 0.5]:
					det.add("box", Vector3(x + lx, y + 0.22, z), Vector3(0.08, 0.44, 0.44), WOOD)
				det.add("box", Vector3(x, y + 0.56, z), Vector3(0.5, 0.14, 0.3), Color(0.45, 0.42, 0.5))
				det.add("cyl", Vector3(x, y + 0.78, z), Vector3(0.08, 0.35, 0.08), WOOD.darkened(0.2), Vector3(0, 0, 18), 5)
				det.add_grad("sphere", Vector3(x + 0.12, y + 0.98, z), Vector3(0.55, 0.28, 0.4), Color(0.35, 0.6, 0.28), Color(0.15, 0.32, 0.12), Vector3.ZERO, 7)
			2:   # bank
				det.add("box", Vector3(x, y + 0.45, z - 0.1), Vector3(1.8, 0.1, 0.5), WOOD.lightened(0.1))
				for lx in [-0.75, 0.75]:
					det.add("box", Vector3(x + lx, y + 0.22, z - 0.1), Vector3(0.1, 0.44, 0.45), WOOD.darkened(0.2))
			3:   # fıçı + şemsiye
				det.add_grad("cyl", Vector3(x, y + 0.45, z), Vector3(0.65, 0.9, 0.65), WOOD.lightened(0.2), WOOD, Vector3.ZERO, 10)
				det.add("cyl", Vector3(x + 0.1, y + 1.15, z), Vector3(0.05, 0.9, 0.05), DARK, Vector3(0, 0, 12), 5)
				det.add("cone", Vector3(x + 0.18, y + 1.25, z), Vector3(0.22, 0.9, 0.22), Color(0.85, 0.3, 0.2), Vector3(0, 0, 12), 8)
			4:   # sandık yığını
				det.add("box", Vector3(x, y + 0.35, z), Vector3(0.7, 0.7, 0.7), WOOD.lightened(0.15))
				det.add("box", Vector3(x + 0.75, y + 0.3, z + 0.05), Vector3(0.6, 0.6, 0.6), WOOD)
				det.add("box", Vector3(x + 0.3, y + 0.95, z), Vector3(0.55, 0.5, 0.55), WOOD.lightened(0.05), Vector3(0, 15, 0))
			5:   # bisiklet (duvara dayalı)
				for wx in [-0.55, 0.55]:
					det.add("torus", Vector3(x + wx, y + 0.35, -d * 0.5 - 0.3), Vector3(0.7, 0.7, 0.7), DARK, Vector3(90, 0, 0), 12)
				det.add("box", Vector3(x, y + 0.55, -d * 0.5 - 0.3), Vector3(1.1, 0.06, 0.05), Color(0.7, 0.15, 0.12), Vector3(0, 0, -8))
				det.add("box", Vector3(x + 0.45, y + 0.8, -d * 0.5 - 0.3), Vector3(0.05, 0.5, 0.05), DARK)
				det.add("box", Vector3(x + 0.45, y + 1.05, -d * 0.5 - 0.3), Vector3(0.05, 0.05, 0.5), DARK)
			6:   # taş fener (küçük)
				det.add("box", Vector3(x, y + 0.1, z), Vector3(0.6, 0.2, 0.6), STONE)
				det.add("cyl", Vector3(x, y + 0.5, z), Vector3(0.18, 0.7, 0.18), STONE, Vector3.ZERO, 6)
				det.add("box", Vector3(x, y + 1.0, z), Vector3(0.5, 0.4, 0.5), STONE.lightened(0.1))
				det.add("box", Vector3(x, y + 1.0, z - 0.26), Vector3(0.25, 0.22, 0.02), Color(1.0, 0.85, 0.5))
				det.add("cone", Vector3(x, y + 1.35, z), Vector3(0.8, 0.35, 0.8), STONE.darkened(0.1), Vector3.ZERO, 6)
			7:   # pencere altı çiçeklik (yalnız bir tane, karışık renkli çiçekler)
				det.add("box", Vector3(x, y + 0.3, -d * 0.5 - 0.3), Vector3(1.6, 0.45, 0.4), WOOD)
				for f in 5:
					var fc = [Color(0.95, 0.4, 0.5), Color(1.0, 0.85, 0.3), Color(0.95, 0.95, 0.95), Color(0.7, 0.45, 0.9)][rng.randi() % 4]
					det.add("sphere", Vector3(x - 0.6 + f * 0.3, y + 0.62, -d * 0.5 - 0.3), Vector3(0.2, 0.18, 0.2), fc, Vector3.ZERO, 6)
				det.add_grad("box", Vector3(x, y + 0.55, -d * 0.5 - 0.3), Vector3(1.5, 0.12, 0.34), Color(0.4, 0.66, 0.3), Color(0.2, 0.4, 0.15))


## Köşeli (yuvarlak olmayan) dükkân / kasaba evi şablonu: genişliği en çok mw, derinliği en çok md (özel dükkânlar için)
static func rect_template(rng: RandomNumberGenerator, mw: float, md: float) -> int:
	ensure()
	var best = -1
	var fit: Array = []
	for k in templates.size():
		var t: Dictionary = templates[k]
		if int(t.get("arch", 0)) in [0, 1, 3] and float(t.get("annex_w", 0.0)) == 0.0:
			if float(t["w"]) <= mw and float(t["d"]) <= md:
				fit.append(k)
			if best < 0 or float(t["w"]) < float(templates[best]["w"]):
				best = k
	return fit[rng.randi() % fit.size()] if not fit.is_empty() else best


static func _window(b: MB, p: Vector3, yaw: float, rng: RandomNumberGenerator) -> void:
	var r = Basis(Vector3.UP, deg_to_rad(yaw))
	var fwd = r * Vector3(0, 0, -1)
	var right = r * Vector3(1, 0, 0)
	var shoji = rng.randf() < 0.5
	b.add_xf("box", Transform3D(r * Basis.from_scale(Vector3(1.5, 1.35, 0.12)), p + fwd * 0.05), WOOD)
	b.add_xf("box", Transform3D(r * Basis.from_scale(Vector3(1.3, 1.15, 0.06)), p + fwd * 0.09), SHOJI if shoji else GLASS)
	b.add_xf("box", Transform3D(r * Basis.from_scale(Vector3(0.05, 1.15, 0.04)), p + fwd * 0.12), DARK)
	b.add_xf("box", Transform3D(r * Basis.from_scale(Vector3(1.3, 0.05, 0.04)), p + fwd * 0.12), DARK)
	if shoji:
		for k in [-1.0, 1.0]:
			b.add_xf("box", Transform3D(r * Basis.from_scale(Vector3(1.3, 0.03, 0.04)), p + fwd * 0.12 + Vector3(0, k * 0.3, 0)), DARK)
	if rng.randf() < 0.35:  # küçük saçak
		b.add_xf("box", Transform3D(Basis(right, deg_to_rad(18)) * r * Basis.from_scale(Vector3(1.8, 0.1, 0.7)), p + Vector3(0, 0.85, 0) + fwd * 0.35), Color(0.35, 0.3, 0.28))
	elif rng.randf() < 0.3:  # kepenkler
		for sx in [-1.0, 1.0]:
			b.add_xf("box", Transform3D(r * Basis.from_scale(Vector3(0.35, 1.3, 0.06)), p + right * sx * 0.95 + fwd * 0.08), WOOD.lightened(0.1))


## Bir köy için yerleştirici: evleri toplar, sonunda MultiMesh'leri ve çarpışmaları kurar
class Placer:
	var parent: Node3D
	var key := ""
	var walls := {}   # şablon -> [[xform, color]]
	var roofs := {}
	var dets := {}
	var body: StaticBody3D
	var view := 1500.0

	func _init(p: Node3D, k: String) -> void:
		parent = p
		key = k
		HouseKit.ensure()
		body = StaticBody3D.new()
		body.collision_layer = 1   # sahneye finish()'te eklenir (bkz. Builder._init)

	## pos: Godot dünya (taban merkezi), yaw: derece (Builder yerel yaw), ön cephe sokağa
	var pack_items := {}   # mesh -> [Transform3D]
	var recs: Array = []   # WorldDamage kayıtları (yanma / yıkılma)
	var pack_chance := 0.0  # 0..1: bu oranda ev hazır modelden (renkli Japon kasaba evi)
	var force_ti := -1      # >= 0: bu şablonu kullan (hazır model yok)

	func add(pos: Vector3, yaw: float, wall_col: Color, roof_col: Color, rng: RandomNumberGenerator, scale := 1.0, max_w := 1e9, max_d := 1e9) -> Dictionary:
		if force_ti < 0 and pack_chance > 0.0 and rng.randf() < pack_chance:
			var hs: Array = AssetLib.town_houses()
			if not hs.is_empty():
				var e: Array = hs[rng.randi() % hs.size()]
				var sz: Vector3 = e[1]
				var xf2 = Transform3D(Basis(Vector3.UP, deg_to_rad(-yaw)).scaled(Vector3.ONE * scale), pos)
				if not pack_items.has(e[0]):
					pack_items[e[0]] = []
				pack_items[e[0]].append(xf2)
				var cs2 = CollisionShape3D.new()
				var sh2 = BoxShape3D.new()
				sh2.size = Vector3(sz.x * 0.9, sz.y, sz.z * 0.9) * scale
				cs2.shape = sh2
				cs2.transform = Transform3D(xf2.basis.orthonormalized(), pos + Vector3(0, sz.y * 0.5 * scale, 0))
				body.add_child(cs2)
				if key != "" and not key.begins_with("yolkenari"):
					if not Builder.roof_points.has(key):
						Builder.roof_points[key] = []
					Builder.roof_points[key].append(pos + Vector3(0, sz.y * scale, 0))
				return {"w": sz.x, "d": sz.z, "h": sz.y * 0.8, "roof_top": sz.y}
		# arsaya sığan şablonlardan biri (sığan yoksa en küçüğü)
		var fit: Array = []
		var small = 0
		for k in HouseKit.templates.size():
			var tk: Dictionary = HouseKit.templates[k]
			if float(tk["w"]) * scale <= max_w and float(tk["d"]) * scale <= max_d:
				fit.append(k)
			if float(tk["w"]) < float(HouseKit.templates[small]["w"]):
				small = k
		var ti = fit[rng.randi() % fit.size()] if not fit.is_empty() else small
		if force_ti >= 0:
			ti = force_ti
			force_ti = -1
		var t: Dictionary = HouseKit.templates[ti]
		var xf = Transform3D(Basis(Vector3.UP, deg_to_rad(-yaw) + PI).scaled(Vector3.ONE * scale), pos)
		var rec = {"pos": pos, "basis": xf.basis, "ti": ti, "scale": scale, "wall": wall_col, "roof": roof_col, "body": body, "mm": [], "shapes": []}
		recs.append(rec)
		for pair in [[walls, wall_col], [roofs, roof_col], [dets, Color(1, 1, 1)]]:
			var dict: Dictionary = pair[0]
			if not dict.has(ti):
				dict[ti] = []
			dict[ti].append([xf, pair[1], rec])
		# çarpışma: gövde + çatı
		var cs = CollisionShape3D.new()
		if t.has("body_shape"):
			cs.shape = t["body_shape"]   # yuvarlak gövde: silindir (köşesiz görünmez duvar olmasın)
		else:
			var sh = BoxShape3D.new()
			var aw = float(t["w"]) - float(t.get("annex_w", 0.0))
			sh.size = Vector3(aw, t["h"], t["d"]) * scale
			cs.shape = sh
		cs.transform = Transform3D(xf.basis.orthonormalized(), pos + Vector3(0, t["h"] * 0.5 * scale, 0))
		body.add_child(cs)
		# çatı: şablonun ana çatısının kendi şekli (beşik / yuvarlak / koni / kubbe) -> eğiminde yürünür, içinden geçilmez
		var rc = CollisionShape3D.new()
		if t.has("roof_shape") and scale == 1.0:
			rc.shape = t["roof_shape"]
			rc.transform = Transform3D(xf.basis.orthonormalized(), pos)
		else:
			var rs = BoxShape3D.new()
			rs.size = Vector3(t["w"] + 0.6, maxf(0.4, (t["roof_top"] - t["h"]) * 0.6), t["d"] * 0.7) * scale
			rc.shape = rs
			rc.transform = Transform3D(xf.basis.orthonormalized(), pos + Vector3(0, (t["h"] + (t["roof_top"] - t["h"]) * 0.3) * scale, 0))
		body.add_child(rc)
		rec["shapes"] = [cs, rc]
		for es2 in t.get("extra_shapes", []):
			var xc = CollisionShape3D.new()
			xc.shape = es2
			xc.transform = Transform3D(xf.basis.orthonormalized(), pos)
			body.add_child(xc)
			rec["shapes"].append(xc)
		for c in t.get("cols", []):  # yan ek bina, balkon, dış merdiven
			var ec = CollisionShape3D.new()
			var es = BoxShape3D.new()
			es.size = c[1] * scale
			ec.shape = es
			ec.transform = Transform3D(xf.basis.orthonormalized() * Basis(Vector3.RIGHT, deg_to_rad(c[2])), pos + xf.basis * c[0])
			body.add_child(ec)
			rec["shapes"].append(ec)
		if key != "" and not key.begins_with("yolkenari"):   # iş parçacığında kurulan yol kenarı evleri paylaşılan sözlüğe yazmaz
			if not Builder.roof_points.has(key):
				Builder.roof_points[key] = []
			Builder.roof_points[key].append(pos + Vector3(0, t["roof_top"] * scale, 0))
		return t

	func finish() -> void:
		if is_instance_valid(body) and body.get_parent() == null and is_instance_valid(parent):
			parent.add_child(body)
		for pm in pack_items:
			var xfs: Array = pack_items[pm]
			var cells2 = {}
			for x in xfs:
				var c2 = Vector2i(int(floor(x.origin.x / 160.0)), int(floor(x.origin.z / 160.0)))
				if not cells2.has(c2):
					cells2[c2] = []
				cells2[c2].append(x)
			# yakın: tam model, orta: %12, uzak: %3 (hazır evler çok detaylı)
			var lv = [[pm, 0.0, 110.0], [AssetLib.lod(pm, 0.12), 110.0, 450.0], [AssetLib.lod(pm, 0.03), 450.0, 1500.0]]
			for c2 in cells2:
				var arr: Array = cells2[c2]
				for l in lv:
					var mm = MultiMesh.new()
					mm.transform_format = MultiMesh.TRANSFORM_3D
					mm.use_colors = true
					mm.mesh = l[0]
					mm.instance_count = arr.size()
					for i in arr.size():
						mm.set_instance_transform(i, arr[i])
						mm.set_instance_color(i, Color.WHITE)
					var mmi = MultiMeshInstance3D.new()
					mmi.layers = 2
					mmi.multimesh = mm
					mmi.visibility_range_begin = l[1] * float(Game.settings["view"])
					mmi.visibility_range_begin_margin = 15.0 if l[1] > 0.0 else 0.0
					mmi.visibility_range_end = l[2] * float(Game.settings["view"])
					mmi.visibility_range_end_margin = 30.0
					mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
					if l[1] > 0.0:
						mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					parent.add_child(mmi)
		pack_items.clear()
		for pair in [[walls, "walls"], [roofs, "roof"], [dets, "detail"]]:
			var dict: Dictionary = pair[0]
			for ti in dict:
				var items: Array = dict[ti]
				# 160 m'lik hücrelere böl (görünürlük kırpma için)
				var cells = {}
				for it in items:
					var c = Vector2i(int(floor(it[0].origin.x / 160.0)), int(floor(it[0].origin.z / 160.0)))
					if not cells.has(c):
						cells[c] = []
					cells[c].append(it)
				for c in cells:
					var arr: Array = cells[c]
					var mm = MultiMesh.new()
					mm.transform_format = MultiMesh.TRANSFORM_3D
					mm.use_colors = true
					mm.mesh = HouseKit.templates[ti][pair[1]]
					mm.instance_count = arr.size()
					for i in arr.size():
						mm.set_instance_transform(i, arr[i][0])
						mm.set_instance_color(i, arr[i][1])
						arr[i][2]["mm"].append([mm, i, pair[1], arr[i][0]])
					var mmi = MultiMeshInstance3D.new()
					mmi.layers = 2
					mmi.multimesh = mm
					mmi.material_override = Props.roof_toon() if pair[1] == "roof" else Props.toon()
					mmi.visibility_range_end = view * float(Game.settings["view"])
					mmi.visibility_range_end_margin = 60.0
					mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
					parent.add_child(mmi)
		if not recs.is_empty():
			WorldDamage.register_houses(recs)
			recs = []
