class_name BeastShukaku
extends RefCounted
## Shukaku — Bir Kuyruk. Referans: _tmp/ref/shukaku (Shippūden: Shukaku.png, Shukaku_Vs_Urashiki, defending_Gaara, Struggling, Gaara_lost_control)
## Okunan özellikler:
##  - kambur dev: omuz/sırt kütlesi kalçadan geniş, baş omuzların önünde ve ALÇAKTA, gövdeye gömülü (boyun yok), baş genişliği gövdenin ~1/3'ü
##  - çok kalın kollar (üst kol ≈ baş genişliği), dirsek dışarıda, eller önde yere basılı; 4 kalın parmak, pençe = parmağın sivrilen ucu (aynı kum rengi)
##  - kısa kalın arka bacaklar yanlarda (but), 3 parmaklı ayak
##  - yüz: yuvarlak tanuki başı, köşelerde dışa bakan sivri üçgen kulak (içi lacivert), göz çevresinde sivri uçlu siyah maske,
##    sarı göz + dört köşeli yıldız bebek, geniş küt burun çıkıntısı + küçük siyah burun, ağız = kum renginde zikzak diş sırası (beyaz diş YOK)
##  - desen: tüm gövdede lacivert, alev gibi kıvrılan iki ucu sivri fırça darbeleri, bazısı kancalı / damla gözlü
##  - kuyruk: gövde kadar uzun, çok kalın, üst üste binen sivri yaprak pullar (her pulda lacivert iz), yukarı kalkık

const C := Color(0.8, 0.72, 0.58)
const MK := Color(0.12, 0.15, 0.4)
const DARK := Color(0.03, 0.03, 0.05)
const TOOTH := Color(0.85, 0.77, 0.62)


static func _flat(mb: MB, pts: Array, rad: Array, col: Color, out_n: Vector3) -> void:
	Loft.tube(mb, pts, rad, col, 8, 2, true, true, Callable(), out_n)


## Yassı üçgen diş (zikzak): taban genişliği w, yüzü out_n'e bakar
static func _fang(mb: MB, base: Vector3, dir: Vector3, ln: float, w: float, out_n: Vector3) -> void:
	_flat(mb, [base - dir * ln * 0.25, base + dir * ln * 0.4, base + dir * ln], [Vector2(w, 0.09), Vector2(w * 0.62, 0.07), Vector2(0.015, 0.015)], TOOTH, out_n)


## Pençeli parmak: kalın kök, hafif kemer, sivri uç
static func _digit(mb: MB, base: Vector3, dir: Vector3, ln: float, rad: float, curl: Vector3) -> void:
	var d = dir.normalized()
	var arch = -curl.normalized() * rad * 0.45
	Loft.tube(mb, [base - d * rad * 0.6, base + d * ln * 0.38 + arch, base + d * ln * 0.78 + curl * 0.35, base + d * ln + curl],
		[rad, rad * 0.95, rad * 0.6, 0.03], C, 10, 3)


static func build(r: BeastRig, root: Node3D) -> void:
	# YAPI (Storm 4 kareleri: _tmp/ref/shukaku_storm A/B): gövde TEK PARÇA dev kubbe (en > boy), göbek yere iner;
	# baş ayrı top değil, kubbenin üst-ön yüzüne gömülü küçük yüz (baş tepesi = gövde tepesi);
	# kollar kubbenin YANINDAN eğimli omuzla çıkar, parantez gibi dışa-aşağı sarkar, pençeler iki yanda yere yakın;
	# ayakların yalnız 3 parmaklı ucu göbeğin altından görünür; kuyruk arkadan dik yukarı, ucu öne kıvrık
	var HP = Vector3(0, 4.0, 0.2)
	r.hips = r._pivot(root, HP, "kalca_kok")
	var tp = [Vector3(0, 3.0, -0.1) - HP, Vector3(0, 4.2, -0.2) - HP, Vector3(0, 5.8, 0.1) - HP, Vector3(0, 7.2, 0.1) - HP, Vector3(0, 8.3, 0.0) - HP]
	var tr = [Vector2(4.3, 4.0), Vector2(4.9, 4.6), Vector2(4.6, 4.1), Vector2(3.9, 3.4), Vector2(2.8, 2.5)]
	var mt = MB.new()
	var ts = BeastSurf.tube(mt, tp, tr, C, 48, 8)
	r._mesh(r.hips, mt)
	var mm = MB.new()
	ts.flame_marks(mm, 11, 18, 11, MK, 0.1, 1.25, 0.0, 1.0, -PI, PI, PI * 0.5)   # seyrek, çoğu yatay kısa dalga
	r._mesh(r.hips, mm)
	var mb_ = MB.new()
	var bs = BeastSurf.tube(mb_, [Vector3(0, 2.5, -1.7) - HP, Vector3(0, 3.6, -1.9) - HP, Vector3(0, 4.9, -1.6) - HP], [Vector2(3.2, 3.0), Vector2(3.9, 3.6), Vector2(3.3, 3.0)], C, 44, 8)
	bs.flame_marks(mb_, 5, 7, 17, MK, 0.085, 1.1, 0.0, 1.0, -PI * 0.5 - 1.5, -PI * 0.5 + 1.5, PI * 0.5)
	r._mesh(r.hips, mb_)
	r._collider(r.hips, Vector3(0, 1.0, -0.5), Vector3(9.4, 9.6, 9.4))
	var CH = Vector3(0, 6.5, 0.0)
	r.chest = r._pivot(r.hips, CH - HP, "gogus")
	# --- yüz: kubbenin üst-önüne yarı gömülü
	var HD = Vector3(0, 7.75, -2.55)
	r.head = r._pivot(r.chest, HD - CH, "bas")
	# Storm yüzü: geniş yassı kubbe, kısa kama burun, burnun hemen altında yanaktan yanağa AÇIK dev ağız (ayrı çene kovası yok)
	var hp_ = [Vector3(0, -0.75, 0.05), Vector3(0, -0.25, 0), Vector3(0, 0.25, 0), Vector3(0, 0.75, 0.1), Vector3(0, 1.15, 0.2)]
	var hr = [Vector2(1.5, 1.05), Vector2(2.0, 1.42), Vector2(2.05, 1.48), Vector2(1.78, 1.32), Vector2(1.15, 0.9)]
	var mh = MB.new()
	var hs = BeastSurf.tube(mh, hp_, hr, C, 44, 8, func(t: float, _a: float, _d: Vector3) -> Color: return DARK if t < 0.001 else C)
	# yüz koordinatı: u = önden yatay açı (+ sağ), y = yükseklik
	var face = func(u: float, y: float) -> Vector2:
		return Vector2((y + 0.75) / 2.0 if y <= 0.75 else 0.75 + (y - 0.75) / 1.6, -PI * 0.5 - u)
	# kısa kama burun: gözlerin arasından aşağı-öne, ucunda küçük koyu burun
	Loft.tube(mh, [Vector3(0, 0.2, -0.9), Vector3(0, -0.1, -1.5), Vector3(0, -0.4, -1.82)], [Vector2(0.62, 0.4), Vector2(0.66, 0.42), Vector2(0.5, 0.34)], C, 18, 4)
	mh.add("sphere", Vector3(0, -0.47, -2.06), Vector3(0.44, 0.26, 0.3), DARK, Vector3.ZERO, 12)
	# ağız içi
	mh.add("sphere", Vector3(0, -1.12, -0.3), Vector3(3.7, 1.15, 2.9), DARK, Vector3.ZERO, 16)
	# üst dudak yayı (köşeler yukarı = sırıtış) + uzun sivri üst dişler
	var lip_y = func(ph: float) -> float: return -0.62 + 0.38 * pow(absf(ph) / 1.5, 2.0)
	var lip: Array = []; var lr: Array = []
	for i in 15:
		var ph = lerpf(-1.55, 1.55, i / 14.0)
		lip.append(Vector3(sin(ph) * 1.95, lip_y.call(ph), -0.3 - cos(ph) * 1.55))
		lr.append(Vector2(0.13, 0.17))
	Loft.tube(mh, lip, lr, C, 8, 3)
	for i in 21:
		var ph = lerpf(-1.45, 1.45, i / 20.0)
		var on = Vector3(sin(ph), 0, -cos(ph))
		_fang(mh, Vector3(sin(ph) * 1.97, lip_y.call(ph) - 0.08, -0.3 - cos(ph) * 1.57), Vector3(sin(ph) * 0.08, -1, -cos(ph) * 0.08), 0.52 if i % 2 == 0 else 0.36, 0.15, on)
	# kulaklar: birbirinden uzak, köşelerde, dışa-yukarı küçük sivri üçgen; ön yüzü lacivert
	for sx in [-1.0, 1.0]:
		var e0 = Vector3(1.4 * sx, 0.95, 0.2)
		var e1 = Vector3(2.2 * sx, 1.9, 0.35)
		Loft.tube(mh, [e0, e0.lerp(e1, 0.45), e1], [Vector2(0.56, 0.24), Vector2(0.4, 0.18), Vector2(0.03, 0.03)], C, 12, 3, true, true, Callable(), Vector3.BACK)
		var f0 = e0.lerp(e1, 0.12) + Vector3(0, 0, -0.2)
		Loft.tube(mh, [f0, f0.lerp(e1, 0.45) + Vector3(0, 0, -0.03), e1.lerp(e0, 0.12) + Vector3(0, 0, -0.06)], [Vector2(0.4, 0.1), Vector2(0.28, 0.08), Vector2(0.02, 0.02)], MK, 10, 3, true, true, Callable(), Vector3.BACK)
	r._mesh(r.head, mh)
	# göz çevresi: buruna doğru eğik dar siyah yama + burun kenarından ağız köşesine inen koyu çizgi
	var mk = MB.new()
	for sx in [-1.0, 1.0]:
		var o := PackedVector2Array()
		for q in [Vector2(0.22, 0.0), Vector2(0.24, 0.2), Vector2(0.48, 0.3), Vector2(0.92, 0.5), Vector2(0.8, 0.28), Vector2(0.58, 0.12), Vector2(0.4, -0.02)]:
			o.append(face.call(q.x * sx, q.y))
		hs.patch(mk, o, DARK, 0.03, 0.07)
		hs.ribbon(mk, [face.call(0.3 * sx, 0.02), face.call(0.42 * sx, -0.12), face.call(0.6 * sx, -0.26), face.call(0.82 * sx, -0.36)], func(u: float) -> float: return 0.07 * (1.0 - u * 0.7), DARK, 0.03)
	r._mesh(r.head, mk)
	# alın sarmalları ve kafa arkası kıvrımları
	var mf = MB.new()
	hs.flame_marks(mf, 2, 5, 37, MK, 0.07, 1.0, 0.68, 0.98, -PI * 0.5 - 1.1, -PI * 0.5 + 1.1, PI * 0.5)
	hs.flame_marks(mf, 3, 5, 39, MK, 0.085, 0.95, 0.1, 0.95, -0.5, PI + 0.5)
	r._mesh(r.head, mf)
	# gözler: siyah yamanın içinde küçük, sarı, yıldız bebekli
	for sx in [-1.0, 1.0]:
		var fq: Vector2 = face.call(0.52 * sx, 0.2)
		var ed = hs.at(fq.x, fq.y, 0.05)
		var eb = Basis.looking_at(ed[1], Vector3.UP) * Basis(Vector3.BACK, deg_to_rad(-22 * sx))
		BeastModels._anime_eye(r, r.head, ed[0], Vector3(0.32, 0.14, 0.08), Color(0.95, 0.78, 0.12), Color(1.0, 0.86, 0.18), Color(0.02, 0.02, 0.02), eb.get_euler() * 180.0 / PI, "star")
	r._collider(r.head, Vector3(0, 0.1, -0.3), Vector3(4.2, 3.8, 4.0))
	# alt dudak: ince hilal (kova değil), arkadan menteşeli (yerel +Z = ileri; pozitif rotation.x indirir)
	r.jaw = r._pivot(r.head, Vector3(0, -0.9, 0.3), "cene")
	r.jaw.rotation.y = PI
	var mj = MB.new()
	var jl_y = func(ph: float) -> float: return -0.78 + 0.42 * pow(absf(ph) / 1.5, 2.0)
	var jl: Array = []; var jr: Array = []
	for i in 15:
		var ph = lerpf(-1.55, 1.55, i / 14.0)
		jl.append(Vector3(sin(ph) * 1.9, jl_y.call(ph), 0.6 + cos(ph) * 1.5))
		jr.append(Vector2(0.17, 0.22))
	Loft.tube(mj, jl, jr, C, 8, 3)
	mj.add("sphere", Vector3(0, -0.95, 0.75), Vector3(3.6, 0.55, 2.9), C, Vector3.ZERO, 14)   # çene altı
	mj.add("sphere", Vector3(0, -0.78, 0.75), Vector3(3.4, 0.4, 2.75), DARK, Vector3.ZERO, 14)
	for i in 20:
		var ph = lerpf(-1.42, 1.42, (i + 0.5) / 20.0)
		var on = Vector3(sin(ph), 0, cos(ph))
		_fang(mj, Vector3(sin(ph) * 1.9, jl_y.call(ph) + 0.08, 0.6 + cos(ph) * 1.5), Vector3(0, 1, 0), 0.42 if i % 2 == 0 else 0.3, 0.14, on)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -1.1, -2.3), "agiz")
	r.head.scale = Vector3.ONE * 0.8   # kullanıcı 2026-11-11: baş gövdeye göre çok büyük
	# --- kollar: yanlardan çıkar, dirsek dışarıda, önkol aşağı; pençeler gövdenin iki yanında yere yakın
	for sx in [-1.0, 1.0]:
		var SH = Vector3(3.3 * sx, 7.3, 0.1)
		var EL = Vector3(5.8 * sx, 4.9, -0.5)
		var WR = Vector3(7.3 * sx, 2.3, -1.6)
		var sh = r._pivot(r.chest, SH - CH, "omuz")
		var ma = MB.new()
		var us = BeastSurf.tube(ma, [Vector3(-0.5 * sx, 0.3, 0.0), (EL - SH) * 0.5 + Vector3(0.2 * sx, 0.2, 0), EL - SH], [2.2, 1.85, 1.45], C, 26, 6)
		us.flame_marks(ma, 3, 7, 51 + int(sx), MK, 0.11, 1.2, 0.2, 0.97, -PI, PI, PI * 0.5)
		r._mesh(sh, ma)
		var el = r._pivot(sh, EL - SH, "dirsek")
		var mf2 = MB.new()
		var fs = BeastSurf.tube(mf2, [Vector3.ZERO, (WR - EL) * 0.5 + Vector3(0.15 * sx, 0, 0), WR - EL], [1.45, 1.4, 1.15], C, 24, 6)
		fs.flame_marks(mf2, 2, 6, 61 + int(sx), MK, 0.1, 1.1, 0.05, 0.97, -PI, PI, PI * 0.5)
		var w = WR - EL
		mf2.add("sphere", w + Vector3(0, -0.45, -0.25), Vector3(2.2, 1.7, 2.0), C, Vector3.ZERO, 14)   # el
		for f in 4:   # uzun pençeler: aşağı-öne, uçları içe kıvrık
			var ph = lerpf(-0.8, 0.8, f / 3.0)
			_digit(mf2, w + Vector3(sin(ph) * 0.8, -0.8, -0.55 - cos(ph) * 0.3), Vector3(sin(ph) * 0.5, -0.75, -0.75), 1.9, 0.34, Vector3(-0.15 * sx, -0.25, 0.4))
		r._mesh(el, mf2)
		r.arms.append({"sh": sh, "el": el, "side": sx})
		# --- ayaklar: göbeğin altında, yalnız parmak uçları öne taşar
		var HI = Vector3(2.4 * sx, 1.6, -1.6)
		var KN = Vector3(2.8 * sx, 1.0, -2.9)
		var AN = Vector3(2.8 * sx, 0.5, -3.5)
		var hi = r._pivot(r.hips, HI - HP, "kalca")
		var ml = MB.new()
		Loft.tube(ml, [Vector3(0, 0.2, 0.5), (KN - HI) * 0.5, KN - HI], [1.3, 1.1, 0.9], C, 16, 3)
		r._mesh(hi, ml)
		var kn = r._pivot(hi, KN - HI, "diz")
		var mk2 = MB.new()
		Loft.tube(mk2, [Vector3.ZERO, AN - KN], [0.9, 0.7], C, 14, 3)
		var a = AN - KN
		mk2.add("sphere", a + Vector3(0, -0.1, -0.4), Vector3(1.6, 0.75, 1.5), C, Vector3.ZERO, 12)
		for f in 3:
			var ph = lerpf(-0.55, 0.55, f / 2.0) + 0.12 * sx
			_digit(mk2, a + Vector3(sin(ph) * 0.65, -0.15, -0.8 - cos(ph) * 0.3), Vector3(sin(ph), 0, -cos(ph)), 1.25, 0.27, Vector3(0, -0.22, 0))
		r._mesh(kn, mk2)
		r.legs.append({"hip": hi, "kn": kn, "side": sx, "front": false, "slide": 1.0})
	_tail(r, Vector3(0, 3.0, 3.7) - HP)
	BeastModels._particles(r.hips, Vector3(4.5, 4.0, 4.0), [Color(0.78, 0.7, 0.56, 0.8), Color(0.78, 0.7, 0.56, 0.0)], 60, 1.2, Vector3(0, -3, 0), 2.0)
	r._weak(r.hips, Vector3(0, 6.4, 0.0))
	r._weak(r.hips, Vector3(0, -0.4, -5.6))
	r._weak(r.hips, Vector3(0, 1.5, 4.5))


## Kuyruk: çok kalın, yaprak pullu, yukarı kalkık; her segment ayrı pivot (BeastRig dalga animasyonu)
static func _tail(r: BeastRig, base_pos: Vector3) -> void:
	var n = 10
	var length = 16.0
	var seg_len = length / n
	var rf = func(k: float) -> float:
		return lerpf(1.7, 2.2, sin(minf(1.0, k * 2.5) * PI * 0.5)) * (1.0 - pow(k, 2.2) * 0.93)
	var base = r._pivot(r.hips, base_pos, "kuyruk_koku")
	var root = r._pivot(base, Vector3.ZERO, "tail")
	var pitch = -62.0
	root.rotation = Vector3(deg_to_rad(pitch), 0, 0)
	r.tail_curl = -0.03
	var segs = []
	var parent = root
	for i in n:
		var k0 = float(i) / n
		var k1 = float(i + 1) / n
		var r0: float = rf.call(k0)
		var r1: float = maxf(0.04, rf.call(k1))
		var hold = parent
		if i >= n - 5:   # uç öne kıvrılır (Storm): animasyon pivotundan bağımsız sabit büküm
			hold = r._pivot(parent, Vector3(0, 0, seg_len), "bukum")
			hold.rotation.x = -0.3
		var piv = r._pivot(hold, Vector3(0, 0, seg_len) if (i > 0 and hold == parent) else Vector3.ZERO, "s%d" % i)
		var mb = MB.new()
		Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.2), Vector3(0, 0, seg_len * 0.5), Vector3(0, 0, seg_len * 1.15)], [r0 * 0.86, (r0 + r1) * 0.43, r1 * 0.86], C.darkened(0.08), 16, 2)
		# iki halka pul, sıralar arası kaydırılmış (kiremit dizilişi)
		for ring in 2:
			var kk = lerpf(k0, k1, ring * 0.5)
			var rr: float = rf.call(kk)
			var cnt = 9 if rr > 1.5 else (7 if rr > 0.8 else 5)
			for s in cnt:
				var ang = TAU * (s + (0.5 if (i * 2 + ring) % 2 == 1 else 0.0)) / cnt
				var nrm = Vector3(cos(ang), sin(ang), 0)
				var d = (Vector3(0, 0, 1) + nrm * 0.2).normalized()
				var p0 = nrm * rr * 0.8 + Vector3(0, 0, seg_len * ring * 0.5)
				var L = seg_len * 1.25 * (0.4 + 0.6 * rr / 2.2)
				var w = rr * TAU / cnt * 0.6
				_flat(mb, [p0, p0 + d * L * 0.35, p0 + d * L * 0.72, p0 + d * L], [Vector2(w * 0.55, 0.16), Vector2(w, 0.15), Vector2(w * 0.7, 0.1), Vector2(0.02, 0.02)], C, nrm)
				# pulun lacivert alev izi
				var m0 = p0 + d * L * 0.3 + nrm * 0.15
				_flat(mb, [m0, m0 + d * L * 0.25 + nrm * 0.02, m0 + d * L * 0.55], [Vector2(w * 0.08, 0.03), Vector2(w * 0.17, 0.03), Vector2(0.01, 0.01)], MK, nrm)
		r._mesh(piv, mb)
		segs.append(piv)
		parent = piv
	r.tails.append(segs)
	r.tail_cfg.append({"yaw": 0.0, "pitch": deg_to_rad(pitch), "amp": 0.13, "phase": randf() * TAU, "style": "sand", "root": root})
