class_name BeastGyuki
extends RefCounted
## Gyūki — Sekiz Kuyruk. Referans: _tmp/ref/gyuki_storm (Storm 4 kareleri A/B, head.png) + _tmp/ref/gyuki (anime)
## Okunan yapı:
##  - soluk gül-mor, dev KASLI öküz-insan üst gövdesi: çok geniş kambur omuzlar, kalın kollar, beş parmaklı eller yerde
##  - bacak yok: gövdenin altı sekiz ahtapot dokunacına açılır; iç yüzlerinde soluk halka vantuzlar (ortası koyu), uçları yukarı kıvrılır
##  - baş boğa: uzun yüz, öne uzayan çene, açık bej yassı burun, iri kare dişli sırıtış; koyu çukurda beyaz göz
##  - iki büyük boynuz yandan öne-yukarı kıvrılır (sol boynuz kesik), altında yana bakan iki küçük boynuz
##  - bütün gövdede kas lifi çizgileri (boyuna ince oluklar)

const C := Color(0.76, 0.55, 0.6)
const CD := Color(0.55, 0.37, 0.44)
const CL := Color(0.86, 0.68, 0.7)
const SUCK := Color(0.95, 0.9, 0.88)
const DARK := Color(0.26, 0.16, 0.22)
const NOSE := Color(0.88, 0.78, 0.64)
const TOOTH := Color(0.98, 0.97, 0.92)


static func _col(_t: float, _a: float, d: Vector3) -> Color:
	return C.lerp(CD, clampf(-d.y * 1.1 - 0.15, 0.0, 1.0) * 0.8)


## Kas lifi çizgileri: tüp boyunca n adet hafif dalgalı ince oluk
static func _fibers(mb: MB, sf: BeastSurf, n: int, a0: float, a1: float, t0: float, t1: float, w: float, seed_v: int) -> void:
	for i in n:
		var a = lerpf(a0, a1, (i + 0.5) / n)
		var ph = seed_v * 1.7 + i * 2.3
		var path = []
		for k in 9:
			var t = lerpf(t0, t1, k / 8.0)
			path.append(Vector2(t, a + 0.035 * sin(t * 9.0 + ph)))
		sf.ribbon(mb, path, func(u: float) -> float: return w * sin(clampf(u, 0.04, 0.96) * PI) + 0.008, CD)


static func build(r: BeastRig, root: Node3D) -> void:
	r.quadruped = false
	r.upright = true
	var HP = Vector3(0, 2.4, 1.6)
	r.hips = r._pivot(root, HP, "kalca_kok")
	# --- alt gövde: dokunaçların çıktığı geniş etli kütle
	var mb = MB.new()
	var bs = BeastSurf.tube(mb, [Vector3(0, 0.4, 2.2) - HP, Vector3(0, 1.6, 1.9) - HP, Vector3(0, 3.0, 1.4) - HP, Vector3(0, 4.2, 0.8) - HP],
		[Vector2(2.6, 2.4), Vector2(3.5, 3.0), Vector2(3.6, 2.9), Vector2(3.3, 2.6)], C, 32, 6, _col, Vector3.BACK)
	_fibers(mb, bs, 22, -PI, PI, 0.08, 0.95, 0.045, 3)
	r._mesh(r.hips, mb)
	r._collider(r.hips, Vector3(0, 0.0, 0.2), Vector3(7.0, 4.0, 6.0))
	# --- üst gövde: öne eğik, çok geniş kambur omuzlar
	var CH = Vector3(0, 4.6, 0.6)
	r.chest = r._pivot(r.hips, CH - HP, "gogus")
	var mc = MB.new()
	var cs = BeastSurf.tube(mc, [Vector3(0, 3.8, 1.0) - CH, Vector3(0, 5.4, 0.3) - CH, Vector3(0, 7.2, -0.7) - CH, Vector3(0, 8.4, -1.5) - CH, Vector3(0, 8.9, -2.0) - CH],
		[Vector2(3.3, 2.6), Vector2(4.1, 3.1), Vector2(4.3, 3.0), Vector2(2.7, 2.2), Vector2(1.5, 1.4)], C, 36, 8, _col, Vector3.BACK)
	_fibers(mc, cs, 30, -PI, PI, 0.05, 0.92, 0.05, 7)
	for sx in [-1.0, 1.0]:
		# göğüs kası altı + karın kası çizgileri (ön yüz)
		mc.add("sphere", Vector3(1.75 * sx, 6.6, -3.1) - CH, Vector3(3.3, 2.4, 1.6), C, Vector3(-18, 0, 0), 14)
		Loft.tube(mc, [Vector3(0.15 * sx, 5.7, -3.5) - CH, Vector3(1.8 * sx, 5.35, -3.6) - CH, Vector3(3.4 * sx, 5.9, -2.9) - CH], [0.07, 0.1, 0.06], CD, 5, 4)
		for k in 3:
			Loft.tube(mc, [Vector3(0.1 * sx, 4.9 - k * 0.6, -3.2 + k * 0.25) - CH, Vector3(1.3 * sx, 4.8 - k * 0.6, -3.1 + k * 0.25) - CH, Vector3(2.3 * sx, 4.95 - k * 0.6, -2.7 + k * 0.25) - CH], [0.05, 0.07, 0.04], CD, 4, 3)
	Loft.tube(mc, [Vector3(0, 7.2, -3.75) - CH, Vector3(0, 5.6, -3.6) - CH, Vector3(0, 3.6, -2.5) - CH], [0.06, 0.08, 0.05], CD, 4, 4)   # orta çizgi
	r._mesh(r.chest, mc)
	r._collider(r.chest, Vector3(0, 2.2, -0.9), Vector3(9.0, 5.4, 6.4))
	# --- baş: boğa (uzun yüz, bej yassı burun, kare dişli sırıtış)
	var HD = Vector3(0, 8.5, -2.9)
	r.head = r._pivot(r.chest, HD - CH, "bas")
	var mh = MB.new()
	var kp = [Vector3(0, 0.3, 1.1), Vector3(0, 0.4, 0.2), Vector3(0, 0.15, -0.8), Vector3(0, -0.35, -1.7), Vector3(0, -0.6, -2.3)]
	var kr = [Vector2(1.25, 1.3), Vector2(1.5, 1.5), Vector2(1.3, 1.25), Vector2(1.1, 0.8), Vector2(0.95, 0.6)]
	var ks = BeastSurf.tube(mh, kp, kr, C, 26, 6, _col, Vector3.UP)
	_fibers(mh, ks, 14, 0.1, PI - 0.1, 0.05, 0.7, 0.035, 11)
	mh.add("sphere", Vector3(0, -0.22, -2.5), Vector3(1.3, 0.6, 0.8), NOSE, Vector3(-20, 0, 0), 12)   # yassı bej burun
	for sx in [-1.0, 1.0]:
		mh.add("sphere", Vector3(0.36 * sx, -0.2, -2.98), Vector3(0.28, 0.2, 0.14), DARK, Vector3(0, 0, 18 * sx), 6)
		# kaş çıkıntısı + koyu göz çukuru + beyaz göz (ortası koyu halka)
		Loft.tube(mh, [Vector3(0.2 * sx, 0.95, -1.4), Vector3(0.8 * sx, 1.2, -1.15), Vector3(1.4 * sx, 1.0, -0.6)], [0.2, 0.26, 0.18], C, 8, 4)
		mh.add("sphere", Vector3(0.74 * sx, 0.45, -1.42), Vector3(1.0, 0.8, 0.5), DARK, Vector3(0, -22 * sx, -12 * sx), 10)
		BeastModels._anime_eye(r, r.head, Vector3(0.74 * sx, 0.45, -1.66), Vector3(0.62, 0.5, 0.16), SUCK, DARK, SUCK, Vector3(0, 22 * sx, -12 * sx), "dot")
		# büyük boynuz: yandan dışa, sonra öne-yukarı; SOL (‑X) boynuz kesik
		var b0 = Vector3(1.15 * sx, 1.0, 0.3)
		var b1 = Vector3(2.9 * sx, 2.0, 0.1)
		var b2 = Vector3(3.2 * sx, 4.0, -1.0)
		var b3 = Vector3(2.5 * sx, 5.6, -2.3)
		if sx > 0:
			Loft.tube(mh, [b0, b1, b2, b3], [0.75, 0.62, 0.42, 0.04], [C, C, CL, CL], 12, 5)
		else:
			Loft.tube(mh, [b0, b1, b1.lerp(b2, 0.55)], [0.75, 0.62, 0.52], [C, C, CL], 12, 4, true, true)
		# alt küçük boynuz: yana-geriye
		Loft.tube(mh, [Vector3(1.3 * sx, 0.0, 0.5), Vector3(2.2 * sx, 0.1, 0.9), Vector3(3.0 * sx, 0.6, 1.3)], [0.42, 0.3, 0.03], [C, C, CL], 10, 3)
		# üst dişler: iri, kare
		for i in 4:
			mh.add("box", Vector3((0.16 + i * 0.3) * sx, -1.02 - i * 0.02, -2.5 + i * 0.22), Vector3(0.28, 0.44, 0.14), TOOTH, Vector3(0, -22 * i * sx, 0))
	mh.add("sphere", Vector3(0, -0.85, -1.6), Vector3(2.0, 0.4, 2.2), CD, Vector3(12, 0, 0), 10)   # üst diş eti / ağız tavanı
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3(0, 0.3, -0.6), Vector3(3.4, 3.2, 4.2))
	r.jaw = r._pivot(r.head, Vector3(0, -0.9, -0.2), "cene")
	r.jaw.rotation.y = PI
	var mj = MB.new()
	Loft.tube(mj, [Vector3(0, -0.3, -0.1), Vector3(0, -0.6, 1.0), Vector3(0, -0.7, 2.0), Vector3(0, -0.6, 2.5)], [Vector2(1.25, 0.5), Vector2(1.15, 0.5), Vector2(1.0, 0.42), Vector2(0.7, 0.3)], C, 16, 4, true, true, _col)
	mj.add("sphere", Vector3(0, -0.35, 1.3), Vector3(1.5, 0.3, 2.2), Color(0.7, 0.3, 0.38), Vector3.ZERO, 10)
	for sx in [-1.0, 1.0]:
		for i in 4:
			mj.add("box", Vector3((0.16 + i * 0.29) * sx, -0.2, 2.5 - i * 0.22), Vector3(0.27, 0.42, 0.14), TOOTH, Vector3(0, 22 * i * sx, 0))
	Loft.tube(mj, [Vector3(0, -0.9, 2.2), Vector3(0, -1.5, 2.3), Vector3(0, -2.2, 2.0)], [0.34, 0.24, 0.03], C, 8, 3)   # çene altı çıkıntısı
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.9, -3.2), "agiz")
	# --- kollar: dev, kaslı; eller yerde beş parmak
	for sx in [-1.0, 1.0]:
		var S = Vector3(4.2 * sx, 7.3, -0.9)
		var E = Vector3(5.9 * sx, 4.3, -1.9)
		var Wr = Vector3(5.2 * sx, 1.5, -4.0)
		var sh = r._pivot(r.chest, S - CH, "omuz")
		var m1 = MB.new()
		m1.add("sphere", Vector3(0, 0.2, 0), Vector3(4.0, 3.6, 3.8), C, Vector3.ZERO, 16)   # omuz kütlesi
		var s1 = BeastSurf.tube(m1, [Vector3(0, 0.2, 0), (E - S) * 0.5 + Vector3(0.3 * sx, 0, 0.2), E - S], [1.9, 1.85, 1.3], C, 22, 6, _col)
		_fibers(m1, s1, 14, -PI, PI, 0.08, 0.92, 0.04, 21)
		r._mesh(sh, m1)
		var el = r._pivot(sh, E - S, "dirsek")
		var m2 = MB.new()
		var s2 = BeastSurf.tube(m2, [Vector3.ZERO, (Wr - E) * 0.45 + Vector3(0.2 * sx, 0, 0), Wr - E], [1.3, 1.5, 1.05], C, 20, 6, _col)
		_fibers(m2, s2, 12, -PI, PI, 0.08, 0.92, 0.035, 23)
		Loft.tube(m2, [Vector3(0.3 * sx, 0.2, 0.6), Vector3(0.6 * sx, 0.6, 1.5), Vector3(0.7 * sx, 1.1, 2.3)], [0.5, 0.34, 0.03], [C, C, CL], 8, 3)   # dirsek dikeni
		var hand = Wr - E + Vector3(0, -0.5, -0.5)
		m2.add("sphere", hand, Vector3(2.5, 1.2, 2.6), C, Vector3.ZERO, 12)
		for f in 5:
			var fa = lerpf(-0.9, 0.9, f / 4.0) - 0.2 * sx
			var f0 = hand + Vector3(sin(fa) * 0.85, 0.0, -cos(fa) * 0.95)
			var f1 = hand + Vector3(sin(fa) * 1.7, 0.1, -cos(fa) * 1.9)
			var f2 = hand + Vector3(sin(fa) * 2.3, -0.5, -cos(fa) * 2.6)
			Loft.tube(m2, [f0, f1, f2], [0.42, 0.36, 0.22], C, 8, 3, true, true, _col)
		r._mesh(el, m2)
		r.arms.append({"sh": sh, "el": el, "side": sx})
	_tails(r, Vector3(0, 1.3, 2.0) - HP)
	r._weak(r.head, Vector3(0, 1.6, 0.0))
	r._weak(r.hips, Vector3(0, 1.0, 2.6))


## Sekiz dokunaç: tabanda kalın, yere yayılıp ucu yukarı-içe kıvrılır; iç (üst) yüzde iki sıra halka vantuz
static func _tails(r: BeastRig, base_pos: Vector3) -> void:
	var n = 10
	var base = r._pivot(r.hips, base_pos, "kuyruk_koku")
	r.tail_curl = 0.0
	for ti in 8:
		var yaw = lerpf(-128.0, 128.0, ti / 7.0)
		var length = 15.0 + 2.5 * fposmod(ti * 0.61, 1.0)
		var seg_len = length / n
		var pitch = -78.0 + absf(ti - 3.5) * 14.0 - 6.0 * fposmod(ti * 0.37, 1.0)
		var troot = r._pivot(base, Vector3(sin(deg_to_rad(yaw)) * 2.4, 0, cos(deg_to_rad(yaw)) * 1.8), "tail")
		troot.rotation = Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0)
		var segs = []
		var parent = troot
		for i in n:
			var k0 = float(i) / n
			var k1 = float(i + 1) / n
			var r0 = lerpf(1.45, 0.3, pow(k0, 0.9))
			var r1 = lerpf(1.45, 0.3, pow(k1, 0.9))
			var piv = r._pivot(parent, Vector3(0, 0, seg_len) if i > 0 else Vector3.ZERO, "s%d" % i)
			var mb = MB.new()
			Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.25), Vector3(0, 0, seg_len * 0.5), Vector3(0, 0, seg_len * 1.15)], [r0, (r0 + r1) * 0.5, r1], C, 14, 3, i == 0, true, _col)
			if i == n - 1:
				mb.add("sphere", Vector3(0, 0, seg_len * 1.12), Vector3(r1 * 2.0, r1 * 2.0, r1 * 2.2), C, Vector3.ZERO, 10)
			# vantuzlar: üst-iç yüzde iki sıra; soluk halka, ortası koyu
			for q in 2:
				for sx in [-1.0, 1.0]:
					var rr = lerpf(r0, r1, 0.25 + q * 0.5)
					var sa = 0.5 * sx
					var sp = Vector3(sin(sa) * rr * 0.96, cos(sa) * rr * 0.96, seg_len * (0.25 + q * 0.5))
					var bb = Basis(Vector3.BACK, -sa)
					mb.add_xf("sphere", Transform3D(bb * Basis.from_scale(Vector3(rr * 0.62, rr * 0.2, rr * 0.62)), sp), SUCK, 10)
					mb.add_xf("sphere", Transform3D(bb * Basis.from_scale(Vector3(rr * 0.26, rr * 0.24, rr * 0.26)), sp + bb * Vector3(0, rr * 0.03, 0)), DARK, 8)
			r._mesh(piv, mb)
			segs.append(piv)
			parent = piv
		r.tails.append(segs)
		r.tail_cfg.append({"yaw": deg_to_rad(yaw), "pitch": deg_to_rad(pitch), "amp": 0.09, "phase": randf() * TAU, "style": "fur", "root": troot, "s_amp": 0.2 + 0.06 * fposmod(ti * 0.53, 1.0), "s_yaw": 0.14 * (1.0 if ti % 2 == 0 else -1.0)})
