class_name BeastKurama
extends RefCounted
## Kurama — Dokuz Kuyruk. Referans: _tmp/ref/kurama (anime; _tmp/ref/kurama_storm/head.png yakın çekimler)
## Okunan yapı:
##  - turuncu-kızıl dev TİLKİ, dört ayak üstünde çömelik; üst gövdesi insan gibi: geniş omuz, kaslı kollar, beş parmaklı pençeli ELLER
##  - arka bacaklar tilki (diz önde, topuk geride yukarıda), uzun ayak
##  - baş: geniş kafatası, öne uzayan burun, siyah burun ucu; göz çevresi SİYAH kürk, yukarı kulağın içine kadar uzanır;
##    kızıl yarık göz bebekli gözler çatık; çok uzun, dik, geriye yatık kulaklar; yanakta geriye sivri kürk tutamları
##  - ağız kulağa kadar: koyu dudak çizgisi, sıra sıra sivri dişler, uzun köpek dişleri
##  - dokuz uzun kalın kuyruk yelpaze gibi açılır, uca doğru sivrilir

const C := Color(0.96, 0.5, 0.13)
const CD := Color(0.74, 0.3, 0.08)
const CL := Color(1.0, 0.66, 0.32)
const BLK := Color(0.07, 0.04, 0.07)
const LIP := Color(0.22, 0.07, 0.05)
const FANG := Color(1.0, 0.98, 0.94)
const CLAW := Color(0.92, 0.9, 0.86)


static func _col(_t: float, _a: float, d: Vector3) -> Color:
	return C.lerp(CD, clampf(-d.y * 1.2 - 0.2, 0.0, 1.0) * 0.75)


static func _arc(p0: Vector3, p1: Vector3, p2: Vector3, n: int) -> Array:
	var out = []
	for i in n + 1:
		var u = float(i) / n
		out.append(p0.lerp(p1, u).lerp(p1.lerp(p2, u), u))
	return out


static func _tuft(mb: MB, base: Vector3, dir: Vector3, ln: float, w: float, col := C) -> void:
	var d = dir.normalized()
	var side = d.cross(Vector3.UP)
	if side.length() < 0.1:
		side = Vector3.RIGHT
	var bend = side.normalized().cross(d) * ln * 0.12
	Loft.tube(mb, [base - d * w * 0.5, base + d * ln * 0.5 + bend, base + d * ln], [Vector2(w, w * 0.45), Vector2(w * 0.6, w * 0.3), Vector2(0.02, 0.02)], col, 8, 2, true, true, Callable(), side.normalized())


## El / ayak: avuç + n parmak + pençe (yerel, ileri = -Z)
static func _hand(mb: MB, at: Vector3, s: float, n: int, spread: float, flen: float) -> void:
	mb.add("sphere", at + Vector3(0, 0.1, -0.2) * s, Vector3(1.5, 0.85, 1.7) * s, C, Vector3.ZERO, 12)
	for f in n:
		var fa = lerpf(-spread, spread, f / float(n - 1))
		var f0 = at + Vector3(sin(fa) * 0.5, 0.05, -0.6 - cos(fa) * 0.2) * s
		var f1 = at + Vector3(sin(fa) * (0.5 + flen * 0.55), 0.18, -0.6 - cos(fa) * flen * 0.6) * s
		var f2 = at + Vector3(sin(fa) * (0.5 + flen * 0.95), -0.2, -0.6 - cos(fa) * flen) * s
		Loft.tube(mb, [f0, f1, f2], [0.3 * s, 0.26 * s, 0.2 * s], C, 8, 3, true, true, _col)
		BeastRig.claw(mb, f2 + Vector3(0, 0.05, 0.05) * s, Vector3(sin(fa) * 0.3, -0.35, -1.0), 0.75 * s, 0.17 * s, CLAW)


static func build(r: BeastRig, root: Node3D) -> void:
	r.quadruped = true
	r.upright = false
	var HP = Vector3(0, 5.0, 2.6)
	r.hips = r._pivot(root, HP, "kalca_kok")
	# --- arka gövde: sağrı -> ince bel
	var mh0 = MB.new()
	var hs0 = BeastSurf.tube(mh0, [Vector3(0, 4.8, 4.3) - HP, Vector3(0, 5.2, 3.0) - HP, Vector3(0, 5.0, 1.0) - HP, Vector3(0, 5.1, -0.6) - HP],
		[Vector2(1.5, 1.5), Vector2(2.2, 2.1), Vector2(1.8, 1.7), Vector2(2.2, 2.1)], C, 34, 8, _col, Vector3.UP)
	for i in 5:   # sırt çizgisi kürkü
		var d = hs0.at(0.1 + i * 0.19, PI * 0.5, -0.08)
		_tuft(mh0, d[0], Vector3(0, 0.7, 1.0), 1.0, 0.4, CD if i % 2 == 0 else C)
	r._mesh(r.hips, mh0)
	r._collider(r.hips, Vector3(0, 0, -0.6), Vector3(4.0, 3.8, 5.6))
	# --- ön gövde: geniş omuzlu derin göğüs + kalın boyun
	var CH = Vector3(0, 5.4, -1.0)
	r.chest = r._pivot(r.hips, CH - HP, "gogus")
	var mc = MB.new()
	var cs = BeastSurf.tube(mc, [Vector3(0, 5.1, -0.3) - CH, Vector3(0, 5.4, -1.8) - CH, Vector3(0, 5.9, -3.2) - CH, Vector3(0, 6.3, -4.3) - CH, Vector3(0, 6.5, -5.0) - CH],
		[Vector2(2.1, 2.0), Vector2(2.6, 2.35), Vector2(2.4, 2.1), Vector2(1.7, 1.6), Vector2(1.45, 1.35)], C, 34, 8, _col, Vector3.UP)
	for i in 7:   # ense yelesi
		var d = cs.at(0.2 + i * 0.11, PI * 0.5, -0.08)
		_tuft(mc, d[0], Vector3(0, 0.8, 1.0), 1.3, 0.5, CD if i % 2 == 0 else C)
	for sx in [-1.0, 1.0]:   # omuz arkası / kürek kası çizgisi
		cs.ribbon(mc, [Vector2(0.15, PI * 0.5 + 0.5 * sx), Vector2(0.35, PI * 0.5 + 0.75 * sx), Vector2(0.55, PI * 0.5 + 0.6 * sx)], func(u: float) -> float: return 0.06 * sin(clampf(u, 0.05, 0.95) * PI) + 0.01, CD)
	r._mesh(r.chest, mc)
	r._collider(r.chest, Vector3(0, 0.3, -1.8), Vector3(5.6, 4.8, 4.6))
	# --- baş
	var HD = Vector3(0, 6.5, -5.6)
	r.head = r._pivot(r.chest, HD - CH, "bas")
	var kp = [Vector3(0, 0.3, 1.1), Vector3(0, 0.5, 0.2), Vector3(0, 0.35, -0.6), Vector3(0, -0.05, -1.3), Vector3(0, -0.3, -1.9), Vector3(0, -0.4, -2.3)]
	var kr = [Vector2(1.5, 1.2), Vector2(2.05, 1.4), Vector2(1.75, 1.15), Vector2(1.0, 0.7), Vector2(0.68, 0.48), Vector2(0.45, 0.32)]
	var mh = MB.new()
	var ks = BeastSurf.tube(mh, kp, kr, C, 28, 8, _col, Vector3.UP)
	mh.add("sphere", Vector3(0, -0.3, -2.58), Vector3(0.36, 0.26, 0.26), BLK, Vector3.ZERO, 10)   # burun
	for k in 3:   # burun sırtı kırışıkları (hırlama)
		Loft.tube(mh, [Vector3(-0.45, 0.2 - k * 0.07, -1.45 - k * 0.24), Vector3(0, 0.36 - k * 0.08, -1.55 - k * 0.24), Vector3(0.45, 0.2 - k * 0.07, -1.45 - k * 0.24)], [0.02, 0.04, 0.02], CD, 4, 3)
	for sx in [-1.0, 1.0]:
		var top = PI * 0.5
		# siyah göz çevresi: burun kökünden gözün üstünden kulağın içine
		ks.ribbon(mh, [Vector2(0.62, top + 0.5 * sx), Vector2(0.46, top + 0.9 * sx), Vector2(0.32, top + 0.95 * sx), Vector2(0.16, top + 0.78 * sx), Vector2(0.06, top + 0.6 * sx)], func(u: float) -> float: return 0.62 * pow(sin(clampf(u, 0.03, 0.99) * PI), 0.5) + 0.03, BLK)
		# göz: kızıl, yarık bebek, çatık (iç köşe aşağı)
		var ed = ks.at(0.45, top + 0.9 * sx, 0.04)
		var nrm = ((ed[1] as Vector3) + Vector3(0, 0, -1.2)).normalized()
		var eb = Basis.looking_at(nrm, Vector3.UP) * Basis(Vector3.BACK, deg_to_rad(-22 * sx))
		BeastModels._anime_eye(r, r.head, (ed[0] as Vector3) + nrm * 0.05, Vector3(0.6, 0.2, 0.08), Color(0.8, 0.07, 0.07), Color(1.0, 0.22, 0.15), BLK, eb.get_euler() * 180.0 / PI, "slit")
		# çok uzun kulak: dik, geriye yatık; içi siyah
		var e0 = Vector3(1.05 * sx, 1.1, 0.5)
		var e1 = Vector3(2.7 * sx, 5.6, 2.2)
		Loft.tube(mh, [e0, e0.lerp(e1, 0.45) + Vector3(0.25 * sx, 0.2, -0.1), e1], [Vector2(0.6, 0.26), Vector2(0.5, 0.2), Vector2(0.03, 0.03)], C, 12, 4, true, true, Callable(), Vector3.BACK)
		var f0 = e0.lerp(e1, 0.08) + Vector3(0, 0, -0.27)
		Loft.tube(mh, [f0, f0.lerp(e1, 0.45) + Vector3(0.22 * sx, 0.15, -0.12), e1.lerp(e0, 0.12) + Vector3(0, 0, -0.1)], [Vector2(0.42, 0.08), Vector2(0.34, 0.07), Vector2(0.03, 0.03)], BLK, 10, 4, true, true, Callable(), Vector3.BACK)
		# yanak kürkü: geriye-dışa sivri tutamlar
		for k in 5:
			var cd = ks.at(0.26 + k * 0.03, (PI if sx > 0 else 0.0) + (0.35 - k * 0.3) * sx, -0.08)
			_tuft(mh, cd[0], Vector3(0.75 * sx, 0.1 - k * 0.16, 1.0), 1.9 - k * 0.18, 0.5, C if k % 2 == 0 else CD)
		# üst dudak (koyu) + diş sırası
		var arc = _arc(Vector3(1.5 * sx, -0.75, -0.2), Vector3(1.0 * sx, -0.72, -1.5), Vector3(0, -0.66, -2.4), 11)
		Loft.tube(mh, arc, arc.map(func(_q): return 0.09), LIP, 6, 1)
		for i in range(1, 11):
			var canine = i == 8
			BeastRig.claw(mh, arc[i] + Vector3(-0.05 * sx, -0.02, 0.04), Vector3(0, -1, 0.05), 0.75 if canine else 0.3, 0.13 if canine else 0.075, FANG)
	mh.add("sphere", Vector3(0, -0.62, -1.1), Vector3(2.2, 0.4, 2.4), Color(0.5, 0.1, 0.12), Vector3.ZERO, 12)   # ağız tavanı
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3(0, 0.2, -0.8), Vector3(3.6, 3.0, 4.6))
	r.jaw = r._pivot(r.head, Vector3(0, -0.8, 0.0), "cene")
	r.jaw.rotation.y = PI
	var mj = MB.new()
	Loft.tube(mj, [Vector3(0, -0.2, 0.0), Vector3(0, -0.4, 1.0), Vector3(0, -0.45, 1.75), Vector3(0, -0.4, 2.2)], [Vector2(1.4, 0.36), Vector2(0.95, 0.34), Vector2(0.6, 0.26), Vector2(0.36, 0.18)], C, 16, 4, true, true, _col)
	mj.add("sphere", Vector3(0, -0.2, 1.0), Vector3(1.1, 0.24, 1.8), Color(0.85, 0.4, 0.42), Vector3.ZERO, 10)   # dil
	for sx in [-1.0, 1.0]:
		var arc2 = _arc(Vector3(1.35 * sx, 0.0, 0.3), Vector3(0.9 * sx, -0.12, 1.4), Vector3(0, -0.2, 2.15), 10)
		Loft.tube(mj, arc2, arc2.map(func(_q): return 0.09), LIP, 6, 1)
		for i in range(1, 10):
			var canine = i == 7
			BeastRig.claw(mj, arc2[i] + Vector3(-0.05 * sx, 0.02, -0.04), Vector3(0, 1, -0.05), 0.6 if canine else 0.26, 0.11 if canine else 0.07, FANG)
		_tuft(mj, Vector3(0.7 * sx, -0.5, 0.6), Vector3(0.4 * sx, -0.6, -0.6), 1.0, 0.34, CD)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.8, -2.8), "agiz")
	# --- uzuvlar
	for sx in [-1.0, 1.0]:
		# ön: insan gibi kaslı kol, el yerde
		var S = Vector3(2.7 * sx, 5.9, -2.6)
		var E = Vector3(4.4 * sx, 3.7, -1.9)
		var W = Vector3(4.0 * sx, 1.0, -3.7)
		var sh = r._pivot(r.chest, S - CH, "kalca")
		var m1 = MB.new()
		m1.add("sphere", Vector3(-0.3 * sx, 0.3, 0.1), Vector3(2.3, 2.2, 2.3), C, Vector3.ZERO, 14)   # omuz kütlesi
		var s1 = BeastSurf.tube(m1, [Vector3(-0.2 * sx, 0.4, 0.1), (E - S) * 0.5 + Vector3(0.15 * sx, 0, 0.1), E - S], [1.05, 1.0, 0.72], C, 20, 6, _col)
		s1.ribbon(m1, [Vector2(0.15, 0.4), Vector2(0.5, 0.2), Vector2(0.85, 0.4)], func(u: float) -> float: return 0.05 * sin(clampf(u, 0.05, 0.95) * PI) + 0.01, CD)
		r._mesh(sh, m1)
		var el = r._pivot(sh, E - S, "diz")
		var m2 = MB.new()
		BeastSurf.tube(m2, [Vector3.ZERO, (W - E) * 0.4 + Vector3(0, 0, 0.1), W - E], [0.72, 0.78, 0.55], C, 16, 6, _col)
		for k in 3:   # dirsek arkası kürkü
			_tuft(m2, Vector3(0, -0.1 - k * 0.5, 0.5), Vector3(0, 0.25, 1), 1.0 - k * 0.15, 0.36, CD if k % 2 == 0 else C)
		_hand(m2, W - E + Vector3(0, -0.5, -0.3), 1.15, 5, 0.9, 1.5)
		r._mesh(el, m2)
		r.legs.append({"hip": sh, "kn": el, "side": sx, "front": true})
		# arka: büyük but, diz önde, topuk geride yukarıda, uzun ayak
		var H = Vector3(1.9 * sx, 5.0, 3.0)
		var K = Vector3(2.7 * sx, 3.2, 1.6)
		var HK = Vector3(2.5 * sx, 2.1, 3.7)
		var A = Vector3(2.5 * sx, 0.9, 2.9)
		var hi_ = r._pivot(r.hips, H - HP, "kalca")
		var m3 = MB.new()
		BeastSurf.tube(m3, [Vector3(-0.3 * sx, 0.5, 0.3), (K - H) * 0.5 + Vector3(0, 0, 0.2), K - H], [1.6, 1.35, 0.85], C, 20, 6, _col)
		r._mesh(hi_, m3)
		var kn = r._pivot(hi_, K - H, "diz")
		var m4 = MB.new()
		BeastSurf.tube(m4, [Vector3.ZERO, HK - K, A - K], [0.85, 0.62, 0.52], C, 16, 6, _col)
		for k in 2:
			_tuft(m4, (HK - K) + Vector3(0, 0.2 - k * 0.5, 0.35), Vector3(0, 0.3, 1), 1.0, 0.36, CD)
		_hand(m4, A - K + Vector3(0, -0.45, -0.4), 1.15, 4, 0.6, 1.3)
		r._mesh(kn, m4)
		r.legs.append({"hip": hi_, "kn": kn, "side": sx, "front": false})
	_tails(r, Vector3(0, 5.2, 4.4) - HP)
	r._weak(r.head, Vector3(0, 1.4, -0.3))
	r._weak(r.chest, Vector3(0, 1.8, 0.4))
	r._weak(r.hips, Vector3(0, 1.4, 1.4))


## Dokuz kuyruk: yelpaze; dipte kalın, ortada şişkin, uca sivri; uca doğru açık ton
static func _tails(r: BeastRig, base_pos: Vector3) -> void:
	var n = 10
	var rf = func(k: float) -> float:
		return lerpf(1.0, 1.65, sin(minf(1.0, k * 2.4) * PI * 0.5)) * (1.0 - pow(k, 2.2) * 0.95)
	var base = r._pivot(r.hips, base_pos, "kuyruk_koku")
	r.tail_curl = 0.0
	for ti in 9:
		var yaw = lerpf(-66.0, 66.0, ti / 8.0)
		var pitch = -48.0 + absf(ti - 4.0) * 9.0 + 6.0 * (ti % 2)
		var length = 18.0 - absf(ti - 4.0) * 0.5
		var seg_len = length / n
		var troot = r._pivot(base, Vector3((ti - 4.0) * 0.22, 0, 0), "tail")
		troot.rotation = Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0)
		var segs = []
		var parent = troot
		for i in n:
			var r0: float = rf.call(float(i) / n)
			var r1: float = rf.call(float(i + 1) / n)
			var piv = r._pivot(parent, Vector3(0, 0, seg_len) if i > 0 else Vector3.ZERO, "s%d" % i)
			var mb = MB.new()
			var c0 = C.lerp(CL, float(i) / n * 0.5)
			var c1 = C.lerp(CL, float(i + 1) / n * 0.5)
			Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.2), Vector3(0, 0, seg_len * 0.5), Vector3(0, 0, seg_len * 1.14)], [Vector2(r0, r0 * 0.8), Vector2((r0 + r1) * 0.5, (r0 + r1) * 0.4), Vector2(r1, r1 * 0.8)], [c0, c0.lerp(c1, 0.5), c1], 12, 3, i == 0, i == n - 1)
			r._mesh(piv, mb)
			segs.append(piv)
			parent = piv
		r.tails.append(segs)
		r.tail_cfg.append({"yaw": deg_to_rad(yaw), "pitch": deg_to_rad(pitch), "amp": 0.12, "phase": randf() * TAU, "style": "fur", "root": troot, "s_amp": 0.2, "s_yaw": (ti - 4.0) * 0.03})
