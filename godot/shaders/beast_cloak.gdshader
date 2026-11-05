// Kuyruklu canavar chakra pelerini: vücudu saran, kaynayan, kenarları parlayan chakra
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

uniform vec4 col : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform float grow = 0.06;
uniform float dark = 0.0;      // V2: koyulaşan katman
uniform vec4 dark_col : source_color = vec4(0.35, 0.02, 0.02, 1.0);   // Kurama: kara-kırmızı; diğer canavarlar: kendi chakrasının koyusu
uniform float strength = 1.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

varying vec3 wp;
void vertex() {
	float bub = vnoise(VERTEX.xy * 9.0 + TIME * 2.0) * 0.6 + vnoise(VERTEX.zy * 7.0 - TIME * 1.5) * 0.4;
	VERTEX += NORMAL * grow * (0.7 + bub * 0.8);
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 1.8);
	float flow = vnoise(wp.xz * 3.0 + vec2(0.0, -TIME * 2.5) + wp.y * 2.0) * 0.6 + vnoise(wp.xy * 6.0 - vec2(TIME * 1.2, TIME * 3.0)) * 0.4;
	vec3 c = mix(col.rgb, dark_col.rgb, dark);
	float a = clamp((0.22 + rim * 0.75 + flow * 0.3) * strength, 0.0, 0.92);
	ALBEDO = c * (0.85 + rim * 0.8 + flow * 0.4);
	ALPHA = a;
}
