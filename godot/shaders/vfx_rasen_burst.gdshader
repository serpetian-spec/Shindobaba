shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, shadows_disabled, blend_mix;
// Rasenshuriken genişlemesi (anime ref Blast.PNG / RasenExpansion.PNG): hedefi içine alan dev beyaz küre;
// yüzeyi fırça darbesi gibi yatay kıvrılan beyaz şeritler (milyonlarca mikro rüzgâr bıçağı), aralardan soluk gri-mavi.
// Silüet düz kabuk değil: kenarı gürültüyle dağılır ve dışa doğru söner.
uniform float t = 0.0;
uniform float alpha = 1.0;
uniform vec3 white : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 shade : source_color = vec3(0.8, 0.84, 0.9);
varying vec3 lp;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	vec3 n = normalize(VERTEX);
	float a = atan(n.x, n.z);
	VERTEX += NORMAL * (vn(vec2(a * 3.0 + t * 4.0, n.y * 4.0)) - 0.5) * 0.08;
	lp = VERTEX;
}

void fragment() {
	vec3 n = normalize(lp);
	float a = atan(n.x, n.z);
	// yatay sarmal şeritler: enlem boyunca, boylamla kıvrılarak hızla döner
	float band = n.y * 7.0 + sin(a * 2.0 + t * 3.0) * 0.6;
	float swirl = a * 1.0 - t * 9.0 + n.y * 2.5;
	float stroke = vn(vec2(swirl * 2.0, band)) * 0.65 + vn(vec2(swirl * 6.0, band * 2.5)) * 0.35;
	float lines = smoothstep(0.45, 0.62, stroke);
	float fres = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	vec3 col = mix(shade, white, clamp(lines + 0.35 - fres * 0.2, 0.0, 1.0));
	// kenar dağınık söner (düz kabuk sınırı görünmez)
	float edge = 1.0 - smoothstep(0.72, 1.0, fres + (vn(vec2(a * 5.0 + t * 5.0, n.y * 5.0)) - 0.5) * 0.35);
	ALBEDO = col;
	ALPHA = clamp((0.92 + lines * 0.08) * edge * alpha, 0.0, 0.96);
}
