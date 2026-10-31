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


## Kōga: koşan ışık tazısı (gövde, kulaklar, kuyruk; bacaklar ayrı düğüm — koşu salınımı)
static func hound(s := 1.0) -> Node3D:
	var root = Node3D.new()
	root.add_child(_two_layer(func(b: MB, k: float):
		_tube(b, [Vector3(0, 0.56, 1.0), Vector3(0, 0.62, 0.78), Vector3(0, 0.64, 0.62), Vector3(0, 0.52, 0.42), Vector3(0, 0.46, 0.15), Vector3(0, 0.46, -0.2), Vector3(0, 0.5, -0.45)],
			[0.05, 0.12, 0.17, 0.14, 0.23, 0.2, 0.17], s, k)
		for sx in [-1.0, 1.0]:
			_tube(b, [Vector3(sx * 0.08, 0.74, 0.6), Vector3(sx * 0.12, 0.92, 0.5), Vector3(sx * 0.13, 1.02, 0.4)], [0.06, 0.045, 0.01], s, k)
		_tube(b, [Vector3(0, 0.52, -0.5), Vector3(0, 0.62, -0.8), Vector3(0, 0.78, -1.1), Vector3(0, 0.84, -1.3)], [0.09, 0.07, 0.05, 0.01], s, k)))
	for leg in [[-1.0, 0.18, 0.0], [1.0, 0.18, PI], [-1.0, -0.38, PI], [1.0, -0.38, 0.0]]:
		var piv = Node3D.new()
		piv.position = Vector3(leg[0] * 0.13, 0.45, leg[1]) * s
		piv.add_child(_two_layer(func(b: MB, k: float):
			_tube(b, [Vector3.ZERO, Vector3(0, -0.22, -0.05), Vector3(0, -0.42, 0.04)], [0.08, 0.06, 0.05], s, k)))
		root.add_child(piv)
		var tw = piv.create_tween().set_loops()
		piv.rotation.x = 0.6 * (1.0 if leg[2] == 0.0 else -1.0)
		tw.tween_property(piv, "rotation:x", -piv.rotation.x, 0.12).set_trans(Tween.TRANS_SINE)
		tw.tween_property(piv, "rotation:x", piv.rotation.x, 0.12).set_trans(Tween.TRANS_SINE)
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
