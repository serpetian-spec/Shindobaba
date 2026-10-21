// Clipmap arazi: yükseklik GPU'da dokudan okunur, anime/toon aydınlatma
shader_type spatial;
render_mode cull_back, diffuse_toon, specular_disabled;

uniform sampler2D heightmap : filter_linear, repeat_disable;
uniform sampler2D albedo_map : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D biome_map : filter_nearest, repeat_disable;
uniform vec4 world_rect; // x0, z0(min z), width, depth (metre)
uniform float level_eps = 0.0;
uniform float texel = 4.0;

varying vec3 wpos;
varying float slope;

float h_at(vec2 xz) {
	vec2 uv = (xz - world_rect.xy) / world_rect.zw;
	return texture(heightmap, uv).r;
}

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = h_at(w.xz);
	float hx = h_at(w.xz + vec2(texel, 0.0)) - h_at(w.xz - vec2(texel, 0.0));
	float hz = h_at(w.xz + vec2(0.0, texel)) - h_at(w.xz - vec2(0.0, texel));
	vec3 n = normalize(vec3(-hx, 2.0 * texel, -hz));
	VERTEX.y = h - level_eps;
	NORMAL = n;
	wpos = vec3(w.x, h, w.z);
	slope = 1.0 - n.y;
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void fragment() {
	vec2 uv = (wpos.xz - world_rect.xy) / world_rect.zw;
	vec3 base = texture(albedo_map, uv).rgb;
	// yakın detay: çim/toprak lekeleri, kaya damarları
	float n1 = vnoise(wpos.xz * 0.35) * 0.6 + vnoise(wpos.xz * 1.7) * 0.4;
	float n2 = vnoise(wpos.xz * 0.05);
	base *= 0.86 + n1 * 0.22 + (n2 - 0.5) * 0.12;
	float rock = smoothstep(0.32, 0.55, slope + (n1 - 0.5) * 0.15);
	vec3 rockc = vec3(0.47, 0.44, 0.40) * (0.85 + n1 * 0.3);
	base = mix(base, rockc, rock);
	// kumsal ıslaklığı
	base *= mix(0.78, 1.0, smoothstep(-0.2, 1.2, wpos.y));
	ALBEDO = base;
	ROUGHNESS = 0.95;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float t = smoothstep(-0.03, 0.05, ndl) * 0.6 + smoothstep(0.42, 0.5, ndl) * 0.4;
	float lit = t * ATTENUATION;
	// anime gölgesi: tamamen kararmaz, hafif soğuk tonlu
	vec3 shade = mix(vec3(0.42, 0.44, 0.55), vec3(1.0), lit);
	DIFFUSE_LIGHT += LIGHT_COLOR * shade / PI;
}
