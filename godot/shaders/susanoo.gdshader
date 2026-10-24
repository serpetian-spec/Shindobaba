// Susanoo: yarı saydam, kenarları parlayan, içinde alev gibi akan chakra
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;

uniform vec4 col : source_color = vec4(0.55, 0.35, 1.0, 1.0);
uniform vec4 rim_col : source_color = vec4(0.55, 0.35, 1.0, 1.0);   // kenar rengi (iki tonlu Susanoo)
uniform float density = 1.0;     // iç dolgu yoğunluğu (0.3 hayalet .. 2 dolu)
uniform float glow = 1.0;        // kenar parlaklığı
uniform float flow_speed = 1.0;  // içindeki chakra alevinin akış hızı
uniform float cut_y = 0.0;   // >0: dinlenme pozunda bu yüksekliğin altı çizilmez (üst gövde kademesi)

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

varying vec3 wp;
varying vec3 rest;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	rest = CUSTOM0.xyz;
}

void fragment() {
	if (cut_y > 0.0 && rest.y > 0.0001 && rest.y < cut_y) discard;
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.2);
	float tt = TIME * flow_speed;
	float flow = vnoise(wp.xz * 0.6 + vec2(0.0, -tt * 1.4) + wp.y * 0.4) * 0.6 + vnoise(wp.xy * 1.7 - vec2(tt * 0.8, tt * 2.0)) * 0.4;
	float a = (0.12 + flow * 0.18) * density + rim * 0.75 * glow;
	vec3 base = mix(col.rgb, rim_col.rgb, clamp(rim * 1.3, 0.0, 1.0));
	ALBEDO = base * (0.5 + rim * 1.6 * glow + flow * 0.5) * a;
}
