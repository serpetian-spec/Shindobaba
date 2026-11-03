extends Node
## Oyuncu çevresindeki 2 km'lik yerel yol dokusu (2 m/piksel). Yol çoklu çizgileri ortografik kamerayla
## tepeden bir SubViewport'a çizilir; arazi shader'ı (terrain.gdshader) bu dokuyu yol maskesi olarak kullanır.
## Ayrıca küçük harita için stilize yerel harita dokusu üretir (local_map / local_rect).

const SIZE := 2048.0         # yol penceresi (m)
const PIX := 1024
const RECENTER := 420.0
const MAP_SIZE := 1600.0      # küçük harita penceresi (m)
const MAP_PIX := 512

var texture: Texture2D
var rect := Vector4.ZERO      # x0, z0, boyut, -
var version := 0
var local_map: Texture2D       # küçük harita: arazi rengi + yollar + nehirler + köyler
var local_rect := Vector4.ZERO
var center := Vector2(1e9, 1e9)

var _sv: SubViewport
var _cam: Camera3D
var _mesh: MeshInstance3D
var _msv: SubViewport
var _mcam: Camera3D
var _mroads: MeshInstance3D
var _mground: MeshInstance3D
var _mmat: ShaderMaterial
var _pending := 0
## Köy içi ara sokak patikaları + ev tabanları (CityLandscape, Builder): dünya xz [a, e, yarı genişlik]. Yol dokusunun G kanalına
## çizilir: çimen (R ya da G) burada çıkmaz; arazi yalnız R'yi (gerçek yollar) okur, köy zemini toprağa boyanmaz.
static var lanes: Array = []
static var lanes_dirty := false
var _lane_mesh: MeshInstance3D
var _lane_t := 0.0


func _ready() -> void:
	_sv = _make_viewport(PIX)
	_cam = _ortho_cam(_sv, SIZE)
	_mesh = MeshInstance3D.new()
	var m = ShaderMaterial.new()
	m.shader = _ribbon_shader(false)
	_mesh.material_override = m
	_sv.add_child(_mesh)
	_lane_mesh = MeshInstance3D.new()
	var lm = ShaderMaterial.new()
	lm.shader = Shader.new()
	lm.shader.code = """shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, depth_test_disabled;
void fragment() {
	float e = 1.0 - smoothstep(0.36, 0.5, abs(UV.x - 0.5));
	ALBEDO = vec3(0.0, e, 0.0);
}"""
	_lane_mesh.material_override = lm
	_sv.add_child(_lane_mesh)
	# küçük harita
	_msv = _make_viewport(MAP_PIX)
	_mcam = _ortho_cam(_msv, MAP_SIZE)
	_mground = MeshInstance3D.new()
	var q = PlaneMesh.new()
	q.size = Vector2(MAP_SIZE * 1.02, MAP_SIZE * 1.02)
	_mground.mesh = q
	_mmat = ShaderMaterial.new()
	_mmat.shader = load("res://shaders/local_map.gdshader")
	Game.setup_height_material(_mmat)
	_mmat.set_shader_parameter("albedo_map", Game.albedo_tex)
	_mground.material_override = _mmat
	_msv.add_child(_mground)
	_mroads = MeshInstance3D.new()
	var rm = ShaderMaterial.new()
	rm.shader = _ribbon_shader(true)
	_mroads.material_override = rm
	_msv.add_child(_mroads)


func _make_viewport(px: int) -> SubViewport:
	var sv = SubViewport.new()
	sv.size = Vector2i(px, px)
	sv.own_world_3d = true
	sv.transparent_bg = false
	sv.render_target_update_mode = SubViewport.UPDATE_DISABLED
	sv.msaa_3d = Viewport.MSAA_2X
	add_child(sv)
	var we = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0)
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	we.environment = env
	sv.add_child(we)
	return sv


func _ortho_cam(sv: SubViewport, size: float) -> Camera3D:
	var c = Camera3D.new()
	c.projection = Camera3D.PROJECTION_ORTHOGONAL
	c.size = size
	c.near = 1.0
	c.far = 2000.0
	c.rotation_degrees = Vector3(-90, 0, 0)
	c.current = true
	sv.add_child(c)
	return c


func _ribbon_shader(colored: bool) -> Shader:
	var s = Shader.new()
	if colored:
		s.code = """shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, depth_test_disabled;
void fragment() {
	float e = 1.0 - smoothstep(0.3, 0.5, abs(UV.x - 0.5));
	ALBEDO = COLOR.rgb;
	ALPHA = e * COLOR.a;
}"""
	else:
		s.code = """shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, depth_test_disabled;
void fragment() {
	float e = 1.0 - smoothstep(0.32, 0.5, abs(UV.x - 0.5));
	ALBEDO = vec3(1.0);
	ALPHA = e;
}"""
	return s


static func add_lane(a: Vector2, e: Vector2, half := 2.4) -> void:
	lanes.append([a, e, half])
	lanes_dirty = true


func _process(dt: float) -> void:
	if _pending > 0:
		return
	var cam = get_viewport().get_camera_3d()
	if cam == null:
		return
	var p = cam.global_position
	var c = Vector2(p.x, p.z)
	_lane_t += dt
	if lanes_dirty and _lane_t > 1.5 and center.x < 1e8:   # köy kurulurken yeni patikalar: en fazla 1.5 sn'de bir yeniden çiz
		lanes_dirty = false
		_lane_t = 0.0
		_rebuild()
		return
	if c.distance_to(center) < RECENTER:
		return
	center = Vector2(snappedf(c.x, 64.0), snappedf(c.y, 64.0))
	_rebuild()


func _rebuild() -> void:
	var m = Vector2(center.x, -center.y)
	var segs = Game.road_segments_near(m, SIZE * 0.75)
	_mesh.mesh = _ribbons(segs, 1.0, false)
	_lane_mesh.mesh = _lane_ribbons()
	_mroads.mesh = _ribbons(Game.road_segments_near(m, MAP_SIZE * 0.75), 2.6, true)
	for cam in [_cam, _mcam]:
		cam.position = Vector3(center.x, 1000.0, center.y)
	_mground.position = Vector3(center.x, 0, center.y)
	_mmat.set_shader_parameter("center", center)
	rect = Vector4(center.x - SIZE * 0.5, center.y - SIZE * 0.5, SIZE, 0)
	local_rect = Vector4(center.x - MAP_SIZE * 0.5, center.y - MAP_SIZE * 0.5, MAP_SIZE, 0)
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_msv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_pending = 1
	# çizim bitince görüntü kapısı dokusunu kalıcı dokuya kopyala (başka materyallerde güvenle örneklenir)
	for i in 3:
		await RenderingServer.frame_post_draw
	var img: Image = _sv.get_texture().get_image()
	img.convert(Image.FORMAT_RG8)   # R: yollar (arazi + çimen), G: patika/ev tabanı (yalnız çimen)
	texture = ImageTexture.create_from_image(img)
	local_map = ImageTexture.create_from_image(_msv.get_texture().get_image())
	_sv.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_msv.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_pending = 0
	version += 1


## Ara sokak patikaları (pencere içindekiler): yarı genişlik 2.4 m (patika 1.5 m + kenar; 2 m/piksel dokuda kaybolmasın)
func _lane_ribbons() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n = 0
	for ln in lanes:
		var a: Vector2 = ln[0]
		var e: Vector2 = ln[1]
		var half: float = ln[2]
		if a.distance_to(center) > SIZE * 0.75:
			continue
		var A = Vector3(a.x, 0, a.y)
		var B = Vector3(e.x, 0, e.y)
		var dir = B - A
		if dir.length() < 0.01:
			continue
		dir = dir.normalized()
		var side = Vector3(-dir.z, 0, dir.x) * half
		A -= dir * half * 0.5
		B += dir * half * 0.5
		for q in [[A - side, 0.0], [A + side, 1.0], [B + side, 1.0], [A - side, 0.0], [B + side, 1.0], [B - side, 0.0]]:
			st.set_uv(Vector2(q[1], 0))
			st.add_vertex(q[0])
		n += 1
	if n == 0:
		return null
	return st.commit()


## Yol parçalarından şerit ağı (UV.x yol kesiti, köşelerde yuvarlak kapak için ek dörtgen)
func _ribbons(segs: Array, width_mul: float, colored: bool) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var road_col = Color(0.62, 0.42, 0.24, 1.0)
	var street_col = Color(0.55, 0.5, 0.45, 1.0)
	for e in segs:
		var rl: Dictionary = Game.roads[e.x]
		var pts: PackedVector2Array = rl["pts"]
		var a: Vector2 = pts[e.y]
		var b: Vector2 = pts[e.y + 1]
		var half = {"road": 8.0, "street": 9.0, "path": 2.6}.get(rl["kind"], 8.0) * width_mul
		var A = Vector3(a.x, 0, -a.y)
		var B = Vector3(b.x, 0, -b.y)
		var dir = (B - A)
		if dir.length() < 0.01:
			continue
		dir = dir.normalized()
		var side = Vector3(-dir.z, 0, dir.x) * half
		A -= dir * half * 0.6
		B += dir * half * 0.6
		var col = road_col if rl["kind"] != "street" else street_col
		var quad = [[A - side, 0.0], [A + side, 1.0], [B + side, 1.0], [A - side, 0.0], [B + side, 1.0], [B - side, 0.0]]
		for q in quad:
			st.set_uv(Vector2(q[1], 0))
			st.set_color(col)
			st.add_vertex(q[0])
	if colored:
		# nehirler (mavi, geniş)
		for rv in Game.rivers:
			for i in range(rv.size() - 1):
				var A = Vector3(rv[i][0], 0, -float(rv[i][1]))
				var B = Vector3(rv[i + 1][0], 0, -float(rv[i + 1][1]))
				if Vector2(A.x, A.z).distance_to(center) > MAP_SIZE * 3 and Vector2(B.x, B.z).distance_to(center) > MAP_SIZE * 3:
					continue
				var dir = (B - A).normalized()
				var side = Vector3(-dir.z, 0, dir.x) * 60.0
				for q in [[A - side, 0.0], [A + side, 1.0], [B + side, 1.0], [A - side, 0.0], [B + side, 1.0], [B - side, 0.0]]:
					st.set_uv(Vector2(q[1], 0))
					st.set_color(Color(0.3, 0.55, 0.85, 1.0))
					st.add_vertex(q[0])
	var mesh = st.commit()
	return mesh
