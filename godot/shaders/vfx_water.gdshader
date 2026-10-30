// Anime su kütlesi (ejderha, köpekbalığı, dalga, kalkan, kalkan küresi): akışkan ve saydam.
// - arkası kırılarak görünür (ekran dokusu, akan gürültüyle bükülür): katı bir madde gibi değil
// - kenarda (fresnel) koyulaşan derinlik, ortada açık ve saydam
// - akış yönünde kayan ince köpük şeritleri + tepe noktalarında küçük yansıma parıltıları
// Eski uniform adları korunur (VFX.mat_water parametreleri değişmesin).
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, shadows_disabled, blend_mix;

uniform vec4 c_deep : source_color = vec4(0.05, 0.28, 0.78, 1.0);
uniform vec4 c_mid : source_color = vec4(0.2, 0.55, 0.98, 1.0);
uniform vec4 c_light : source_color = vec4(0.62, 0.88, 1.0, 1.0);
uniform vec4 c_foam : source_color = vec4(0.97, 0.99, 1.0, 1.0);
uniform float speed = 2.5;
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
	// iki katmanlı dalgalanma: büyük yavaş kabarma + küçük hızlı titreşim (yüzey canlı aksın)
	float w = (vn(VERTEX * 1.6 + flow * TIME * speed * 0.6) - 0.5) * 1.4 + (vn(VERTEX * 4.5 - flow * TIME * speed * 1.4) - 0.5) * 0.6;
	VERTEX += NORMAL * w * wobble * 2.0;
}

void fragment() {
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fres = pow(1.0 - ndv, 1.6);
	vec3 p = lp * scale;
	vec3 fl = flow * TIME * speed;
	float n = fbm(p + fl);
	float n2 = fbm(p * 1.7 - fl * 1.3 + 5.0);
	// kırılma: arkasındaki dünya akan suyun içinden bükülerek görünür
	vec2 off = (vec2(n, n2) - 0.5) * 0.045 * (0.4 + ndv);
	vec3 behind = textureLod(screen_tex, SCREEN_UV + off, 1.5).rgb;
	// renk: ortası açık / saydam, kenarı koyu derin mavi (yumuşak geçiş, sert bant yok)
	vec3 body = mix(c_light.rgb, c_mid.rgb, smoothstep(0.0, 0.55, fres + (n - 0.5) * 0.35));
	body = mix(body, c_deep.rgb, smoothstep(0.45, 1.0, fres + (n2 - 0.5) * 0.25));
	// akış şeritleri: akış yönünde uzayan ince açık çizgiler (köpük değil, akış izi)
	float along = dot(lp, normalize(flow + vec3(1e-4)));
	float streak = smoothstep(0.8, 0.95, sin(along * 7.0 * scale - TIME * speed * 5.0 + n * 7.0) * 0.5 + 0.5) * smoothstep(0.35, 0.65, n2);
	// köpük: yalnız kenarlarda ve kabaran tepelerde, ince ve yırtık
	float fm = smoothstep(0.66, 0.74, n + fres * 0.45 * foam) * foam;
	// yansıma parıltısı: küçük, keskin
	vec3 h = normalize(vec3(-0.4, 0.8, 0.45));
	float spec = smoothstep(0.93, 0.97, dot(NORMAL, (VIEW_MATRIX * vec4(h, 0.0)).xyz)) * (0.6 + n * 0.6);
	float tint = clamp(alpha * (0.42 + fres * 0.58), 0.0, 1.0);   // ortada arkası görünür
	vec3 col = mix(behind, body, tint);
	col = mix(col, c_light.rgb * 1.1, streak * 0.35);
	col = mix(col, c_foam.rgb, fm * 0.85);
	col += c_foam.rgb * spec * 0.7;
	ALBEDO = col;
	ALPHA = clamp(0.55 + fres * 0.45 + fm * 0.3, 0.0, 1.0) * clamp(alpha / 0.88, 0.0, 1.0);
}
