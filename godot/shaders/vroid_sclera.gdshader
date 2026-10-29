// VRoid göz akı: dōjutsu tüm gözü kaplayınca (Rinnegan) göz akı da boyanır; iki göz ayrı (model uzayı x işareti)
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;

uniform sampler2D tex : source_color, filter_linear_mipmap, hint_default_white;
uniform vec4 tint_r : source_color = vec4(1.0);   // sağ göz (model -x)
uniform vec4 tint_l : source_color = vec4(1.0);   // sol göz (model +x)
uniform float rings_r = 0.0;
uniform float rings_l = 0.0;
uniform vec3 eye_c_r = vec3(-0.032, 1.62, 0.08);
uniform vec3 eye_c_l = vec3(0.032, 1.62, 0.08);
varying vec3 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	vec4 tx = texture(tex, UV);
	bool left = lp.x > 0.0;
	vec3 t = left ? tint_l.rgb : tint_r.rgb;
	float rg = left ? rings_l : rings_r;
	vec3 c = tx.rgb * t;
	if (rg > 0.5) {
		// Rinnegan: göz akına taşan eşmerkezli halkalar
		float r = length((lp - (left ? eye_c_l : eye_c_r)).xy) / 0.011;
		if (abs(fract(r * 0.5) - 0.5) < 0.08) c = vec3(0.2, 0.12, 0.28);
	}
	if (tx.a < 0.5) discard;
	ALBEDO = c;
}
