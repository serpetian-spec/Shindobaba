class_name LightRibbon
extends MeshInstance3D
## Işın şeridi (anime lazer / Ranton): her karede kameraya dönük şerit; ortası beyaz-sıcak, kenarlara doğru
## renkli hâleye ve saydama yumuşakça söner. Kutu değil, derinlik yazmaz (kenar çizgisi geçişine girmez).
## pts: dünya noktaları (bükülebilir), width: tam genişlik, dur: ömür (sona doğru söner)

var pts: Array = []
var width := 0.6
var dur := 0.4
var col := Color(0.5, 0.8, 1.0)
var grow := 0.08          # ışının uca doğru uzama süresi
var _t := 0.0
var _im := ImmediateMesh.new()
var _mat: StandardMaterial3D

static var _tex_cache := {}


static func spawn(points: Array, w: float, d: float, c := Color(0.5, 0.8, 1.0)) -> LightRibbon:
	var r = LightRibbon.new()
	r.pts = points
	r.width = w
	r.dur = d
	r.col = c
	var sc = Engine.get_main_loop().current_scene
	sc.add_child(r)
	return r


func _ready() -> void:
	mesh = _im
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.vertex_color_use_as_albedo = true
	_mat.albedo_texture = _cross_tex(col)
	material_override = _mat
	extra_cull_margin = 1000.0
	_build()


## Şeridin enine kesiti: merkez beyaz, sonra renk, kenarda saydam
static func _cross_tex(c: Color) -> Texture2D:
	var key = c.to_html()
	if _tex_cache.has(key):
		return _tex_cache[key]
	var g = Gradient.new()
	g.set_color(0, Color(c.r, c.g, c.b, 0.0))
	g.add_point(0.22, Color(c.r, c.g, c.b, 0.55))
	g.add_point(0.4, Color(c.lerp(Color.WHITE, 0.6), 1.0))
	g.add_point(0.5, Color(1, 1, 1, 1))
	g.add_point(0.6, Color(c.lerp(Color.WHITE, 0.6), 1.0))
	g.add_point(0.78, Color(c.r, c.g, c.b, 0.55))
	g.set_color(g.get_point_count() - 1, Color(c.r, c.g, c.b, 0.0))
	var t = GradientTexture2D.new()
	t.gradient = g
	t.width = 64
	t.height = 4
	t.fill_from = Vector2(0, 0.5)
	t.fill_to = Vector2(1, 0.5)
	_tex_cache[key] = t
	return t


func _process(dt: float) -> void:
	_t += dt
	if _t >= dur:
		queue_free()
		return
	_build()


func _build() -> void:
	_im.clear_surfaces()
	var cam = get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null or pts.size() < 2:
		return
	var eye = cam.global_position
	var k_len = clampf(_t / maxf(grow, 0.001), 0.0, 1.0)          # ucuna doğru uzar
	var fade = 1.0 - clampf((_t - dur * 0.55) / (dur * 0.45), 0.0, 1.0)   # sona doğru söner
	var n = pts.size()
	var last = maxi(1, int(ceil((n - 1) * k_len)))
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in last + 1:
		var p: Vector3 = pts[i]
		var tan: Vector3 = (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var side = tan.cross((eye - p).normalized()).normalized()
		var w = width * fade * (0.55 + 0.45 * sin(PI * (0.15 + 0.85 * float(i) / float(n - 1))))   # uçlarda biraz incelir
		var a = fade
		_im.surface_set_color(Color(1, 1, 1, a))
		_im.surface_set_uv(Vector2(0, float(i) / n))
		_im.surface_add_vertex(to_local(p - side * w * 0.5))
		_im.surface_set_color(Color(1, 1, 1, a))
		_im.surface_set_uv(Vector2(1, float(i) / n))
		_im.surface_add_vertex(to_local(p + side * w * 0.5))
	_im.surface_end()


## Düz ya da bükülmüş yol üret (a'dan b'ye, mid'den geçen ikinci derece eğri)
static func curve(a: Vector3, b: Vector3, mid: Vector3, n := 16) -> Array:
	var out = []
	for i in n + 1:
		var f = float(i) / n
		out.append(a.lerp(mid, f).lerp(mid.lerp(b, f), f))
	return out
