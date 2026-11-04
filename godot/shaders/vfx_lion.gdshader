shader_type spatial;
// Jūho Sōshiken aslan kılıfı: yarı saydam mavi chakra, kenarlar ak parlar (anime: açık mavi gövde, beyazımsı kontur), hafif dalgalanma
render_mode unshaded, blend_mix, depth_draw_never, cull_back;

uniform vec4 core : source_color = vec4(0.42, 0.68, 1.0, 0.32);
uniform vec4 rim : source_color = vec4(0.88, 0.96, 1.0, 0.95);
uniform float wobble = 0.025;
uniform float seed = 0.0;

void vertex() {
	float w = sin(TIME * 6.0 + VERTEX.y * 9.0 + seed) * 0.6 + sin(TIME * 9.0 + VERTEX.x * 11.0 + seed * 1.7) * 0.4;
	VERTEX += NORMAL * w * wobble;
}

void fragment() {
	float f = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.2);
	float flick = sin(UV.y * 34.0 - TIME * 7.0 + seed) * 0.04;
	ALBEDO = mix(core.rgb, rim.rgb, f) + vec3(flick);
	ALPHA = clamp(mix(core.a, rim.a, f) + flick, 0.0, 1.0);
}
