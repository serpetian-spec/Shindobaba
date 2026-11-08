// Ultimate Ninja Storm tarzı su kütlesi (ejderha, köpekbalığı, dalga, kalkan, hapis, su ipi):
// - doygun camgöbeği-mavi gövde, sert geçişli cel tonları (yumuşak degrade değil)
// - koyu mavi dış hat (fresnel kenar) — suyun silueti net okunur
// - akış yönünde hızla kayan keskin beyaz akım şeritleri + yırtık beyaz köpük lekeleri
// - küçük keskin parlama; arkası çok az görünür (cam gibi değil, boyanmış su)
// Eski uniform adları korunur (VFX.mat_water parametreleri değişmesin).
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, shadows_disabled, blend_mix;

uniform vec4 c_deep : source_color = vec4(0.05, 0.28, 0.78, 1.0);
uniform vec4 c_mid : source_color = vec4(0.2, 0.55, 0.98, 1.0);
uniform vec4 c_light : source_color = vec4(0.62, 0.88, 1.0, 1.0);
uniform vec4 c_foam : source_color = vec4(0.97, 0.99, 1.0, 1.0);
uniform float speed = 4.2;
uniform float scale = 2.0;
uniform vec3 flow = vec3(0.0, 0.0, 1.0);
uniform float alpha = 0.88;
uniform float foam = 0.5;
uniform float wobble = 0.06;
uniform float hi_amt = 0.7;   // üst parlak (yassı su örtüsünde düşük: beyaz leke olmasın)
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

varying vec3 lp;

float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float vn(vec3 p) {
	vec3 i = floor(p), f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), u.x), mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), u.x), u.y),
	           mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), u.x), mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), u.x), u.y), u.z);
}
float fbm(vec3 p) { return vn(p) * 0.55 + vn(p * 2.1 + 3.1) * 0.3 + vn(p * 4.3 + 7.7) * 0.15; }

void vertex() {
	lp = VERTEX;
	// canlı yüzey: büyük kabarma + küçük titreşim
	float w = (vn(VERTEX * 1.6 + flow * TIME * speed * 0.6) - 0.5) * 1.4 + (vn(VERTEX * 4.5 - flow * TIME * speed * 1.4) - 0.5) * 0.6;
	VERTEX += NORMAL * w * wobble * 3.2;
}

void fragment() {
	// NARUTO STORM SUYU (ref: Storm 4 Suiton videosu, su duvarı 0:32, ejder 5:28): açık camgöbeği, yarı saydam, hafif ışıyan;
	// yüzeyde yumuşak, iri koyu camgöbeği lekeler (akışla kayar), siluete doğru yumuşakça beyaza dönen kenar, üstte parlak vurgu.
	// Sert koyu kontur / ince gürültü şeridi YOK.
	vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fres = 1.0 - ndv;
	vec3 fl = flow * TIME * speed * 0.5;
	float big = fbm(lp * scale * 0.45 + fl);          // iri lekeler
	float big2 = fbm(lp * scale * 0.9 - fl * 1.3 + 4.0);
	vec3 col = c_light.rgb;
	col = mix(col, c_mid.rgb, smoothstep(0.5, 0.56, big));                    // orta camgöbeği leke (yumuşak sınır)
	col = mix(col, c_deep.rgb, smoothstep(0.66, 0.7, big) * 0.8);             // koyu leke çekirdeği
	float lit = dot(wn, normalize(vec3(-0.3, 1.0, 0.35))) * 0.5 + 0.5;
	col = mix(col, c_foam.rgb, smoothstep(0.82, 0.92, lit) * hi_amt);         // ışığa bakan üst parlak
	col = mix(col, c_foam.rgb, smoothstep(0.55, 0.95, fres));                 // kenar yumuşakça beyaz
	// akış boyunca kayan beyaz köpük izleri (iri, yumuşak — ince çizgi değil)
	float foamp = smoothstep(0.62, 0.7, big2) * foam;
	col = mix(col, c_foam.rgb, foamp * 0.85);
	ALBEDO = col;
	EMISSION = col * 0.18;   // hafif içten ışıma
	// gövde ortası daha saydam, kenarlar dolu (Storm suyu yarı saydam)
	ALPHA = clamp(mix(0.72, 1.0, smoothstep(0.2, 0.8, fres)) * (alpha / 0.88), 0.0, 1.0);
}
