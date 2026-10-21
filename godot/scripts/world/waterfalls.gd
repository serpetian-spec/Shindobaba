extends Node
## Şelaleler (kayan su dokusu + köpük parçacıkları) ve kaplıca buharı.

var mat: ShaderMaterial


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
