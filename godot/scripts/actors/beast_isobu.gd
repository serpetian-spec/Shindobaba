class_name BeastIsobu
extends RefCounted
## Isobu — Üç Kuyruk. Referans: _tmp/ref/isobu_storm (Storm 4 kareleri A + anime.png)
## Okunan yapı:
##  - dev kaplumbağa: alçak ve çok geniş; sırtta gri-mavi, dikenli, bantlı kabuk kemeri (yengeç kabuğu gibi), kenarında kalın dikenli çerçeve
##  - kabuğun altı ve ön yüzü kırmızı-pembe, boyuna oluklu kas dokusu (kabuk bunun üstüne oturur)
##  - ARKA BACAK YOK: yalnız iki iri, zırhlı insan kolu (omuzda dikenli plaka), geniş elleriyle yerde sürünür
##  - baş kabuğun ön siperliği altında: zırhlı miğfer, alından geriye-yana yıldız gibi açılan iri dikenler, çenede dikenler
##  - sol gözü açık (kırmızı, sarı bebek), sağ gözü hep kapalı
##  - üç kuyruk: karides kuyruğu gibi yassı, boğumlu, üstü gri plaka altı kırmızı

const SH := Color(0.58, 0.63, 0.72)
const SH_D := Color(0.4, 0.45, 0.56)
const SH_L := Color(0.74, 0.78, 0.85)
const MUS := Color(0.74, 0.3, 0.38)
const MUS_D := Color(0.48, 0.14, 0.24)
const DARK := Color(0.08, 0.06, 0.1)


static func _spike(mb: MB, base: Vector3, dir: Vector3, ln: float, rad: float, col := SH_L) -> void:
	BeastRig.claw(mb, base - dir.normalized() * rad * 0.5, dir, ln, rad, col)


## Kabuk bandı: gövdenin üstünden bir yandan öbürüne kemer; üstünde dikenler
static func _arch(mb: MB, z: float, cy: float, rx: float, ry: float, half_w: float, thick: float, a_max: float, spikes: int, sp_len: float, col: Color) -> void:
	var pts = []
	var rad = []
	var n = 14
	for i in n + 1:
		var a = lerpf(-a_max, a_max, float(i) / n)
		pts.append(Vector3(sin(a) * rx, cy + cos(a) * ry, z))
		var edge = 1.0 - 0.35 * pow(absf(float(i) / n * 2.0 - 1.0), 3.0)
		rad.append(Vector2(half_w * edge, thick))
	Loft.tube(mb, pts, rad, col, 10, 2, true, true, Callable(), Vector3.BACK)
	for i in spikes:
		var a = lerpf(-a_max * 0.86, a_max * 0.86, (i + 0.5) / spikes)
		var nr = Vector3(sin(a), cos(a), 0)
		_spike(mb, Vector3(sin(a) * rx, cy + cos(a) * ry, z) + nr * thick * 0.6, nr + Vector3(0, 0, 0.25), sp_len * (1.0 if i % 2 == 0 else 0.7), sp_len * 0.3)


static func build(r: BeastRig, root: Node3D) -> void:
	r.quadruped = true
	r.upright = false
	var HP = Vector3(0, 3.7, 0.8)
	r.hips = r._pivot(root, HP, "kalca_kok")
	var mb = MB.new()
	# --- kırmızı kas gövde (boyuna oluklu)
	var bp = [Vector3(0, 0.1, 5.0), Vector3(0, 0.0, 3.2), Vector3(0, 0.0, 0.5), Vector3(0, 0.0, -2.2), Vector3(0, -0.1, -4.2)]
	var br = [Vector2(2.2, 1.8), Vector2(4.2, 3.2), Vector2(4.8, 3.5), Vector2(4.3, 3.3), Vector2(2.6, 2.3)]
	var bs = BeastSurf.tube(mb, bp, br, MUS, 40, 8, Callable(), Vector3.UP)
	for i in 26:
		var a = TAU * i / 26.0
		bs.ribbon(mb, [Vector2(0.03, a), Vector2(0.3, a + 0.03), Vector2(0.65, a - 0.02), Vector2(0.97, a)], func(u: float) -> float: return 0.07 * sin(clampf(u, 0.03, 0.97) * PI) + 0.012, MUS_D)
	# --- kabuk: arkadan öne beş bant + öne taşan siperlik; kenarda kalın dikenli çerçeve
	var prof = [[4.6, 0.62, 0.5], [3.3, 0.86, 0.9], [1.9, 0.97, 1.15], [0.4, 1.0, 1.25], [-1.1, 0.97, 1.15], [-2.6, 0.9, 1.0], [-4.0, 0.8, 0.8]]
	for i in prof.size():
		var q = prof[i]
		var k = float(q[1])
		_arch(mb, float(q[0]) - HP.z + 0.8, 0.0, 5.25 * k, 5.2 * k, 1.3, 0.36, deg_to_rad(104), 5 if i % 2 == 0 else 4, float(q[2]) * 1.35, SH if i % 2 == 0 else SH_D.lerp(SH, 0.5))
	for sx in [-1.0, 1.0]:
		var rim = []
		var rr = []
		for i in prof.size():
			var q = prof[i]
			var k = float(q[1])
			var a = deg_to_rad(104) * sx
			rim.append(Vector3(sin(a) * 5.35 * k, cos(a) * 5.2 * k, float(q[0]) - HP.z + 0.8))
			rr.append(0.6 * (0.6 + 0.4 * k))
		Loft.tube(mb, rim, rr, SH_L, 10, 3)
		for i in range(1, rim.size()):
			var m: Vector3 = (rim[i - 1] as Vector3).lerp(rim[i], 0.5)
			_spike(mb, m, Vector3(sx, 0.25, 0.2), 1.1, 0.34)
	# siperlik kenarı (başın üstünde kalın dikenli kaş)
	_arch(mb, -4.7 - HP.z + 0.8, 0.1, 3.9, 3.9, 0.7, 0.5, deg_to_rad(96), 6, 1.5, SH_L)
	r._mesh(r.hips, mb)
	r._collider(r.hips, Vector3(0, 0.6, 0.4), Vector3(10.0, 8.6, 9.6))
	# --- göğüs (kollar + baş buna bağlı)
	var CH = Vector3(0, 3.4, -3.0)
	r.chest = r._pivot(r.hips, CH - HP, "gogus")
	var mc = MB.new()
	var ns = BeastSurf.tube(mc, [Vector3(0, 0.1, 0.6), Vector3(0, -0.2, -1.2), Vector3(0, -0.5, -2.4)], [Vector2(2.4, 2.1), Vector2(2.0, 1.75), Vector2(1.5, 1.3)], MUS, 24, 4, Callable(), Vector3.UP)
	for i in 14:
		var a = TAU * i / 14.0
		ns.ribbon(mc, [Vector2(0.05, a), Vector2(0.5, a + 0.03), Vector2(0.95, a)], func(u: float) -> float: return 0.06 * sin(clampf(u, 0.03, 0.97) * PI) + 0.01, MUS_D)
	r._mesh(r.chest, mc)
	# --- baş: zırhlı miğfer + yıldız dikenler
	var HD = Vector3(0, 3.1, -5.9)
	r.head = r._pivot(r.chest, HD - CH, "bas")
	var mh = MB.new()
	var hs = BeastSurf.tube(mh, [Vector3(0, 0.1, 1.0), Vector3(0, 0.2, 0.1), Vector3(0, 0.05, -0.9), Vector3(0, -0.15, -1.7)], [Vector2(1.5, 1.25), Vector2(1.75, 1.45), Vector2(1.35, 1.05), Vector2(0.8, 0.6)], SH, 24, 5, Callable(), Vector3.UP)
	# alın plakası + miğfer çizgileri
	for sx in [-1.0, 1.0]:
		hs.ribbon(mh, [Vector2(0.2, PI * 0.5 + 0.5 * sx), Vector2(0.5, PI * 0.5 + 0.42 * sx), Vector2(0.85, PI * 0.5 + 0.25 * sx)], func(_u: float) -> float: return 0.035, SH_D)
		hs.ribbon(mh, [Vector2(0.45, PI * 0.5 + 1.5 * sx), Vector2(0.62, PI * 0.5 + 1.2 * sx), Vector2(0.86, PI * 0.5 + 1.05 * sx)], func(_u: float) -> float: return 0.035, SH_D)
	# yıldız dikenler: alından geriye-yana açılır (ortadaki en uzun)
	for i in 7:
		var a = deg_to_rad(lerpf(-112.0, 112.0, i / 6.0))
		var ln = 3.3 - absf(i - 3) * 0.35
		var base = Vector3(sin(a) * 1.5, 0.2 + cos(a) * 1.25, 0.25)
		var dir = Vector3(sin(a) * 1.0, cos(a) * 1.0, 0.55)
		Loft.tube(mh, [base - dir.normalized() * 0.3, base + dir.normalized() * ln * 0.5, base + dir.normalized() * ln], [Vector2(0.75, 0.3), Vector2(0.5, 0.2), Vector2(0.02, 0.02)], SH_L, 8, 2, true, true, Callable(), Vector3.BACK)
	# yanak / burun dikenleri
	for sx in [-1.0, 1.0]:
		_spike(mh, Vector3(1.3 * sx, -0.3, -0.5), Vector3(sx, -0.25, -0.5), 1.1, 0.3)
		_spike(mh, Vector3(0.55 * sx, 0.55, -1.5), Vector3(0.3 * sx, 0.7, -0.7), 0.7, 0.2)
	_spike(mh, Vector3(0, 0.75, -1.2), Vector3(0, 0.8, -0.6), 0.9, 0.24)
	# gözler: sol (‑X) açık kırmızı/sarı; sağ (+X) kapalı çizgi
	var ed = hs.at(0.6, PI * 0.5 - 0.95, 0.02)   # a=0 → ‑X tarafı
	var nrm = ((ed[1] as Vector3) + Vector3(0, 0, -1.2)).normalized()
	var eb = Basis.looking_at(nrm, Vector3.UP) * Basis(Vector3.BACK, deg_to_rad(14))
	mh.add("sphere", (ed[0] as Vector3) - nrm * 0.05, Vector3(0.56, 0.42, 0.2), DARK, eb.get_euler() * 180.0 / PI, 10)
	BeastModels._anime_eye(r, r.head, (ed[0] as Vector3) + nrm * 0.05, Vector3(0.4, 0.3, 0.1), Color(0.8, 0.12, 0.12), Color(1.0, 0.85, 0.2), DARK, eb.get_euler() * 180.0 / PI, "dot")
	hs.ribbon(mh, [Vector2(0.55, PI * 0.5 + 0.7), Vector2(0.6, PI * 0.5 + 0.95), Vector2(0.62, PI * 0.5 + 1.2)], func(u: float) -> float: return 0.07 * sin(clampf(u, 0.05, 0.95) * PI) + 0.01, DARK)
	mh.add("sphere", Vector3(0, -0.62, -0.7), Vector3(1.9, 0.4, 2.0), MUS_D, Vector3.ZERO, 10)   # ağız tavanı
	for sx in [-1.0, 1.0]:
		for i in 5:
			BeastRig.claw(mh, Vector3((0.35 + i * 0.2) * sx, -0.62, -1.55 + i * 0.32), Vector3(0, -1, 0), 0.34, 0.1, Color(0.92, 0.94, 0.98))
	r._mesh(r.head, mh)
	r.head.scale = Vector3.ONE * 1.4
	r._collider(r.head, Vector3(0, 0.3, -0.2), Vector3(4.4, 3.8, 3.6))
	# alt çene: zırhlı, önde iki diken, altta sakal dikenleri
	r.jaw = r._pivot(r.head, Vector3(0, -0.72, 0.5), "cene")
	r.jaw.rotation.y = PI
	var mj = MB.new()
	Loft.tube(mj, [Vector3(0, -0.15, 0.0), Vector3(0, -0.3, 1.1), Vector3(0, -0.2, 2.1)], [Vector2(1.3, 0.4), Vector2(1.1, 0.4), Vector2(0.6, 0.28)], SH, 14, 3)
	for sx in [-1.0, 1.0]:
		_spike(mj, Vector3(0.4 * sx, -0.1, 2.05), Vector3(0.15 * sx, 0.9, 0.5), 0.8, 0.2)
		_spike(mj, Vector3(0.9 * sx, -0.5, 1.0), Vector3(0.5 * sx, -0.8, 0.3), 0.9, 0.24)
		for i in 4:
			BeastRig.claw(mj, Vector3((0.35 + i * 0.2) * sx, 0.1, 1.7 - i * 0.32), Vector3(0, 1, 0), 0.28, 0.09, Color(0.92, 0.94, 0.98))
	_spike(mj, Vector3(0, -0.55, 1.6), Vector3(0, -0.8, 0.5), 1.0, 0.26)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.6, -2.1), "agiz")
	# --- kollar: iri, zırhlı insan kolları; omuzda dikenli plaka; geniş el yerde
	for sx in [-1.0, 1.0]:
		var S = Vector3(4.1 * sx, 3.6, -2.7)
		var E = Vector3(6.2 * sx, 2.5, -3.9)
		var W = Vector3(5.6 * sx, 1.0, -5.7)
		var sh = r._pivot(r.chest, S - CH, "omuz")
		var m1 = MB.new()
		Loft.tube(m1, [Vector3(-0.6 * sx, 0.2, 0.4), (E - S) * 0.5 + Vector3(0.2 * sx, 0.25, 0), E - S], [1.3, 1.2, 1.0], SH, 16, 4)
		m1.add("sphere", Vector3(0.3 * sx, 0.7, -0.1), Vector3(2.3, 1.3, 2.4), SH_L, Vector3(0, 0, -25 * sx), 12)   # omuz plakası
		for i in 3:
			_spike(m1, Vector3((0.2 + i * 0.5) * sx, 1.15 - i * 0.12, -0.5 + i * 0.35), Vector3(0.5 * sx, 1, -0.1 + i * 0.1), 1.5, 0.36)
		m1.add("sphere", E - S, Vector3(1.15, 1.15, 1.15), SH_D, Vector3.ZERO, 10)   # dirsek
		_spike(m1, E - S + Vector3(0.6 * sx, 0.2, 0.5), Vector3(sx, 0.3, 0.8), 0.9, 0.26)
		r._mesh(sh, m1)
		var el = r._pivot(sh, E - S, "dirsek")
		var m2 = MB.new()
		Loft.tube(m2, [Vector3.ZERO, (W - E) * 0.5 + Vector3(0.15 * sx, 0.1, 0), W - E], [1.05, 1.1, 0.9], SH, 16, 4)
		for i in 3:   # önkol plakaları
			var f: Vector3 = (W - E) * (0.25 + i * 0.25)
			m2.add("sphere", f + Vector3(0.35 * sx, 0.45, 0), Vector3(1.0, 0.5, 1.0), SH_L, Vector3(0, 0, -30 * sx), 8)
			_spike(m2, f + Vector3(0.6 * sx, 0.7, 0), Vector3(0.8 * sx, 1, 0), 0.55, 0.17)
		var hand: Vector3 = W - E + Vector3(-0.2 * sx, -0.45, -0.7)
		m2.add("sphere", hand, Vector3(1.5, 0.75, 1.6), SH, Vector3.ZERO, 12)
		for f in 4:
			var ph = lerpf(-0.75, 0.75, f / 3.0) - 0.2 * sx
			var b0 = hand + Vector3(sin(ph) * 0.9, 0.05, -0.9 - cos(ph) * 0.2)
			var b1 = b0 + Vector3(sin(ph) * 0.9, -0.1, -1.0)
			BeastRig.limb(m2, b0, b1, 0.42, 0.36, SH, 8)
			BeastRig.claw(m2, b1, Vector3(sin(ph) * 0.5, -0.35, -1.0), 0.8, 0.26, SH_L)
		r._mesh(el, m2)
		r.arms.append({"sh": sh, "el": el, "side": sx})
	_tails(r, Vector3(0, 0.3, 5.0))
	r._weak(r.head, Vector3(0, 1.4, 0.4))
	r._weak(r.hips, Vector3(0, 5.3, 0.0))


## Üç karides kuyruğu: yassı, boğumlu; üstü gri plaka, altı kırmızı, kenarda küçük dikenler, uç yelpaze
static func _tails(r: BeastRig, base_pos: Vector3) -> void:
	var n = 9
	var length = 11.0
	var seg_len = length / n
	var base = r._pivot(r.hips, base_pos, "kuyruk_koku")
	r.tail_curl = -0.015
	var colf = func(_t: float, _a: float, d: Vector3) -> Color:
		return MUS if d.y < -0.25 else SH
	for ti in 3:
		var yaw = (ti - 1) * 30.0
		var pitch = -5.0 - (6.0 if ti == 1 else 0.0)
		var troot = r._pivot(base, Vector3((ti - 1) * 1.2, 0, 0), "tail")
		troot.rotation = Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0)
		var segs = []
		var parent = troot
		for i in n:
			var k0 = float(i) / n
			var k1 = float(i + 1) / n
			var w0 = lerpf(2.1, 0.8, k0)
			var w1 = lerpf(2.1, 0.8, k1)
			var piv = r._pivot(parent, Vector3(0, 0, seg_len) if i > 0 else Vector3.ZERO, "s%d" % i)
			var mb = MB.new()
			# boğum: önü geniş, arkası dar; bir sonrakinin üstüne biner
			Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.15), Vector3(0, 0.05, seg_len * 0.45), Vector3(0, 0, seg_len * 1.1)], [Vector2(w0 * 1.08, w0 * 0.5), Vector2((w0 + w1) * 0.5, (w0 + w1) * 0.24), Vector2(w1 * 0.9, w1 * 0.42)], SH, 14, 3, true, true, colf, Vector3.UP)
			Loft.tube(mb, [Vector3(-w0 * 1.0, 0.1, 0), Vector3(0, w0 * 0.52, 0.05), Vector3(w0 * 1.0, 0.1, 0)], [0.14, 0.17, 0.14], SH_L, 6, 3)   # plaka kenarı
			for sx in [-1.0, 1.0]:
				_spike(mb, Vector3(w0 * 1.0 * sx, 0.05, seg_len * 0.2), Vector3(sx, 0.2, 0.7), 0.7 * w0 / 2.1 + 0.3, 0.2)
			if i == n - 1:   # uç yelpaze
				for f in 3:
					var a = (f - 1) * 0.55
					Loft.tube(mb, [Vector3(0, 0, seg_len * 0.9), Vector3(sin(a) * 0.9, 0, seg_len * 0.9 + cos(a) * 1.0), Vector3(sin(a) * 1.5, 0, seg_len * 0.9 + cos(a) * 2.0)], [Vector2(0.45, 0.16), Vector2(0.42, 0.12), Vector2(0.03, 0.03)], SH_L, 8, 2, true, true, Callable(), Vector3.UP)
			r._mesh(piv, mb)
			segs.append(piv)
			parent = piv
		r.tails.append(segs)
		r.tail_cfg.append({"yaw": deg_to_rad(yaw), "pitch": deg_to_rad(pitch), "amp": 0.13, "phase": randf() * TAU, "style": "fur", "root": troot})
