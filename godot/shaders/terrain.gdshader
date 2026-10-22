// Clipmap arazi: yükseklik GPU'da dokudan okunur. Anime/boyalı yüzeyler: çimen lekeleri, katmanlı kaya, kum dalgası, yol.
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
varying vec3 wnrm;

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
	wnrm = n;
	wpos = vec3(w.x, h, w.z);
	slope = 1.0 - n.y;
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) { float s = 0.0, a = 0.5; for (int i = 0; i < 4; i++) { s += vnoise(p) * a; p *= 2.07; a *= 0.5; } return s; }

void fragment() {
	vec2 uv = (wpos.xz - world_rect.xy) / world_rect.zw;
	vec3 base = texture(albedo_map, uv).rgb;
	vec4 bio = texture(biome_map, uv);
	int b = int(bio.r * 255.0 + 0.5);
	float n1 = fbm(wpos.xz * 0.08);
	float n2 = vnoise(wpos.xz * 0.9);
	float n3 = vnoise(wpos.xz * 4.0);
	// boyalı çimen: büyük açık/koyu lekeler + sarımsı çiçekli alanlar
	if (b == 2 || b == 7 || b == 6 || b == 11 || b == 4 || b == 10) {
		float patch = smoothstep(0.38, 0.62, n1);
		base *= mix(0.82, 1.14, patch);
		base = mix(base, base * vec3(1.12, 1.08, 0.7), smoothstep(0.7, 0.85, fbm(wpos.xz * 0.03 + 7.0)) * 0.6);
		base *= 0.93 + n3 * 0.12;
	}
	// kum: rüzgar dalgaları
	if (b == 3 || b == 1) {
		float rip = sin(wpos.x * 1.6 + wpos.z * 0.7 + n1 * 6.0) * 0.5 + 0.5;
		base *= 0.92 + rip * 0.1 + n2 * 0.06;
	}
	// çöl köyü: sıkıştırılmış kum, hafif dalga
	if (b == 13) {
		float rip = sin(wpos.x * 1.1 + wpos.z * 0.5 + n1 * 5.0) * 0.5 + 0.5;
		base *= 0.93 + rip * 0.06 + n2 * 0.06;
	}
	// taş köy (Kiri/Iwa/Kumo): taş döşeme
	if (b == 14) {
		vec2 tt = wpos.xz / 1.7;
		tt.x += step(0.5, fract(tt.y * 0.5)) * 0.5;
		vec2 f = abs(fract(tt) - 0.5);
		float joint = smoothstep(0.45, 0.49, max(f.x, f.y));
		base *= (0.9 + hash(floor(tt)) * 0.18) * (1.0 - joint * 0.4);
	}
	if (b == 15) {
		base = mix(base, vec3(1.0), 0.1) + step(0.985, n3) * 0.2;
	}
	// kar parıltısı
	if (b == 8) {
		base = mix(base, vec3(1.0), 0.15) + step(0.985, n3) * 0.25;
	}
	// yol: keskin kenarlı toprak + tekerlek izleri
	float road = smoothstep(0.35, 0.6, bio.g + (n2 - 0.5) * 0.25);
	vec3 dirt = vec3(0.74, 0.56, 0.36) * (0.85 + n3 * 0.2);
	base = mix(base, dirt, road * 0.92);
	// yarlar: katmanlı kaya (yüksekliğe göre tabaka bantları)
	float rock = smoothstep(0.3, 0.5, slope + (n2 - 0.5) * 0.18);
	float strata = sin(wpos.y * 0.9 + n1 * 3.0) * 0.5 + 0.5;
	float strata2 = sin(wpos.y * 3.1 + n2 * 2.0) * 0.5 + 0.5;
	vec3 rockc = mix(vec3(0.45, 0.4, 0.36), vec3(0.62, 0.55, 0.47), strata);
	if (b == 3 || b == 5) rockc = mix(vec3(0.62, 0.42, 0.3), vec3(0.8, 0.6, 0.42), strata);
	rockc *= 0.85 + strata2 * 0.2;
	rockc *= mix(0.75, 1.0, smoothstep(0.0, 0.15, abs(fract(wpos.y * 0.25 + n1) - 0.5)));
	base = mix(base, rockc, rock);
	// sahil ıslaklığı
	base *= mix(0.72, 1.0, smoothstep(-0.2, 1.4, wpos.y));
	// anime canlılığı: doygunluğu artır
	float lum = dot(base, vec3(0.299, 0.587, 0.114));
	base = max(mix(vec3(lum), base, 1.12), vec3(0.0));
	ALBEDO = base;
	ROUGHNESS = 0.95;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float t = smoothstep(-0.03, 0.05, ndl) * 0.6 + smoothstep(0.42, 0.5, ndl) * 0.4;
	if (LIGHT_IS_DIRECTIONAL) {
		// anime gölgesi: soğuk, doygun; tamamen kararmaz
		vec3 shade = mix(vec3(0.5, 0.52, 0.7), vec3(1.0), t * ATTENUATION);
		DIFFUSE_LIGHT += LIGHT_COLOR * shade / PI;
	} else {
		// fener/omni: taban gölge eklenmez (yoksa küme hücreleri kare kare yanar)
		DIFFUSE_LIGHT += LIGHT_COLOR * (0.35 + 0.65 * t) * ATTENUATION / PI;
	}
}
