class_name VfxTrail
extends MeshInstance3D
## Hedefi takip eden kameraya dönük kurdele iz (mermi kuyruğu). Hedef yok olunca kuyruk toplanıp kaybolur.

var target: Node3D
var width = 1.0
var max_pts = 18
var min_step = 0.35
var pts: Array[Vector3] = []
var fade = 1.0
var dying = false
var im := ImmediateMesh.new()


func _ready() -> void:
	top_level = true
	mesh = im
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 2000.0
	global_transform = Transform3D.IDENTITY


func _process(dt: float) -> void:
	if not dying and target != null and is_instance_valid(target) and target.is_inside_tree():
		var p = target.global_position
		if pts.is_empty() or pts[0].distance_to(p) > min_step:
			pts.push_front(p)
			if pts.size() > max_pts:
				pts.pop_back()
		else:
			pts[0] = p
	else:
		dying = true
		fade -= dt * 4.0
		if not pts.is_empty() and randf() < 0.9:
			pts.pop_back()
		if fade <= 0.0 or pts.size() < 2:
			queue_free()
			return
	_rebuild()


func _rebuild() -> void:
	im.clear_surfaces()
	if pts.size() < 2:
		return
	var cam = get_viewport().get_camera_3d()
	if cam == null:
		return
	var cp = cam.global_position
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var n = pts.size()
	var a = clampf(fade, 0.0, 1.0)
	for i in n - 1:
		var p0 = pts[i]; var p1 = pts[i + 1]
		var d = (p1 - p0)
		if d.length() < 0.001:
			continue
		var s0 = d.cross(cp - p0).normalized() * width * 0.5
		var s1 = d.cross(cp - p1).normalized() * width * 0.5
		var u0 = float(i) / (n - 1); var u1 = float(i + 1) / (n - 1)
		var c = Color(1, 1, 1, a)
		for v in [[p0 + s0, u0, 0.0], [p1 + s1, u1, 0.0], [p1 - s1, u1, 1.0], [p0 + s0, u0, 0.0], [p1 - s1, u1, 1.0], [p0 - s0, u0, 1.0]]:
			im.surface_set_color(c)
			im.surface_set_uv(Vector2(v[1], v[2]))
			im.surface_add_vertex(v[0])
	im.surface_end()
