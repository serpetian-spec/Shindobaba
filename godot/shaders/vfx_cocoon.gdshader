shader_type spatial;
render_mode blend_mix, unshaded, cull_back, depth_draw_never;
// Hijutsu: Mushimayu (anime): kullanıcıyı saran yarı saydam, soluk mavi-beyaz ipek koza — kenarları parlar, ipeksi dikey lifler,
// alttan yukarı örülerek kapanır (grow), içindeki kullanıcı görünür.
uniform float grow = 1.0;       // 0..1 örülme (mesh yüksekliği oranı)
uniform float height = 2.0;
uniform float t = 0.0;
uniform vec3 silk : source_color = vec3(0.78, 0.88, 1.0);
uniform vec3 glow : source_color = vec3(0.55, 0.75, 1.0);
varying vec3 lp;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	// kozanın yüzeyi düzgün kabuk değil: ipek demetleri hafif kabarık/çökük
	float a = atan(VERTEX.x, VERTEX.z);
	VERTEX += NORMAL * ((vn(vec2(a * 3.0, VERTEX.y * 2.5)) - 0.5) * 0.09 + sin(a * 9.0 + VERTEX.y * 4.0) * 0.012);
	lp = VERTEX;
}

void fragment() {
	float h01 = (lp.y + height * 0.5) / height;
	float edge = vn(vec2(atan(lp.x, lp.z) * 5.0, t * 0.5)) * 0.08;
	if (h01 > grow + edge) discard;
	float a = atan(lp.x, lp.z);
	// ipek lifleri: çevre boyunca sık, dikeyde uzun çizgiler (hafif sarmal)
	float fib = vn(vec2(a * 22.0 + lp.y * 1.6, lp.y * 1.2 + t * 0.15));
	float fib2 = vn(vec2(a * 55.0 - lp.y * 2.0, lp.y * 3.0));
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
	float top_band = smoothstep(0.08, 0.0, grow - h01) * step(grow, 0.999);   // örülen kenar parlak
	vec3 col = mix(silk, vec3(1.0), fib2 * 0.35);
	col = mix(col, glow, fres * 0.6);
	ALBEDO = col + glow * top_band * 0.6;
	ALPHA = clamp(0.14 + fres * 0.62 + fib * 0.16 + fib2 * 0.08 + top_band * 0.4, 0.0, 0.9);
}
