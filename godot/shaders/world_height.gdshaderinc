// Dünya yüksekliği: makro harita (32 m) + deterministik ayrıntı gürültüsü + yüksek çözünürlüklü yamalar.
// Game.terrain_height (game.gd) ile BİREBİR aynı formül; değiştirirsen ikisini birlikte değiştir.
uniform sampler2D heightmap : filter_nearest, repeat_disable;     // makro yükseklik (RF)
uniform sampler2D biome_map : filter_nearest, repeat_disable;     // R biyom, G kaba yol, B ıslak, A ayrıntı genliği
uniform sampler2D shape_map : filter_nearest, repeat_disable;     // R sırt, G mesa, B kum tepesi, A kaya çıkıntısı
uniform vec4 world_rect;            // x0, z0 (min z), genişlik, derinlik (m)
uniform vec2 macro_size;            // piksel: W, H
uniform float macro_res = 32.0;
uniform float detail_max = 26.0;
uniform sampler2D patch0 : filter_nearest, repeat_disable;
uniform sampler2D patch1 : filter_nearest, repeat_disable;
uniform sampler2D patch2 : filter_nearest, repeat_disable;
uniform vec4 patch_rect[3];         // x0, z0 (min z), boyut (m), kenar geçişi (m); boyut 0 = yok
uniform vec3 patch_info[3];         // n (piksel), çözünürlük, -

uint wh_hash(ivec2 p, uint seed) {
	uint h = uint(p.x) * 374761393u + uint(p.y) * 668265263u + seed * 2246822519u;
	h = (h ^ (h >> 13u)) * 1274126177u;
	return h ^ (h >> 16u);
}
float wh_lat(ivec2 p, uint seed) { return float(wh_hash(p, seed) & 16777215u) / 16777215.0; }
float wh_vn(vec2 p, uint seed) {
	vec2 i = floor(p);
	vec2 f = p - i;
	vec2 u = f * f * (3.0 - 2.0 * f);
	ivec2 ii = ivec2(i);
	float a = mix(wh_lat(ii, seed), wh_lat(ii + ivec2(1, 0), seed), u.x);
	float b = mix(wh_lat(ii + ivec2(0, 1), seed), wh_lat(ii + ivec2(1, 1), seed), u.x);
	return mix(a, b, u.y);
}

// texel merkezli elle bilinear (CPU ile aynı)
vec4 wh_bilin(sampler2D t, vec2 xz) {
	vec2 f = vec2((xz.x - world_rect.x) / macro_res - 0.5, (xz.y - world_rect.y) / macro_res - 0.5);
	vec2 i = floor(f);
	vec2 t2 = clamp(f - i, 0.0, 1.0);
	ivec2 a = clamp(ivec2(i), ivec2(0), ivec2(macro_size) - 2);
	vec4 v00 = texelFetch(t, a, 0);
	vec4 v10 = texelFetch(t, a + ivec2(1, 0), 0);
	vec4 v01 = texelFetch(t, a + ivec2(0, 1), 0);
	vec4 v11 = texelFetch(t, a + ivec2(1, 1), 0);
	return mix(mix(v00, v10, t2.x), mix(v01, v11, t2.x), t2.y);
}

float wh_terrace(float h, float step_h, float edge) {
	float k = h / step_h;
	float f = clamp((k - floor(k) - edge) / (1.0 - edge), 0.0, 1.0);
	f = f * f * (3.0 - 2.0 * f);
	return (floor(k) + f) * step_h;
}

float wh_patch(sampler2D t, vec4 r, vec3 info, vec2 xz, float h) {
	if (r.z <= 0.0) return h;
	vec2 l = xz - r.xy;
	if (l.x < 0.0 || l.y < 0.0 || l.x > r.z || l.y > r.z) return h;
	vec2 f = l / info.y - 0.5;
	vec2 i = floor(f);
	vec2 t2 = clamp(f - i, 0.0, 1.0);
	ivec2 a = clamp(ivec2(i), ivec2(0), ivec2(int(info.x) - 2));
	float v = mix(mix(texelFetch(t, a, 0).r, texelFetch(t, a + ivec2(1, 0), 0).r, t2.x),
		mix(texelFetch(t, a + ivec2(0, 1), 0).r, texelFetch(t, a + ivec2(1, 1), 0).r, t2.x), t2.y);
	float e = min(min(l.x, l.y), min(r.z - l.x, r.z - l.y));
	float w = clamp(e / r.w, 0.0, 1.0);
	w = w * w * (3.0 - 2.0 * w);
	return mix(h, v, w);
}

float world_height(vec2 xz) {
	float h = wh_bilin(heightmap, xz).r;
	float amp = wh_bilin(biome_map, xz).a;
	if (amp > 0.002) {
		vec4 shp = wh_bilin(shape_map, xz);
		vec2 p = xz;
		float f = wh_vn(p / 300.0, 1u) * 0.5 + wh_vn(p / 150.0, 2u) * 0.3 + wh_vn(p / 70.0, 3u) * 0.2;
		float r1 = 1.0 - abs(wh_vn(p / 520.0, 4u) * 2.0 - 1.0);
		float r2 = 1.0 - abs(wh_vn(p / 230.0, 5u) * 2.0 - 1.0);
		float fine = wh_vn(p / 24.0, 6u);
		float d = (f - 0.5) + shp.r * ((r1 * r1 * 0.7 + r2 * r2 * 0.3) - 0.45) * 1.6 + (fine - 0.5) * 0.08;
		h += d * amp * detail_max;
		float gate = clamp(amp * 5.0, 0.0, 1.0);
		float mesa = shp.g * gate;
		if (mesa > 0.004) h = mix(h, wh_terrace(h + 6.0, 22.0, 0.8), mesa);
		float outc = shp.a * gate;
		if (outc > 0.004) h = mix(h, wh_terrace(h, 14.0, 0.75) + 10.0, outc);
		float dune = shp.b * gate;
		if (dune > 0.004) h += dune * pow(abs(sin((p.x * 0.9 - p.y * 0.4) / 38.0 + wh_vn(p / 300.0, 7u) * 6.0)), 1.5) * 12.0;
	}
	h = wh_patch(patch0, patch_rect[0], patch_info[0], xz, h);
	h = wh_patch(patch1, patch_rect[1], patch_info[1], xz, h);
	h = wh_patch(patch2, patch_rect[2], patch_info[2], xz, h);
	return h;
}
