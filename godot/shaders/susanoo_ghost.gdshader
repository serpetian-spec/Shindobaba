// Susanoo hayalet eti: iskelet kademelerinde kemikleri saran soluk chakra bedeni (derinlik yazmaz, kemiklerin üstüne hafifçe biner)
shader_type spatial;
render_mode unshaded, cull_back, blend_mix, depth_draw_never, fog_disabled;

uniform vec4 col : source_color = vec4(0.55, 0.35, 1.0, 1.0);
uniform vec4 rim_col : source_color = vec4(0.55, 0.35, 1.0, 1.0);
uniform float density = 1.0;
uniform float glow = 1.0;
uniform float flow_speed = 1.0;
uniform float ground_y = -100000.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

varying vec3 wp;
varying vec3 op;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	op = VERTEX;
}

void fragment() {
	if (wp.y < ground_y) discard;
	float rim = pow(1.0 - clamp(abs(dot(normalize(NORMAL), VIEW)), 0.0, 1.0), 2.0);
	float tt = TIME * flow_speed;
	float m = vnoise(op.xy * 6.0 + vec2(op.z * 4.0, -tt * 0.8)) * 0.6 + vnoise(op.zy * 12.0 + vec2(tt * 0.3, -tt * 1.2)) * 0.4;
	ALBEDO = mix(col.rgb, mix(rim_col.rgb, vec3(1.0), 0.5), rim * 0.8) * (0.8 + 0.4 * m);
	ALPHA = clamp((0.1 + 0.14 * m) * density + rim * 0.5 * glow, 0.0, 0.75);
}
