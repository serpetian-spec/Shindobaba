// Cel alev kütlesi (ateş topu, alev akışı, alev ejderhası): kayan 3B gürültü, 4 sert renk bandı,
// gürültüyle aşınan dalgalı silüet, koyu kırmızı kontur. Opak (alfa testi) → sahne çizgisi de oturur.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque, shadows_disabled;

uniform vec4 c_core : source_color = vec4(1.0, 0.99, 0.86, 1.0);
uniform vec4 c_hot : source_color = vec4(1.0, 0.86, 0.22, 1.0);
uniform vec4 c_mid : source_color = vec4(1.0, 0.48, 0.06, 1.0);
uniform vec4 c_edge : source_color = vec4(0.82, 0.13, 0.03, 1.0);
uniform vec4 c_line : source_color = vec4(0.3, 0.04, 0.02, 1.0);
uniform float speed = 2.2;
uniform float scale = 2.4;
uniform float erode = 0.42;        // silüet aşınması
uniform float glow = 1.35;
uniform float swirl = 1.2;
uniform float wobble = 0.12;
uniform vec3 flow = vec3(0.0, 1.0, 0.0);   // nesne uzayında akış yönü
uniform float alpha_cut = 0.0;      // >0: tüm kütleyi eritir (sönme animasyonu)

varying vec3 lp;

float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float vn(vec3 p) {
	vec3 i = floor(p), f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), u.x), mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), u.x), u.y),
	           mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), u.x), mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), u.x), u.y), u.z);
}

uniform float tongue = 0.0;   // >0: üst yarı sivri, titreyen alev dillerine çekilir (Amaterasu, meşale)

void vertex() {
	lp = VERTEX;
	float w = vn(VERTEX * 3.1 - flow * TIME * speed * 1.4) - 0.5;
	VERTEX += NORMAL * w * wobble * 2.0;
	if (tongue > 0.0) {
		float up = max(0.0, lp.y + 0.1);
		float lick = vn(vec3(lp.x * 4.0, lp.z * 4.0, TIME * speed * 1.7)) ;
		VERTEX.xz *= 1.0 - clamp(up * tongue * 1.5, 0.0, 0.85);
		VERTEX.y += up * tongue * (0.6 + lick * 1.6);
	}
}

void fragment() {
	float fres = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	vec3 p = lp * scale;
	float a = TIME * swirl;
	p.xz = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * p.xz;
	p -= flow * TIME * speed;
	float n = vn(p) * 0.55 + vn(p * 2.3 + vec3(3.1, 7.7, 1.3)) * 0.3 + vn(p * 5.2) * 0.15;
	float v = fres * 0.95 + (n - 0.5) * 1.0;
	if (fres + (n - 0.5) * erode * 2.2 > 0.97 - alpha_cut) discard;
	// yumuşak geçişli bantlar (anime kademesi korunur ama keskin yapay disk görünmez); parlak çekirdek küçük
	float e = 0.05;
	vec3 col = c_core.rgb;
	col = mix(col, c_hot.rgb, smoothstep(0.1 - e, 0.1 + e, v));
	col = mix(col, c_mid.rgb, smoothstep(0.33 - e, 0.33 + e, v));
	col = mix(col, c_edge.rgb, smoothstep(0.6 - e, 0.6 + e, v));
	col = mix(col, c_line.rgb, smoothstep(0.86 - e * 0.6, 0.86 + e * 0.6, v));
	// iç dalgalanma: sıcak/soğuk damarlar (düz renk alanı kalmasın)
	col *= 0.86 + 0.28 * vn(p * 3.7 + vec3(TIME * 0.7));
	col *= mix(1.0, glow, 0.55);   // parlama yarıya: göz yormasın
	float mx = max(col.r, max(col.g, col.b));
	if (mx > 1.0) col = col / mx * (1.0 + (mx - 1.0) * 0.15);   // tonu koru
	ALBEDO = col;
}
