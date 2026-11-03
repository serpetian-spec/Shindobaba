shader_type spatial;
// Anime ağaç yaprak kartları (AnimeTree): yaprak öbeği atlası (R = yaprak parlaklığı, A = kesme), köşe rengi = öbeğin tonu
// (taç üstü açık, altı koyu; MultiMesh örnek rengi de çarpılır: yanık/kararmış ağaç). Normal taç merkezinden dışa: kütle gölgesi.
// Rüzgâr: toon.gdshader "sway" ile AYNI formül (gövde ve yapraklar birlikte salınır) + yaprak titreşimi.
render_mode cull_disabled, diffuse_toon, specular_disabled;

uniform sampler2D leaf_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform float alpha_cut = 0.5;
uniform float sway = 1.0;
uniform float flutter = 1.0;
uniform vec3 shadow_tint = vec3(0.5, 0.58, 0.62);
global uniform float g_night;

void vertex() {
	if (sway > 0.0) {
		vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float k = max(VERTEX.y - 1.5, 0.0);
		float ph = w.x * 0.13 + w.z * 0.09;
		float gust = 0.6 + 0.4 * sin(TIME * 0.35 + ph * 0.5);
		float s = (sin(TIME * 1.3 + ph) * 0.7 + sin(TIME * 2.9 + ph * 1.7) * 0.3) * sway * k * 0.026 * gust;
		float fl = sin(TIME * 7.0 + w.x * 1.9 + w.y * 2.3 + w.z * 1.3) * sway * 0.035 * smoothstep(2.5, 5.0, k);
		// yaprak kartı titreşimi: kartın köşeleri kendi içinde hafifçe dalgalanır (öbek nefes alır)
		float lf = sin(TIME * 3.1 + w.x * 0.7 + w.z * 0.9 + UV.x * 6.0) * 0.06 * flutter * smoothstep(1.0, 4.0, k);
		VERTEX.x += s + fl + lf;
		VERTEX.z += s * 0.7 - fl * 0.6 + lf * 0.6;
		VERTEX.y += fl * 0.5 + lf * 0.3;
	}
}

void fragment() {
	vec4 t = texture(leaf_tex, UV);
	if (t.a < alpha_cut) discard;
	// yaprak parlaklığı tona çarpılır: açık yapraklar canlı sarı-yeşile, koyular derin yeşile kayar
	float b = t.r;
	vec3 vc = COLOR.rgb;
	vc = mix(vc / 12.92, pow((vc + 0.055) / 1.055, vec3(2.4)), step(0.04045, vc));   // sRGB -> lineer (yoksa soluk/beyazımsı)
	vec3 c = vc * mix(0.55, 1.2, b);
	c = mix(c, c * vec3(1.06, 1.08, 0.86), smoothstep(0.75, 1.0, b) * 0.6);
	ALBEDO = c * (1.0 - g_night * 0.35);
	ROUGHNESS = 0.02;   // çizgi efekti yaprak kartlarının içine karalama çizmesin (çimen gibi)
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	// iki keskin bant: güneşli yüz / yarı gölge / öbek altı (anime boyama)
	float t = smoothstep(-0.25, -0.15, ndl) * 0.45 + smoothstep(0.25, 0.35, ndl) * 0.55;
	float lit = t * mix(0.55, 1.0, ATTENUATION);
	if (LIGHT_IS_DIRECTIONAL) {
		vec3 shade = mix(shadow_tint, vec3(1.0), lit);
		DIFFUSE_LIGHT += LIGHT_COLOR * shade / PI;
	} else {
		DIFFUSE_LIGHT += LIGHT_COLOR * (0.35 + 0.65 * t) * ATTENUATION / PI;
	}
}
