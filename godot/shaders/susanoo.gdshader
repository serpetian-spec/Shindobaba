// Susanoo: dolgun renkli chakra bedeni. Yalnız en öndeki yüzey çizilir (derinlik yazar, arkadaki sahneyle kendisi karışır):
// katmanlar üst üste binip sütleşmez, içindeki kullanıcı seçilir. Açık renk kontur + zırh plaka çizgileri (animedeki çizgi işçiliği).
// Köşe rengi parça türünü taşır (r): 1 chakra eti, 0.8 zırh plakası (ızgara çizgili), 0.6 kemik, 0.4 açık çizgi, 0.15 koyu oyuk; g = ton.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_always, fog_disabled;

uniform sampler2D scr : hint_screen_texture, filter_linear, repeat_disable;
uniform vec4 col : source_color = vec4(0.55, 0.35, 1.0, 1.0);
uniform vec4 rim_col : source_color = vec4(0.55, 0.35, 1.0, 1.0);   // kenar rengi (iki tonlu Susanoo)
uniform float density = 1.0;     // dolgunluk (0.3 hayalet .. 2 dolu)
uniform float glow = 1.0;        // kontur parlaklığı
uniform float flow_speed = 1.0;  // içindeki chakra akış hızı
uniform float ground_y = -100000.0;   // yere gömülü kademeler: zemin altı çizilmez
uniform float cut_y = 0.0;       // >0: dinlenme pozunda bu yüksekliğin altı çizilmez (üst gövde kademesi)
uniform float force_kind = 0.0;  // >0: bütün yüzey bu türden boyanır (canavar kuyrukları Susanoo plakasına bürünür)
uniform float grid_k = 1.0;      // lamel ızgarasının ölçeği (canavar gövdesi büyük birimlerle kurulu)
uniform float flesh_a = 1.0;     // chakra etinin dolgunluk çarpanı (canavarın giydiği zırhta et silikleşir, plaka kalır)
uniform float all_a = 1.0;       // tüm yüzeyin dolgunluk çarpanı (canavar bedenindeki ince enerji katmanı)
uniform float vcol = 1.0;        // 0: gövde ağı (köşe rengi tür taşımaz, hepsi chakra eti)

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

varying vec3 wp;
varying vec3 rest;
varying vec3 op;
varying vec3 on;
varying float kind;
varying float tone;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	rest = CUSTOM0.xyz;
	op = dot(rest, rest) > 0.000001 ? rest : VERTEX;
	on = NORMAL;
	kind = force_kind > 0.0 ? force_kind : mix(1.0, COLOR.r, vcol);
	tone = mix(1.0, COLOR.g, vcol);
}

void fragment() {
	if (cut_y > 0.0 && rest.y > 0.0001 && rest.y < cut_y) discard;
	if (wp.y < ground_y) discard;
	float ndv = clamp(abs(dot(normalize(NORMAL), VIEW)), 0.0, 1.0);
	float rim = pow(1.0 - ndv, 2.2);
	float tt = TIME * flow_speed;
	// enerji akışı ve akan eş-yükselti çizgileri (önceki sürümün boyaması: dünya uzayında, yukarı akar)
	float flow = vnoise(wp.xz * 0.6 + vec2(0.0, -tt * 1.4) + wp.y * 0.4) * 0.6 + vnoise(wp.xy * 1.7 - vec2(tt * 0.8, tt * 2.0)) * 0.4;
	float n2 = vnoise(wp.xy * 0.9 + vec2(wp.z * 0.7, -tt * 0.6)) * 0.6 + vnoise(wp.zy * 1.9 + vec2(tt * 0.3, -tt * 1.1)) * 0.4;
	float lines = clamp(1.0 - smoothstep(0.02, 0.09, abs(fract(n2 * 6.0) - 0.5)), 0.0, 1.0);
	float flick = 0.85 + 0.15 * sin(tt * 9.0 + wp.y * 2.0);
	float fill = 0.5;       // iç dolgu: enerji gibi yarı saydam
	float bright = 0.0;
	float k2 = 0.0;         // ikinci renge kayma
	if (kind < 0.3) {            // koyu oyuk (göz çukuru, ağız içi, başlık gölgesi)
		vec3 bgd = texture(scr, SCREEN_UV).rgb;
		ALBEDO = mix(bgd, col.rgb * 0.1, 0.92);
	} else {
		if (kind < 0.5) {        // açık çizgi (sarmal, kenar şeridi, mücevher): ikinci renk, parlak
			k2 = 1.0;
			bright = 0.75;
			fill = 0.92;
			lines = 0.0;
		} else if (kind < 0.7) { // kemik: ikinci renge yakın, dolgun
			k2 = 0.7;
			bright = 0.45;
			fill = 0.88;
			lines *= 0.4;
		} else if (kind < 0.9) { // zırh plakası: lamel çizgileri akan çizgilere eklenir
			vec3 an = abs(normalize(on));
			float u = an.y > 0.8 ? op.x : (an.z > an.x ? op.x : op.z);
			float v = an.y > 0.8 ? op.z : op.y;
			float ch = 0.17 * grid_k, cw = 0.044 * grid_k;
			float fv = fract(v / ch);
			float fu = fract(u / cw);
			float dv = min(fv, 1.0 - fv) * ch, du = min(fu, 1.0 - fu) * cw;
			float wv = max(0.0045 * grid_k, fwidth(v) * 1.1), wu = max(0.0045 * grid_k, fwidth(u) * 1.1);
			float grid = max(1.0 - smoothstep(0.0, wv, dv), 1.0 - smoothstep(0.0, wu, du));
			grid *= clamp(0.012 * grid_k / max(fwidth(u), 0.0001), 0.0, 1.0);   // uzakta ızgara kırpışmasın
			lines = max(lines * 0.5, grid);
			fill = 0.62;
		}
		// renk geçişi: gövde ana renk, kenara ve çizgilere doğru ikinci renge akar
		float mixk = clamp(max(k2, rim * 1.3 + lines * 0.5), 0.0, 1.0);
		vec3 c = mix(col.rgb, rim_col.rgb, mixk) * (0.75 + rim * 0.9 * glow + flow * 0.25 + lines * 0.55 + bright) * flick * mix(1.0, tone, 0.6);
		float a = (fill + flow * 0.16) * mix(0.5, 1.0, clamp(density, 0.0, 1.0)) + (density - 1.0) * 0.15 + rim * 0.42 * glow + lines * 0.22 * glow;
		vec3 bg = texture(scr, SCREEN_UV).rgb;
		a *= all_a * (kind >= 0.9 ? flesh_a : 1.0);
		ALBEDO = mix(bg, c, clamp(a, 0.04, 0.96));
	}
}
