class_name ClayArt
extends RefCounted
## Deidara'nın patlayıcı kil figürleri (anime referanslı): pürüzsüz, yuvarlak hatlı, sıcak kırık-beyaz kil.
## Küre/kutu yığını yok — gövdeler Loft tüpleri (yumuşak normaller), kanatlar yassı elips kesitli dirsekli tüpler.
## Modeller +Z ile kurulur, dönen düğüm Godot standardında -Z'ye bakar (look_at / mermi yönüyle uyumlu); kanatlılar kendi kendine çırpar.

const CLAY := Color(0.95, 0.95, 0.93)
const CLAY_SHADE := Color(0.74, 0.79, 0.8)   # karın / kanat altı: hafif koyu (hacim okunsun)
const EYE := Color(0.12, 0.11, 0.12)

static var _mat: ShaderMaterial


## Kil malzemesi: cel gölge + hafif yüzey dokusu (plastik gibi parlak değil, el ile yoğrulmuş kil)
static func mat() -> ShaderMaterial:
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = load("res://shaders/toon.gdshader")
		_mat.set_shader_parameter("tint", Color.WHITE)
		_mat.set_shader_parameter("use_vertex_color", true)
		_mat.set_shader_parameter("rim_amount", 0.25)
		_mat.set_shader_parameter("detail_noise", 0.12)
		var ol = ShaderMaterial.new()   # anime dış çizgisi (ters kabuk)
		ol.shader = load("res://shaders/clay_outline.gdshader")
		_mat.next_pass = ol
	return _mat


static func _mi(b: MB) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(mat())
	mi.material_override = mat()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi


## Karın tarafı hafif koyu boyama (alt yüzey): Loft col_fn
static func _belly(_t: float, ang: float, _sd) -> Color:
	return CLAY.lerp(CLAY_SHADE, clampf(-sin(ang), 0.0, 1.0))


static func _sc(arr: Array, s: float) -> Array:
	var out = []
	for v in arr:
		out.append(v * s)
	return out


## Tek kanat (sağ: +X). Pivot omuzda; kol → dirsek → uç, arka kenarda üç uzun tüy (tırtıklı siluet)
static func _wing(s: float, sx: float, span := 1.0) -> MeshInstance3D:
	var b = MB.new()
	var m = Vector3(sx, 1, 1)
	var pts = [Vector3(0.0, 0.0, 0.0), Vector3(0.32, 0.05, -0.03), Vector3(0.66, 0.07, -0.1), Vector3(0.95, 0.04, -0.24), Vector3(1.12, 0.0, -0.36)]
	var rad = [Vector2(0.16, 0.045), Vector2(0.19, 0.04), Vector2(0.15, 0.032), Vector2(0.09, 0.022), Vector2(0.025, 0.012)]
	var P = []
	for p in pts:
		P.append(p * m * Vector3(span, 1, 1) * s)
	Loft.tube(b, P, _sc(rad, s), CLAY, 14, 4, true, true, _belly)
	# arka kenar tüyleri: kanat altından geriye ve dışa uzanan yassı uçlar
	for k in 4:
		var root = Vector3(0.38 + k * 0.17, 0.045 - k * 0.008, -0.08 - k * 0.05) * m * Vector3(span, 1, 1)
		var tip = root + Vector3((0.05 + k * 0.05) * sx, -0.005, -0.2 - k * 0.03)
		Loft.tube(b, [root * s, root.lerp(tip, 0.55) * s, tip * s], [Vector2(0.1, 0.018) * s, Vector2(0.085, 0.015) * s, Vector2(0.035, 0.01) * s], CLAY, 10, 3, true, true, _belly)
	return _mi(b)


## Kil kuş (C1 kuşu / Kibaku Nendo / C4 binek kuşu): ince uzun gövde, gaga, küçük koyu gözler, dirsekli kanatlar, yelpaze kuyruk
static func bird(s := 1.0, flap_speed := 1.0) -> Node3D:
	var root = Node3D.new()
	var b = MB.new()
	var pts = [Vector3(0, 0.03, 0.66), Vector3(0, 0.05, 0.56), Vector3(0, 0.07, 0.45), Vector3(0, 0.04, 0.32), Vector3(0, 0.0, 0.12), Vector3(0, 0.0, -0.12), Vector3(0, 0.02, -0.34), Vector3(0, 0.03, -0.46)]
	var rad = [Vector2(0.012, 0.012), Vector2(0.05, 0.045), Vector2(0.115, 0.115), Vector2(0.1, 0.1), Vector2(0.17, 0.16), Vector2(0.15, 0.14), Vector2(0.08, 0.065), Vector2(0.035, 0.025)]
	Loft.tube(b, _sc(pts, s), _sc(rad, s), CLAY, 18, 4, true, true, _belly)
	# yelpaze kuyruk: üç yassı tüy
	for k in 3:
		var a = (k - 1) * 0.35
		var r0 = Vector3(0, 0.03, -0.4)
		var tip = r0 + Vector3(sin(a) * 0.3, 0.01, -cos(a) * 0.38)
		Loft.tube(b, [r0 * s, r0.lerp(tip, 0.5) * s, tip * s], [Vector2(0.05, 0.014) * s, Vector2(0.075, 0.014) * s, Vector2(0.03, 0.01) * s], CLAY, 10, 3, true, true, _belly)
	# gözler: küçük koyu noktalar
	for sx in [-1.0, 1.0]:
		b.add("sphere", Vector3(sx * 0.085, 0.11, 0.48) * s, Vector3.ONE * 0.045 * s, EYE, Vector3.ZERO, 12)
	root.add_child(_mi(b))
	for sx in [-1.0, 1.0]:
		var piv = Node3D.new()
		piv.position = Vector3(sx * 0.1, 0.06, 0.12) * s
		piv.add_child(_wing(s, sx))
		root.add_child(piv)
		_flap(piv, sx, flap_speed)
	return _fwd(root)


static func _fwd(inner: Node3D) -> Node3D:
	var root = Node3D.new()
	inner.rotation.y = PI
	root.add_child(inner)
	return root


static func _flap(piv: Node3D, sx: float, speed: float) -> void:
	piv.rotation.z = sx * -0.35
	var tw = piv.create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(piv, "rotation:z", sx * 0.55, 0.22 / speed)
	tw.tween_property(piv, "rotation:z", sx * -0.4, 0.28 / speed)


## C2 ejderhası (anime referansı: _tmp/ref/c2 — C2 Dragon / C2 Guided Missile / C2 Mines): iri şişkin gövde, kalın uzun boyun
## (öne uzanıp aşağı kavis yapar), geniş küt su aygırı kafası + aşağı eğik kutu burun ve ucunda sivri gaga, üst dudaktan
## sarkan kare dişler (kale burcu çizgisi), yanda yuvarlak kara göz deliği, burun üstünde iki delik; kafada ve boyun boyunca
## çift çift ucu kesik kalın boynuz kütükleri; insan eli gibi dört parmaklı kalın bacaklar aşağı sarkar; geniş kılıç
## kanatlar (ön kenarda yumrular, arka kenarda yuvarlak uçlu tüy lobları) + arkada küçük ikinci çift; gövde kalınlığında,
## halka halka boğumlu çok uzun kıvrılan kuyruk. s=1: burun ucu +4.2, sırt üstü y≈0.7 (binici omuzların üstünde durur)
static func c2_dragon(s := 1.0) -> Node3D:
	var root = Node3D.new()
	var b = MB.new()
	# kafatası → boyun (yukarı kavis) → omuz → şişkin gövde → kalça
	var pts = [Vector3(0, 0.02, 3.42), Vector3(0, 0.2, 3.12), Vector3(0, 0.4, 2.75), Vector3(0, 0.52, 2.25), Vector3(0, 0.42, 1.7),
		Vector3(0, 0.16, 1.25), Vector3(0, 0.0, 0.6), Vector3(0, -0.04, -0.2), Vector3(0, 0.0, -1.0), Vector3(0, 0.06, -1.6)]
	var rad = [Vector2(0.5, 0.38), Vector2(0.58, 0.47), Vector2(0.42, 0.4), Vector2(0.4, 0.38), Vector2(0.46, 0.44),
		Vector2(0.74, 0.66), Vector2(1.06, 0.88), Vector2(1.14, 0.94), Vector2(1.0, 0.84), Vector2(0.7, 0.64)]
	Loft.tube(b, _sc(pts, s), _sc(rad, s), CLAY, 24, 4, true, true, _belly)
	# burun: köşeleri yuvarlak kutu kesitli, geniş ve küt; öne doğru aşağı eğilir
	var sn = [Vector3(0, 0.1, 3.15), Vector3(0, 0.02, 3.45), Vector3(0, -0.1, 3.75), Vector3(0, -0.22, 4.0), Vector3(0, -0.3, 4.12)]
	var sh = [Vector2(0.55, 0.38), Vector2(0.52, 0.34), Vector2(0.47, 0.3), Vector2(0.41, 0.26), Vector2(0.3, 0.18)]
	_sbox_loft(b, _sc(sn, s), _sc(sh, s), 2.6, 28)
	# burnun ucundan aşağı sarkan sivri gaga
	Loft.tube(b, _sc([Vector3(0, -0.34, 4.1), Vector3(0, -0.5, 4.2), Vector3(0, -0.72, 4.24)], s), _sc([Vector2(0.17, 0.13), Vector2(0.11, 0.09), Vector2(0.03, 0.03)], s), CLAY, 12, 3, true, true, _belly)
	for sx in [-1.0, 1.0]:
		# yuvarlak kara göz deliği (açık renk çukur kenarıyla), kafatası ile burnun birleştiği yerde yanda
		b.add("sphere", Vector3(sx * 0.52, 0.2, 3.3) * s, Vector3(0.1, 0.26, 0.26) * s, CLAY_SHADE, Vector3.ZERO, 16)
		b.add("sphere", Vector3(sx * 0.55, 0.2, 3.3) * s, Vector3(0.08, 0.17, 0.17) * s, EYE, Vector3.ZERO, 16)
		# burun delikleri (uçta, üst yüzde)
		b.add("sphere", Vector3(sx * 0.13, -0.03, 4.02) * s, Vector3(0.09, 0.05, 0.09) * s, EYE, Vector3.ZERO, 10)
		# üst dudaktan sarkan kare dişler: burnun yanında kale burcu gibi ince koyu çizgi
		var ml = []
		var mr = []
		var z = 4.02
		var up = false
		while z > 3.2:
			var t0 = clampf((4.05 - z) / 0.9, 0.0, 1.0)
			var hw = lerpf(0.41, 0.55, t0) + 0.012
			var y = lerpf(-0.3, 0.01, t0) + (0.085 if up else 0.0)
			ml.append(Vector3(sx * hw, y, z) * s)
			z -= 0.1
			ml.append(Vector3(sx * (hw + 0.012), y + 0.034, z) * s)
			up = not up
		for q in ml.size():
			mr.append(Vector2(0.013, 0.013) * s)
		Loft.tube(b, ml, mr, EYE, 6, 1, true, true)
		# ucu kesik kalın boynuz kütükleri: kafada bir çift (iri), boyun boyunca iki çift (küçülerek)
		for hk in [[Vector3(0.24, 0.56, 3.02), 0.5, 0.135], [Vector3(0.22, 0.72, 2.45), 0.34, 0.11], [Vector3(0.26, 0.74, 1.8), 0.3, 0.1]]:
			var h0: Vector3 = hk[0] * Vector3(sx, 1, 1)
			var h1 = h0 + Vector3(sx * 0.55, 0.8, -0.3).normalized() * float(hk[1])
			var hr = float(hk[2])
			Loft.tube(b, _sc([h0 - (h1 - h0) * 0.3, h0, h1], s), _sc([Vector2(hr * 1.15, hr * 1.15), Vector2(hr * 1.05, hr * 1.05), Vector2(hr, hr)], s), CLAY, 14, 2, false, false, _belly)
			b.add("sphere", h1 * s, Vector3(hr * 2.0, hr * 0.5, hr * 2.0) * s, CLAY_SHADE.lerp(CLAY, 0.4), Vector3(-20, 0, -sx * 18), 12)   # kesik uç
	root.add_child(_mi(b))
	# boğumlu kuyruk: gövde kalınlığında üst üste binen halkalar; geriye uzanır, aşağı sarkıp yana doğru kıvrılır
	var tail = Node3D.new()
	tail.position = Vector3(0, 0.04, -1.5) * s
	var tb = MB.new()
	var p = Vector3.ZERO
	var r = 0.62
	var ang = 0.0
	for k in 32:
		ang += 0.03 + k * 0.0085
		var pitch = -0.42 * sin(minf(k / 12.0, 1.0) * PI)   # önce aşağı sarkar, sonra düzleşir
		p += Vector3(sin(ang), pitch, -cos(ang)) * r * 0.82
		tb.add("sphere", p * s, Vector3(r * 2.15, r * 2.0, r * 1.35) * s, CLAY if k % 2 == 0 else CLAY_SHADE.lerp(CLAY, 0.55), Vector3(0, -rad_to_deg(ang), 0), 16)
		r *= 0.972
	tail.add_child(_mi(tb))
	root.add_child(tail)
	var tw = tail.create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tail.rotation.y = -0.16
	tw.tween_property(tail, "rotation:y", 0.16, 1.6)
	tw.tween_property(tail, "rotation:y", -0.16, 1.6)
	# insan eli gibi parmaklı dört kalın bacak: gövdenin altından aşağı sarkar, hafifçe geriye toplanıp yavaşça salınır
	var i = 0
	for sx in [-1.0, 1.0]:
		for fz in [0.8, -1.0]:
			var leg = _c2_leg(s, sx)
			leg.position = Vector3(sx * 0.74, -0.38, fz) * s
			root.add_child(leg)
			var tuck = 0.2 if fz > 0.0 else 0.42
			leg.rotation = Vector3(tuck, 0, sx * -0.1)
			var tl = leg.create_tween().set_loops()
			tl.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tl.tween_interval(0.12 * i)
			tl.tween_property(leg, "rotation:x", tuck + 0.14, 1.3)
			tl.tween_property(leg, "rotation:x", tuck - 0.06, 1.3)
			i += 1
	# gövde kanat çırpışıyla hafifçe iner kalkar, burnu hafif yukarı aşağı
	var bob = root.create_tween().set_loops()
	bob.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(root, "position:y", 0.12 * s, 0.9)
	bob.parallel().tween_property(root, "rotation:x", -0.04, 0.9)
	bob.tween_property(root, "position:y", -0.08 * s, 1.1)
	bob.parallel().tween_property(root, "rotation:x", 0.03, 1.1)
	# kanatlar: omuzda büyük çift, kalçaya doğru küçük ikinci çift
	for wk in [[Vector3(0.6, 0.62, 0.7), 1.0], [Vector3(0.6, 0.6, -0.75), 0.5]]:
		for sx in [-1.0, 1.0]:
			var piv = Node3D.new()
			piv.position = (wk[0] as Vector3) * Vector3(sx, 1, 1) * s
			piv.add_child(_c2_wing(s * float(wk[1]), sx))
			root.add_child(piv)
			_glide(piv, sx)
	return _fwd(root)


## Büyük kanat süzülüşü: geniş, yavaş çırpış (aşağı vuruş güçlü/kısa, yukarı kalkış yavaş), arada kısa süzülme
static func _glide(piv: Node3D, sx: float) -> void:
	piv.rotation.z = sx * 0.1
	var tw = piv.create_tween().set_loops()
	tw.tween_property(piv, "rotation:z", sx * -0.42, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(piv, "rotation:z", sx * 0.5, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(piv, "rotation:z", sx * 0.1, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Süperelips kesitli loft (köşeleri yuvarlatılmış dikdörtgen tüp): pts Z boyunca, half = (yarı genişlik, yarı yükseklik), n=2 elips, n büyüdükçe köşeli
static func _sbox_loft(b: MB, pts: Array, half: Array, n := 4.0, seg := 24) -> void:
	var rings = []
	for i in pts.size():
		var ring = []
		for j in seg + 1:
			var a = TAU * j / seg
			var c = cos(a)
			var sn = sin(a)
			var ex = 2.0 / n
			var x = signf(c) * pow(absf(c), ex) * half[i].x
			var y = signf(sn) * pow(absf(sn), ex) * half[i].y
			# süperelips gradyanı = yüzey normali
			var gx = signf(x) * pow(absf(x / half[i].x) + 1e-5, n - 1.0) / half[i].x
			var gy = signf(y) * pow(absf(y / half[i].y) + 1e-5, n - 1.0) / half[i].y
			ring.append([pts[i] + Vector3(x, y, 0), Vector3(gx, gy, 0).normalized()])
		rings.append(ring)
	var cols = []
	for i in pts.size():
		var rc = []
		for j in seg + 1:
			var ny: float = rings[i][j][1].y
			rc.append(CLAY.lerp(CLAY_SHADE, clampf(-ny, 0.0, 1.0)))
		cols.append(rc)
	var base = b.verts.size()
	for i in pts.size():
		for j in seg + 1:
			b.verts.append(rings[i][j][0])
			b.normals.append(rings[i][j][1])
			b.colors.append(cols[i][j])
			b.uvs.append(Vector2.ZERO)
	for i in pts.size() - 1:
		for j in seg:
			var i0 = base + i * (seg + 1) + j
			var i1 = i0 + 1
			var i2 = i0 + seg + 1
			var i3 = i2 + 1
			var p0 = b.verts[i0]
			var nrm = b.normals[i0]
			var geo = (b.verts[i2] - p0).cross(b.verts[i1] - p0)
			if geo.dot(nrm) > 0.0:
				b.idx.append_array([i0, i1, i2, i1, i3, i2])
			else:
				b.idx.append_array([i0, i2, i1, i1, i2, i3])
	# uç kapağı (öne bakan yelpaze)
	var last = pts.size() - 1
	var ci = b.verts.size()
	b.verts.append(pts[last] + Vector3(0, 0, half[last].y * 0.4))
	b.normals.append(Vector3.FORWARD * -1.0)
	b.colors.append(CLAY)
	b.uvs.append(Vector2.ZERO)
	for j in seg:
		var k0 = base + last * (seg + 1) + j
		var k1 = k0 + 1
		var geo = (b.verts[k0] - b.verts[ci]).cross(b.verts[k1] - b.verts[ci])
		if geo.dot(Vector3.BACK) > 0.0:
			b.idx.append_array([ci, k1, k0])
		else:
			b.idx.append_array([ci, k0, k1])


## C2 bacağı (sağ: +X): kalın üst kol dışa-aşağı, dirsek, ön kol, geniş avuç ve dört uzun yuvarlak uçlu parmak (aşağı-öne açık)
static func _c2_leg(s: float, sx: float) -> Node3D:
	var b = MB.new()
	var m = Vector3(sx, 1, 1)
	var sh = Vector3.ZERO
	var el = Vector3(0.3, -0.5, -0.1) * m
	var wr = Vector3(0.34, -1.05, 0.14) * m
	Loft.tube(b, _sc([sh, el, wr], s), _sc([Vector2(0.36, 0.36), Vector2(0.27, 0.27), Vector2(0.22, 0.2)], s), CLAY, 14, 4, true, true, _belly)
	b.add("sphere", wr * s + Vector3(0, -0.1, 0.06) * s, Vector3(0.5, 0.3, 0.46) * s, CLAY, Vector3.ZERO, 14)   # avuç
	for q in 4:
		var a = (q - 1.5) * 0.4
		var k0 = wr + Vector3(sin(a) * 0.17, -0.14, 0.1 + cos(a) * 0.12)
		var k1 = k0 + Vector3(sin(a) * 0.12, -0.2, cos(a) * 0.2)
		var k2 = k1 + Vector3(sin(a) * 0.05, -0.24, cos(a) * 0.1)
		Loft.tube(b, _sc([k0, k1, k2], s), _sc([Vector2(0.1, 0.095), Vector2(0.09, 0.085), Vector2(0.08, 0.075)], s), CLAY, 10, 3, true, true, _belly)
	var piv = Node3D.new()
	piv.add_child(_mi(b))
	return piv


## C2 kanadı (sağ: +X): geniş, yassı, geriye süpürülüp sivrilen kılıç kanat; ön kenarda kalın kol + köke yakın yumrular,
## arka kenarın iç yarısında birbirine binen yuvarlak uçlu kalın tüy lobları (anime: parmak gibi sarkan tüyler)
static func _c2_wing(s: float, sx: float) -> MeshInstance3D:
	var b = MB.new()
	var m = Vector3(sx, 1, 1)
	var spar = [Vector3(0, 0, 0), Vector3(1.0, 0.22, -0.05), Vector3(2.1, 0.32, -0.4), Vector3(3.3, 0.26, -1.0), Vector3(4.3, 0.1, -1.8)]
	var chord = [1.35, 1.5, 1.25, 0.75, 0.05]
	var S = []
	var B = []
	var BR = []
	for q in spar.size():
		S.append(spar[q] * m * s)
		B.append((spar[q] + Vector3(0, -0.04, -chord[q] * 0.5)) * m * s)
		BR.append(Vector2(maxf(chord[q] * 0.5, 0.02), 0.045 if q < 4 else 0.015) * s)
	Loft.tube(b, B, BR, CLAY, 14, 4, true, true, _belly)   # kanat yüzeyi
	Loft.tube(b, S, _sc([Vector2(0.2, 0.17), Vector2(0.17, 0.14), Vector2(0.13, 0.11), Vector2(0.08, 0.07), Vector2(0.03, 0.03)], s), CLAY, 12, 4, true, true, _belly)   # ön kenar kolu
	for q in 4:   # köke yakın yumrular (ön kenarın üstünde)
		var kp = _along(spar, 0.08 + q * 0.085) * m + Vector3(0, 0.12, 0.02)
		b.add("sphere", kp * s, Vector3(0.2, 0.15, 0.2) * s * (1.0 - q * 0.1), CLAY, Vector3.ZERO, 12)
	for q in 8:   # arka kenar tüy lobları
		var t = 0.04 + q * 0.09
		var f = t * (spar.size() - 1)
		var ci = mini(int(f), spar.size() - 2)
		var ch = lerpf(chord[ci], chord[ci + 1], f - ci)
		var r0 = (_along(spar, t) + Vector3(0, -0.07, -ch * 0.8)) * m
		var L = 0.62 + 0.14 * sin(q * 1.9)
		var tip = r0 + Vector3(sx * (0.06 + q * 0.03), -0.05, -L)
		Loft.tube(b, [r0 * s, r0.lerp(tip, 0.55) * s, tip * s], [Vector2(0.21, 0.07) * s, Vector2(0.22, 0.07) * s, Vector2(0.16, 0.06) * s], CLAY if q % 2 == 0 else CLAY_SHADE.lerp(CLAY, 0.45), 10, 3, true, true, _belly)
	return _mi(b)


static func _along(pts: Array, t: float) -> Vector3:
	var f = t * (pts.size() - 1)
	var i = mini(int(f), pts.size() - 2)
	return pts[i].lerp(pts[i + 1], f - i)


## C1 örümcek: yuvarlak gövde + baş, dizden kırık sekiz ince bacak
static func spider(s := 1.0) -> Node3D:
	var root = Node3D.new()
	var b = MB.new()
	Loft.tube(b, _sc([Vector3(0, 0.12, 0.3), Vector3(0, 0.14, 0.12), Vector3(0, 0.16, -0.12), Vector3(0, 0.14, -0.38)], s), _sc([Vector2(0.1, 0.09), Vector2(0.15, 0.12), Vector2(0.24, 0.2), Vector2(0.12, 0.1)], s), CLAY, 16, 4, true, true, _belly)
	for sx in [-1.0, 1.0]:
		b.add("sphere", Vector3(sx * 0.05, 0.2, 0.36) * s, Vector3.ONE * 0.035 * s, EYE, Vector3.ZERO, 10)
		for q in 4:
			var a = Vector3(sx * 0.1, 0.13, 0.15 - q * 0.1)
			var kn = a + Vector3(sx * 0.22, 0.16, 0.08 - q * 0.04)
			var f = kn + Vector3(sx * 0.16, -0.3, 0.05 - q * 0.05)
			Loft.tube(b, [a * s, kn * s, f * s], [Vector2(0.03, 0.03) * s, Vector2(0.026, 0.026) * s, Vector2(0.012, 0.012) * s], CLAY, 8, 3, true, true, _belly)
	root.add_child(_mi(b))
	return _fwd(root)


## Ningyō Kibaku Nendo: küçük kil bebek (yuvarlak baş, nokta gözler, tombul gövde, kısa kol/bacak)
static func doll(s := 1.0) -> Node3D:
	var root = Node3D.new()
	var b = MB.new()
	Loft.tube(b, _sc([Vector3(0, 0.12, 0), Vector3(0, 0.3, 0), Vector3(0, 0.48, 0), Vector3(0, 0.56, 0)], s), _sc([Vector2(0.12, 0.1), Vector2(0.17, 0.15), Vector2(0.14, 0.12), Vector2(0.09, 0.08)], s), CLAY, 16, 4, true, true, Callable(), Vector3.FORWARD)
	b.add("sphere", Vector3(0, 0.74, 0) * s, Vector3.ONE * 0.36 * s, CLAY, Vector3.ZERO, 18)
	for sx in [-1.0, 1.0]:
		b.add("sphere", Vector3(sx * 0.07, 0.77, 0.16) * s, Vector3(0.04, 0.055, 0.03) * s, EYE, Vector3.ZERO, 10)
		var sh = Vector3(sx * 0.13, 0.46, 0)
		Loft.tube(b, [sh * s, (sh + Vector3(sx * 0.12, -0.12, 0.05)) * s, (sh + Vector3(sx * 0.16, -0.26, 0.08)) * s], [Vector2(0.05, 0.05) * s, Vector2(0.045, 0.045) * s, Vector2(0.05, 0.05) * s], CLAY, 10, 3, true, true)
		var hp = Vector3(sx * 0.08, 0.14, 0)
		Loft.tube(b, [hp * s, (hp + Vector3(sx * 0.02, -0.08, 0)) * s, (hp + Vector3(sx * 0.02, -0.14, 0.04)) * s], [Vector2(0.06, 0.06) * s, Vector2(0.055, 0.055) * s, Vector2(0.06, 0.05) * s], CLAY, 10, 3, true, true)
	root.add_child(_mi(b))
	return _fwd(root)


## Kibaku Jirai mayını (anime): C2'nin ağzından saçılan yuvarlak kil top, önünde iki kara göz deliği
static func mine(s := 1.0) -> Node3D:
	var root = Node3D.new()
	var b = MB.new()
	b.add("sphere", Vector3.ZERO, Vector3(1.0, 0.92, 1.0) * s, CLAY, Vector3.ZERO, 20)
	for sx in [-1.0, 1.0]:
		b.add("sphere", Vector3(sx * 0.17, 0.1, 0.43) * s, Vector3(0.14, 0.17, 0.08) * s, EYE, Vector3.ZERO, 10)
	b.add("sphere", Vector3(0, -0.14, 0.45) * s, Vector3(0.1, 0.05, 0.05) * s, EYE, Vector3.ZERO, 8)
	root.add_child(_mi(b))
	return _fwd(root)


## C3 (anime): dev tombul kil heykel — iri yuvarlak gövde-kafa, önde geniş ağız çizgisi ve sarkan kare dişler,
## üstte kara göz delikleri, kulak yumruları, kısa kalın bacaklar. s=1: ~3.5 m
static func c3(s := 1.0) -> Node3D:
	var root = Node3D.new()
	var b = MB.new()
	Loft.tube(b, _sc([Vector3(0, 0.95, -1.15), Vector3(0, 1.05, -0.55), Vector3(0, 1.1, 0.15), Vector3(0, 1.05, 0.8), Vector3(0, 0.92, 1.28), Vector3(0, 0.86, 1.52)], s),
		_sc([Vector2(0.65, 0.6), Vector2(1.0, 0.95), Vector2(1.08, 1.02), Vector2(0.98, 0.88), Vector2(0.76, 0.6), Vector2(0.42, 0.32)], s), CLAY, 24, 3, true, true, _belly)
	# ağız çizgisi: burnun altından iki yana kıvrılan kontur, altında sarkan kare dişler
	var ml = []
	var rr = []
	for q in 9:
		var a = (q - 4) * 0.28
		ml.append(Vector3(sin(a) * 0.86, 0.62 + absf(a) * 0.12, 1.12 + cos(a) * 0.32) * s)
		rr.append(Vector2(0.03, 0.03) * s)
	Loft.tube(b, ml, rr, EYE, 6, 2, true, true)
	for q in 7:
		var a = (q - 3) * 0.3
		b.add("box", Vector3(sin(a) * 0.86, 0.5 + absf(a) * 0.12, 1.12 + cos(a) * 0.33) * s, Vector3(0.16, 0.22, 0.12) * s, CLAY_SHADE, Vector3(0, rad_to_deg(a), 0))
	for sx in [-1.0, 1.0]:
		b.add("sphere", Vector3(sx * 0.42, 1.45, 1.05) * s, Vector3(0.26, 0.3, 0.16) * s, EYE, Vector3(0, sx * 25.0, 0), 12)
		b.add("sphere", Vector3(sx * 0.13, 1.02, 1.62) * s, Vector3(0.09, 0.08, 0.06) * s, EYE, Vector3.ZERO, 8)
		b.add("sphere", Vector3(sx * 0.62, 1.95, 0.35) * s, Vector3(0.5, 0.42, 0.45) * s, CLAY, Vector3.ZERO, 14)
		for fz in [0.75, -0.65]:
			var a0 = Vector3(sx * 0.72, 0.7, fz)
			Loft.tube(b, _sc([a0, a0 + Vector3(sx * 0.12, -0.42, 0.05), a0 + Vector3(sx * 0.16, -0.68, 0.14)], s), _sc([Vector2(0.38, 0.38), Vector2(0.32, 0.32), Vector2(0.34, 0.26)], s), CLAY, 14, 3, true, true, _belly)
	# kısa kalın kuyruk
	Loft.tube(b, _sc([Vector3(0, 0.9, -1.4), Vector3(0, 0.75, -1.85), Vector3(0, 0.5, -2.1)], s), _sc([Vector2(0.3, 0.3), Vector2(0.2, 0.2), Vector2(0.1, 0.1)], s), CLAY, 12, 3, true, true, _belly)
	root.add_child(_mi(b))
	return _fwd(root)


## C3 patlaması (anime): koyu benekli dev turuncu küre hızla şişer, ekvatorunda beyaz halka; tabanını kalın
## beyaz-gri karnabahar duman halkası sarar; sonra küre söner, duman ve moloz kalır. R: küre yarıçapı (m)
static func c3_blast(pos: Vector3, R := 12.0) -> void:
	var scene = (Engine.get_main_loop() as SceneTree).current_scene
	var orb = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 1.0; sm.height = 2.0; sm.radial_segments = 40; sm.rings = 20
	orb.mesh = sm
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/clay_orb.gdshader")
	orb.material_override = m
	orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scene.add_child(orb)
	orb.global_position = pos + Vector3.UP * R * 0.35
	orb.scale = Vector3.ONE * 0.5
	var tw = orb.create_tween()
	tw.tween_property(orb, "scale", Vector3.ONE * R, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(orb, "scale", Vector3.ONE * R * 1.08, 0.6)
	tw.tween_method(func(a: float): m.set_shader_parameter("alpha", a), 1.0, 0.0, 0.5)
	tw.tween_callback(orb.queue_free)
	FX.light(pos, Color(1.0, 0.7, 0.3), 30.0, R * 5.0, 1.2)
	# taban duman halkası: kürenin ekvatoru çevresinde dışa yuvarlanan beyaz-gri topaklar
	var ring_y = pos.y - R * 0.15
	for k in 3:
		VFX.puffs(Vector3(pos.x, ring_y, pos.z), {"amount": 60, "life": 2.6 + k * 0.4, "size": R * 0.32, "radius": R * (0.85 + k * 0.12), "vmin": R * 0.15, "vmax": R * 0.45, "dir": Vector3.UP, "spread": 100.0, "damp": 1.6, "gravity": Vector3(0, 0.4, 0),
			"rough": 0.22, "outline": 0.035, "outline_col": Color(0.3, 0.29, 0.3), "shade": 0.3,
			"colors": [Color(0.66, 0.65, 0.65, 0.0), Color(0.66, 0.65, 0.65, 1), Color(0.52, 0.51, 0.52, 0.9), Color(0.42, 0.41, 0.42, 0.0)]})
	VFX.clay_blast(pos, R * 0.45)
	VFX.debris(pos, Color(0.42, 0.33, 0.24), 50, R * 1.8, 1.0)


## Kil topak / mayın: pürüzsüz, hafif basık (köşeli küre değil)
static func lump(s := 1.0) -> Node3D:
	var root = Node3D.new()
	var b = MB.new()
	b.add("sphere", Vector3.ZERO, Vector3(1.0, 0.8, 1.0) * s, CLAY, Vector3.ZERO, 20)
	b.add("sphere", Vector3(0.18, 0.22, 0.1) * s, Vector3.ONE * 0.45 * s, CLAY, Vector3.ZERO, 14)
	root.add_child(_mi(b))
	return _fwd(root)
