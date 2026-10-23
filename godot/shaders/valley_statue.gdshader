// Sonun Vadisi dev heykelleri ve kanyon duvarları (hayran modeli): taş rengi + katman çizgileri; diğer heykelin parçaları ve
// boyun üstü (orijinal kafa/saç) dünya koordinatında kesilir, yerine kendi taş büstümüz konur
shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_disabled;

uniform vec4 stone : source_color = vec4(0.66, 0.6, 0.52, 1.0);
uniform float x_min = -1e9;
uniform float x_max = 1e9;
uniform float y_cut = 1e9;
uniform float z_min = -1e9;   // kanyon duvarları: şelalenin yukarısı kesilir
uniform float moss = 0.35;   // eteklerde/kıvrımlarda yosun

varying vec3 wp;
varying vec3 wn;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	if (wp.x < x_min || wp.x > x_max || wp.y > y_cut || wp.z < z_min) discard;
	float n = vnoise(wp.xz * 0.08 + wp.y * 0.05) * 0.6 + vnoise(wp.xy * 0.3 + wp.zy * 0.2) * 0.4;
	float strata = 0.5 + 0.5 * sin(wp.y * 0.6 + n * 3.0);
	vec3 c = stone.rgb * (0.84 + n * 0.24) * (0.94 + strata * 0.08);
	// yaşlanma: yukarıdan inen koyu su izleri
	c *= 1.0 - 0.14 * smoothstep(0.6, 0.9, vnoise(vec2(wp.x * 0.12 + wp.z * 0.12, wp.y * 0.015)));
	// yukarı bakan yüzeylerde yeşil yosun lekeleri (asırlık heykel)
	float up = clamp(wn.y, 0.0, 1.0);
	float mm = smoothstep(0.55, 0.8, vnoise(wp.xz * 0.12) * 0.7 + up * 0.5) * moss;
	c = mix(c, vec3(0.32, 0.5, 0.24), mm);
	ALBEDO = c;
	ROUGHNESS = 1.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float t = smoothstep(-0.05, 0.08, ndl) * 0.65 + smoothstep(0.4, 0.5, ndl) * 0.35;
	if (LIGHT_IS_DIRECTIONAL) {
		vec3 shade = mix(vec3(0.3, 0.32, 0.42), vec3(1.05), t * ATTENUATION);
		DIFFUSE_LIGHT += LIGHT_COLOR * shade / PI;
	} else {
		DIFFUSE_LIGHT += LIGHT_COLOR * t * ATTENUATION / PI;
	}
}
