// Storm tarzı şimşek şeridi: keskin beyaz çekirdek + doygun camgöbeği bant (cel, sert kenar) + ince dış hale; titreşir.
// Karışımlı (toplamalı değil): gündüz/kumda beyaza boğulmasın, rengi okunsun. UV.y şeridin eni, UV.x boyu.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, blend_mix;

uniform vec4 col : source_color = vec4(0.45, 0.72, 1.0, 1.0);
uniform float core_w = 0.22;
uniform float intensity = 2.2;

void fragment() {
	float v = abs(UV.y * 2.0 - 1.0);
	float fl = 0.85 + 0.15 * sin(TIME * 90.0 + UV.x * 13.0);
	float lum = dot(col.rgb, vec3(0.3, 0.59, 0.11));
	vec3 sat = clamp(mix(vec3(lum), col.rgb, 1.7), 0.0, 1.0);
	float core = 1.0 - smoothstep(core_w, core_w + 0.14, v);
	float band = 1.0 - smoothstep(0.4, 0.85, v);
	float glow = pow(max(0.0, 1.0 - v), 2.0) * 0.3;
	vec3 c = mix(sat * 0.95, vec3(1.0), core);
	ALBEDO = c * (1.0 + 0.25 * intensity * core) ;
	ALPHA = clamp(max(band, glow) * COLOR.a * fl, 0.0, 1.0);
}
