class_name SwordTrail
extends MeshInstance3D
## Kılıç savuruş izi (Storm tarzı): kılıç gövdesinin taradığı yüzey, yarı saydam soluk beyaz-mavi şerit.
## Sadece hızlı savuruşta görünür (uç hızıyla saydamlık), ~0.15 sn'de söner.

var node: Node3D
var z0 := 0.45          # silah yerelinde şeridin başladığı nokta (sargının ortası)
var z1 := 1.9           # uç
var life := 0.15
var active := true
var color := Color(0.88, 0.95, 1.0)
var _hist: Array = []   # [zaman, taban, uç, hız katsayısı]
var _t := 0.0
var _im := ImmediateMesh.new()


func _ready() -> void:
	top_level = true
	mesh = _im
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 1000.0
	global_transform = Transform3D.IDENTITY
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.vertex_color_use_as_albedo = true
	m.no_depth_test = false
	material_override = m


func _process(dt: float) -> void:
	_t += dt
	if active and node != null and is_instance_valid(node) and node.is_inside_tree():
		var xf = node.global_transform
		var b = xf * Vector3(0, 0, z0)
		var tp = xf * Vector3(0, 0, z1)
		var sp = 0.0
		if not _hist.is_empty() and dt > 0.0:
			sp = clampf((tp.distance_to(_hist[0][2]) / dt - 6.0) / 14.0, 0.0, 1.0)   # ~6 m/s altı iz yok, 20 m/s tam
		_hist.push_front([_t, b, tp, sp])
	elif _hist.is_empty():
		queue_free()
		return
	while not _hist.is_empty() and _t - _hist[_hist.size() - 1][0] > life:
		_hist.pop_back()
	_rebuild()


func _rebuild() -> void:
	_im.clear_surfaces()
	var n = _hist.size()
	if n < 2:
		return
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n - 1:
		var h0 = _hist[i]
		var h1 = _hist[i + 1]
		var a0 = (1.0 - (_t - h0[0]) / life) * h0[3] * 0.55
		var a1 = (1.0 - (_t - h1[0]) / life) * h1[3] * 0.55
		var c0b = Color(color, a0 * 0.35)
		var c0t = Color(color, a0)
		var c1b = Color(color, a1 * 0.35)
		var c1t = Color(color, a1)
		_im.surface_set_color(c0b); _im.surface_add_vertex(h0[1])
		_im.surface_set_color(c0t); _im.surface_add_vertex(h0[2])
		_im.surface_set_color(c1t); _im.surface_add_vertex(h1[2])
		_im.surface_set_color(c0b); _im.surface_add_vertex(h0[1])
		_im.surface_set_color(c1t); _im.surface_add_vertex(h1[2])
		_im.surface_set_color(c1b); _im.surface_add_vertex(h1[1])
	_im.surface_end()
