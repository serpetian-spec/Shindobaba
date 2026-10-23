// Kurdele iz (mermi arkası): uç beyaz-sıcak, kuyruğa doğru renk ve incelme; sert kenarlı bantlar. UV.x 0=baş 1=kuyruk.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, blend_mix;

uniform vec4 c_head : source_color = vec4(1.0, 1.0, 0.9, 1.0);
uniform vec4 c_mid : source_color = vec4(1.0, 0.6, 0.15, 1.0);
uniform vec4 c_tail : source_color = vec4(0.7, 0.15, 0.05, 1.0);
uniform float additive = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void fragment() {
	float x = UV.x;
	float v = abs(UV.y * 2.0 - 1.0);
	float n = vn(vec2(x * 8.0 - TIME * 6.0, UV.y * 3.0));
	float width = (1.0 - x) * (0.75 + 0.25 * n);
	if (v > width) discard;
	vec3 c = x < 0.2 ? c_head.rgb : (x < 0.55 ? c_mid.rgb : c_tail.rgb);
	if (v > width * 0.75) c *= 0.75;
	ALBEDO = c * (1.0 + additive);
	ALPHA = COLOR.a * (1.0 - smoothstep(0.8, 1.0, x));
}
