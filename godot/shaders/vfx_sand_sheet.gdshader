shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_disabled;
// Kūsa Bōheki: havada süzülen kalın, kenarları yırtık kum tabakası (anime: köyün üstüne yayılan kum kalkanı). Kubbe değil.
uniform float t = 0.0;
uniform float spread = 1.0;      // 0..1 açılma (kenar yırtığı içeri/dışarı)
uniform vec3 sand : source_color = vec3(0.80, 0.67, 0.45);
uniform vec3 dark : source_color = vec3(0.5, 0.38, 0.24);
varying vec3 lp;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	vec2 q = VERTEX.xz;
	float r2 = dot(q, q);
	// kenarlar aşağı kıvrılır, yüzey dalgalanır (kum akıyor)
	VERTEX.y += -r2 * 0.05 + (vn(q * 0.8 + t * 0.6) - 0.5) * 0.6 + (vn(q * 2.3 - t) - 0.5) * 0.2;
	lp = VERTEX;
}

void fragment() {
	vec2 q = lp.xz / 3.6;
	float r = length(q) + (vn(lp.xz * 1.3 + t * 0.4) - 0.5) * 0.35;
	if (r > spread) discard;
	float g = vn(lp.xz * 9.0 + t) * 0.6 + vn(lp.xz * 31.0) * 0.4;
	vec3 col = sand * (0.8 + 0.3 * g);
	col = mix(col, dark, smoothstep(spread - 0.12, spread, r) * 0.6);   // yırtık kenar koyu
	if (!FRONT_FACING) col *= 0.88;   // alt yüz biraz koyu
	ALBEDO = col;
	EMISSION = col * 0.35;   // kum gölgede de açık renk kalır (alt yüz simsiyah görünüyordu)
	ROUGHNESS = 1.0;
}
