class_name BeastSonGoku
extends RefCounted
## Son Gokū — Dört Kuyruk. Referans: _tmp/ref/son_goku_storm (Storm 4 kareleri A/B + anime.png)
## Okunan yapı:
##  - kırmızı kürklü dev goril; yumruklarının üstünde yürür: çok geniş omuz, kalın uzun kollar, kısa arka bacaklar, kambur
##  - yüz, göğüs-karın paneli, eller ve ayaklar soluk yeşil deri
##  - alında kemik rengi taç bant + yukarı-dışa kıvrılan iki uzun boynuz; ağır kaş; sarı göz; yeşil sivri kulak
##  - üst çeneden inen iki uzun kılıç diş; kırmızı favori ve sakal tutamları
##  - omuz, dirsek ve sırtta sivri kürk tutamları
##  - dört uzun kırmızı kuyruk, yukarı-geriye kalkık; üstlerinde sıra sıra kemik plaka-diken

const RED := Color(0.84, 0.17, 0.08)
const RED_D := Color(0.6, 0.09, 0.05)
const SKIN := Color(0.72, 0.8, 0.62)
const SKIN_D := Color(0.52, 0.62, 0.46)
const BONE := Color(0.93, 0.84, 0.64)
const DARK := Color(0.08, 0.04, 0.04)


## Sivri kürk tutamı (yassı koni, hafif kıvrık)
static func _tuft(mb: MB, base: Vector3, dir: Vector3, ln: float, w: float, col := RED) -> void:
	var d = dir.normalized()
	var side = d.cross(Vector3.UP)
	if side.length() < 0.1:
		side = Vector3.RIGHT
	var bend = side.normalized().cross(d) * ln * 0.12
	Loft.tube(mb, [base - d * w * 0.5, base + d * ln * 0.5 + bend, base + d * ln], [Vector2(w, w * 0.45), Vector2(w * 0.6, w * 0.3), Vector2(0.02, 0.02)], col, 8, 2, true, true, Callable(), side.normalized())


static func _front_skin(half: float, zmin: float) -> Callable:
	return func(t: float, _a: float, d: Vector3) -> Color:
		if d.z < zmin and absf(d.x) < half + 0.08 * sin(t * 31.0):
			return SKIN
		return RED


static func build(r: BeastRig, root: Node3D) -> void:
	r.quadruped = false
	r.upright = true
	var HP = Vector3(0, 3.6, 1.6)
	r.hips = r._pivot(root, HP, "kalca_kok")
	var mb = MB.new()
	var ws = BeastSurf.tube(mb, [Vector3(0, 2.9, 2.2) - HP, Vector3(0, 4.4, 1.0) - HP, Vector3(0, 6.0, -0.4) - HP], [Vector2(2.1, 1.9), Vector2(2.4, 2.1), Vector2(2.9, 2.4)], RED, 28, 6, _front_skin(0.62, -0.5))
	for i in 5:   # bel yanı ve kalça kürk tutamları
		for sx in [-1.0, 1.0]:
			var d = ws.at(0.15 + i * 0.17, (PI if sx > 0 else 0.0) + 0.5 * sx, -0.1)
			_tuft(mb, d[0], (d[1] as Vector3) + Vector3(0, -0.9, 0.5), 1.0, 0.4, RED_D if i % 2 == 0 else RED)
	r._mesh(r.hips, mb)
	r._collider(r.hips, Vector3(0, 0.6, 0.2), Vector3(5.2, 4.4, 4.6))
	# --- göğüs: çok geniş omuz kütlesi, kambur; önde yeşil göğüs paneli
	var CH = Vector3(0, 6.2, -0.6)
	r.chest = r._pivot(r.hips, CH - HP, "gogus")
	var mc = MB.new()
	var cs = BeastSurf.tube(mc, [Vector3(0, 5.4, 0.0) - CH, Vector3(0, 6.9, -1.0) - CH, Vector3(0, 8.0, -2.0) - CH, Vector3(0, 8.5, -2.6) - CH], [Vector2(3.0, 2.5), Vector2(3.7, 2.8), Vector2(3.0, 2.3), Vector2(1.6, 1.4)], RED, 30, 6, _front_skin(0.55, -0.55))
	for i in 7:   # sırt çizgisi tutamları
		var d = cs.at(0.1 + i * 0.13, PI * 0.5, -0.1)
		_tuft(mc, d[0], (d[1] as Vector3) + Vector3(0, 0.5, 0.6), 1.3, 0.5, RED_D if i % 2 == 0 else RED)
	for sx in [-1.0, 1.0]:
		# göğüs kası çizgisi
		cs.ribbon(mc, [Vector2(0.3, -PI * 0.5 + 0.08 * sx), Vector2(0.38, -PI * 0.5 + 0.3 * sx), Vector2(0.42, -PI * 0.5 + 0.52 * sx)], func(u: float) -> float: return 0.05 * sin(clampf(u, 0.05, 0.95) * PI) + 0.01, SKIN_D)
	cs.ribbon(mc, [Vector2(0.08, -PI * 0.5), Vector2(0.3, -PI * 0.5), Vector2(0.55, -PI * 0.5)], func(_u: float) -> float: return 0.035, SKIN_D)
	r._mesh(r.chest, mc)
	r._collider(r.chest, Vector3(0, 0.8, -1.0), Vector3(7.6, 4.6, 5.2))
	# --- baş
	var HD = Vector3(0, 7.9, -3.5)
	r.head = r._pivot(r.chest, HD - CH, "bas")
	var mh = MB.new()
	var facef = func(t: float, _a: float, d: Vector3) -> Color:
		return SKIN if (t > 0.4 and d.y > -0.95) or t > 0.7 else RED
	var hs = BeastSurf.tube(mh, [Vector3(0, 0.2, 1.1), Vector3(0, 0.3, 0.2), Vector3(0, 0.05, -0.7), Vector3(0, -0.4, -1.4), Vector3(0, -0.5, -1.8)], [Vector2(1.45, 1.4), Vector2(1.7, 1.6), Vector2(1.45, 1.25), Vector2(1.15, 0.85), Vector2(0.9, 0.6)], RED, 26, 6, facef, Vector3.UP)
	# taç bandı + boynuzlar
	var band = []
	for i in 9:
		var a = lerpf(-1.25, 1.25, i / 8.0)
		band.append(Vector3(sin(a) * 1.62, 0.2 + cos(a) * 1.5, -0.55 - cos(a) * 0.25))
	Loft.tube(mh, band, band.map(func(_q): return Vector2(0.3, 0.42)), BONE, 8, 2, true, true, Callable(), Vector3.BACK)
	mh.add("sphere", Vector3(0, 1.75, -0.95), Vector3(0.75, 0.6, 0.5), BONE, Vector3.ZERO, 10)
	for sx in [-1.0, 1.0]:
		Loft.tube(mh, [Vector3(1.0 * sx, 1.35, -0.75), Vector3(1.9 * sx, 1.9, -0.6), Vector3(2.5 * sx, 3.0, -0.2), Vector3(2.3 * sx, 4.3, 0.5)], [0.48, 0.42, 0.3, 0.03], BONE, 10, 4)
		# ağır kaş çıkıntısı + göz
		var ed = hs.at(0.6, PI * 0.5 + 0.62 * sx, 0.0)
		var nrm = ((ed[1] as Vector3) + Vector3(0, 0, -1.4)).normalized()
		var eb = Basis.looking_at(nrm, Vector3.UP) * Basis(Vector3.BACK, deg_to_rad(-16 * sx))
		mh.add("sphere", (ed[0] as Vector3) + Vector3(0, 0.3, 0.05), Vector3(0.95, 0.4, 0.6), SKIN_D, Vector3(0, 0, -14 * sx), 10)
		BeastModels._anime_eye(r, r.head, (ed[0] as Vector3) + nrm * 0.03, Vector3(0.34, 0.2, 0.08), Color(1.0, 0.9, 0.55), Color(1.0, 0.75, 0.2), DARK, eb.get_euler() * 180.0 / PI, "dot")
		# yeşil sivri kulak
		Loft.tube(mh, [Vector3(1.55 * sx, 0.2, 0.2), Vector3(2.2 * sx, 0.6, 0.4), Vector3(2.7 * sx, 1.3, 0.7)], [Vector2(0.5, 0.2), Vector2(0.4, 0.15), Vector2(0.03, 0.03)], SKIN, 8, 2, true, true, Callable(), Vector3.BACK)
		# favori tutamları (yüzün çevresinde kırmızı kürk)
		for k in 5:
			var cd = hs.at(0.36 + k * 0.02, (PI if sx > 0 else 0.0) + (0.6 - k * 0.38) * sx, -0.1)
			_tuft(mh, cd[0], Vector3(0.9 * sx, -0.5 - k * 0.25, 0.1), 1.3 - k * 0.08, 0.42, RED if k % 2 == 0 else RED_D)
		mh.add("sphere", Vector3(0.24 * sx, -0.3, -2.12), Vector3(0.2, 0.16, 0.14), DARK, Vector3.ZERO, 6)   # burun deliği
		# kılıç diş + küçük dişler
		Loft.tube(mh, [Vector3(0.62 * sx, -0.95, -1.55), Vector3(0.68 * sx, -1.7, -1.7), Vector3(0.6 * sx, -2.5, -1.55)], [0.24, 0.2, 0.03], BONE, 8, 3)
		for i in 4:
			BeastRig.claw(mh, Vector3((0.15 + i * 0.13) * sx, -1.0, -1.95 + i * 0.05), Vector3(0, -1, 0), 0.3, 0.09, BONE)
	for i in 5:   # tepe kürkü
		_tuft(mh, Vector3((i - 2) * 0.5, 1.6, 0.3), Vector3((i - 2) * 0.25, 0.8, 0.8), 1.3, 0.45, RED if i % 2 == 0 else RED_D)
	mh.add("sphere", Vector3(0, -1.0, -0.8), Vector3(1.9, 0.4, 2.0), Color(0.5, 0.2, 0.4), Vector3.ZERO, 10)   # ağız tavanı
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3(0, 0.4, -0.2), Vector3(4.0, 4.0, 3.6))
	r.jaw = r._pivot(r.head, Vector3(0, -1.05, 0.2), "cene")
	r.jaw.rotation.y = PI
	var mj = MB.new()
	Loft.tube(mj, [Vector3(0, -0.2, 0.0), Vector3(0, -0.4, 1.0), Vector3(0, -0.35, 1.95)], [Vector2(1.3, 0.42), Vector2(1.15, 0.42), Vector2(0.75, 0.32)], SKIN, 14, 3)
	for sx in [-1.0, 1.0]:
		BeastRig.claw(mj, Vector3(0.5 * sx, 0.0, 1.85), Vector3(0, 1, 0), 0.6, 0.14, BONE)
		for i in 3:
			BeastRig.claw(mj, Vector3((0.1 + i * 0.13) * sx, 0.0, 2.1), Vector3(0, 1, 0), 0.26, 0.08, BONE)
	for k in 5:   # sakal
		_tuft(mj, Vector3((k - 2) * 0.45, -0.6, 1.0 + (0.5 - absf(k - 2) * 0.25)), Vector3((k - 2) * 0.2, -1, 0.15), 1.5 - absf(k - 2) * 0.25, 0.45, RED if k % 2 == 0 else RED_D)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -1.0, -2.3), "agiz")
	# --- kollar: kalın, uzun; yumruk yerde
	for sx in [-1.0, 1.0]:
		var S = Vector3(3.5 * sx, 7.2, -1.3)
		var E = Vector3(5.2 * sx, 4.3, -2.3)
		var W = Vector3(4.7 * sx, 1.7, -4.2)
		var sh = r._pivot(r.chest, S - CH, "omuz")
		var m1 = MB.new()
		var s1 = BeastSurf.tube(m1, [Vector3(-0.8 * sx, 0.5, 0.3), (E - S) * 0.5 + Vector3(0.3 * sx, 0.2, 0.1), E - S], [2.0, 1.75, 1.35], RED, 18, 5)
		for i in 5:   # omuz + üst kol dış tutamları
			var d = s1.at(0.1 + i * 0.2, (PI if sx > 0 else 0.0), -0.1)
			_tuft(m1, d[0], (d[1] as Vector3) + Vector3(0.2 * sx, 0.6 - i * 0.35, 0.3), 1.2, 0.5, RED_D if i % 2 == 0 else RED)
		r._mesh(sh, m1)
		var el = r._pivot(sh, E - S, "dirsek")
		var m2 = MB.new()
		Loft.tube(m2, [Vector3.ZERO, (W - E) * 0.5 + Vector3(0.1 * sx, 0, 0.1), W - E], [1.4, 1.65, 1.3], RED, 18, 5)
		for i in 4:   # dirsek ve önkol arkası tutamları
			_tuft(m2, (W - E) * (i * 0.25) + Vector3(0.3 * sx, 0.2, 1.1), Vector3(0.4 * sx, 0.5, 1), 1.4 - i * 0.15, 0.5, RED_D if i % 2 == 0 else RED)
		for i in 6:   # bilek kürk yakası
			var a = TAU * i / 6.0
			_tuft(m2, (W - E) * 0.92 + Vector3(cos(a), 0, sin(a)) * 1.1, Vector3(cos(a) * 0.6, -1, sin(a) * 0.6 - 0.3), 0.8, 0.4)
		var fist: Vector3 = W - E + Vector3(-0.1 * sx, -0.75, -0.5)
		m2.add("sphere", fist, Vector3(1.55, 1.2, 1.6), SKIN, Vector3.ZERO, 12)
		for f in 4:
			m2.add("sphere", fist + Vector3((f - 1.5) * 0.62, -0.25, -1.05), Vector3(0.42, 0.55, 0.6), SKIN, Vector3.ZERO, 8)
			m2.add("sphere", fist + Vector3((f - 1.5) * 0.62, -0.7, -0.75), Vector3(0.38, 0.35, 0.5), SKIN_D.lerp(SKIN, 0.5), Vector3.ZERO, 8)
		m2.add("sphere", fist + Vector3(-1.2 * sx, -0.2, -0.3), Vector3(0.5, 0.45, 0.8), SKIN, Vector3.ZERO, 8)   # başparmak
		r._mesh(el, m2)
		r.arms.append({"sh": sh, "el": el, "side": sx})
		# --- kısa arka bacak
		var H = Vector3(1.9 * sx, 3.5, 1.9)
		var K = Vector3(2.8 * sx, 2.1, 0.3)
		var A = Vector3(2.8 * sx, 0.75, 1.3)
		var hi_ = r._pivot(r.hips, H - HP, "kalca")
		var m3 = MB.new()
		var s3 = BeastSurf.tube(m3, [Vector3(-0.3 * sx, 0.4, 0.2), (K - H) * 0.5, K - H], [1.75, 1.5, 1.1], RED, 16, 4)
		for i in 3:
			var d = s3.at(0.25 + i * 0.25, (PI if sx > 0 else 0.0), -0.1)
			_tuft(m3, d[0], (d[1] as Vector3) + Vector3(0, -0.6, 0.6), 0.9, 0.42, RED_D)
		r._mesh(hi_, m3)
		var kn = r._pivot(hi_, K - H, "diz")
		var m4 = MB.new()
		Loft.tube(m4, [Vector3.ZERO, (A - K) * 0.5 + Vector3(0, 0, 0.15), A - K], [1.1, 1.0, 0.8], RED, 14, 4)
		var foot: Vector3 = A - K + Vector3(0, -0.4, -0.7)
		m4.add("sphere", foot, Vector3(1.2, 0.6, 1.7), SKIN, Vector3.ZERO, 10)
		for f in 4:
			m4.add("sphere", foot + Vector3((f - 1.5) * 0.5, -0.05, -1.45), Vector3(0.36, 0.36, 0.6), SKIN, Vector3.ZERO, 8)
		r._mesh(kn, m4)
		r.legs.append({"hip": hi_, "kn": kn, "side": sx, "front": false})
	_tails(r, Vector3(0, 3.6, 3.2) - HP)
	r._weak(r.head, Vector3(0, 2.2, 0.3))
	r._weak(r.chest, Vector3(0, 1.6, 2.4))


## Dört kuyruk: kırmızı, kalın, yukarı-geriye kalkık; üstte sıra sıra kemik plaka-diken
static func _tails(r: BeastRig, base_pos: Vector3) -> void:
	var n = 9
	var length = 13.0
	var seg_len = length / n
	var base = r._pivot(r.hips, base_pos, "kuyruk_koku")
	r.tail_curl = -0.02
	for ti in 4:
		var yaw = lerpf(-38.0, 38.0, ti / 3.0)
		var pitch = -50.0 + absf(ti - 1.5) * 8.0
		var troot = r._pivot(base, Vector3((ti - 1.5) * 0.7, 0, 0), "tail")
		troot.rotation = Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0)
		var segs = []
		var parent = troot
		for i in n:
			var r0 = lerpf(1.3, 0.4, pow(float(i) / n, 1.2))
			var r1 = lerpf(1.3, 0.4, pow(float(i + 1) / n, 1.2))
			var piv = r._pivot(parent, Vector3(0, 0, seg_len) if i > 0 else Vector3.ZERO, "s%d" % i)
			var mb = MB.new()
			Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.15), Vector3(0, 0, seg_len * 0.5), Vector3(0, 0, seg_len * 1.1)], [r0, (r0 + r1) * 0.5, r1], RED if i % 2 == 0 else RED.lerp(RED_D, 0.35), 12, 3, i == 0, i == n - 1)
			# üst plaka-diken (kuyruk kalkıkken geriye bakan yüz = yerel +Y)
			Loft.tube(mb, [Vector3(0, r0 * 0.7, seg_len * 0.15), Vector3(0, r0 * 1.5, seg_len * 0.5), Vector3(0, r0 * 1.9 + 0.2, seg_len * 0.95)], [Vector2(r0 * 0.6, r0 * 0.4), Vector2(r0 * 0.42, r0 * 0.26), Vector2(0.03, 0.03)], BONE, 8, 2, true, true, Callable(), Vector3.RIGHT)
			r._mesh(piv, mb)
			segs.append(piv)
			parent = piv
		r.tails.append(segs)
		r.tail_cfg.append({"yaw": deg_to_rad(yaw), "pitch": deg_to_rad(pitch), "amp": 0.12, "phase": randf() * TAU, "style": "fur", "root": troot})
