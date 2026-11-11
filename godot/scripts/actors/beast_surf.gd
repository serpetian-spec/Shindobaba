class_name BeastSurf
extends RefCounted
## Loft tüpünün yüzeyini örnekleyen yardımcı: desenler (damar, maske, pul) gövdenin GERÇEK yüzeyine yapışır.
## Loft.tube ile aynı alt bölme ve paralel taşıma çerçevesi kullanılır; t: 0..1 omurga boyunca, a: kesit açısı.
## up = Vector3.BACK ile dikey tüplerde: a = -PI/2 ön (-Z), a = PI/2 arka (+Z), a = PI sağ (+X), a = 0 sol (-X).

var P: Array = []
var S: Array = []
var N: Array = []
var R: Array = []
var length := 1.0


static func make(pts: Array, rad: Array, sub := 4, up := Vector3.BACK) -> BeastSurf:
	var s = BeastSurf.new()
	var n = pts.size()
	var RR: Array = []
	for r in rad:
		RR.append(r if r is Vector2 else Vector2(float(r), float(r)))
	for i in n - 1:
		var p0 = pts[maxi(0, i - 1)]; var p1 = pts[i]; var p2 = pts[i + 1]; var p3 = pts[mini(n - 1, i + 2)]
		var r0 = RR[maxi(0, i - 1)]; var r1 = RR[i]; var r2 = RR[i + 1]; var r3 = RR[mini(n - 1, i + 2)]
		for k in sub:
			var t = float(k) / sub
			s.P.append(Loft._cr(p0, p1, p2, p3, t))
			var rr: Vector2 = Loft._cr(r0, r1, r2, r3, t)
			s.R.append(Vector2(maxf(rr.x, 0.01), maxf(rr.y, 0.01)))
	s.P.append(pts[n - 1]); s.R.append(RR[n - 1])
	var m = s.P.size()
	var T: Array = []
	for i in m:
		var tt: Vector3 = s.P[mini(m - 1, i + 1)] - s.P[maxi(0, i - 1)]
		T.append(tt.normalized() if tt.length() > 1e-5 else Vector3.FORWARD)
	var side: Vector3 = up.cross(T[0])
	if side.length() < 0.1:
		side = Vector3.RIGHT.cross(T[0])
	side = side.normalized()
	s.length = 0.0
	for i in m:
		if i > 0:
			var q = Quaternion(T[i - 1], T[i]) if T[i - 1].dot(T[i]) < 0.9999 else Quaternion.IDENTITY
			side = q * side
			side = (side - T[i] * side.dot(T[i])).normalized()
			s.length += (s.P[i] - s.P[i - 1]).length()
		s.S.append(side)
		s.N.append((T[i] as Vector3).cross(side).normalized())
	return s


## Tüpü kurar (Loft.tube) ve aynı yüzeyin örnekleyicisini döndürür
static func tube(mb: MB, pts: Array, rad: Array, col, seg := 32, sub := 6, col_fn := Callable(), up := Vector3.BACK) -> BeastSurf:
	Loft.tube(mb, pts, rad, col, seg, sub, true, true, col_fn, up)
	return make(pts, rad, sub, up)


## Yüzey noktası + normal: [pos, nrm]
func at(t: float, a: float, lift := 0.0) -> Array:
	var x = clampf(t, 0.0, 1.0) * (P.size() - 1)
	var k = mini(int(x), P.size() - 2)
	var f = x - k
	var c: Vector3 = (P[k] as Vector3).lerp(P[k + 1], f)
	var sd: Vector3 = (S[k] as Vector3).lerp(S[k + 1], f).normalized()
	var nm: Vector3 = (N[k] as Vector3).lerp(N[k + 1], f).normalized()
	var r: Vector2 = (R[k] as Vector2).lerp(R[k + 1], f)
	var ca = cos(a); var sa = sin(a)
	var n = (sd * ca / r.x + nm * sa / r.y).normalized()
	return [c + sd * ca * r.x + nm * sa * r.y + n * lift, n]


func radius(t: float) -> float:
	var x = clampf(t, 0.0, 1.0) * (P.size() - 1)
	var k = mini(int(x), P.size() - 2)
	var r: Vector2 = (R[k] as Vector2).lerp(R[k + 1], x - k)
	return (r.x + r.y) * 0.5


## Yüzeye yapışık yassı şerit: path = [Vector2(t, a)...], wfn(u 0..1) -> yarı genişlik
func ribbon(mb: MB, path: Array, wfn: Callable, col: Color, lift := 0.04) -> void:
	var n = path.size()
	if n < 2:
		return
	var pp: Array = []; var nn: Array = []
	for q in path:
		var d = at(q.x, q.y, lift)
		pp.append(d[0]); nn.append(d[1])
	var base = mb.verts.size()
	for i in n:
		var tg: Vector3 = (pp[mini(n - 1, i + 1)] as Vector3) - (pp[maxi(0, i - 1)] as Vector3)
		var sd = (nn[i] as Vector3).cross(tg).normalized()
		var h: float = wfn.call(float(i) / (n - 1))
		for sg in [-1.0, 1.0]:
			mb.verts.append((pp[i] as Vector3) + sd * h * sg)
			mb.normals.append(nn[i])
			mb.colors.append(col)
			mb.uvs.append(Vector2.ZERO)
	for i in n - 1:
		var a0 = base + i * 2
		mb.idx.append_array([a0, a0 + 2, a0 + 1, a0 + 1, a0 + 2, a0 + 3, a0, a0 + 1, a0 + 2, a0 + 1, a0 + 3, a0 + 2])


## Yüzeye yapışık dolu yama (maske, leke): outline = (t, a) uzayında çokgen; iç ızgarayla yüzeye uyar
func patch(mb: MB, outline: PackedVector2Array, col: Color, lift := 0.04, cell := 0.05) -> void:
	# kenarları sıklaştır
	var a_sc = 1.0 / maxf(0.2, radius(outline[0].x))
	var t_sc = 1.0 / maxf(0.2, length)
	var pts := PackedVector2Array()
	for i in outline.size():
		var p = outline[i]; var q = outline[(i + 1) % outline.size()]
		var d = Vector2((q.x - p.x) / t_sc, (q.y - p.y) / a_sc).length()
		var st = maxi(1, int(ceil(d / cell)))
		for k in st:
			pts.append(p.lerp(q, float(k) / st))
	var poly = pts.duplicate()
	var mn = pts[0]; var mx = pts[0]
	for p in pts:
		mn = mn.min(p); mx = mx.max(p)
	var x = mn.x + cell * t_sc * 0.5
	while x < mx.x:
		var y = mn.y + cell * a_sc * 0.5
		while y < mx.y:
			var g = Vector2(x, y)
			if Geometry2D.is_point_in_polygon(g, poly):
				pts.append(g)
			y += cell * a_sc
		x += cell * t_sc
	# Delaunay ölçekli uzayda (yaklaşık izometrik) yapılır
	var sc := PackedVector2Array()
	for p in pts:
		sc.append(Vector2(p.x / t_sc, p.y / a_sc))
	var tri = Geometry2D.triangulate_delaunay(sc)
	var base = mb.verts.size()
	for p in pts:
		var d = at(p.x, p.y, lift)
		mb.verts.append(d[0]); mb.normals.append(d[1]); mb.colors.append(col); mb.uvs.append(Vector2.ZERO)
	for i in range(0, tri.size(), 3):
		var c = (pts[tri[i]] + pts[tri[i + 1]] + pts[tri[i + 2]]) / 3.0
		if not Geometry2D.is_point_in_polygon(c, poly):
			continue
		mb.idx.append_array([base + tri[i], base + tri[i + 1], base + tri[i + 2], base + tri[i], base + tri[i + 2], base + tri[i + 1]])


## Alev gibi kıvrılan mühür damarları (Shukaku): iki ucu sivri, dalgalı, bazısı kancalı ya da damla gözlü.
## Yüzeye eşit dağılır (katmanlı ızgara + sapma). a0..a1: kesit açı aralığı, t0..t1: omurga aralığı.
func flame_marks(mb: MB, n_t: int, n_a: int, seed_v: int, col: Color, w: float, ln: float, t0 := 0.06, t1 := 0.94, a0 := -PI, a1 := PI, flow := 0.0) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_v
	for it in n_t:
		for ia in n_a:
			var t = lerpf(t0, t1, (it + rng.randf_range(0.15, 0.85)) / n_t)
			var a = lerpf(a0, a1, (ia + rng.randf_range(0.15, 0.85) + (0.5 if it % 2 == 1 else 0.0)) / n_a)
			var l = ln * rng.randf_range(0.65, 1.35)
			var th = flow + rng.randf_range(-0.7, 0.7) + (PI if rng.randf() < 0.5 else 0.0)   # akış: omurga boyunca (flow=0), iki yöne
			var wav = rng.randf_range(0.3, 0.65) * (1.0 if rng.randf() < 0.5 else -1.0)
			var hook = rng.randf_range(0.5, 1.3) * (1.0 if rng.randf() < 0.5 else -1.0) if rng.randf() < 0.5 else 0.0
			var ww = w * rng.randf_range(0.75, 1.25)
			var steps = 16
			var path: Array = []
			var ct = t; var ca = a
			var mid := Vector2.ZERO; var mid_th := 0.0
			for k in steps + 1:
				var u = float(k) / steps
				path.append(Vector2(ct, ca))
				var dir = th + sin(u * PI * 1.6 + it) * wav + hook * u * u * u
				if k == steps / 2:
					mid = Vector2(ct, ca); mid_th = dir
				var ds = l / steps
				ct += cos(dir) * ds / maxf(0.2, length)
				ca += sin(dir) * ds / maxf(0.2, radius(ct))
			# tüpün ucundan taşan darbe atılmaz, taştığı yerde kesilir
			var cut = path.size()
			for k in path.size():
				if path[k].x < 0.01 or path[k].x > 0.99:
					cut = k
					break
			if cut < 7:
				continue
			path = path.slice(0, cut)
			# fırça darbesi: başta çabuk kalınlaşır, uca doğru uzun sivrilir
			ribbon(mb, path, func(u: float) -> float: return ww * pow(sin(minf(1.0, u * 2.2) * PI * 0.5), 0.8) * pow(1.0 - u, 0.9) * 1.5 + 0.004, col)
			var kind = rng.randf()
			if kind < 0.35:   # yan çatal: gövdeden ayrılan kısa sivri dil
				var fp: Array = []
				var ft = mid.x; var fa = mid.y
				var fdir = mid_th + (1.1 if rng.randf() < 0.5 else -1.1)
				for k in 8:
					fp.append(Vector2(ft, fa))
					fdir += 0.12 * signf(wav)
					ft += cos(fdir) * l * 0.045 / maxf(0.2, length)
					fa += sin(fdir) * l * 0.045 / maxf(0.2, radius(ft))
				ribbon(mb, fp, func(u: float) -> float: return ww * 0.7 * (1.0 - u) + 0.004, col)
			elif kind < 0.45:   # damla "göz": darbenin başında içi boş badem halka
				var lp: Array = []
				var e = path[0] as Vector2
				var rr = ww * 1.5
				for k in 15:
					var g = TAU * k / 14.0
					var ox = cos(g) * rr * 1.5 - rr * 1.2; var oy = sin(g) * rr * 0.8
					var dx = ox * cos(th) - oy * sin(th); var dy = ox * sin(th) + oy * cos(th)
					lp.append(Vector2(e.x + dx / maxf(0.2, length), e.y + dy / maxf(0.2, radius(e.x))))
				if not lp.any(func(q): return q.x < 0.01 or q.x > 0.99):
					ribbon(mb, lp, func(_u: float) -> float: return ww * 0.36, col)


## Kalın sarmal kıvrımlar (Matatabi siyah alev deseni): teğet bir kuyrukla girip içe sarılan fırça darbesi.
func swirl_marks(mb: MB, n_t: int, n_a: int, seed_v: int, col: Color, w: float, size: float, t0 := 0.04, t1 := 0.96, a0 := -PI, a1 := PI) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_v
	for it in n_t:
		for ia in n_a:
			var ct = lerpf(t0, t1, (it + rng.randf_range(0.2, 0.8)) / n_t)
			var ca = lerpf(a0, a1, (ia + rng.randf_range(0.2, 0.8) + (0.5 if it % 2 == 1 else 0.0)) / n_a)
			var R = size * rng.randf_range(0.65, 1.2)
			var ph0 = rng.randf_range(0.0, TAU)
			var hand = 1.0 if rng.randf() < 0.5 else -1.0
			var turns = rng.randf_range(2.0, 2.7) * PI
			var tail_l = R * rng.randf_range(1.6, 3.0)
			var wob = rng.randf_range(-0.5, 0.5) * R
			var ww = w * rng.randf_range(0.8, 1.25)
			var loc: Array = []   # yerel 2B (uzunluk birimi): x omurga boyunca, y çevre boyunca
			var p0 = Vector2(cos(ph0), sin(ph0)) * R
			var tg = Vector2(-sin(ph0), cos(ph0)) * hand
			for k in 10:
				var u = k / 10.0
				loc.append(p0 - tg * tail_l * (1.0 - u) + Vector2(cos(ph0), sin(ph0)) * wob * sin(u * PI))
			for k in 25:
				var u = k / 24.0
				var ph = ph0 + hand * turns * u
				loc.append(Vector2(cos(ph), sin(ph)) * R * (1.0 - 0.8 * u))
			var path: Array = []
			var ok = true
			for q in loc:
				var tt = ct + q.x / maxf(0.2, length)
				if tt < 0.005 or tt > 0.995:
					ok = false
					break
				path.append(Vector2(tt, ca + q.y / maxf(0.2, radius(tt))))
			if not ok:
				continue
			ribbon(mb, path, func(u: float) -> float: return ww * pow(minf(1.0, u * 4.0), 0.7) * (1.0 - 0.45 * u) * (1.0 if u < 0.97 else 0.5) + 0.004, col)
