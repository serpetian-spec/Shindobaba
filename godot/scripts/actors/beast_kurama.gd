class_name BeastKurama
extends RefCounted
## Kurama — Dokuz Kuyruk (v2, baştan). Referans: _tmp/ref/kurama (Kurama2 önden çömelik, Kurama_Sealed kafes önü,
## Kyuubi_attack_on_Konoha yandan siluet, Kurama_Stares_Down yüz yakın, Kurama_Revived manga önden oturuş)
## Referanstan okunan yapı:
##  - DÜZ turuncu-kızıl (doku/leke yok, cel), alt yüzler koyu kızıl gölge
##  - üst gövde insan gibi ve İRİ: omuz kütleleri başın hizasından yüksek ve çok geniş; baş omuzların arasında, öne-aşağı sarkık
##  - kollar uzun ve kaslı (kalın pazı, dirsekte sivri kürk), beş parmaklı uzun pençeli eller yere açık basar
##  - bel ince, sırt kambur; arka bacaklar tilki (diz önde, topuk geride yukarıda)
##  - baş: uçurtma biçimi — yanaklarda geriye sivri iri kürk tutamları, çeneye doğru daralan İNCE sivri burun, küçük siyah burun ucu
##  - göz: burun kökünün iki yanında, dış köşe yukarı çekik; kızıl, yarık bebek. Gözü saran SİYAH bant kulağın iç yüzüne kesintisiz çıkar
##  - kulak: başın 1.5 katı uzunlukta, YASSI yaprak biçimli (boynuz değil), yukarı-geri-dışa; iç yüzü siyah
##  - ağız yanağa kadar uzun sırıtış: koyu dudak çizgisi, sıra sivri diş
##  - dokuz kuyruk: kol kadar KALIN, gövdeden uzun, yelpaze gibi yukarı-dışa açılır, yalnız son üçte birde sivrilir

const C := Color(0.95, 0.44, 0.1)
const CD := Color(0.7, 0.25, 0.06)
const CL := Color(1.0, 0.58, 0.22)
const BLK := Color(0.06, 0.035, 0.05)
const LIP := Color(0.1, 0.07, 0.08)
const FANG := Color(1.0, 0.98, 0.94)
const CLAW := Color(0.93, 0.91, 0.86)

static var _mat: ShaderMaterial


## Düz cel malzeme: ortak Props.toon sıva dokusu dev gövdede kirli çizgi/leke yapıyordu
static func mat() -> ShaderMaterial:
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = load("res://shaders/toon.gdshader")
		_mat.set_shader_parameter("rim_amount", 0.22)
	return _mat


static func _col(_t: float, _a: float, d: Vector3) -> Color:
	return C.lerp(CD, smoothstep(0.25, 0.8, -d.y) * 0.8)


## (t, açı) yolunu sıklaştır: şerit kavisli yüzeye otursun (seyrek noktalar kiriş gibi kesip gömülüyordu)
static func _dense(path: Array, k: int) -> Array:
	var out = []
	for i in path.size() - 1:
		for j in k:
			out.append((path[i] as Vector2).lerp(path[i + 1], float(j) / k))
	out.append(path[path.size() - 1])
	return out


static func _arc(p0: Vector3, p1: Vector3, p2: Vector3, n: int) -> Array:
	var out = []
	for i in n + 1:
		var u = float(i) / n
		out.append(p0.lerp(p1, u).lerp(p1.lerp(p2, u), u))
	return out


## Yassı sivri kürk tutamı (geniş yüzü `face` yönüne bakar)
static func _tuft(mb: MB, base: Vector3, dir: Vector3, ln: float, w: float, col := C, face := Vector3.UP, thick := 0.3) -> void:
	var d = dir.normalized()
	var side = d.cross(face)
	if side.length() < 0.1:
		side = d.cross(Vector3.RIGHT)
	side = side.normalized()
	var nrm = side.cross(d).normalized()
	var bend = nrm * ln * 0.1
	Loft.tube(mb, [base - d * w * 0.6, base + d * ln * 0.35 + bend, base + d * ln * 0.75 + bend * 0.6, base + d * ln],
		[Vector2(w * thick, w), Vector2(w * thick, w * 0.9), Vector2(w * thick * 0.6, w * 0.45), Vector2(0.02, 0.02)], col, 10, 3, true, true, Callable(), side)


## El / ayak: avuç + n parmak + pençe (yerel, ileri = -Z)
static func _hand(mb: MB, at: Vector3, s: float, n: int, spread: float, flen: float) -> void:
	mb.add("sphere", at + Vector3(0, 0.12, -0.1) * s, Vector3(1.7, 0.8, 1.9) * s, C, Vector3.ZERO, 14)
	for f in n:
		var fa = lerpf(-spread, spread, f / float(n - 1))
		var f0 = at + Vector3(sin(fa) * 0.55, 0.1, -0.7 - cos(fa) * 0.2) * s
		var f1 = at + Vector3(sin(fa) * (0.55 + flen * 0.5), 0.34, -0.7 - cos(fa) * flen * 0.55) * s
		var f2 = at + Vector3(sin(fa) * (0.55 + flen * 0.95), -0.16, -0.7 - cos(fa) * flen) * s
		Loft.tube(mb, [f0, f1, f2], [0.33 * s, 0.3 * s, 0.2 * s], C, 10, 4, true, true, _col)
		BeastRig.claw(mb, f2 + Vector3(0, 0.04, 0.06) * s, Vector3(sin(fa) * 0.3, -0.4, -1.0), 0.95 * s, 0.19 * s, CLAW)


static func build(r: BeastRig, root: Node3D) -> void:
	r.quadruped = true
	r.upright = false
	var M = mat()
	var HP = Vector3(0, 6.0, 4.8)
	r.hips = r._pivot(root, HP, "kalca_kok")
	# --- arka gövde: sağrı -> ince bel -> göğse doğru yükselen kambur
	var mh0 = MB.new()
	BeastSurf.tube(mh0, [Vector3(0, 5.6, 7.0) - HP, Vector3(0, 6.2, 5.5) - HP, Vector3(0, 6.3, 2.6) - HP, Vector3(0, 6.9, -0.4) - HP],
		[Vector2(1.3, 1.3), Vector2(2.05, 1.95), Vector2(1.4, 1.45), Vector2(2.3, 2.1)], C, 36, 8, _col, Vector3.UP)
	r._mesh(r.hips, mh0, M)
	r._collider(r.hips, Vector3(0, 0, -1.8), Vector3(4.0, 3.8, 7.8))
	# --- ön gövde: fıçı göğüs, geniş sırt, kalın kısa boyun öne-aşağı
	var CH = Vector3(0, 7.0, -1.0)
	r.chest = r._pivot(r.hips, CH - HP, "gogus")
	var mc = MB.new()
	var cs = BeastSurf.tube(mc, [Vector3(0, 6.8, -0.1) - CH, Vector3(0, 7.2, -1.9) - CH, Vector3(0, 7.4, -3.4) - CH, Vector3(0, 7.0, -4.8) - CH, Vector3(0, 6.6, -5.8) - CH],
		[Vector2(2.3, 2.1), Vector2(3.1, 2.65), Vector2(2.9, 2.45), Vector2(1.95, 1.75), Vector2(1.5, 1.4)], C, 36, 8, _col, Vector3.UP)
	for sx in [-1.0, 1.0]:   # kürek kemiği / omuz arkası kas çizgisi (anime: ince koyu çizgi)
		cs.ribbon(mc, [Vector2(0.12, PI * 0.5 + 0.45 * sx), Vector2(0.3, PI * 0.5 + 0.7 * sx), Vector2(0.5, PI * 0.5 + 0.5 * sx)], func(u: float) -> float: return 0.05 * sin(clampf(u, 0.05, 0.95) * PI) + 0.01, CD)
	for i in 4:   # ense: geriye yatık kısa kürk dişleri (gövde renginde, siluette)
		var d = cs.at(0.5 + i * 0.11, PI * 0.5, -0.1)
		_tuft(mc, d[0], Vector3(0, 0.55, 1.0), 1.3, 0.55, C, Vector3.UP, 0.4)
	r._mesh(r.chest, mc, M)
	r._collider(r.chest, Vector3(0, 0.3, -1.8), Vector3(6.4, 5.2, 4.6))
	# --- baş
	var HD = Vector3(0, 6.3, -6.9)
	r.head = r._pivot(r.chest, HD - CH, "bas")
	var face = r._pivot(r.head, Vector3(0, 0.1, 0), "yuz")   # yüz düzlemi öne baksın (r.head dönüşünü rig yazar)
	face.rotation.x = deg_to_rad(-14)
	face.scale = Vector3(1, 1, 1.0)   # burun biraz daha uzun
	_head(r, face, M)
	r.head.scale = Vector3.ONE * 1.3
	r._collider(r.head, Vector3(0, 0.2, -0.8), Vector3(3.6, 3.0, 4.6))
	# --- uzuvlar
	for sx in [-1.0, 1.0]:
		# ön: insan gibi kaslı kol, el yerde açık
		var S = Vector3(3.6 * sx, 7.9, -2.7)
		var E = Vector3(6.1 * sx, 4.7, -1.6)
		var W = Vector3(5.7 * sx, 1.1, -4.6)
		var sh = r._pivot(r.chest, S - CH, "kalca")
		var m1 = MB.new()
		m1.add("sphere", Vector3(-0.35 * sx, 0.25, 0.1), Vector3(3.2, 3.1, 3.3), C, Vector3.ZERO, 16)   # omuz kütlesi (deltoid)
		var s1 = BeastSurf.tube(m1, [Vector3(-0.2 * sx, 0.2, 0.1), (E - S) * 0.45 + Vector3(0.3 * sx, 0, -0.15), E - S], [1.4, 1.45, 0.95], C, 22, 7, _col)
		s1.ribbon(m1, [Vector2(0.12, 0.5), Vector2(0.45, 0.25), Vector2(0.8, 0.45)], func(u: float) -> float: return 0.05 * sin(clampf(u, 0.05, 0.95) * PI) + 0.01, CD)
		r._mesh(sh, m1, M)
		var el = r._pivot(sh, E - S, "diz")
		var m2 = MB.new()
		BeastSurf.tube(m2, [Vector3(0, 0.15, 0.1), (W - E) * 0.35 + Vector3(0.1 * sx, 0, 0.15), (W - E) * 0.8, W - E], [0.95, 1.08, 0.74, 0.62], C, 18, 6, _col)
		for k in 3:   # dirsek arkası: geriye sivri kürk
			_tuft(m2, Vector3(0.1 * sx, 0.1 - k * 0.55, 0.6), Vector3(0.15 * sx, 0.35 - k * 0.12, 1), 1.7 - k * 0.3, 0.6, C, Vector3.RIGHT, 0.35)
		_hand(m2, W - E + Vector3(0, -0.55, -0.3), 1.4, 5, 0.95, 1.6)
		r._mesh(el, m2, M)
		r.legs.append({"hip": sh, "kn": el, "side": sx, "front": true})
		# arka: büyük but, diz önde, topuk geride yukarıda, uzun ayak
		var H = Vector3(2.0 * sx, 6.0, 5.4)
		var K = Vector3(3.1 * sx, 3.6, 3.3)
		var HK = Vector3(2.8 * sx, 2.5, 6.3)
		var A = Vector3(2.8 * sx, 0.95, 5.0)
		var hi_ = r._pivot(r.hips, H - HP, "kalca")
		var m3 = MB.new()
		BeastSurf.tube(m3, [Vector3(-0.4 * sx, 0.6, 0.4), (K - H) * 0.45 + Vector3(0.1 * sx, 0, 0.35), K - H], [1.75, 1.6, 0.95], C, 22, 7, _col)
		r._mesh(hi_, m3, M)
		var kn = r._pivot(hi_, K - H, "diz")
		var m4 = MB.new()
		BeastSurf.tube(m4, [Vector3.ZERO, (HK - K) * 0.55 + Vector3(0, 0.1, 0.1), HK - K, A - K], [0.95, 0.72, 0.6, 0.58], C, 18, 6, _col)
		_tuft(m4, (HK - K) + Vector3(0, 0.1, 0.3), Vector3(0, 0.45, 1), 1.3, 0.5, C, Vector3.RIGHT, 0.35)
		_hand(m4, A - K + Vector3(0, -0.45, -0.5), 1.25, 4, 0.6, 1.4)
		r._mesh(kn, m4, M)
		r.legs.append({"hip": hi_, "kn": kn, "side": sx, "front": false})
	_tails(r, Vector3(0, 6.1, 7.0) - HP, M)
	r._weak(r.head, Vector3(0, 1.4, -0.3))
	r._weak(r.chest, Vector3(0, 1.8, 0.4))
	r._weak(r.hips, Vector3(0, 1.4, 1.4))


## Baş (yerel: ileri = -Z). Kafatası geniş ve basık, burun ince-sivri; yanak tutamlarıyla önden uçurtma silueti.
static func _head(r: BeastRig, face: Node3D, M: Material) -> void:
	# kafatası: yuvarlak alın, KALIN kurt burnu (profil ref: burun derin, ucu küt, iri siyah burun)
	var kp = [Vector3(0, 0.25, 1.3), Vector3(0, 0.5, 0.5), Vector3(0, 0.44, -0.4), Vector3(0, 0.3, -1.0), Vector3(0, 0.08, -1.5), Vector3(0, -0.04, -2.3), Vector3(0, -0.14, -2.95), Vector3(0, -0.18, -3.3)]
	var kr = [Vector2(1.05, 1.0), Vector2(1.4, 1.3), Vector2(1.38, 1.24), Vector2(1.2, 1.1), Vector2(0.78, 0.8), Vector2(0.68, 0.7), Vector2(0.56, 0.58), Vector2(0.4, 0.44)]
	var mh = MB.new()
	var ks = BeastSurf.tube(mh, kp, kr, C, 30, 8, _col, Vector3.UP)
	mh.add("sphere", Vector3(0, -0.04, -3.46), Vector3(0.54, 0.38, 0.42), BLK, Vector3.ZERO, 12)   # iri siyah burun
	var top = PI * 0.5
	# burun sırtı kırışıkları (hırlama) + alın ortası çizgisi
	ks.ribbon(mh, [Vector2(0.2, top), Vector2(0.28, top), Vector2(0.38, top)], func(u: float) -> float: return 0.03 * sin(clampf(u, 0.05, 0.95) * PI) + 0.008, CD)
	for k in 3:
		ks.ribbon(mh, _dense([Vector2(0.6 + k * 0.07, top - 0.5), Vector2(0.58 + k * 0.07, top), Vector2(0.6 + k * 0.07, top + 0.5)], 4), func(u: float) -> float: return 0.022 * sin(clampf(u, 0.05, 0.95) * PI) + 0.006, CD)
	for sx in [-1.0, 1.0]:
		# siyah bant: burun yanında ince başlar, gözü sarar, kaşın üstünden KULAĞIN DİBİNE çıkar (kulak içi şeridiyle tek parça)
		ks.ribbon(mh, _dense([Vector2(0.79, top + 0.7 * sx), Vector2(0.64, top + 0.86 * sx), Vector2(0.49, top + 0.92 * sx), Vector2(0.39, top + 0.72 * sx), Vector2(0.3, top + 0.42 * sx)], 6),
			func(u: float) -> float: return lerpf(0.06, 0.44, smoothstep(0.0, 0.5, u)) * (1.0 if u < 0.98 else 0.6), BLK, 0.05)
		# göz: beyaz, küçük kızıl iris + yarık bebek; dış köşe yukarı çekik (çatık)
		var ed = ks.at(0.49, top + 0.92 * sx, 0.09)
		var nrm = ((ed[1] as Vector3) * 0.5 + Vector3(0, 0.1, -1.0)).normalized()
		var eb = Basis.looking_at(nrm, Vector3.UP) * Basis(Vector3.BACK, deg_to_rad(30 * sx))
		var er = eb.get_euler() * 180.0 / PI
		var ep = (ed[0] as Vector3) + nrm * 0.04
		BeastModels._anime_eye(r, face, ep, Vector3(0.74, 0.27, 0.1), Color(0.96, 0.94, 0.9), Color(0.96, 0.94, 0.9), BLK, er, "none")
		BeastModels._anime_eye(r, face, ep + nrm * 0.03, Vector3(0.34, 0.26, 0.1), Color(0.78, 0.05, 0.04), Color(0.95, 0.1, 0.06), BLK, er, "slit")
		# kulak: KAŞTAN çıkar (iki kulak alında V yapar), başın ~2.5 katı, yassı yaprak; ön yüzünde siyah şerit
		var e0 = Vector3(0.52 * sx, 1.46, -0.3)
		var e1 = Vector3(5.6 * sx, 7.4, 3.6)
		var em = e0.lerp(e1, 0.4) + Vector3(0.3 * sx, 0.25, -0.2)
		var ew = Vector3(sx, -0.75, -0.1).normalized()   # yaprağın geniş ekseni
		Loft.tube(mh, [e0 - (e1 - e0).normalized() * 0.7, e0.lerp(em, 0.5), em, em.lerp(e1, 0.6), e1],
			[Vector2(0.34, 0.66), Vector2(0.26, 0.74), Vector2(0.18, 0.62), Vector2(0.1, 0.38), Vector2(0.03, 0.03)], C, 14, 4, true, true, Callable(), ew)
		var en = (e1 - e0).normalized().cross(ew).normalized()   # yaprağın öne bakan yüzünün normali
		if en.z > 0.0:
			en = -en
		var fo = en * 0.25
		Loft.tube(mh, [e0 + fo + Vector3(0, -0.25, -0.05), e0.lerp(em, 0.5) + fo, em + fo * 0.75, em.lerp(e1, 0.6) + fo * 0.5, e1.lerp(em, 0.25) + fo * 0.3],
			[Vector2(0.08, 0.3), Vector2(0.08, 0.36), Vector2(0.07, 0.3), Vector2(0.05, 0.15), Vector2(0.02, 0.02)], BLK, 12, 4, true, true, Callable(), ew)
		# yanak kürkü: çene köşesinde geriye sivri, tırtıklı tutamlar
		var side_a = PI if sx > 0 else 0.0
		for k in 5:
			var cd = ks.at(0.3 - k * 0.035, side_a - (0.0 + k * 0.2) * sx, -0.1)
			_tuft(mh, cd[0], Vector3(0.6 * sx, -0.15 - k * 0.14, 1.0), (1.9 - k * 0.2) * (1.0 if k % 2 == 0 else 0.75), 0.46, C, Vector3(sx, 0.4, 0), 0.4)
		# üst dudak: kalın koyu çizgi, ağız köşesi gözün altına kadar geride; iri seyrek üçgen dişler
		var arc = _arc(Vector3(1.32 * sx, -0.62, -0.1), Vector3(0.9 * sx, -0.86, -1.9), Vector3(0, -0.62, -3.3), 11)
		Loft.tube(mh, arc, arc.map(func(_q): return 0.11), LIP, 8, 2)
		var gum = arc.map(func(q): return Vector3(q.x * 0.78, q.y - 0.1, q.z * 0.88 + 0.12))
		Loft.tube(mh, gum, gum.map(func(_q): return 0.14), Color(0.16, 0.03, 0.04), 8, 1)
		for i in range(1, 11):
			var canine = i == 9
			BeastRig.claw(mh, arc[i] + Vector3(0, -0.05, 0), Vector3(0, -1, 0), 0.58 if canine else 0.36, 0.13 if canine else 0.1, FANG)
	mh.add("sphere", Vector3(0, -0.55, -1.4), Vector3(1.7, 0.3, 3.0), Color(0.3, 0.05, 0.07), Vector3.ZERO, 12)   # ağız tavanı
	r._mesh(face, mh, M)
	# alt çene. Dişler animedeki gibi ZİKZAK: alt sıra üst sırayla AYNI yay üstünde, yarım adım kaydırılmış, uçlar birbirinin
	# boşluğuna girer (kapalıyken iki sıra da görünür); altta kalın koyu dudak
	var JY = -1.08
	var TL = 0.36   # diş boyu
	r.jaw = r._pivot(face, Vector3(0, JY, 0.1), "cene")
	r.jaw.rotation.y = PI
	var mj = MB.new()
	Loft.tube(mj, [Vector3(0, -0.34, -0.1), Vector3(0, -0.44, 1.0), Vector3(0, -0.42, 2.1), Vector3(0, -0.34, 2.95), Vector3(0, -0.24, 3.4)],
		[Vector2(1.34, 0.36), Vector2(1.02, 0.38), Vector2(0.7, 0.32), Vector2(0.46, 0.25), Vector2(0.24, 0.14)], C, 18, 4, true, true, _col)
	mj.add("sphere", Vector3(0, -0.14, 1.4), Vector3(0.85, 0.14, 2.5), Color(0.82, 0.36, 0.4), Vector3.ZERO, 10)   # dil
	for sx in [-1.0, 1.0]:
		# üst yayın çene uzayındaki karşılığı (çene Y'de 180° dönük: x ve z ters), diş boyu kadar aşağıda
		var lo = func(q: Vector3) -> Vector3: return Vector3(-q.x * 0.985, q.y - JY - TL - 0.1, -(q.z - 0.1) * 0.985)
		var arc2 = _arc(lo.call(Vector3(1.32 * sx, -0.62, -0.1)), lo.call(Vector3(0.9 * sx, -0.86, -1.9)), lo.call(Vector3(0, -0.62, -3.3)), 11)
		Loft.tube(mj, arc2, arc2.map(func(_q): return 0.1), LIP, 8, 2)
		var gum2 = arc2.map(func(q): return Vector3(q.x * 0.8, q.y + 0.08, q.z * 0.9 - 0.1))
		Loft.tube(mj, gum2, gum2.map(func(_q): return 0.13), Color(0.16, 0.03, 0.04), 8, 1)
		for i in range(1, 11):
			var canine = i == 8
			BeastRig.claw(mj, (arc2[i] as Vector3).lerp(arc2[i + 1], 0.5) + Vector3(0, 0.05, 0), Vector3(0, 1, 0), TL * (1.3 if canine else 1.0), 0.12 if canine else 0.1, FANG)
		# çene altı kürk: geriye sivri
		_tuft(mj, Vector3(0.8 * sx, -0.36, 0.4), Vector3(0.35 * sx, -0.45, -1.0), 1.5, 0.5, C, Vector3(0, 0.3, 1), 0.3)
	r._mesh(r.jaw, mj, M)
	r.mouth = r._pivot(face, Vector3(0, -0.8, -3.6), "agiz")


## Dokuz kuyruk: kol kadar kalın, uzun, yelpaze; yalnız son üçte birde sivrilir
static func _tails(r: BeastRig, base_pos: Vector3, M: Material) -> void:
	var n = 12
	var rf = func(k: float) -> float:
		return lerpf(1.15, 2.0, sin(minf(1.0, k * 3.0) * PI * 0.5)) * (1.0 - pow(maxf(0.0, (k - 0.55) / 0.45), 1.6) * 0.97)
	var base = r._pivot(r.hips, base_pos, "kuyruk_koku")
	r.tail_curl = 0.0
	for ti in 9:
		var yaw = lerpf(-78.0, 78.0, ti / 8.0)
		var pitch = -68.0 + absf(ti - 4.0) * 14.0 + 8.0 * (ti % 2)
		var length = 31.0 - absf(ti - 4.0) * 0.6 - 2.0 * (ti % 2)
		var seg_len = length / n
		var troot = r._pivot(base, Vector3((ti - 4.0) * 0.26, 0, 0), "tail")
		troot.rotation = Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0)
		var segs = []
		var parent = troot
		for i in n:
			var r0: float = rf.call(maxf(0.0, (i - 0.18) / n))
			var r1: float = rf.call(minf(1.0, (i + 1.18) / n))
			var piv = r._pivot(parent, Vector3(0, 0, seg_len) if i > 0 else Vector3.ZERO, "s%d" % i)
			var mb = MB.new()
			var c0 = C.lerp(CL, float(i) / n * 0.35)
			var c1 = C.lerp(CL, float(i + 1) / n * 0.35)
			Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.18), Vector3(0, 0, seg_len * 0.5), Vector3(0, 0, seg_len * 1.18)], [Vector2(r0, r0 * 0.86), Vector2((r0 + r1) * 0.5, (r0 + r1) * 0.43), Vector2(r1, r1 * 0.86)], [c0, c0.lerp(c1, 0.5), c1], 16, 3, i == 0, i == n - 1)
			r._mesh(piv, mb, M)
			segs.append(piv)
			parent = piv
		r.tails.append(segs)
		r.tail_cfg.append({"yaw": deg_to_rad(yaw), "pitch": deg_to_rad(pitch), "amp": 0.12, "phase": randf() * TAU, "style": "fur", "root": troot, "s_amp": 0.42, "s_yaw": (ti - 4.0) * 0.04})
