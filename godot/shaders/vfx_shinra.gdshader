shader_type spatial;
// Shinra Tensei / Banshō Ten'in itme-çekme alanı (referans: Tendō'yu saran neredeyse görünmez, koyu yeşilimsi saydam küre):
// arkasını büken ve hafif yeşile boyayan saydam küre, kenarda yeşil halka.
render_mode unshaded, cull_back, depth_draw_never, blend_mix;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float fade = 1.0;
uniform float bend = 0.035;
uniform vec3 tint = vec3(0.62, 0.8, 0.68);
uniform vec3 rim = vec3(0.3, 0.5, 0.38);
void fragment() {
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	vec2 off = NORMAL.xy * bend * fade * (0.4 + fr);
	vec3 bg = textureLod(screen_tex, SCREEN_UV + off, 0.0).rgb;
	vec3 tinted = bg * mix(vec3(1.0), tint, 0.55 * fade);
	ALBEDO = mix(tinted, rim, fr * 0.55 * fade);
	ALPHA = clamp(fade * 1.2, 0.0, 1.0);
}
