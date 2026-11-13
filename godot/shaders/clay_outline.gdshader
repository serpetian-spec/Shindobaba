shader_type spatial;
// Kil figürlerinin anime dış çizgisi: ters kabuk (ön yüzler atılır), normale doğru ekranda sabit kalınlıkta şişirilir
render_mode unshaded, cull_front, shadows_disabled;
uniform vec4 line_color : source_color = vec4(0.42, 0.47, 0.5, 1.0);
uniform float width = 0.0022;

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float d = clamp(distance(wp, CAMERA_POSITION_WORLD), 2.0, 160.0);
	float sc = length(MODEL_MATRIX[0].xyz);
	VERTEX += NORMAL * width * d / max(sc, 0.001);
}

void fragment() {
	ALBEDO = line_color.rgb;
}
