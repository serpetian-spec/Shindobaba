class_name Arcs
extends MeshInstance3D
## Zikzak elektrik arkları (Chidori, Raiton). Her kare yeniden çizilir, titrer.

var color = Color(0.5, 0.75, 1.0)
var radius = 1.0
var count = 6
var segs = 7
var im = ImmediateMesh.new()
var t = 0.0


func _ready() -> void:
	mesh = im
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(2.5, 2.5, 2.5)
	material_override = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _process(dt: float) -> void:
	t -= dt
	if t > 0.0:
		return
	t = 0.04
	im.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in count:
		var dir = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var p = Vector3.ZERO
		var L = radius * randf_range(0.5, 1.0)
		for s in segs:
			var q = dir * L * float(s + 1) / segs + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * radius * 0.18
			var c = color.lerp(Color(1, 1, 1), 0.5 if s < 2 else 0.0)
			im.surface_set_color(c)
			im.surface_add_vertex(p)
			im.surface_set_color(c)
			im.surface_add_vertex(q)
			p = q
	im.surface_end()
