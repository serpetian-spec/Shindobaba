// Anime rüzgâr perdesi: yumuşak kenarlı, yarı saydam beyaz-mavimsi akış; içinde boyuna akan parlak çizgiler.
// VfxTrail kurdelesine giyilir. UV.x 0=baş 1=kuyruk, UV.y enine. Sert kenar / geometrik kabuk görünmez.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, blend_mix;

uniform vec4 tint : source_color = vec4(0.86, 0.95, 1.0, 1.0);
uniform vec4 line_col : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float opacity = 0.55;
uniform float lines = 9.0;
uniform float speed = 5.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void fragment() {
	float x = UV.x;
	float y = UV.y * 2.0 - 1.0;
	// perde kuyruğa doğru incelir, kenarları dalgalı ve yumuşak
	float wob = (vn(vec2(x * 5.0 - TIME * speed * 0.6, 3.1)) - 0.5) * 0.35;
	float half_w = mix(1.0, 0.25, x);
	float v = abs(y - wob) / half_w;
	if (v > 1.0) discard;
	float edge = 1.0 - smoothstep(0.35, 1.0, v);
	// boyuna akan çizgiler (anime hız/akım çizgisi)
	float l = vn(vec2(x * 2.5 - TIME * speed, (y - wob) * lines));
	float streak = smoothstep(0.55, 0.85, l);
	// baş yumuşak açılır, kuyruk söner
	float fade = smoothstep(0.0, 0.08, x) * (1.0 - smoothstep(0.45, 1.0, x));
	vec3 c = mix(tint.rgb, line_col.rgb, streak);
	ALBEDO = c;
	ALPHA = COLOR.a * opacity * fade * edge * (0.35 + 0.65 * streak) * tint.a;
}
