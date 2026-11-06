class_name AcademyGrounds
extends RefCounted
## Ninja Akademisi bahçesi: alçak taş duvar + kapı, taş döşeli yol, fenerler, çit/ağaç sıraları,
## toprak antrenman alanı (hedefler, kütükler, kuklalar), göletli bahçe, salıncak ağacı, oyun parkı,
## bayrak direği, çan, kapalı sundurma, yükseltilmiş çiçek tarhları (yalnız yeşil/beyaz).
## Hepsi prosedürel (hazır ağaç modeli yok); her şey zemine oturur ve çarpışır.

const VL = preload("res://scripts/world/village_life.gd")
const WOOD := Color(0.45, 0.31, 0.19)
const WOOD_D := Color(0.3, 0.2, 0.13)
const STONE := Color(0.63, 0.6, 0.55)
const STONE_D := Color(0.48, 0.46, 0.43)
const DIRT := Color(0.66, 0.55, 0.4)

static var _veg := {}


static func _vm(t: int) -> Mesh:
	if not _veg.has(t):
		_veg[t] = Props.vegetation_mesh(t)
	return _veg[t]


## b: köy Builder'ı. cx: bina orta x'i, front_n: bina ön cephesi (n). Avlu güneye (n azalan) uzanır.
## opts: vid, climate (green|desert|dry), flag (Color), kanji, roof (Color), bw (bina genişliği), decor (Node3D), scale
static func dress(b: Builder, cx: float, front_n: float, half_w: float, depth: float, rng: RandomNumberGenerator, opts := {}) -> void:
	var g = func(x: float, n: float) -> float:
		var wp = b.w(Vector3(x, 0, n))
		return Game.terrain_height(wp.x, wp.z) - b.origin.y - b.yoff
	var vid: String = opts.get("vid", "")
	var climate: String = opts.get("climate", "green")
	var flag: Color = opts.get("flag", Color(0.2, 0.42, 0.26))
	var roof_c: Color = opts.get("roof", Color(0.72, 0.18, 0.15))
	var bw: float = opts.get("bw", half_w)
	var s: float = opts.get("scale", 1.0)  # küçük köy yerleşkelerinde 0.6
	var decor: Node3D = opts.get("decor", b.root)
	var W = half_w; var n1 = front_n; var n0 = front_n - depth
	var site = func(type: String, x: float, n: float, extra := {}) -> void:
		if vid == "":
			return
		var wp = b.w(Vector3(x, 0, n))
		wp.y = Game.terrain_height(wp.x, wp.z)
		var d = {"type": type, "pos": wp}
		d.merge(extra)
		if not VL.sites.has(vid):
			VL.sites[vid] = []
		VL.sites[vid].append(d)
	var tree = func(x: float, n: float, t: int, sc: float) -> void:
		b.pack_mesh(_vm(t), Vector3(x, g.call(x, n) - 0.15, n), rng.randf() * 360.0, sc, 1.0)
		b._collide_cyl(b.w(Vector3(x, g.call(x, n) + 2.5 * sc, n)), 0.4 * sc, 5.0 * sc)
	var green = climate != "desert"
	var tree_types = [0, 0, 0] if climate == "green" else ([7, 7, 3] if climate == "desert" else [1, 0, 1])
	var bush_t = 18 if green else 17

	# ---- alçak taş duvar + ahşap korkuluk (güney ortasında kapı)
	var gate_hw = 6.0 * s
	var edges = [[Vector2(cx - W, n0), Vector2(cx - gate_hw, n0)], [Vector2(cx + gate_hw, n0), Vector2(cx + W, n0)],
		[Vector2(cx - W, n0), Vector2(cx - W, n1 - 2)], [Vector2(cx + W, n0), Vector2(cx + W, n1 - 2)]]
	for e in edges:
		var a: Vector2 = e[0]; var c: Vector2 = e[1]
		var L = a.distance_to(c)
		var segs = maxi(1, int(ceil(L / 4.0)))
		var yaw = 0.0 if absf(c.y - a.y) < 0.1 else 90.0  # 0: x boyunca
		for k in segs:
			var m = a.lerp(c, (k + 0.5) / segs)
			var y = g.call(m.x, m.y)
			var sl = L / segs + 0.05
			var sz = Vector3(sl, 1.4, 0.8) if yaw == 0.0 else Vector3(0.8, 1.4, sl)
			b.box(Vector3(m.x, y + 0.25, m.y), sz, STONE.darkened(rng.randf() * 0.06))
			b.box(Vector3(m.x, y + 1.0, m.y), Vector3(sz.x + 0.2, 0.14, sz.z + 0.2), STONE_D, 0, false)
			var pk = a.lerp(c, float(k) / segs)
			b.box(Vector3(pk.x, y + 1.55, pk.y), Vector3(0.18, 1.1, 0.18), WOOD_D, 0, false)
			b.box(Vector3(m.x, y + 2.0, m.y), (Vector3(sl, 0.1, 0.12) if yaw == 0.0 else Vector3(0.12, 0.1, sl)), WOOD, 0, false)
			b.box(Vector3(m.x, y + 1.55, m.y), (Vector3(sl, 0.07, 0.08) if yaw == 0.0 else Vector3(0.08, 0.07, sl)), WOOD, 0, false)
	# kapı: iki kalın direk, çift kiriş, küçük kiremit çatı, "忍" levhası
	var gy0 = g.call(cx, n0)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(cx + sx * gate_hw, gy0 + 2.0, n0), Vector3(0.7, 5.0, 0.7), WOOD_D)
		b.box(Vector3(cx + sx * gate_hw, gy0 + 0.0, n0), Vector3(1.1, 0.6, 1.1), STONE_D)
	b.box(Vector3(cx, gy0 + 4.2, n0), Vector3(gate_hw * 2 + 2.0, 0.45, 0.6), WOOD_D, 0, false)
	b.box(Vector3(cx, gy0 + 3.4, n0), Vector3(gate_hw * 2, 0.3, 0.4), WOOD, 0, false)
	b.roof(Vector3(cx, gy0 + 4.45, n0), Vector3(gate_hw * 2 + 3.0, 1.3, 2.4), roof_c.darkened(0.2))
	b.box(Vector3(cx, gy0 + 3.8, n0 - 0.32), Vector3(2.6, 0.9, 0.1), Color(0.95, 0.92, 0.84), 0, false)
	b.kanji(Vector3(cx, gy0 + 3.8, n0 - 0.4), opts.get("kanji", "忍"), 0.8, Color(0.15, 0.1, 0.08))

	# ---- taş döşeli ana yol (kapı -> kapı), kenar taşları; ön meydan
	var rows = int(depth / 2.3)
	for k in rows:
		var n = n0 + 1.0 + k * 2.3
		if n > n1 - 10.0 * s:
			break
		var y = g.call(cx, n)
		b.box(Vector3(cx + rng.randf_range(-0.15, 0.15), y + 0.02, n), Vector3(4.0 * s + rng.randf_range(-0.2, 0.2), 0.2, 2.1), STONE.lightened(rng.randf_range(-0.04, 0.08)), rng.randf_range(-2, 2), false)
		for sx in [-1.0, 1.0]:
			b.box(Vector3(cx + sx * (2.3 * s + 0.2), y + 0.06, n), Vector3(0.35, 0.3, 2.25), STONE_D, 0, false)
	var py = g.call(cx, n1 - 5 * s)
	b.box(Vector3(cx, py + 0.04, n1 - 5.5 * s), Vector3(26 * s, 0.25, 11 * s), STONE.lightened(0.05), 0, false)
	b.box(Vector3(cx, py + 0.08, n1 - 11 * s), Vector3(26 * s, 0.3, 0.4), STONE_D, 0, false)
	for k in 3:  # kapı önü basamaklar
		b.box(Vector3(cx, py + 0.15 + k * 0.18, n1 - 1.6 + k * 0.45), Vector3(8 * s, 0.2, 1.0), STONE_D.lightened(0.05 * k))
	# fenerler ve budanmış çit sıraları
	var ln = n0 + 7.0
	while ln < n1 - 13.0 * s:
		for sx in [-1.0, 1.0]:
			var lx = cx + sx * 4.2 * s
			b.lantern(lx, ln, g.call(lx, ln) + 3.2)
			if ln + 12.0 < n1 - 12.0 * s:
				var hx = cx + sx * 4.6 * s
				var hy = g.call(hx, ln + 6.0)
				if green:
					b.box(Vector3(hx, hy + 0.4, ln + 6.0), Vector3(0.9, 1.2, 8.5), Color(0.24, 0.47, 0.22), 0, true)
					for q in 4:
						b.sphere(Vector3(hx, hy + 1.0, ln + 3.0 + q * 2.0), Vector3(1.05, 0.55, 2.3), Color(0.3, 0.55, 0.25).lightened(rng.randf() * 0.06), 7)
				else:
					b.box(Vector3(hx, hy + 0.3, ln + 6.0), Vector3(1.0, 0.9, 8.5), STONE.lerp(DIRT, 0.4))
					for q in 3:
						b.pack_mesh(_vm(bush_t), Vector3(hx, hy + 0.7, ln + 3.5 + q * 2.5), rng.randf() * 360.0, 0.7, 0.6)
		ln += 12.0

	# ---- duvar boyunca ağaç sırası (iç taraf) + diplerinde çalı/taş
	for side in [-1.0, 1.0]:
		var n = n0 + 6.0
		var k = 0
		while n < n1 - 6.0:
			var x = cx + side * (W - 4.0 + rng.randf_range(-0.8, 0.8))
			tree.call(x, n, tree_types[k % tree_types.size()], rng.randf_range(0.75, 1.15) * (1.0 if s > 0.8 else 0.8))
			if green:
				b.pack_mesh(_vm(bush_t), Vector3(x + side * -2.2, g.call(x, n) - 0.1, n + 2.5), rng.randf() * 360.0, rng.randf_range(0.6, 1.0), 0.6)
			b.pack_mesh(_vm(19), Vector3(x - side * 1.4, g.call(x, n) - 0.1, n - 2.0), rng.randf() * 360.0, rng.randf_range(0.5, 0.9), 0.6)
			n += rng.randf_range(10.0, 13.0)
			k += 1
	# ön köşeler: kapının iki yanında ağaç
	for sx in [-1.0, 1.0]:
		tree.call(cx + sx * (gate_hw + 4.5), n0 + 3.5, tree_types[0], 0.9)

	# ---- batı yarısı: toprak antrenman alanı (ahşap kenarlı, hafif yükseltilmiş)
	var tx0 = cx - W + 7.0; var tx1 = cx - 7.0 * s
	var tn0 = n0 + 8.0; var tn1 = n1 - 15.0 * s
	var tcx = (tx0 + tx1) * 0.5; var tcn = (tn0 + tn1) * 0.5
	var ty = g.call(tcx, tcn)
	b.box(Vector3(tcx, ty + 0.0, tcn), Vector3(tx1 - tx0, 0.24, tn1 - tn0), DIRT, 0, false)
	for e in [[Vector3(tcx, 0, tn0), Vector3(tx1 - tx0 + 0.5, 0.35, 0.35)], [Vector3(tcx, 0, tn1), Vector3(tx1 - tx0 + 0.5, 0.35, 0.35)],
			[Vector3(tx0, 0, tcn), Vector3(0.35, 0.35, tn1 - tn0)], [Vector3(tx1, 0, tcn), Vector3(0.35, 0.35, tn1 - tn0)]]:
		var p: Vector3 = e[0]
		b.box(Vector3(p.x, g.call(p.x, p.z) + 0.1, p.z), e[1], WOOD, 0, false)
	# arka sırada hedef tahtaları
	var nt = maxi(3, int((tx1 - tx0) / 9.0))
	for i in nt:
		var x = tx0 + (i + 0.5) * (tx1 - tx0) / nt
		var n = tn1 - 2.5
		var y = g.call(x, n)
		b.box(Vector3(x, y + 1.1, n + 0.25), Vector3(0.22, 2.4, 0.22), WOOD_D)
		var rings = [[1.4, Color(0.95, 0.93, 0.86)], [1.05, Color(0.2, 0.2, 0.22)], [0.7, Color(0.95, 0.93, 0.86)], [0.32, Color(0.2, 0.2, 0.22)]]
		for r in rings.size():
			b.disc(Vector3(x, y + 1.9, n - 0.02 * r), rings[r][0], 0.12, rings[r][1], 0.0, 18)
		if i % 2 == 0:  # saplanmış kunai
			b.box(Vector3(x + 0.25, y + 2.05, n - 0.35), Vector3(0.05, 0.05, 0.5), Color(0.25, 0.27, 0.3), 0, false)
	# üçlü kütükler
	for i in 3:
		var x = tx0 + 6.0 + i * 3.2
		var n = tn0 + 6.0
		b.cyl(Vector3(x, g.call(x, n) + 0.8, n), 0.6, 1.9, WOOD.lightened(0.08), true, 9)
		b.cyl(Vector3(x, g.call(x, n) + 1.78, n), 0.62, 0.06, WOOD_D, false, 9)
	# silah rafı
	var rx = tx1 - 3.5; var rn = tn0 + 4.0
	var ry = g.call(rx, rn)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(rx + sx * 1.3, ry + 0.8, rn), Vector3(0.15, 1.6, 0.4), WOOD_D)
	b.box(Vector3(rx, ry + 1.45, rn), Vector3(2.8, 0.12, 0.4), WOOD, 0, false)
	b.box(Vector3(rx, ry + 0.6, rn), Vector3(2.8, 0.12, 0.4), WOOD, 0, false)
	for k in 6:
		b.box(Vector3(rx - 1.0 + k * 0.4, ry + 1.05, rn - 0.05), Vector3(0.05, 1.2, 0.05), Color(0.3, 0.32, 0.36), 0, false, Vector3(0, 0, 8))
	# saman balyaları
	for k in 3:
		var hx = tx0 + 2.5 + (k % 2) * 1.3
		var hn = tn1 - 6.0 - k * 1.1
		b.box(Vector3(hx, g.call(hx, hn) + 0.45 + (0.8 if k == 2 else 0.0), hn if k < 2 else hn + 1.6), Vector3(1.3, 0.8, 0.9), Color(0.82, 0.72, 0.42), rng.randf_range(-10, 10))
	# kuklalar + eşli antrenman
	for i in 4:
		var x = tx0 + 4.0 + i * (tx1 - tx0 - 8.0) / 3.0
		var n = tcn + 1.0
		Spawner.dummy(b.w(Vector3(x, g.call(x, n), n)))
	site.call("spar", tcx, tcn - 4.0)
	site.call("academy_yard", tcx, tcn)

	# ---- doğu yarısı: gölet, basamak taşları, banklar, çiçek tarhları
	var px = cx + W * 0.5; var pn = n0 + depth * 0.42
	var pw = 14.0 * s; var pd = 9.0 * s
	var pgy = g.call(px, pn)
	var water_y = pgy + 0.12
	_oval_water(b, Vector3(px, water_y, pn), pw, pd)
	var nb = int((pw + pd) * 1.1)
	for k in nb:  # kenar taşları (yassı, gri tonlu)
		var a = TAU * (k + rng.randf() * 0.4) / nb
		var ex = px + cos(a) * (pw * 0.5 + 0.1)
		var en = pn + sin(a) * (pd * 0.5 + 0.1)
		var bs = rng.randf_range(0.7, 1.3)
		b.sphere(Vector3(ex, g.call(ex, en) + 0.12, en), Vector3(bs * 1.4, bs * 0.6, bs), STONE.darkened(rng.randf() * 0.18), 7)
	for k in 4:  # basamak taşları
		var sx2 = px - pw * 0.35 + k * pw * 0.23
		b.cyl(Vector3(sx2, water_y + 0.02, pn + (0.6 if k % 2 else -0.5)), 1.1, 0.25, STONE.lightened(0.05), true, 9)
	for k in 5:  # nilüferler (yeşil yapraklar, beyaz çiçek)
		var lx = px + rng.randf_range(-pw * 0.4, pw * 0.4)
		var lzn = pn + rng.randf_range(-pd * 0.35, pd * 0.35)
		b.cyl(Vector3(lx, water_y + 0.02, lzn), rng.randf_range(0.7, 1.1), 0.03, Color(0.3, 0.55, 0.28), false, 8)
		if k % 2 == 0:
			b.sphere(Vector3(lx, water_y + 0.12, lzn), Vector3(0.28, 0.18, 0.28), Color(0.97, 0.97, 0.94), 6)
	if green:
		for k in 3:
			var a = rng.randf() * TAU
			b.pack_mesh(_vm(16), Vector3(px + cos(a) * pw * 0.48, pgy, pn + sin(a) * pd * 0.48), rng.randf() * 360.0, 1.0, 0.6)
	# banklar (gölete bakar) + oturma noktaları
	for sx in [-1.0, 1.0]:
		var bx = px + sx * (pw * 0.5 + 3.0)
		var bn = pn
		var byy = g.call(bx, bn)
		var yaw = 90.0
		b.box(Vector3(bx, byy + 0.45, bn), Vector3(0.55, 0.1, 2.2), WOOD.lightened(0.1), 0, true)
		b.box(Vector3(bx + sx * 0.25, byy + 0.8, bn), Vector3(0.08, 0.5, 2.2), WOOD, 0, false)
		for e in [-0.85, 0.85]:
			b.box(Vector3(bx, byy + 0.2, bn + e), Vector3(0.5, 0.45, 0.12), WOOD_D, 0, false)
		site.call("bench", bx, bn, {"face": atan2(sx, 0.0)})
	# çardak (azumaya): gölete bakan, içinde bank
	var gx = px + pw * 0.15; var gn = pn + pd * 0.5 + 6.0 * s
	var gyy = g.call(gx, gn)
	b.box(Vector3(gx, gyy + 0.1, gn), Vector3(5.2, 0.35, 4.2), STONE_D)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			b.box(Vector3(gx + sx * 2.2, gyy + 1.6, gn + sz * 1.7), Vector3(0.24, 2.8, 0.24), WOOD_D)
	b.roof(Vector3(gx, gyy + 3.0, gn), Vector3(6.4, 1.6, 5.4), roof_c.darkened(0.3), 90.0)
	b.box(Vector3(gx, gyy + 2.95, gn), Vector3(5.0, 0.16, 4.0), WOOD_D, 0, false)
	b.box(Vector3(gx, gyy + 0.7, gn + 1.4), Vector3(3.6, 0.1, 0.5), WOOD.lightened(0.1), 0, true)
	site.call("bench", gx, gn + 1.3, {"face": PI})
	# taş patika: ana yoldan gölete
	var sp0 = Vector2(cx + 4.0 * s, pn + 2.0); var sp1 = Vector2(px - pw * 0.5 - 1.0, pn)
	var nst = int(sp0.distance_to(sp1) / 1.6)
	for k in nst:
		var q = sp0.lerp(sp1, (k + 0.5) / nst) + Vector2(rng.randf_range(-0.3, 0.3), sin(k * 0.7) * 0.8)
		b.cyl(Vector3(q.x, g.call(q.x, q.y) + 0.02, q.y), rng.randf_range(0.8, 1.1), 0.14, STONE.lightened(rng.randf_range(-0.05, 0.08)), false, 7)
	# bahçe ağaç kümeleri (ağaç + çalılar + taş): bahçede boş düz alan kalmasın
	for c2 in [Vector2(px + pw * 0.75, pn - pd * 0.3), Vector2(px - pw * 0.55, pn + pd * 1.2), Vector2(cx + W * 0.25, n0 + depth * 0.2)]:
		var cyy = g.call(c2.x, c2.y)
		tree.call(c2.x, c2.y, tree_types[rng.randi() % tree_types.size()], rng.randf_range(0.8, 1.1))
		for q in 3:
			var a = rng.randf() * TAU
			b.pack_mesh(_vm(bush_t if q < 2 else 19), Vector3(c2.x + cos(a) * 2.6, cyy - 0.1, c2.y + sin(a) * 2.6), rng.randf() * 360.0, rng.randf_range(0.6, 1.0), 0.6)
	# yükseltilmiş taş kenarlı tarhlar: yeşil çalı + beyaz çiçek (kırmızı/mor yok)
	for i in 4:
		var fx = cx + (-1.0 if i < 2 else 1.0) * (7.0 + (i % 2) * 8.0) * s
		var fn = n1 - 14.5 * s
		var fy = g.call(fx, fn)
		b.box(Vector3(fx, fy + 0.25, fn), Vector3(6.0 * s, 0.7, 2.0), STONE_D)
		b.box(Vector3(fx, fy + 0.62, fn), Vector3(5.6 * s, 0.06, 1.6), Color(0.33, 0.24, 0.16), 0, false)
		if green:
			for q in 3:
				b.pack_mesh(_vm(18), Vector3(fx - 1.8 * s + q * 1.8 * s, fy + 0.55, fn), rng.randf() * 360.0, rng.randf_range(0.45, 0.6), 0.5)
			for q in 7:
				b.sphere(Vector3(fx + rng.randf_range(-2.6, 2.6) * s, fy + 0.95 + rng.randf() * 0.25, fn + rng.randf_range(-0.6, 0.6)), Vector3(0.22, 0.16, 0.22), Color(0.97, 0.96, 0.9), 5)
		else:
			b.pack_mesh(_vm(3 if climate == "desert" else 17), Vector3(fx, fy + 0.55, fn), rng.randf() * 360.0, 0.5, 0.5)

	# ---- salıncak ağacı (bahçenin kuzeydoğusu)
	var sw_x = cx + W - 13.0 * s; var sw_n = n1 - 19.0 * s
	var swy = g.call(sw_x, sw_n)
	b.pack_mesh(_vm(0 if green else tree_types[0]), Vector3(sw_x, swy - 0.15, sw_n), 200.0, 1.45, 1.0)
	b._collide_cyl(b.w(Vector3(sw_x, swy + 3.5, sw_n)), 0.55, 7.0)
	b.box(Vector3(sw_x + 3.0, swy + 6.3, sw_n), Vector3(6.2, 0.38, 0.4), WOOD_D, 0, false, Vector3(0, 0, 6))  # yatay dal
	for dz in [-0.55, 0.55]:
		b.box(Vector3(sw_x + 4.6, swy + 3.5, sw_n + dz), Vector3(0.05, 5.0, 0.05), Color(0.85, 0.8, 0.68), 0, false)
	b.box(Vector3(sw_x + 4.6, swy + 0.95, sw_n), Vector3(0.75, 0.1, 1.4), WOOD.lightened(0.1), 0, false)
	b.pack_mesh(_vm(19), Vector3(sw_x - 1.5, swy - 0.1, sw_n - 1.8), 40.0, 0.8, 0.6)
	if vid != "":
		var wp = b.w(Vector3(sw_x + 4.6, 0, sw_n))
		wp.y = Game.terrain_height(wp.x, wp.z) + 0.4
		Interact.add({"pos": wp, "radius": 3.0, "kind": "swing", "label": "[F] Salıncağa otur"})

	# ---- çocuk oyun alanı (kapıya yakın, doğu): kum havuzu, tahterevalli, tırmanma çerçevesi
	var kx = cx + W * 0.42; var kn = n0 + 8.0
	var ky = g.call(kx, kn)
	for e in [[0, 1.8, 4.0, 0.3], [0, -1.8, 4.0, 0.3], [1.8, 0, 0.3, 3.9], [-1.8, 0, 0.3, 3.9]]:
		b.box(Vector3(kx - 6.0 + e[0], ky + 0.15, kn + e[1]), Vector3(e[2], 0.35, e[3]), WOOD, 0, true)
	b.box(Vector3(kx - 6.0, ky + 0.12, kn), Vector3(3.4, 0.2, 3.4), Color(0.9, 0.83, 0.62), 0, false)
	b.box(Vector3(kx, ky + 0.35, kn), Vector3(0.5, 0.7, 0.5), WOOD_D)  # tahterevalli
	b.box(Vector3(kx, ky + 0.72, kn), Vector3(4.6, 0.12, 0.45), WOOD.lightened(0.12), 0, false, Vector3(0, 0, 10))
	for k in 2:
		b.box(Vector3(kx - 2.0 + k * 4.0, ky + 1.05 + (0.35 if k == 0 else -0.35), kn), Vector3(0.06, 0.4, 0.5), WOOD_D, 0, false)
	var jx = kx + 6.0
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			b.box(Vector3(jx + sx * 1.5, ky + 1.2, kn + sz * 1.2), Vector3(0.16, 2.4, 0.16), WOOD_D, 0, true)
	for h in [0.8, 1.6, 2.35]:
		for sz in [-1.0, 1.0]:
			b.box(Vector3(jx, ky + h, kn + sz * 1.2), Vector3(3.1, 0.08, 0.08), WOOD, 0, false)
	b.box(Vector3(jx, ky + 2.4, kn), Vector3(3.1, 0.12, 2.5), WOOD.lightened(0.05), 0, false)
	site.call("ball", kx - 2.0, kn + 6.0)

	# ---- bayrak direği + kapı yanı sancaklar + çan
	var fpx = cx + 15.0 * s; var fpn = n1 - 8.0 * s
	var fpy = g.call(fpx, fpn)
	b.box(Vector3(fpx, fpy + 0.3, fpn), Vector3(1.4, 0.6, 1.4), STONE_D)
	b.cyl(Vector3(fpx, fpy + 6.5, fpn), 0.22, 12.0, Color(0.8, 0.78, 0.74), true, 8)
	b.sphere(Vector3(fpx, fpy + 12.6, fpn), Vector3(0.4, 0.4, 0.4), Color(0.85, 0.7, 0.3), 6)
	b.box(Vector3(fpx + 1.7, fpy + 11.2, fpn), Vector3(3.2, 2.1, 0.06), flag, 0, false)
	for sd in [-1.0, 1.0]:
		b.kanji(Vector3(fpx + 1.7, fpy + 11.2, fpn - sd * 0.05), opts.get("flag_kanji", "忍"), 1.4, Color(0.98, 0.96, 0.9), 0.0 if sd > 0 else 180.0)
	for sx in [-1.0, 1.0]:
		CityDecor.banner(decor, b.w(Vector3(cx + sx * 5.0 * s, 0, n1 - 3.0)), 0.0, flag, Color(0.98, 0.95, 0.9))
	var bx2 = cx - 15.0 * s; var bn2 = n1 - 8.0 * s
	var by2 = g.call(bx2, bn2)
	b.box(Vector3(bx2, by2 + 0.15, bn2), Vector3(3.6, 0.3, 2.4), STONE_D)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(bx2 + sx * 1.3, by2 + 1.9, bn2), Vector3(0.26, 3.5, 0.26), WOOD_D)
	b.box(Vector3(bx2, by2 + 3.6, bn2), Vector3(3.2, 0.25, 0.3), WOOD_D, 0, false)
	b.roof(Vector3(bx2, by2 + 3.75, bn2), Vector3(3.8, 1.0, 2.2), roof_c.darkened(0.25))
	b.cyl(Vector3(bx2, by2 + 2.75, bn2), 1.0, 1.3, Color(0.55, 0.42, 0.22), false, 12)
	b.dome(Vector3(bx2, by2 + 3.38, bn2), 1.0, 0.25, Color(0.5, 0.38, 0.2), 12)
	b.box(Vector3(bx2 + 1.0, by2 + 2.3, bn2 - 0.2), Vector3(1.2, 0.12, 0.12), WOOD, 0, false)  # tokmak

	# ---- kapalı sundurma (bina önü boyunca ahşap güverte + direkler + eğimli çatı + fener dizisi)
	var cw = minf(bw * 0.9, 70.0)
	var cn = n1 - 2.4
	var cy = g.call(cx, cn)
	b.box(Vector3(cx, cy + 0.05, cn), Vector3(cw, 0.3, 4.4), WOOD.darkened(0.1))
	var np = maxi(2, int(cw / 6.5))
	for k in np + 1:
		var x = cx - cw * 0.5 + k * cw / np
		if absf(x - cx) < 2.5:
			continue
		b.box(Vector3(x, cy + 1.85, cn - 2.0), Vector3(0.28, 3.6, 0.28), WOOD_D)
		b.box(Vector3(x, cy + 0.15, cn - 2.0), Vector3(0.5, 0.3, 0.5), STONE_D, 0, false)
	b.box(Vector3(cx, cy + 3.75, cn - 0.2), Vector3(cw + 1.0, 0.18, 5.4), roof_c.darkened(0.15), 0, false, Vector3(-9, 0, 0))
	b.box(Vector3(cx, cy + 3.55, cn - 2.0), Vector3(cw, 0.22, 0.3), WOOD_D, 0, false)
	CityDecor.lantern_string(decor, b.w(Vector3(cx - cw * 0.5, cy + 3.3, cn - 2.1)), b.w(Vector3(cx + cw * 0.5, cy + 3.3, cn - 2.1)), maxi(4, int(cw / 5.0)), [Color(1.0, 0.92, 0.7), Color(0.98, 0.98, 0.95)])

	# ---- çim öbekleri, yosunlu taşlar: boş düz alan kalmasın
	for k in int(depth * W / 140.0):
		var x = cx + rng.randf_range(2.0, W - 3.0) * (1.0 if k % 2 else -1.0)
		var n = rng.randf_range(n0 + 3.0, n1 - 12.0)
		if x < tx1 + 1.0 and x > tx0 - 1.0 and n > tn0 - 1.0 and n < tn1 + 1.0:
			continue  # antrenman alanı
		if Vector2(x - px, (n - pn) * pw / pd).length() < pw * 0.6:
			continue  # gölet
		if absf(x - cx) < 6.0:
			continue  # yol
		b.pack_mesh(_vm(15 if green and k % 3 else 19), Vector3(x, g.call(x, n) - 0.05, n), rng.randf() * 360.0, rng.randf_range(0.6, 1.1), 0.5)


## Oval gölet suyu (yassı silindir)
static var _water_mat: StandardMaterial3D
static func _oval_water(b: Builder, p: Vector3, wdt: float, dep: float) -> void:
	if _water_mat == null:
		_water_mat = StandardMaterial3D.new()
		_water_mat.albedo_color = Color(0.22, 0.48, 0.58, 0.85)
		_water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_water_mat.roughness = 0.08
		_water_mat.metallic_specular = 0.9
	var cm = CylinderMesh.new()
	cm.top_radius = 0.5
	cm.bottom_radius = 0.5
	cm.height = 0.3
	cm.radial_segments = 28
	cm.rings = 1
	cm.material = _water_mat
	var mi = MeshInstance3D.new()
	mi.mesh = cm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = b.view_dist
	b.root.add_child(mi)
	mi.global_position = b.w(p) - Vector3(0, 0.15, 0)
	mi.scale = Vector3(wdt, 1.0, dep)
	var wp = b.w(p)
	Game.add_water(mi, Vector2(wp.x, wp.z), Vector2(wdt, dep), mi.global_rotation.y, wp.y, true)
	# koyu taban (derinlik hissi)
	var bp = b.w(p - Vector3(0, 0.1, 0))
	b._mb(bp).add("cyl", bp, Vector3(wdt + 0.3, 0.06, dep + 0.3), Color(0.2, 0.28, 0.26), Vector3.ZERO, 24)
