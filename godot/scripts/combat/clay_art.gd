class_name ClayArt
extends RefCounted
## Deidara'nın patlayıcı kil figürleri (anime referanslı): pürüzsüz, yuvarlak hatlı, sıcak kırık-beyaz kil.
## Küre/kutu yığını yok — gövdeler Loft tüpleri (yumuşak normaller), kanatlar yassı elips kesitli dirsekli tüpler.
## Modeller +Z ile kurulur, dönen düğüm Godot standardında -Z'ye bakar (look_at / mermi yönüyle uyumlu); kanatlılar kendi kendine çırpar.

const CLAY := Color(0.94, 0.92, 0.86)
const CLAY_SHADE := Color(0.86, 0.84, 0.78)   # karın / kanat altı: hafif koyu (hacim okunsun)
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


## C2 ejderhası (anime): kalın kertenkele gövde, büyük baş + koyu göz/burun delikleri, arkaya kıvrık iki boynuz,
## dört kısa pençeli bacak, halka halka boğumlu uzun kuyruk, sırtta yavaş çırpan büyük kanatlar. s=1: ~6 m boy
static func c2_dragon(s := 1.0) -> Node3D:
	var root = Node3D.new()
	var b = MB.new()
	var pts = [Vector3(0, 0.15, 2.45), Vector3(0, 0.3, 2.15), Vector3(0, 0.38, 1.75), Vector3(0, 0.28, 1.3), Vector3(0, 0.1, 0.75), Vector3(0, 0.0, 0.1), Vector3(0, 0.02, -0.6), Vector3(0, 0.08, -1.1)]
	var rad = [Vector2(0.2, 0.14), Vector2(0.42, 0.3), Vector2(0.5, 0.44), Vector2(0.38, 0.36), Vector2(0.62, 0.55), Vector2(0.72, 0.62), Vector2(0.6, 0.52), Vector2(0.42, 0.38)]
	# boğumlu kuyruk: kalın/ince sırayla halkalar, sonda ince uç
	var z = -1.1
	var r = 0.4
	var k = 0
	while r > 0.06:
		z -= 0.24
		k += 1
		pts.append(Vector3(sin(k * 0.35) * 0.25, 0.08 + k * 0.012, z))
		rad.append(Vector2.ONE * (r if k % 2 == 1 else r * 0.8))
		r *= 0.92
	Loft.tube(b, _sc(pts, s), _sc(rad, s), CLAY, 20, 3, true, true, _belly)
	# göz ve burun delikleri
	for sx in [-1.0, 1.0]:
		b.add("sphere", Vector3(sx * 0.33, 0.5, 2.02) * s, Vector3(0.2, 0.16, 0.18) * s, EYE, Vector3.ZERO, 14)
		b.add("sphere", Vector3(sx * 0.08, 0.24, 2.42) * s, Vector3(0.06, 0.05, 0.05) * s, EYE, Vector3.ZERO, 10)
		# başın üstünden arkaya kıvrılan boynuz
		var h0 = Vector3(sx * 0.22, 0.7, 1.7)
		Loft.tube(b, [h0 * s, (h0 + Vector3(sx * 0.12, 0.35, -0.25)) * s, (h0 + Vector3(sx * 0.2, 0.5, -0.65)) * s], [Vector2(0.12, 0.12) * s, Vector2(0.09, 0.09) * s, Vector2(0.03, 0.03) * s], CLAY, 12, 4, true, true, _belly)
		# bacaklar: omuz → dirsek → pençe (üç parmak)
		for fz in [0.6, -0.7]:
			var a = Vector3(sx * 0.55, -0.05, fz)
			var e = a + Vector3(sx * 0.35, -0.45, 0.05)
			var f = e + Vector3(sx * 0.05, -0.4, 0.15)
			Loft.tube(b, [a * s, e * s, f * s], [Vector2(0.24, 0.24) * s, Vector2(0.17, 0.17) * s, Vector2(0.15, 0.12) * s], CLAY, 12, 3, true, true, _belly)
			for q in 3:
				var t0 = f + Vector3((q - 1) * 0.1, -0.02, 0.05)
				Loft.tube(b, [t0 * s, (t0 + Vector3((q - 1) * 0.08, -0.04, 0.22)) * s], [Vector2(0.06, 0.05) * s, Vector2(0.035, 0.03) * s], CLAY, 8, 2, true, true, _belly)
	root.add_child(_mi(b))
	for sx in [-1.0, 1.0]:
		var piv = Node3D.new()
		piv.position = Vector3(sx * 0.35, 0.55, 0.45) * s
		piv.add_child(_wing(s * 2.6, sx))
		root.add_child(piv)
		_flap(piv, sx, 0.45)
	return _fwd(root)


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


## Kil topak / mayın: pürüzsüz, hafif basık (köşeli küre değil)
static func lump(s := 1.0) -> Node3D:
	var root = Node3D.new()
	var b = MB.new()
	b.add("sphere", Vector3.ZERO, Vector3(1.0, 0.8, 1.0) * s, CLAY, Vector3.ZERO, 20)
	b.add("sphere", Vector3(0.18, 0.22, 0.1) * s, Vector3.ONE * 0.45 * s, CLAY, Vector3.ZERO, 14)
	root.add_child(_mi(b))
	return _fwd(root)
