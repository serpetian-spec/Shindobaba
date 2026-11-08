// 3B alev / duman topağı (Storm): kabarık karnabahar yüzey; ömür sonunda SAYDAMLAŞMAZ, gürültüyle delik delik aşınarak
// yok olur (yarı saydam yuvarlak "bokeh" daireleri kalmasın). Ateş: merkez beyaz-sarı ışır. Duman: üstten aydınlık, alttan gölgeli toon.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, shadows_disabled, blend_mix;
uniform float hot = 1.0;     // 1: ateş, 0: duman/toz
uniform float soft = 0.0;    // 1: sis (yumuşak yarı saydam hacim, aşınma yok)
varying vec3 lp;
varying float seed;
float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float vn(vec3 p) {
	vec3 i = floor(p), f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), u.x), mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), u.x), u.y),
	           mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), u.x), mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), u.x), u.y), u.z);
}
void vertex() {
	seed = float(INSTANCE_ID) * 3.1;
	lp = VERTEX;
	vec3 q = VERTEX * 2.2 + vec3(seed, seed * 0.7, 0.0);
	float w = vn(q + vec3(0.0, TIME * 1.5, 0.0)) * 0.65 + vn(q * 2.3 - vec3(0.0, TIME * 2.0, 0.0)) * 0.35 - 0.5;
	VERTEX += NORMAL * w * 0.34;   // kabarık topak yüzeyi
}
void fragment() {
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float core = smoothstep(0.35, 1.0, ndv);
	vec3 c = COLOR.rgb;
	vec3 col;
	if (hot > 0.5) {
		// yalnız en iç çekirdek sarı-beyaza döner; kenar doygun ve koyu (soluk krem balon değil)
		float inner = smoothstep(0.72, 1.0, ndv);
		col = mix(c * mix(0.7, 1.0, core), vec3(1.0, 0.92, 0.6), inner * 0.45) * (1.0 + inner * 0.25);
	} else {
		float up = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).y;
		col = c * mix(0.72, 1.08, smoothstep(-0.3, 0.6, up));
	}
	// aşınma: COLOR.a ömürle düşer -> eşik yükselir, topak gürültüyle kemirilir (yarı saydamlaşmaz)
	float n = vn(lp * 3.2 + vec3(seed, -TIME * 0.6, seed * 0.4)) * 0.75 + vn(lp * 8.0 + vec3(seed)) * 0.25;
	float rim = smoothstep(0.0, 0.35, ndv);
	float thr = 1.0 - clamp(COLOR.a * 1.15, 0.0, 1.0);
	float vis = smoothstep(thr - 0.05, thr + 0.05, n * 0.7 + rim * 0.3);
	ALBEDO = col;
	ALPHA = vis * smoothstep(0.0, 0.18, ndv) * 0.95;
	if (soft > 0.5) {
		// sis: kenara doğru yumuşakça incelen yarı saydam hacim, gürültülü yoğunluk, ömürle saydamlaşır
		float dens = smoothstep(0.0, 0.75, ndv);
		ALPHA = COLOR.a * dens * dens * (0.45 + 0.55 * n) * 0.6;
	}
}
