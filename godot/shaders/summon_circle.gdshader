// Kuchiyose mührü (REFERANS: animede avucun altından yayılan yazı çizgileri): dolu çember yok —
// avuçtan dışa uzanan 6 ince, tırtıklı mürekkep yazı çizgisi + aralarını bağlayan iki kat zikzak ağ (yıldız/örümcek ağı).
// grow: merkezden dışa yayılma (0..1), fade: silinme; glow: yayılma ucunda sözleşme rengi parıltı
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

uniform vec4 col : source_color = vec4(0.05, 0.04, 0.06, 1.0);
uniform vec4 glow : source_color = vec4(1.0, 0.6, 0.2, 1.0);
uniform float grow = 1.0;
uniform float fade = 0.0;
uniform float seed = 0.0;

const int N = 6;

float hash(float p) { return fract(sin(p * 127.1 + seed * 31.7) * 43758.5453); }

// yazı fırça darbesi: eksen boyunca tırtıklı zikzak + yer yer dik kısa çentikler (harf izlenimi)
float stroke(float along, float across, float w, float k) {
	// düzensiz ince titreme (el yazısı), düzenli testere dişi değil
	float c0 = floor(along * 70.0);
	float zig = (hash(c0 + k) - 0.5) * 0.03 + sin(along * 140.0 + k * 7.0) * 0.005;
	float zig2 = (hash(c0 + 1.0 + k) - 0.5) * 0.03;
	zig = mix(zig, zig2, fract(along * 70.0));
	float d = abs(across - zig);
	float ink = step(d, w * (0.6 + 0.7 * hash(floor(along * 90.0) + k)));
	// yazı: kısa dik ve eğik darbeler (kanji izlenimi), aralıklı
	float cell = floor(along * 38.0);
	float fa = fract(along * 38.0);
	float h = hash(cell + k * 3.1);
	if (h > 0.55 && abs(fa - 0.5 + (h - 0.75) * (across * 6.0)) < 0.17 && abs(across) < 0.022 + 0.026 * hash(cell + k)) ink = 1.0;
	return ink;
}

float seg(vec2 p, vec2 a, vec2 b, float w, float k, out float t) {
	vec2 ab = b - a;
	t = clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0);
	vec2 dir = normalize(ab);
	vec2 rel = p - a;
	float along = dot(rel, dir);
	float across = dot(rel, vec2(-dir.y, dir.x));
	if (along < 0.0 || along > length(ab)) return 0.0;
	return stroke(along, across, w, k);
}

void fragment() {
	vec2 q = (UV - 0.5) * 2.0;
	float r = length(q);
	if (r > grow || r > 1.0) discard;
	float ink = 0.0;
	float t;
	for (int i = 0; i < N; i++) {
		float a0 = float(i) * 6.2832 / float(N) + 0.35 + (hash(float(i)) - 0.5) * 0.35;
		float a1 = float(i + 1) * 6.2832 / float(N) + 0.35 + (hash(float(i + 1)) - 0.5) * 0.35;
		vec2 d0 = vec2(cos(a0), sin(a0));
		vec2 d1 = vec2(cos(a1), sin(a1));
		float len0 = 0.82 + 0.16 * hash(float(i) + 9.0);
		// avuçtan dışa yazı çizgisi
		ink = max(ink, seg(q, d0 * 0.06, d0 * len0, 0.014, float(i), t));
		// ağ: komşu çizgiler arası iki kat zikzak bağ (iç ve dış)
		float ri = 0.34 + 0.06 * hash(float(i) + 3.0);
		float ro = 0.66 + 0.08 * hash(float(i) + 5.0);
		ink = max(ink, seg(q, d0 * ri, d1 * (ri + 0.03), 0.011, float(i) + 20.0, t));
		ink = max(ink, seg(q, d0 * ro, d1 * (ro - 0.04), 0.011, float(i) + 40.0, t));
		// dış uçlarda kısa çatallanma
		vec2 tip = d0 * len0;
		vec2 br = normalize(d0 + vec2(-d0.y, d0.x) * 0.6);
		ink = max(ink, seg(q, d0 * (len0 - 0.18), tip - d0 * 0.18 + br * 0.16, 0.009, float(i) + 60.0, t));
	}
	// avucun altında küçük mürekkep lekesi
	ink = max(ink, step(r, 0.05));
	if (ink < 0.5) discard;
	float front = smoothstep(grow - 0.12, grow, r);
	ALBEDO = mix(col.rgb, glow.rgb * 1.8, front);
	ALPHA = (1.0 - fade) * 0.96;
}
