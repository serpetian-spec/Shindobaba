class_name Doki
extends Node3D
## Doki (kanon, Tayuya'nın Mateki: Genbu Sōkyoku ile çağırdığı üç iblis savaşçı). Referans: _tmp/dokiref (Narutopedia "Doki.png",
## "Doki Attack.png"): Tayuya'nın 3-4 katı boyda (~5 m), kambur, gözleri sargıyla bağlı; hepsinin belinde kalın MOR ip (shimenawa).
## 0 Gürzlü: koyu yeşil cüppe, uzun kahverengi saç sırttan sarkar, omzunda delikli gri dev gürz (kanabō), ten rengi kolluklar.
## 1 Pençeli: kel, kaslı pembe ten, iki küçük beyaz boynuz, ağızdan aşağı iki kara dikiş çizgisi, kahverengi hakama,
##    sargılı ön kollardan çıkan uzun eğri kemik bıçaklar.
## 2 Sargılı: baştan aşağı beyaz sargılı iri yuvarlak gövde, sargılı kafa, sırtta ve kollarda mor boğumlu ip kangalları.
## Ruh solucanları (Mateki: Mugen Onsa / ruh yeme): ağızlardan çıkan mor boğumlu solucanlar (Doki.spirit_worm).
## Tasarım birimi: ayakta boy 10 birim (BeastRig.D), ön -Z.

const H := 6.2   # tasarım boyu (dik); kambur duruşta ~5 m (ref: Tayuya kalçalarına ancak gelir)
const ROPE := Color(0.5, 0.42, 0.66)
const BANDAGE := Color(0.93, 0.92, 0.88)
const HORN := Color(0.95, 0.94, 0.9)

var kind := 0
var rig: BeastRig
var root: Node3D
var hips: Node3D
var torso: Node3D
var head: Node3D
var jaw: Node3D
var arms: Array = []
var legs: Array = []
var weapon: Node3D
var t := 0.0
var pose_from := {}
var pose_to := {}
var pose_k := 1.0
var pose_dur := 0.4
var jaw_want := 0.0
var jaw_open := 0.0


static func spawn(parent: Node, at: Vector3, yaw: float, k: int) -> Doki:
	var d = Doki.new()
	d.kind = k
	parent.add_child(d)
	d.global_position = at
	d.rotation.y = yaw
	return d


func _ready() -> void:
	_build()
	set_pose("stand", 0.0)


func _skin() -> Color:
	return [Color(0.6, 0.52, 0.48), Color(0.9, 0.72, 0.64), BANDAGE][kind]


func _mi(parent: Node3D, mb: MB) -> MeshInstance3D:
	return rig._mesh(parent, mb)


# ------------------------------------------------------------------ kurulum
func _build() -> void:
	rig = BeastRig.new()
	rig.id = "doki_%d" % kind
	rig.height_m = H
	add_child(rig)
	root = Node3D.new()
	rig.add_child(root)
	hips = rig._pivot(root, Vector3(0, 3.3, 0), "kalca")
	torso = rig._pivot(hips, Vector3(0, 0.25, 0), "govde")
	_build_torso()
	head = rig._pivot(torso, Vector3(0, 4.5, -1.05), "bas")
	_build_head()
	for s in [-1.0, 1.0]:
		_build_arm(s)
		_build_leg(s)
	_build_rope()
	if kind == 0:
		_build_club()
	root.scale = Vector3.ONE * rig.design_scale()
	var bm = BeastModels.beast_material(1, Color(0.42, 0.36, 0.42))
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if mi.material_override == null and mi.mesh and mi.mesh.get_surface_count() > 0 and mi.mesh.surface_get_material(0) == Props.toon():
			mi.material_override = bm


func _band_fn(base: Color, band: Color, freq: float) -> Callable:
	# sargı sarmalı: gövde boyunca eğik bantlar (Sargılı'nın tamamı, kolluk ve ön kol sargıları)
	return func(tt: float, a: float, _d: Vector3) -> Color:
		return band if fmod(tt * freq + a / TAU * 0.6, 1.0) < 0.12 else base


## Yatay sargı katları (ref Sargılı: gövdeyi enine saran belirgin kat çizgileri)
func _hband_fn(base: Color, line: Color, freq: float) -> Callable:
	return func(tt: float, _a: float, _d: Vector3) -> Color:
		return line if fmod(tt * freq, 1.0) < 0.14 else base


func _build_torso() -> void:
	var sk = _skin()
	var mb = MB.new()
	match kind:
		0:   # cüppeli, kambur: geniş omuz, cüppe beline kadar
			var sp = [Vector3(0, -0.2, 0.05), Vector3(0, 1.0, 0.2), Vector3(0, 2.3, 0.45), Vector3(0, 3.4, 0.4), Vector3(0, 4.1, -0.2)]
			var rd = [Vector2(1.55, 1.0), Vector2(1.7, 1.05), Vector2(2.05, 1.25), Vector2(2.2, 1.25), Vector2(1.0, 0.75)]
			Loft.tube(mb, sp, rd, Color(0.2, 0.27, 0.2), 20, 4)
			# cüppe yakası: V açıklık (ten görünür)
			Loft.blob(mb, Vector3(0, 2.8, -0.85), Vector3(0, -1, -0.15), 1.1, [Vector2(0.1, 0.05), Vector2(0.35, 0.12), Vector2(0.18, 0.08), Vector2(0.05, 0.03)], sk, 10)
			# sırttan sarkan uzun kahverengi saç
			for k in 9:
				var x = lerpf(-0.9, 0.9, k / 8.0)
				Loft.tube(mb, [Vector3(x * 0.6, 4.6, -0.4), Vector3(x * 0.9, 4.0, 0.9), Vector3(x * 1.1, 2.4, 1.45), Vector3(x * 1.15, 0.8, 1.35)], [0.26, 0.28, 0.24, 0.07], Color(0.4, 0.28, 0.18).darkened(0.08 * (k % 2)), 6, 3)
		1:   # çıplak kaslı gövde: iri göğüs, karın, omuz tepeleri
			var sp = [Vector3(0, -0.2, 0.0), Vector3(0, 1.0, 0.05), Vector3(0, 2.3, 0.2), Vector3(0, 3.4, 0.2), Vector3(0, 4.1, -0.25)]
			var rd = [Vector2(1.6, 0.95), Vector2(1.75, 1.0), Vector2(2.1, 1.2), Vector2(2.3, 1.2), Vector2(1.0, 0.75)]
			Loft.tube(mb, sp, rd, sk, 20, 4)
			for s in [-1.0, 1.0]:
				Loft.blob(mb, Vector3(s * 0.7, 2.9, -0.88), Vector3(s * 0.3, -0.4, -1), 1.0, [Vector2(0.15, 0.1), Vector2(0.62, 0.32), Vector2(0.5, 0.25), Vector2(0.1, 0.05)], sk, 12)   # göğüs kası
				Loft.blob(mb, Vector3(s * 1.95, 3.35, 0.05), Vector3(s * 0.4, -1, 0), 1.1, [Vector2(0.2, 0.2), Vector2(0.5, 0.48), Vector2(0.44, 0.4), Vector2(0.18, 0.18)], sk, 12)   # omuz
				for k in 3:   # karın kasları
					mb.add("sphere", Vector3(s * 0.32, 0.7 + k * 0.5, -0.86), Vector3(0.5, 0.42, 0.22), sk.darkened(0.04), Vector3.ZERO, 8)
			# göğüste kara dikiş/çizik izleri (ref: göğüs üstünde koyu yara)
			mb.add("box", Vector3(0, 2.6, -1.1), Vector3(0.07, 0.7, 0.05), Color(0.25, 0.15, 0.15))
		2:   # yuvarlak, şişkin sargılı gövde
			var sp = [Vector3(0, -0.3, 0.0), Vector3(0, 1.0, 0.0), Vector3(0, 2.2, 0.1), Vector3(0, 3.4, 0.1), Vector3(0, 4.1, -0.15)]
			var rd = [Vector2(1.5, 1.25), Vector2(2.0, 1.6), Vector2(2.2, 1.75), Vector2(1.95, 1.5), Vector2(0.95, 0.8)]
			Loft.tube(mb, sp, rd, BANDAGE, 24, 12, true, true, _hband_fn(BANDAGE, Color(0.55, 0.55, 0.55), 13.0))
	_mi(torso, mb)
	# boyun
	var nb = MB.new()
	Loft.tube(nb, [Vector3(0, 3.7, -0.2), Vector3(0, 4.15, -0.65), Vector3(0, 4.5, -1.05)], [0.62, 0.55, 0.5], _skin() if kind != 0 else Color(0.6, 0.52, 0.48), 12, 3)
	_mi(torso, nb)


func _build_head() -> void:
	var sk = _skin()
	var mb = MB.new()
	if kind == 2:   # spiral sargılı top kafa (ref: sarmal kat kat bant, tepede küçük düğüm)
		Loft.blob(mb, Vector3(0, 0.55, -0.05), Vector3(0, 1, 0), 1.3, [Vector2(0.55, 0.55), Vector2(0.78, 0.78), Vector2(0.72, 0.72), Vector2(0.3, 0.3)], BANDAGE, 16, _band_fn(BANDAGE, BANDAGE.darkened(0.28), 6.0))
		mb.add("sphere", Vector3(0, 1.3, 0.05), Vector3(0.3, 0.22, 0.3), Color(0.92, 0.84, 0.6), Vector3.ZERO, 8)
	else:
		# kafatası (Pençeli kel, Gürzlü tepede saç)
		Loft.blob(mb, Vector3(0, 0.4, 0), Vector3(0, 1, 0), 1.05, [Vector2(0.7, 0.72), Vector2(0.9, 0.86), Vector2(0.8, 0.76), Vector2(0.36, 0.32)], sk, 16)
		# göz bağı: alnın altında kalın beyaz sargı bandı (gözler görünmez)
		mb.add("cyl", Vector3(0, 0.55, -0.02), Vector3(1.86, 0.34, 1.78), BANDAGE, Vector3.ZERO, 18)
		# burun ve ağız çevresi
		mb.add("sphere", Vector3(0, 0.22, -0.86), Vector3(0.26, 0.28, 0.22), sk.darkened(0.05), Vector3.ZERO, 8)
		if kind == 1:
			for s in [-1.0, 1.0]:
				mb.add("cone", Vector3(s * 0.55, 1.05, -0.2), Vector3(0.16, 0.42, 0.16), HORN, Vector3(-15, 0, -s * 35), 8)   # küçük beyaz boynuz
				# ağızdan çeneye inen iki kara dikiş çizgisi (ref)
				mb.add("box", Vector3(s * 0.2, -0.35, -0.95), Vector3(0.06, 0.8, 0.05), Color(0.12, 0.1, 0.1), Vector3(0, 0, s * 4))
		else:
			# tepeden arkaya taranmış kahverengi saç kütlesi
			Loft.blob(mb, Vector3(0, 0.95, 0.25), Vector3(0, 0.3, 1), 1.0, [Vector2(0.5, 0.35), Vector2(0.72, 0.45), Vector2(0.6, 0.35), Vector2(0.3, 0.15)], Color(0.4, 0.28, 0.18), 12)
	_mi(head, mb)
	jaw = rig._pivot(head, Vector3(0, 0.05, -0.15), "cene")
	var jb = MB.new()
	jb.add("sphere", Vector3(0, -0.1, -0.3), Vector3(1.35, 0.55, 0.95), sk if kind != 2 else BANDAGE, Vector3.ZERO, 12)
	jb.add("box", Vector3(0, 0.02, -0.95), Vector3(0.55, 0.06, 0.1), Color(0.2, 0.1, 0.1))   # ağız yarığı
	_mi(jaw, jb)


func _build_arm(s: float) -> void:
	var sk = _skin()
	var thick = [1.25, 1.45, 1.4][kind]
	var sh = rig._pivot(torso, Vector3(s * 2.15, 3.3, 0.05), "omuz")
	var ub = MB.new()
	var ucol = Color(0.2, 0.27, 0.2) if kind == 0 else sk
	Loft.tube(ub, [Vector3(0, 0.15, 0), Vector3(s * 0.12, -1.1, 0), Vector3(s * 0.08, -2.2, 0)], [0.55 * thick, 0.6 * thick, 0.42 * thick], ucol, 12, 3, true, true, _band_fn(BANDAGE, BANDAGE.darkened(0.25), 6.0) if kind == 2 else Callable())
	_mi(sh, ub)
	var el = rig._pivot(sh, Vector3(s * 0.08, -2.2, 0), "dirsek")
	var lb = MB.new()
	var fcol = sk
	var fn = Callable()
	if kind == 0:
		fcol = Color(0.72, 0.58, 0.4)   # ten rengi kolluk
		fn = _band_fn(fcol, fcol.darkened(0.25), 4.0)
	elif kind >= 1:
		fcol = BANDAGE
		fn = _band_fn(BANDAGE, BANDAGE.darkened(0.25), 7.0)
	Loft.tube(lb, [Vector3(0, 0, 0), Vector3(0, -1.1, -0.05), Vector3(0, -2.1, -0.05)], [0.45 * thick, 0.5 * thick, 0.38 * thick], fcol, 12, 8, true, true, fn)
	# el: dev el (ref: yumruklar dizlere kadar iner, iri boğumlu parmaklar)
	var hc = sk if kind != 2 else BANDAGE
	Loft.blob(lb, Vector3(0, -2.5, -0.1), Vector3(0, -1, -0.15), 1.0, [Vector2(0.45, 0.32), Vector2(0.62, 0.42), Vector2(0.55, 0.36), Vector2(0.28, 0.2)], hc, 10)
	for f in 4:
		var fx = lerpf(-0.36, 0.36, f / 3.0)
		BeastRig.limb(lb, Vector3(fx, -2.85, -0.3), Vector3(fx * 1.1, -3.35, -0.5), 0.14, 0.1, hc, 6)
	BeastRig.limb(lb, Vector3(-s * 0.45, -2.5, -0.35), Vector3(-s * 0.55, -2.95, -0.6), 0.15, 0.11, hc, 6)   # başparmak
	if kind == 1:   # ön koldan çıkan iki uzun eğri kemik bıçak (ref: bileğin üstünden aşağı-ileri)
		for k in 2:   # bileğin dış-önünden çıkıp elin önünden aşağı uzanan, ucu içe kıvrık iki kemik bıçak
			var ox = s * (0.2 + k * 0.32)
			var pts = [Vector3(ox, -1.6, -0.55), Vector3(ox * 1.15, -2.6, -0.95), Vector3(ox * 1.2, -3.6, -1.05), Vector3(ox * 1.0, -4.4, -0.75)]
			Loft.tube(lb, pts, [0.24, 0.19, 0.11, 0.015], Color(0.92, 0.85, 0.65), 8, 4)
	_mi(el, lb)
	arms.append({"sh": sh, "el": el, "side": s})


func _build_leg(s: float) -> void:
	var hp = rig._pivot(hips, Vector3(s * 0.95, -0.1, 0.0), "kalca_b")
	var pc = [Color(0.18, 0.24, 0.18), Color(0.45, 0.32, 0.22), Color(0.42, 0.3, 0.22)][kind]   # cüppe / kahverengi hakama
	var ub = MB.new()
	Loft.tube(ub, [Vector3(0, 0.25, 0), Vector3(s * 0.1, -0.8, 0), Vector3(s * 0.06, -1.65, 0)], [0.95, 1.0, 0.75], pc, 12, 3)
	_mi(hp, ub)
	var kn = rig._pivot(hp, Vector3(s * 0.06, -1.65, 0), "diz")
	var lb = MB.new()
	Loft.tube(lb, [Vector3(0, 0, 0), Vector3(0, -0.8, 0.02), Vector3(0, -1.5, 0)], [0.78, 0.68, 0.5], pc, 12, 3)
	# ayak: bileğe sargı + iri çıplak ayak
	lb.add("cyl", Vector3(0, -1.42, 0), Vector3(1.0, 0.28, 1.0), BANDAGE, Vector3.ZERO, 12)
	Loft.blob(lb, Vector3(0, -1.65, -0.35), Vector3(0, -0.1, -1), 1.3, [Vector2(0.28, 0.18), Vector2(0.42, 0.22), Vector2(0.4, 0.18), Vector2(0.25, 0.1)], _skin() if kind != 2 else BANDAGE, 10)
	_mi(kn, lb)
	legs.append({"hip": hp, "kn": kn, "side": s})


## Belde kalın mor ip (shimenawa) — üçünde de; Sargılı'da sırtta ve omuzlarda boğumlu kangallar
func _build_rope() -> void:
	var mb = MB.new()
	var wx = [1.42, 1.32, 1.68][kind]
	var wz = wx * 0.8
	var n = 28
	for k in n:   # örgü: iki iç içe burulmuş kalın halat — her biri boğum boğum küre zinciri (ref: kalın mor shimenawa)
		var a = k * TAU / n
		for st in 2:
			var tw = a * 6.0 + st * PI
			var c = Vector3(cos(a) * (wx + cos(tw) * 0.14), 0.2 + sin(tw) * 0.14, sin(a) * (wz + cos(tw) * 0.14) + 0.05)
			mb.add("sphere", c, Vector3(0.5, 0.42, 0.5), ROPE.lightened(0.07 * st), Vector3.ZERO, 8)
	# önde sarkan iki kalın düğüm ucu
	for s in [-1.0, 1.0]:
		Loft.tube(mb, [Vector3(s * 0.3, 0.1, -wz - 0.05), Vector3(s * 0.45, -0.7, -wz - 0.12), Vector3(s * 0.4, -1.4, -wz - 0.05)], [0.24, 0.22, 0.17], ROPE, 8, 3)
	_mi(hips, mb)
	if kind == 2:
		var cb = MB.new()
		# ref (Sargılı): kalın boğumlu mor ip kangalları sırttan omuzların üstünden aşırılıp göğsün önüne dökülür
		var path = func(x: float, q: float) -> Vector3:
			var back = Vector3(x, 2.2, 1.5)
			var top = Vector3(x * 1.15, 4.5, 0.2)
			var front = Vector3(x * 1.2, 2.6, -1.75)
			return back.lerp(top, q * 2.0) if q < 0.5 else top.lerp(front, (q - 0.5) * 2.0) + Vector3.UP * sin((q - 0.5) * PI) * 0.4
		for k in 4:
			var x = [-1.5, -0.6, 0.6, 1.5][k]
			var pts = []
			var rr = []
			for j in 9:
				pts.append(path.call(x, j / 8.0))
				rr.append(0.36)
			Loft.tube(cb, pts, rr, ROPE, 10, 3)
			for j in 10:   # boğumlar: ipi saran koyu halkalar
				var q = (j + 0.5) / 10.0
				var p0 = path.call(x, q)
				var p1 = path.call(x, minf(1.0, q + 0.02))
				var dd = (p1 - p0).normalized()
				var rot = Basis.looking_at(dd, Vector3.UP if absf(dd.y) < 0.95 else Vector3.FORWARD).get_euler() * (180.0 / PI)
				cb.add("torus", p0, Vector3(0.82, 0.22, 0.82), ROPE.darkened(0.18), rot + Vector3(90, 0, 0), 10)
		_mi(torso, cb)


## Gürzlü'nün dev gürzü (kanabō): gri, kalınlaşan gövde, delikli yüzey, sap sargılı — sağ elde, omza yaslı
func _build_club() -> void:
	weapon = Node3D.new()
	arms[1]["el"].add_child(weapon)   # sağ (s=+1) ön kol
	weapon.position = Vector3(0.55, -2.5, -0.45)
	weapon.rotation = Vector3(0.3, 0, -0.32)   # sap yumrukta, gövde yukarı: kol sarkıkken omzun önünden başın yanına yükselir
	var mb = MB.new()
	Loft.tube(mb, [Vector3(0, -0.6, 0), Vector3(0, 1.0, 0), Vector3(0, 3.5, 0), Vector3(0, 5.2, 0), Vector3(0, 5.6, 0)], [0.22, 0.28, 0.62, 0.72, 0.3], Color(0.5, 0.5, 0.52), 14, 4)
	var rng = RandomNumberGenerator.new()
	rng.seed = 3311
	for k in 22:   # yüzeydeki delikler (ref: koyu yuvarlak oyuklar)
		var y = rng.randf_range(1.6, 5.1)
		var a = rng.randf() * TAU
		var r = lerpf(0.4, 0.72, (y - 1.0) / 4.2)
		mb.add("sphere", Vector3(cos(a) * r, y, sin(a) * r), Vector3(0.2, 0.2, 0.08), Color(0.22, 0.22, 0.24), Vector3(0, -rad_to_deg(a) + 90, 0), 6)
	Loft.tube(mb, [Vector3(0, -0.6, 0), Vector3(0, 1.0, 0)], [0.25, 0.25], Color(0.35, 0.25, 0.18), 10, 2, true, true, _band_fn(Color(0.35, 0.25, 0.18), Color(0.2, 0.14, 0.1), 5.0))
	_mi(weapon, mb)


# ------------------------------------------------------------------ pozlar
func _pose(nm: String) -> Dictionary:
	match nm:
		"raise":   # vuruş kurulumu: sağ kol yukarı-arkaya, gövde geriye
			return {"hy": 3.2, "tx": 0.1, "hx": -0.2, "rax": -2.6, "raz": 0.3, "rex": -0.6, "lax": 0.2, "laz": 0.4, "lex": -0.6, "lx": 0.2, "kx": -0.3}
		"smash":   # yere indiriş: gövde öne çöker, sağ kol aşağı-ileri
			return {"hy": 2.4, "tx": -0.75, "hx": 0.5, "rax": -0.9, "raz": 0.15, "rex": -0.2, "lax": -0.3, "laz": 0.5, "lex": -0.9, "lx": 0.7, "kx": -1.1}
		"swipe":   # iki kolla yandan tırmık
			return {"hy": 2.9, "tx": -0.4, "hx": 0.3, "rax": -1.3, "raz": -0.6, "rex": -0.4, "lax": -1.3, "laz": -0.6, "lex": -0.4, "lx": 0.4, "kx": -0.6}
		"roar":   # ağız açık, baş kalkık (ruh solucanları)
			return {"hy": 3.1, "tx": -0.2, "hx": -0.5, "rax": 0.1, "raz": 0.7, "rex": -0.8, "lax": 0.1, "laz": 0.7, "lex": -0.8, "lx": 0.2, "kx": -0.3}
		_:   # stand: ref duruşu — kambur, baş omuzların arasında öne, dizler bükük geniş, dev kollar öne sarkık
			return {"hy": 2.95, "tx": -0.5, "hx": 0.55, "rax": 0.35, "raz": 0.12, "rex": -0.45, "lax": 0.35, "laz": 0.12, "lex": -0.45, "lx": 0.7, "kx": -0.9}


func _apply(p: Dictionary) -> void:
	hips.position.y = p["hy"]
	torso.rotation.x = p["tx"]
	head.rotation.x = p["hx"]
	for a in arms:
		var r = a["side"] > 0
		a["sh"].rotation = Vector3(p["rax"] if r else p["lax"], 0, a["side"] * (p["raz"] if r else p["laz"]))
		a["el"].rotation.x = p["rex"] if r else p["lex"]
	for l in legs:
		l["hip"].rotation = Vector3(-p["lx"] * 0.5, 0, l["side"] * 0.22)   # geniş duruş
		l["kn"].rotation.x = -p["kx"] * 0.9


func set_pose(nm: String, dur := 0.4) -> void:
	pose_from = _blend(pose_from, pose_to, pose_k) if not pose_to.is_empty() else _pose(nm)
	pose_to = _pose(nm)
	pose_dur = maxf(0.01, dur)
	pose_k = 0.0 if dur > 0.0 else 1.0
	if dur <= 0.0:
		_apply(pose_to)
	jaw_want = 1.0 if nm == "roar" else 0.0


func _blend(a: Dictionary, b: Dictionary, k: float) -> Dictionary:
	var o = {}
	var s = k * k * (3.0 - 2.0 * k)
	for key in b:
		o[key] = lerpf(float(a.get(key, b[key])), float(b[key]), s)
	return o


func _process(dt: float) -> void:
	t += dt
	if pose_k < 1.0:
		pose_k = minf(1.0, pose_k + dt / pose_dur)
	var p = _blend(pose_from, pose_to, pose_k) if pose_k < 1.0 else pose_to
	if p.is_empty():
		return
	_apply(p)
	torso.scale = Vector3.ONE * (1.0 + sin(t * 1.6 + kind) * 0.015)   # ağır nefes
	jaw_open = lerpf(jaw_open, jaw_want, minf(1.0, dt * 8.0))
	jaw.rotation.x = jaw_open * 0.6


func mouth_pos() -> Vector3:
	return jaw.global_position + jaw.global_transform.basis * Vector3(0, -0.1, -0.7)


func hand_pos(right := true) -> Vector3:
	var a = arms[1 if right else 0]
	return a["el"].global_transform * Vector3(0, -2.6, -0.2)


## Ruh solucanı (ref "Doki Attack": mor boğumlu, kalın kıvrık solucanlar): from'dan to'ya kıvrılarak uçar, değince patlar
static func spirit_worm(parent: Node, from: Vector3, to: Vector3, dur: float, on_hit: Callable) -> void:
	var w = Node3D.new()
	parent.add_child(w)
	var segs = []
	for k in 9:
		var mi = MeshInstance3D.new()
		var b = MB.new()
		var r = 0.38 * (1.0 - k * 0.07)
		b.add("sphere", Vector3.ZERO, Vector3(r * 2.0, r * 2.0, r * 1.6), ROPE, Vector3.ZERO, 10)
		b.add("torus", Vector3.ZERO, Vector3(r * 2.1, 0.12, r * 2.1), ROPE.darkened(0.25), Vector3(90, 0, 0), 10)
		mi.mesh = b.build(Props.toon())
		w.add_child(mi)
		segs.append(mi)
	var side = (to - from).cross(Vector3.UP).normalized() * randf_range(-3.0, 3.0)
	var tw = w.create_tween()
	tw.tween_method(func(q: float):
		for k in segs.size():
			var qq = clampf(q - k * 0.035, 0.0, 1.0)
			var p = from.lerp(to, qq) + Vector3.UP * sin(qq * PI) * 3.0 + side * sin(qq * PI) + Vector3(0, sin(qq * 18.0 + k) * 0.25, 0)
			(segs[k] as Node3D).global_position = p, 0.0, 1.3, dur)
	tw.tween_callback(func():
		on_hit.call(to)
		w.queue_free())
