// Hazır modeller (ağaç, kaya, bina, aksesuar) için anime ışığı: doku + renk, 2 bantlı gölge, kenar ışığı.
// cutout: yaprak/çimen kartları (alfa kesimi, iki yüz), sway: rüzgarda sallanma (yüksekliğe göre)
shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_disabled;

uniform sampler2D tex : source_color, filter_linear_mipmap_anisotropic, hint_default_white;
uniform vec4 tint : source_color = vec4(1.0);
uniform bool cutout = false;
uniform float alpha_cut = 0.45;
uniform float sway = 0.0;
uniform float sway_h = 6.0;        // bu yükseklikte tam sallanma (model birimi)
uniform float rim_amount = 0.25;
uniform float saturation = 1.15;   // anime renkleri: hafif doygunluk artışı
uniform float vary = 0.12;         // dünya konumuna göre ton çeşitliliği (her ağaç biraz farklı)
uniform bool use_instance_color = true;
uniform vec2 uv_scale = vec2(1.0);

varying vec3 wpos;
varying vec3 inst_col;

float hash(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }   // sinüssüz: büyük koordinatta bloklaşmaz

void vertex() {
	vec3 origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	if (sway > 0.0) {
		float k = clamp(VERTEX.y / sway_h, 0.0, 1.0);
		k = k * k;
		float ph = TIME * 1.3 + origin.x * 0.11 + origin.z * 0.07;
		float s = (sin(ph) * 0.7 + sin(ph * 2.3 + VERTEX.x) * 0.3) * sway * k;
		VERTEX.x += s;
		VERTEX.z += s * 0.6;
	}
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	inst_col = use_instance_color ? COLOR.rgb : vec3(1.0);
	// ton çeşitliliği nesne başına sabit (köke göre)
	float h = hash(floor(origin.xz * 0.5));
	inst_col *= 1.0 + (h - 0.5) * vary;
}

void fragment() {
	vec4 t = texture(tex, UV * uv_scale);
	vec3 c = t.rgb * tint.rgb * inst_col;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	ALBEDO = c;
	ROUGHNESS = 0.9;
	if (cutout) {
		ALPHA = t.a * tint.a;
		ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	}
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 3.0);
	EMISSION = rim * rim_amount * 0.3 * ALBEDO;
	// bozuk piksel güvenliği: geçersiz (NaN / sonsuz) renk ya da sıfır normal ekran efektlerinde (ortam gölgesi, bulanıklık) siyah karelere büyür
	if (any(isnan(ALBEDO)) || any(isinf(ALBEDO))) ALBEDO = vec3(0.4);
	if (any(isnan(EMISSION)) || any(isinf(EMISSION))) EMISSION = vec3(0.0);
	if (!(dot(NORMAL, NORMAL) > 1e-8)) NORMAL = vec3(0.0, 0.0, 1.0);
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	if (cutout) {
		ndl = abs(ndl) * 0.8 + 0.2;  // yaprak kartları: arkadan da aydınlık
	}
	float t = smoothstep(-0.03, 0.05, ndl) * 0.6 + smoothstep(0.42, 0.5, ndl) * 0.4;
	float lit = t * ATTENUATION;
	if (LIGHT_IS_DIRECTIONAL) {
		vec3 shade = mix(vec3(0.29, 0.32, 0.45), vec3(1.0), lit);
		DIFFUSE_LIGHT += LIGHT_COLOR * shade / PI;
	} else {
		DIFFUSE_LIGHT += LIGHT_COLOR * (0.35 + 0.65 * t) * ATTENUATION / PI;
	}
}
