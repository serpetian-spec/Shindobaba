// Kalın şimşek şeridi: sert beyaz çekirdek + renkli bant + dış parıltı; titreşir. UV.y şeridin eni, UV.x boyu.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, blend_add;

uniform vec4 col : source_color = vec4(0.45, 0.72, 1.0, 1.0);
uniform float core_w = 0.26;
uniform float intensity = 2.2;

void fragment() {
	float v = abs(UV.y * 2.0 - 1.0);
	float fl = 0.8 + 0.2 * sin(TIME * 90.0 + UV.x * 13.0);
	float core = 1.0 - smoothstep(core_w, core_w + 0.06, v);
	float band = 1.0 - smoothstep(0.55, 0.62, v);
	float glow = pow(1.0 - v, 2.0);
	vec3 c = vec3(1.0) * core * 1.6 + col.rgb * band * 0.9 + col.rgb * glow * 0.6;
	ALBEDO = c * mix(1.0, intensity, 0.6) * fl * COLOR.a;   // parlama kısık
}
