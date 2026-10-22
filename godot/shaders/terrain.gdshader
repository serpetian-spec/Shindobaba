// Clipmap arazi: yükseklik GPU'da makro harita + ayrıntı gürültüsünden hesaplanır (world_height.gdshaderinc).
// Anime/boyalı yüzeyler: çimen lekeleri, katmanlı kaya, kum dalgası, yol (oyuncu çevresindeki yerel yol dokusundan).
shader_type spatial;
render_mode cull_back, diffuse_toon, specular_disabled;

#include "res://shaders/world_height.gdshaderinc"

uniform sampler2D albedo_map : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D road_tex : filter_linear, repeat_disable;   // oyuncu çevresindeki yollar (R) - RoadMap düğümü çizer
uniform vec4 road_rect;                                         // x0, z0, boyut, -
uniform vec4 villages[16];                                      // x, z, yarıçap, zemin biyomu
uniform int village_count = 0;
uniform float level_eps = 0.0;
uniform float texel = 4.0;

varying vec3 wpos;
varying float slope;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float e = max(texel, 1.5);
	float h = world_height(w.xz);
	float hx = world_height(w.xz + vec2(e, 0.0)) - world_height(w.xz - vec2(e, 0.0));
	float hz = world_height(w.xz + vec2(0.0, e)) - world_height(w.xz - vec2(0.0, e));
	vec3 n = normalize(vec3(-hx, 2.0 * e, -hz));
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
float fbm(vec2 p) { float s = 0.0, a = 0.5; for (int i = 0; i < 4; i++) { s += vnoise(p) * a; p *= 2.07; a *= 0.5; } return s; }

void fragment() {
	vec2 uv = (wpos.xz - world_rect.xy) / world_rect.zw;
	vec3 base = texture(albedo_map, uv).rgb;
	vec4 bio = wh_bilin(biome_map, wpos.xz);
	ivec2 bc = clamp(ivec2((wpos.xz - world_rect.xy) / macro_res), ivec2(0), ivec2(macro_size) - 1);
	int b = int(texelFetch(biome_map, bc, 0).r * 255.0 + 0.5);
	// köy zemini: keskin daire (makro harita 32 m, köy kenarı tırtıklı olmasın)
	for (int i = 0; i < village_count; i++) {
		vec4 v = villages[i];
		float d = length(wpos.xz - v.xy);
		if (d < v.z * 0.95) { b = int(v.w); }
	}
	float n1 = fbm(wpos.xz * 0.08);
	float n2 = vnoise(wpos.xz * 0.9);
	float n3 = vnoise(wpos.xz * 4.0);
	float n4 = fbm(wpos.xz * 0.011);
	// geniş ölçekli renk çeşitliliği (32 m doku düz görünmesin)
	base *= 0.9 + n4 * 0.22;
	if (b == 11) base = vec3(0.42, 0.62, 0.29);
	if (b == 13) base = vec3(0.85, 0.71, 0.52);
	if (b == 14) base = vec3(0.59, 0.57, 0.53);
	if (b == 15) base = vec3(0.89, 0.91, 0.94);
	// boyalı çimen: büyük açık/koyu lekeler + sarımsı çiçekli alanlar
	if (b == 2 || b == 7 || b == 6 || b == 11 || b == 4 || b == 10) {
		float patch = smoothstep(0.38, 0.62, n1);
		base *= mix(0.84, 1.14, patch);
		base = mix(base, base * vec3(1.12, 1.08, 0.7), smoothstep(0.7, 0.85, fbm(wpos.xz * 0.03 + 7.0)) * 0.6);
		base *= 0.93 + n3 * 0.12;
	}
	if (b == 3 || b == 1) {
		float rip = sin(wpos.x * 1.6 + wpos.z * 0.7 + n1 * 6.0) * 0.5 + 0.5;
		base *= 0.92 + rip * 0.1 + n2 * 0.06;
	}
	if (b == 13) {
		float rip = sin(wpos.x * 1.1 + wpos.z * 0.5 + n1 * 5.0) * 0.5 + 0.5;
		base *= 0.93 + rip * 0.06 + n2 * 0.06;
	}
	if (b == 14) {
		vec2 tt = wpos.xz / 1.7;
		tt.x += step(0.5, fract(tt.y * 0.5)) * 0.5;
		vec2 f = abs(fract(tt) - 0.5);
		float joint = smoothstep(0.45, 0.49, max(f.x, f.y));
		base *= (0.9 + hash(floor(tt)) * 0.18) * (1.0 - joint * 0.4);
	}
	if (b == 15 || b == 8) {
		base = mix(base, vec3(1.0), 0.12) + step(0.985, n3) * 0.22;
	}
	// yol: yerel yol dokusu (2 m), dışında kaba makro yol
	vec2 ruv = (wpos.xz - road_rect.xy) / max(road_rect.z, 1.0);
	float rmask;
	if (road_rect.z > 0.0 && ruv.x > 0.01 && ruv.y > 0.01 && ruv.x < 0.99 && ruv.y < 0.99) {
		rmask = texture(road_tex, ruv).r;
	} else {
		rmask = smoothstep(0.55, 0.9, bio.g) * 0.8;
	}
	float road = smoothstep(0.3, 0.6, rmask + (n2 - 0.5) * 0.22);
	vec3 dirt = vec3(0.74, 0.56, 0.36) * (0.85 + n3 * 0.2);
	if (b == 14 || b == 15) dirt = vec3(0.62, 0.6, 0.56) * (0.88 + n3 * 0.16);
	base = mix(base, dirt, road * 0.92);
	// yarlar: katmanlı kaya
	float rock = smoothstep(0.3, 0.5, slope + (n2 - 0.5) * 0.18);
	float strata = sin(wpos.y * 0.9 + n1 * 3.0) * 0.5 + 0.5;
	float strata2 = sin(wpos.y * 3.1 + n2 * 2.0) * 0.5 + 0.5;
	vec3 rockc = mix(vec3(0.45, 0.4, 0.36), vec3(0.62, 0.55, 0.47), strata);
	if (b == 3 || b == 5) rockc = mix(vec3(0.62, 0.42, 0.3), vec3(0.8, 0.6, 0.42), strata);
	rockc *= 0.85 + strata2 * 0.2;
	rockc *= mix(0.75, 1.0, smoothstep(0.0, 0.15, abs(fract(wpos.y * 0.25 + n1) - 0.5)));
	base = mix(base, rockc, rock);
	// nehir kıyısı ıslaklığı + sahil
	base = mix(base, base * vec3(0.7, 0.85, 0.75), bio.b * 0.5);
	base *= mix(0.72, 1.0, smoothstep(-0.2, 1.4, wpos.y));
	float lum = dot(base, vec3(0.299, 0.587, 0.114));
	base = max(mix(vec3(lum), base, 1.12), vec3(0.0));
	ALBEDO = base;
	ROUGHNESS = 0.95;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float t = smoothstep(-0.03, 0.05, ndl) * 0.6 + smoothstep(0.42, 0.5, ndl) * 0.4;
	if (LIGHT_IS_DIRECTIONAL) {
		vec3 shade = mix(vec3(0.5, 0.52, 0.7), vec3(1.0), t * ATTENUATION);
		DIFFUSE_LIGHT += LIGHT_COLOR * shade / PI;
	} else {
		DIFFUSE_LIGHT += LIGHT_COLOR * (0.35 + 0.65 * t) * ATTENUATION / PI;
	}
}
