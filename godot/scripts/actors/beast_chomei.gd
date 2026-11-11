class_name BeastChomei
extends RefCounted
## Chōmei — Yedi Kuyruk. Referans: _tmp/ref/chomei_storm (Storm 4 kareleri A/B, head.png) + _tmp/ref/chomei (anime)
## Okunan yapı:
##  - mavi-gri ZIRHLI gergedan böceği, havada dik durur; göğüs zırhı + iki yanda dev kubbe omuzluk (önünde dikey havalandırma yarıkları, tepesinde yukarı diken)
##  - kask baş: önde turuncu dikey çizgili vizör, yanlarda diken, tepede uzun yassı boynuz, ucu Y gibi çatallanır
##  - altı ince, çok eklemli böcek kolu; uçlarında pençe parmaklar, öne-aşağı sarkar
##  - göğsün altından aşağı uzun, kalın, boğumlu karın: mavi-griden yeşile döner, ucu sivrilip öne kıvrılır (yedinci kuyruk)
##  - altı kanat belden yıldız gibi açılır: dar-uzun bıçak, kalın açık yeşil kenar ve orta damar, arası turuncu zar

const C := Color(0.5, 0.57, 0.72)
const CD := Color(0.35, 0.4, 0.55)
const CL := Color(0.68, 0.74, 0.86)
const SLIT := Color(0.1, 0.1, 0.16)
const ORN := Color(1.0, 0.62, 0.15)
const GR := Color(0.74, 0.92, 0.56)
const GR_D := Color(0.5, 0.74, 0.42)
const WING := Color(0.9, 0.5, 0.14)
const WING_D := Color(0.62, 0.3, 0.1)


static func _armor(_t: float, _a: float, d: Vector3) -> Color:
	return C.lerp(CD, clampf(-d.y * 1.2 - 0.1, 0.0, 1.0))


static func _abdomen(t: float, _a: float, d: Vector3) -> Color:
	var base = C.lerp(GR, smoothstep(0.15, 0.6, t))
	if fposmod(t * 11.0, 1.0) < 0.14:
		return base.darkened(0.3)   # boğum çizgisi
	return base.lerp(base.darkened(0.25), clampf(d.z * 0.8, 0.0, 1.0))


static func build(r: BeastRig, root: Node3D) -> void:
	r.quadruped = false
	r.upright = true
	var HP = Vector3(0, 5.6, 0.5)
	r.hips = r._pivot(root, HP, "kalca_kok")
	# --- karın: uzun, boğumlu; aşağı iner, ucu öne kıvrılır
	var ab = MB.new()
	Loft.tube(ab, [Vector3(0, 6.0, 0.3) - HP, Vector3(0, 5.0, 0.7) - HP, Vector3(0, 3.6, 1.3) - HP, Vector3(0, 2.2, 1.5) - HP, Vector3(0, 1.0, 1.0) - HP, Vector3(0, 0.3, 0.0) - HP, Vector3(0, 0.15, -0.9) - HP],
		[1.25, 1.45, 1.3, 1.0, 0.7, 0.4, 0.06], C, 26, 8, true, true, _abdomen)
	r._mesh(r.hips, ab)
	r._collider(r.hips, Vector3(0, -2.4, 0.7), Vector3(3.0, 6.0, 3.2))
	# --- göğüs zırhı
	var CH = Vector3(0, 6.3, 0.2)
	r.chest = r._pivot(r.hips, CH - HP, "gogus")
	var mc = MB.new()
	Loft.tube(mc, [Vector3(0, 5.5, 0.3) - CH, Vector3(0, 6.3, 0.15) - CH, Vector3(0, 7.3, 0.0) - CH, Vector3(0, 8.0, -0.1) - CH], [Vector2(1.5, 1.3), Vector2(1.85, 1.5), Vector2(1.75, 1.45), Vector2(1.1, 1.0)], C, 26, 6, true, true, _armor)
	for k in 3:   # göğüs plaka dikişleri (öne V)
		var y = 5.9 + k * 0.6
		Loft.tube(mc, [Vector3(-1.5, y + 0.3, -0.7) - CH, Vector3(0, y - 0.15, -1.42) - CH, Vector3(1.5, y + 0.3, -0.7) - CH], [0.07, 0.09, 0.07], CD, 5, 4)
	for sx in [-1.0, 1.0]:
		# dev kubbe omuzluk: dışa yatık; alt kenarında koyu saçak, önünde dikey yarıklar, tepesinde diken
		var sp = Vector3(2.6 * sx, 7.5, 0.1) - CH
		var bas = Basis(Vector3.BACK, deg_to_rad(-14 * sx))
		mc.add_xf("sphere", Transform3D(Basis.from_scale(Vector3(1.7, 1.4, 1.6)), Vector3(1.4 * sx, 7.2, 0.1) - CH), CD, 12)   # eklem
		mc.add_xf("sphere", Transform3D(bas * Basis.from_scale(Vector3(3.0, 3.5, 3.1)), sp), C, 18)
		mc.add_xf("sphere", Transform3D(bas * Basis.from_scale(Vector3(3.08, 0.5, 3.18)), sp + bas * Vector3(0, -1.2, 0)), CD, 16)
		mc.add_xf("sphere", Transform3D(bas * Basis.from_scale(Vector3(2.5, 1.2, 2.6)), sp + bas * Vector3(0, -1.35, 0)), SLIT, 14)   # kubbenin içi (karanlık)
		Loft.tube(mc, [sp + bas * Vector3(0.3 * sx, 1.3, 0), sp + bas * Vector3(0.7 * sx, 2.5, 0.1), sp + bas * Vector3(1.3 * sx, 3.6, 0.2)], [0.55, 0.36, 0.03], [C, C, CL], 10, 3)   # tepe dikeni
		for k in 6:
			var a = deg_to_rad(lerpf(-70.0, 30.0, k / 5.0))
			var n = Vector3(sin(a) * sx, 0.0, -cos(a)).normalized()
			mc.add_xf("box", Transform3D(bas * Basis.looking_at(-n, Vector3.UP) * Basis.from_scale(Vector3(0.17, 1.35, 0.1)), sp + bas * Vector3(n.x * 1.47, 0.15, n.z * 1.52)), SLIT, 1)
	r._mesh(r.chest, mc)
	r._collider(r.chest, Vector3(0, 0.8, 0), Vector3(7.6, 4.6, 3.4))
	# --- baş: kask + vizör + çatal boynuz
	var HD = Vector3(0, 8.2, -0.5)
	r.head = r._pivot(r.chest, HD - CH, "bas")
	var mh = MB.new()
	Loft.tube(mh, [Vector3(0, -0.5, 0.3), Vector3(0, 0.1, 0.1), Vector3(0, 0.8, 0.0), Vector3(0, 1.2, 0.05)], [Vector2(1.0, 0.95), Vector2(1.2, 1.15), Vector2(1.05, 1.0), Vector2(0.5, 0.5)], C, 20, 5, true, true, _armor)
	# vizör: öne çıkık koyu yüz plakası, turuncu dikey çizgiler; üstünde kaş siperi
	mh.add_xf("sphere", Transform3D(Basis.from_scale(Vector3(1.7, 1.15, 0.9)), Vector3(0, 0.15, -0.85)), SLIT, 12)
	for k in 6:
		var x = lerpf(-0.55, 0.55, k / 5.0)
		mh.add("box", Vector3(x, 0.15, -1.31 + absf(x) * 0.22), Vector3(0.12, 0.7, 0.1), ORN, Vector3(0, -x * 30.0, 0))
	Loft.tube(mh, [Vector3(-1.05, 0.7, -0.7), Vector3(0, 0.95, -1.3), Vector3(1.05, 0.7, -0.7)], [0.2, 0.24, 0.2], CL, 8, 4)   # kaş siperi
	Loft.tube(mh, [Vector3(-0.95, -0.5, -0.65), Vector3(0, -0.68, -1.15), Vector3(0.95, -0.5, -0.65)], [0.16, 0.2, 0.16], C, 8, 4)   # çene siperi
	# boynuz: tepeden yukarı, yassı; ucu Y gibi çatallanır
	var h0 = Vector3(0, 1.0, -0.1)
	var h1 = Vector3(0, 3.6, -0.5)
	Loft.tube(mh, [h0, Vector3(0, 2.3, -0.45), h1], [Vector2(0.52, 0.4), Vector2(0.36, 0.26), Vector2(0.42, 0.2)], C, 10, 4, true, true, Callable(), Vector3.BACK)
	for sx in [-1.0, 1.0]:
		Loft.tube(mh, [h1 + Vector3(0, -0.25, 0), h1 + Vector3(0.55 * sx, 0.45, -0.05), h1 + Vector3(0.8 * sx, 1.35, 0.0)], [0.3, 0.24, 0.03], [C, C, CL], 8, 3)
		# yan kask dikenleri
		Loft.tube(mh, [Vector3(0.85 * sx, 0.5, 0.1), Vector3(1.4 * sx, 1.2, 0.2), Vector3(1.7 * sx, 2.1, 0.3)], [0.34, 0.22, 0.03], [C, C, CL], 8, 3)
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3(0, 0.4, -0.2), Vector3(2.6, 2.6, 2.6))
	r.jaw = r._pivot(r.head, Vector3(0, -0.5, -0.8), "cene")
	var mj = MB.new()
	for sx in [-1.0, 1.0]:   # çene kıskaçları
		BeastRig.claw(mj, Vector3(0.32 * sx, 0, -0.2), Vector3(-0.3 * sx, -0.5, -1.0).normalized(), 0.8, 0.15, CD)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.2, -1.5), "agiz")
	# --- altı böcek kolu: göğsün altından, öne-aşağı sarkar
	for row in 3:
		for sx in [-1.0, 1.0]:
			var sh = Vector3(1.1 * sx, 0.5 - row * 0.65, -0.9 + row * 0.15)
			BeastModels._insect_arm(r, r.chest, sx, sh, Vector3((1.5 - row * 0.2) * sx, 0.15, -1.3), Vector3((0.5 - row * 0.1) * sx, -1.9 + row * 0.2, -1.2), 0.16, CL, CD, 0.6)
	# --- altı kanat: belden yıldız gibi açılır (üst çift yukarı, orta çift yana, alt çift aşağı-yana)
	var wb = r._pivot(r.hips, Vector3(0, 0.3, 1.0), "kanat_koku")
	for i in 6:
		var sx2 = -1.0 if i < 3 else 1.0
		var k = i % 3
		var yaw = [35.0, 72.0, 98.0][k] * sx2
		var pitch = [-74.0, -48.0, -18.0][k]
		_wing(r, wb, yaw, pitch, [21.0, 20.0, 16.0][k])
	BeastModels._particles(wb, Vector3(6.0, 4.0, 3.0), [Color(0.9, 1.0, 0.6, 0.7), Color(0.9, 1.0, 0.6, 0.0)], 40, 0.5, Vector3(0, -1, 0), 2.0, true)
	r._weak(r.head, Vector3(0, 1.4, 0.0))
	r._weak(r.chest, Vector3(0, 1.6, 1.4))


## Kanat: dar-uzun bıçak (yerel +Z boyunca, genişlik yerel Y); kalın yeşil kenar + orta damar, arası turuncu zar, ince yan damarlar
static func _wing(r: BeastRig, base: Node3D, yaw_deg: float, pitch_deg: float, length: float) -> void:
	var root = r._pivot(base, Vector3.ZERO, "tail")
	root.rotation = Vector3(deg_to_rad(pitch_deg), deg_to_rad(yaw_deg), 0)
	var piv = r._pivot(root, Vector3.ZERO, "s0")
	var mb = MB.new()
	var n = 14
	var wf = func(u: float) -> float:   # yarı genişlik: dipte dar sap, %60'ta en geniş, uca sivri
		return 0.22 + 1.55 * pow(sin(clampf(u, 0.0, 1.0) * PI), 0.8) * (0.55 + 0.45 * u)
	var mid = []
	var e_up = []
	var e_dn = []
	var rad_m = []
	var rad_w = []
	for i in n + 1:
		var u = float(i) / n
		var w: float = wf.call(u)
		var z = u * length
		mid.append(Vector3(0, 0, z))
		e_up.append(Vector3(0, w, z))
		e_dn.append(Vector3(0, -w, z))
		rad_m.append(Vector2(0.06, maxf(0.05, w)))
		rad_w.append(lerpf(0.32, 0.06, u))
	var cols = []
	for i in n + 1:
		cols.append(WING.lerp(WING_D, pow(float(i) / n, 1.5) * 0.7))
	Loft.tube(mb, mid, rad_m, cols, 6, 1, true, true, Callable(), Vector3.UP)   # zar
	Loft.tube(mb, mid, rad_w.map(func(q): return q * 1.15), GR, 6, 1)            # orta damar
	Loft.tube(mb, e_up, rad_w, GR, 6, 1)
	Loft.tube(mb, e_dn, rad_w, GR, 6, 1)
	for i in range(2, n, 2):   # yan damarlar
		var u = float(i) / n
		var w: float = wf.call(minf(1.0, u + 0.08))
		for sy in [-1.0, 1.0]:
			Loft.tube(mb, [Vector3(0.07, 0, u * length), Vector3(0.07, sy * w * 0.6, (u + 0.05) * length), Vector3(0.07, sy * w * 0.95, (u + 0.08) * length)], [0.05, 0.04, 0.03], GR_D, 4, 2)
			Loft.tube(mb, [Vector3(-0.07, 0, u * length), Vector3(-0.07, sy * w * 0.6, (u + 0.05) * length), Vector3(-0.07, sy * w * 0.95, (u + 0.08) * length)], [0.05, 0.04, 0.03], GR_D, 4, 2)
	r._mesh(piv, mb)
	r.tails.append([piv])
	r.tail_cfg.append({"yaw": deg_to_rad(yaw_deg), "pitch": deg_to_rad(pitch_deg), "amp": 0.3, "phase": randf() * TAU, "style": "wing", "root": root})
