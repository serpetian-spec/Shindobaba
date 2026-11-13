// Susanoo alev silueti: gövdenin şişirilmiş arka yüz kabuğu; yalnız siluetin dışında görünür, yukarı akan alev dilleri
shader_type spatial;
render_mode unshaded, cull_front, blend_mix, depth_draw_never, fog_disabled;

uniform vec4 col : source_color = vec4(0.55, 0.35, 1.0, 1.0);
uniform vec4 rim_col : source_color = vec4(0.55, 0.35, 1.0, 1.0);
uniform float glow = 1.0;
uniform float flow_speed = 1.0;
uniform float shell = 0.06;      // kabuk kalınlığı (model birimi)
uniform float strength = 1.0;
uniform float ground_y = -100000.0;
uniform float cut_y = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

varying vec3 wp;
varying vec3 rest;
varying vec3 op;
varying float nv;
void vertex() {
	rest = CUSTOM0.xyz;
	op = dot(rest, rest) > 0.000001 ? rest : VERTEX;
	float tt = TIME * flow_speed;
	nv = vnoise(op.xy * 6.0 + vec2(op.z * 4.0, -tt * 1.6)) * 0.65 + vnoise(op.zy * 13.0 + vec2(op.x * 5.0, -tt * 2.6)) * 0.35;
	float push = shell * (0.25 + 1.5 * nv);
	VERTEX += normalize(NORMAL) * push;
	VERTEX.y += push * 0.9;
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (cut_y > 0.0 && rest.y > 0.0001 && rest.y < cut_y) discard;
	if (wp.y < ground_y) discard;
	float tt = TIME * flow_speed;
	float f = vnoise(op.xy * 10.0 + vec2(op.z * 6.0, -tt * 2.8));
	float a = smoothstep(0.38, 0.85, f * 0.55 + nv * 0.65);
	a *= smoothstep(0.05, 0.6, abs(dot(normalize(NORMAL), VIEW)));   // kabuğun dış kenarı köşeli görünmesin: sıyıran açıda söner
	ALBEDO = mix(mix(col.rgb, rim_col.rgb, 0.65), vec3(1.0), 0.15) * (0.95 + 0.25 * glow);
	ALPHA = clamp(a * 0.6 * strength, 0.0, 0.75);
}
