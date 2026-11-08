## (yükleme: CharacterModel.AnimeHair = preload)
extends RefCounted
## Sıfırdan anime saçı (VRoid tabanı YOK; kullanıcı 2026-11-09: "iki saç üst üste gibi, sıfırdan yap").
## Yapı: (1) kafatasını saran kalın saç KÜTLESİ — saç çizgisi tırtıklı (uçlar sivri), alt kenarı içe kıvrık (kâğıt gibi
## ince görünmez); (2) kütlenin İÇİNDEN çıkan baklava kesitli, sivri uçlu, kavisli TUTAMLAR. Tutam kökü kütlenin içinde
## kalır: iki ayrı saç üst üste değil, tek bir saç kütlesi gibi okunur. Model uzayında üretilir (Head kemiğine bağlanır).
## Açı kuralı: yaw 0 = yüz (+Z), pitch 0 = tepe; c/r = kafatası elipsoidi (CharacterModel._measure_skull).

const STYLES := {"s2": "Dikenli Taç"}

static var _st: SurfaceTool
static var _c: Vector3
static var _r: Vector3
static var _rng: RandomNumberGenerator
static var _banded := false


static func has(style: String) -> bool:
	return STYLES.has(style)


## Elipsoit üstünde yön (birim) ve nokta
static func _dir(yaw_deg: float, pitch_deg: float) -> Vector3:
	var yw = deg_to_rad(yaw_deg); var pt = deg_to_rad(pitch_deg)
	return Vector3(sin(yw) * sin(pt), cos(pt), cos(yw) * sin(pt))


## Kafatası yarıçapı o yönde: alın elipsten düz ve öndedir (yüz parçası) — önde dışa şişirilir, yoksa ön saç alnın içinde kalır
static func _rr(d: Vector3) -> Vector3:
	var front = smoothstep(0.25, 0.85, d.z) * smoothstep(0.75, 0.2, d.y)
	return _r * (1.0 + 0.11 * front)


static func _surf(yaw_deg: float, pitch_deg: float, k := 1.0) -> Vector3:
	var d = _dir(yaw_deg, pitch_deg)
	return _c + d * _rr(d) * k


static func build(style: String, c: Vector3, r: Vector3, banded := false) -> ArrayMesh:
	_c = c; _r = r
	_banded = banded
	_rng = RandomNumberGenerator.new()
	_rng.seed = hash("anime|" + style)
	_st = SurfaceTool.new()
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_st.set_color(Color.WHITE)
	match style:
		"s2":
			_s2()
	_st.generate_normals()
	return _st.commit()


# ---------------------------------------------------------------- kütle
## Saç kütlesi: hairline(yaw) -> o yöndeki en alt pitch (saç çizgisi). off: kafatasından dışarı kalınlık
static func _mass(hairline: Callable, off: float, zig_deg := 4.0, zig_n := 26) -> void:
	var NY = 72; var NP = 16
	var outer = []; var inner = []
	for i in NY + 1:
		var yw = lerpf(-180.0, 180.0, float(i) / NY)
		# saç çizgisi tırtıklı: üçgen dalga (tutam uçları)
		var tri = absf(fposmod(float(i) / NY * zig_n, 1.0) - 0.5) * 2.0
		var hl: float = hairline.call(yw) + zig_deg * tri
		var ro = []; var ri = []
		for j in NP + 1:
			var pt = lerpf(0.0, hl, float(j) / NP)
			var d = _dir(yw, pt)
			var edge = float(j) / NP
			# kenara doğru kütle incelir (kalın kapak gibi değil, saç uçlarına iner)
			var o = off * (1.0 - 0.55 * pow(edge, 3.0))
			ro.append(_c + d * (_rr(d) + Vector3.ONE * o))
			ri.append(_c + d * (_rr(d) + Vector3.ONE * (o * 0.25)))
		outer.append(ro); inner.append(ri)
	for i in NY:
		for j in NP:
			_quad(outer[i][j], outer[i + 1][j], outer[i + 1][j + 1], outer[i][j + 1])
			_quad(inner[i][j + 1], inner[i + 1][j + 1], inner[i + 1][j], inner[i][j])   # iç yüz (ters)
		# alt kenar: dış ve iç yüzü birleştir (kalınlık)
		_quad(outer[i][NP], outer[i + 1][NP], inner[i + 1][NP], inner[i][NP])


## Godot ön yüzü saat yönünde: dışa bakan (sağ el) a-b-c-d dörtgeni ters sırayla yazılır
static func _quad(a: Vector3, b: Vector3, cc: Vector3, d: Vector3) -> void:
	_st.add_vertex(a); _st.add_vertex(cc); _st.add_vertex(b)
	_st.add_vertex(a); _st.add_vertex(d); _st.add_vertex(cc)


# ---------------------------------------------------------------- tutam
## Tutam: kökten (kütlenin içinde) çıkıp dir yönünde kavisle uzayan, baklava kesitli, sivri uçlu şerit.
## bend: uca doğru eklenen eğilme (yerçekimi / savrulma), width: kök genişliği, thick: kalınlık oranı
static func _lock(yaw: float, pitch: float, dir: Vector3, length: float, width: float, bend := Vector3.ZERO, thick := 0.38, root_k := 0.93) -> void:
	var p0 = _surf(yaw, pitch, root_k)
	var n0 = _dir(yaw, pitch)
	var d = dir.normalized()
	var p1 = p0 + (n0 * 0.5 + d * 0.5).normalized() * length * 0.35
	var p2 = p0 + d * length * 0.75 + bend * 0.6
	var p3 = p0 + d * length + bend
	var N = 10
	var rings = []
	var prev_side = Vector3.ZERO
	for k in N + 1:
		var u = float(k) / N
		var p = _bez(p0, p1, p2, p3, u)
		var tg = (_bez(p0, p1, p2, p3, minf(u + 0.02, 1.0)) - _bez(p0, p1, p2, p3, maxf(u - 0.02, 0.0))).normalized()
		var rad = (p - _c).normalized()
		var side = tg.cross(rad)
		if side.length() < 0.01:
			side = prev_side if prev_side != Vector3.ZERO else tg.cross(Vector3.UP)
		side = side.normalized()
		prev_side = side
		var up = side.cross(tg).normalized()   # dış yüz (kafadan dışarı)
		# genişlik: kökte dolgun, ortadan sonra sivrilir; uçta tek nokta
		var w = width * (1.0 - pow(u, 1.6)) * (0.85 + 0.15 * sin(minf(u * 3.0, 1.0) * PI * 0.5))
		var t = w * thick
		if k == N:
			rings.append([p, p, p, p])
		else:
			rings.append([p + side * w * 0.5, p + up * t * 0.5, p - side * w * 0.5, p - up * t * 0.3])
	for k in N:
		var A: Array = rings[k]; var B: Array = rings[k + 1]
		for e in 4:
			var f = (e + 1) % 4
			_quad(A[e], B[e], B[f], A[f])
	# kök kapağı (kütlenin içinde kalır ama açık delik olmasın)
	var R0: Array = rings[0]
	_st.add_vertex(R0[0]); _st.add_vertex(R0[2]); _st.add_vertex(R0[1])
	_st.add_vertex(R0[0]); _st.add_vertex(R0[3]); _st.add_vertex(R0[2])


static func _bez(a: Vector3, b: Vector3, cc: Vector3, d: Vector3, u: float) -> Vector3:
	var v = 1.0 - u
	return a * v * v * v + b * 3.0 * v * v * u + cc * 3.0 * v * u * u + d * u * u * u


## Yatık tutam: kafa yüzeyini izleyerek (yaw0,pitch0)'dan (yaw1,pitch1)'e akar, uca doğru yüzeyden hafif kalkar
## (kütleyi örter: arka/yan "kask" görünmesin). lift_tip: uçtaki kalkma (kafa yarıçapı oranı)
static func _flow(yaw0: float, pitch0: float, yaw1: float, pitch1: float, width: float, lift_tip := 0.12, thick := 0.32) -> void:
	var N = 10
	var pts = []
	for k in N + 1:
		var u = float(k) / N
		var yw = lerpf(yaw0, yaw1, u); var pt = lerpf(pitch0, pitch1, u)
		var lift = 0.03 + lift_tip * 0.1 * pow(u, 2.0)   # kütlenin (≈+2.2 cm) yüzeyinde, uca doğru kalkar
		var dd = _dir(yw, pt)
		pts.append(_c + dd * (_rr(dd) + Vector3.ONE * lift))
	_ribbon(pts, width, thick)


## Noktalar boyunca baklava kesitli, sivrilen şerit (tutam gövdesi)
static func _ribbon(pts: Array, width: float, thick: float) -> void:
	var N = pts.size() - 1
	var rings = []
	var prev_side = Vector3.ZERO
	for k in N + 1:
		var u = float(k) / N
		var p: Vector3 = pts[k]
		var tg: Vector3 = (pts[mini(k + 1, N)] - pts[maxi(k - 1, 0)]).normalized()
		var rad = (p - _c).normalized()
		var side = tg.cross(rad)
		if side.length() < 0.01:
			side = prev_side if prev_side != Vector3.ZERO else tg.cross(Vector3.UP)
		side = side.normalized()
		prev_side = side
		var up = side.cross(tg).normalized()
		var w = width * (1.0 - pow(u, 1.6)) * (0.85 + 0.15 * sin(minf(u * 3.0, 1.0) * PI * 0.5))
		var t = w * thick
		if k == N:
			rings.append([p, p, p, p])
		else:
			rings.append([p + side * w * 0.5, p + up * t * 0.5, p - side * w * 0.5, p - up * t * 0.3])
	for k in N:
		var A: Array = rings[k]; var B: Array = rings[k + 1]
		for e in 4:
			var f = (e + 1) % 4
			_quad(A[e], B[e], B[f], A[f])
	var R0: Array = rings[0]
	_st.add_vertex(R0[0]); _st.add_vertex(R0[2]); _st.add_vertex(R0[1])
	_st.add_vertex(R0[0]); _st.add_vertex(R0[3]); _st.add_vertex(R0[2])


# ---------------------------------------------------------------- stiller
## Striker 2 (refs/hair_ss/2.jpg): tepeden her yöne fışkıran iri sivri dikenler (taç), yanlarda dışa/arkaya
## çıkan dikenler, ensede aşağı-arkaya dikenler; alında bandın altından görünen kısa sivri kâküller.
static func _s2() -> void:
	# saç çizgisi: alında kaşların biraz üstü (kâküller kaşa iner), yanlarda kulak üstü, ensede boyun
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 96.0
		if a < 95.0:
			return lerpf(96.0, 100.0, (a - 45.0) / 50.0)
		return lerpf(100.0, 112.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.022)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	# TAÇ (ref 2.jpg): önden bakınca kafanın çevresinde güneş ışını gibi açılan iri, yassı, düzenli dikenler.
	# Taç düzlemi kulakların hafif arkası; ortadaki dik, yanlara doğru yataylaşır. İki sıra: ön sıra + arka sıra (hacim)
	for layer in [[0.0, 13, 0.15], [-0.35, 10, 0.13]]:
		var n_sp: int = layer[1]
		for k in n_sp:
			var th = lerpf(-98.0, 98.0, (k + 0.5) / n_sp) + j.call(3)   # 0 = tepe, ±90 = yan
			var thr = deg_to_rad(th)
			# kökün kafadaki yeri: taç düzleminde (x-y), biraz arkada
			var rd = Vector3(sin(thr), cos(thr), layer[0] - 0.15).normalized()
			var yw = rad_to_deg(atan2(rd.x, rd.z)); var pt = rad_to_deg(acos(clampf(rd.y, -1.0, 1.0)))
			var dir = Vector3(sin(thr) * 0.9, cos(thr) + 0.35, -0.22 + layer[0] * 0.5).normalized()
			var ln = layer[2] * (1.0 - 0.3 * absf(th) / 98.0) * _rng.randf_range(0.92, 1.08)
			_lock(yw, pt, dir, ln, 0.085, Vector3(sin(thr) * 0.01, -0.008, -0.01), 0.28)
	# arka: kat kat aşağı-arkaya bakan dikenler (üst kat kısa ve dışa, alt kat uzun ve aşağı)
	for row in [[60.0, 7, 0.11, 0.3], [84.0, 8, 0.1, 0.6], [102.0, 7, 0.09, 0.85]]:
		for k in row[1]:
			var yw = lerpf(105.0, 255.0, (k + 0.5) / row[1]) + row[0] * 0.4 + j.call(5)
			var wy = wrapf(yw, -180.0, 180.0)
			var pt = row[0] + j.call(4)
			var n = _dir(wy, pt)
			var dir = (n + Vector3(0, -row[3], 0) + Vector3(0, 0, -0.1)).normalized()
			_lock(wy, pt, dir, row[2] * _rng.randf_range(0.9, 1.1), 0.095, Vector3(0, -0.015, -0.008), 0.3)
	# yan örtü: kulak üstünü kaplayan, aşağı-arkaya akan yatık tutamlar
	for sx in [-1.0, 1.0]:
		for k in 4:
			var yw = sx * (58.0 + k * 14.0)
			_flow(yw, 55.0, yw + sx * 8.0, 104.0 + j.call(3), 0.085, 0.14)
		# favori: kulağın önünden çeneye inen sivri tutam (ref: sağda belirgin)
		_flow(sx * 70.0, 90.0, sx * 72.0, 125.0, 0.045, 0.04, 0.3)
	if _banded:
		# alın bandı takılı (ref 2.jpg): bandın hemen üstünden yukarı-öne kalkan dikenler; kâkül bandın altında kalır
		for k in 7:
			var u = (k + 0.5) / 7.0
			var yw = lerpf(-50.0, 50.0, u) + j.call(3)
			var pt = 62.0 + j.call(3)
			var n = _dir(yw, pt)
			var dir = (n * 0.5 + Vector3(signf(yw) * 0.15, 1.0, 0.25)).normalized()
			_lock(yw, pt, dir, 0.09 * _rng.randf_range(0.9, 1.1), 0.085, Vector3(0, -0.005, -0.01), 0.28)
		for k in 4:   # bandın altından kaşa sarkan kısa uçlar
			var yw = lerpf(-30.0, 30.0, (k + 0.5) / 4.0)
			_flow(yw, 92.0, yw, 104.0 + j.call(2), 0.06, 0.02, 0.28)
		return
	# kâkül: alnı örten, kaşa kadar inen geniş üçgenler (ortada uzun), arkasında ikinci kat
	for k in 6:
		var u = (k + 0.5) / 6.0
		var yw = lerpf(-44.0, 44.0, u) + j.call(3)
		var end_p = 103.0 - absf(u - 0.5) * 12.0 + j.call(2)
		_flow(yw, 50.0, yw * 1.08, end_p, 0.09, 0.06, 0.28)
	for k in 5:
		var yw = lerpf(-36.0, 36.0, (k + 0.5) / 5.0)
		_flow(yw, 40.0, yw * 1.12, 97.0 + j.call(3), 0.085, 0.1, 0.28)
