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


func _ready() -> void:
	mesh = im
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 200.0


func _process(dt: float) -> void:
	if color != _col_set:
		_col_set = color
		material_override = VFX.mat_bolt(color, 2.0)
	t -= dt
	if t > 0.0:
		return
	t = 0.045
	var cam = get_viewport().get_camera_3d()
	if cam == null:
		return
	var cl: Vector3 = global_transform.affine_inverse() * cam.global_position
	im.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
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


func _path(a: Vector3, b: Vector3, n: int, jitter: float) -> Array:
	var out = [a]
	for s in range(1, n):
		var k = float(s) / n
		out.append(a.lerp(b, k) + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * jitter)
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
