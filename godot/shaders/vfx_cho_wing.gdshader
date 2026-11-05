shader_type spatial;
// Akimichi Kelebek Modu kanadı (anime ref): yarı saydam açık camgöbeği chakra yüzeyi, içinde akan koyu mavi alev lekeleri,
// parlak beyazımsı kenar. UV.y = kenar katsayısı (0 kök/merkez .. 1 kenar), UV.x = kenar boyunca konum.
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, shadows_disabled;

uniform vec4 base_col : source_color = vec4(0.3, 0.72, 1.0, 1.0);
uniform vec4 deep_col : source_color = vec4(0.04, 0.18, 0.85, 1.0);
uniform vec4 edge_col : source_color = vec4(0.9, 0.98, 1.0, 1.0);
uniform float opacity = 0.92;

varying vec3 lp;

void vertex() {
	lp = VERTEX;
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	float e = UV.y;
	// alev dilleri (anime): kökten kenara uzanan, yukarı akan, uzun koyu mavi lekeler — 3 katlı yumuşak gürültü (köşeli blok olmasın)
	vec2 q = vec2(lp.x * 1.1, lp.y * 0.55);
	float fl = 0.0;
	float amp = 0.55;
	vec2 qq = q + vec2(0.0, -TIME * 0.35);
	for (int i = 0; i < 3; i++) {
		fl += noise(qq) * amp;
		qq = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * qq * 2.1 + vec2(1.7, -TIME * 0.2);
		amp *= 0.5;
	}
	float streak = smoothstep(0.46, 0.6, fl);
	vec3 c = mix(base_col.rgb, deep_col.rgb, streak * smoothstep(0.05, 0.4, e) * (1.0 - smoothstep(0.85, 0.97, e)));
	// parlak kenar ve kökte yoğun parıltı
	float rim = smoothstep(0.8, 0.98, e);
	c = mix(c, edge_col.rgb, rim);
	c += vec3(0.25, 0.3, 0.35) * (1.0 - smoothstep(0.0, 0.25, e));
	float flick = 0.9 + 0.1 * sin(TIME * 9.0 + lp.x * 4.0);
	ALBEDO = c * 1.12;
	ALPHA = clamp(opacity * (0.72 + rim * 0.28) * flick * (1.0 - smoothstep(0.985, 1.0, e) * 0.6), 0.0, 1.0);
}
