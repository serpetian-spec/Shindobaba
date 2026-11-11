class_name BeastSaiken
extends RefCounted
## Saiken — Altı Kuyruk. Referans: _tmp/ref/saiken_storm (Storm 4 kareleri A, head.png) + _tmp/ref/saiken (anime)
## Okunan yapı:
##  - beyaz-leylak, sümüksü, dik oturan ARMUT gövde: altta geniş göbek halkası (kat), üstte daralan gövde
##  - baş boyunsuz, kova gibi: düz yanlı, yuvarlak tepeli; yüzün ortasında yan yana dikey YARIK sırası (ağız ızgarası)
##  - tepede iki göz sapı (anten), uçları koyu top
##  - kısa küt kollar, ucunda üç-dört minik parmak; altta önde iki küt ayak
##  - altı kalın kuyruk arkadan yukarı taç yaprağı gibi kalkar (gövdeden uzun), uçları dışa kıvrılır
##  - her yerden sümük damlar: baş kenarı, kollar, kuyruk uçları; kuyruklar arasında sümük iplikleri

const C := Color(0.92, 0.92, 0.98)
const C_D := Color(0.74, 0.74, 0.88)
const C_L := Color(1.0, 1.0, 1.0)
const DK := Color(0.2, 0.2, 0.3)


static func _col(_t: float, _a: float, d: Vector3) -> Color:
	return C.lerp(C_D, clampf((-d.y - 0.1) * 1.3, 0.0, 1.0) * 0.8 + clampf(d.z, 0.0, 1.0) * 0.25)


## Sarkan sümük damlası: tabandan aşağı incelip ucunda damla
static func _drip(mb: MB, base: Vector3, ln: float, w: float) -> void:
	Loft.tube(mb, [base + Vector3(0, w * 0.6, 0), base + Vector3(0, -ln * 0.5, 0), base + Vector3(0, -ln * 0.86, 0), base + Vector3(0, -ln, 0)], [w * 0.45, w * 0.3, w * 0.62, w * 0.3], C_L, 8, 3, true, true)


static func build(r: BeastRig, root: Node3D) -> void:
	r.quadruped = false
	r.upright = true
	var HP = Vector3(0, 1.9, 0.2)
	r.hips = r._pivot(root, HP, "kalca_kok")
	# --- alt gövde: geniş göbek halkası (yere yayılan etek + kat)
	var mb = MB.new()
	Loft.tube(mb, [Vector3(0, 0.05, 0.2) - HP, Vector3(0, 0.5, 0.2) - HP, Vector3(0, 1.6, 0.15) - HP, Vector3(0, 2.7, 0.05) - HP, Vector3(0, 3.4, 0.0) - HP],
		[3.0, 3.7, 3.85, 3.4, 2.6], C, 36, 8, true, true, _col)
	for i in 9:   # etek kenarından yere yayılan sümük lobları
		var a = TAU * i / 9.0 + 0.3
		mb.add("sphere", Vector3(sin(a) * 3.5, 0.25, 0.2 + cos(a) * 3.5) - HP, Vector3(1.9, 0.6, 1.9), C_D.lerp(C, 0.5), Vector3.ZERO, 10)
	for i in 7:   # kat altından sarkan damlalar
		var a = lerpf(-1.9, 1.9, i / 6.0)
		_drip(mb, Vector3(sin(a) * 3.75, 1.9 + 0.3 * sin(i * 2.1), 0.15 - cos(a) * 3.75) - HP, 0.7 + 0.4 * fposmod(i * 0.37, 1.0), 0.2)
	r._mesh(r.hips, mb)
	r._collider(r.hips, Vector3(0, 0.0, 0.0), Vector3(7.4, 3.6, 7.4))
	# --- üst gövde: göbek katının içinden çıkan, yukarı daralan gövde
	var CH = Vector3(0, 3.2, 0.0)
	r.chest = r._pivot(r.hips, CH - HP, "gogus")
	var mc = MB.new()
	Loft.tube(mc, [Vector3(0, 2.6, 0.0) - CH, Vector3(0, 3.5, 0.0) - CH, Vector3(0, 4.6, -0.05) - CH, Vector3(0, 5.5, -0.1) - CH, Vector3(0, 6.0, -0.1) - CH],
		[2.9, 3.15, 2.85, 2.35, 1.9], C, 36, 8, true, true, _col)
	for i in 6:   # gövdeden süzülen sümük izleri
		var a = lerpf(-1.3, 1.3, i / 5.0)
		_drip(mc, Vector3(sin(a) * 2.95, 4.4 - 0.3 * (i % 2), -0.05 - cos(a) * 2.95) - CH, 0.9 + 0.3 * (i % 3), 0.17)
	r._mesh(r.chest, mc)
	r._collider(r.chest, Vector3(0, 1.3, 0), Vector3(6.2, 3.6, 6.0))
	# --- baş: kova (düz yan, yuvarlak tepe), boyun yok; yüzde dikey yarık sırası; tepede iki göz sapı
	var HD = Vector3(0, 6.0, -0.15)
	r.head = r._pivot(r.chest, HD - CH, "bas")
	var mh = MB.new()
	Loft.tube(mh, [Vector3(0, -0.4, 0), Vector3(0, 0.3, 0), Vector3(0, 1.3, 0), Vector3(0, 1.95, 0), Vector3(0, 2.3, 0)], [2.0, 2.05, 1.95, 1.6, 0.9], C, 30, 8, true, true, _col)
	# baş kenarı: kovanın alt ağzı gövdeye sümük gibi sarkar
	for i in 10:
		var a = TAU * i / 10.0 + 0.2
		_drip(mh, Vector3(sin(a) * 2.02, -0.1, -cos(a) * 2.02), 0.6 + 0.5 * fposmod(i * 0.61, 1.0), 0.24)
	# ağız ızgarası: dikey yarıklar, yüz yayında
	for i in 8:
		var a = deg_to_rad(lerpf(-52.0, 52.0, i / 7.0))
		var p = Vector3(sin(a) * 2.02, 0.75, -cos(a) * 2.02)
		mh.add("sphere", p, Vector3(0.17, 0.72, 0.17), DK, Vector3(0, -rad_to_deg(a), 0), 8)
	# göz sapları: tepeden yukarı-dışa, ucu koyu top
	for sx in [-1.0, 1.0]:
		var s0 = Vector3(0.75 * sx, 2.0, -0.35)
		var s1 = Vector3(1.25 * sx, 3.1, -0.55)
		var s2 = Vector3(1.75 * sx, 3.6, -0.75)
		Loft.tube(mh, [s0, s1, s2], [0.26, 0.15, 0.13], C, 8, 4)
		mh.add("sphere", s2 + Vector3(0.08 * sx, 0.08, -0.03), Vector3(0.46, 0.46, 0.46), C, Vector3.ZERO, 10)
		mh.add("sphere", s2 + Vector3(0.14 * sx, 0.14, -0.12), Vector3(0.3, 0.3, 0.3), DK, Vector3.ZERO, 8)
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3(0, 1.0, 0), Vector3(4.2, 3.0, 4.2))
	# çene: ızgaranın altında ince dudak (asit püskürtürken açılır)
	r.jaw = r._pivot(r.head, Vector3(0, 0.3, -1.6), "cene")
	r.jaw.rotation.y = PI
	var mj = MB.new()
	Loft.tube(mj, [Vector3(-1.4, 0, 0.1), Vector3(0, -0.05, 0.5), Vector3(1.4, 0, 0.1)], [0.005, 0.005, 0.005], C, 4, 2)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, 0.7, -2.3), "agiz")
	# --- kollar: kısa, küt; ucunda minik parmaklar
	for sx in [-1.0, 1.0]:
		var S = Vector3(2.35 * sx, 4.7, -1.5)
		var E = Vector3(2.95 * sx, 4.25, -2.15)
		var Wr = Vector3(3.05 * sx, 3.8, -2.95)
		var sh = r._pivot(r.chest, S - CH, "omuz")
		var m1 = MB.new()
		Loft.tube(m1, [Vector3(-0.25 * sx, 0.05, 0.15), (E - S) * 0.5, E - S], [0.2, 0.17, 0.14], C, 10, 4, true, true, _col)
		r._mesh(sh, m1)
		var el = r._pivot(sh, E - S, "dirsek")
		var m2 = MB.new()
		Loft.tube(m2, [Vector3.ZERO, (Wr - E) * 0.6, Wr - E], [0.14, 0.12, 0.13], C, 10, 4, true, true, _col)
		for f in 4:
			var fa = lerpf(-0.9, 0.9, f / 3.0)
			var f0 = Wr - E + Vector3(sin(fa) * 0.08, cos(fa) * 0.03 - 0.02, -0.05)
			Loft.tube(m2, [f0, f0 + Vector3(sin(fa) * 0.08, 0.03, -0.11), f0 + Vector3(sin(fa) * 0.12, 0.05, -0.2)], [0.05, 0.04, 0.03], C, 6, 3)
		r._mesh(el, m2)
		r.arms.append({"sh": sh, "el": el, "side": sx})
		# ayak: önde küt lob (kayarak yürür)
		var F = Vector3(1.5 * sx, 0.4, -3.0)
		var hip = r._pivot(r.hips, F - HP, "kalca")
		var m3 = MB.new()
		m3.add("sphere", Vector3(0, 0, 0.3), Vector3(1.7, 0.85, 2.3), C, Vector3.ZERO, 12)
		for f in 3:
			m3.add("sphere", Vector3((f - 1) * 0.45, -0.05, -0.75), Vector3(0.5, 0.45, 0.6), C, Vector3.ZERO, 8)
		r._mesh(hip, m3)
		var kn = r._pivot(hip, Vector3(0, -0.2, 0), "diz")
		r.legs.append({"hip": hip, "kn": kn, "side": sx, "front": false, "slide": 0.6})
	_tails(r, Vector3(0, 1.6, 2.6) - HP)
	BeastModels._particles(r.hips, Vector3(3.4, 0.5, 3.4), [Color(0.9, 0.9, 1.0, 0.6), Color(0.9, 0.9, 1.0, 0.0)], 30, 1.0, Vector3(0, -2, 0), 1.5)
	r._weak(r.head, Vector3(0, 2.0, -0.2))
	r._weak(r.hips, Vector3(0, 0.5, 4.2))


## Altı kalın kuyruk: arkada yelpaze, dik yukarı kalkar; ortası şişkin, ucu sivrilip dışa-aşağı kıvrılır; uçtan sümük sarkar
static func _tails(r: BeastRig, base_pos: Vector3) -> void:
	var n = 8
	var length = 10.5
	var seg_len = length / n
	var rf = func(k: float) -> float:
		return lerpf(1.0, 1.6, sin(minf(1.0, k * 2.2) * PI * 0.5)) * (1.0 - pow(k, 2.4) * 0.62)
	var base = r._pivot(r.hips, base_pos, "kuyruk_koku")
	r.tail_curl = 0.0
	for ti in 6:
		var yaw = lerpf(-100.0, 100.0, ti / 5.0)
		var pitch = -62.0 + absf(ti - 2.5) * 9.0
		var troot = r._pivot(base, Vector3(sin(deg_to_rad(yaw)) * 1.6, 0, cos(deg_to_rad(yaw)) * 1.0 - 0.6), "tail")
		troot.rotation = Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0)
		var segs = []
		var parent = troot
		for i in n:
			var r0: float = rf.call(float(i) / n)
			var r1: float = rf.call(float(i + 1) / n)
			var piv = r._pivot(parent, Vector3(0, 0, seg_len) if i > 0 else Vector3.ZERO, "s%d" % i)
			var mb = MB.new()
			Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.2), Vector3(0, 0, seg_len * 0.5), Vector3(0, 0, seg_len * 1.12)], [r0, (r0 + r1) * 0.5, r1], C, 14, 3, i == 0, true, _col)
			if i == n - 1:   # yuvarlak uç
				mb.add("sphere", Vector3(0, 0, seg_len * 1.1), Vector3(r1 * 2.0, r1 * 2.0, r1 * 2.2), C, Vector3.ZERO, 12)
			r._mesh(piv, mb)
			segs.append(piv)
			parent = piv
		r.tails.append(segs)
		r.tail_cfg.append({"yaw": deg_to_rad(yaw), "pitch": deg_to_rad(pitch), "amp": 0.07, "phase": randf() * TAU, "style": "fur", "root": troot, "s_amp": 0.2, "s_yaw": 0.0})
