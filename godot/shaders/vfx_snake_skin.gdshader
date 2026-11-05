shader_type spatial;
render_mode cull_back, diffuse_toon, specular_disabled;
// Yılan derisi (Sen'ei Jashu): sırt koyu, karın açık bantlı; sırtta iri pul kalıbı (kenarları koyu çizgi), anime cel gölge.
// UV.x = gövde boyunca metre, UV.y = çevre (0..1, 0.5 = karın)

uniform vec3 back_col : source_color = vec3(0.24, 0.26, 0.17);
uniform vec3 belly_col : source_color = vec3(0.86, 0.8, 0.64);
uniform vec3 line_col : source_color = vec3(0.08, 0.08, 0.05);
uniform float scale_len = 9.0;    // metre başına pul sırası
uniform float scale_around = 7.0;

void fragment() {
	float v = UV.y;
	float w = 1.0 - abs(v - 0.5) * 2.0;   // 1 karın ortası, 0 sırt
	float bel = smoothstep(0.62, 0.68, w);
	// karın: enine bant çizgileri
	float band = abs(fract(UV.x * scale_len * 0.8) - 0.5);
	float belly_line = 1.0 - smoothstep(0.42, 0.47, band);
	// sırt: kaydırılmış sıralarla iri pul (altıgenimsi hücre kenarı)
	vec2 g = vec2(UV.x * scale_len, v * scale_around);
	float row = floor(g.x);
	g.y += mod(row, 2.0) * 0.5;
	vec2 f = fract(g) - 0.5;
	float d = max(abs(f.x) * 1.15 + abs(f.y) * 0.55, abs(f.y));
	float edge = smoothstep(0.40, 0.47, d);
	vec3 back = mix(back_col * (0.92 + 0.16 * (1.0 - d)), line_col, edge * 0.85);
	vec3 belly = mix(belly_col, belly_col * 0.72, belly_line);
	// karın ile sırt arasında ince koyu çizgi (animedeki kontur)
	float seam = 1.0 - smoothstep(0.0, 0.03, abs(w - 0.65));
	ALBEDO = mix(mix(back, belly, bel), line_col, seam * 0.8);
	ROUGHNESS = 0.9;
}
