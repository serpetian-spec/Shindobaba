shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, shadows_disabled, blend_mix;
// Düşman başının üstündeki can barı: kameraya dönük dörtgen; sol taraf (fill oranı) dolu renk, kalanı koyu, ince kenar.
uniform float fill = 1.0;
uniform float lag = 1.0;           // az önce kaybedilen can (açık renk iz)
uniform vec4 col : source_color = vec4(0.9, 0.2, 0.18, 1.0);
uniform float alpha = 1.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 uv = UV;
	float border = step(uv.x, 0.012) + step(0.988, uv.x) + step(uv.y, 0.1) + step(0.9, uv.y);
	vec3 c = vec3(0.08, 0.07, 0.08);
	if (uv.x < lag) c = vec3(0.95, 0.85, 0.75);
	if (uv.x < fill) c = col.rgb * (0.85 + 0.3 * (1.0 - uv.y));
	if (border > 0.0) c = vec3(0.02);
	ALBEDO = c;
	ALPHA = alpha;
}
