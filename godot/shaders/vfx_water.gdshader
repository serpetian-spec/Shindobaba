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
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fres = 1.0 - ndv;
	vec3 p = lp * scale;
	vec3 fl = flow * TIME * speed;
	float n = fbm(p + fl);
	float n2 = fbm(p * 1.7 - fl * 1.3 + 5.0);
	// cel tonları: açık / orta / derin — sert sınırlar, sınırlar akışla dalgalanır
	float shade = fres + (n - 0.5) * 0.45;
	vec3 col = c_light.rgb;
	col = mix(col, c_mid.rgb, step(0.32, shade));
	col = mix(col, c_deep.rgb, step(0.62, shade));
	// koyu mavi dış hat (Storm'daki net su silueti)
	float edge = step(0.86, fres + (n2 - 0.5) * 0.12);
	col = mix(col, c_deep.rgb * 0.55, edge);
	// akım şeritleri: akış yönünde hızla kayan keskin beyaz çizgiler (iki frekans)
	float along = dot(lp, normalize(flow + vec3(1e-4)));
	float s1 = step(0.86, sin(along * 6.0 * scale - TIME * speed * 6.0 + n * 8.0) * 0.5 + 0.5) * step(0.45, n2);
	float s2 = step(0.92, sin(along * 13.0 * scale - TIME * speed * 9.0 + n2 * 6.0) * 0.5 + 0.5) * step(0.5, n);
	float streak = max(s1, s2) * (1.0 - edge);
	// köpük: yırtık beyaz lekeler (kabaran tepelerde ve kenara yakın)
	float fm = step(0.7, n + fres * 0.35 * foam) * foam * (1.0 - edge);
	// parlama: küçük keskin beyaz nokta
	vec3 h = normalize(vec3(-0.4, 0.8, 0.45));
	float spec = step(0.95, dot(NORMAL, (VIEW_MATRIX * vec4(h, 0.0)).xyz)) * step(0.4, n);
	col = mix(col, c_foam.rgb, max(streak, max(fm * 0.95, spec)));
	// çok hafif kırılma: yalnız ortada arkası sezilir (boyanmış su, cam değil)
	vec2 off = (vec2(n, n2) - 0.5) * 0.03;
	vec3 behind = textureLod(screen_tex, SCREEN_UV + off, 1.0).rgb;
	float see = (1.0 - smoothstep(0.0, 0.35, fres)) * 0.18 * (1.0 - streak) * (1.0 - fm);
	col = mix(col, behind, see);
	ALBEDO = col;
	ALPHA = clamp(0.9 + fres * 0.1, 0.0, 1.0) * clamp(alpha / 0.88, 0.0, 1.0);
}
