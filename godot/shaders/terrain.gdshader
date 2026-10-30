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
uniform vec4 hokage_rock = vec4(0.0);   // x0, x1, yüz hattı (dünya z), tepe yüksekliği: altın-toprak kaya dağı
uniform float level_eps = 0.0;
uniform sampler2D tex_cobble : filter_linear_mipmap, repeat_enable;   // köy döşemesi (parke taşı)
uniform sampler2D tex_stone : filter_linear_mipmap, repeat_enable;    // cadde iri taş
uniform sampler2D tex_rock : filter_linear_mipmap, repeat_enable;     // yarlar / kayalıklar
uniform sampler2D tex_sand : filter_linear_mipmap, repeat_enable;     // çöl, kumsal
uniform sampler2D tex_forest : filter_linear_mipmap, repeat_enable;   // orman zemini
uniform sampler2D tex_dirt : filter_linear_mipmap, repeat_enable;     // köy dışı toprak yollar
uniform sampler2D tex_grass : filter_linear_mipmap, repeat_enable;    // çimenli zemin
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
		// gerçek çimen zemini: yakında ince yaprak dokusu, uzakta iri lekeler (iki ölçek: tekrar deseni görünmesin)
		float gt = texture(tex_grass, wpos.xz * 0.16).r * 0.6 + texture(tex_grass, wpos.xz * 0.023 + 0.37).r * 0.4;
		base *= 1.0 + (gt - 0.5) * 0.75;
		// doygunluğu biraz kır + geniş ölçekte sarımsı / mavimsi yeşil bölgeler (tek tip neon yeşil olmasın)
		float gl = dot(base, vec3(0.299, 0.587, 0.114));
		base = mix(vec3(gl), base, 0.82);
		float hue = fbm(wpos.xz * 0.006 + 31.0);
		base *= mix(vec3(0.92, 1.0, 1.06), vec3(1.1, 1.02, 0.82), smoothstep(0.35, 0.7, hue));
	}
	// köy zemini (referans: tasarlanmış meydan): çoğu yer taş döşeme (ofsetli plaka + derz + plaka plaka ton), çimen yalnız
	// kenarı belirgin tarhlarda, aralarda toprak; çimenin her yeri kapladığı boş görünümü kırar
	if (b == 11 || b == 13) {
		vec2 tt = wpos.xz / vec2(2.2, 1.6);
		tt.x += step(0.5, fract(tt.y * 0.5)) * 0.5;
		vec2 f = abs(fract(tt) - 0.5);
		float joint = smoothstep(0.44, 0.49, max(f.x, f.y));
		float tone = hash(floor(tt));
		vec3 pave = (b == 11) ? mix(vec3(0.6, 0.52, 0.41), vec3(0.69, 0.6, 0.47), tone) : mix(vec3(0.8, 0.68, 0.49), vec3(0.88, 0.77, 0.58), tone);
		pave *= (1.0 - joint * 0.25) * (0.94 + n3 * 0.08);
		pave *= 1.0 + (texture(tex_cobble, wpos.xz * 0.45).r - 0.5) * 0.8;   // gerçek parke taşı dokusu
		if (b == 11) {
			// Konoha (animedeki gibi): açık bej sıkıştırılmış toprak, ince toprak dokusu, yer yer koyu ıslak lekeler (taş döşeme değil)
			pave = vec3(0.5, 0.45, 0.37) * (0.93 + n3 * 0.1) * (0.95 + n2 * 0.08);   // daha nötr: sarıya kaçmasın
			pave *= 1.0 + (texture(tex_dirt, wpos.xz * 0.18).r - 0.5) * 0.55;
			pave = mix(pave, pave * vec3(0.86, 0.8, 0.72), smoothstep(0.6, 0.8, fbm(wpos.xz * 0.03 + 9.0)) * 0.6);
		}
		pave = mix(pave, pave * vec3(0.82, 0.8, 0.74), smoothstep(0.55, 0.8, fbm(wpos.xz * 0.05 + 3.0)) * 0.5);   // aşınmış/kirli lekeler
		float bed = smoothstep(0.49, 0.53, fbm(wpos.xz * 0.045 + 11.0));      // çimen tarhları (keskin kenar)
		float dirt = smoothstep(0.46, 0.49, fbm(wpos.xz * 0.045 + 11.0)) * (1.0 - bed);   // tarhın toprak kenarı
		vec3 soil = (b == 11) ? vec3(0.42, 0.32, 0.22) : vec3(0.7, 0.55, 0.38);
		vec3 green = (b == 11) ? base : mix(base, vec3(0.55, 0.62, 0.32), 0.6);
		// döşeme yalnız bazı mahallelerde / meydanlarda; aralar sıkıştırılmış sıcak toprak (her yer beton gibi durmasın)
		float earthz = 0.0;
		vec3 earth = vec3(0.6, 0.47, 0.33) * (0.9 + n3 * 0.14) * (0.92 + n2 * 0.12);
		earth = mix(earth, earth * vec3(0.85, 0.95, 0.8), smoothstep(0.55, 0.75, fbm(wpos.xz * 0.06 + 4.0)) * 0.5);   // yer yer yosunlu
		pave = mix(pave, earth, earthz);
		vec3 ground = mix(pave, soil, dirt);
		ground = mix(ground, green, bed * ((b == 11) ? 1.0 : 0.35));
		base = ground;
	}
	if (b == 2) base *= 1.0 + (texture(tex_forest, wpos.xz * 0.12).r - 0.5) * 0.7;   // orman zemini: yaprak, dal, toprak
	if (b == 3 || b == 1 || b == 13) base *= 1.0 + (texture(tex_sand, wpos.xz * 0.15).r - 0.5) * 0.7;   // kum dokusu
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
		base *= (0.9 + hash(floor(tt)) * 0.18) * (1.0 - joint * 0.3);
		base *= 1.0 + (texture(tex_stone, wpos.xz * 0.35).r - 0.5) * 0.8;   // taş köy döşemesi
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
	if (b == 8 || b == 9) dirt = vec3(0.52, 0.47, 0.42) * (0.88 + n3 * 0.18);  // karlı/dağ yolu: ıslak çakıl
	if (b != 11) dirt *= 1.0 + (texture(tex_dirt, wpos.xz * 0.2).r - 0.5) * 0.8;   // köy dışı toprak yol
	// köy içi cadde: toprak değil büyük taş plaka döşeme (referans meydan), kenarda koyu bordür
	if (b == 11) {
		vec2 st = wpos.xz / 3.0;
		st.x += step(0.5, fract(st.y * 0.5)) * 0.5;
		vec2 sf = abs(fract(st) - 0.5);
		float sj = smoothstep(0.45, 0.49, max(sf.x, sf.y));
		// köy caddesi: açık, düzgün sıkıştırılmış toprak (zeminden bir ton açık), kenarı hafif koyu; tekerlek / ayak izi lekeleri
		dirt = vec3(0.52, 0.47, 0.39) * (0.95 + n3 * 0.07);   // nötr açık toprak (sarıya kaçmasın)
		dirt *= 1.0 + (texture(tex_dirt, wpos.xz * 0.22).r - 0.5) * 0.4;
		dirt *= 1.0 - 0.12 * (smoothstep(0.3, 0.45, rmask) - smoothstep(0.45, 0.6, rmask));
	}
	// yol kenarı: tekerlek izi ortası hafif çimenli, kenarlarda çakıl
	dirt *= 1.0 - 0.06 * smoothstep(0.75, 0.95, rmask);
	base = mix(base, dirt, road * 0.92);
	// yarlar: katmanlı kaya
	float rock = smoothstep(0.3, 0.5, slope + (n2 - 0.5) * 0.18);
	float strata = sin(wpos.y * 0.9 + n1 * 3.0) * 0.5 + 0.5;
	float strata2 = sin(wpos.y * 3.1 + n2 * 2.0) * 0.5 + 0.5;
	vec3 rockc = mix(vec3(0.45, 0.4, 0.36), vec3(0.62, 0.55, 0.47), strata);
	if (b == 3 || b == 5) rockc = mix(vec3(0.62, 0.42, 0.3), vec3(0.8, 0.6, 0.42), strata);
	rockc *= 0.85 + strata2 * 0.2;
	rockc *= mix(0.75, 1.0, smoothstep(0.0, 0.15, abs(fract(wpos.y * 0.25 + n1) - 0.5)));
	rockc *= 1.0 + (texture(tex_rock, vec2(wpos.x + wpos.z, wpos.y) * 0.06).r - 0.5) * 1.1;   // gerçek kaya yüzeyi dokusu
	// tüm yarlar: dikey çatlaklar + kaya blokları (düz bant bant duvar gibi durmasın)
	float blk = vnoise(vec2(wpos.x * 0.045 + wpos.z * 0.045, wpos.y * 0.09));
	float crk = smoothstep(0.86, 0.95, vnoise(vec2((wpos.x + wpos.z) * 0.11, wpos.y * 0.018)));
	rockc *= (0.88 + blk * 0.24) * (1.0 - crk * 0.45);
	// Hokage Kayası: altın-toprak sarısı kaya dağı (referans), koyu oyuklar, aydınlık çıkıntılar, yer yer yeşil çalı kümeleri
	if (hokage_rock.w > 0.0 && wpos.x > hokage_rock.x - 400.0 && wpos.x < hokage_rock.y + 400.0 && wpos.z < hokage_rock.z + 120.0 && wpos.z > hokage_rock.z - 900.0) {
		float k1 = fbm(wpos.xz * 0.012 + vec2(wpos.y * 0.01));
		float k2 = vnoise(vec2((wpos.x + wpos.z) * 0.06, wpos.y * 0.035));
		vec3 gold = mix(vec3(0.42, 0.28, 0.14), vec3(0.8, 0.6, 0.3), smoothstep(0.2, 0.8, k1 * 0.6 + k2 * 0.4));
		gold = mix(gold, vec3(0.92, 0.74, 0.42), smoothstep(0.8, 0.95, k2) * 0.5);          // aydınlık çıkıntı
		float groove = vnoise(vec2((wpos.x + wpos.z) * 0.05, wpos.y * 0.008)) * 0.6 + vnoise(vec2((wpos.x + wpos.z) * 0.17, wpos.y * 0.02)) * 0.4;
		gold *= mix(1.08, 0.55, smoothstep(0.55, 0.85, groove));                               // dikey oluk gölgeleri (kontrast)
		gold *= 1.0 - smoothstep(0.86, 0.94, vnoise(vec2((wpos.x + wpos.z) * 0.12, wpos.y * 0.015))) * 0.5;   // ince çatlaklar
		gold *= 0.85 + blk * 0.3;
		float moss = smoothstep(0.62, 0.72, fbm(wpos.xz * 0.02 + vec2(7.0, wpos.y * 0.03))) * smoothstep(0.75, 0.45, slope);
		gold = mix(gold, vec3(0.22, 0.42, 0.36), moss * 0.85);                                // yeşil çalı kümeleri
		rockc = gold * 0.86 * (1.0 + (texture(tex_rock, vec2(wpos.x + wpos.z, wpos.y) * 0.05).r - 0.5) * 1.4);   // kaya dokusu altın tonda da
	}
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
