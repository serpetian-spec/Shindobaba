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
uniform float iris_r3 = 0.011;
varying vec3 lp;

// Rinnegan: model uzayında göz merkezinden ince, eşit aralıklı halkalar — iris ve göz akı kesintisiz (referans: Sasuke/Nagato)
vec3 rinne_col(vec3 p, vec3 c, float ir) {
	float d = length((p - c).xy);
	float sp = ir * 0.26;
	vec3 col = mix(vec3(0.76, 0.68, 0.92), vec3(0.62, 0.52, 0.84), clamp(d / (ir * 3.0), 0.0, 1.0));
	float f = fract(d / sp);
	float w = fwidth(d / sp) * 0.7 + 0.03;
	float line = 1.0 - smoothstep(w * 0.5, w, min(f, 1.0 - f));
	col = mix(col, vec3(0.2, 0.13, 0.3), line);
	if (d < ir * 0.14) col = vec3(0.05, 0.03, 0.08);
	return col;
}

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
		c = rinne_col(lp, left ? eye_c_l : eye_c_r, iris_r3);
	}
	if (tx.a < 0.5) discard;
	ALBEDO = c;
}
