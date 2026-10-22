class_name Loft
extends RefCounted
## Pürüzsüz organik gövde parçaları: eğri bir omurga boyunca değişken elips kesitli tüp (yumuşak normaller, yuvarlak uçlar).
## Kuyruklu canavarlar ve çağrı hayvanları bunu kullanır; ilkel küre yığınlarının yerini alır.
## pts: omurga kontrol noktaları, rad: her nokta için Vector2(yan yarıçap, dikey yarıçap) ya da float
## col: Color ya da her nokta için Color dizisi; col_fn(t, ang, side_dir) -> Color varsa desen boyar
## (t: 0 baş..1 son, ang: kesit açısı, 0 = yan, PI/2 = üst, -PI/2 = alt).


static func _cr(p0, p1, p2, p3, t: float):
	var t2 = t * t; var t3 = t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)


static func tube(mb: MB, pts: Array, rad: Array, col, seg := 16, sub := 4, cap_a := true, cap_b := true, col_fn := Callable(), up := Vector3.UP) -> void:
	var n = pts.size()
	if n < 2:
		return
	var R: Array = []
	for r in rad:
		R.append(r if r is Vector2 else Vector2(float(r), float(r)))
	var C: Array = []
	for i in n:
		C.append(col[i] if col is Array else col)
	# Catmull-Rom ile alt bölme
	var P: Array = []; var RR: Array = []; var CC: Array = []
	for i in n - 1:
		var p0 = pts[maxi(0, i - 1)]; var p1 = pts[i]; var p2 = pts[i + 1]; var p3 = pts[mini(n - 1, i + 2)]
		var r0 = R[maxi(0, i - 1)]; var r1 = R[i]; var r2 = R[i + 1]; var r3 = R[mini(n - 1, i + 2)]
		for s in sub:
			var t = float(s) / sub
			P.append(_cr(p0, p1, p2, p3, t))
			var rr: Vector2 = _cr(r0, r1, r2, r3, t)
			RR.append(Vector2(maxf(rr.x, 0.01), maxf(rr.y, 0.01)))
			CC.append((C[i] as Color).lerp(C[i + 1], t))
	P.append(pts[n - 1]); RR.append(R[n - 1]); CC.append(C[n - 1])
	var m = P.size()
	# uzunluk boyunca t
	var L = PackedFloat32Array(); L.resize(m)
	for i in range(1, m):
		L[i] = L[i - 1] + (P[i] - P[i - 1]).length()
	var total = maxf(L[m - 1], 0.0001)
	# çerçeveler (paralel taşıma)
	var T: Array = []
	for i in m:
		var a = P[maxi(0, i - 1)]; var b = P[mini(m - 1, i + 1)]
		var tt: Vector3 = b - a
		T.append(tt.normalized() if tt.length() > 1e-5 else Vector3.FORWARD)
	var side: Vector3 = up.cross(T[0])
	if side.length() < 0.1:
		side = Vector3.RIGHT.cross(T[0])
	side = side.normalized()
	var S: Array = []; var N: Array = []
	for i in m:
		if i > 0:
			var q = Quaternion(T[i - 1], T[i]) if T[i - 1].dot(T[i]) < 0.9999 else Quaternion.IDENTITY
			side = (q * side)
			side = (side - T[i] * side.dot(T[i])).normalized()
		S.append(side)
		N.append(T[i].cross(side).normalized())
	# halkalar: uçlara yuvarlak kubbe halkaları eklenir
	var rings: Array = []  # [merkez, side, nrm, rx, ry, col, t, tan]
	var capn = 4
	if cap_a:
		for k in range(capn, 0, -1):
			var f = float(k) / capn
			var sh = cos(f * PI * 0.5)
			var ex = sin(f * PI * 0.5)
			rings.append([P[0] - T[0] * RR[0].length() * 0.5 * ex, S[0], N[0], RR[0].x * sh, RR[0].y * sh, CC[0], 0.0, T[0]])
	for i in m:
		rings.append([P[i], S[i], N[i], RR[i].x, RR[i].y, CC[i], L[i] / total, T[i]])
	if cap_b:
		for k in range(1, capn + 1):
			var f = float(k) / capn
			var sh = cos(f * PI * 0.5)
			var ex = sin(f * PI * 0.5)
			rings.append([P[m - 1] + T[m - 1] * RR[m - 1].length() * 0.5 * ex, S[m - 1], N[m - 1], RR[m - 1].x * sh, RR[m - 1].y * sh, CC[m - 1], 1.0, T[m - 1]])
	var base = mb.verts.size()
	var has_fn = col_fn.is_valid()
	for ri in rings.size():
		var rg = rings[ri]
		var ctr: Vector3 = rg[0]; var sd: Vector3 = rg[1]; var nm: Vector3 = rg[2]
		var rx: float = rg[3]; var ry: float = rg[4]
		# uç kubbelerinde normal tanjanta doğru eğilir
		var cap_tilt = 0.0
		if ri < (capn if cap_a else 0):
			cap_tilt = -sin(float(capn - ri) / capn * PI * 0.5)
		elif cap_b and ri >= rings.size() - capn:
			cap_tilt = sin(float(ri - (rings.size() - capn - 1)) / capn * PI * 0.5)
		for j in seg + 1:
			var a = TAU * float(j) / seg
			var ca = cos(a); var sa = sin(a)
			var off = sd * ca * rx + nm * sa * ry
			var nrm = (sd * ca / maxf(rx, 0.001) + nm * sa / maxf(ry, 0.001)).normalized()
			if cap_tilt != 0.0:
				nrm = (nrm * (1.0 - absf(cap_tilt)) + (rg[7] as Vector3) * cap_tilt).normalized()
			mb.verts.append(ctr + off)
			mb.normals.append(nrm)
			var c: Color = rg[5]
			if has_fn:
				c = col_fn.call(float(rg[6]), wrapf(a, -PI, PI), sd * ca + nm * sa)
			mb.colors.append(c)
			mb.uvs.append(Vector2(float(j) / seg, float(rg[6])))
	var rs = seg + 1
	for ri in rings.size() - 1:
		for j in seg:
			var a0 = base + ri * rs + j
			var b0 = a0 + rs
			mb.idx.append_array([a0, b0, a0 + 1, a0 + 1, b0, b0 + 1])


## Kısa yol: iki/üç noktalı kas şişkinlikli uzuv
static func limb(mb: MB, a: Vector3, b: Vector3, ra: float, rb: float, col, seg := 12, bulge := 1.12) -> void:
	var mid = a.lerp(b, 0.45)
	tube(mb, [a, mid, b], [ra, (ra + rb) * 0.5 * bulge, rb], col, seg, 3, true, true)


## Elipsoid benzeri pürüzsüz gövde: merkez + eksen boyunca yarıçap profili
static func blob(mb: MB, center: Vector3, axis: Vector3, length: float, profile: Array, col, seg := 18, col_fn := Callable(), up := Vector3.UP) -> void:
	var pts: Array = []
	var n = profile.size()
	var ax = axis.normalized()
	for i in n:
		var t = float(i) / (n - 1)
		pts.append(center + ax * (t - 0.5) * length)
	tube(mb, pts, profile, col, seg, 3, true, true, col_fn, up)
