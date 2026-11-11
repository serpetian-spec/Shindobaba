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
const FLESH := Color(0.66, 0.67, 0.72)
const SOCK := Color(0.2, 0.2, 0.26)


## Yassı zırh levhası: pts = (x sağ, y yukarı) yarım hat (x >= 0), side = ±1 ile aynalanır; öne (‑Z) bakar,
## pitch üstü geriye yatırır, yaw levhayı kendi ekseninde çevirir.
static func _plate(mb: MB, pts: Array, side: float, origin: Vector3, pitch_deg: float, yaw_deg: float, thick: float, col: Color, side_col: Color) -> void:
	var ol = PackedVector2Array()
	for q in pts:
		ol.append(Vector2((q as Vector2).y, (q as Vector2).x * side))
	var b0 = Basis(Vector3(0, 0, -1), Vector3.UP, Vector3.RIGHT)
	var bb = Basis(Vector3.UP, deg_to_rad(yaw_deg)) * Basis(Vector3.RIGHT, deg_to_rad(pitch_deg)) * b0
	mb.add_slab(ol, thick, col, Transform3D(bb, origin), Callable(), side_col)


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
		rad.append(Vector2(thick, half_w * edge))
	Loft.tube(mb, pts, rad, col, 10, 2, true, true, Callable(), Vector3.BACK)
	for i in spikes:
		var a = lerpf(-a_max * 0.86, a_max * 0.86, (i + 0.5) / spikes)
		var nr = Vector3(sin(a), cos(a), 0)
		_spike(mb, Vector3(sin(a) * rx, cy + cos(a) * ry, z) + nr * thick * 0.6, nr + Vector3(0, 0, 0.25), sp_len * (1.0 if i % 2 == 0 else 0.7), sp_len * 0.3)


## Kabuk Yuvarlanışı topu: Isobu'nun kendi kabuğu (aynı kemerler, pul dikişleri, diken sıraları, açık kenar çerçevesi)
## top halinde kapanmış. Yarıçap R (metre), ileri = -Z, yuvarlanma ekseni X.
static func shell_ball(R: float) -> Node3D:
	var root = Node3D.new()
	var mb = MB.new()
	var Q = 5.2
	var nz = 28
	var kf = func(z: float) -> float:
		return maxf(0.1, sqrt(maxf(0.0, 1.0 - pow(z / (Q + 0.25), 2.0))))
	for i in nz + 1:
		var z = lerpf(Q, -Q, float(i) / nz)
		var k: float = kf.call(z)
		_arch(mb, z, 0.0, Q * k, Q * k, 0.5, 0.34, PI, 0, 0.0, SH)
		if i % 5 == 2:
			_arch(mb, z, 0.0, Q * k + 0.06, Q * k + 0.06, 0.07, 0.34, PI, 0, 0.0, SH_D)
	for li in 14:
		var a = TAU * li / 14.0
		var seam = []
		for i in nz + 1:
			var z = lerpf(Q, -Q, float(i) / nz)
			var k: float = kf.call(z)
			var pt = Vector3(sin(a) * (Q * k + 0.3), cos(a) * (Q * k + 0.3), z)
			seam.append(pt)
			var nr = Vector3(sin(a) * k, cos(a) * k, z / Q).normalized()
			if i % 5 == 0 and li % 2 == 0:
				_spike(mb, pt, nr, 1.5 * maxf(k, 0.6), 0.42)
			elif i % 5 == 2 and li % 2 == 1:
				_spike(mb, pt, nr, 1.0 * maxf(k, 0.6), 0.32)
		if li % 2 == 1:
			Loft.tube(mb, seam, seam.map(func(_q): return 0.09), SH_D, 5, 1)
	# kabuk kenarı çerçevesi: iki yanda kalın açık renk kuşak + kenar dikenleri
	for sx in [-1.0, 1.0]:
		var rim = []
		for i in 25:
			var ra = TAU * i / 24.0
			rim.append(Vector3(sx * 0.9, cos(ra) * (Q + 0.15) * 0.985, sin(ra) * (Q + 0.15) * 0.985))
			if i % 3 == 0 and i < 24:
				_spike(mb, rim[i], Vector3(sx * 0.5, cos(ra), sin(ra)), 1.2, 0.36)
		Loft.tube(mb, rim, rim.map(func(_q): return 0.42), SH_L, 8, 1)
	# iki yanda kabuk açıklığından görünen kırmızı kas (çizgili)
	mb.add("sphere", Vector3(0, 0, 0), Vector3(1.5, (Q + 0.42) * 2.0, (Q + 0.42) * 2.0), MUS, Vector3.ZERO, 24)
	for i in 16:
		var ra = TAU * i / 16.0
		var c0 = Vector3(0, cos(ra), sin(ra)) * (Q + 0.44)
		Loft.tube(mb, [c0 + Vector3(-0.7, 0, 0), c0 * 1.004, c0 + Vector3(0.7, 0, 0)], [0.05, 0.08, 0.05], MUS_D, 4, 2)
	var mi = MeshInstance3D.new()
	mi.mesh = mb.build(Props.toon())
	mi.scale = Vector3.ONE * (R / (Q + 0.6))
	root.add_child(mi)
	return root


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
		# ön ve arka yüzde merkezden kabuk kenarına yelpaze çizgiler
		bs.ribbon(mb, [Vector2(0.74, a), Vector2(0.85, a + 0.02), Vector2(0.97, a)], func(u: float) -> float: return 0.07 * sin(clampf(u, 0.03, 0.97) * PI) + 0.012, MUS_D)
		bs.ribbon(mb, [Vector2(0.03, a), Vector2(0.1, a + 0.02), Vector2(0.18, a)], func(u: float) -> float: return 0.06 * sin(clampf(u, 0.03, 0.97) * PI) + 0.012, MUS_D)
	# yanlarda kabuk kenarından karna inen enine kas olukları
	for i in 15:
		var rt = lerpf(0.2, 0.73, i / 14.0)
		var ring = []
		for j in 33:
			var ra = lerpf(-PI, PI, j / 32.0)
			ring.append(Vector2(rt + 0.008 * sin(ra * 3.0 + i), ra))
		bs.ribbon(mb, ring, func(_u: float) -> float: return 0.075, MUS_D)
	# --- kabuk: arkadan öne beş bant + öne taşan siperlik; kenarda kalın dikenli çerçeve
	var prof = [[4.6, 0.62, 0.5], [3.3, 0.86, 0.9], [1.9, 0.97, 1.15], [0.4, 1.0, 1.25], [-1.1, 0.97, 1.15], [-2.6, 0.9, 1.0], [-4.0, 0.8, 0.8]]
	# tek parça kaplumbağa kabuğu: sık, üst üste binen kemerlerle kesintisiz kubbe; üstünde pul dikişleri ve diken sıraları
	var kf = func(z: float) -> float:
		for i in range(1, prof.size()):
			if z >= float(prof[i][0]):
				return lerpf(float(prof[i][1]), float(prof[i - 1][1]), (z - float(prof[i][0])) / (float(prof[i - 1][0]) - float(prof[i][0])))
		return float(prof[prof.size() - 1][1])
	var zo = -HP.z + 0.8
	var nz = 26
	for i in nz + 1:
		var z = lerpf(4.6, -4.0, float(i) / nz)
		var k: float = kf.call(z)
		_arch(mb, z + zo, 0.0, 5.25 * k, 5.2 * k, 0.5, 0.34, deg_to_rad(104), 0, 0.0, SH)
		if i % 5 == 2:   # enine pul dikişi
			_arch(mb, z + zo, 0.0, 5.25 * k + 0.06, 5.2 * k + 0.06, 0.07, 0.34, deg_to_rad(103), 0, 0.0, SH_D)
	for li in 7:   # boyuna dikişler + diken sıraları
		var a = deg_to_rad(lerpf(-84.0, 84.0, li / 6.0))
		var seam = []
		for i in nz + 1:
			var z = lerpf(4.6, -4.0, float(i) / nz)
			var k: float = kf.call(z)
			var pt = Vector3(sin(a) * (5.25 * k + 0.3), cos(a) * (5.2 * k + 0.3), z + zo)
			seam.append(pt)
			if i % 5 == 0 and li % 2 == 0:
				_spike(mb, pt, Vector3(sin(a), cos(a), 0.25), 1.5 * k + (0.4 if li == 3 else 0.0), 0.42)
			elif i % 5 == 2 and li % 2 == 1:
				_spike(mb, pt, Vector3(sin(a), cos(a), 0.25), 1.0 * k, 0.32)
		if li % 2 == 1:
			Loft.tube(mb, seam, seam.map(func(_q): return 0.09), SH_D, 5, 1)
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
	# --- baş (anime yakın çekim: _tmp/ref/isobu_storm/head.png)
	#  yüz bir MASKE: yassı zırh levhalarından; üst levha alnı örter, kenarından yıldız gibi yassı üçgen dikenler çıkar,
	#  ortadan gaga gibi sivri bir burun siperi iner; gözler kaş levhasının altındaki çukurda (sol açık kırmızı-sarı, sağ kapalı kırışık);
	#  ağız = üst levhanın zikzak kenarı ile alt çene levhasının zikzak kenarı (birbirine geçen üçgenler); alt çenede aşağı sarkan yassı dikenler
	var HD = Vector3(0, 3.1, -5.9)
	r.head = r._pivot(r.chest, HD - CH, "bas")
	var mh = MB.new()
	var hs = BeastSurf.tube(mh, [Vector3(0, 0.2, 1.1), Vector3(0, 0.2, 0.1), Vector3(0, 0.05, -0.6), Vector3(0, -0.05, -0.95)], [Vector2(1.3, 1.2), Vector2(1.5, 1.35), Vector2(1.35, 1.15), Vector2(1.1, 0.95)], FLESH, 24, 5, Callable(), Vector3.UP)
	# üst levha: iki yarım (ortada sırt yapar), kenarında yıldız dikenler, ortada burun siperi
	var crown = [Vector2(0, -1.3), Vector2(0.3, -0.75), Vector2(0.5, 0.3), Vector2(1.2, 0.45), Vector2(1.7, 0.2), Vector2(2.5, 0.8), Vector2(1.75, 0.9),
		Vector2(2.15, 1.9), Vector2(1.25, 1.5), Vector2(1.0, 2.45), Vector2(0.45, 1.75), Vector2(0, 2.6)]
	for sx in [-1.0, 1.0]:
		_plate(mh, crown, sx, Vector3(0, 0.1, -1.5), 22.0, -15.0 * sx, 0.6, SH_L, SH)
		# yanak levhası: yana ve aşağı iki yassı diken
		_plate(mh, [Vector2(0.9, 0.35), Vector2(1.6, 0.25), Vector2(2.7, -0.2), Vector2(1.75, -0.45), Vector2(2.3, -1.4), Vector2(1.3, -1.0), Vector2(0.85, -0.3)], sx, Vector3(0.25 * sx, -0.05, -1.2), 8.0, -40.0 * sx, 0.5, SH, SH_D)
		# üst dudak levhası: aşağı bakan zikzak
		_plate(mh, [Vector2(0, 0.0), Vector2(1.25, 0.05), Vector2(1.45, -0.25), Vector2(1.05, -0.85), Vector2(0.75, -0.35), Vector2(0.45, -0.9), Vector2(0.2, -0.4), Vector2(0, -0.5)], sx, Vector3(0, -0.45, -1.42), -6.0, -14.0 * sx, 0.45, SH, SH_D)
		# arka-yan sırt dikenleri (yassı)
		for k in 3:
			_plate(mh, [Vector2(0.0, -0.4), Vector2(1.5 - k * 0.2, 0.2), Vector2(0.0, 0.5)], sx, Vector3(1.3 * sx, 0.9 - k * 0.7, 0.3 + k * 0.1), 0.0, -75.0 * sx, 0.45, SH_L, SH)
	# göz çukurları
	for sx in [-1.0, 1.0]:
		mh.add("sphere", Vector3(0.85 * sx, 0.05, -1.22), Vector3(0.8, 0.62, 0.3), SOCK, Vector3(0, -18 * sx, 0), 10)
		for k in 3:   # göz çevresi kırışıkları
			var wa = deg_to_rad(-30.0 + k * 30.0)
			var w0 = Vector3((0.85 + cos(wa) * 0.5) * sx, 0.05 + sin(wa) * 0.38 - 0.25, -1.3)
			Loft.tube(mh, [w0, w0 + Vector3(0.3 * sx, -0.1 - k * 0.05, 0.08), w0 + Vector3(0.55 * sx, -0.12 - k * 0.1, 0.22)], [0.02, 0.025, 0.012], SOCK, 4, 2)
	# sol göz (‑X) açık: kırmızı, sarı halka, koyu bebek; sağ göz (+X) kapalı: kıvrık kırışık çizgiler
	BeastModels._anime_eye(r, r.head, Vector3(-0.85, 0.05, -1.36), Vector3(0.42, 0.3, 0.1), Color(0.8, 0.1, 0.12), Color(1.0, 0.85, 0.2), Color(0.5, 0.05, 0.08), Vector3(0, 18, 0), "dot")
	for k in 3:
		var e0 = Vector3(0.5, 0.12 - k * 0.12, -1.42)
		Loft.tube(mh, [e0, e0 + Vector3(0.35, -0.1, 0.04), e0 + Vector3(0.7, 0.02, 0.14)], [0.02, 0.03, 0.015], SOCK, 4, 3)
	mh.add("sphere", Vector3(0, -0.75, -0.6), Vector3(2.2, 0.5, 1.9), MUS_D, Vector3.ZERO, 10)   # ağız içi
	r._mesh(r.head, mh)
	r.head.scale = Vector3.ONE * 0.8
	r._collider(r.head, Vector3(0, 0.3, -0.2), Vector3(4.4, 3.8, 3.6))
	# alt çene: zikzak üst kenar + aşağı sarkan yassı dikenler
	r.jaw = r._pivot(r.head, Vector3(0, -0.85, 0.3), "cene")
	r.jaw.rotation.y = PI
	var mj = MB.new()
	Loft.tube(mj, [Vector3(0, -0.25, 0.0), Vector3(0, -0.4, 0.9), Vector3(0, -0.35, 1.6)], [Vector2(1.25, 0.4), Vector2(1.15, 0.42), Vector2(0.8, 0.32)], FLESH, 14, 3)
	var jawp = [Vector2(0, 0.1), Vector2(0.3, 0.5), Vector2(0.62, 0.02), Vector2(0.9, 0.48), Vector2(1.2, 0.0), Vector2(1.55, 0.3), Vector2(1.7, -0.7), Vector2(1.15, -0.6),
		Vector2(0.9, -1.3), Vector2(0.42, -0.9), Vector2(0, -1.6)]
	for sx in [-1.0, 1.0]:
		_plate(mj, jawp, sx, Vector3(0, -0.2, 1.65), 10.0, 180.0 - 14.0 * sx, 0.5, SH_L, SH)
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
		# omuz zırhı: üst üste iki iri plaka + kenar çıtası + dikenler
		m1.add("sphere", Vector3(0.2 * sx, 0.75, -0.1), Vector3(3.0, 1.7, 3.1), SH_L, Vector3(0, 0, -22 * sx), 14)
		m1.add("sphere", Vector3(1.0 * sx, 0.0, -0.2), Vector3(2.5, 1.4, 2.7), SH, Vector3(0, 0, -48 * sx), 12)
		var prim = []
		for i in 9:
			var pa = TAU * i / 8.0
			prim.append(Basis(Vector3.BACK, deg_to_rad(-22 * sx)) * Vector3(cos(pa) * 1.5, -0.1, sin(pa) * 1.55) + Vector3(0.2 * sx, 0.75, -0.1))
		Loft.tube(m1, prim, prim.map(func(_q): return 0.2), SH_D, 6, 1, false, false)
		for i in 4:
			var sa = TAU * i / 4.0 + 0.6
			_spike(m1, Vector3(0.2 * sx + cos(sa) * 0.9, 1.5, -0.1 + sin(sa) * 0.9), Vector3(cos(sa) * 0.5 + 0.3 * sx, 1, sin(sa) * 0.5), 1.3, 0.34)
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
