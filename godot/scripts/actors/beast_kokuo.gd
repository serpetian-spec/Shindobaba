class_name BeastKokuo
extends RefCounted
## Kokuō — Beş Kuyruk. Referans: _tmp/ref/kokuo_storm (Storm 4 kareleri A/B, anime yakın çekim head.png) + _tmp/ref/kokuo
## Okunan yapı:
##  - bembeyaz, yalın AT gövdesi: derin göğüs, ince bel, çok uzun ince bacaklar, bej toynaklar, bilekte tüy
##  - öne-yukarı kavisli uzun boyun; baş YUNUS: yuvarlak alın (kavun), öne uzayan pürüzsüz gaga, ağız çizgisi göz altına kadar,
##    iki çenede küçük üçgen dişler; yanda açık mavi göz, altında kırmızı hilal
##  - başın arkasından geriye-yukarı dört boynuz (arka çift uzun, ön çift kısa): beyaz, ucu bej, dipte bej benekler
##  - omuz/boyun kökünde kabarık sivri yele tutamları; sırtta soluk gri şimşek izleri
##  - beş uzun, akan beyaz kuyruk; uca doğru incelir, uçları bej

const W := Color(0.95, 0.96, 0.98)
const W_D := Color(0.74, 0.8, 0.88)
const GREY := Color(0.8, 0.84, 0.9)
const TAN := Color(0.87, 0.73, 0.5)
const DK := Color(0.14, 0.16, 0.22)
const RED := Color(0.86, 0.14, 0.16)
const TOOTH := Color(1, 1, 1)
const GUM := Color(0.86, 0.5, 0.6)


static func _body_col(_t: float, _a: float, d: Vector3) -> Color:
	return W.lerp(W_D, clampf((-d.y - 0.25) * 1.6, 0.0, 1.0))


## Sivri yassı tüy tutamı
static func _tuft(mb: MB, base: Vector3, dir: Vector3, ln: float, w: float, col := W) -> void:
	var d = dir.normalized()
	var side = d.cross(Vector3.UP)
	if side.length() < 0.1:
		side = Vector3.RIGHT
	var bend = side.normalized().cross(d) * ln * 0.14
	Loft.tube(mb, [base - d * w * 0.5, base + d * ln * 0.5 + bend, base + d * ln], [Vector2(w, w * 0.45), Vector2(w * 0.6, w * 0.3), Vector2(0.02, 0.02)], col, 8, 2, true, true, Callable(), side.normalized())


## Toynak + bilek tüyü (at = bilek noktası; toynak aşağı uzanır)
static func _hoof(mb: MB, at: Vector3, s: float) -> void:
	Loft.tube(mb, [at + Vector3(0, 0.1, 0), at + Vector3(0, -0.3, -0.08) * s, at + Vector3(0, -0.62, -0.16) * s], [0.36 * s, 0.44 * s, 0.56 * s], [W, TAN, TAN], 12, 2, true, true)
	for k in 4:
		var a = k * 1.3 + 2.2
		_tuft(mb, at + Vector3(sin(a) * 0.25, 0.35, cos(a) * 0.25) * s, Vector3(sin(a) * 0.5, -1, cos(a) * 0.5 + 0.4), 0.8 * s, 0.26 * s, W if k % 2 == 0 else GREY)


static func build(r: BeastRig, root: Node3D) -> void:
	r.quadruped = true
	r.upright = false
	var HP = Vector3(0, 6.5, 2.6)
	r.hips = r._pivot(root, HP, "kalca_kok")
	# --- arka gövde: sağrı -> ince bel
	var mh0 = MB.new()
	var hs0 = BeastSurf.tube(mh0, [Vector3(0, 6.3, 4.2) - HP, Vector3(0, 6.7, 3.0) - HP, Vector3(0, 6.45, 1.0) - HP, Vector3(0, 6.35, -0.6) - HP],
		[Vector2(1.3, 1.4), Vector2(1.95, 2.1), Vector2(1.65, 1.8), Vector2(1.85, 2.15)], W, 32, 8, _body_col, Vector3.UP)
	hs0.flame_marks(mh0, 4, 5, 31, GREY, 0.05, 0.8, 0.1, 0.9, 0.35, PI - 0.35)
	r._mesh(r.hips, mh0)
	r._collider(r.hips, Vector3(0, 0, -0.4), Vector3(3.0, 3.2, 5.2))
	# --- ön gövde: derin göğüs + uzun kavisli boyun
	var CH = Vector3(0, 6.5, -1.0)
	r.chest = r._pivot(r.hips, CH - HP, "gogus")
	var mc = MB.new()
	var cs = BeastSurf.tube(mc, [Vector3(0, 6.35, -0.3) - CH, Vector3(0, 6.3, -1.8) - CH, Vector3(0, 6.9, -3.1) - CH, Vector3(0, 7.7, -4.1) - CH, Vector3(0, 8.3, -5.0) - CH, Vector3(0, 8.5, -5.6) - CH],
		[Vector2(1.85, 2.15), Vector2(2.15, 2.6), Vector2(1.8, 2.15), Vector2(1.3, 1.5), Vector2(1.0, 1.1), Vector2(0.9, 0.95)], W, 32, 8, _body_col, Vector3.UP)
	cs.flame_marks(mc, 4, 5, 32, GREY, 0.05, 0.8, 0.05, 0.5, 0.35, PI - 0.35)
	# yele: boyun sırtından omuza sivri tutamlar + göğüs önü tüyü
	for i in 9:
		var d = cs.at(0.3 + i * 0.07, PI * 0.5, -0.08)
		_tuft(mc, d[0], (d[1] as Vector3) * 0.6 + Vector3(0, 0.2, 1.0), 1.5 - absf(i - 3) * 0.1, 0.5, W if i % 2 == 0 else GREY)
		for sx in [-1.0, 1.0]:
			if i < 6:
				var d2 = cs.at(0.26 + i * 0.07, PI * 0.5 + 0.75 * sx, -0.08)
				_tuft(mc, d2[0], (d2[1] as Vector3) * 0.5 + Vector3(0, -0.2, 1.0), 1.25, 0.45, GREY if i % 2 == 0 else W)
	for i in 5:
		var d3 = cs.at(0.3 + i * 0.07, -PI * 0.5, -0.08)
		_tuft(mc, d3[0], Vector3(0, -1, 0.35), 1.0, 0.42, W if i % 2 == 0 else GREY)
	r._mesh(r.chest, mc)
	r._collider(r.chest, Vector3(0, 0.6, -2.0), Vector3(3.4, 4.6, 4.6))
	# --- baş: yunus (yuvarlak alın + uzun gaga). Üst gaga başın parçası, alt gaga çene.
	var HD = Vector3(0, 8.45, -6.0)
	r.head = r._pivot(r.chest, HD - CH, "bas")
	var mh = MB.new()
	var kp = [Vector3(0, 0.25, 1.0), Vector3(0, 0.25, 0.2), Vector3(0, 0.05, -0.7), Vector3(0, -0.35, -1.4), Vector3(0, -0.62, -2.0), Vector3(0, -0.85, -2.5)]
	var kr = [Vector2(0.95, 0.95), Vector2(1.25, 1.2), Vector2(1.15, 1.05), Vector2(0.8, 0.55), Vector2(0.56, 0.34), Vector2(0.36, 0.22)]
	var ks = BeastSurf.tube(mh, kp, kr, W, 26, 8, _body_col, Vector3.UP)
	for sx in [-1.0, 1.0]:
		# göz: yanda, açık mavi; koyu çerçeve; altında kırmızı hilal
		var ea = (PI if sx > 0 else 0.0) - 0.38 * sx
		var ed = ks.at(0.4, ea, 0.02)
		var nrm = (ed[1] as Vector3).normalized()
		var eb = Basis.looking_at(nrm, Vector3.UP) * Basis(Vector3.BACK, deg_to_rad(-10 * sx))
		BeastModels._anime_eye(r, r.head, (ed[0] as Vector3) + nrm * 0.03, Vector3(0.62, 0.4, 0.09), Color(1, 1, 1), Color(0.5, 0.68, 0.92), DK, eb.get_euler() * 180.0 / PI, "dot")
		ks.ribbon(mh, [Vector2(0.36, ea - 0.2 * sx), Vector2(0.4, ea - 0.26 * sx), Vector2(0.45, ea - 0.2 * sx)], func(u: float) -> float: return 0.035 * sin(clampf(u, 0.05, 0.95) * PI) + 0.008, DK)   # üst kapak çizgisi
		ks.ribbon(mh, [Vector2(0.33, ea + 0.1 * sx), Vector2(0.4, ea + 0.34 * sx), Vector2(0.48, ea + 0.12 * sx)], func(u: float) -> float: return 0.04 * sin(clampf(u, 0.05, 0.95) * PI) + 0.008, RED)   # kırmızı hilal
		# boynuzlar: arka çift uzun, ön çift kısa; geriye-yukarı, hafif dışa; ucu bej
		var b0 = Vector3(0.62 * sx, 0.85, 0.35)
		var b1 = Vector3(1.9 * sx, 3.5, 3.0)
		Loft.tube(mh, [b0, b0.lerp(b1, 0.5) + Vector3(0.15 * sx, 0.35, -0.1), b1], [0.42, 0.3, 0.03], [W, W, TAN], 10, 4)
		var c0 = Vector3(0.42 * sx, 0.95, -0.35)
		var c1 = Vector3(1.0 * sx, 2.7, 1.2)
		Loft.tube(mh, [c0, c0.lerp(c1, 0.5) + Vector3(0.08 * sx, 0.25, -0.1), c1], [0.34, 0.24, 0.03], [W, W, TAN], 10, 4)
		for k in 7:   # boynuz dibi benekleri
			var hb = b0.lerp(b1, 0.12 + k * 0.07) + Vector3(0.2 * sx * (1 if k % 2 == 0 else -1), 0.05, -0.2 if k % 3 == 0 else 0.18)
			mh.add("sphere", hb, Vector3(0.12, 0.12, 0.12), TAN, Vector3.ZERO, 5)
		# üst diş sırası (ağız çizgisi: göz altından gaga ucuna)
		for i in 11:
			var u = i / 10.0
			var tp = Vector3(lerpf(0.82, 0.24, u) * sx, lerpf(-0.5, -1.02, u), lerpf(-0.8, -2.4, u))
			BeastRig.claw(mh, tp, Vector3(0, -1, 0), 0.17, 0.06, TOOTH)
	mh.add("sphere", Vector3(0, -0.72, -1.6), Vector3(1.2, 0.16, 1.9), GUM, Vector3(18, 0, 0), 10)   # ağız tavanı
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3(0, 0.3, -0.8), Vector3(2.6, 2.6, 4.6))
	# alt gaga (çene): arkadan menteşeli, yerel +Z ileri
	r.jaw = r._pivot(r.head, Vector3(0, -0.55, -0.5), "cene")
	r.jaw.rotation.y = PI
	var mj = MB.new()
	Loft.tube(mj, [Vector3(0, -0.2, -0.1), Vector3(0, -0.42, 0.6), Vector3(0, -0.62, 1.3), Vector3(0, -0.72, 1.9)], [Vector2(0.85, 0.3), Vector2(0.72, 0.26), Vector2(0.5, 0.2), Vector2(0.3, 0.13)], W.lerp(W_D, 0.5), 14, 4)
	mj.add("sphere", Vector3(0, -0.3, 0.9), Vector3(0.8, 0.14, 1.7), Color(0.92, 0.55, 0.62), Vector3(-18, 0, 0), 10)   # dil
	for sx in [-1.0, 1.0]:
		for i in 10:
			var u = i / 9.0
			BeastRig.claw(mj, Vector3(lerpf(0.74, 0.2, u) * sx, lerpf(-0.12, -0.62, u), lerpf(0.3, 1.8, u)), Vector3(0, 1, 0), 0.15, 0.055, TOOTH)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -1.0, -2.8), "agiz")
	# --- bacaklar: at; uzun, ince, eklemler belirgin
	for sx in [-1.0, 1.0]:
		var S = Vector3(1.45 * sx, 6.2, -2.3)
		var E = Vector3(1.5 * sx, 3.6, -2.5)
		var Wr = Vector3(1.5 * sx, 0.9, -2.4)
		var sh = r._pivot(r.chest, S - CH, "kalca")
		var m1 = MB.new()
		Loft.tube(m1, [Vector3(-0.15 * sx, 0.8, 0.2), (E - S) * 0.5 + Vector3(0, 0, 0.12), E - S], [1.3, 0.9, 0.56], W, 16, 5, true, true, _body_col)
		_tuft(m1, (E - S) * 0.75 + Vector3(0, 0, 0.3), Vector3(0, -0.3, 1), 0.8, 0.3, GREY)   # dirsek tüyü
		r._mesh(sh, m1)
		var el = r._pivot(sh, E - S, "diz")
		var m2 = MB.new()
		Loft.tube(m2, [Vector3.ZERO, (Wr - E) * 0.5 + Vector3(0, 0, 0.05), Wr - E], [0.6, 0.42, 0.4], W, 12, 4, true, true)
		_hoof(m2, Wr - E, 1.25)
		r._mesh(el, m2)
		r.legs.append({"hip": sh, "kn": el, "side": sx, "front": true})
		var H = Vector3(1.3 * sx, 6.3, 3.0)
		var K = Vector3(1.55 * sx, 4.4, 2.3)
		var HK = Vector3(1.55 * sx, 2.9, 3.6)
		var A = Vector3(1.55 * sx, 0.9, 3.2)
		var hi_ = r._pivot(r.hips, H - HP, "kalca")
		var m3 = MB.new()
		Loft.tube(m3, [Vector3(-0.15 * sx, 0.6, 0.2), (K - H) * 0.5 + Vector3(0, 0, 0.1), K - H], [1.6, 1.2, 0.66], W, 16, 5, true, true, _body_col)
		r._mesh(hi_, m3)
		var kn = r._pivot(hi_, K - H, "diz")
		var m4 = MB.new()
		Loft.tube(m4, [Vector3.ZERO, HK - K, (HK - K).lerp(A - K, 0.5), A - K], [0.66, 0.48, 0.4, 0.4], W, 12, 4, true, true)
		_tuft(m4, HK - K + Vector3(0, 0, 0.25), Vector3(0, -0.4, 1), 0.8, 0.3, GREY)   # ökçe tüyü
		_hoof(m4, A - K, 1.25)
		r._mesh(kn, m4)
		r.legs.append({"hip": hi_, "kn": kn, "side": sx, "front": false})
	_tails(r, Vector3(0, 6.6, 4.2) - HP)
	BeastModels._particles(r.hips, Vector3(2.0, 2.0, 3.5), [Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.0)], 60, 2.5, Vector3(0, 4, 0), 2.0)
	r._weak(r.head, Vector3(0, 1.3, 0.0))
	r._weak(r.hips, Vector3(0, 2.0, -1.0))


## Beş uzun akan kuyruk: dipte kalın, ortada hafif şişkin, uca doğru sivri; uç bej
static func _tails(r: BeastRig, base_pos: Vector3) -> void:
	var n = 10
	var length = 10.5
	var seg_len = length / n
	var rf = func(k: float) -> float:
		return lerpf(0.7, 1.3, sin(minf(1.0, k * 2.5) * PI * 0.5)) * (1.0 - pow(k, 2.4) * 0.94)
	var base = r._pivot(r.hips, base_pos, "kuyruk_koku")
	r.tail_curl = 0.0
	for ti in 5:
		var yaw = lerpf(-24.0, 24.0, ti / 4.0)
		var pitch = -30.0 + absf(ti - 2.0) * 9.0
		var troot = r._pivot(base, Vector3((ti - 2.0) * 0.3, 0, 0), "tail")
		troot.rotation = Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0)
		var segs = []
		var parent = troot
		for i in n:
			var k0 = float(i) / n
			var k1 = float(i + 1) / n
			var r0: float = rf.call(k0)
			var r1: float = rf.call(k1)
			var piv = r._pivot(parent, Vector3(0, 0, seg_len) if i > 0 else Vector3.ZERO, "s%d" % i)
			var mb = MB.new()
			var c0 = W.lerp(TAN, clampf((k0 - 0.72) * 4.0, 0.0, 1.0))
			var c1 = W.lerp(TAN, clampf((k1 - 0.72) * 4.0, 0.0, 1.0))
			Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.15), Vector3(0, 0, seg_len * 0.5), Vector3(0, 0, seg_len * 1.12)], [Vector2(r0, r0 * 0.8), Vector2((r0 + r1) * 0.5, (r0 + r1) * 0.4), Vector2(r1, r1 * 0.8)], [c0, c0.lerp(c1, 0.5), c1], 12, 3, i == 0, true)
			if i < 3:   # kuyruk dibi tüy tutamları
				_tuft(mb, Vector3(0, r0 * 0.7, seg_len * 0.3), Vector3(0, 0.5, 1), 1.0, 0.36, GREY)
			r._mesh(piv, mb)
			segs.append(piv)
			parent = piv
		r.tails.append(segs)
		r.tail_cfg.append({"yaw": deg_to_rad(yaw), "pitch": deg_to_rad(pitch), "amp": 0.13, "phase": randf() * TAU, "style": "fur", "root": troot, "s_amp": 0.26 - absf(ti - 2.0) * 0.04, "s_yaw": (ti - 2.0) * 0.05})
