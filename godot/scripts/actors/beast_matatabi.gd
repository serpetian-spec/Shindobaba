class_name BeastMatatabi
extends RefCounted
## Matatabi — İki Kuyruk. Referans: _tmp/ref/matatabi_storm (Storm 4 kareleri A/B) + _tmp/ref/matatabi (anime)
## Okunan yapı:
##  - mavi alevden YALIN büyük kedi, dört ayak üstünde; derin göğüs, ince bel, uzun bacaklar (bacak ≈ gövde derinliğinin 1.3 katı)
##  - kalın boyun öne-yukarı, baş omuz hizasının biraz üstünde; kama biçimli baş, geriye yatık uzun sivri kulaklar, yanakta geriye alev tutamları
##  - gözler çekik: biri sarı biri yeşil; beyaz köpek dişleri
##  - tüm gövdede KALIN siyah sarmal kıvrımlar; sırt çizgisi, bacak arkası ve kuyruk kenarlarında alev dilleri
##  - iki kuyruk: gövdeden uzun, dalgalı şerit gibi, uçta alev çatalı

const C := Color(0.16, 0.5, 0.98)
const HI := Color(0.45, 0.76, 1.0)
const DK := Color(0.02, 0.02, 0.06)
const FANG := Color(0.95, 0.97, 1.0)
const LIP := Color(0.92, 0.5, 0.58)


## Anime gövde boyası: açık/koyu mavi alev lekeleri; karın/boğaz altı siyah, alev dişli kenarla
static func _body_col(t: float, _a: float, d: Vector3) -> Color:
	if d.y < -0.52 + 0.2 * sin(t * 37.0) + 0.1 * sin(t * 83.0 + d.x * 5.0):
		return DK
	return C.lerp(HI, 0.4 * (0.5 + 0.5 * sin(t * 21.0 + d.x * 4.0) * sin(d.y * 5.0 + t * 9.0)))


static func _leg_col(sx: float) -> Callable:
	return func(t: float, _a: float, d: Vector3) -> Color:
		if d.x * sx < -0.5 + 0.22 * sin(t * 29.0):
			return DK   # bacak içi siyah
		return C.lerp(HI, 0.4 * (0.5 + 0.5 * sin(t * 17.0 + d.z * 4.0)))


static func _arc(p0: Vector3, p1: Vector3, p2: Vector3, n: int) -> Array:
	var out = []
	for i in n + 1:
		var u = float(i) / n
		out.append(p0.lerp(p1, u).lerp(p1.lerp(p2, u), u))
	return out


## Yassı alev dili: tabandan dir yönünde S kıvrımlı; nrm = kıvrımın yattığı düzlemdeki dış yön
static func _tongue(mb: MB, base: Vector3, dir: Vector3, nrm: Vector3, ln: float, w: float, col: Color) -> void:
	var d = dir.normalized()
	var up = nrm.cross(d)
	if up.length() < 0.05:
		up = Vector3.RIGHT
	Loft.tube(mb, [base - d * w * 0.4, base + d * ln * 0.4 + nrm * ln * 0.16, base + d * ln * 0.75 + nrm * ln * 0.05, base + d * ln + nrm * ln * 0.22],
		[Vector2(w, w * 0.22), Vector2(w * 0.8, w * 0.18), Vector2(w * 0.42, w * 0.12), Vector2(0.02, 0.02)], col, 8, 3, true, true, Callable(), up.normalized())


## Tüpün bir çizgisi (a) boyunca geriye savrulan alev dilleri
static func _fringe(mb: MB, sf: BeastSurf, t0: float, t1: float, a: float, n: int, ln: float, w: float, back: Vector3, seed_v: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_v
	for i in n:
		var d = sf.at(lerpf(t0, t1, (i + 0.5) / n), a + rng.randf_range(-0.12, 0.12), -0.1)
		var nr: Vector3 = d[1]
		_tongue(mb, d[0], (back + nr * rng.randf_range(0.15, 0.35)).normalized(), nr, ln * rng.randf_range(0.7, 1.3), w * rng.randf_range(0.8, 1.2), HI if i % 3 == 1 else C)


static func _paw(mb: MB, at: Vector3, size: float) -> void:
	mb.add("sphere", at + Vector3(0, 0.05, -0.35) * size, Vector3(1.15, 0.7, 1.5) * size, C, Vector3.ZERO, 12)
	for f in 4:
		var ph = lerpf(-0.5, 0.5, f / 3.0)
		mb.add("sphere", at + Vector3(sin(ph) * 0.42, -0.02, -0.95 - cos(ph) * 0.1) * size, Vector3(0.36, 0.42, 0.55) * size, C, Vector3.ZERO, 8)
		BeastRig.claw(mb, at + Vector3(sin(ph) * 0.45, 0.0, -1.2) * size, Vector3(sin(ph) * 0.2, -0.45, -1.0), 0.5 * size, 0.09 * size, HI)


static func build(r: BeastRig, root: Node3D) -> void:
	r.quadruped = true
	r.upright = false
	var HP = Vector3(0, 5.6, 2.6)
	r.hips = r._pivot(root, HP, "kalca_kok")
	# --- arka gövde: sağrı -> but -> ince bel
	var hp_ = [Vector3(0, 5.4, 4.3) - HP, Vector3(0, 5.7, 3.0) - HP, Vector3(0, 5.55, 0.9) - HP, Vector3(0, 5.5, -0.7) - HP]
	var hr = [Vector2(1.4, 1.5), Vector2(1.95, 2.05), Vector2(1.6, 1.7), Vector2(1.85, 2.05)]
	var mh0 = MB.new()
	var hs0 = BeastSurf.tube(mh0, hp_, hr, C, 36, 8, _body_col, Vector3.UP)
	hs0.swirl_marks(mh0, 7, 8, 51, DK, 0.17, 0.5, 0.04, 0.96, -0.5, PI + 0.5)
	hs0.flame_marks(mh0, 5, 8, 151, DK, 0.07, 0.9)
	_fringe(mh0, hs0, 0.05, 0.95, PI * 0.5, 6, 1.3, 0.4, Vector3(0, 0.25, 1), 61)
	_fringe(mh0, hs0, 0.3, 0.9, -PI * 0.5, 4, 1.0, 0.3, Vector3(0, -0.3, 1), 62)
	r._mesh(r.hips, mh0)
	r._collider(r.hips, Vector3(0, 0, -0.6), Vector3(3.4, 3.6, 5.6))
	# --- ön gövde: derin göğüs + kalın boyun (öne-yukarı)
	var CH = Vector3(0, 5.6, -1.0)
	r.chest = r._pivot(r.hips, CH - HP, "gogus")
	var cp = [Vector3(0, 5.5, -0.2) - CH, Vector3(0, 5.45, -1.8) - CH, Vector3(0, 5.7, -3.3) - CH, Vector3(0, 6.1, -4.5) - CH, Vector3(0, 6.35, -5.3) - CH]
	var cr = [Vector2(1.85, 2.05), Vector2(2.2, 2.55), Vector2(1.95, 2.2), Vector2(1.6, 1.7), Vector2(1.4, 1.4)]
	var mc = MB.new()
	var cs = BeastSurf.tube(mc, cp, cr, C, 36, 8, _body_col, Vector3.UP)
	cs.swirl_marks(mc, 8, 8, 52, DK, 0.17, 0.5, 0.04, 0.96, -0.5, PI + 0.5)
	cs.flame_marks(mc, 6, 8, 152, DK, 0.07, 0.9)
	_fringe(mc, cs, 0.05, 0.95, PI * 0.5, 7, 1.4, 0.4, Vector3(0, 0.3, 1), 63)
	_fringe(mc, cs, 0.35, 0.9, -PI * 0.5, 5, 1.1, 0.32, Vector3(0, -0.5, 0.8), 64)   # göğüs altı
	r._mesh(r.chest, mc)
	r._collider(r.chest, Vector3(0, 0.2, -1.6), Vector3(3.8, 4.2, 4.2))
	# --- baş (anime yakın çekim: kama biçimli kurt/kaplan başı — geniş kafatası öne doğru daralıp buruna iner;
	#     burun köprüsünde V gibi birleşen kalın siyah göz yamaları içinde YUVARLAK düz renk gözler (sağ sarı, sol yeşil);
	#     alında yukarı çıkan siyah alev darbeleri, yanakta yatay bıyık çizgileri; gri-mor geniş burun;
	#     ağız kocaman: köşeler yukarı-dışa çekik, aşağı doğru daralır, çepeçevre pembe dudak + sivri dişler; çene altı siyah)
	var HD = Vector3(0, 6.45, -6.0)
	r.head = r._pivot(r.chest, HD - CH, "bas")
	# yüz düzlemi öne baksın: baş geometrisi burun aşağı eğik ayrı bir düğümde (r.head dönüşünü rig her kare yazar)
	var face = r._pivot(r.head, Vector3(0, 0.25, 0), "yuz")
	face.rotation.x = deg_to_rad(-17)
	var kp = [Vector3(0, 0.3, 1.1), Vector3(0, 0.5, 0.2), Vector3(0, 0.42, -0.6), Vector3(0, 0.12, -1.3), Vector3(0, -0.08, -1.9), Vector3(0, -0.18, -2.25)]
	var kr = [Vector2(1.6, 1.3), Vector2(2.0, 1.5), Vector2(1.8, 1.25), Vector2(1.25, 0.82), Vector2(0.98, 0.6), Vector2(0.74, 0.44)]
	var mh = MB.new()
	var ks = BeastSurf.tube(mh, kp, kr, C, 28, 8, func(t: float, _a: float, d: Vector3) -> Color:
		return C.lerp(HI, 0.4 * (0.5 + 0.5 * sin(t * 21.0 + d.x * 4.0) * sin(d.y * 5.0 + t * 9.0))), Vector3.UP)
	var top = PI * 0.5
	# alın: yukarı-geriye çıkan damla biçimli siyah alev darbeleri (ortada uzun, yanlarda kısa)
	for k in 7:
		var fa = top + (k - 3.0) * 0.26
		var fl = 0.3 - absf(k - 3.0) * 0.035
		var f1 = 0.5 - absf(k - 3.0) * 0.02
		ks.ribbon(mh, [Vector2(f1, fa), Vector2(f1 - fl * 0.5, fa + 0.04 * (k - 3.0)), Vector2(f1 - fl, fa + 0.1 * (k - 3.0))], func(u: float) -> float: return 0.15 * pow(sin(clampf(u, 0.03, 0.97) * PI), 0.8) * (1.3 - u * 0.6) + 0.01, DK)
	for k in 4:   # ikinci sıra, daha geride
		var fa2 = top + (k - 1.5) * 0.42
		ks.ribbon(mh, [Vector2(0.2, fa2), Vector2(0.12, fa2 + 0.05 * (k - 1.5)), Vector2(0.04, fa2 + 0.1 * (k - 1.5))], func(u: float) -> float: return 0.14 * sin(clampf(u, 0.03, 0.97) * PI) + 0.01, DK)
	# burun köprüsü kırışıkları
	for k in 2:
		ks.ribbon(mh, [Vector2(0.66 + k * 0.05, top - 0.22), Vector2(0.68 + k * 0.05, top), Vector2(0.66 + k * 0.05, top + 0.22)], func(u: float) -> float: return 0.035 * sin(clampf(u, 0.05, 0.95) * PI) + 0.008, DK)
	# gri-mor geniş burun + dudağa inen çizgi
	mh.add("sphere", Vector3(0, -0.02, -2.58), Vector3(0.52, 0.28, 0.3), Color(0.42, 0.36, 0.5), Vector3.ZERO, 12)
	Loft.tube(mh, [Vector3(0, -0.15, -2.72), Vector3(0, -0.4, -2.68), Vector3(0, -0.6, -2.58)], [0.022, 0.022, 0.02], DK, 4, 2)
	for sx in [-1.0, 1.0]:
		# siyah göz yaması: dış üst köşeden gözün üstünden geçip burun köprüsünde ortada birleşir (çatık)
		ks.ribbon(mh, [Vector2(0.34, top + 1.25 * sx), Vector2(0.46, top + 0.95 * sx), Vector2(0.56, top + 0.6 * sx), Vector2(0.65, top + 0.3 * sx), Vector2(0.71, top + 0.02 * sx)], func(u: float) -> float: return 0.4 * pow(sin(clampf(u * 0.82 + 0.06, 0.0, 1.0) * PI), 0.8) + 0.03, DK)
		# göz: yuvarlak, düz renk (bebek yok), öne bakar
		var ed = ks.at(0.55, top + 0.62 * sx, 0.04)
		var nrm = ((ed[1] as Vector3) + Vector3(0, 0, -1.4)).normalized()
		var eb = Basis.looking_at(nrm, Vector3.UP)
		var iris = Color(1.0, 0.86, 0.3) if sx > 0 else Color(0.1, 0.72, 0.6)
		BeastModels._anime_eye(r, face, (ed[0] as Vector3) + nrm * 0.13, Vector3(0.3, 0.3, 0.07), iris, iris, iris, eb.get_euler() * 180.0 / PI, "none")
		# yanak bıyık çizgileri: buruna yakın yerden dışa-geriye yatay darbeler
		for k in 4:
			var wa = top + (1.28 + k * 0.2) * sx
			ks.ribbon(mh, [Vector2(0.7 - k * 0.02, wa - 0.1 * sx), Vector2(0.58 - k * 0.02, wa + 0.02 * sx), Vector2(0.44 - k * 0.02, wa + 0.14 * sx)], func(u: float) -> float: return 0.14 * sin(clampf(u, 0.03, 0.97) * PI) * (1.3 - u * 0.6) + 0.008, DK)
		# uzun sivri kulak: dışa-geriye yatık, içi siyah
		var e0 = Vector3(1.25 * sx, 1.2, 0.5)
		var e1 = Vector3(3.1 * sx, 2.7, 2.4)
		Loft.tube(mh, [e0, e0.lerp(e1, 0.45) + Vector3(0.1 * sx, 0.25, 0), e1], [Vector2(0.78, 0.3), Vector2(0.52, 0.2), Vector2(0.02, 0.02)], C, 12, 4, true, true, Callable(), Vector3.BACK)
		var f0 = e0.lerp(e1, 0.12) + Vector3(0, -0.02, -0.27)
		Loft.tube(mh, [f0, f0.lerp(e1, 0.45) + Vector3(0.08 * sx, 0.16, -0.06), e1.lerp(e0, 0.12) + Vector3(0, 0, -0.1)], [Vector2(0.5, 0.08), Vector2(0.34, 0.07), Vector2(0.02, 0.02)], DK, 10, 4, true, true, Callable(), Vector3.BACK)
		# yanakta dışa-geriye savrulan büyük alev tutamları (yüzü yanlara doğru genişletir)
		for k in 6:
			var cd = ks.at(0.3 + k * 0.035, (PI if sx > 0 else 0.0) + (0.6 - k * 0.3) * sx, -0.1)
			_tongue(mh, cd[0], Vector3(1.0 * sx, 0.2 - k * 0.16, 0.8), Vector3(sx, 0, 0), 2.1 - k * 0.16, 0.5, HI if k % 2 == 1 else C)
		# üst dudak (pembe): köşe yukarıda-geride, öne doğru aşağı inip burun altında birleşir + diş sırası
		var arc = _arc(Vector3(1.5 * sx, -0.3, -0.35), Vector3(1.2 * sx, -0.72, -1.7), Vector3(0, -0.62, -2.55), 10)
		Loft.tube(mh, arc, arc.map(func(_q): return 0.11), LIP, 6, 1)
		for i in range(1, 10):
			var canine = i == 8
			BeastRig.claw(mh, arc[i] + Vector3(-0.06 * sx, -0.04, 0.05), Vector3(0, -1, 0.05), 0.8 if canine else 0.34 + 0.08 * (i % 2), 0.14 if canine else 0.085, FANG)
	# tepe alevleri: kafanın üstünden geriye-yukarı yalayan diller (alev silueti)
	for k in 5:
		var td = ks.at(0.08 + k * 0.08, top + (k % 2 - 0.5) * 0.5, -0.1)
		_tongue(mh, td[0], Vector3((k % 2 - 0.5) * 0.4, 0.08, 1.0), Vector3(0, 1, 0), 1.1 - k * 0.1, 0.4, HI if k % 2 == 0 else C)
	mh.add("sphere", Vector3(0, -0.55, -1.1), Vector3(2.3, 0.5, 2.6), Color(0.62, 0.2, 0.3), Vector3.ZERO, 12)   # ağız tavanı
	mh.add("sphere", Vector3(0, -0.9, -0.1), Vector3(2.5, 1.7, 1.2), Color(0.4, 0.1, 0.18), Vector3.ZERO, 12)   # gırtlak (ağzın dibi koyu)
	r._mesh(face, mh)
	r.head.scale = Vector3.ONE * 0.78
	r._collider(r.head, Vector3(0, 0, -0.6), Vector3(4.2, 3.2, 4.0))
	# alt çene: arkadan menteşeli (yerel +Z = ileri; pozitif rotation.x indirir); kükrer gibi AÇIK modellenir, altı siyah
	r.jaw = r._pivot(face, Vector3(0, -0.45, -0.1), "cene")
	r.jaw.rotation.y = PI
	var mj = MB.new()
	Loft.tube(mj, [Vector3(0, -0.2, 0.0), Vector3(0, -0.65, 1.0), Vector3(0, -1.0, 1.85), Vector3(0, -1.12, 2.25)], [Vector2(1.5, 0.4), Vector2(1.2, 0.38), Vector2(0.82, 0.32), Vector2(0.5, 0.24)], DK, 16, 4)
	mj.add("sphere", Vector3(0, -0.56, 1.05), Vector3(1.9, 0.3, 2.3), Color(0.86, 0.42, 0.5), Vector3(22, 0, 0), 12)   # dil / ağız tabanı
	for sx in [-1.0, 1.0]:
		var arc2 = _arc(Vector3(1.48 * sx, 0.12, 0.25), Vector3(1.15 * sx, -0.55, 1.5), Vector3(0, -0.86, 2.3), 9)
		Loft.tube(mj, arc2, arc2.map(func(_q): return 0.11), LIP, 6, 1)
		for i in range(1, 9):
			var canine = i == 7
			BeastRig.claw(mj, arc2[i] + Vector3(-0.06 * sx, 0.03, -0.05), Vector3(0, 1, -0.25), 0.65 if canine else 0.3 + 0.07 * (i % 2), 0.12 if canine else 0.08, FANG)
		for k in 2:   # çene altı alev tutamları
			_tongue(mj, Vector3((0.9 - k * 0.5) * sx, -0.9 - k * 0.35, 0.8 + k * 0.6), Vector3(0.4 * sx, -0.8, -0.5), Vector3(sx, 0, 0), 1.2, 0.34, C)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(face, Vector3(0, -1.1, -2.6), "agiz")
	# --- bacaklar
	for sx in [-1.0, 1.0]:
		# ön: omuz kalın, dirsek hafif geride, uzun düz önkol, büyük pençe
		var S = Vector3(1.75 * sx, 5.5, -2.6)
		var E = Vector3(1.85 * sx, 3.2, -2.1)
		var W = Vector3(1.85 * sx, 0.8, -2.5)
		var sh = r._pivot(r.chest, S - CH, "kalca")
		var m1 = MB.new()
		var s1 = BeastSurf.tube(m1, [Vector3(-0.2 * sx, 0.7, 0.2), (E - S) * 0.5 + Vector3(0, 0, 0.15), E - S], [1.4, 1.15, 0.82], C, 20, 6, _leg_col(sx))
		s1.swirl_marks(m1, 3, 5, 71 + int(sx), DK, 0.13, 0.36)
		r._mesh(sh, m1)
		var el = r._pivot(sh, E - S, "diz")
		var m2 = MB.new()
		var s2 = BeastSurf.tube(m2, [Vector3.ZERO, (W - E) * 0.5, W - E], [0.82, 0.68, 0.62], C, 16, 6, _leg_col(sx))
		s2.swirl_marks(m2, 3, 4, 73 + int(sx), DK, 0.1, 0.26)
		for k in 3:   # dirsekten geriye alev dilleri
			_tongue(m2, Vector3(0, -0.2 - k * 0.7, 0.4), Vector3(0, 0.25, 1), Vector3(0, 0, 1), 1.1 - k * 0.2, 0.3, HI if k == 1 else C)
		_paw(m2, W - E + Vector3(0, -0.4, 0), 1.3)
		r._mesh(el, m2)
		r.legs.append({"hip": sh, "kn": el, "side": sx, "front": true})
		# arka: büyük but, diz önde, topuk geride yukarıda, pençe
		var H = Vector3(1.6 * sx, 5.4, 3.2)
		var K = Vector3(1.9 * sx, 3.3, 2.1)
		var HK = Vector3(1.85 * sx, 2.0, 3.7)
		var A = Vector3(1.85 * sx, 0.8, 3.2)
		var hi_ = r._pivot(r.hips, H - HP, "kalca")
		var m3 = MB.new()
		var s3 = BeastSurf.tube(m3, [Vector3(-0.2 * sx, 0.5, 0.2), (K - H) * 0.5 + Vector3(0, 0, -0.1), K - H], [1.65, 1.35, 0.85], C, 20, 6, _leg_col(sx))
		s3.swirl_marks(m3, 3, 5, 75 + int(sx), DK, 0.14, 0.4)
		r._mesh(hi_, m3)
		var kn = r._pivot(hi_, K - H, "diz")
		var m4 = MB.new()
		var s4 = BeastSurf.tube(m4, [Vector3.ZERO, HK - K, A - K], [0.85, 0.65, 0.6], C, 16, 6, _leg_col(sx))
		s4.swirl_marks(m4, 3, 4, 77 + int(sx), DK, 0.1, 0.26)
		for k in 3:
			_tongue(m4, (HK - K) * (0.3 + k * 0.3) + Vector3(0, 0, 0.35), Vector3(0, 0.3, 1), Vector3(0, 0, 1), 1.2 - k * 0.2, 0.3, HI if k == 1 else C)
		_paw(m4, A - K + Vector3(0, -0.4, 0), 1.3)
		r._mesh(kn, m4)
		r.legs.append({"hip": hi_, "kn": kn, "side": sx, "front": false})
	_tails(r, Vector3(0, 5.9, 4.5) - HP)
	BeastModels._particles(r.hips, Vector3(2.0, 1.8, 3.4), [Color(0.4, 0.65, 1.0, 0.95), Color(0.02, 0.02, 0.15, 0.0)], 160, 2.0, Vector3(0, 7, 0), 1.0, true)
	BeastModels._particles(r.chest, Vector3(2.0, 2.2, 2.0), [Color(0.4, 0.65, 1.0, 0.95), Color(0.02, 0.02, 0.15, 0.0)], 90, 1.8, Vector3(0, 7, 0), 0.9, true)
	r._weak(r.head, Vector3(0, 1.4, 0.2))
	r._weak(r.hips, Vector3(0, 2.0, 0.0))


## İki uzun alev kuyruk: dalgalı şerit, kenarlarında alev dilleri, üstünde siyah sarmallar, uçta alev çatalı
static func _tails(r: BeastRig, base_pos: Vector3) -> void:
	var n = 10
	var length = 15.0
	var seg_len = length / n
	var rf = func(k: float) -> float:
		return lerpf(0.7, 1.3, sin(minf(1.0, k * 2.2) * PI * 0.5)) * (1.0 - pow(k, 2.2) * 0.8)
	var base = r._pivot(r.hips, base_pos, "kuyruk_koku")
	r.tail_curl = -0.015
	for ti in 2:
		var yaw = -13.0 if ti == 0 else 13.0
		var pitch = -10.0 - ti * 12.0
		var root = r._pivot(base, Vector3.ZERO, "tail")
		root.rotation = Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0)
		var segs = []
		var parent = root
		for i in n:
			var k0 = float(i) / n
			var k1 = float(i + 1) / n
			var r0: float = rf.call(k0)
			var r1: float = rf.call(k1)
			var piv = r._pivot(parent, Vector3(0, 0, seg_len) if i > 0 else Vector3.ZERO, "s%d" % i)
			var mb = MB.new()
			var sf = BeastSurf.tube(mb, [Vector3(0, 0, -seg_len * 0.2), Vector3(0, 0, seg_len * 0.5), Vector3(0, 0, seg_len * 1.15)], [Vector2(r0 * 0.65, r0), Vector2((r0 + r1) * 0.325, (r0 + r1) * 0.5), Vector2(r1 * 0.65, r1)], C.lerp(HI, k0 * 0.35), 14, 3, Callable(), Vector3.UP)
			sf.swirl_marks(mb, 1, 4, 90 + ti * 20 + i, DK, 0.12, 0.34, 0.15, 0.85)
			for f in 3:   # kenarlardan geriye savrulan alev dilleri
				if (f == 1 and i % 2 == 0) or (f == 2 and i % 3 == 1):
					continue
				var nr = Vector3(0, 1.0 if f < 2 else -1.0, 0)   # üst kenarda iki, altta bir alev dili
				_tongue(mb, nr * r0 * 0.75 + Vector3(0, 0, seg_len * (0.15 + f * 0.35)), (Vector3(0, 0, 1) + nr * 0.4).normalized(), nr, r0 * (1.2 + 1.3 * fposmod(sin(i * 12.9898 + f * 78.233 + ti * 3.1) * 43758.5453, 1.0)), r0 * 0.55, HI if f == 1 else C)
			if i == n - 1:   # uç alev çatalı
				for f in 3:
					var nr2 = Vector3(cos(f * 2.1 + ti), sin(f * 2.1 + ti), 0)
					_tongue(mb, Vector3(0, 0, seg_len * 0.9), (Vector3(0, 0, 1) + nr2 * 0.4).normalized(), nr2, 2.4, 0.6, HI if f == 0 else C)
			r._mesh(piv, mb)
			segs.append(piv)
			parent = piv
		r.tails.append(segs)
		r.tail_cfg.append({"yaw": deg_to_rad(yaw), "pitch": deg_to_rad(pitch), "amp": 0.2, "phase": randf() * TAU, "style": "flame", "root": root})
