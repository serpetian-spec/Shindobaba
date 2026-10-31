shader_type spatial;
// Anime buzu: saydam açık camgöbeği gövde, yüz yüz değişen ton (kristal yüzeyleri okunur),
// kenarlarda beyaz fresnel ve çapraz beyaz parlama çizgileri. Kar gibi opak beyaz değil.
render_mode blend_mix, depth_draw_always, cull_back, specular_schlick_ggx;

uniform vec4 light_col : source_color = vec4(0.80, 0.95, 1.0, 1.0);
uniform vec4 deep_col : source_color = vec4(0.22, 0.52, 0.82, 1.0);
uniform float alpha = 0.62;
uniform float streak = 1.0;
uniform float glow = 0.55;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
	// yüzey tonu: ışığa bakan üst yüzler açık, yan/alt yüzler koyu mavi (cel basamaklı)
	float up = dot(wn, normalize(vec3(0.35, 1.0, 0.25))) * 0.5 + 0.5;
	float band = floor(up * 3.0) / 3.0;
	vec3 col = mix(deep_col.rgb, light_col.rgb, 0.25 + 0.75 * band);
	col *= COLOR.rgb;
	// çapraz beyaz parlama çizgileri (anime buz aynası / buz kristali)
	float s = (wpos.x * 0.8 + wpos.y * 1.4 + wpos.z * 0.6) * 1.6;
	float f = fract(s);
	float st = (smoothstep(0.0, 0.04, f) - smoothstep(0.08, 0.12, f)) + (smoothstep(0.2, 0.22, f) - smoothstep(0.24, 0.26, f)) * 0.6;
	st *= streak * (0.4 + 0.6 * band);
	col = mix(col, vec3(1.0), clamp(fres * 0.9 + st * 0.8, 0.0, 1.0));
	ALBEDO = col * (1.0 - glow);
	EMISSION = col * glow;
	ROUGHNESS = 0.08;
	SPECULAR = 0.9;
	ALPHA = clamp(alpha * COLOR.a + fres * 0.35 + st * 0.3, 0.0, 1.0);
}
