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
	kind = mix(1.0, COLOR.r, vcol);
	tone = mix(1.0, COLOR.g, vcol);
}

void fragment() {
	if (cut_y > 0.0 && rest.y > 0.0001 && rest.y < cut_y) discard;
	if (wp.y < ground_y) discard;
	float ndv = clamp(abs(dot(normalize(NORMAL), VIEW)), 0.0, 1.0);
	float rim = pow(1.0 - ndv, 2.6);
	float tt = TIME * flow_speed;
	// benek: yavaş akan açık bulutlar (animedeki alacalı chakra dokusu)
	float m = vnoise(op.xy * 5.0 + vec2(op.z * 3.0, -tt * 0.5)) * 0.6 + vnoise(op.zy * 11.0 + vec2(tt * 0.3, -tt * 0.9)) * 0.4;
	vec3 light = mix(rim_col.rgb, vec3(1.0), 0.5);
	vec3 base = col.rgb * (0.7 + 0.42 * m) * tone;
	float a = 0.9;
	float ln = 0.0;
	if (kind < 0.3) {            // koyu oyuk (göz çukuru, ağız içi, başlık gölgesi)
		base = col.rgb * 0.13;
		a = 0.93;
	} else if (kind < 0.5) {     // açık çizgi (sarmal, kenar şeridi)
		base = light * (0.9 + 0.2 * m);
		a = 0.95;
	} else if (kind < 0.7) {     // kemik
		base = mix(col.rgb, vec3(1.0), 0.38) * (0.85 + 0.25 * m) * tone;
		a = 0.94;
	} else if (kind < 0.9) {     // zırh plakası: tuğla örgülü ızgara çizgileri
		vec3 an = abs(normalize(on));
		float u = an.y > 0.8 ? op.x : (an.z > an.x ? op.x : op.z);
		float v = an.y > 0.8 ? op.z : op.y;
		float ch = 0.17, cw = 0.044;
		float row = floor(v / ch);
		float fv = fract(v / ch);
		float fu = fract(u / cw);
		float dv = min(fv, 1.0 - fv) * ch, du = min(fu, 1.0 - fu) * cw;
		float wv = max(0.0045, fwidth(v) * 1.1), wu = max(0.0045, fwidth(u) * 1.1);
		ln = max(1.0 - smoothstep(0.0, wv, dv), 1.0 - smoothstep(0.0, wu, du));
		ln *= 0.7 * clamp(0.012 / max(fwidth(u), 0.0001), 0.0, 1.0);   // uzakta ızgara kırpışmasın
		base *= 0.92;
		a = 0.94;
	} else {                     // chakra eti: akan eş-yükselti çizgileri (hafif)
		float n2 = vnoise(op.xy * 7.0 + vec2(op.z * 5.0, -tt * 0.6)) * 0.6 + vnoise(op.zy * 14.0 + vec2(tt * 0.3, -tt * 1.1)) * 0.4;
		ln = clamp(1.0 - smoothstep(0.02, 0.09, abs(fract(n2 * 5.0) - 0.5)), 0.0, 1.0) * 0.22;
	}
	float flick = 0.93 + 0.07 * sin(tt * 7.0 + op.y * 9.0);
	vec3 c = (base + light * (rim * 0.7 * glow + ln * 0.5 * glow)) * flick;
	a = clamp(a * mix(0.55, 1.0, clamp(density, 0.0, 1.0)) + (density - 1.0) * 0.12 + rim * 0.25, 0.12, 0.97);
	vec3 bg = texture(scr, SCREEN_UV).rgb;
	ALBEDO = mix(bg, c, a);
}
