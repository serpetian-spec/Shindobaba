class_name RantonArt
extends RefCounted
## Ranton ışık figürleri: iki katmanlı parlak gövde — mavi yarı saydam dış kabuk + içte daha ince beyaz-sıcak çekirdek.
## Gövdeler Loft tüpleri (yumuşak siluet); kutu/küre yığını yok. Figürler -Z'ye bakar (ClayArt._fwd).

const SHELL := Color(0.3, 0.58, 1.0, 0.55)
const CORE := Color(0.92, 0.97, 1.0, 0.9)

static var _shell_mat: StandardMaterial3D
static var _core_mat: StandardMaterial3D


static func _glow(c: Color, add := true) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if add else BaseMaterial3D.BLEND_MODE_MIX
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.cull_mode = BaseMaterial3D.CULL_BACK
	m.albedo_color = c
	return m


## Aynı gövdeyi iki kez kurar: dış kabuk (tam yarıçap) ve çekirdek (yarıçap * 0.5)
static func _two_layer(build: Callable) -> Node3D:
	if _shell_mat == null:
		_shell_mat = _glow(SHELL, false)   # dış kabuk karışımlı: açık zeminde de mavi okunur (eklemeli beyaza yıkanıyordu)
		_core_mat = _glow(CORE)
	var root = Node3D.new()
	for layer in [[1.0, _shell_mat], [0.45, _core_mat]]:
		var b = MB.new()
		build.call(b, layer[0])
		var mi = MeshInstance3D.new()
		mi.mesh = b.build(layer[1])
		mi.material_override = layer[1]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	return root


static func _tube(b: MB, pts: Array, rad: Array, s: float, k: float) -> void:
	var R = []
	for r in rad:
		R.append((r if r is Vector2 else Vector2(r, r)) * s * k)
	Loft.tube(b, ClayArt._sc(pts, s), R, Color.WHITE, 12, 3)


## Kōga: dörtnala koşan ışık tazısı — açık çene, geriye yatık kulaklar, sırtta şimşek yelesi, uzun kuyruk;
## her bacak kalça + diz eklemli, dörtnal döngüsüyle (ön çift / arka çift faz farkı) koşar, gövde iner kalkar
static func hound(s := 1.0) -> Node3D:
	var root = Node3D.new()
	var body = Node3D.new()
	root.add_child(body)
	body.add_child(_two_layer(func(b: MB, k: float):
		_tube(b, [Vector3(0, 0.6, 1.05), Vector3(0, 0.63, 0.9), Vector3(0, 0.67, 0.72), Vector3(0, 0.69, 0.6), Vector3(0, 0.6, 0.45), Vector3(0, 0.5, 0.25), Vector3(0, 0.49, 0.0), Vector3(0, 0.52, -0.2), Vector3(0, 0.53, -0.38), Vector3(0, 0.55, -0.52)],
			[0.04, 0.08, Vector2(0.13, 0.15), Vector2(0.14, 0.15), 0.13, Vector2(0.18, 0.24), Vector2(0.16, 0.19), Vector2(0.12, 0.14), Vector2(0.16, 0.17), 0.09], s, k)
		# açık alt çene
		_tube(b, [Vector3(0, 0.58, 0.62), Vector3(0, 0.53, 0.8), Vector3(0, 0.48, 0.95)], [0.08, 0.06, 0.03], s, k)
		for sx in [-1.0, 1.0]:
			_tube(b, [Vector3(sx * 0.07, 0.78, 0.62), Vector3(sx * 0.1, 0.88, 0.5), Vector3(sx * 0.11, 0.92, 0.38)], [0.05, 0.035, 0.008], s, k)
		# şimşek yelesi: boyun ve sırt boyunca geriye yatık sivri dikenler
		for q in 6:
			var z = 0.5 - q * 0.17
			var y = 0.74 - q * 0.02 if q < 2 else 0.68
			_tube(b, [Vector3(0, y - 0.06, z), Vector3(0, y + 0.1 - q * 0.01, z - 0.14)], [0.05, 0.006], s, k)
		_tube(b, [Vector3(0, 0.56, -0.52), Vector3(0, 0.66, -0.82), Vector3(0, 0.62, -1.15), Vector3(0, 0.72, -1.45)], [0.07, 0.06, 0.04, 0.008], s, k)))
	var legs = []
	for leg in [[-1.0, 0.24, 0.0, 1.0], [1.0, 0.24, 0.12, 1.0], [-1.0, -0.38, 0.5, -1.0], [1.0, -0.38, 0.62, -1.0]]:
		var hip = Node3D.new()
		hip.position = Vector3(leg[0] * 0.12, 0.47, leg[1]) * s
		hip.add_child(_two_layer(func(b: MB, k: float):
			_tube(b, [Vector3.ZERO, Vector3(0, -0.12, 0.0), Vector3(0, -0.23, 0.0)], [0.08, 0.065, 0.05], s, k)))
		var knee = Node3D.new()
		knee.position = Vector3(0, -0.23, 0) * s
		knee.add_child(_two_layer(func(b: MB, k: float):
			_tube(b, [Vector3.ZERO, Vector3(0, -0.12, 0.0), Vector3(0, -0.22, 0.02), Vector3(0, -0.24, 0.08)], [0.05, 0.04, 0.045, 0.03], s, k)))
		hip.add_child(knee)
		body.add_child(hip)
		legs.append([hip, knee, leg[2], leg[3]])
	var tw = root.create_tween().set_loops()
	tw.tween_method(func(ph: float):
		for L in legs:
			if not is_instance_valid(L[0]):
				return
			var a = TAU * (ph + L[2])
			L[0].rotation.x = -sin(a) * 0.85
			L[1].rotation.x = L[3] * (0.25 + 0.75 * maxf(0.0, sin(a + 1.3))) * 0.95
		body.position.y = absf(sin(TAU * ph)) * 0.06 * s
		body.rotation.x = sin(TAU * ph) * 0.06, 0.0, 1.0, 0.3)
	return ClayArt._fwd(root)


## Kaminari Ryū: ışık ejderhası başı (uzun burun, açık çene, arkaya kıvrık boynuzlar, yele dikenleri); gövde ışın kuyruğudur
static func dragon_head(s := 1.0) -> Node3D:
	return ClayArt._fwd(_two_layer(func(b: MB, k: float):
		# üst kafa + burun
		_tube(b, [Vector3(0, 0.1, 1.2), Vector3(0, 0.16, 0.85), Vector3(0, 0.26, 0.4), Vector3(0, 0.28, 0.0), Vector3(0, 0.2, -0.4)], [0.12, 0.2, 0.32, 0.38, 0.3], s, k)
		# açık alt çene
		_tube(b, [Vector3(0, -0.05, 0.0), Vector3(0, -0.18, 0.5), Vector3(0, -0.3, 0.95)], [0.24, 0.16, 0.08], s, k)
		for sx in [-1.0, 1.0]:
			_tube(b, [Vector3(sx * 0.2, 0.5, -0.05), Vector3(sx * 0.32, 0.75, -0.45), Vector3(sx * 0.36, 0.85, -0.95)], [0.09, 0.07, 0.02], s, k)
			# bıyık gibi uzanan ışık telleri
			_tube(b, [Vector3(sx * 0.12, 0.08, 1.0), Vector3(sx * 0.45, 0.0, 0.8), Vector3(sx * 0.8, -0.15, 0.4)], [0.035, 0.03, 0.008], s, k)
		for q in 4:
			var z = -0.25 - q * 0.22
			_tube(b, [Vector3(0, 0.4, z), Vector3(0, 0.62 - q * 0.04, z - 0.15)], [0.07, 0.01], s, k)))
