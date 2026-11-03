// Rüzgâr kütlesi (ref fuuton2.png, Temari): yarı saydam soluk gri-beyaz gövde, akış yönünde uzanan ve hafif kıvrılan
// yoğun beyaz hız çizgileri; kenarları yumuşak söner. Nesne uzayında +Z = akış.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, blend_mix;

uniform vec4 base_col : source_color = vec4(0.86, 0.9, 0.93, 1.0);
uniform vec4 line_col : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 shade_col : source_color = vec4(0.62, 0.68, 0.72, 1.0);
uniform float speed = 3.0;
uniform float density = 1.0;   // çizgi sıklığı (m başına)
uniform float alpha = 1.0;     // genel görünürlük (sönme)
uniform float reach = 20.0;    // kütle boyu (öne/arkaya sönme)

varying vec3 lp;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void vertex() { lp = VERTEX; }

void fragment() {
	float fres = 1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0);
	float z = lp.z;
	// kıvrılan çizgiler: kesit açısı + akış boyunca yavaş dönen kıvrım
	float ang = atan(lp.y - 2.0, lp.x);
	float curl = ang * 3.0 + sin(z * 0.18 - TIME * 1.4) * 1.4 + z * 0.05;
	float lane = fract(curl * density * 1.6 + vn(vec2(curl * 2.0, z * 0.1)) * 0.6);
	float thin = 1.0 - smoothstep(0.0, 0.08, abs(lane - 0.5));
	// çizgiler parça parça akar (uzun beyaz yalazlar ileri kayar)
	float seg = vn(vec2(floor(curl * density * 1.6) * 7.1, z * 0.12 - TIME * speed * 0.35));
	float lines = thin * smoothstep(0.35, 0.55, seg);
	// gövde: soluk, gölgeli taraf hafif koyu; kenar ve uçlarda söner
	vec3 col = mix(base_col.rgb, shade_col.rgb, smoothstep(0.2, 0.9, fres) * 0.5 + vn(vec2(ang * 2.0, z * 0.2 - TIME)) * 0.15);
	col = mix(col, line_col.rgb, lines);
	float ends = smoothstep(0.0, 0.12, z / max(reach, 0.1)) * (1.0 - smoothstep(0.75, 1.0, z / max(reach, 0.1)));
	float a = (0.32 + lines * 0.65) * (1.0 - smoothstep(0.55, 1.0, fres) * 0.7) * ends * alpha;
	ALBEDO = col;
	ALPHA = clamp(a, 0.0, 1.0);
}
