shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_opaque, diffuse_toon, specular_disabled;
// Bedene sarılan kum katmanı (material_overlay: skinli gövdeyi izler). Ayaktan reveal_h yüksekliğine kadar görünür
// (Sabaku Kyū: boyunda durur, baş dışarıda; Suna no Yoroi: tüm beden). Taneli kum + koyu çatlak çizgileri (anime).
uniform float reveal_h = 0.0;   // mesh kökünden (ayak) görünen yükseklik
uniform float top_h = 9.0;      // en üst sınır (boyun)
uniform float inflate = 0.03;   // bedenin biraz dışında (kalınlık)
uniform float crack = 1.0;      // çatlak yoğunluğu
uniform vec3 sand : source_color = vec3(0.80, 0.67, 0.45);
uniform vec3 dark : source_color = vec3(0.45, 0.34, 0.2);
uniform float selfglow = 0.0;   // kendi başına duran kum kütlesi (Sabaku Fuyū): gölgede kararmasın

varying vec3 wpos;
varying float hloc;

float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float vnoise(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x), mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x), mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}
// hücre kenarı (çatlak)
float cells(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p);
	float d1 = 9.0; float d2 = 9.0;
	for (int x = -1; x <= 1; x++) for (int y = -1; y <= 1; y++) for (int z = -1; z <= 1; z++) {
		vec3 o = vec3(float(x), float(y), float(z));
		vec3 r = o + vec3(hash(i + o), hash(i + o + 7.1), hash(i + o + 3.3)) - f;
		float d = dot(r, r);
		if (d < d1) { d2 = d1; d1 = d; } else if (d < d2) { d2 = d; }
	}
	return sqrt(d2) - sqrt(d1);
}

void vertex() {
	VERTEX += NORMAL * inflate;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	hloc = wpos.y - MODEL_MATRIX[3].y;
}

void fragment() {
	float edge = vnoise(wpos * 6.0) * 0.08;   // yükselen kumun kenarı düz çizgi olmasın
	if (hloc > min(reveal_h, top_h) + edge) discard;
	float g = vnoise(wpos * 40.0) * 0.5 + vnoise(wpos * 9.0) * 0.5;
	vec3 col = sand * (0.82 + 0.3 * g);
	float c = cells(wpos * 7.0);
	col = mix(dark, col, smoothstep(0.0, 0.06 * crack + 0.001, c));
	// üst kenarda koyu nem/akma bandı
	float band = smoothstep(0.12, 0.0, min(reveal_h, top_h) - hloc);
	col = mix(col, dark * 1.2, band * 0.5);
	ALBEDO = col;
	EMISSION = col * selfglow;
	ROUGHNESS = 1.0;
}
