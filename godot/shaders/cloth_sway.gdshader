// Rüzgârda sallanan kumaş/fener: mesh'in tepesi (y=0) sabit, aşağısı salınır. Toon ışık + gece parıltısı.
shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_disabled;

uniform float amp = 0.25;        // en alttaki salınım (m)
uniform float hang = 2.0;        // asılı uzunluk (m): bu derinlikte tam salınım
uniform float speed = 1.7;
uniform float glow = 0.0;        // 0..1 gece parıltısı (vertex rengi ile)
uniform float glow_only_alpha = 0.0; // 1: sadece alfası 1 olan köşeler parlar (fener gövdesi)

varying float g_mask;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float k = clamp(-VERTEX.y / hang, 0.0, 1.0);
	k = max(k - 0.35 * step(1.5, hang), 0.0);  // fener dizisi: ip kısmı sabit
	k = k * k;
	float ph = TIME * speed + w.x * 0.21 + w.z * 0.17 + (VERTEX.x + VERTEX.z) * 0.9;
	VERTEX.x += sin(ph) * amp * k;
	VERTEX.z += sin(ph * 0.77 + 1.3) * amp * 0.6 * k;
	g_mask = mix(1.0, COLOR.a, glow_only_alpha);
}

void fragment() {
	vec3 c = COLOR.rgb;
	c = mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
	ALBEDO = c;
	ROUGHNESS = 0.9;
	EMISSION = c * glow * g_mask * 1.6;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float t = smoothstep(-0.05, 0.08, abs(ndl)) * 0.7 + 0.3;
	if (LIGHT_IS_DIRECTIONAL) {
		DIFFUSE_LIGHT += LIGHT_COLOR * mix(vec3(0.45, 0.47, 0.58), vec3(1.0), t * ATTENUATION) / PI;
	} else {
		DIFFUSE_LIGHT += LIGHT_COLOR * t * ATTENUATION / PI;
	}
}
