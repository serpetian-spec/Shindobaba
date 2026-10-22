// Kayaya oyulmuş dev yüzler (Hokage Kayası): taş rengi, katman çizgileri, anime gölgesi; boyun altı çizilmez
shader_type spatial;
render_mode cull_back, diffuse_toon, specular_disabled;

uniform vec4 stone : source_color = vec4(0.66, 0.6, 0.52, 1.0);
uniform float cut_world_y = -1e9;

varying vec3 wp;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (wp.y < cut_world_y) discard;
	float n = vnoise(wp.xz * 0.08 + wp.y * 0.05) * 0.6 + vnoise(wp.xy * 0.35) * 0.4;
	float strata = 0.5 + 0.5 * sin(wp.y * 0.9 + n * 3.0);
	vec3 c = stone.rgb * (0.86 + n * 0.22) * (0.94 + strata * 0.08);
	// yaşlanma: yukarıdan inen hafif koyu lekeler
	c *= 1.0 - 0.12 * smoothstep(0.6, 0.9, vnoise(vec2(wp.x * 0.15, wp.y * 0.02)));
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
