// VRoid parçaları (yüz derisi, saç): anime cel gölge, doku x renk ya da parlaklık x renk (saç boyama), alfa kesme
shader_type spatial;
render_mode cull_back, diffuse_toon, specular_disabled;

uniform sampler2D tex : source_color, filter_linear_mipmap, hint_default_white;
uniform vec4 tint : source_color = vec4(1.0);
uniform int mode = 0;            // 0 doku x tint, 1 parlaklık x tint (saç), 2 düz doku (yüz çizgileri)
uniform float alpha_cut = 0.5;
uniform bool use_alpha = false;  // gerçek saydamlık yerine kesme
uniform float rim_amount = 0.35;
uniform float hit_flash = 0.0;
uniform float shade_floor = 0.62;

void fragment() {
	vec4 tx = texture(tex, UV);
	vec3 c = tx.rgb * tint.rgb;
	if (mode == 1) {
		float l = dot(tx.rgb, vec3(0.3, 0.59, 0.11));
		// saç: dokunun ışık/gölge detayı korunur, renk oyuncunun saç rengi
		c = tint.rgb * (0.45 + l * 1.15);
	} else if (mode == 2) {
		c = tx.rgb;
	}
	if (use_alpha && tx.a < alpha_cut) discard;
	ALBEDO = mix(c, vec3(1.0), hit_flash);
	ROUGHNESS = 1.0;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = rim * rim_amount * 0.3 * ALBEDO + vec3(hit_flash) * 0.6;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float t = smoothstep(-0.02, 0.06, ndl);
	if (LIGHT_IS_DIRECTIONAL) {
		vec3 shade = mix(vec3(shade_floor, shade_floor * 1.02, shade_floor * 1.18), vec3(1.0), t * ATTENUATION);
		DIFFUSE_LIGHT += LIGHT_COLOR * shade / PI;
	} else {
		DIFFUSE_LIGHT += LIGHT_COLOR * (0.35 + 0.65 * t) * ATTENUATION / PI;
	}
}
