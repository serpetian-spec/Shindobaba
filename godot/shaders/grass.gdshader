// Oyuncu çevresinde çimen: yükseklik/renk araziden, biyoma göre gizlenir, rüzgarla sallanır.
shader_type spatial;
render_mode cull_disabled, world_vertex_coords, diffuse_toon, specular_disabled, depth_draw_never;

#include "res://shaders/world_height.gdshaderinc"
uniform sampler2D albedo_map : source_color, filter_linear, repeat_disable;
uniform sampler2D road_tex : filter_linear, repeat_disable;
uniform vec4 road_rect;
uniform vec4 villages[16];
uniform int village_count = 0;
uniform vec3 player_pos;
uniform float radius = 58.0;

varying float tip;
varying vec3 base_col;
varying float fade;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) { float s = 0.0, a = 0.5; for (int i = 0; i < 4; i++) { s += vnoise(p) * a; p *= 2.07; a *= 0.5; } return s; }

void vertex() {
	vec2 uv = (VERTEX.xz - world_rect.xy) / world_rect.zw;
	// köke göre ofset: bu tutamın kökü (örnek noktası) = model merkezi
	vec3 root = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec2 ruv = (root.xz - world_rect.xy) / world_rect.zw;
	// dünyaya sabit rastgelelik: ızgara hücresi -> kayma, dönüş, boy (oyuncu yürürken çimen yerinden oynamasın)
	vec2 cell = floor(root.xz / 0.6 + 0.5);
	vec2 jit = vec2(hash(cell + 1.7), hash(cell + 9.3)) - 0.5;
	float ang = hash(cell + 4.1) * 6.2832;
	float hs = 0.7 + hash(cell + 2.9) * 0.6;
	float hv = 0.8 + hash(cell + 6.6) * 0.6;
	vec3 root0 = root;
	root.xz += jit * 0.6;
	float h = world_height(root.xz);
	vec4 bio = wh_bilin(biome_map, root.xz);
	ivec2 bc = clamp(ivec2((root.xz - world_rect.xy) / macro_res), ivec2(0), ivec2(macro_size) - 1);
	int b = int(texelFetch(biome_map, bc, 0).r * 255.0 + 0.5);
	for (int i = 0; i < village_count; i++) {
		if (length(root.xz - villages[i].xy) < villages[i].z * 0.95) { b = int(villages[i].w); }
	}
	vec2 rr = (root.xz - road_rect.xy) / max(road_rect.z, 1.0);
	float road = (road_rect.z > 0.0 && rr.x > 0.0 && rr.y > 0.0 && rr.x < 1.0 && rr.y < 1.0) ? texture(road_tex, rr).r : bio.g;
	// 2 orman 4 yağmur 6 pirinç 7 çimen 9 dağ 10 bataklık 11 köy
	float ok = (b == 2 || b == 4 || b == 6 || b == 7 || b == 10) ? 1.0 : (b == 9 ? 0.5 : 0.0);
	// köy içinde sadece duvar diplerinde/bahçelerde seyrek öbekler
	if (b == 11) ok = step(0.58, fbm(root.xz * 0.045 + 11.0));   // köy: yalnız çimen tarhlarında (arazi gölgelendiricisiyle aynı desen), döşemede çimen yok
	// 13 çöl köyü, 14 taş köy, 15 karlı köy: çimen yok
	ok *= 1.0 - step(0.2, road);            // yol
	ok *= 1.0 - step(0.5, bio.b);           // ıslak
	ok *= step(0.6, h);                     // su altı
	float rnd = hash(floor(root.xz * 3.0));
	ok *= step(rnd, 0.92);
	float d = distance(root.xz, player_pos.xz);
	fade = 1.0 - smoothstep(radius * 0.7, radius, d);
	float s = ok * fade * (0.7 + rnd * 0.6);
	tip = clamp(VERTEX.y - root.y, 0.0, 1.0);
	vec3 local = VERTEX - root0;
	local = vec3(local.x * cos(ang) - local.z * sin(ang), local.y, local.x * sin(ang) + local.z * cos(ang));
	local *= vec3(hs, hs * hv, hs) * s;
	// rüzgar
	// rüzgar: tarlada yavaşça ilerleyen esinti dalgası + çok hafif titreşim (sakin, abartısız)
	float wave = sin(TIME * 0.9 - dot(root.xz, vec2(0.12, 0.07))) * 0.5 + 0.5;
	float w = (0.05 + wave * wave * 0.2) + sin(TIME * 2.6 + root.x * 0.9 + root.z * 0.7) * 0.04;
	local.x += w * tip * tip;
	local.z += w * 0.6 * tip * tip;
	local.y -= w * w * tip * 0.6;   // eğilen uç biraz alçalsın (uzamasın)
	VERTEX = vec3(root.x, h - 0.05, root.z) + local;
	base_col = texture(albedo_map, ruv).rgb;
}

void fragment() {
	vec3 c = base_col * mix(0.62, 1.25, tip);
	c = mix(c, c * vec3(1.05, 1.12, 0.85), tip * 0.5);
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	c = max(mix(vec3(lum), c, 1.08), vec3(0.0));
	ALBEDO = c;
	ROUGHNESS = 0.02;  // çizgi efekti için işaret
}

void light() {
	float ndl = abs(dot(NORMAL, LIGHT));
	if (LIGHT_IS_DIRECTIONAL) {
		float lit = mix(0.6, 1.0, smoothstep(0.0, 0.2, ndl)) * mix(0.6, 1.0, ATTENUATION);
		DIFFUSE_LIGHT += LIGHT_COLOR * lit / PI;
	} else {
		DIFFUSE_LIGHT += LIGHT_COLOR * mix(0.4, 1.0, smoothstep(0.0, 0.2, ndl)) * ATTENUATION / PI;
	}
}
