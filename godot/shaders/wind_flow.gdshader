shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
// Rüzgar chakrası akışı: UV.x boyunca (kökten uca) kayan yumuşak bantlar + yanlarda incelen kenar; hafif dalgalı.
uniform vec4 tint : source_color = vec4(0.75, 1.0, 0.88, 1.0);
uniform float base_alpha = 0.35;
uniform float flow_speed = 2.2;
uniform float bands = 3.0;
uniform float edge_soft = 0.5;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	float a = hash(i), b = hash(i + vec2(1, 0)), c = hash(i + vec2(0, 1)), d = hash(i + vec2(1, 1));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	float u = UV.x;
	float v = UV.y;
	float wob = noise(vec2(u * 6.0 - TIME * flow_speed, v * 3.0 + TIME * 0.7)) * 0.35;
	float band = 0.5 + 0.5 * sin((u * bands - TIME * flow_speed + wob) * 6.2832);
	band = smoothstep(0.25, 1.0, band);
	float edge = smoothstep(0.0, edge_soft, v) * smoothstep(1.0, 1.0 - edge_soft, v);
	float a = base_alpha * (0.35 + 0.65 * band) * edge;
	ALBEDO = mix(tint.rgb, vec3(1.0), band * 0.45);
	ALPHA = clamp(a, 0.0, 1.0);
}
