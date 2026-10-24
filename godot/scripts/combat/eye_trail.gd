class_name EyeTrail
extends MeshInstance3D
## Dōjutsu açıkken gözden çıkan ince ışık izi (Shinobi Striker tarzı): baş hareket ettikçe arkada kısa,
## incelerek sönen kırmızı kurdele bırakır. Noktalar zamanla eskir; dururken iz kendiliğinden kısalır.

const LIFE := 0.28
var anchor: Node3D
var col := Color(1.0, 0.12, 0.1)
var width := 0.03
var pts: Array = []   # [konum, yaş]
var im := ImmediateMesh.new()
var glow: MeshInstance3D


func _ready() -> void:
	top_level = true
	mesh = im
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 50.0
	global_transform = Transform3D.IDENTITY
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	material_override = m
	# gözün kendisinde yumuşak parıltı
	glow = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = Vector2(0.06, 0.06)
	glow.mesh = q
	var gm = StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	gm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	gm.albedo_texture = _dot()
	gm.albedo_color = Color(col.r, col.g, col.b, 0.55)
	glow.material_override = gm
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glow.top_level = true
	add_child(glow)


static var _dot_tex: Texture2D
static func _dot() -> Texture2D:
	if _dot_tex == null:
		var g = Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t = GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 32
		t.height = 32
		_dot_tex = t
	return _dot_tex


func _process(dt: float) -> void:
	if anchor == null or not is_instance_valid(anchor) or not anchor.is_inside_tree():
		queue_free()
		return
	var p = anchor.global_position
	glow.global_position = p
	glow.visible = anchor.is_visible_in_tree()
	for e in pts:
		e[1] += dt
	while not pts.is_empty() and pts[-1][1] > LIFE:
		pts.pop_back()
	if pts.is_empty() or pts[0][0].distance_to(p) > 0.012:
		pts.push_front([p, 0.0])
	else:
		pts[0][0] = p
	_rebuild()


func _rebuild() -> void:
	im.clear_surfaces()
	if pts.size() < 2 or not anchor.is_visible_in_tree():
		return
	var cam = get_viewport().get_camera_3d()
	if cam == null:
		return
	var cp = cam.global_position
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in pts.size() - 1:
		var p0: Vector3 = pts[i][0]; var p1: Vector3 = pts[i + 1][0]
		var d = p1 - p0
		if d.length() < 0.0005:
			continue
		var k0 = 1.0 - pts[i][1] / LIFE; var k1 = 1.0 - pts[i + 1][1] / LIFE
		var s0 = d.cross(cp - p0).normalized() * width * 0.5 * k0
		var s1 = d.cross(cp - p1).normalized() * width * 0.5 * k1
		var c0 = Color(col.r, col.g, col.b, k0 * 0.9); var c1 = Color(col.r, col.g, col.b, k1 * 0.9)
		for v in [[p0 + s0, c0], [p1 + s1, c1], [p1 - s1, c1], [p0 + s0, c0], [p1 - s1, c1], [p0 - s0, c0]]:
			im.surface_set_color(v[1])
			im.surface_add_vertex(v[0])
	im.surface_end()
