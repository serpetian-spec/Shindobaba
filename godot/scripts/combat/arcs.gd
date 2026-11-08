class_name Arcs
extends MeshInstance3D
## Kalın, titreyen şimşek arkları (Chidori, Raiton). Her ~0.045 sn yeniden zikzaklanır.
## to_point == ZERO: merkezden rastgele yönlere ışıyan arklar; değilse yerel 0 → to_point arası dallanan ana şimşek.

var color = Color(0.5, 0.75, 1.0)
var radius = 1.0
var count = 6
var segs = 7
var width = 0.05
var to_point := Vector3.ZERO
var im = ImmediateMesh.new()
var t = 0.0
var _col_set := Color(-1, -1, -1)
var glow := 4.5   # hale genişliği (çekirdeğin katı); 0 = hale yok
var _gim := ImmediateMesh.new()
var _gmi: MeshInstance3D
static var _glow_tex: GradientTexture2D
static var _glow_mats := {}


func _ready() -> void:
	mesh = im
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 200.0
	if glow > 0.0:
		_gmi = MeshInstance3D.new()
		_gmi.mesh = _gim
		_gmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_gmi.extra_cull_margin = 200.0
		add_child(_gmi)


func _process(dt: float) -> void:
	if color != _col_set:
		_col_set = color
		material_override = VFX.mat_bolt(color, 2.0)
		if _gmi:
			_gmi.material_override = _glow_mat(color)
	t -= dt
	if t > 0.0:
		return
	t = 0.045
	var cam = get_viewport().get_camera_3d()
	if cam == null:
		return
	var cl: Vector3 = global_transform.affine_inverse() * cam.global_position
	im.clear_surfaces()
	_gim.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	if _gmi:
		_gim.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	if to_point != Vector3.ZERO:
		var main = _path(Vector3.ZERO, to_point, segs, to_point.length() * 0.06)
		_strip(main, width, cl)
		for b in count:
			var i = randi_range(1, maxi(1, main.size() - 2))
			var from: Vector3 = main[i]
			var dir = (to_point.normalized() + Vector3(randf_range(-1, 1), randf_range(-0.6, 0.6), randf_range(-1, 1)) * 0.9).normalized()
			var L = to_point.length() * randf_range(0.12, 0.3)
			_strip(_path(from, from + dir * L, 4, L * 0.12), width * 0.55, cl)
	else:
		for i in count:
			var dir = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
			var L = radius * randf_range(0.5, 1.0)
			_strip(_path(Vector3.ZERO, dir * L, segs, radius * 0.16), width * randf_range(0.7, 1.2), cl)
	im.surface_end()
	if _gmi:
		_gim.surface_end()


## Hale malzemesi: enine yumuşak gradyan (kenarlar saydam), toplamalı, gölgesiz
static func _glow_mat(c: Color) -> StandardMaterial3D:
	var key = c.to_html()
	if _glow_mats.has(key):
		return _glow_mats[key]
	if _glow_tex == null:
		var g = Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		_glow_tex = GradientTexture2D.new()
		_glow_tex.gradient = g
		_glow_tex.fill_from = Vector2(0, 0)
		_glow_tex.fill_to = Vector2(0, 1)
		_glow_tex.width = 4
		_glow_tex.height = 64
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# karışım modu: toplamalıda üst üste binen haleler HDR'de taşıp bloom'da siyah bloklar yapıyordu
	m.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.albedo_texture = _glow_tex
	m.albedo_color = Color(c.r * 0.6, c.g * 0.9, minf(1.0, c.b * 1.1), 0.22)   # doygun, soluk hale (beyaz sis değil)
	_glow_mats[key] = m
	return m


func _path(a: Vector3, b: Vector3, n: int, jitter: float) -> Array:
	var out = [a]
	# düzensiz kırılım: iki kat nokta, çoğu küçük sapma, arada büyük kıvrım (eşit zikzak geometrik duruyordu)
	n *= 2
	var drift = Vector3.ZERO
	for s in range(1, n):
		var k = float(s) / n
		var r = randf()
		drift = drift * 0.55 + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * jitter * (0.25 + r * r * 1.1)
		out.append(a.lerp(b, k) + drift * sin(k * PI) * 1.4)
	out.append(b)
	return out


## Kameraya dönük şerit (incelen uç)
func _strip(pts: Array, w: float, cl: Vector3) -> void:
	var n = pts.size()
	for i in n - 1:
		var p0: Vector3 = pts[i]; var p1: Vector3 = pts[i + 1]
		var d = p1 - p0
		if d.length() < 0.0001:
			continue
		var taper0 = 1.0 - float(i) / n * 0.6
		var taper1 = 1.0 - float(i + 1) / n * 0.6
		var s0 = d.cross(cl - p0).normalized() * w * taper0
		var s1 = d.cross(cl - p1).normalized() * w * taper1
		for v in [[p0 + s0, 0.0], [p1 + s1, 0.0], [p1 - s1, 1.0], [p0 + s0, 0.0], [p1 - s1, 1.0], [p0 - s0, 1.0]]:
			im.surface_set_color(Color(1, 1, 1, 1))
			im.surface_set_uv(Vector2(float(i) / n, v[1]))
			im.surface_add_vertex(v[0])
		if _gmi:
			# hale: ince şimşekte geniş, kalında çekirdeğin hemen dışında (kalın şimşekte 4 m'lik düz levhalar oluyordu)
			var g0 = s0.normalized() * minf(s0.length() * glow, s0.length() + 0.22)
			var g1 = s1.normalized() * minf(s1.length() * glow, s1.length() + 0.22)
			for v in [[p0 + g0, 0.0], [p1 + g1, 0.0], [p1 - g1, 1.0], [p0 + g0, 0.0], [p1 - g1, 1.0], [p0 - g0, 1.0]]:
				_gim.surface_set_uv(Vector2(float(i) / n, v[1]))
				_gim.surface_add_vertex(v[0])
