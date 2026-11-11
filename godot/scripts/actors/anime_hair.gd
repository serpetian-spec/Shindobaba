## (yükleme: CharacterModel.AnimeHair = preload)
extends RefCounted
## Sıfırdan anime saçı (VRoid tabanı YOK; kullanıcı 2026-11-09: "iki saç üst üste gibi, sıfırdan yap").
## Yapı: (1) kafatasını saran kalın saç KÜTLESİ — saç çizgisi tırtıklı (uçlar sivri), alt kenarı içe kıvrık (kâğıt gibi
## ince görünmez); (2) kütlenin İÇİNDEN çıkan baklava kesitli, sivri uçlu, kavisli TUTAMLAR. Tutam kökü kütlenin içinde
## kalır: iki ayrı saç üst üste değil, tek bir saç kütlesi gibi okunur. Model uzayında üretilir (Head kemiğine bağlanır).
## Açı kuralı: yaw 0 = yüz (+Z), pitch 0 = tepe; c/r = kafatası elipsoidi (CharacterModel._measure_skull).

const STYLES := {"s1": "Dağınık Diken", "s2": "Dikenli Taç", "s3": "Yatık Diken", "s4": "Alev Yelpaze", "s5": "Düz Kuyruk", "s6": "Örtük Kâkül", "s7": "Yan Alev", "s8": "Ananas Kuyruk", "s9": "Kâse Kesim", "s10": "Dikenli Yele", "s11": "Düz Kısa", "s12": "Sık Diken", "s13": "Kısa Kirpi", "s14": "Geri Diken", "s15": "Uzun Perde", "s16": "Ördek Kuyruğu", "s17": "Yan Tarama", "s18": "Dik Fırça", "s19": "Savruk Diken", "s20": "Katlı Uç", "s21": "Tepe Kuyruk", "s22": "Geri Tarama", "s23": "Kısa Geri", "s24": "Dağınık Kısa", "f1": "Yan Ayrık Kısa", "f2": "Uzun Düz", "f3": "Uzun Dağınık", "f4": "Prenses Kâkül", "f5": "Dalgalı Uzun", "f6": "Dikenli Kuyruk", "f7": "Yan Kâkül Kuyruk", "f8": "Çift Topuz", "f9": "Dörtlü Kuyruk", "f10": "Kabarık Bere", "f11": "Düz Kesik Kısa", "f12": "Kısa Prenses", "f13": "Bantlı Kısa", "f14": "Açık Alın Kısa", "f15": "Topuz Kâkül", "f16": "Uzun Ayrık", "f17": "Örtük Kısa", "f18": "Küçük Prenses", "f19": "Uzun Kuyruk", "f20": "Alçak Kuyruk", "f21": "Kâküllü Kısa", "f22": "Arka Topuz", "f23": "Yana Kısa", "f24": "Tepe Topuz", "d0": "Yele Diken", "d1": "Uzun Yılan", "d2": "Çift Alçak Kuyruk", "d3": "Dev Yele", "d4": "Dağınık Kirpi", "d5": "Uzun Orman", "d6": "Dik Geri", "d8": "Sarı Şimşek", "d9": "Sert Kısa", "d10": "Topuz Perde", "d11": "Uzun Açık", "d14": "Gezgin Kâkül", "d15": "Geri Uzun", "d16": "Örtük Kuyruk", "d17": "Parlak Kâse", "d18": "Topuz Örtük", "d20": "Kabarık Kısa", "d22": "Hokage Dikeni", "d23": "Uzun Ayrık Düz", "d24": "Açık Alın Uzun", "d25": "Kıvırcık Kısa", "d26": "Dik Kısa", "d27": "Sivri Kâkül", "d28": "Savaş Sonrası Bob", "d29": "Asimetrik Bob", "d30": "Omuz Düz", "d32": "Alçak Kuyruk Uzun", "d33": "Kadim Diken", "d34": "Altı Yol Yelesi", "d35": "Dört Tutam", "d36": "Genç Dik", "d37": "Çift Uzun Kuyruk", "d39": "Görev Uzun", "d40": "Yere Uzun", "d41": "Kıvrık Tepe", "d42": "Savruk Dağınık", "d43": "Kukla Bob", "d44": "Yan Geri", "d45": "Dağınık Örtük", "e0": "Ananas Topuz", "e2": "Akademi Düz", "e3": "ANBU Tutam", "e4": "Genç Diken", "e5": "Ördek Kuyruğu", "e6": "Geriye Taralı", "e7": "Topuz", "e8": "Uzun Ayrık Perde", "e9": "Kemik Ayrık", "e10": "Vahşi Diken", "e11": "Genin Düz", "e12": "Yan Kâkül Uzun", "e13": "Genç Yan Alev", "e14": "Genç Uzun", "e15": "Küçük Bob", "e22": "Geniş Alın Uzun", "e23": "Kabarık Örtük", "e26": "Kabarık Kısa Kâkül", "e27": "Kabarık Kâse", "e28": "Kâkül Kuyruk", "e29": "Yüksek Kuyruk", "e30": "Uzun Prenses", "e31": "Omuz Ayrık", "e32": "Kedi Kâse", "e33": "Patlayıcı Kuyruk", "e34": "Patlayıcı Tutam", "e35": "Köpük Örtük", "e36": "Dağınık Kısa"}

static var _st: SurfaceTool
static var _c: Vector3
static var _r: Vector3
static var _rng: RandomNumberGenerator
static var _banded := false
static var _grid := PackedFloat32Array()   # kafa yüzeyi ızgarası (CharacterModel._head_radial): yaw 10° x pitch 10°
static var _band_y := -INF
static var last_arrays: Array = []
static var strands: Array = []   # her tutamın orta çizgisi {pts, kind} — ikincil hareket (UV2.x = tutam no, kütle = -1)
static var _kind := "shard"
static var _flow_kind := "flow"
static var _taper := 1.0
static var _curtain_banded := false   # true: bantlıyken de perde (bandın altından düz dökülen uzun saç)
static var _lift0 := 0.014   # tutamın deriden taban uzaklığı (göz örten kâkülde göz/kirpik geometrisinin önünde kalsın diye büyür)   # >1: tutam uca kadar geniş kalır, en sonda sivrilir (göz örten kâkül perdesi)   # "lie": kafaya taranmış tutam (ikincil harekette sabit; salınırsa kafadan kalkar)
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


## Gerçek deri yarıçapı: ızgara (yüz + kafa + boyun) varsa o, yoksa elipsoit. Tutamlar bunu izler
## (elipsoit alında ve boyunda deriden dışarıda: perçem/ense tutamı havada kalıyordu)
static func _real_r(d: Vector3) -> float:
	var g = _grid_r(d)
	return g if g > 0.0 else (d * _rr(d)).length()


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
	strands = []
	_curtain_banded = false
	_lift0 = 0.014
	_taper = 1.0
	_st.set_uv2(Vector2(-1, 0))
	match style:
		"s1":
			_s1()
		"s2":
			_s2()
		"s3":
			_s3()
		"s4":
			_s4()
		"s5":
			_s5()
		"s6":
			_s6()
		"s7":
			_s7()
		"s8":
			_s8()
		"s9":
			_s9()
		"s10":
			_s10()
		"s11":
			_s11()
		"s12":
			_s12()
		"s13":
			_s13()
		"s14":
			_s14()
		"s15":
			_s15()
		"s16":
			_s16()
		"s17":
			_s17()
		"s18":
			_s18()
		"s19":
			_s19()
		"s20":
			_s20()
		"s21":
			_s21()
		"s22":
			_s22()
		"s23":
			_s23()
		"s24":
			_s24()
		"f1":
			_f1()
		"f2":
			_f2()
		"f3":
			_f3()
		"f4":
			_f4()
		"f5":
			_f5()
		"f6":
			_f6()
		"f7":
			_f7()
		"f8":
			_f8()
		"f9":
			_f9()
		"f10":
			_f10()
		"f11":
			_f11()
		"f12":
			_f12()
		"f13":
			_f13()
		"f14":
			_f14()
		"f15":
			_f15()
		"f16":
			_f16()
		"f17":
			_f17()
		"f18":
			_f18()
		"f19":
			_f19()
		"f20":
			_f20()
		"f21":
			_f21()
		"f22":
			_f22()
		"f23":
			_f23()
		"f24":
			_f24()
		"d0":
			_d0()
		"d1":
			_d1()
		"d2":
			_d2()
		"d3":
			_d3()
		"d4":
			_d4()
		"d5":
			_d5()
		"d6":
			_d6()
		"d8":
			_d8()
		"d9":
			_d9()
		"d10":
			_d10()
		"d11":
			_d11()
		"d14":
			_d14()
		"d15":
			_d15()
		"d16":
			_d16()
		"d17":
			_d17()
		"d18":
			_d18()
		"d20":
			_d20()
		"d22":
			_d22()
		"d23":
			_d23()
		"d24":
			_d24()
		"d25":
			_d25()
		"d26":
			_d26()
		"d27":
			_d27()
		"d28":
			_d28()
		"d29":
			_d29()
		"d30":
			_d30()
		"d32":
			_d32()
		"d33":
			_d33()
		"d34":
			_d34()
		"d35":
			_d35()
		"d36":
			_d36()
		"d37":
			_d37()
		"d39":
			_d39()
		"d40":
			_d40()
		"d41":
			_d41()
		"d42":
			_d42()
		"d43":
			_d43()
		"d44":
			_d44()
		"d45":
			_d45()
		"e0":
			_e0()
		"e2":
			_e2()
		"e3":
			_e3()
		"e4":
			_e4()
		"e5":
			_e5()
		"e6":
			_e6()
		"e7":
			_e7()
		"e8":
			_e8()
		"e9":
			_e9()
		"e10":
			_e10()
		"e11":
			_e11()
		"e12":
			_e12()
		"e13":
			_e13()
		"e14":
			_e14()
		"e15":
			_e15()
		"e22":
			_e22()
		"e23":
			_e23()
		"e26":
			_e26()
		"e27":
			_e27()
		"e28":
			_e28()
		"e29":
			_e29()
		"e30":
			_e30()
		"e31":
			_e31()
		"e32":
			_e32()
		"e33":
			_e33()
		"e34":
			_e34()
		"e35":
			_e35()
		"e36":
			_e36()
	_st.generate_normals()
	last_arrays = _st.commit_to_arrays()   # iş parçacığında GPU'dan geri okumadan sallanma paketi kurulsun
	var m = ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, last_arrays)
	return m


# ---------------------------------------------------------------- kütle
## Saç kütlesi: hairline(yaw) -> o yöndeki en alt pitch (saç çizgisi). off: kafatasından dışarı kalınlık
## curtain_p > 0: o pitch'in altında saç kafaya yapışmaz, en geniş yerinden SİLİNDİR gibi düz iner (kâse kesim: kulakları
## örten dikey yan perde, düz kâkül). thin_edge: kenara doğru incelme (0 = kenar kalın, kâse kesimin keskin alt kenarı)
## top_k < 1: tepede kütle incelir (kalınlık yanlara/ekvatora toplanır — kâse kesim tepede sivri çan olmasın)
static func _mass(hairline: Callable, off: float, zig_deg := 4.0, zig_n := 26, thin_edge := 0.55, curtain_p := 0.0, top_k := 1.0) -> void:
	var NY = 96; var NP = 36   # bant kenarında düzgün çizgi için sık ızgara
	var outer = []; var inner = []
	for i in NY + 1:
		var yw = lerpf(-180.0, 180.0, float(i) / NY)
		# saç çizgisi tırtıklı: üçgen dalga (tutam uçları)
		var tri = absf(fposmod(float(i) / NY * zig_n, 1.0) - 0.5) * 2.0
		var zz = zig_deg * (smoothstep(40.0, 90.0, absf(yw)) if _band_y > -INF else 1.0)   # bantlı: önde diş yok (bandın üstüne biner; alnı bant örter)
		var hl: float = hairline.call(yw) + zz * tri
		var ro = []; var ri = []
		for j in NP + 1:
			var pt = lerpf(0.0, hl, float(j) / NP)
			var d = _dir(yw, pt)
			var edge = float(j) / NP
			# kenara doğru kütle incelir (kalın kapak gibi değil, saç uçlarına iner)
			var o = off * (1.0 - thin_edge * pow(edge, 3.0)) * lerpf(top_k, 1.0, smoothstep(0.0, 70.0, pt))
			var oi = o * 0.25
			var py = (_c + d * _rr(d)).y
			var bh = _band_at(d)
			if _band_y > -INF:
				var dy = py - bh
				# bant şeridi: saç bandın içinde (alında elipsoit deriden dışarıda -> iyice içe). Üst kenardan HEMEN çıkar
				# (geç çıkarsa alında çıplak deri, erken çıkarsa bandın üstüne diş diş biner)
				var tb = (1.0 - smoothstep(0.006, 0.02, dy)) if dy > 0.0 else (1.0 - smoothstep(0.012, 0.028, -dy))
				o = lerpf(o, -0.025, tb); oi = lerpf(oi, -0.03, tb)   # elipsoit alında gerçek deriden dışarıda: iyice içe al
			var po = _c + d * (_rr(d) + Vector3.ONE * o)
			var pi = _c + d * (_rr(d) + Vector3.ONE * oi)
			if curtain_p > 0.0 and pt > curtain_p and (_band_y == -INF or (_curtain_banded and py < bh - 0.03)):   # bantlı: kısa saçta perde yok (mantar eteği), uzun düz saçta bandın altından
				# perde: yatayda en az, perde başlangıcındaki (en geniş) yarıçap kadar dışarıda kalır -> dikey düz iner
				var dr = _dir(yw, curtain_p)
				var pr = _c + dr * (_rr(dr) + Vector3.ONE * off)
				var rh = Vector2(pr.x - _c.x, pr.z - _c.z).length()
				var hz = Vector2(po.x - _c.x, po.z - _c.z)
				var hd = hz.normalized() if hz.length() > 0.001 else Vector2(sin(deg_to_rad(yw)), cos(deg_to_rad(yw)))
				if hz.length() < rh:
					po = Vector3(_c.x + hd.x * rh, po.y, _c.z + hd.y * rh)
				var hzi = Vector2(pi.x - _c.x, pi.z - _c.z)
				if hzi.length() < rh - 0.014:
					pi = Vector3(_c.x + hd.x * (rh - 0.014), pi.y, _c.z + hd.y * (rh - 0.014))
			ro.append(po)
			ri.append(pi)
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
	_kind = _flow_kind
	# bant takılıyken bandın altında biten KISA tutam (favori, yan tutam) bandın alt kenarından başlar: bant şeridinden
	# geçerse içeri basılıp altında kanca gibi dışa kıvrılıyordu. Uzun taranmış tutamlar (tepeden enseye) dokunulmaz
	if _band_y > -INF and pitch1 - pitch0 < 50.0:
		var de = _dir(yaw1, pitch1)
		if (_c + de * _real_r(de)).y < _band_at(de) - 0.026:
			var ps = _start_below_band(yaw0, pitch0)
			if ps > pitch1 - 30.0:
				return   # bandın altında çok kısa kalan tutam: yüz kenarında kanca/buruşuk parça olur, çizilmez
			pitch0 = ps
	var N = 10
	var pts = []
	for k in N + 1:
		var u = float(k) / N
		var yw = lerpf(yaw0, yaw1, u); var pt = lerpf(pitch0, pitch1, u)
		var lift = _lift0 + lift_tip * 0.04 * pow(u, 2.0)   # kütle (1.2 cm) üstünde, deriye yatık; ucu çok az kalkar (eski 3 cm = havada uçan perçem)
		var dd = _dir(yw, pt)
		var rr = _real_r(dd) + lift
		if _band_y > -INF:
			var dy = (_c + dd * _real_r(dd)).y - _band_at(dd)
			if dy > -0.024 and dy < 0.02:
				rr = _real_r(dd) - 0.004   # bant şeridinden geçen tutam bandın ALTINDA (üstünden geçip bandı örtmesin)
		pts.append(_c + dd * rr)
	_ribbon(pts, width, thick)
	_kind = "shard"


## Noktalar boyunca baklava kesitli, sivrilen şerit (tutam gövdesi)
static func _ribbon(pts: Array, width: float, thick: float, side_ref := Vector3.ZERO) -> void:
	strands.append({"pts": PackedVector3Array(pts), "kind": _kind})
	_st.set_uv2(Vector2(strands.size() - 1, 0))
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
		var w = width * (1.0 - pow(u, _taper))   # taper 1: doğrusal, iğne gibi sivri; perde kâkülde uca kadar geniş
		if _kind != "shard" and width > 0.07:
			w *= lerpf(0.35, 1.0, smoothstep(0.0, 0.35, u))   # geniş akan tutamın kökü dar: düz kesit kavisli kafada kenarlarından kalkıp "tahta/torba" olmasın
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
	_st.set_uv2(Vector2(-1, 0))


## Diken (anime "shard"): kafatasının içinden çıkan, geniş tabanlı, YASSI, doğrusal sivrilen üçgen; ucu hafif kıvrık.
## Komşu dikenlerin tabanları üst üste biner -> tek parça tırtıklı saç kütlesi okunur (tek tek tüp değil).
## ln/width kafa yarıçapı (R) oranı; thick = kalınlık/genişlik
static func _shard(yaw: float, pitch: float, dir: Vector3, ln: float, width: float, thick := 0.4, bend := Vector3.ZERO) -> void:
	var R = (_r.x + _r.z) * 0.5
	var p0 = _c + _dir(yaw, pitch) * (_real_r(_dir(yaw, pitch)) * 0.97)   # kök gerçek derinin hemen altında (derin gömülürse görünen diken kısalır)
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


## Bant takılıysa: tutam kökünü bandın ALT kenarının hemen altına indirir (yüzü çerçeveleyen tutam/kâkül bandın içinden
## geçip altında kırılarak dışa fırlamasın — "örümcek bacağı")
static func _start_below_band(yaw: float, pitch: float) -> float:
	if _band_y == -INF:
		return pitch
	var pt = pitch
	while pt < 160.0 and (_c + _dir(yaw, pt) * _real_r(_dir(yaw, pt))).y > _band_at(_dir(yaw, pt)) - 0.026:
		pt += 2.0
	return pt


## Bant takılıysa: kökü bandın ÜST kenarının üstüne taşır (bandın üstünden geçen taranmış tutam bandı örtmesin)
static func _start_above_band(yaw: float, pitch: float) -> float:
	if _band_y == -INF:
		return pitch
	var pt = pitch
	while pt > 10.0 and (_c + _dir(yaw, pt) * _real_r(_dir(yaw, pt))).y < _band_at(_dir(yaw, pt)) + 0.028:
		pt -= 2.0
	return pt


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
				dir = dir.normalized().lerp((n * 0.75 + back * 0.5 + Vector3.UP * 0.2).normalized(), bk)   # arkaya-dışa, hafif yukarı: bandın altına sarkmaz
				ln *= lerpf(1.0, 1.15, bk)   # kafatası arkası büyük (yetişkin ~0.15 m): kısa diken kütleye gömülür, kel yumurta kalır
			if pt < 40.0:
				# tepe (anime tepeden: yıldız silueti): dikenler tepe girdabından her yöne YATARAK açılır; dik dursa yukarıdan
				# yalnız uçları görünür, kenarda kısa dikenli kel kubbe kalır (oyun kamerası şikâyeti)
				var hz = Vector3(sin(deg_to_rad(yw)), 0, cos(deg_to_rad(yw)))
				dir = hz * 0.85 + Vector3.UP * 0.4 + back * 0.2
			_shard(yw, pt, dir, ln * _rng.randf_range(0.9, 1.1), row[3], 0.4, Vector3(0, -0.06, -0.05))
	# arka ek sıra (anime arkadan: ense üstüne kadar baştan sona dikenli; arka yarı ön yarıdan seyrek kalmasın)
	for k in 9:
		var yw = wrapf(lerpf(100.0, 260.0, (k + 0.5) / 9.0) + j.call(6), -180.0, 180.0)
		var pt = 64.0 + j.call(8)
		while _under_band_top(yw, pt) and pt > 20.0:
			pt -= 3.0
		var n = _dir(yw, pt)
		_shard(yw, pt, n * 0.75 + back * 0.5 + Vector3.UP * 0.1, 0.9 * _rng.randf_range(0.9, 1.1), 0.9, 0.4, Vector3(0, -0.05, -0.03))
	# yanlar (ref 2.jpg önden: bant hizasında yüzün iki yanına dışa açılan dikenler -> geniş güneş silueti)
	for sx in [-1.0, 1.0]:
		for k in 3:
			var yw = sx * (68.0 + k * 22.0 + j.call(4))
			var pt = 86.0 + j.call(3)
			while _under_band_top(yw, pt) and pt > 30.0:
				pt -= 3.0
			var n = _dir(yw, pt)
			_shard(yw, pt, n + Vector3(0, 0.3 - k * 0.08, 0) + back * 0.1, 1.0 * _rng.randf_range(0.9, 1.1), 0.9, 0.4, Vector3(0, -0.08, 0))
	# ense (anime arkadan): birkaç geniş, boyları karışık sivri uç boyuna iner; eşit dişli tek sıra "yaka/etek" gibi durur
	for k in 6:
		var yw = wrapf(lerpf(125.0, 235.0, (k + 0.5) / 6.0) + j.call(5), -180.0, 180.0)
		var p0 = 96.0
		while _in_band(yw, p0, 0.02, 0.02) and p0 < 120.0:
			p0 += 3.0
		var end_p = (138.0 if k % 2 == 0 else 126.0) + j.call(4)
		_flow(yw, p0, yw + j.call(4), end_p, 0.06, 0.0, 0.3)
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


## Saç 1 — Kiba tabanlı (wiki: "Hairstyle 1 (Based on Kiba Inuzuka)").
## Kaynaklar: refs/hair_ss/1.jpg (Striker ön), refs/hair_kiba (anime 3/4, yan), refs/hair_naruto/p2/inuzuka_kiba_profile (profil). Ortak tasarım:
##  - Naruto'dan KISA (≈0.45 R) ve DAĞINIK dikenler: çok sayıda, yönleri düzensiz; tepe gür, yuvarlakça (sivri taç değil)
##  - şakaktan kulak önüne inen kısa favoriler; ense dolu, kulak arkasından boyuna inen kısa sivri tutamlar
##  - bantsız: alnın ortasına inen kısa dağınık kâküller; bant: s2 ile aynı kural (şerit bastırılır, kökler üst kenarın üstünde)
static func _s1() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 86.0
		if a < 95.0:
			return lerpf(86.0, 100.0, (a - 45.0) / 50.0)
		return lerpf(100.0, 116.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.012, 3.0, 34)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var back = Vector3(0, 0, -1)
	# dağınık taç: [pitch, adet, uzunluk(R), genişlik(R)] — Naruto'dan kısa (0.6–0.7 R), sayıca çok, yönleri düzensiz
	for row in [[6.0, 7, 0.6, 0.7], [26.0, 12, 0.68, 0.72], [46.0, 14, 0.7, 0.7], [66.0, 15, 0.66, 0.66], [84.0, 12, 0.6, 0.62]]:
		var n_sp: int = row[1]
		var off = _rng.randf_range(0.0, 360.0 / n_sp)
		for k in n_sp:
			var yw = wrapf(off + k * 360.0 / n_sp + j.call(10), -180.0, 180.0)
			var pt: float = row[0] + j.call(7)
			if row[0] >= 66.0 and absf(yw) < 45.0:
				continue   # alın: kâkül / bant üstü sırası aşağıda
			while _under_band_top(yw, pt) and pt > 15.0:
				pt -= 3.0
			var n = _dir(yw, pt)
			var dir = n + Vector3(j.call(0.35), 0.15 + j.call(0.2), j.call(0.35)) + back * 0.15   # dağınık
			var bk = smoothstep(95.0, 150.0, absf(yw))
			if bk > 0.0 and pt > 20.0:
				dir = dir.normalized().lerp((n * 0.75 + back * 0.5 + Vector3.UP * 0.15).normalized(), bk)   # arkaya-dışa, tam boy
			if pt < 40.0:
				var hz = Vector3(sin(deg_to_rad(yw)), 0, cos(deg_to_rad(yw)))
				dir = hz * 0.85 + Vector3.UP * 0.45 + back * 0.2 + Vector3(j.call(0.2), 0, j.call(0.2))   # tepe: yıldız (tepeden bakış)
			_shard(yw, pt, dir, row[2] * _rng.randf_range(0.8, 1.2), row[3] * _rng.randf_range(0.85, 1.1), 0.4, Vector3(j.call(0.05), -0.05, -0.03))
	# arka ek sıra: ense üstüne kadar dikenli
	for k in 9:
		var yw = wrapf(lerpf(100.0, 260.0, (k + 0.5) / 9.0) + j.call(8), -180.0, 180.0)
		var pt = 70.0 + j.call(8)
		while _under_band_top(yw, pt) and pt > 20.0:
			pt -= 3.0
		var n = _dir(yw, pt)
		_shard(yw, pt, n * 0.75 + back * 0.5 + Vector3(j.call(0.2), 0.05, 0), 0.72 * _rng.randf_range(0.85, 1.15), 0.75, 0.4, Vector3(0, -0.05, -0.03))
	# favori: şakaktan kulak önüne (deriye yatık)
	for sx in [-1.0, 1.0]:
		_flow(sx * 70.0, 84.0, sx * 73.0, 114.0, 0.04, 0.0, 0.3)
		_flow(sx * 80.0, 86.0, sx * 84.0, 108.0, 0.035, 0.0, 0.3)
	# ense: boyları karışık sivri uçlar yakaya kadar (eşit sıra = yaka/etek)
	for k in 7:
		var yw = wrapf(lerpf(118.0, 242.0, (k + 0.5) / 7.0) + j.call(5), -180.0, 180.0)
		var p0 = 98.0
		while _in_band(yw, p0, 0.02, 0.02) and p0 < 120.0:
			p0 += 3.0
		_flow(yw, p0, yw + j.call(5), (140.0 if k % 2 == 0 else 128.0) + j.call(4), 0.055, 0.0, 0.3)
	if _banded:
		# bandın hemen üstü: kısa dağınık dikenler (yukarı, hafif öne/yana)
		for k in 9:
			var yw = lerpf(-60.0, 60.0, (k + 0.5) / 9.0) + j.call(4)
			var pt = 62.0
			while _under_band_top(yw, pt) and pt > 25.0:
				pt -= 3.0
			_shard(yw, pt, _dir(yw, pt) * 0.7 + Vector3(j.call(0.3), 1.0, 0.1), 0.58 * _rng.randf_range(0.85, 1.15), 0.6, 0.4, Vector3(0, 0, -0.04))
		return
	# bantsız: alnın ortasına inen kısa dağınık kâküller (deriye yatık)
	for k in 7:
		var u = (k + 0.5) / 7.0
		var yw = lerpf(-42.0, 42.0, u) + j.call(3)
		_flow(yw, 55.0, yw * 1.1 + j.call(6), 92.0 + j.call(5), 0.075, 0.02, 0.32)


## Saç 3 — Gaara tabanlı (wiki: "Hairstyle 3 (Based on Gaara)").
## Kaynaklar: refs/hair_ss/3.jpg (Striker ön), refs/hair_gaara (anime profil, yan, 3/4, üstten). Ortak tasarım:
##  - yuvarlak, toplu hacim (kalın kütle); kısa (≈0.5 R) dikenler dışa değil aşağı-arkaya YATIK, kenar tırtıklı
##  - önde asimetrik sivri kâküller (bir yan açık: alın görünür); yüzü çerçeveleyen yan tutamlar elmacığa kadar
##  - kulak arkasından boyuna sarkan tutam; ense yakaya kadar dikenli
static func _s3() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 84.0
		if a < 95.0:
			return lerpf(84.0, 100.0, (a - 45.0) / 50.0)
		return lerpf(100.0, 118.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.013, 3.0, 40)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var back = Vector3(0, 0, -1)
	# yatık dikenler: [pitch, adet, uzunluk(R), genişlik(R), yatıklık (0 dışa .. 1 yüzey boyunca aşağı)]
	for row in [[8.0, 7, 0.62, 0.72, 0.1], [28.0, 12, 0.7, 0.74, 0.22], [48.0, 14, 0.72, 0.72, 0.3], [68.0, 15, 0.66, 0.68, 0.35], [86.0, 13, 0.58, 0.62, 0.4]]:
		var n_sp: int = row[1]
		var off = _rng.randf_range(0.0, 360.0 / n_sp)
		for k in n_sp:
			var yw = wrapf(off + k * 360.0 / n_sp + j.call(9), -180.0, 180.0)
			var pt: float = row[0] + j.call(6)
			if row[0] >= 68.0 and absf(yw) < 50.0:
				continue   # alın: kâkül / bant üstü aşağıda
			while _under_band_top(yw, pt) and pt > 15.0:
				pt -= 3.0
			var n = _dir(yw, pt)
			var down = (_dir(yw, pt + 6.0) - _dir(yw, pt - 6.0)).normalized()   # yüzey boyunca aşağı (meridyen)
			var lie = float(row[4]) if not _banded or pt < 45.0 else 0.0   # bantlı: bandın hemen üstündeki diken aşağı yatarsa bandın üstüne diş diş biner
			var dir = n.lerp(down, lie) + back * 0.15 + Vector3(j.call(0.2), 0, j.call(0.2))
			if pt < 20.0:
				var hz = Vector3(sin(deg_to_rad(yw)), 0, cos(deg_to_rad(yw)))
				dir = hz * 0.8 + Vector3.UP * 0.5 + back * 0.2   # tepe: yıldız
			_shard(yw, pt, dir, row[2] * _rng.randf_range(0.85, 1.15), row[3] * _rng.randf_range(0.85, 1.1), 0.4, Vector3(0, -0.04, -0.02))
	# yüzü çerçeveleyen yan tutamlar (elmacığa kadar) + kulak arkasından boyuna sarkan tutam
	for sx in [-1.0, 1.0]:
		if not _banded:   # bantlı: bandın altından şakakta başlayan tutam göz kenarında parça gibi duruyordu
			_flow(sx * 58.0, 74.0, sx * 62.0, 124.0, 0.1, 0.0, 0.3)
			_flow(sx * 70.0, 78.0, sx * 75.0, 118.0, 0.09, 0.0, 0.3)
		# şakak: aşağı bakan sivri uçlar (Striker 3: yüzü çerçeveleyen koyu tutam demeti); bantlıyken bandın üstünden sarkıp kıvrılıyordu
		for k in (0 if _banded else 3):
			var yw = sx * (50.0 + k * 12.0)
			var pt = 72.0
			while _under_band_top(yw, pt) and pt > 40.0:
				pt -= 3.0
			var dn = (_dir(yw, pt + 6.0) - _dir(yw, pt - 6.0)).normalized()
			_shard(yw, pt, dn + _dir(yw, pt) * 0.35, 0.75, 0.6, 0.38)
		_flow(sx * 104.0, 92.0, sx * 108.0, 132.0, 0.05, 0.0, 0.3)
	# ense: boyları karışık sivri uçlar yakaya kadar
	for k in 7:
		var yw = wrapf(lerpf(122.0, 238.0, (k + 0.5) / 7.0) + j.call(5), -180.0, 180.0)
		var p0 = 98.0
		while _in_band(yw, p0, 0.02, 0.02) and p0 < 120.0:
			p0 += 3.0
		_flow(yw, p0, yw + j.call(5), (138.0 if k % 2 == 0 else 127.0) + j.call(4), 0.06, 0.0, 0.3)
	if _banded:
		# bandın hemen üstü: öne-yukarı hafif kalkan kısa yatık dikenler
		for k in 8:
			var yw = lerpf(-58.0, 58.0, (k + 0.5) / 8.0) + j.call(4)
			var pt = 62.0
			while _under_band_top(yw, pt) and pt > 25.0:
				pt -= 3.0
			_shard(yw, pt, _dir(yw, pt) * 0.8 + Vector3(j.call(0.2), 0.7, 0.2), 0.45 * _rng.randf_range(0.85, 1.15), 0.6, 0.4, Vector3(0, -0.03, 0))
		return
	# bantsız: asimetrik sivri kâküller (sağ yan kısa: alın görünür, sol uzun kaşa iner)
	for k in 6:
		var u = (k + 0.5) / 6.0
		var yw = lerpf(-46.0, 46.0, u) + j.call(3)
		var end_p = lerpf(100.0, 86.0, u) + j.call(3)
		_flow(yw, 54.0, yw * 1.1 + j.call(5), end_p, 0.085, 0.02, 0.32)


## Saç 4 — Konohamaru (BORUTO) tabanlı (wiki: "Hairstyle 4 (Based on Konohamaru Sarutobi (BORUTO))").
## Kaynaklar: refs/hair_ss/4.jpg (Striker ön), refs/hair_konohamaru (anime ön). Ortak tasarım:
##  - tepede AZ ve BÜYÜK, YUKARI kalkan dikenler (alev yelpazesi; Naruto gibi her yöne güneş değil), hafif bir yana ve arkaya yatık
##  - yanlar kulak üstünde kısa ve kafaya yakın; kâkül yok: saç alından yukarı kalkar
##  - arka dikenler arkaya-yukarı; ense kısa
static func _s4() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 82.0
		if a < 95.0:
			return lerpf(82.0, 98.0, (a - 45.0) / 50.0)
		return lerpf(98.0, 112.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.011, 3.0, 36)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var back = Vector3(0, 0, -1)
	var lean = Vector3(0.45, 0, 0)   # Striker 4: alev bir yana yatık
	# yelpaze: [pitch, adet, uzunluk(R), genişlik(R), yukarı ağırlığı]
	for row in [[6.0, 5, 1.0, 0.95, 1.0], [26.0, 8, 0.95, 0.95, 0.9], [46.0, 10, 0.8, 0.9, 0.7], [66.0, 11, 0.55, 0.75, 0.35], [84.0, 10, 0.4, 0.62, 0.0]]:
		var n_sp: int = row[1]
		var off = _rng.randf_range(0.0, 360.0 / n_sp)
		for k in n_sp:
			var yw = wrapf(off + k * 360.0 / n_sp + j.call(8), -180.0, 180.0)
			var pt: float = row[0] + j.call(5)
			if row[0] >= 66.0 and absf(yw) < 45.0:
				continue   # alın: ön sıra aşağıda
			while _under_band_top(yw, pt) and pt > 15.0:
				pt -= 3.0
			var n = _dir(yw, pt)
			var down = (_dir(yw, pt + 6.0) - _dir(yw, pt - 6.0)).normalized()
			var up_w: float = row[4]
			var dir: Vector3
			if row[0] >= 84.0 and absf(yw) > 110.0:
				continue   # arka alt sıra yok (ense tutamları var; burada halka/etek oluşuyordu)
			var hz = Vector3(sin(deg_to_rad(yw)), 0, cos(deg_to_rad(yw)))
			if up_w > 0.0:
				# yelpaze: yukarı + dışa açılır (yalnız yukarı = dar mohikan kulesi), bir yana yatık
				dir = Vector3.UP * up_w + hz * 0.6 + back * 0.2 + lean + Vector3(j.call(0.12), 0, j.call(0.12))
			else:
				dir = n * 0.5 + down * 0.6 + back * 0.3   # yan/alt: kısa, kafaya yakın, arkaya
			if absf(yw) > 120.0 and up_w > 0.0:
				dir += back * 0.35   # arka: arkaya-yukarı
			_shard(yw, pt, dir, row[2] * _rng.randf_range(0.85, 1.15), row[3] * _rng.randf_range(0.9, 1.1), 0.4, Vector3(0, -0.03, -0.04))
	# arka sıra: arkaya-yukarı bakan dikenler (arkadan bakınca kel kubbe kalmasın)
	for k in 9:
		var yw = wrapf(lerpf(100.0, 260.0, (k + 0.5) / 9.0) + j.call(8), -180.0, 180.0)
		var pt = 62.0 + j.call(8)
		while _under_band_top(yw, pt) and pt > 20.0:
			pt -= 3.0
		var n = _dir(yw, pt)
		_shard(yw, pt, n * 0.7 + back * 0.45 + Vector3.UP * 0.35 + lean * 0.5, 0.8 * _rng.randf_range(0.9, 1.1), 0.85, 0.4, Vector3(0, -0.03, -0.03))
	# ön sıra: alından/bandın üstünden yukarı-arkaya kalkan büyük dikenler (kâkül yok)
	for k in 5:
		var yw = lerpf(-48.0, 48.0, (k + 0.5) / 5.0) + j.call(4)
		var pt = 58.0
		while _under_band_top(yw, pt) and pt > 25.0:
			pt -= 3.0
		_shard(yw, pt, Vector3.UP + _dir(yw, pt) * 0.35 + back * 0.2 + lean, 0.85 * _rng.randf_range(0.9, 1.1), 0.9, 0.4, Vector3(0, -0.02, -0.05))
	# favori: kulak önünde kısa
	for sx in [-1.0, 1.0]:
		_flow(sx * 72.0, 84.0, sx * 74.0, 106.0, 0.04, 0.0, 0.3)
	# ense: tutam yerine dağınık kısa dikenler (eşit tutam sırası arkada yaka/diş gibi duruyordu — s7 dersi)
	for k in 8:
		var yw = wrapf(lerpf(110.0, 250.0, (k + 0.5) / 8.0) + j.call(10), -180.0, 180.0)
		var pt = 74.0 + _rng.randf_range(0.0, 22.0)
		if _under_band_top(yw, pt) or _in_band(yw, pt):
			continue
		var n = _dir(yw, pt)
		var dn = (_dir(yw, pt + 6.0) - _dir(yw, pt - 6.0)).normalized()
		_shard(yw, pt, n * 0.7 + dn * 0.4 + back * 0.2 + lean * 0.3, _rng.randf_range(0.4, 0.65), 0.7, 0.4)
	if not _banded:
		# bantsız: alın çizgisinde yukarı kalkan kısa uçlar (saç alından yukarı taranmış)
		for k in 6:
			var yw = lerpf(-44.0, 44.0, (k + 0.5) / 6.0) + j.call(3)
			_shard(yw, 74.0, Vector3.UP * 0.8 + _dir(yw, 74.0) * 0.5 + back * 0.1, 0.55, 0.7, 0.4, Vector3(0, 0, -0.03))


## Saç 5 — Kabuto tabanlı (wiki: "Hairstyle 5 (Based on Kabuto Yakushi)").
## Kaynaklar: refs/hair_ss/5.jpg (Striker ön), refs/hair_kabuto (anime 3/4, yan, arkadan 3/4). Ortak tasarım:
##  - dikensiz, düz, kafaya yatık saç; tepeden ensedeki bağa taranmış
##  - ortadan ayrılan uzun kâküller göz hizasına; yüzü çerçeveleyen yan tutamlar çeneye kadar
##  - ensede kısa alçak at kuyruğu: 3-4 sivri uca açılır, arkaya-aşağı
static func _s5() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 82.0
		if a < 95.0:
			return lerpf(82.0, 102.0, (a - 45.0) / 50.0)
		return lerpf(102.0, 114.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.014, 2.0, 48)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var tie_p = 104.0   # at kuyruğu bağı (ense, arka orta)
	_flow_kind = "lie"   # taranmış tutamlar sabit
	# tepeden ense bağına taranmış tutamlar (kütleyi örter, düz parlak yüzey + ince tutam çizgileri)
	for k in 12:
		var yw0 = lerpf(-150.0, 150.0, (k + 0.5) / 12.0) + j.call(4)
		var p0 = 30.0 + j.call(8)
		var yw1 = 180.0 * signf(yw0) - signf(yw0) * (8.0 + j.call(4))
		_flow(yw0, p0, yw1, tie_p - 4.0 + j.call(3), 0.095, (k % 3) * 0.04, 0.2)   # kademeli yükseklik: üst üste binen tutamlar çakışıp buruşmasın
	# yanlar: kulak üstünden arkaya taranan tutamlar
	for sx in [-1.0, 1.0]:
		for k in 3:
			_flow(sx * (58.0 + k * 14.0), 62.0 + k * 6.0, sx * (160.0 + k * 4.0), tie_p, 0.065, 0.0, 0.25)
	_flow_kind = "flow"
	# yüzü çerçeveleyen yan tutamlar: çeneye kadar
	for sx in [-1.0, 1.0]:
		if _banded:
			# bant alnı kapatır: yüz çerçevesi şakak/kulak önünden bandın altından çıkar (yanağa yapışık plaka olmasın)
			pass   # bantlı: yüz çerçevesi yok (bandın altından başlayan kısa tutam göz kenarında kama gibi duruyordu)
		else:
			_flow(sx * 50.0, 62.0, sx * 60.0, 150.0, 0.085, 0.0, 0.3)   # çene hizası (kafatası merkezinden ≈150°)
			_flow(sx * 62.0, 68.0, sx * 72.0, 142.0, 0.08, 0.0, 0.3)
			_flow(sx * 76.0, 76.0, sx * 84.0, 128.0, 0.065, 0.0, 0.3)
	# kâkül: ortadan ayrık, göz hizasına inen uzun sivri tutamlar
	for sx in [-1.0, 1.0]:
		if _banded:
			continue   # bantlı: kâkül bandın altında kalır (yüze inen tutam göz çevresinde buruşuyordu)
		for k in 3:
			var yw = sx * (8.0 + k * 13.0) + j.call(2)
			_flow(yw, 38.0, yw + sx * 8.0, 122.0 - k * 5.0 + j.call(2), 0.09, 0.02, 0.3)   # göz hizasına
	# at kuyruğu: bağdan arkaya-aşağı açılan 4 sivri uç (ikincil hareketli)
	var tie = _c + _dir(180.0, tie_p) * (_real_r(_dir(180.0, tie_p)) + 0.01)
	for k in 4:
		var sp = (k - 1.5) * 0.35
		var d0 = Vector3(sp * 0.5, -0.55 + j.call(0.1), -1.0).normalized()
		var L = 0.11 + j.call(0.02)
		var pts = []
		for q in 9:
			var u = q / 8.0
			pts.append(tie + d0 * L * u + Vector3(sp * 0.03 * u, -0.05 * u * u, 0))
		_kind = "flow"
		_ribbon(pts, 0.045, 0.45)
		_kind = "shard"
	# bağ: küçük koyu halka yerine kuyruğun kökünde kalın düğüm
	var knot = []
	for q in 5:
		knot.append(tie + Vector3(0, 0, -0.012 * q / 4.0))
	_ribbon(knot, 0.05, 0.9)


## Saç 6 — Sasuke (BORUTO) tabanlı (wiki: "Hairstyle 6 (Based on Sasuke Uchiha (BORUTO))").
## Kaynaklar: refs/hair_ss/6.jpg (Striker ön), refs/hair_sasuke_b (anime ön, yan, arka, 3/4). Ortak tasarım:
##  - orta boy düz koyu saç, yuvarlak küt kesim; tepe düzgün, uçlar katlı-sivri
##  - BÜYÜK asimetrik kâkül bir gözü örter, yanağa iner; diğer yan kaşa kadar
##  - yan tutamlar çene/boyuna, kulakları yarı örter; arka enseye kadar, uçlar aşağı sivri
static func _s6() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 80.0
		if a < 95.0:
			return lerpf(80.0, 110.0, (a - 45.0) / 50.0)
		return lerpf(110.0, 124.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.007, 2.0, 48, 0.55, 0.0, 0.4)   # ince: tepede "torba" gibi şişmesin (kullanıcı şikâyeti)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var cover = 1.0   # örtülen göz tarafı (+yaw = önden bakınca görüntünün sağı; Striker 6)
	# tepeden aşağı dökülen düz tutamlar (kafaya yatık, sabit)
	_flow_kind = "lie"
	_lift0 = 0.008
	for k in 16:
		var yw = lerpf(-160.0, 160.0, (k + 0.5) / 16.0) + j.call(4)
		if absf(yw) < 40.0:
			continue
		_flow(yw * 0.5, 12.0 + j.call(5), yw, float(hl.call(yw)) + 2.0, 0.11, (k % 3) * 0.02, 0.14)
	_lift0 = 0.014
	_flow_kind = "flow"
	# arka katlar (anime arkadan): aşağı yatık sivri katlar — düz kâse gibi durmasın
	for row in [[55.0, 9], [80.0, 10]]:
		for k in row[1]:
			var yw = wrapf(lerpf(95.0, 265.0, (k + 0.5) / row[1]) + j.call(6), -180.0, 180.0)
			var pt = float(row[0]) + j.call(6)
			while _under_band_top(yw, pt) and pt > 20.0:
				pt -= 3.0
			var n = _dir(yw, pt)
			var dn = (_dir(yw, pt + 6.0) - _dir(yw, pt - 6.0)).normalized()
			_shard(yw, pt, dn + n * (0.3 if not _banded else 0.7), 0.55 * _rng.randf_range(0.85, 1.15), 0.7, 0.3)
	# uçlar: saç çizgisinde aşağı inen katlı sivri uçlar (salınır)
	for k in 14:
		var yw = lerpf(-170.0, 170.0, (k + 0.5) / 14.0) + j.call(5)
		if absf(yw) < 50.0:
			continue
		var h = float(hl.call(yw))
		_flow(yw, h - 16.0, yw + j.call(4), h + 14.0 + j.call(5), 0.065, 0.02, 0.3)
	if not _banded:
		# yan tutamlar: çene/boyun hizasına
		for sx in [-1.0, 1.0]:
			_flow(sx * 56.0, 66.0, sx * 62.0, 156.0, 0.09, 0.0, 0.3)   # ref: açık yandaki uzun tutam çenenin altına
			_flow(sx * 70.0, 74.0, sx * 76.0, 146.0, 0.08, 0.0, 0.3)
		# büyük örtücü kâkül: tepeden bir gözün üstünden yanağa
		# kâkül (Striker 6 tutam tutam): ayrı sivri tutamlar, araları açık (düz duvar değil). Kökler tepenin öbür yanında, çapraz iner.
		#  A orta: ince uzun, burnun yanından çeneye   B göz: geniş, gözü örter, elmacıkta biter
		#  C, D: örtülen yanda aşağı-DIŞA açılır, çene altına   E: kulak önü, dışa taşar
		_taper = 1.6
		_lift0 = 0.009   # kökte deriye yakın (tepede "torba" olmasın); göz hizasına doğru uç kalkar (lift_tip)
		for t in [[-2.0, 160.0, 0.07, 0.1], [18.0, 138.0, 0.19, 0.1], [8.0, 130.0, 0.1, 0.08], [42.0, 150.0, 0.11, 0.6], [62.0, 158.0, 0.1, 0.9], [82.0, 150.0, 0.09, 0.9]]:
			var ye = cover * float(t[0])
			_flow(-cover * 22.0 + ye * 0.45, 16.0 + absf(float(t[0])) * 0.15, ye, float(t[1]) + j.call(2), float(t[2]), maxf(float(t[3]), 0.5), 0.3)   # uç ~+2 cm: kirpiğin önünde
		# A ile B arası ve B üstü dolgu: tepeden göze kısa geniş tutamlar (alın açık kalmasın)
		_flow(-cover * 10.0, 20.0, cover * 8.0, 112.0, 0.12, 0.4, 0.3)
		_flow(cover * 8.0, 22.0, cover * 30.0, 118.0, 0.12, 0.4, 0.3)
		_taper = 1.0
		_lift0 = 0.014
		# diğer yan: kaşa kadar kısa kâküller
		for k in 3:
			var yw = -cover * (16.0 + k * 12.0)
			_flow(yw, 36.0, yw - cover * 6.0, 100.0 + k * 4.0 + j.call(2), 0.085, 0.02, 0.3)
	else:
		# bantlı: bandın üstünde düz saç; örtücü kâkül bandın üstünden tek büyük tutam olarak bir gözün üstüne
		_flow(cover * 10.0, 26.0, cover * 24.0, 70.0, 0.12, 0.05, 0.3)


## Saç 7 — Kakashi tabanlı (wiki: "Hairstyle 7 (Based on Kakashi Hatake)").
## Kaynaklar: refs/hair_ss/7.jpg (Striker ön), refs/hair_kakashi (anime arkadan, yandan, 3/4). Ortak tasarım:
##  - büyük, gür, yerçekimine meydan okuyan diken kütlesi; hepsi YUKARI ve TEK YANA (Striker: görüntünün solu = -x) savrulmuş alev
##  - Konohamaru'dan çok daha fazla/uzun diken, yana yatıklık güçlü; arkadan dikenler yukarı-dışa açılır
##  - ense kısa, bandın altında saç kafaya yakın; bantsız: alına birkaç kısa sivri uç
static func _s7() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 82.0
		if a < 95.0:
			return lerpf(82.0, 98.0, (a - 45.0) / 50.0)
		return lerpf(98.0, 112.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.012, 3.0, 36)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var back = Vector3(0, 0, -1)
	var lean = Vector3(-0.95, 0, 0)   # tek yana savrulma (önden görüntünün solu)
	# [pitch, adet, uzunluk(R), genişlik(R), yukarı ağırlığı]
	for row in [[6.0, 6, 1.05, 0.95, 1.0], [26.0, 11, 1.05, 0.95, 0.9], [46.0, 13, 0.95, 0.9, 0.75], [66.0, 13, 0.75, 0.8, 0.5], [84.0, 11, 0.45, 0.62, 0.0]]:
		var n_sp: int = row[1]
		var off = _rng.randf_range(0.0, 360.0 / n_sp)
		for k in n_sp:
			var yw = wrapf(off + k * 360.0 / n_sp + j.call(8), -180.0, 180.0)
			var pt: float = row[0] + j.call(5)
			if row[0] >= 66.0 and absf(yw) < 45.0:
				continue
			if row[0] >= 84.0 and absf(yw) > 110.0:
				continue   # arka alt: ense tutamları (halka/etek olmasın)
			while _under_band_top(yw, pt) and pt > 15.0:
				pt -= 3.0
			var n = _dir(yw, pt)
			var hz = Vector3(sin(deg_to_rad(yw)), 0, cos(deg_to_rad(yw)))
			var up_w: float = row[4]
			var dir: Vector3
			if up_w > 0.0:
				# yatık yanın dikenleri daha yatay-uzun, karşı yanınkiler yukarı kalkıp o yana döner
				dir = Vector3.UP * up_w + hz * 0.45 + back * 0.2 + lean + Vector3(j.call(0.12), 0, j.call(0.12))
			else:
				var down = (_dir(yw, pt + 6.0) - _dir(yw, pt - 6.0)).normalized()
				dir = n * 0.5 + down * 0.5 + back * 0.3 + lean * 0.4
			if absf(yw) > 120.0 and up_w > 0.0:
				dir += back * 0.35
			_shard(yw, pt, dir, row[2] * _rng.randf_range(0.85, 1.15), row[3] * _rng.randf_range(0.9, 1.1), 0.4, Vector3(0, -0.03, -0.04))
	# arka: yukarı-dışa açılan dikenler (anime arkadan)
	for k in 10:
		var yw = wrapf(lerpf(100.0, 260.0, (k + 0.5) / 10.0) + j.call(8), -180.0, 180.0)
		var pt = 60.0 + j.call(8)
		while _under_band_top(yw, pt) and pt > 20.0:
			pt -= 3.0
		var n = _dir(yw, pt)
		_shard(yw, pt, n * 0.7 + back * 0.4 + Vector3.UP * 0.4 + lean * 0.6, 0.85 * _rng.randf_range(0.9, 1.1), 0.85, 0.4, Vector3(0, -0.03, -0.03))
	# ön: alından/bandın üstünden yukarı ve yana kalkan büyük dikenler
	for k in 6:
		var yw = lerpf(-50.0, 50.0, (k + 0.5) / 6.0) + j.call(4)
		var pt = 56.0
		while _under_band_top(yw, pt) and pt > 25.0:
			pt -= 3.0
		_shard(yw, pt, Vector3.UP * 0.9 + _dir(yw, pt) * 0.35 + back * 0.15 + lean, 0.95 * _rng.randf_range(0.9, 1.1), 0.9, 0.4, Vector3(0, -0.02, -0.05))
	# savrulma yanı: yatay taşan uzun diken öbeği (ref: kütle o yana kafadan çok taşar)
	for k in 5:
		var yw = -lerpf(55.0, 125.0, k / 4.0) + j.call(5)
		var pt = 42.0 + j.call(8)
		while _under_band_top(yw, pt) and pt > 20.0:
			pt -= 3.0
		_shard(yw, pt, lean + Vector3.UP * 0.45 + back * 0.15 + _dir(yw, pt) * 0.3, 1.15 * _rng.randf_range(0.9, 1.1), 0.9, 0.4, Vector3(0, -0.04, 0))
	# ense: tutam YOK (ref arkadan: dikenler yukarı açılır, alt kısım kısa ve düz; sarkan tutamlar diş/yaka gibi duruyordu)
	# arka-alt: dağınık kısa dikenler (düzensiz yükseklik/boy — eşit sıra diş/yaka gibi durur; hiç olmazsa kel yumurta)
	for k in 9:
		var yw = wrapf(lerpf(105.0, 255.0, (k + 0.5) / 9.0) + j.call(10), -180.0, 180.0)
		var pt = 72.0 + _rng.randf_range(0.0, 24.0)
		if _under_band_top(yw, pt) or _in_band(yw, pt):
			continue
		var n = _dir(yw, pt)
		var dn = (_dir(yw, pt + 6.0) - _dir(yw, pt - 6.0)).normalized()
		_shard(yw, pt, n * 0.7 + dn * 0.4 + back * 0.2 + lean * 0.3, _rng.randf_range(0.4, 0.7), 0.7, 0.4)
	for sx in [-1.0, 1.0]:
		_flow(sx * 72.0, 84.0, sx * 74.0, 104.0, 0.04, 0.0, 0.3)
	if not _banded:
		# bantsız: alına düşen birkaç kısa sivri uç (yana savrulmuş)
		for k in 4:
			var yw = lerpf(-30.0, 30.0, (k + 0.5) / 4.0) + j.call(3)
			_flow(yw, 58.0, yw - 10.0, 96.0 + j.call(4), 0.08, 0.04, 0.3)


## Saç 8 — Shikamaru tabanlı (wiki: "Hairstyle 8 (Based on Shikamaru Nara)").
## Kaynaklar: refs/hair_ss/8.jpg (Striker ön), refs/hair_shika (anime settei, yan, profil). Ortak tasarım:
##  - saç kafaya SIKI taranmış (ince kütle), alın çizgisi sivri-tırtıklı
##  - tepenin arkasında yüksek bağ; bağdan yukarı-arkaya fışkıran 7-8 sivri diken (ananas)
##  - yanlar/ense kafaya yakın, hepsi bağa taranmış
static func _s8() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 50.0   # yüksek alın (ref; açı kafatası merkezinden, merkez alın hizasında)
		if a < 95.0:
			return lerpf(50.0, 94.0, (a - 45.0) / 50.0)
		return lerpf(98.0, 114.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.008, 7.0, 30)   # ince; alın çizgisi belirgin tırtıklı
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var back = Vector3(0, 0, -1)
	var tie_p = 34.0   # bağ: tepenin arkası (yaw 180)
	# taranmış tutamlar: saç çizgisinden bağa (kafaya yatık, sabit)
	_flow_kind = "lie"
	for k in 14:
		var yw = lerpf(-170.0, 170.0, (k + 0.5) / 14.0) + j.call(4)
		var h = _start_above_band(yw, float(hl.call(yw)) - 4.0)
		var yt = 180.0 * signf(yw) - signf(yw) * (10.0 + j.call(4))
		_flow(yw, h, yt, tie_p + 6.0, 0.1, (k % 3) * 0.03, 0.18)
	_flow_kind = "flow"
	# bağ düğümü
	var td = _dir(180.0, tie_p)
	var tie = _c + td * (_real_r(td) + 0.012)
	var knot = []
	for q in 5:
		knot.append(tie + td * (0.02 * q / 4.0))
	_ribbon(knot, 0.045, 1.0)
	# ananas: bağdan yukarı-arkaya fışkıran sivri dikenler (eksen etrafında açılır)
	var ax = (Vector3.UP + back * 0.3).normalized()   # önden kafanın üstünde taç gibi görünür (ref)
	var s1 = ax.cross(Vector3.RIGHT).normalized()
	var s2 = ax.cross(s1).normalized()
	for k in 8:
		var a = TAU * k / 8.0 + j.call(0.2)
		var dir = (ax + (s1 * cos(a) + s2 * sin(a)) * 1.0).normalized()   # geniş açılır (ref: ananas neredeyse kafa genişliğinde)
		var L = (0.16 if k % 2 == 0 else 0.12) + j.call(0.015)
		var pts = []
		for q in 9:
			var u = q / 8.0
			pts.append(tie + td * 0.015 + dir * L * u + Vector3(0, -0.012 * u * u, 0))
		_ribbon(pts, 0.06, 0.45)
	# merkez: düz yukarı kısa diken
	var cp = []
	for q in 9:
		cp.append(tie + td * 0.015 + ax * 0.15 * q / 8.0)
	_ribbon(cp, 0.06, 0.45)
	# favori: kulak önünde kısa
	for sx in [-1.0, 1.0]:
		_flow(sx * 74.0, 86.0, sx * 76.0, 104.0, 0.035, 0.0, 0.3)


## Saç 9 — Rock Lee tabanlı (wiki: "Hairstyle 9 (Based on Rock Lee)").
## Kaynaklar: refs/hair_ss/9.jpg (Striker ön), refs/hair_lee (anime yan, profil, settei). Ortak tasarım:
##  - parlak, pürüzsüz, KALIN kâse kesim; tutam/diken yok
##  - önde kaş hizasında DÜMDÜZ kesik kâkül; yanlarda kulak altına kadar düz iner, arkada enseye
##  - alt kenar keskin kesim çizgisi (kalınlığı görünür)
static func _s9() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 44.0:
			return 100.0   # kâkül: kaş hizasında dümdüz
		if a < 54.0:
			return lerpf(100.0, 132.0, smoothstep(44.0, 54.0, a))   # keskin köşe: kâkülden dikey yan perdeye
		return lerpf(132.0, 126.0, clampf((a - 54.0) / 126.0, 0.0, 1.0))   # yan perde burun hizasına (ref), arka enseye
	_curtain_banded = true   # bantlı: bandın altında da düz perde (mantar eteği olmasın)
	_mass(hl, 0.012 if _banded else 0.028, 0.0, 26, 0.0, 100.0, 0.3)   # bantlı: ince (kalın kâse bandın üstünde mantar olur)   # perde kulak hizasından (dar) başlar: yanlar yanağa yakın düz iner   # kalın, kenar kalın, 84°'den aşağısı dikey perde (kulakları örter)


## Saç 10 — Chōji tabanlı (wiki: "Hairstyle 10 (Based on Choji Akimichi)"; Shippuden).
## Kaynaklar: refs/hair_ss/10.jpg (Striker ön), refs/hair_choji (anime 3/4, aksiyon). Ortak tasarım:
##  - devasa uzun dikenli YELE: tepeden yukarı-arkaya fışkırır, arkada kafadan ~2x büyük yelpaze/alev silueti
##  - yanlarda uzun sivri tutamlar yüzü çerçeveler, çene/boyun hizasına iner ve dışa açılır
##  - bantsız: alına kısa sivri uçlar
static func _s10() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 82.0
		if a < 95.0:
			return lerpf(82.0, 100.0, (a - 45.0) / 50.0)
		return lerpf(100.0, 116.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.012, 3.0, 36)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var back = Vector3(0, 0, -1)
	# yele: [pitch, adet, uzunluk(R), genişlik(R)] — yukarı-arkaya ve dışa açılan uzun dikenler (önde kısa)
	for row in [[8.0, 6, 1.4, 0.95], [28.0, 11, 1.7, 1.0], [50.0, 13, 1.8, 1.0], [72.0, 13, 1.6, 0.95], [92.0, 10, 1.3, 0.9]]:
		var n_sp: int = row[1]
		var off = _rng.randf_range(0.0, 360.0 / n_sp)
		for k in n_sp:
			var yw = wrapf(off + k * 360.0 / n_sp + j.call(8), -180.0, 180.0)
			var pt: float = row[0] + j.call(5)
			if absf(yw) < 50.0 and row[0] >= 28.0:
				continue   # ön: yüz çerçevesi ve kâkül aşağıda
			while _under_band_top(yw, pt) and pt > 15.0:
				pt -= 3.0
			var n = _dir(yw, pt)
			var hz = Vector3(sin(deg_to_rad(yw)), 0, cos(deg_to_rad(yw)))
			var bk = smoothstep(60.0, 150.0, absf(yw))   # arkaya doğru daha uzun ve yukarı-arkaya
			var dir = n * 0.5 + hz * 0.35 + back * (0.4 + 0.5 * bk) + Vector3.UP * (0.5 - float(row[0]) / 200.0)
			var ln = float(row[2]) * lerpf(0.55, 1.0, bk)
			_shard(yw, pt, dir, ln * _rng.randf_range(0.85, 1.15), float(row[3]) * _rng.randf_range(0.9, 1.1), 0.4, Vector3(0, -0.08, -0.06))
	# sarkan yele: yanlardan ve arkadan omuzlara aşağı-dışa inen uzun dikenli katmanlar (ref: yele aşağı da iner)
	for row in [[70.0, 12, 1.5], [92.0, 12, 1.4]]:
		for k in row[1]:
			var yw = wrapf(lerpf(55.0, 305.0, (k + 0.5) / row[1]) + j.call(8), -180.0, 180.0)
			var pt = float(row[0]) + j.call(6)
			while _under_band_top(yw, pt) and pt > 20.0:
				pt -= 3.0
			var n = _dir(yw, pt)
			var dn = (_dir(yw, pt + 6.0) - _dir(yw, pt - 6.0)).normalized()
			_shard(yw, pt, dn * 0.9 + n * 0.55 + back * 0.15, float(row[2]) * _rng.randf_range(0.85, 1.15), 0.95, 0.4, Vector3(0, -0.05, 0))
	# yüz çerçevesi: yanaklar boyunca boyna inen dikenli tutamlar (ince çizgi değil, geniş sivri)
	for sx in ([] if _banded else [-1.0, 1.0]):   # bantlı: yüz çerçevesi yok (bandın altından yanakta plaka oluyordu)
		for k in 3:
			var yw = sx * (52.0 + k * 12.0)
			var pt = 66.0
			var dn = (_dir(yw, pt + 6.0) - _dir(yw, pt - 6.0)).normalized()
			_shard(yw, pt, dn + _dir(yw, pt) * 0.35 + Vector3(sx * 0.15, 0, 0), 1.25 - k * 0.1, 0.8, 0.38, Vector3(sx * 0.03, -0.04, 0))
	if not _banded:
		# bantsız: alına kısa sivri uçlar
		for k in 5:
			var yw = lerpf(-36.0, 36.0, (k + 0.5) / 5.0) + j.call(3)
			_flow(yw, 50.0, yw * 1.15, 98.0 + j.call(4), 0.09, 0.05, 0.3)
	else:
		# bantlı: bandın üstünden yukarı-arkaya kalkan ön dikenler
		for k in 6:
			var yw = lerpf(-50.0, 50.0, (k + 0.5) / 6.0) + j.call(4)
			var pt = 58.0
			while _under_band_top(yw, pt) and pt > 25.0:
				pt -= 3.0
			_shard(yw, pt, Vector3.UP * 0.8 + back * 0.5 + _dir(yw, pt) * 0.3, 0.9 * _rng.randf_range(0.9, 1.1), 0.9, 0.4, Vector3(0, -0.03, -0.05))


## Saç 11 — Sai tabanlı (wiki: "Hairstyle 11 (Based on Sai)").
## Kaynaklar: refs/hair_ss/11.jpg (Striker ön), refs/hair_sai (anime profil, yakın). Ortak tasarım:
##  - kısa, düz, kafaya yakın yuvarlak saç
##  - simetrik kâkül: ince sivri tutamlar kaş-göz arasına, aralarında boşluk
##  - yanlar kulağın yarısını örter, ense kısa ve düzgün
static func _s11() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 80.0
		if a < 95.0:
			return lerpf(80.0, 118.0, (a - 45.0) / 50.0)
		return lerpf(118.0, 122.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.007, 2.0, 48, 0.55, 0.0, 0.4)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	# tepeden dökülen düz tutamlar (sabit)
	_flow_kind = "lie"
	_lift0 = 0.008
	for k in 16:
		var yw = lerpf(-160.0, 160.0, (k + 0.5) / 16.0) + j.call(4)
		if absf(yw) < 40.0:
			continue
		_flow(yw * 0.4, 10.0 + j.call(5), yw, float(hl.call(yw)) + 2.0, 0.1, (k % 3) * 0.02, 0.14)
	_lift0 = 0.014
	_flow_kind = "flow"
	# uçlar: saç çizgisinde aşağı inen kısa sivri uçlar (yan + arka)
	for k in 12:
		var yw = lerpf(-165.0, 165.0, (k + 0.5) / 12.0) + j.call(6)
		if absf(yw) < 52.0:
			continue
		var h = float(hl.call(yw))
		_flow(yw, h - 14.0, yw + j.call(3), h + 8.0 + _rng.randf_range(0.0, 8.0), 0.06, 0.0, 0.3)
	if not _banded:
		# yüz çerçevesi: elmacığın altına inen sivri tutamlar (Striker 11)
		for sx in [-1.0, 1.0]:
			_flow(sx * 50.0, 60.0, sx * 58.0, 140.0, 0.085, 0.1, 0.3)
			_flow(sx * 64.0, 68.0, sx * 72.0, 134.0, 0.08, 0.1, 0.3)
		# simetrik kâkül: ince sivri tutamlar, aralarında boşluk
		_taper = 1.4
		for k in 7:
			var yw = lerpf(-40.0, 40.0, k / 6.0) + j.call(2)
			_flow(yw * 0.4, 18.0, yw, 120.0 + j.call(4) - absf(yw) * 0.1, 0.08, 0.3, 0.3)   # göz üstüne
		_taper = 1.0


## Saç 12 — Pain tabanlı (wiki: "Hairstyle 12 (Based on Pain)").
## Kaynaklar: refs/hair_ss/12.jpg (Striker ön), refs/hair_pain (anime yan, aksiyon). Ortak tasarım:
##  - kısa, SIK, DÜZENLİ dikenler; çoğu yukarı-hafif arkaya (Naruto'dan kısa, Kiba'dan düzenli)
##  - şakaklarda aşağı bakan dikenli tutamlar kulak önüne; bantsız: alına kısa sivri uçlar
static func _s12() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 84.0
		if a < 95.0:
			return lerpf(84.0, 100.0, (a - 45.0) / 50.0)
		return lerpf(100.0, 114.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.011, 3.0, 40)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var back = Vector3(0, 0, -1)
	for row in [[6.0, 7, 0.62, 0.7], [24.0, 13, 0.66, 0.7], [42.0, 16, 0.64, 0.68], [60.0, 17, 0.6, 0.64], [78.0, 15, 0.52, 0.6]]:
		var n_sp: int = row[1]
		var off = _rng.randf_range(0.0, 360.0 / n_sp)
		for k in n_sp:
			var yw = wrapf(off + k * 360.0 / n_sp + j.call(4), -180.0, 180.0)
			var pt: float = row[0] + j.call(3)
			if row[0] >= 60.0 and absf(yw) < 45.0:
				continue
			while _under_band_top(yw, pt) and pt > 15.0:
				pt -= 3.0
			var n = _dir(yw, pt)
			var hz = Vector3(sin(deg_to_rad(yw)), 0, cos(deg_to_rad(yw)))
			var dir = n * 0.6 + Vector3.UP * (0.55 if pt < 36.0 else 0.3) + back * 0.2 + hz * (0.15 if pt < 36.0 else 0.45)   # tepe yukarı, yanlar dışa: geniş siluet (Striker 12)
			if absf(yw) > 120.0:
				dir = n * 0.8 + back * 0.4 + Vector3.UP * 0.25   # arka: arkaya-dışa (kel kubbe olmasın)
			_shard(yw, pt, dir, float(row[2]) * _rng.randf_range(0.92, 1.08), float(row[3]), 0.4, Vector3(0, -0.03, -0.03))
	# arka-alt: dağınık kısa dikenler (yaka olmasın)
	for k in 9:
		var yw = wrapf(lerpf(105.0, 255.0, (k + 0.5) / 9.0) + j.call(8), -180.0, 180.0)
		var pt = 80.0 + _rng.randf_range(0.0, 20.0)
		if _under_band_top(yw, pt) or _in_band(yw, pt):
			continue
		var n = _dir(yw, pt)
		var dn = (_dir(yw, pt + 6.0) - _dir(yw, pt - 6.0)).normalized()
		_shard(yw, pt, n * 0.7 + dn * 0.45 + back * 0.2, _rng.randf_range(0.4, 0.6), 0.65, 0.4)
	# şakak: aşağı bakan dikenli tutamlar kulak önüne
	for sx in [-1.0, 1.0]:
		for k in 2:
			var yw = sx * (64.0 + k * 12.0)
			var pt = 76.0
			if _banded:
				continue
			var dn = (_dir(yw, pt + 6.0) - _dir(yw, pt - 6.0)).normalized()
			_shard(yw, pt, dn + _dir(yw, pt) * 0.35, 0.75 - k * 0.1, 0.6, 0.38)
	if _banded:
		for k in 7:
			var yw = lerpf(-56.0, 56.0, (k + 0.5) / 7.0) + j.call(3)
			var pt = 58.0
			while _under_band_top(yw, pt) and pt > 25.0:
				pt -= 3.0
			_shard(yw, pt, _dir(yw, pt) * 0.6 + Vector3.UP * 0.8 + back * 0.15, 0.55, 0.65, 0.4)
	else:
		for k in 6:
			var yw = lerpf(-40.0, 40.0, (k + 0.5) / 6.0) + j.call(3)
			_flow(yw, 54.0, yw * 1.1, 98.0 + j.call(4), 0.08, 0.05, 0.3)


## Saç 13 — Naruto (BORUTO) tabanlı (wiki: "Hairstyle 13 (Based on Naruto Uzumaki (BORUTO))").
## Kaynaklar: refs/hair_ss/13.jpg (Striker ön), refs/hair_naruto_b (anime yakın, tam boy). Ortak tasarım:
##  - kısa, dağınık, yukarı dikenler (Pain'den kısa, kirpi kesime yakın)
##  - alına küçük sivri uçlardan kısa kâkül; yanlar kulak üstünde kısacık (kulak açık), ense kısa düzgün
static func _s13() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 82.0
		if a < 95.0:
			return lerpf(82.0, 92.0, (a - 45.0) / 50.0)
		return lerpf(92.0, 108.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.01, 3.0, 44)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var back = Vector3(0, 0, -1)
	for row in [[6.0, 8, 0.45, 0.65], [24.0, 14, 0.5, 0.66], [42.0, 17, 0.48, 0.64], [62.0, 18, 0.42, 0.6], [80.0, 16, 0.34, 0.55]]:
		var n_sp: int = row[1]
		var off = _rng.randf_range(0.0, 360.0 / n_sp)
		for k in n_sp:
			var yw = wrapf(off + k * 360.0 / n_sp + j.call(7), -180.0, 180.0)
			var pt: float = row[0] + j.call(5)
			if row[0] >= 62.0 and absf(yw) < 45.0:
				continue
			while _under_band_top(yw, pt) and pt > 15.0:
				pt -= 3.0
			var n = _dir(yw, pt)
			var hz = Vector3(sin(deg_to_rad(yw)), 0, cos(deg_to_rad(yw)))
			var dir = n * 0.7 + Vector3.UP * (0.5 if pt < 36.0 else 0.25) + back * 0.2 + hz * 0.2 + Vector3(j.call(0.2), 0, j.call(0.2))
			_shard(yw, pt, dir, float(row[2]) * _rng.randf_range(0.85, 1.15), float(row[3]), 0.4, Vector3(0, -0.02, -0.02))
	if _banded:
		for k in 7:
			var yw = lerpf(-56.0, 56.0, (k + 0.5) / 7.0) + j.call(3)
			var pt = 58.0
			while _under_band_top(yw, pt) and pt > 25.0:
				pt -= 3.0
			_shard(yw, pt, _dir(yw, pt) * 0.6 + Vector3.UP * 0.8 + back * 0.1, 0.45, 0.6, 0.4)
	else:
		# kısa kâkül: küçük sivri uçlar
		for k in 7:
			var yw = lerpf(-42.0, 42.0, (k + 0.5) / 7.0) + j.call(3)
			_flow(yw, 58.0, yw * 1.05 + j.call(4), 94.0 + j.call(4), 0.07, 0.06, 0.3)


## Saç 14 — Asuma tabanlı (wiki: "Hairstyle 14 (Based on Asuma Sarutobi)").
## Kaynaklar: refs/hair_ss/14.jpg (Striker ön), refs/hair_asuma (anime portre, aksiyon). Ortak tasarım:
##  - kısa sert dikenler YUKARI kalkıp DÜZ ARKAYA taranmış (yana yatık değil)
##  - yanlar kısa dikenli; bantsız: alın açık, saç alından yukarı-arkaya
static func _s14() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 76.0
		if a < 95.0:
			return lerpf(76.0, 96.0, (a - 45.0) / 50.0)
		return lerpf(96.0, 110.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.01, 3.0, 40)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var back = Vector3(0, 0, -1)
	for row in [[6.0, 7, 0.75, 0.8], [24.0, 12, 0.8, 0.8], [44.0, 14, 0.7, 0.75], [64.0, 15, 0.55, 0.65], [82.0, 13, 0.4, 0.55]]:
		var n_sp: int = row[1]
		var off = _rng.randf_range(0.0, 360.0 / n_sp)
		for k in n_sp:
			var yw = wrapf(off + k * 360.0 / n_sp + j.call(7), -180.0, 180.0)
			var pt: float = row[0] + j.call(4)
			if row[0] >= 64.0 and absf(yw) < 45.0:
				continue
			while _under_band_top(yw, pt) and pt > 15.0:
				pt -= 3.0
			var n = _dir(yw, pt)
			var hz = Vector3(sin(deg_to_rad(yw)), 0, cos(deg_to_rad(yw)))
			var dir = n * 0.5 + Vector3.UP * (0.6 if pt < 50.0 else 0.2) + back * 0.6 + hz * 0.15
			_shard(yw, pt, dir, float(row[2]) * _rng.randf_range(0.88, 1.12), float(row[3]), 0.4, Vector3(0, -0.03, -0.04))
	# ön: alından yukarı-arkaya kalkan dikenler
	for k in 6:
		var yw = lerpf(-46.0, 46.0, (k + 0.5) / 6.0) + j.call(3)
		var pt = 64.0
		while _under_band_top(yw, pt) and pt > 25.0:
			pt -= 3.0
		_shard(yw, pt, Vector3.UP * 0.8 + back * 0.6 + _dir(yw, pt) * 0.3, 0.75 * _rng.randf_range(0.9, 1.1), 0.8, 0.4, Vector3(0, -0.02, -0.04))
	# arka-alt: dağınık kısa dikenler
	for k in 8:
		var yw = wrapf(lerpf(110.0, 250.0, (k + 0.5) / 8.0) + j.call(8), -180.0, 180.0)
		var pt = 78.0 + _rng.randf_range(0.0, 20.0)
		if _under_band_top(yw, pt) or _in_band(yw, pt):
			continue
		var n = _dir(yw, pt)
		var dn = (_dir(yw, pt + 6.0) - _dir(yw, pt - 6.0)).normalized()
		_shard(yw, pt, n * 0.7 + dn * 0.4 + back * 0.3, _rng.randf_range(0.4, 0.6), 0.65, 0.4)


## Saç 15 — Nagato tabanlı (wiki: "Hairstyle 15 (Based on Nagato)").
## Kaynaklar: refs/hair_ss/15.jpg (Striker ön), refs/hair_nagato (anime yakın, aksiyon). Ortak tasarım:
##  - uzun, DÜMDÜZ saç; çene-omuz arası, düz dökülür (perde modu)
##  - büyük düz kâkül perdesi bir gözü (önden görüntünün sağı) TAMAMEN örter, çeneye iner
##  - diğer yan yandan ayrık, yüz kenarından çeneye düz iner
static func _s15() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 40.0:
			return 70.0
		if a < 70.0:
			return lerpf(70.0, 150.0, smoothstep(40.0, 70.0, a))
		return lerpf(150.0, 140.0, clampf((a - 70.0) / 110.0, 0.0, 1.0))
	_curtain_banded = true
	_mass(hl, 0.012, 1.5, 60, 0.3, 96.0, 0.5)   # uzun düz: 96°'den aşağısı dikey düz iner
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var cover = 1.0
	# tepeden dökülen düz tutamlar (sabit, ince çizgi dokusu)
	_flow_kind = "lie"
	_lift0 = 0.014
	for k in 14:
		var yw = lerpf(-150.0, 150.0, (k + 0.5) / 14.0) + j.call(4)
		if absf(yw) < 40.0:
			continue
		_flow(yw * 0.3 - cover * 10.0, 10.0, yw, 92.0, 0.1, 0.0, 0.12)
	_lift0 = 0.014
	_flow_kind = "flow"
	if not _banded:
		# büyük düz perde: yan ayrıktan (öbür yan) çapraz, gözü tamamen örter, çeneye düz iner
		_taper = 2.2
		_lift0 = 0.009
		for t in [[6.0, 150.0, 0.13], [16.0, 148.0, 0.16], [26.0, 146.0, 0.16], [32.0, 150.0, 0.14], [46.0, 154.0, 0.12], [60.0, 154.0, 0.11]]:
			var ye = cover * float(t[0])
			_flow(-cover * 24.0 + ye * 0.35, 14.0, ye, float(t[1]) + j.call(2), float(t[2]), 0.45, 0.28)
		_taper = 1.0
		_lift0 = 0.014
		# açık yan: yüz kenarından çeneye düz tutamlar
		for k in 2:
			var yw = -cover * (46.0 + k * 14.0)
			_flow(yw * 0.6, 30.0, yw, 152.0 - k * 4.0, 0.1, 0.1, 0.3)


## Saç 16 — Sasuke (Shippūden) tabanlı (wiki: "Hairstyle 16 (Based on Sasuke Uchiha)").
## Kaynaklar: refs/hair_ss/16.jpg (Striker ön), refs/hair_sasuke (anime yan, profil, arka siluet). Ortak tasarım:
##  - önde düz uzun: kâküller göze, iki yanda yüzü çerçeveleyen uzun kâküller çeneye
##  - tepenin ARKASINDA arkaya-yukarı fışkıran büyük sivri öbek ("ördek kuyruğu"); yanlar kısa; tepe öne taranmış
static func _s16() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 80.0
		if a < 95.0:
			return lerpf(80.0, 102.0, (a - 45.0) / 50.0)
		return lerpf(102.0, 112.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.008, 2.0, 48, 0.55, 0.0, 0.5)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var back = Vector3(0, 0, -1)
	# tepe: öne taranmış düz tutamlar (sabit)
	_flow_kind = "lie"
	_lift0 = 0.008
	for k in 12:
		var yw = lerpf(-120.0, 120.0, (k + 0.5) / 12.0) + j.call(4)
		_flow(yw * 0.6, 30.0, yw, float(hl.call(yw)) - 2.0, 0.1, (k % 3) * 0.02, 0.14)
	_lift0 = 0.014
	_flow_kind = "flow"
	# ördek kuyruğu: tepe arkasında arkaya-yukarı fışkıran büyük sivri öbek
	for row in [[30.0, 6, 1.1], [48.0, 8, 1.2], [66.0, 9, 1.0], [84.0, 8, 0.75]]:
		for k in row[1]:
			var yw = wrapf(lerpf(110.0, 250.0, (k + 0.5) / row[1]) + j.call(6), -180.0, 180.0)
			var pt = float(row[0]) + j.call(5)
			while _under_band_top(yw, pt) and pt > 15.0:
				pt -= 3.0
			var n = _dir(yw, pt)
			var hz = Vector3(sin(deg_to_rad(yw)), 0, cos(deg_to_rad(yw)))
			_shard(yw, pt, n * 0.5 + back * 0.7 + Vector3.UP * (0.55 - float(row[0]) / 200.0) + hz * 0.2, float(row[2]) * _rng.randf_range(0.88, 1.12), 0.9, 0.4, Vector3(0, -0.04, -0.03))
	# yanlar: kısa sivri uçlar
	for sx in [-1.0, 1.0]:
		for k in 3:
			var yw = sx * (80.0 + k * 12.0)
			var pt = 70.0
			while _under_band_top(yw, pt) and pt > 30.0:
				pt -= 3.0
			var dn = (_dir(yw, pt + 6.0) - _dir(yw, pt - 6.0)).normalized()
			_shard(yw, pt, dn * 0.7 + _dir(yw, pt) * 0.5 + back * 0.4, 0.6, 0.7, 0.4)
	if not _banded:
		# yüz çerçevesi: iki yanda çeneye inen uzun kâküller
		_taper = 1.5
		for sx in [-1.0, 1.0]:
			_flow(sx * 20.0, 26.0, sx * 46.0, 150.0, 0.11, 0.35, 0.3)
			_flow(sx * 34.0, 32.0, sx * 58.0, 142.0, 0.09, 0.3, 0.3)
		# orta kâkül: göze inen sivri tutamlar
		for k in 4:
			var yw = lerpf(-14.0, 14.0, k / 3.0) + j.call(2)
			_flow(yw * 0.5, 22.0, yw, 118.0 + j.call(4), 0.08, 0.3, 0.3)
		_taper = 1.0


## Saç 17 — Gaara (BORUTO) tabanlı (wiki: "Hairstyle 17 (Based on Gaara (BORUTO))").
## Kaynaklar: refs/hair_ss/17.jpg (Striker ön), refs/hair_gaara/b_* (anime portre). Ortak tasarım (Striker'dan tutam tutam):
##  - ayrık önden görüntünün SAĞINDA (+yaw); saç oradan SOLA çapraz taranır, pürüzsüz
##  - kâkül alnın üstünden çapraz geçip görüntünün solundaki gözü kısmen örter, yanağa iner
##  - ayrık tarafında (sağ) uzun yan tutamlar çeneye; öbür yanda (sol) kulak açık, kısa
static func _s17() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if yw < -45.0:
			return lerpf(80.0, 142.0, smoothstep(-45.0, -80.0, yw)) if yw > -110.0 else lerpf(142.0, 118.0, clampf((-yw - 110.0) / 70.0, 0.0, 1.0))   # örtülen (sol) yan uzun, çeneye
		if a < 45.0:
			return 80.0
		if a < 95.0:
			return lerpf(80.0, 96.0, (a - 45.0) / 50.0)
		return lerpf(96.0, 118.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.008, 2.0, 48, 0.55, 0.0, 0.6)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var part = 34.0   # ayrık (önden görüntünün sağı)
	var endp = func(yw: float, p: float) -> float: return _start_above_band(yw, p) if _banded else p   # bantlı: bandın üst kenarında biter
	_flow_kind = "lie"
	_lift0 = 0.008
	# ayrıktan sola çapraz taranmış tutamlar (tepe, sol yan, arka)
	for k in 12:
		var u = (k + 0.5) / 12.0
		var ye = wrapf(part - lerpf(90.0, 250.0, u), -180.0, 180.0)
		_flow(part, lerpf(10.0, 40.0, u), ye, endp.call(ye, float(hl.call(ye)) - 2.0), 0.11, (k % 3) * 0.02, 0.14)
	# ayrığın sağ yanı: aşağı taranmış KISA (ref: kulak + küpe görünür)
	for k in 4:
		var ye = part + 30.0 + k * 22.0
		_flow(part + 4.0, 16.0 + k * 10.0, ye, endp.call(ye, float(hl.call(ye)) - 2.0), 0.1, 0.0, 0.14)
	_lift0 = 0.014
	_flow_kind = "flow"
	if not _banded:
		# kâkül: ayrıktan alın üstünden çapraz sola, soldaki gözü kısmen örter, yanağa
		_taper = 1.5
		_lift0 = 0.009
		for t in [[-2.0, 120.0, 0.12], [-14.0, 136.0, 0.15], [-26.0, 142.0, 0.16], [-38.0, 144.0, 0.15], [-52.0, 146.0, 0.12], [-66.0, 146.0, 0.1]]:
			_flow(part - 8.0 + float(t[0]) * 0.3, 20.0, float(t[0]), float(t[1]) + j.call(2), float(t[2]), 0.45, 0.3)   # sol gözü örter, yanağa
		_lift0 = 0.014
		_taper = 1.0


## Saç 18 — Kisame tabanlı (wiki: "Hairstyle 18 (Based on Kisame Hoshigaki)").
## Kaynaklar: refs/hair_ss/18.jpg (Striker ön), refs/hair_kisame (anime yan, üstten). Ortak tasarım:
##  - dimdik YUKARI kalkmış kısa-sık dikenlerden fırça (yüzgeç gibi tepe); yanlar çok kısa
##  - kâkül yok: saç alın çizgisinden doğrudan yukarı; arka dikenler yukarı-hafif arkaya
static func _s18() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 74.0
		if a < 95.0:
			return lerpf(74.0, 88.0, (a - 45.0) / 50.0)
		return lerpf(88.0, 104.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.008, 2.0, 50)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var back = Vector3(0, 0, -1)
	# fırça: tepede yoğun, dimdik yukarı; kenara doğru kısalır, hafif dışa
	for row in [[4.0, 8, 0.75], [18.0, 14, 0.75], [32.0, 18, 0.7], [46.0, 20, 0.6], [60.0, 20, 0.45], [74.0, 18, 0.3]]:
		var n_sp: int = row[1]
		var off = _rng.randf_range(0.0, 360.0 / n_sp)
		for k in n_sp:
			var yw = wrapf(off + k * 360.0 / n_sp + j.call(5), -180.0, 180.0)
			var pt: float = row[0] + j.call(3)
			if row[0] >= 74.0 and absf(yw) < 40.0:
				continue
			while _under_band_top(yw, pt) and pt > 10.0:
				pt -= 3.0
			var n = _dir(yw, pt)
			var dir = Vector3.UP * 1.0 + n * (0.15 + float(row[0]) / 200.0) + back * 0.1
			_shard(yw, pt, dir, float(row[2]) * _rng.randf_range(0.9, 1.1), 0.6, 0.4, Vector3(0, 0, -0.02))


## Saç 19 — Boruto tabanlı (wiki: "Hairstyle 19 (Based on Boruto Uzumaki)").
## Kaynaklar: refs/hair_ss/19.jpg (Striker ön), refs/hair_boruto (anime yan, yakın). Ortak tasarım:
##  - büyük sivri tutamlar yukarı kalkıp TEK YANA (önden görüntünün sağı = +x) yatar; Kakashi'den kısa, keskin
##  - önde alına sarkan sivri kâkül; görüntünün solunda yanağa inen yan tutam
static func _s19() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 80.0
		if a < 95.0:
			return lerpf(80.0, 98.0, (a - 45.0) / 50.0)
		return lerpf(98.0, 112.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.011, 3.0, 38)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var back = Vector3(0, 0, -1)
	var lean = Vector3(0.6, 0, 0)
	for row in [[6.0, 6, 0.85, 0.9, 0.9], [26.0, 11, 0.9, 0.9, 0.8], [46.0, 13, 0.8, 0.85, 0.6], [66.0, 13, 0.6, 0.75, 0.3], [84.0, 11, 0.4, 0.6, 0.0]]:
		var n_sp: int = row[1]
		var off = _rng.randf_range(0.0, 360.0 / n_sp)
		for k in n_sp:
			var yw = wrapf(off + k * 360.0 / n_sp + j.call(8), -180.0, 180.0)
			var pt: float = row[0] + j.call(5)
			if row[0] >= 66.0 and absf(yw) < 45.0:
				continue
			if row[0] >= 84.0 and absf(yw) > 110.0:
				continue
			while _under_band_top(yw, pt) and pt > 15.0:
				pt -= 3.0
			var n = _dir(yw, pt)
			var hz = Vector3(sin(deg_to_rad(yw)), 0, cos(deg_to_rad(yw)))
			var up_w: float = row[4]
			var dir: Vector3
			if up_w > 0.0:
				dir = Vector3.UP * up_w + hz * 0.45 + back * 0.25 + lean + Vector3(j.call(0.12), 0, j.call(0.12))
			else:
				var down = (_dir(yw, pt + 6.0) - _dir(yw, pt - 6.0)).normalized()
				dir = n * 0.5 + down * 0.5 + back * 0.3 + lean * 0.4
			if absf(yw) > 120.0 and up_w > 0.0:
				dir += back * 0.35
			_shard(yw, pt, dir, float(row[2]) * _rng.randf_range(0.85, 1.15), float(row[3]) * _rng.randf_range(0.9, 1.1), 0.4, Vector3(0, -0.03, -0.04))
	# imza: görüntünün sağında tepeden yana yatay uzanan iri sivri tutamlar (Striker 19)
	for k in 4:
		var yw = lerpf(40.0, 110.0, k / 3.0) + j.call(5)
		var pt = 30.0 + k * 6.0 + j.call(4)
		while _under_band_top(yw, pt) and pt > 15.0:
			pt -= 3.0
		_shard(yw, pt, lean * 1.6 + Vector3.UP * 0.45 + back * 0.15, 1.25 * _rng.randf_range(0.9, 1.1), 1.0, 0.4, Vector3(0, -0.05, 0))
	# arka-alt: dağınık kısa dikenler
	for k in 9:
		var yw = wrapf(lerpf(105.0, 255.0, (k + 0.5) / 9.0) + j.call(10), -180.0, 180.0)
		var pt = 72.0 + _rng.randf_range(0.0, 24.0)
		if _under_band_top(yw, pt) or _in_band(yw, pt):
			continue
		var n = _dir(yw, pt)
		var dn = (_dir(yw, pt + 6.0) - _dir(yw, pt - 6.0)).normalized()
		_shard(yw, pt, n * 0.7 + dn * 0.4 + back * 0.2 + lean * 0.3, _rng.randf_range(0.4, 0.65), 0.7, 0.4)
	if not _banded:
		# sarkan sivri kâkül + soldaki yan tutam
		_flow(8.0, 46.0, -6.0, 104.0, 0.12, 0.2, 0.3)
		_flow(-18.0, 50.0, -28.0, 100.0, 0.1, 0.2, 0.3)
		_flow(-58.0, 64.0, -66.0, 140.0, 0.09, 0.15, 0.3)
	else:
		for k in 6:
			var yw = lerpf(-50.0, 50.0, (k + 0.5) / 6.0) + j.call(4)
			var pt = 58.0
			while _under_band_top(yw, pt) and pt > 25.0:
				pt -= 3.0
			_shard(yw, pt, Vector3.UP * 0.9 + _dir(yw, pt) * 0.35 + back * 0.15 + lean, 0.85, 0.9, 0.4, Vector3(0, -0.02, -0.05))


## Saç 20 — Mitsuki tabanlı (wiki: "Hairstyle 20 (Based on Mitsuki)").
## Kaynaklar: refs/hair_ss/20.jpg (Striker ön), refs/hair_mitsuki (anime yan, yakın). Ortak tasarım:
##  - kısa-orta, KATLI, dolgun yuvarlak; uçlar sivri ve düzensiz
##  - kâkül sivri tutamlar göze; yanlar kulağı örter elmacığa; arka enseyi kısmen örter
static func _s20() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 80.0
		if a < 95.0:
			return lerpf(80.0, 118.0, (a - 45.0) / 50.0)
		return lerpf(118.0, 124.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.012, 2.0, 48, 0.55, 0.0, 0.5)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var back = Vector3(0, 0, -1)
	_flow_kind = "lie"
	_lift0 = 0.008
	for k in 16:
		var yw = lerpf(-160.0, 160.0, (k + 0.5) / 16.0) + j.call(4)
		if absf(yw) < 40.0:
			continue
		_flow(yw * 0.4, 10.0 + j.call(5), yw, float(hl.call(yw)) - 6.0, 0.1, (k % 3) * 0.02, 0.14)
	_lift0 = 0.014
	_flow_kind = "flow"
	# katlar: iki kademe sivri, düzensiz uçlar (yan + arka) — dışa hafif kalkık
	for layer in [[-26.0, 0.0], [-10.0, 10.0]]:
		for k in 13:
			var yw = lerpf(-165.0, 165.0, (k + 0.5) / 13.0) + j.call(8)
			if absf(yw) < 50.0:
				continue
			var h = float(hl.call(yw))
			_flow(yw, h + float(layer[0]), yw + j.call(5), h + float(layer[1]) + _rng.randf_range(0.0, 10.0), 0.07, 0.08, 0.3)   # hafif kalkık (fazlası kanat öbeği gibi fırlıyordu)
	if not _banded:
		_taper = 1.4
		for k in 6:
			var yw = lerpf(-36.0, 36.0, k / 5.0) + j.call(3)
			_flow(yw * 0.4, 18.0, yw * 1.1, 118.0 + j.call(5) - absf(yw) * 0.1, 0.085, 0.3, 0.3)
		for sx in [-1.0, 1.0]:
			_flow(sx * 50.0, 58.0, sx * 58.0, 136.0, 0.085, 0.2, 0.3)
		_taper = 1.0


## Saç 21 — Iruka tabanlı (wiki: "Hairstyle 21 (Based on Iruka Umino)").
## Kaynaklar: refs/hair_ss/21.jpg (Striker ön), refs/hair_iruka (anime portre). Ortak tasarım:
##  - saç düz-pürüzsüz tepeye taranmış; tepede bağlı KISA sivri kuyruk yukarı-arkaya
##  - Shikamaru'dan küçük, dar açılı, daha arkaya yatık; alın çizgisi normal
static func _s21() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 64.0
		if a < 95.0:
			return lerpf(64.0, 96.0, (a - 45.0) / 50.0)
		return lerpf(96.0, 114.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.008, 2.0, 50)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var back = Vector3(0, 0, -1)
	var tie_p = 30.0
	_flow_kind = "lie"
	_lift0 = 0.008
	for k in 14:
		var yw = lerpf(-170.0, 170.0, (k + 0.5) / 14.0) + j.call(4)
		var h = _start_above_band(yw, float(hl.call(yw)) - 4.0)
		var yt = 180.0 * signf(yw) - signf(yw) * (10.0 + j.call(4))
		_flow(yw, h, yt, tie_p + 6.0, 0.1, (k % 3) * 0.03, 0.16)
	_lift0 = 0.014
	_flow_kind = "flow"
	var td = _dir(180.0, tie_p)
	var tie = _c + td * (_real_r(td) + 0.01)
	var knot = []
	for q in 5:
		knot.append(tie + td * (0.018 * q / 4.0))
	_ribbon(knot, 0.04, 1.0)
	var ax = (Vector3.UP * 0.7 + back * 0.75).normalized()
	var s1 = ax.cross(Vector3.RIGHT).normalized()
	var s2 = ax.cross(s1).normalized()
	for k in 6:
		var a = TAU * k / 6.0 + j.call(0.25)
		var dir = (ax + (s1 * cos(a) + s2 * sin(a)) * 0.55).normalized()
		var L = (0.14 if k % 2 == 0 else 0.11) + j.call(0.01)
		var pts = []
		for q in 9:
			var u = q / 8.0
			pts.append(tie + td * 0.012 + dir * L * u + Vector3(0, -0.01 * u * u, 0))
		_ribbon(pts, 0.06, 0.45)
	for sx in [-1.0, 1.0]:
		_flow(sx * 72.0, 84.0, sx * 74.0, 104.0, 0.035, 0.0, 0.3)


## Saç 22 — Ay (Dördüncü Raikage) tabanlı (wiki: "Hairstyle 22 (Based on Ay (Fourth Raikage))").
## Kaynaklar: refs/hair_ss/22.jpg (Striker ön), refs/hair_ay (anime yakın, tam boy). Ortak tasarım:
##  - alından DÜZ ARKAYA taranmış, kafaya yatık; alın çizgisi yüksek, sivri-tırtıklı
##  - arkada tutamlar enseye kadar iner; uçlar kısa sivri, hafif arkaya-dışa kalkık
static func _s22() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 58.0
		if a < 95.0:
			return lerpf(58.0, 96.0, (a - 45.0) / 50.0)
		return lerpf(96.0, 120.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.008, 3.5, 54)   # alın çizgisi: çok sayıda küçük sivri uç (tek büyük V değil)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var back = Vector3(0, 0, -1)
	var endp = func(yw: float, p: float) -> float: return _start_above_band(yw, p) if _banded else p
	_flow_kind = "lie"
	_lift0 = 0.008
	# geri tarama: tutamlar tepeden (pitch ~20) alın çizgisine uzanır, uçları alında sivri diş olur (Striker 22);
	# yaw sabit (çapraz geçen tutam alın üstünde açıklık bırakıyordu); arka yarı tepeden enseye
	for k in 18:
		var yw = lerpf(-170.0, 170.0, (k + 0.5) / 18.0) + j.call(3)
		var h = endp.call(yw, float(hl.call(yw)) + 2.0)
		_flow(yw * 0.6, 14.0, yw, h, 0.12, 0.0, 0.14)
	_lift0 = 0.014
	_flow_kind = "flow"
	# ense uçları: kısa sivri, arkaya-dışa
	for k in 8:
		var yw = wrapf(lerpf(120.0, 240.0, (k + 0.5) / 8.0) + j.call(6), -180.0, 180.0)
		var pt = 106.0 + _rng.randf_range(0.0, 10.0)
		if _in_band(yw, pt):
			continue
		var n = _dir(yw, pt)
		var dn = (_dir(yw, pt + 6.0) - _dir(yw, pt - 6.0)).normalized()
		_shard(yw, pt, dn * 0.6 + n * 0.5 + back * 0.4, _rng.randf_range(0.45, 0.7), 0.7, 0.4)


## Saç 23 — Killer B tabanlı (wiki: "Hairstyle 23 (Based on Killer Bee)").
## Kaynaklar: refs/hair_ss/23.jpg (Striker ön), refs/hair_bee (anime portre). Ortak tasarım:
##  - kısa, kafaya sıkı, düz geri taranmış (Ay'dan kısa: ense yukarıda)
##  - tepede arkaya bakan tek küçük sivri uç; alın çizgisi hafif sivri
static func _s23() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 66.0
		if a < 95.0:
			return lerpf(66.0, 92.0, (a - 45.0) / 50.0)
		return lerpf(92.0, 108.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.007, 3.0, 50)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var back = Vector3(0, 0, -1)
	var endp = func(yw: float, p: float) -> float: return _start_above_band(yw, p) if _banded else p
	_flow_kind = "lie"
	_lift0 = 0.007
	for k in 18:
		var yw = lerpf(-170.0, 170.0, (k + 0.5) / 18.0) + j.call(3)
		_flow(yw * 0.6, 14.0, yw, endp.call(yw, float(hl.call(yw)) + 2.0), 0.11, 0.0, 0.12)
	_lift0 = 0.014
	_flow_kind = "flow"
	# tepe: arkaya bakan küçük sivri uç
	_shard(180.0, 8.0, Vector3.UP * 0.9 + back * 0.5, 0.75, 0.6, 0.4)   # Striker 23: tepede görünür boynuz
	_shard(-175.0, 30.0, Vector3.UP * 0.4 + back * 0.9, 0.35, 0.5, 0.4)


## Saç 24 — Yamato tabanlı (wiki: "Hairstyle 24 (Based on Yamato)").
## Kaynaklar: refs/hair_ss/24.jpg (Striker ön), refs/hair_yamato (anime yan, portre). Ortak tasarım:
##  - kısa, dağınık; tepede küçük düzensiz sivri uçlar her yöne, yanlar kısa
##  - şakaklarda kulak önüne inen sivri favoriler; ense kısa dağınık
static func _s24() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 80.0
		if a < 95.0:
			return lerpf(80.0, 96.0, (a - 45.0) / 50.0)
		return lerpf(96.0, 110.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.012, 3.0, 44)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var back = Vector3(0, 0, -1)
	for row in [[6.0, 8, 0.6, 0.66], [24.0, 14, 0.62, 0.68], [42.0, 16, 0.6, 0.66], [62.0, 17, 0.52, 0.6], [80.0, 15, 0.38, 0.55]]:
		var n_sp: int = row[1]
		var off = _rng.randf_range(0.0, 360.0 / n_sp)
		for k in n_sp:
			var yw = wrapf(off + k * 360.0 / n_sp + j.call(9), -180.0, 180.0)
			var pt: float = row[0] + j.call(6)
			if row[0] >= 62.0 and absf(yw) < 45.0:
				continue
			while _under_band_top(yw, pt) and pt > 15.0:
				pt -= 3.0
			var n = _dir(yw, pt)
			var dir = n * 0.8 + Vector3(j.call(0.45), 0.2 + j.call(0.25), j.call(0.45)) + back * 0.15
			_shard(yw, pt, dir, float(row[2]) * _rng.randf_range(0.8, 1.2), float(row[3]), 0.4, Vector3(j.call(0.03), -0.03, -0.02))
	if not _banded:
		for sx in [-1.0, 1.0]:
			for k in 2:
				var yw = sx * (64.0 + k * 10.0)
				var dn = (_dir(yw, 80.0) - _dir(yw, 74.0)).normalized()
				_shard(yw, 76.0, dn + _dir(yw, 76.0) * 0.3, 0.6 - k * 0.1, 0.55, 0.38)
		for k in 6:
			var yw = lerpf(-40.0, 40.0, (k + 0.5) / 6.0) + j.call(4)
			_flow(yw, 56.0, yw * 1.1 + j.call(5), 96.0 + j.call(5), 0.08, 0.08, 0.3)
	else:
		for k in 7:
			var yw = lerpf(-56.0, 56.0, (k + 0.5) / 7.0) + j.call(3)
			var pt = 58.0
			while _under_band_top(yw, pt) and pt > 25.0:
				pt -= 3.0
			_shard(yw, pt, _dir(yw, pt) * 0.7 + Vector3(j.call(0.3), 0.8, 0.1), 0.42, 0.58, 0.4)


# ================================================================ kadın saçları (refs/hair_ss/N-0.jpg)
## Uzun saç kurucusu (kadın stilleri ortak). o: {
##   front: alın saç çizgisi pitch, side: yan uç pitch (çene ~150), back: arka uç pitch, curtain: perde başlangıcı,
##   drop: omuzdan aşağı sarkan perde boyu (m, 0 = yok), drop_from/drop_to: sarkan perdenin yaw aralığı (arka = 180),
##   bang: "hime" düz kesik | "side" yana süpürülmüş | "center" ortadan ayrık | "spiky" sivri dağınık | "none",
##   bang_len: kâkül uç pitch, face: yüz çerçevesi uç pitch (0 = yok), ragged: uç dişliliği (derece) }
static func _long(o: Dictionary) -> void:
	var front: float = o.get("front", 70.0)
	var side: float = o.get("side", 150.0)
	var backp: float = o.get("back", 150.0)
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 40.0:
			return front
		if a < 70.0:
			return lerpf(front, side, smoothstep(40.0, 70.0, a))
		return lerpf(side, backp, clampf((a - 70.0) / 110.0, 0.0, 1.0))
	_curtain_banded = true
	_mass(hl, 0.012, float(o.get("ragged", 2.0)), 56, 0.3, float(o.get("curtain", 96.0)), 0.5)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	# tepeden dökülen düz tutamlar (sabit doku)
	_flow_kind = "lie"
	_lift0 = 0.012
	var part: float = o.get("part", 0.0)
	for k in 14:
		var yw = lerpf(-150.0, 150.0, (k + 0.5) / 14.0) + j.call(4)
		if absf(yw) < 40.0:
			continue
		_flow(part + (yw - part) * 0.3, 10.0, yw, 94.0, 0.11, 0.0, 0.12)
	_lift0 = 0.014
	_flow_kind = "flow"
	# omuzdan aşağı sarkan perde (dikey, salınır)
	var drop: float = o.get("drop", 0.0)
	if drop > 0.0:
		var y0: float = o.get("drop_from", 105.0)
		var y1: float = o.get("drop_to", 255.0)
		var n = int(clampf((y1 - y0) / 9.0, 4.0, 40.0))
		for k in n:
			var yw = wrapf(lerpf(y0, y1, (k + 0.5) / n) + j.call(3), -180.0, 180.0)
			var a = absf(yw)
			var pe = lerpf(side, backp, clampf((a - 70.0) / 110.0, 0.0, 1.0)) if a >= 70.0 else side
			var d0 = _dir(yw, minf(pe, 150.0) - 8.0)
			var top = _c + d0 * (_real_r(d0) + 0.02)
			var hz = Vector3(d0.x, 0, d0.z).normalized()
			var r_out = Vector2(top.x - _c.x, top.z - _c.z).length()
			var start = top
			var L = drop * _rng.randf_range(0.92, 1.08)
			var pts = []
			for q in 9:
				var u = q / 8.0
				pts.append(start + Vector3(0, -L * u, 0) + hz * 0.07 * u * u)   # aşağı, sırta/omza oturacak kadar dışa (yelpaze değil)
			_taper = 5.0
			_ribbon(pts, 0.13, 0.22, Vector3(-hz.z, 0, hz.x))
			_taper = 1.0
	# önde omuzların önüne sarkan iki uzun tutam öbeği (Kushina/Hinata: saç omuzdan öne dökülür)
	var fd: float = o.get("front_drop", 0.0)
	if fd > 0.0:
		for sx in [-1.0, 1.0]:
			for k in 3:
				var yw = sx * (64.0 + k * 9.0)
				var d0 = _dir(yw, 140.0)
				var top = _c + d0 * (_real_r(d0) + 0.025)
				var hz = Vector3(d0.x, 0, d0.z).normalized()
				var pts = []
				for q in 9:
					var u = q / 8.0
					pts.append(top + Vector3(0, -fd * u, 0) + Vector3(0, 0, 0.06) * u * u + hz * 0.03 * u)
				_taper = 4.0
				_ribbon(pts, 0.07, 0.25, Vector3(-hz.z, 0, hz.x))
				_taper = 1.0
	# yüz çerçevesi
	var face: float = o.get("face", 0.0)
	if face > 0.0 and not _banded:
		for sx in [-1.0, 1.0]:
			_flow(sx * 46.0, 50.0, sx * 54.0, face, 0.09, 0.15, 0.3)
			_flow(sx * 58.0, 58.0, sx * 64.0, face - 6.0, 0.08, 0.1, 0.3)
	if _banded:
		return
	_lift0 = 0.03   # kâkül alın/kaş geometrisinin önünde (kadın yüzü öne çıkık; 0.014'te yüzün içinde kalıp görünmüyordu)
	var bang: String = o.get("bang", "none")
	var bl: float = o.get("bang_len", 104.0)
	match bang:
		"hime":
			_taper = 6.0
			for k in 9:
				var yw = lerpf(-42.0, 42.0, k / 8.0)
				_flow(yw * 0.5, 30.0, yw, bl + j.call(1), 0.1, 0.1, 0.3)
			_taper = 1.0
		"side":
			# yana süpürülmüş kâkül: ayrığın KARŞI yanına çapraz iner, gözü örter (ref'lerde göz yarı/tam kapalı)
			_taper = 3.0
			var sgn = -signf(part) if part != 0.0 else -1.0
			for k in 7:
				var ye = part * 0.3 + sgn * lerpf(0.0, 50.0, k / 6.0)
				_flow(part, 24.0, ye, bl - absf(ye - part) * 0.08 + j.call(3), 0.13, 0.45, 0.3)
			_taper = 1.0
		"center":
			for sx in [-1.0, 1.0]:
				for k in 3:
					var ye = sx * (14.0 + k * 12.0)
					_flow(sx * 4.0, 28.0, ye, bl + k * 6.0 + j.call(2), 0.1, 0.2, 0.3)
		"spiky":
			for k in 7:
				var ye = lerpf(-40.0, 40.0, k / 6.0) + j.call(4)
				_flow(ye * 0.4, 28.0, ye, bl + j.call(6), 0.085, 0.3, 0.3)
	_lift0 = 0.014

## K1 — Sakura (1-0.jpg): çene boyu, yandan ayrık; büyük yana süpürülmüş kâkül bir gözün üstüne
static func _f1() -> void:
	_long({"front": 70.0, "side": 152.0, "back": 140.0, "curtain": 98.0, "bang": "side", "bang_len": 124.0, "part": 30.0, "face": 150.0})


## K2 — Kushina (2-0.jpg): çok uzun düz, ortadan ayrık; yüz çerçevesi göğse, arkada bele doğru perde
static func _f2() -> void:
	_long({"front": 64.0, "side": 156.0, "back": 150.0, "curtain": 94.0, "bang": "center", "bang_len": 112.0, "face": 156.0, "drop": 1.0, "front_drop": 0.36})


## K3 — Karin (3-0.jpg): uzun, uçlar dişli; sivri dağınık kâkül; omuz altına perde
static func _f3() -> void:
	_long({"front": 70.0, "side": 154.0, "back": 150.0, "curtain": 96.0, "bang": "spiky", "bang_len": 112.0, "face": 152.0, "drop": 0.24, "ragged": 7.0})


## K4 — Hinata (4-0.jpg): kaş hizasında dümdüz kesik (hime) kâkül, çeneye yüz çerçevesi, uzun düz perde
static func _f4() -> void:
	_long({"front": 74.0, "side": 152.0, "back": 150.0, "curtain": 96.0, "bang": "hime", "bang_len": 106.0, "face": 150.0, "drop": 0.5, "front_drop": 0.2})


## K5 — Kurenai (5-0.jpg): omuz altına dalgalı-dağınık uzun saç, dişli uçlar, sivri kâkül
static func _f5() -> void:
	_long({"front": 70.0, "side": 154.0, "back": 152.0, "curtain": 94.0, "bang": "spiky", "bang_len": 104.0, "face": 154.0, "drop": 0.16, "ragged": 9.0})


## K6 — Anko (6-0.jpg): tepede arkaya-yukarı fışkıran dikenli kuyruk; sivri kâkül alına
static func _f6() -> void:
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return 78.0
		if a < 95.0:
			return lerpf(78.0, 100.0, (a - 45.0) / 50.0)
		return lerpf(100.0, 116.0, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.01, 4.0, 40)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var back = Vector3(0, 0, -1)
	var tie_p = 40.0
	var td = _dir(180.0, tie_p)
	var tie = _c + td * (_real_r(td) + 0.012)
	var ax = (Vector3.UP * 0.55 + back * 0.85).normalized()
	var s1 = ax.cross(Vector3.RIGHT).normalized()
	var s2 = ax.cross(s1).normalized()
	for k in 11:
		var a = TAU * k / 11.0 + j.call(0.2)
		var dir = (ax + (s1 * cos(a) + s2 * sin(a)) * 0.9).normalized()
		var L = (0.2 if k % 2 == 0 else 0.15) + j.call(0.02)
		var pts = []
		for q in 9:
			var u = q / 8.0
			pts.append(tie + dir * L * u + Vector3(0, -0.02 * u * u, 0))
		_ribbon(pts, 0.07, 0.42)
	for k in 6:
		var yw = lerpf(-40.0, 40.0, (k + 0.5) / 6.0) + j.call(3)
		if _banded:
			var pt = 58.0
			while _under_band_top(yw, pt) and pt > 25.0:
				pt -= 3.0
			_shard(yw, pt, _dir(yw, pt) * 0.6 + Vector3.UP * 0.6 + back * 0.4, 0.5, 0.6, 0.4)
		else:
			_flow(yw, 56.0, yw * 1.1, 102.0 + j.call(5), 0.09, 0.15, 0.3)
	for sx in [-1.0, 1.0]:
		if not _banded:
			_flow(sx * 60.0, 64.0, sx * 66.0, 128.0, 0.08, 0.2, 0.3)


## Topuz: kafa yüzeyinde yaw/pitch noktasına oturan basık küre (rad m)
static func _bun(yaw: float, pitch: float, rad: float) -> void:
	var d = _dir(yaw, pitch)
	var cen = _c + d * (_real_r(d) + rad * 0.75)
	var bas = Basis.looking_at(-d, Vector3.UP if absf(d.y) < 0.95 else Vector3.FORWARD)
	var la = 8; var lo = 12
	var grid = []
	for i in la + 1:
		var row = []
		var th = PI * float(i) / la
		for k in lo + 1:
			var ph = TAU * float(k) / lo
			var v = Vector3(sin(th) * cos(ph), sin(th) * sin(ph), cos(th))
			row.append(cen + bas * (v * Vector3(rad, rad, rad * 0.8)))
		grid.append(row)
	for i in la:
		for k in lo:
			_quad(grid[i][k], grid[i][k + 1], grid[i + 1][k + 1], grid[i + 1][k])
			_quad(grid[i][k], grid[i + 1][k], grid[i + 1][k + 1], grid[i][k + 1])   # çift yüz (sarım yönü garanti)


## At kuyruğu: bağ noktasından aşağı-arkaya sarkan, uçları sivri tutam demeti (salınır)
static func _ponytail(yaw: float, pitch: float, length: float, spread := 0.04, n := 6) -> void:
	var d = _dir(yaw, pitch)
	var tie = _c + d * (_real_r(d) + 0.012)
	var hz = Vector3(d.x, 0, d.z).normalized() if Vector2(d.x, d.z).length() > 0.05 else Vector3(0, 0, -1)
	var side = Vector3(-hz.z, 0, hz.x)
	for k in n:
		var o = (k - (n - 1) * 0.5) / maxf(1.0, (n - 1) * 0.5)
		var L = length * _rng.randf_range(0.85, 1.1)
		var pts = []
		for q in 9:
			var u = q / 8.0
			pts.append(tie + hz * (0.05 * sin(u * PI) + 0.03 * u) + Vector3(0, -L * u, 0) + side * o * spread * u)
		_taper = 2.5
		_kind = "flow"
		_ribbon(pts, 0.06, 0.35, side)
		_taper = 1.0
	var knot = []
	for q in 5:
		knot.append(tie + d * (0.015 * q / 4.0))
	_ribbon(knot, 0.045, 1.0)


## Kısa bob kurucusu (çene boyu, düz)
static func _bob(o: Dictionary) -> void:
	var oo = {"front": 72.0, "side": 146.0, "back": 132.0, "curtain": 98.0}
	oo.merge(o, true)
	_long(oo)


static func _f7() -> void:   # Ino: uzun, bir gözü örten yan kâkül, arkada uzun kuyruk
	_long({"front": 68.0, "side": 146.0, "back": 120.0, "curtain": 98.0, "bang": "side", "bang_len": 132.0, "part": -30.0, "face": 146.0})
	_ponytail(180.0, 70.0, 0.62, 0.09, 10)


static func _f8() -> void:   # Tenten: tepede iki topuz, kısa kâkül
	_long({"front": 70.0, "side": 118.0, "back": 112.0, "curtain": 0.0, "bang": "center", "bang_len": 100.0, "face": 128.0})
	for sx in [-1.0, 1.0]:
		_bun(sx * 62.0, 40.0, 0.068)   # Striker 8: iki yanda iri topuz


static func _f9() -> void:   # Temari: iki yanda ikişer dikenli kuyruk, sivri kâkül
	_long({"front": 72.0, "side": 112.0, "back": 112.0, "curtain": 0.0, "bang": "spiky", "bang_len": 100.0, "ragged": 4.0})
	var back = Vector3(0, 0, -1)
	for sx in [-1.0, 1.0]:
		for t in [[118.0, 40.0], [142.0, 74.0]]:
			var d = _dir(sx * float(t[0]), float(t[1]))
			var tie = _c + d * (_real_r(d) + 0.01)
			var ax = (d * 0.7 + back * 0.5 + Vector3(sx * 0.3, 0.2, 0)).normalized()
			var s1 = ax.cross(Vector3.UP).normalized()
			var s2 = ax.cross(s1).normalized()
			for k in 6:
				var a = TAU * k / 6.0
				var dir = (ax + (s1 * cos(a) + s2 * sin(a)) * 0.8).normalized()
				var pts = []
				for q in 9:
					pts.append(tie + dir * 0.09 * q / 8.0)
				_ribbon(pts, 0.05, 0.42)


static func _f10() -> void:   # Taji: kabarık bere gibi şişkin yuvarlak saç
	_bob({"front": 84.0, "side": 120.0, "back": 116.0, "curtain": 0.0, "bang": "center", "bang_len": 104.0})
	for k in 7:
		_bun(lerpf(-150.0, 150.0, k / 6.0), 46.0, 0.06)
	_bun(0.0, 6.0, 0.075)


static func _f11() -> void:   # Rin: çene boyu düz bob, ortadan kâkül
	_bob({"bang": "center", "bang_len": 108.0, "face": 148.0})


static func _f12() -> void:   # Hinata (Boruto): kısa bob, düz kesik kâkül
	_bob({"bang": "hime", "bang_len": 108.0, "side": 142.0, "back": 128.0})


static func _f13() -> void:   # Sakura (genç): çene boyu, yana kâkül
	_bob({"bang": "side", "bang_len": 112.0, "part": 24.0, "face": 146.0})


static func _f14() -> void:   # Sakura (Boruto): kısa bob, alın açık, yandan ayrık
	_bob({"front": 62.0, "bang": "none", "part": 30.0, "face": 144.0, "side": 140.0, "back": 126.0})


static func _f15() -> void:   # Konan: kısa, bir gözü örten yan kâkül, tepede topuz
	_bob({"bang": "side", "bang_len": 128.0, "part": 34.0, "side": 136.0, "back": 120.0})
	_bun(-50.0, 34.0, 0.06)


static func _f16() -> void:   # Hanabi: uzun düz, ortadan ayrık, yüz çerçevesi
	_long({"front": 62.0, "side": 154.0, "back": 150.0, "curtain": 94.0, "bang": "center", "bang_len": 96.0, "face": 156.0, "drop": 0.42, "front_drop": 0.16})


static func _f17() -> void:   # Hakui: kısa bob, bir gözü örten büyük yan kâkül
	_bob({"bang": "side", "bang_len": 132.0, "part": -30.0, "face": 144.0})


static func _f18() -> void:   # Hinata (genç): kısa, düz kesik kâkül
	_bob({"bang": "hime", "bang_len": 106.0, "side": 134.0, "back": 120.0, "face": 140.0})


static func _f19() -> void:   # Ino (Boruto): uzun yan kâkül, yüksek uzun kuyruk
	_long({"front": 66.0, "side": 138.0, "back": 112.0, "curtain": 0.0, "bang": "side", "bang_len": 130.0, "part": 30.0, "face": 140.0})
	_ponytail(180.0, 44.0, 0.72, 0.1, 11)


static func _f20() -> void:   # Yugito: yana kâkül, kısa, ensede alçak kuyruk
	_bob({"bang": "side", "bang_len": 110.0, "part": 28.0, "side": 128.0, "back": 118.0})
	_ponytail(180.0, 104.0, 0.3, 0.03, 5)


static func _f21() -> void:   # Fū: kısa bob, sivri kâkül, dişli uçlar
	_bob({"bang": "spiky", "bang_len": 106.0, "side": 136.0, "back": 124.0, "ragged": 5.0})


static func _f22() -> void:   # Tenten (Boruto): arkada iki topuz, düz kesik kâkül
	_long({"front": 74.0, "side": 120.0, "back": 112.0, "curtain": 0.0, "bang": "hime", "bang_len": 104.0, "face": 128.0})
	for sx in [-1.0, 1.0]:
		_bun(sx * 130.0, 44.0, 0.05)


static func _f23() -> void:   # Sarada: çene boyu, yana süpürülmüş kâkül
	_bob({"bang": "side", "bang_len": 118.0, "part": -26.0, "face": 148.0, "side": 148.0})


static func _f24() -> void:   # Mei: tepede topuz, bir gözü örten uzun yan kâkül, uzun yan tutamlar
	_long({"front": 66.0, "side": 154.0, "back": 150.0, "curtain": 94.0, "bang": "side", "bang_len": 136.0, "part": -32.0, "face": 156.0, "front_drop": 0.34, "drop": 1.0})
	_bun(180.0, 18.0, 0.05)


# ================================================================ DLC / etkinlik saçları (refs/hair_dlc, anahtar d<index>)
## Dikenli kısa saç kurucusu. o: {L: diken boy ölçeği, up: yukarı ağırlığı, lean: Vector3 savrulma, back: geriye yatma,
##   splay: dışa açılma, jit: düzensizlik, front/side/backp: saç çizgisi, rows: sıra sayısı çarpanı, bang: "spiky"/"none"/"side",
##   bang_len, face: yüz çerçevesi uç pitch, hang: arkadan sarkan dikenli yele boyu (R, 0 = yok), cover: göz örten yan kâkül (+1/-1/0)}
static func _spiky(o: Dictionary) -> void:
	var front: float = o.get("front", 80.0)
	var side: float = o.get("side", 98.0)
	var backp: float = o.get("backp", 112.0)
	var hl = func(yw: float) -> float:
		var a = absf(yw)
		if a < 45.0:
			return front
		if a < 95.0:
			return lerpf(front, side, (a - 45.0) / 50.0)
		return lerpf(side, backp, clampf((a - 95.0) / 60.0, 0.0, 1.0))
	_mass(hl, 0.011, 3.0, 40)
	var j = func(a: float) -> float: return _rng.randf_range(-a, a)
	var back = Vector3(0, 0, -1)
	var L: float = o.get("L", 0.7)
	var up: float = o.get("up", 0.5)
	var lean: Vector3 = o.get("lean", Vector3.ZERO)
	var bk: float = o.get("back", 0.25)
	var splay: float = o.get("splay", 0.3)
	var jit: float = o.get("jit", 0.15)
	for row in [[6.0, 7, 1.0], [26.0, 12, 1.05], [46.0, 14, 1.0], [66.0, 14, 0.85], [84.0, 12, 0.6]]:
		var n_sp: int = row[1]
		var off = _rng.randf_range(0.0, 360.0 / n_sp)
		for k in n_sp:
			var yw = wrapf(off + k * 360.0 / n_sp + j.call(8), -180.0, 180.0)
			var pt: float = row[0] + j.call(5)
			if row[0] >= 66.0 and absf(yw) < 45.0:
				continue
			while _under_band_top(yw, pt) and pt > 15.0:
				pt -= 3.0
			var n = _dir(yw, pt)
			var hz = Vector3(sin(deg_to_rad(yw)), 0, cos(deg_to_rad(yw)))
			var uw = up * (1.0 - float(row[0]) / 120.0)
			var dir = n * 0.6 + Vector3.UP * uw + hz * splay + back * bk + lean + Vector3(j.call(jit), j.call(jit), j.call(jit))
			if absf(yw) > 120.0:
				dir += back * 0.3
			_shard(yw, pt, dir, L * float(row[2]) * _rng.randf_range(0.85, 1.15), 0.8 * _rng.randf_range(0.9, 1.1), 0.4, Vector3(0, -0.03, -0.03))
	# arka-alt: dağınık kısa dikenler (yaka olmasın)
	for k in 8:
		var yw = wrapf(lerpf(110.0, 250.0, (k + 0.5) / 8.0) + j.call(10), -180.0, 180.0)
		var pt = 76.0 + _rng.randf_range(0.0, 20.0)
		if _under_band_top(yw, pt) or _in_band(yw, pt):
			continue
		var n = _dir(yw, pt)
		var dn = (_dir(yw, pt + 6.0) - _dir(yw, pt - 6.0)).normalized()
		_shard(yw, pt, n * 0.7 + dn * 0.4 + back * 0.2 + lean * 0.3, L * _rng.randf_range(0.55, 0.85), 0.7, 0.4)
	# arkadan sarkan dikenli yele (Jiraiya, Madara, Indra)
	var hang: float = o.get("hang", 0.0)
	if hang > 0.0:
		for row in [[70.0, 12], [92.0, 12], [112.0, 10]]:
			for k in row[1]:
				var yw = wrapf(lerpf(70.0, 290.0, (k + 0.5) / row[1]) + j.call(8), -180.0, 180.0)
				var pt = float(row[0]) + j.call(6)
				while _under_band_top(yw, pt) and pt > 20.0:
					pt -= 3.0
				var n = _dir(yw, pt)
				var dn = (_dir(yw, pt + 6.0) - _dir(yw, pt - 6.0)).normalized()
				_shard(yw, pt, dn * 1.0 + n * 0.4 + back * 0.2, hang * _rng.randf_range(0.85, 1.15), 1.0, 0.4, Vector3(0, -0.05, 0))
	# bele/kalçaya inen dikenli yele (Madara, Jiraiya): katmanlı, uçları sivri, sırta yayılan uzun tutamlar
	var mane: float = o.get("mane", 0.0)
	if mane > 0.0:
		var mw: float = o.get("mane_w", 0.16)
		for lay in [[1.0, 13, 118.0, 0.03], [0.82, 12, 104.0, 0.06], [0.62, 11, 90.0, 0.1], [0.42, 10, 78.0, 0.14]]:
			var nn: int = lay[1]
			for k in nn:
				var yw = wrapf(lerpf(84.0, 276.0, (k + 0.5) / nn) + j.call(5), -180.0, 180.0)
				var pt: float = float(lay[2]) + j.call(4)
				while _under_band_top(yw, pt) and pt > 20.0:
					pt -= 3.0
				var d0 = _dir(yw, pt)
				var top = _c + d0 * (_real_r(d0) + 0.015)
				var hz = Vector3(d0.x, 0, d0.z).normalized()
				var Lm = mane * float(lay[0]) * _rng.randf_range(0.88, 1.12)
				var outw: float = float(lay[3]) * _rng.randf_range(0.8, 1.2)
				var pts = []
				for q in 9:
					var u = q / 8.0
					# önce dışa kabarır, sonra aşağı dökülür; uç hafif dışa kıvrık (diken)
					pts.append(top + Vector3(0, -Lm * u, 0) + hz * outw * (sin(u * PI * 0.6) + 0.35 * u * u) + Vector3(0, 0, -0.05) * u)
				_taper = 2.2
				_ribbon(pts, mw * _rng.randf_range(0.85, 1.15), 0.3, Vector3(-hz.z, 0, hz.x))
				_taper = 1.0
	var mfd: float = o.get("front_drop", 0.0)
	if mfd > 0.0 and not _banded:
		for sx in [-1.0, 1.0]:
			for k in 3:
				var yw = sx * (58.0 + k * 10.0)
				var d0 = _dir(yw, 132.0)
				var top = _c + d0 * (_real_r(d0) + 0.025)
				var hz = Vector3(d0.x, 0, d0.z).normalized()
				var pts = []
				var Lf = mfd * (1.0 - k * 0.12)
				for q in 9:
					var u = q / 8.0
					pts.append(top + Vector3(0, -Lf * u, 0) + Vector3(0, 0, 0.05) * u * u + hz * 0.04 * u)
				_taper = 2.5
				_ribbon(pts, 0.08, 0.28, Vector3(-hz.z, 0, hz.x))
				_taper = 1.0
	var face: float = o.get("face", 0.0)
	if face > 0.0 and not _banded:
		for sx in [-1.0, 1.0]:
			_flow(sx * 52.0, 60.0, sx * 58.0, face, 0.1, 0.2, 0.3)
			_flow(sx * 64.0, 66.0, sx * 70.0, face - 8.0, 0.08, 0.15, 0.3)
	var cover: float = o.get("cover", 0.0)
	if _banded:
		for k in 6:
			var yw = lerpf(-50.0, 50.0, (k + 0.5) / 6.0) + j.call(4)
			var pt = 58.0
			while _under_band_top(yw, pt) and pt > 25.0:
				pt -= 3.0
			_shard(yw, pt, _dir(yw, pt) * 0.6 + Vector3.UP * maxf(up, 0.4) + back * 0.2 + lean, L * 0.8, 0.8, 0.4)
		return
	if cover != 0.0:
		_taper = 2.0
		_lift0 = 0.02
		for t in [[0.0, 128.0, 0.13], [16.0, 138.0, 0.17], [30.0, 142.0, 0.15], [44.0, 140.0, 0.12]]:
			_flow(-cover * 20.0 + cover * float(t[0]) * 0.4, 18.0, cover * float(t[0]), float(t[1]), float(t[2]), 0.45, 0.3)
		_taper = 1.0
		_lift0 = 0.014
		return
	match String(o.get("bang", "spiky")):
		"spiky":
			for k in 6:
				var yw = lerpf(-40.0, 40.0, (k + 0.5) / 6.0) + j.call(3)
				_flow(yw, 54.0, yw * 1.1 + j.call(4), float(o.get("bang_len", 100.0)) + j.call(5), 0.09, 0.08, 0.3)
		"up":
			for k in 6:
				var yw = lerpf(-46.0, 46.0, (k + 0.5) / 6.0) + j.call(3)
				_shard(yw, 60.0, Vector3.UP * 0.9 + _dir(yw, 60.0) * 0.35 + back * 0.15 + lean, L * 0.9, 0.85, 0.4)


static func _d0() -> void:   # Jiraiya: uzun dikenli yele arkaya ve aşağı, yüz çerçevesi
	_spiky({"L": 0.9, "up": 0.4, "back": 0.6, "splay": 0.35, "hang": 1.1, "mane": 0.5, "mane_w": 0.13, "face": 150.0, "bang": "spiky", "bang_len": 104.0})


static func _d1() -> void:   # Orochimaru: uzun düz, ortadan ayrık, yüze dökülen uzun kâkül tutamları
	_long({"front": 60.0, "side": 156.0, "back": 150.0, "curtain": 94.0, "bang": "center", "bang_len": 138.0, "face": 158.0, "drop": 0.5, "front_drop": 0.3})


static func _d2() -> void:   # Tsunade: uzun, yandan ayrık; arkada iki alçak kuyruk
	_long({"front": 62.0, "side": 152.0, "back": 120.0, "curtain": 96.0, "bang": "side", "bang_len": 112.0, "part": 20.0, "face": 154.0, "front_drop": 0.14})
	for sx in [-1.0, 1.0]:
		_ponytail(sx * 150.0, 104.0, 0.52, 0.05, 6)


static func _d3() -> void:   # Madara: devasa dikenli yele, bir gözü örten kâkül
	_spiky({"L": 1.0, "up": 0.35, "back": 0.6, "splay": 0.45, "hang": 1.1, "cover": 1.0, "mane": 0.56, "front_drop": 0.3})


static func _d4() -> void:   # Obito: kısa dağınık dikenli
	_spiky({"L": 0.6, "up": 0.55, "splay": 0.35, "jit": 0.3, "bang": "spiky", "bang_len": 98.0})


static func _d5() -> void:   # Hashirama: uzun düz, ortadan ayrık, yüz çerçevesi
	_long({"front": 60.0, "side": 156.0, "back": 150.0, "curtain": 94.0, "bang": "center", "bang_len": 104.0, "face": 158.0, "drop": 0.52, "front_drop": 0.2})


static func _d6() -> void:   # Tobirama: dimdik yukarı, arkaya yatık dikenler
	_spiky({"L": 0.8, "up": 0.9, "back": 0.45, "splay": 0.2, "bang": "up"})


static func _d8() -> void:   # Minato: dikenli tepe + çeneye inen uzun yan kâküller
	_spiky({"L": 0.85, "up": 0.5, "splay": 0.45, "face": 150.0, "bang": "spiky", "bang_len": 108.0})


static func _d9() -> void:   # Zabuza: kısa sert dikenler arkaya
	_spiky({"L": 0.55, "up": 0.3, "back": 0.6, "splay": 0.3, "bang": "none"})


static func _d10() -> void:   # Haku: uzun düz, arkada topuz, öne sarkan yüz tutamları
	_long({"front": 64.0, "side": 152.0, "back": 120.0, "curtain": 96.0, "bang": "center", "bang_len": 104.0, "face": 154.0, "front_drop": 0.26})
	_bun(180.0, 54.0, 0.05)


static func _d11() -> void:   # Haku (ilk karşılaşma): uzun açık düz saç
	_long({"front": 64.0, "side": 154.0, "back": 150.0, "curtain": 94.0, "bang": "center", "bang_len": 106.0, "face": 154.0, "drop": 0.36, "front_drop": 0.24})


static func _d14() -> void:   # Sasuke (The Last): orta boy dağınık, göze kâkül, yan tutamlar
	_bob({"front": 76.0, "side": 136.0, "back": 124.0, "bang": "spiky", "bang_len": 118.0, "face": 140.0, "ragged": 6.0})


static func _d15() -> void:   # Ino (erkek): geriye taranmış uzun, tek uzun yüz tutamı
	_long({"front": 56.0, "side": 150.0, "back": 150.0, "curtain": 96.0, "bang": "none", "drop": 0.26})
	_flow(-30.0, 40.0, -46.0, 150.0, 0.12, 0.35, 0.3)


static func _d16() -> void:   # Inojin: kısa, gözü örten yan kâkül, ensede küçük kuyruk
	_bob({"bang": "side", "bang_len": 130.0, "part": 30.0, "side": 132.0, "back": 120.0})
	_ponytail(180.0, 96.0, 0.14, 0.03, 4)


static func _d17() -> void:   # Gai: kâse kesim
	_s9()


static func _d18() -> void:   # Mei (DLC): uzun, gözü örten kâkül, tepede uzun topuz
	_long({"front": 64.0, "side": 154.0, "back": 150.0, "curtain": 94.0, "bang": "side", "bang_len": 136.0, "part": -32.0, "face": 156.0, "drop": 1.0, "front_drop": 0.36})
	_bun(180.0, 12.0, 0.045)
	_shard(180.0, 4.0, Vector3.UP, 0.9, 0.5, 0.6)


static func _d20() -> void:   # Naruto (The Last): kısa kabarık dikenler
	_spiky({"L": 0.5, "up": 0.6, "splay": 0.35, "jit": 0.25, "bang": "spiky", "bang_len": 96.0})


static func _d22() -> void:   # Kakashi (Hokage): geniş açılan dağınık büyük dikenler
	_spiky({"L": 1.0, "up": 0.5, "splay": 0.7, "jit": 0.3, "bang": "spiky", "bang_len": 104.0})


static func _d23() -> void:   # Neji (jōnin): uzun düz, ortadan ayrık
	_long({"front": 62.0, "side": 154.0, "back": 150.0, "curtain": 94.0, "bang": "center", "bang_len": 112.0, "face": 154.0, "drop": 0.5})


static func _d24() -> void:   # Neji (bantsız): uzun düz, açık alın, yüz çerçevesi
	_long({"front": 56.0, "side": 154.0, "back": 150.0, "curtain": 94.0, "bang": "none", "face": 154.0, "drop": 0.5})


static func _d25() -> void:   # Shisui: kısa kıvırcık dağınık
	_spiky({"L": 0.5, "up": 0.4, "splay": 0.45, "jit": 0.45, "bang": "spiky", "bang_len": 98.0})


static func _d26() -> void:   # Asura: kısa dik dikenler
	_spiky({"L": 0.65, "up": 0.95, "back": 0.2, "splay": 0.25, "bang": "up"})


static func _d27() -> void:   # Kawaki: kısa dağınık, alına sivri kâkül
	_spiky({"L": 0.45, "up": 0.3, "splay": 0.3, "jit": 0.3, "bang": "spiky", "bang_len": 108.0})


static func _d28() -> void:   # Sakura (savaş sonrası): çene boyu, ortadan kâkül
	_bob({"bang": "center", "bang_len": 112.0, "face": 148.0})


static func _d29() -> void:   # Sakura (The Last): asimetrik bob, yana kâkül
	_bob({"bang": "side", "bang_len": 120.0, "part": 28.0, "side": 152.0, "face": 150.0})


static func _d30() -> void:   # Nagato (kurucu): omuz boyu düz, ortadan ayrık
	_long({"front": 64.0, "side": 154.0, "back": 150.0, "curtain": 94.0, "bang": "center", "bang_len": 116.0, "face": 154.0, "drop": 0.12})


static func _d32() -> void:   # Itachi (reanimasyon): uzun yüz tutamları, alçak at kuyruğu
	_long({"front": 64.0, "side": 152.0, "back": 120.0, "curtain": 96.0, "bang": "center", "bang_len": 126.0, "face": 154.0})
	_ponytail(180.0, 102.0, 0.34, 0.03, 5)


static func _d33() -> void:   # Indra: dağınık dikenli, arkada sarkan dikenler, yüz tutamları
	_spiky({"L": 0.8, "up": 0.45, "splay": 0.5, "jit": 0.3, "hang": 1.1, "mane": 0.32, "mane_w": 0.13, "face": 150.0, "bang": "spiky", "bang_len": 112.0})


static func _d34() -> void:   # Madara (Altı Yol): geriye taranmış alın, arkada devasa dikenli yele
	_spiky({"front": 66.0, "L": 0.8, "up": 0.3, "back": 0.8, "splay": 0.3, "hang": 1.1, "bang": "none", "mane": 0.6})


static func _d35() -> void:   # Temari (Boruto): dört iri dikenli tutam, yana kâkül
	_long({"front": 72.0, "side": 120.0, "back": 112.0, "curtain": 0.0, "bang": "side", "bang_len": 112.0, "part": 20.0})
	var back = Vector3(0, 0, -1)
	for sx in [-1.0, 1.0]:
		for t in [[110.0, 44.0], [130.0, 84.0]]:
			var d = _dir(sx * float(t[0]), float(t[1]))
			var tie = _c + d * (_real_r(d) + 0.01)
			var ax = (d * 0.8 + back * 0.3 + Vector3(sx * 0.4, 0.1, 0)).normalized()
			var s1 = ax.cross(Vector3.UP).normalized()
			var s2 = ax.cross(s1).normalized()
			for k in 8:
				var a = TAU * k / 8.0
				var dir = (ax + (s1 * cos(a) + s2 * sin(a)) * 0.9).normalized()
				var pts = []
				for q in 9:
					pts.append(tie + dir * 0.12 * q / 8.0)
				_ribbon(pts, 0.065, 0.42)


static func _d36() -> void:   # Konohamaru (genç): dimdik dikenli
	_spiky({"L": 0.75, "up": 1.0, "splay": 0.3, "bang": "up"})


static func _d37() -> void:   # Naruto (Oiroke): yüksek iki uzun kuyruk, sivri kâkül
	_long({"front": 70.0, "side": 140.0, "back": 120.0, "curtain": 0.0, "bang": "spiky", "bang_len": 110.0, "face": 142.0})
	for sx in [-1.0, 1.0]:
		_ponytail(sx * 95.0, 34.0, 0.5, 0.16, 12)   # iri, yelpaze gibi açılan ikiz kuyruk


static func _d39() -> void:   # Kushina (görev): çok uzun düz, kâkül, uzun yüz tutamları
	_long({"front": 66.0, "side": 156.0, "back": 150.0, "curtain": 94.0, "bang": "spiky", "bang_len": 112.0, "face": 158.0, "drop": 1.0, "front_drop": 0.4})


static func _d40() -> void:   # Kaguya: yerlere kadar uzun düz saç, ortadan ayrık
	_long({"front": 60.0, "side": 156.0, "back": 150.0, "curtain": 94.0, "bang": "center", "bang_len": 100.0, "face": 158.0, "drop": 1.38, "front_drop": 0.85})


static func _d41() -> void:   # Boruto (Karma): dağınık dikenli, tepede kıvrık tutam, alına iri kâkül
	_spiky({"L": 0.6, "up": 0.5, "splay": 0.4, "jit": 0.3, "bang": "spiky", "bang_len": 112.0})
	_shard(0.0, 6.0, Vector3.UP + Vector3(0, 0, 0.5), 0.7, 0.7, 0.4)


static func _d42() -> void:   # Boruto (Prolog): dağınık, bir yana savruk
	_spiky({"L": 0.65, "up": 0.5, "lean": Vector3(0.4, 0, 0), "splay": 0.35, "jit": 0.3, "bang": "spiky", "bang_len": 110.0})


static func _d43() -> void:   # Sasori: kısa dağınık bob, dişli uçlar
	_bob({"bang": "spiky", "bang_len": 108.0, "side": 128.0, "back": 120.0, "ragged": 8.0})


static func _d44() -> void:   # Amado: kısa, yandan ayrık, geriye-yana taranmış (alın açık)
	_s23()


static func _d45() -> void:   # Kagami: kısa dağınık, göze kâkül, yan tutamlar
	_spiky({"L": 0.5, "up": 0.3, "splay": 0.35, "jit": 0.3, "face": 136.0, "bang": "spiky", "bang_len": 112.0})


# ------------------------------------------------------------------ Online etkinlik ödülü saçları (refs/hair_ev, v1)
static func _e0() -> void:   # Shikadai: kısa yanlar, tepede yukarı dikilen dikenli ananas topuzu, iki yan tutam
	_bob({"front": 74.0, "side": 104.0, "back": 102.0, "curtain": 0.0, "bang": "none"})
	var tie = _c + _dir(180.0, 22.0) * (_real_r(_dir(180.0, 22.0)) + 0.01)
	for k in 9:
		var a = TAU * k / 9.0
		var dir = (Vector3.UP * 1.0 + Vector3(0, 0, -0.35) + Vector3(cos(a), 0, sin(a)) * 0.55).normalized()
		var pts = []
		for q in 9:
			pts.append(tie + dir * 0.11 * q / 8.0)
		_ribbon(pts, 0.05, 0.42)
	for sx in [-1.0, 1.0]:
		_flow(sx * 60.0, 70.0, sx * 64.0, 118.0, 0.05, 0.1, 0.3)


static func _e2() -> void:   # Sumire (Akademi): uzun düz, düz kesik kâkül, yüz çerçevesi
	_long({"front": 70.0, "side": 154.0, "back": 150.0, "curtain": 96.0, "bang": "hime", "bang_len": 112.0, "face": 154.0, "drop": 0.3, "front_drop": 0.2})


static func _e3() -> void:   # Itachi (ANBU): orta boy, ortadan ayrık uzun yüz tutamları, ensede kısa kuyruk
	_long({"front": 66.0, "side": 146.0, "back": 120.0, "curtain": 96.0, "bang": "center", "bang_len": 118.0, "face": 150.0})
	_ponytail(180.0, 100.0, 0.2, 0.03, 4)


static func _e4() -> void:   # Naruto (genç): kısa sivri dikenler her yöne, sivri kâkül
	_spiky({"L": 0.62, "up": 0.6, "splay": 0.5, "jit": 0.2, "bang": "spiky", "bang_len": 100.0})


static func _e5() -> void:   # Sasuke (genç): arkada yukarı kalkık ördek kuyruğu dikenleri, çeneye inen iki uzun yüz tutamı
	_spiky({"L": 0.62, "up": 0.35, "back": 0.75, "splay": 0.25, "face": 146.0, "bang": "spiky", "bang_len": 112.0})


static func _e6() -> void:   # Geriye taranmış (erkek): kısa, alın açık, tepeden enseye yatık
	_bob({"front": 58.0, "side": 102.0, "back": 112.0, "curtain": 0.0, "bang": "none", "ragged": 3.0})


static func _e7() -> void:   # Topuz (kadın): başın arkasında yüksek topuz, iki ince yüz tutamı
	_bob({"front": 66.0, "side": 108.0, "back": 104.0, "curtain": 0.0, "bang": "none"})
	_bun(180.0, 40.0, 0.06)
	for sx in [-1.0, 1.0]:
		_flow(sx * 38.0, 60.0, sx * 44.0, 140.0, 0.04, 0.05, 0.25)


static func _e8() -> void:   # Tayuya: uzun düz, ortadan ayrık, omuzdan sarkan perde
	_long({"front": 64.0, "side": 156.0, "back": 150.0, "curtain": 94.0, "bang": "center", "bang_len": 108.0, "face": 156.0, "drop": 0.42, "front_drop": 0.22})


static func _e9() -> void:   # Kimimaro: omuz boyu düz, ortadan ayrık, çeneye inen kâkül tutamları
	_long({"front": 60.0, "side": 152.0, "back": 140.0, "curtain": 94.0, "bang": "center", "bang_len": 130.0, "face": 154.0, "drop": 0.14})


static func _e10() -> void:   # Kagemasa: iri, dağınık, yana ve arkaya fırlayan büyük dikenler, göze kâkül
	_spiky({"L": 1.0, "up": 0.4, "back": 0.5, "splay": 0.6, "jit": 0.3, "face": 140.0, "bang": "spiky", "bang_len": 116.0})


static func _e11() -> void:   # Sumire (genin): uzun düz, ortadan ayrık kâkül, yüz çerçevesi
	_long({"front": 66.0, "side": 154.0, "back": 150.0, "curtain": 94.0, "bang": "center", "bang_len": 110.0, "face": 154.0, "drop": 0.3, "front_drop": 0.16})


static func _e12() -> void:   # Hanabi (Boruto): uzun, gözün yanından inen yan kâkül, uzun yüz tutamları
	_long({"front": 62.0, "side": 156.0, "back": 150.0, "curtain": 94.0, "bang": "side", "bang_len": 126.0, "part": -24.0, "face": 158.0, "drop": 0.48, "front_drop": 0.24})


static func _e13() -> void:   # Kakashi (Gaiden): genç, sola yatık büyük dikenler, alına sivri kâkül
	_spiky({"L": 0.85, "up": 0.6, "lean": Vector3(0.3, 0, 0), "splay": 0.45, "jit": 0.25, "bang": "spiky", "bang_len": 106.0})


static func _e14() -> void:   # Neji (genç): uzun düz, ortadan ayrık, yüz çerçevesi, ensede bağlı
	_long({"front": 62.0, "side": 154.0, "back": 140.0, "curtain": 94.0, "bang": "center", "bang_len": 108.0, "face": 154.0, "drop": 0.46})


static func _e15() -> void:   # Himawari: çene boyu bob, düz kesik kâkül, tepede iki kalkık tutam
	_bob({"bang": "hime", "bang_len": 106.0, "side": 128.0, "back": 120.0, "face": 132.0})
	_shard(0.0, 14.0, Vector3.UP + Vector3(0, 0, 0.3), 0.45, 0.35, 0.4)
	_shard(20.0, 18.0, Vector3.UP + Vector3(0.2, 0, 0.2), 0.35, 0.3, 0.4)


static func _e22() -> void:   # Sakura (genç): uzun düz, geniş alın, ortadan ayrık uzun yüz tutamları
	_long({"front": 58.0, "side": 154.0, "back": 150.0, "curtain": 94.0, "bang": "center", "bang_len": 104.0, "face": 156.0, "drop": 0.3, "front_drop": 0.2})


static func _e23() -> void:   # Cho-Chō: iri kabarık dikenli tepe, bir gözü örten uzun yan kâkül, uzun arka
	_spiky({"L": 0.9, "up": 0.55, "back": 0.4, "splay": 0.55, "hang": 1.3, "cover": 1.0})


static func _e26() -> void:   # Wasabi: kısa kabarık, alnı örten kâkül, yanlardan kıvrık uçlar
	_bob({"front": 80.0, "side": 116.0, "back": 112.0, "curtain": 0.0, "bang": "spiky", "bang_len": 100.0, "ragged": 6.0})


static func _e27() -> void:   # Metal Lee: kabarık kâse kesim
	_s9()


static func _e28() -> void:   # Denki: kısa, alnı örten düz kâkül, ensede sivri kuyruk
	_bob({"front": 78.0, "side": 118.0, "back": 116.0, "curtain": 0.0, "bang": "hime", "bang_len": 104.0})
	_ponytail(180.0, 70.0, 0.22, 0.04, 5)


static func _e29() -> void:   # Tsubaki: düz kesik kâkül, yüz tutamları, tepeden yüksek uzun kuyruk
	_bob({"front": 76.0, "side": 128.0, "back": 112.0, "curtain": 0.0, "bang": "hime", "bang_len": 106.0, "face": 140.0})
	_ponytail(180.0, 30.0, 0.42, 0.05, 7)


static func _e30() -> void:   # Eida: çok uzun düz, düz kesik kâkül, uzun yüz tutamları
	_long({"front": 70.0, "side": 156.0, "back": 150.0, "curtain": 94.0, "bang": "hime", "bang_len": 110.0, "face": 158.0, "drop": 1.2, "front_drop": 0.45})


static func _e31() -> void:   # Merz: uzun düz, ortadan ayrık, omuzlara dökülen
	_long({"front": 66.0, "side": 154.0, "back": 150.0, "curtain": 94.0, "bang": "center", "bang_len": 114.0, "face": 154.0, "drop": 0.3, "front_drop": 0.2})


static func _e32() -> void:   # Daemon: kâse kesim, alnı örten kâkül, yanlarda kalkık kedi kulağı uçlar
	_bob({"front": 80.0, "side": 120.0, "back": 116.0, "curtain": 0.0, "bang": "hime", "bang_len": 104.0})
	for sx in [-1.0, 1.0]:
		_shard(sx * 70.0, 34.0, (Vector3.UP + Vector3(sx * 0.6, 0, 0)).normalized(), 0.5, 0.5, 0.4)


static func _e33() -> void:   # Deidara: tepede yüksek at kuyruğu, bir gözü örten uzun yan kâkül, uzun yüz tutamı
	_long({"front": 68.0, "side": 150.0, "back": 150.0, "curtain": 94.0, "bang": "side", "bang_len": 136.0, "part": 30.0, "face": 154.0, "front_drop": 0.2, "drop": 0.28})
	_ponytail(180.0, 28.0, 0.42, 0.05, 7)


static func _e34() -> void:   # Deidara (bantsız): aynı kesim, tepede tutam belirgin
	_e33()
	_bun(180.0, 26.0, 0.035)


static func _e35() -> void:   # Utakata: orta boy dağınık, bir gözü örten uzun kâkül, arkada sivri uçlar
	_bob({"front": 72.0, "side": 134.0, "back": 126.0, "bang": "side", "bang_len": 132.0, "part": -26.0, "face": 140.0, "ragged": 6.0})


static func _e36() -> void:   # Shizune: kısa dağınık, yanlara savrulan uçlar, alına kâkül
	_bob({"front": 76.0, "side": 120.0, "back": 114.0, "curtain": 0.0, "bang": "spiky", "bang_len": 104.0, "ragged": 8.0})

