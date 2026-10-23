extends Node
## Şelaleler (kayan su dokusu + köpük parçacıkları) ve kaplıca buharı.
## add_epic: büyük şelaleler (Sonun Vadisi) için kavisli su perdesi, katmanlı köpük çizgileri, dipte sis/serpinti,
## köpük halkaları, gökkuşağı, yan sızıntılar, akan nehir yüzeyi ve uğultu sesi.

var mat: ShaderMaterial
var _epic_mats := {}


func _ready() -> void:
	mat = ShaderMaterial.new()
	var sh = Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) { vec2 i = floor(p), f = fract(p); vec2 u = f*f*(3.0-2.0*f);
	return mix(mix(hash(i), hash(i+vec2(1,0)), u.x), mix(hash(i+vec2(0,1)), hash(i+vec2(1,1)), u.x), u.y); }
void fragment() {
	vec2 uv = UV * vec2(6.0, 3.0);
	float n = vn(vec2(uv.x * 3.0, uv.y * 2.0 - TIME * 4.0)) * 0.6 + vn(vec2(uv.x * 9.0, uv.y * 5.0 - TIME * 7.0)) * 0.4;
	vec3 c = mix(vec3(0.35, 0.62, 0.78), vec3(0.95, 0.98, 1.0), smoothstep(0.45, 0.8, n));
	c = mix(c, vec3(1.0), smoothstep(0.85, 1.0, UV.y));
	ALBEDO = c;
	ALPHA = 0.85;
}
"""
	mat.shader = sh


## base: şelalenin dibi (dünya), height: yükseklik, width: genişlik, yaw: yön (derece, yerel)
func add(base: Vector3, height: float, width: float, yaw: float) -> void:
	var mi = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = Vector2(width, height)
	mi.mesh = q
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = base + Vector3(0, height * 0.5, 0)
	mi.rotation.y = deg_to_rad(-yaw)
	# dipte köpük
	var p = GPUParticles3D.new()
	p.amount = 60
	p.lifetime = 1.5
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(width * 0.5, 0.5, 1.0)
	pm.direction = Vector3.UP
	pm.spread = 40.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 5.0
	pm.gravity = Vector3(0, -2, 0)
	pm.scale_min = 2.0; pm.scale_max = 4.0
	p.process_material = pm
	var qm = QuadMesh.new()
	qm.material = FX._draw_mat(FX.tex_smoke, false)
	p.draw_pass_1 = qm
	add_child(p)
	p.global_position = base + Vector3(0, 0.5, 0)
	p.emitting = true


# ------------------------------------------------------------------ destansı şelale
const SHEET_SH := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_always;
uniform float speed = 1.0;
uniform float streak_x = 40.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) { vec2 i = floor(p), f = fract(p); vec2 u = f*f*(3.0-2.0*f);
	return mix(mix(hash(i), hash(i+vec2(1,0)), u.x), mix(hash(i+vec2(0,1)), hash(i+vec2(1,1)), u.x), u.y); }
void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;
	// katmanlı köpük çizgileri: yatayda sık, düşeyde uzun, farklı hızlarda aşağı kayar
	float s1 = vn(vec2(uv.x * streak_x, uv.y * 3.0 - t * 1.7));
	float s2 = vn(vec2(uv.x * streak_x * 2.3 + 7.0, uv.y * 6.0 - t * 2.8));
	float s3 = vn(vec2(uv.x * streak_x * 0.45 + 3.0, uv.y * 1.6 - t * 1.1));
	float b = s1 * 0.5 + s2 * 0.3 + s3 * 0.2;
	// anime bantları: koyu turkuaz -> gök mavisi -> açık -> beyaz köpük
	vec3 c = vec3(0.07, 0.42, 0.78);
	c = mix(c, vec3(0.22, 0.68, 0.96), step(0.40, b));
	c = mix(c, vec3(0.66, 0.92, 1.0), step(0.58, b));
	c = mix(c, vec3(1.0), step(0.73, b));
	// tepede köpüklü dudak, dipte beyaz kaynama
	float lip = 1.0 - smoothstep(0.0, 0.06, uv.y - (vn(vec2(uv.x * 25.0, t * 0.7)) - 0.5) * 0.04);
	float bot = smoothstep(0.72, 0.97, uv.y + (vn(vec2(uv.x * 18.0, uv.y * 5.0 - t * 3.0)) - 0.5) * 0.2);
	float foam = max(lip, bot);
	c = mix(c, vec3(1.0), foam);
	// yırtık yan kenarlar
	float rag = vn(vec2(uv.y * 14.0 - t * 2.2, uv.x * 4.0));
	float ed = min(uv.x, 1.0 - uv.x);
	if (ed < 0.05 * rag) discard;
	ALBEDO = c;
	ALPHA = clamp(0.8 + 0.2 * foam + 0.1 * step(0.58, b), 0.0, 1.0) * smoothstep(0.0, 0.05, ed + 0.02);
}
"""

const POOL_SH := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) { vec2 i = floor(p), f = fract(p); vec2 u = f*f*(3.0-2.0*f);
	return mix(mix(hash(i), hash(i+vec2(1,0)), u.x), mix(hash(i+vec2(0,1)), hash(i+vec2(1,1)), u.x), u.y); }
void fragment() {
	// şelalenin dibinden (UV.y küçük taraf) dışa yayılan köpük halkaları
	vec2 q = (UV - vec2(0.5, 0.12)) * vec2(1.0, 1.6);
	float d = length(q);
	float n = vn(UV * 30.0 + vec2(0.0, -TIME * 0.8));
	float ring = smoothstep(0.55, 0.85, fract(d * 9.0 - TIME * 0.45 + n * 0.25));
	float core = 1.0 - smoothstep(0.08, 0.3, d + (n - 0.5) * 0.12);
	float a = max(core, ring * (1.0 - smoothstep(0.25, 0.75, d)) * 0.7);
	a *= smoothstep(0.62, 0.45, d) * (0.6 + 0.4 * n);
	ALBEDO = mix(vec3(0.7, 0.92, 1.0), vec3(1.0), core);
	ALPHA = clamp(a, 0.0, 0.95);
}
"""

const RIVER_SH := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float flow = 0.5;       // akış hızı
uniform float foam_start = 0.0; // UV.y'nin şelaleye yakın ucu (0 ya da 1)
uniform float dir = 1.0;        // akış UV.y artan (1) ya da azalan (-1) yönde
uniform float base_alpha = 0.0; // >0: kendi su yüzeyi (altında su yoksa: üst nehir)
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) { vec2 i = floor(p), f = fract(p); vec2 u = f*f*(3.0-2.0*f);
	return mix(mix(hash(i), hash(i+vec2(1,0)), u.x), mix(hash(i+vec2(0,1)), hash(i+vec2(1,1)), u.x), u.y); }
void fragment() {
	float t = TIME * flow * dir;
	// akışa paralel uzun köpük çizgileri + parlak yüzey pırıltıları
	float l1 = vn(vec2(UV.x * 22.0, UV.y * 6.0 - t * 3.0));
	float l2 = vn(vec2(UV.x * 50.0 + 3.0, UV.y * 12.0 - t * 4.5));
	float line = smoothstep(0.66, 0.8, l1 * 0.6 + l2 * 0.4);
	float glint = smoothstep(0.82, 0.9, vn(vec2(UV.x * 12.0, UV.y * 30.0 - t * 5.0)));
	float near = abs(foam_start - UV.y);
	float churn = (1.0 - smoothstep(0.0, 0.25, near)) * smoothstep(0.35, 0.6, l1);
	float side = smoothstep(0.0, 0.08, UV.x) * smoothstep(1.0, 0.92, UV.x);
	float far = 1.0 - smoothstep(0.85, 1.0, near);
	float a = max(max(line * 0.55, glint * 0.5), churn * 0.85) * side * far;
	float foam = max(max(line, glint), churn);
	// kendi yüzeyi: koyu turkuaz -> akıntı bantları, kenara (şelaleye) yaklaştıkça açılır
	vec3 water = mix(vec3(0.08, 0.42, 0.72), vec3(0.2, 0.62, 0.9), (1.0 - smoothstep(0.0, 0.4, near)) * 0.8 + l2 * 0.2);
	ALBEDO = base_alpha > 0.0 ? mix(water, vec3(0.9, 0.98, 1.0), foam * 0.85) : mix(vec3(0.75, 0.95, 1.0), vec3(1.0), churn);
	ALPHA = base_alpha > 0.0 ? base_alpha * smoothstep(0.0, 0.03, UV.x) * smoothstep(1.0, 0.97, UV.x) * (1.0 - smoothstep(0.75, 1.0, near)) : a;
}
"""

const BOW_SH := """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;
void fragment() {
	// UV.y: dıştan (kırmızı) içe (mor); UV.x: yay boyunca (uçlarda söner)
	float h = UV.y * 0.8;
	vec3 c = clamp(abs(fract(vec3(h) + vec3(0.0, 2.0/3.0, 1.0/3.0)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
	float a = sin(UV.x * 3.14159) * sin(UV.y * 3.14159) * (0.7 + 0.3 * sin(TIME * 0.6));
	ALBEDO = c * 0.35 * a;
}
"""


func _epic_mat(key: String, code: String) -> ShaderMaterial:
	if _epic_mats.has(key):
		return _epic_mats[key]
	var sh = Shader.new()
	sh.code = code
	var m = ShaderMaterial.new()
	m.shader = sh
	_epic_mats[key] = m
	return m


## Kavisli su perdesi: kenardan dışa fırlayıp parabolle düşer, enine öne doğru kavislidir.
## Yerel: x genişlik, y yukarı, +z aşağı akış (öne). Tepe y = h, dip y = 0.
static func _sheet_mesh(w: float, h: float, throw: float, arch: float, back: float) -> ArrayMesh:
	var NU = 28
	var NV = 22
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in NV + 1:
		var v = float(j) / NV
		for i in NU + 1:
			var u = float(i) / NU
			var e = 2.0 * u - 1.0
			var x = e * w * 0.5 * (1.0 + 0.1 * v)
			var bulge = arch * (1.0 - e * e)
			var z = -back + throw * sqrt(v) + bulge * (0.5 + 0.5 * v)
			var y = h * (1.0 - v) + (0.6 if j == 0 else 0.0)
			st.set_uv(Vector2(u, v))
			st.add_vertex(Vector3(x, y, z))
	for j in NV:
		for i in NU:
			var a = j * (NU + 1) + i
			var b = a + NU + 1
			st.add_index(a); st.add_index(b); st.add_index(a + 1)
			st.add_index(a + 1); st.add_index(b); st.add_index(b + 1)
	st.generate_normals()
	return st.commit()


## Gökkuşağı yayı (dikey düzlemde yarım halka)
static func _bow_mesh(r: float, thick: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var N = 40
	for i in N + 1:
		var a = PI * float(i) / N
		var d = Vector3(cos(a), sin(a), 0)
		st.set_uv(Vector2(float(i) / N, 0.0)); st.add_vertex(d * r)
		st.set_uv(Vector2(float(i) / N, 1.0)); st.add_vertex(d * (r - thick))
	for i in N:
		var k = i * 2
		st.add_index(k); st.add_index(k + 1); st.add_index(k + 2)
		st.add_index(k + 2); st.add_index(k + 1); st.add_index(k + 3)
	return st.commit()


func _flat(parent: Node3D, size: Vector2, pos: Vector3, m: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = size
	mi.mesh = pm
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.position = pos
	return mi


func _mist(parent: Node3D, pos: Vector3, ext: Vector3, amount: int, life: float, vel: Vector2, sc: Vector2, alpha: float, out_z: float, grav := 0.0) -> void:
	var p = GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.visibility_aabb = AABB(-ext - Vector3(40, 10, 40), ext * 2.0 + Vector3(80, 140, 140))
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = ext
	pm.direction = Vector3(0, 1, out_z).normalized()
	pm.spread = 35.0
	pm.initial_velocity_min = vel.x
	pm.initial_velocity_max = vel.y
	pm.gravity = Vector3(0, grav, 0)
	pm.damping_min = 0.5
	pm.damping_max = 1.5
	pm.scale_min = sc.x
	pm.scale_max = sc.y
	pm.angle_max = 360.0
	var g = Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.0))
	g.set_color(1, Color(0.9, 0.97, 1.0, 0.0))
	g.add_point(0.15, Color(1, 1, 1, alpha))
	var gt = GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	var sc_c = Curve.new()
	sc_c.add_point(Vector2(0, 0.5))
	sc_c.add_point(Vector2(1, 1.0))
	var sct = CurveTexture.new()
	sct.curve = sc_c
	pm.scale_curve = sct
	p.process_material = pm
	var qm = QuadMesh.new()
	qm.material = FX._draw_mat(FX.tex_smoke, false)
	p.draw_pass_1 = qm
	parent.add_child(p)
	p.position = pos
	p.emitting = true


## Destansı şelale. base: dip (su seviyesi, perdenin önü), height, width; opts:
##   throw (öne fırlama m), arch (kavis m), back (kenarın dibe göre geride kalma mesafesi), river_len (aşağı akış yüzeyi),
##   river_w, upper_len (kenara akan üst nehir yüzeyi), trickles ([[x, genişlik, yükseklik oranı], ...]), sound
func add_epic(base: Vector3, height: float, width: float, opts := {}) -> Node3D:
	var root = Node3D.new()
	add_child(root)
	root.global_position = base
	var throw = float(opts.get("throw", height * 0.12))
	var back = float(opts.get("back", 4.0))
	var arch = float(opts.get("arch", width * 0.05))
	# ana perde + biraz önünde daha seyrek ikinci köpük katmanı (derinlik hissi)
	var sheet = MeshInstance3D.new()
	sheet.mesh = _sheet_mesh(width, height, throw, arch, back)
	sheet.material_override = _epic_mat("sheet", SHEET_SH)
	sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(sheet)
	var veil = MeshInstance3D.new()
	veil.mesh = _sheet_mesh(width * 0.92, height * 0.97, throw * 1.15, arch * 1.2, back - 1.5)
	var vm: ShaderMaterial = _epic_mat("sheet", SHEET_SH).duplicate()
	vm.set_shader_parameter("speed", 1.35)
	vm.set_shader_parameter("streak_x", 23.0)
	veil.material_override = vm
	veil.transparency = 0.45
	veil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(veil)
	# yan sızıntılar: kayalıktan inen ince su şeritleri
	for tr in opts.get("trickles", []):
		var t = MeshInstance3D.new()
		var th = height * float(tr[2])
		t.mesh = _sheet_mesh(float(tr[1]), th, 2.5, 0.6, back + 1.0)
		var tm: ShaderMaterial = _epic_mat("sheet", SHEET_SH).duplicate()
		tm.set_shader_parameter("streak_x", 6.0)
		t.material_override = tm
		t.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(t)
		t.position = Vector3(float(tr[0]), 0, 0)
		_mist(root, Vector3(float(tr[0]), 1.0, 0.0), Vector3(float(tr[1]), 0.5, 2.0), 6, 3.0, Vector2(1, 3), Vector2(4, 8), 0.35, 0.3)
	# dip: köpük halkaları + kabaran sis + ince serpinti + perde ortasından savrulan buğu
	var hit_z = throw - back
	_flat(root, Vector2(width * 1.7, width * 1.1), Vector3(0, 0.25, hit_z + width * 0.42), _epic_mat("pool", POOL_SH))
	_mist(root, Vector3(0, 3.0, hit_z + 4.0), Vector3(width * 0.45, 2.0, 6.0), 34, 7.0, Vector2(3, 9), Vector2(18, 34), 0.55, 0.6)
	_mist(root, Vector3(0, 1.0, hit_z + 2.0), Vector3(width * 0.45, 1.0, 3.0), 70, 1.8, Vector2(9, 20), Vector2(2.5, 5), 0.8, 0.35, -14.0)
	_mist(root, Vector3(0, height * 0.35, hit_z), Vector3(width * 0.4, height * 0.2, 2.0), 14, 6.0, Vector2(1, 3), Vector2(14, 24), 0.25, 1.0)
	# sisin içinde gökkuşağı
	var bow = MeshInstance3D.new()
	bow.mesh = _bow_mesh(width * 0.32, width * 0.05)
	bow.material_override = _epic_mat("bow", BOW_SH)
	bow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(bow)
	bow.position = Vector3(width * 0.12, -2.0, hit_z + 22.0)
	bow.rotation.y = deg_to_rad(-12.0)
	# akan nehir: aşağı akışta (+z) köpük çizgileri; üstte kenara doğru akan akıntı
	var rl = float(opts.get("river_len", 0.0))
	if rl > 0.0:
		var rm: ShaderMaterial = _epic_mat("river", RIVER_SH).duplicate()
		rm.set_shader_parameter("flow", 0.45)
		rm.set_shader_parameter("foam_start", 0.0)   # PlaneMesh UV.y=0 -z ucunda = şelale tarafı
		rm.set_shader_parameter("dir", 1.0)
		_flat(root, Vector2(float(opts.get("river_w", width * 1.2)), rl), Vector3(0, 0.18, hit_z + rl * 0.5), rm)
	var ul = float(opts.get("upper_len", 0.0))
	if ul > 0.0:
		var um: ShaderMaterial = _epic_mat("river", RIVER_SH).duplicate()
		um.set_shader_parameter("flow", 0.8)
		um.set_shader_parameter("foam_start", 1.0)   # +z ucu (UV.y=1) kenarda
		um.set_shader_parameter("dir", 1.0)
		um.set_shader_parameter("base_alpha", 0.95)
		_flat(root, Vector2(float(opts.get("upper_w", width)), ul), Vector3(0, height - 1.2, -back - ul * 0.5), um)
	# uğultu (döngüsel sentez gürültü)
	if opts.get("sound", true) and ResourceLoader.exists("res://assets/sfx/waterfall.wav"):
		var s: AudioStreamWAV = load("res://assets/sfx/waterfall.wav").duplicate()
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = int(s.get_length() * s.mix_rate)
		var ap = AudioStreamPlayer3D.new()
		ap.stream = s
		ap.unit_size = 70.0
		ap.max_distance = 700.0
		ap.volume_db = linear_to_db(maxf(0.001, float(Game.settings.get("sfx", 1.0)) * 0.8))
		ap.autoplay = true
		root.add_child(ap)
		ap.position = Vector3(0, height * 0.2, hit_z)
	return root
