// Karakter + bina toon shader'ı: 2 bantlı anime gölge, kenar ışığı, vertex renkleri
shader_type spatial;
render_mode cull_back, diffuse_toon, specular_toon;

uniform vec4 tint : source_color = vec4(1.0);
uniform bool use_vertex_color = true;
uniform sampler2D tex : source_color, filter_linear_mipmap, hint_default_white;
uniform float rim_amount = 0.35;
uniform float spec_amount = 0.0;
uniform vec4 emission_color : source_color = vec4(0.0);
uniform float hit_flash = 0.0;
uniform float detail_noise = 0.0;
uniform float sway = 0.0;
uniform bool cloth_mode = false;
uniform bool hide_masked = false;  // vertex alfa=1 olan bölgeler çizilmez (kıyafet altı)   // doku (ten) + vertex rengi (kıyafet, alfa = maske)
uniform bool luma_tint = false;    // saç: doku parlaklığı x tint
uniform bool eye_mode = false;     // göz: iris tint, beyaz korunur
uniform vec4 eye_color : source_color = vec4(0.3, 0.5, 0.9, 1.0);

varying vec3 wpos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void vertex() {
	if (sway > 0.0) {
		vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float k = max(VERTEX.y - 1.5, 0.0);
		float s = sin(TIME * 1.6 + w.x * 0.13 + w.z * 0.09) * sway * k * 0.02;
		VERTEX.x += s;
		VERTEX.z += s * 0.7;
	}
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 tx = texture(tex, UV);
	vec4 c = tint * tx;
	if (luma_tint) {
		float l = dot(tx.rgb, vec3(0.3, 0.59, 0.11));
		c = vec4(tint.rgb * (0.35 + l * 1.3), tx.a);
	}
	if (eye_mode) {
		float l = dot(tx.rgb, vec3(0.3, 0.59, 0.11));
		float sclera = smoothstep(0.55, 0.75, l);
		c = vec4(mix(eye_color.rgb * (0.5 + l * 1.2), tx.rgb, sclera), 1.0);
	}
	if (hide_masked && COLOR.a > 0.5) discard;
	if (cloth_mode) {
		float sl = dot(tx.rgb, vec3(0.3, 0.59, 0.11));
		c.rgb = tint.rgb * (0.55 + sl * 1.5);
		vec3 vc = COLOR.rgb;
		vc = mix(vc / 12.92, pow((vc + 0.055) / 1.055, vec3(2.4)), step(0.04045, vc));
		c.rgb = mix(c.rgb, vc, COLOR.a);
	} else if (use_vertex_color) {
		vec3 vc = COLOR.rgb;
		vc = mix(vc / 12.92, pow((vc + 0.055) / 1.055, vec3(2.4)), step(0.04045, vc));  // sRGB -> lineer
		c *= vec4(vc, COLOR.a);
	}
	if (detail_noise > 0.0) {
		float n = vnoise(wpos.xz * 0.9 + wpos.y * 0.7) * 0.6 + vnoise(wpos.xy * 3.1) * 0.4;
		c.rgb *= 1.0 + (n - 0.5) * detail_noise;
	}
	ALBEDO = mix(c.rgb, vec3(1.0), hit_flash);
	ROUGHNESS = 0.8;
	EMISSION = emission_color.rgb * emission_color.a + vec3(hit_flash) * 0.6;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION += rim * rim_amount * 0.35 * ALBEDO;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float t = smoothstep(-0.03, 0.05, ndl) * 0.6 + smoothstep(0.42, 0.5, ndl) * 0.4;
	float lit = t * ATTENUATION;
	// anime gölgesi: tamamen kararmaz, hafif soğuk tonlu
	vec3 shade = mix(vec3(0.42, 0.44, 0.55), vec3(1.0), lit);
	DIFFUSE_LIGHT += LIGHT_COLOR * shade / PI;
	if (spec_amount > 0.0) {
		vec3 h = normalize(LIGHT + VIEW);
		float s = smoothstep(0.93, 0.96, dot(NORMAL, h));
		SPECULAR_LIGHT += LIGHT_COLOR * s * spec_amount * ATTENUATION;
	}
}
