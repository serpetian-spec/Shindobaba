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
static var _grid := PackedFloat32Array()   # kafa yüzeyi ızgarası (CharacterModel._head_radial): yaw 10° x pitch 10°
static var _band_y := -INF
static var _band_drop := 0.0   # bant arkaya doğru iner (CharacterModel.BAND_DROP)   # model uzayı bant yüksekliği (takılıysa): o şeritteki saç kafaya sıkışır, bant ince kalır


static func has(style: String) -> bool:
	return STYLES.has(style)


## Elipsoit üstünde yön (birim) ve nokta
static func _dir(yaw_deg: float, pitch_deg: float) -> Vector3:
	var yw = deg_to_rad(yaw_deg); var pt = deg_to_rad(pitch_deg)
	return Vector3(sin(yw) * sin(pt), cos(pt), cos(yw) * sin(pt))


## Kafatası yarıçapı o yönde: alın elipsten düz ve öndedir (yüz parçası) — önde dışa şişirilir, yoksa ön saç alnın içinde kalır
static func _rr(d: Vector3) -> Vector3:
	var front = smoothstep(0.25, 0.85, d.z) * smoothstep(0.75, 0.2, d.y)
	var e = _r * (1.0 + 0.11 * front)
	var m = _grid_r(d)
	var el = (d * e).length()
	if m > el:
		e *= m / el   # gerçek kafa elipsoitten dışarıda (kafatası arkası): saç gerçek yüzeye oturur
	return e


## Izgaradan o yöndeki deri yarıçapı (komşu hücrelerle yumuşatılmış; boş hücre = 0)
static func _grid_r(d: Vector3) -> float:
	if _grid.is_empty():
		return 0.0
	var yw = rad_to_deg(atan2(d.x, d.z)); var pt = rad_to_deg(acos(clampf(d.y, -1.0, 1.0)))
	var fy = (yw + 180.0) / 10.0 - 0.5; var fp = pt / 10.0 - 0.5
	var y0 = int(floor(fy)); var p0 = int(floor(fp))
	var ty = fy - y0; var tp = fp - p0
	var acc = 0.0; var wsum = 0.0
	for a in 2:
		for b in 2:
			var iy = posmod(y0 + a, 36); var ip = clampi(p0 + b, 0, 18)
			var v = _grid[ip * 36 + iy]
			if v <= 0.0:
				continue
			var w = (ty if a == 1 else 1.0 - ty) * (tp if b == 1 else 1.0 - tp) + 0.001
			acc += v * w; wsum += w
	return acc / wsum if wsum > 0.0 else 0.0


static func _surf(yaw_deg: float, pitch_deg: float, k := 1.0) -> Vector3:
	var d = _dir(yaw_deg, pitch_deg)
	return _c + d * _rr(d) * k


static func build(style: String, c: Vector3, r: Vector3, banded := false, band_y := -INF, grid := PackedFloat32Array(), band_drop := 0.0) -> ArrayMesh:
	_c = c; _r = r
	_band_drop = band_drop
	_grid = grid
	_banded = banded
	_band_y = band_y if banded else -INF
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
	var NY = 96; var NP = 36   # bant kenarında düzgün çizgi için sık ızgara
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
			var oi = o * 0.25
			var py = (_c + d * _rr(d)).y
			var bh = _band_at(d)
			if _band_y > -INF:
				var dy = py - bh
				# bant şeridi: saç bandın içinde (alında elipsoit deriden dışarıda -> iyice içe). Üst kenardan HEMEN çıkar
				# (geç çıkarsa alında çıplak deri, erken çıkarsa bandın üstüne diş diş biner)
				var tb = (1.0 - smoothstep(0.006, 0.02, dy)) if dy > 0.0 else (1.0 - smoothstep(0.012, 0.028, -dy))
				o = lerpf(o, -0.025, tb); oi = lerpf(oi, -0.03, tb)   # elipsoit alında gerçek deriden dışarıda: iyice içe al
			ro.append(_c + d * (_rr(d) + Vector3.ONE * o))
			ri.append(_c + d * (_rr(d) + Vector3.ONE * oi))
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
static func _ribbon(pts: Array, width: float, thick: float, side_ref := Vector3.ZERO) -> void:
	var N = pts.size() - 1
	var rings = []
	var prev_side = Vector3.ZERO
	for k in N + 1:
		var u = float(k) / N
		var p: Vector3 = pts[k]
		var tg: Vector3 = (pts[mini(k + 1, N)] - pts[maxi(k - 1, 0)]).normalized()
		var rad = (p - _c).normalized()
		var side = tg.cross(rad)
		if side_ref != Vector3.ZERO:
			side = side_ref - tg * side_ref.dot(tg)   # diken: genişlik verilen yönde (önden/yandan yassı yüzü görünsün)
		if side.length() < 0.01:
			side = prev_side if prev_side != Vector3.ZERO else tg.cross(Vector3.UP)
		side = side.normalized()
		var up = side.cross(tg).normalized()
		if up.dot(rad) < 0.0:   # dış yüz hep kafadan dışarı: yoksa sarım ters döner, yüzler arkadan kesilir (görünmez diken)
			side = -side; up = -up
		prev_side = side
		var w = width * (1.0 - u)   # doğrusal: anime ucu iğne gibi sivri (eski pow eğrisi küt "kürek" yapıyordu)
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


## Diken (anime "shard"): kafatasının içinden çıkan, geniş tabanlı, YASSI, doğrusal sivrilen üçgen; ucu hafif kıvrık.
## Komşu dikenlerin tabanları üst üste biner -> tek parça tırtıklı saç kütlesi okunur (tek tek tüp değil).
## ln/width kafa yarıçapı (R) oranı; thick = kalınlık/genişlik
static func _shard(yaw: float, pitch: float, dir: Vector3, ln: float, width: float, thick := 0.4, bend := Vector3.ZERO) -> void:
	var R = (_r.x + _r.z) * 0.5
	var p0 = _surf(yaw, pitch, 0.9)
	var d = dir.normalized()
	var pts = []
	for k in 9:
		var u = k / 8.0
		pts.append(p0 + d * ln * R * u + bend * R * u * u)
	# genişlik meridyen yönünde (tepe->ense/yan): önden bakınca taç, yandan bakınca testere dişi okunur
	var mer = _dir(yaw, pitch + 2.0) - _dir(yaw, pitch - 2.0)
	if mer.length() < 0.001:
		mer = Vector3(cos(deg_to_rad(yaw)), 0, -sin(deg_to_rad(yaw)))
	_ribbon(pts, width * R, thick, mer.normalized())


## Tutam köküne bant şeridi denk geliyorsa (bant takılı) atla: bant çevresindeki saç bastırılmış kalmalı
static func _in_band(yaw: float, pitch: float, pad_lo := 0.04, pad_hi := 0.06) -> bool:   # pad_hi: geniş diken tabanı bandın üst kenarından taşmasın
	if _band_y == -INF:
		return false
	var y = _surf(yaw, pitch).y
	var bh = _band_at(_dir(yaw, pitch))
	return y > bh - pad_lo and y < bh + pad_hi


## Taç dikeni kökü bandın üst kenarının altında mı (bant takılı; içinde VEYA altında -> yukarı kaydırılmalı)
static func _under_band_top(yaw: float, pitch: float) -> bool:
	if _band_y == -INF:
		return false
	return _surf(yaw, pitch).y < _band_at(_dir(yaw, pitch)) + 0.075   # geniş diken tabanı (±4 cm) bandın üst kenarına diş gibi binmesin


## Bandın o yöndeki yüksekliği: önde _band_y, arkaya doğru _band_drop kadar iner
static func _band_at(d: Vector3) -> float:
	var h = Vector2(d.x, d.z)
	var zn = h.y / h.length() if h.length() > 0.001 else 0.0
	return _band_y - _band_drop * (1.0 - zn) * 0.5


# ---------------------------------------------------------------- stiller
## Saç 2 — Naruto tabanlı (wiki: "Hairstyle 2 (Based on Naruto Uzumaki)").
## Kaynaklar: refs/hair_ss/2.jpg (Striker, ön), refs/hair_naruto (anime yan/arka: n3, from_side #17/#19). Ortak tasarım:
##  - saç kafatasından en fazla ~0.6–0.7 R taşar (eski sürüm 1.5 R tepe = "kalın, uzun" reddi)
##  - geniş tabanlı, yassı, doğrusal sivrilen dikenler; önden güneş ışını gibi her yöne, yandan arkaya yatık
##  - ense: kısa, aşağı-arkaya; kulak önü kısa favori; bantsız: alna inen 3 büyük sivri kâkül
##  - bant: bant şeridindeki saç kafaya bastırılır, dikenler bandın HEMEN üstünden kalkar (bant ince kalır)
static func _s2() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 88.0
		if a < 95.0:
			return lerpf(88.0, 98.0, (a - 45.0) / 50.0)
		return lerpf(98.0, 112.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.012, 3.0)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var back = Vector3(0, 0, -1)
	# sıralar: [pitch, adet, uzunluk(R), genişlik(R), geriye yatma, yukarı eğilim]
	for row in [[6.0, 6, 0.72, 0.9, 0.4, 0.2], [28.0, 10, 0.82, 0.95, 0.3, 0.2], [52.0, 12, 0.95, 0.95, 0.12, 0.15], [74.0, 13, 0.88, 0.9, 0.08, 0.1]]:
		var n_sp: int = row[1]
		var off = _rng.randf_range(0.0, 360.0 / n_sp)
		for k in n_sp:
			var yw = wrapf(off + k * 360.0 / n_sp + j.call(6), -180.0, 180.0)
			var pt: float = row[0] + j.call(4)
			var front = absf(yw) < 40.0
			if row[0] >= 76.0 and absf(yw) < 50.0:
				continue   # alın: bantsızda kâkül, bantlıda bandın üstü sırası (aşağıda)
			while _under_band_top(yw, pt) and pt > 20.0:
				pt -= 3.0   # bant şeridine denk gelen kök bandın hemen üstüne çıkar (sıra atlanmaz, arka kel kalmaz)
			var n = _dir(yw, pt)
			var dir = n + back * float(row[4]) + Vector3.UP * float(row[5])
			var ln: float = row[2]
			if front:
				dir = n + Vector3.UP * 0.45   # önde: yukarı-öne kalkar (yüzün üstüne yatmaz)
			var bk = smoothstep(95.0, 150.0, absf(yw))   # arka: kafatası zaten büyük -> dikenler kafaya yatar (dışa fışkırırsa "uzaylı kafası")
			if bk > 0.0 and pt > 20.0:
				dir = dir.normalized().lerp((n * 0.6 + back * 0.5 + Vector3.UP * 0.25).normalized(), bk)   # arkaya-hafif yukarı: bandın üstünden aşağı sarkmaz
				ln *= lerpf(1.0, 0.6, bk)
			_shard(yw, pt, dir, ln * _rng.randf_range(0.9, 1.1), row[3], 0.4, Vector3(0, -0.06, -0.05))
	# yanlar (ref 2.jpg önden: bant hizasında yüzün iki yanına dışa açılan dikenler -> geniş güneş silueti)
	for sx in [-1.0, 1.0]:
		for k in 3:
			var yw = sx * (68.0 + k * 22.0 + j.call(4))
			var pt = 86.0 + j.call(3)
			while _under_band_top(yw, pt) and pt > 30.0:
				pt -= 3.0
			var n = _dir(yw, pt)
			_shard(yw, pt, n + Vector3(0, 0.3 - k * 0.08, 0) + back * 0.1, 1.0 * _rng.randf_range(0.9, 1.1), 0.9, 0.4, Vector3(0, -0.08, 0))
	# ense: kafaya yatık, aşağı inen kısa sivri uçlar (etek gibi dışa açılmaz)
	for k in 9:
		var yw = wrapf(lerpf(115.0, 245.0, (k + 0.5) / 9.0) + j.call(4), -180.0, 180.0)
		var p0 = 100.0 if not _in_band(yw, 100.0, 0.02, 0.02) else 108.0
		_flow(yw, p0, yw + j.call(4), 124.0 + j.call(3), 0.035, 0.03, 0.3)
	# favori: kulak önünde aşağı inen kısa sivri tutam
	for sx in [-1.0, 1.0]:
		_flow(sx * 72.0, 86.0, sx * 74.0, 118.0, 0.045, 0.04, 0.3)
	if _banded:
		# bandın hemen üstü: önde dik kalkan dikenler (ref 2.jpg: bandın üst kenarından taç başlar)
		for k in 7:
			var yw = lerpf(-60.0, 60.0, (k + 0.5) / 7.0) + j.call(3)
			var pt = 60.0
			while _under_band_top(yw, pt) and pt > 30.0:
				pt -= 3.0
			_shard(yw, pt, _dir(yw, pt) * 0.6 + Vector3(signf(yw) * 0.1, 1.0, 0.15), 0.6 * _rng.randf_range(0.9, 1.1), 0.5, 0.4, Vector3(0, 0, -0.05))
		return
	# bantsız: alna inen büyük sivri kâküller (anime: 3 ana uç + aralarda küçükler)
	for k in 5:
		var u = (k + 0.5) / 5.0
		var yw = lerpf(-40.0, 40.0, u) + j.call(2)
		var big = k % 2 == 0
		_flow(yw, 52.0, yw * 1.15, (104.0 if big else 96.0) + j.call(2), 0.12 if big else 0.09, 0.08, 0.32)
