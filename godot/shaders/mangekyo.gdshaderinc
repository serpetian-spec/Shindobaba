// Özelleştirilebilir Mangekyō / Ebedi Mangekyō deseni (3B göz ve 2B önizleme ortak)
// a: x stil (0 çark, 1 yıldız, 2 taç yaprak, 3 shuriken, 4 sarmal, 5 haç, 6 tomoe halkası), y kanat sayısı, z kıvrım, w kalınlık
// b: x iç bebek yarıçapı, y dış halka (0/1), z ters renk (0/1), w dönüş hızı
float ms_ink(vec2 q, vec4 a, vec4 b, float t) {
	float r = length(q);
	if (r > 1.0) return 0.0;
	float n = max(2.0, floor(a.y + 0.5));
	float ang = atan(q.y, q.x) + t * b.w + a.z * r;
	float s = fract(ang * n / 6.28318);
	float d = abs(s - 0.5) * 2.0;           // 0 = kanat ortası, 1 = kanat arası
	float inner = b.x;
	int st = int(a.x + 0.5);
	float ink = 0.0;
	if (st == 0) {
		ink = step(s, a.w * (1.0 - r * 0.45)) * step(inner, r) * step(r, 0.93);
	} else if (st == 1) {
		ink = step(r, mix(inner + 0.12, 0.95, pow(1.0 - d, 1.0 + 3.0 * (1.0 - a.w))));
	} else if (st == 2) {
		float pr = (r - 0.58) / (0.3 + 0.15 * a.w);
		ink = step(pr * pr + pow((1.0 - d) * 1.4, 2.0), 0.55 * a.w + 0.25);
		ink = max(ink, step(r, inner));
	} else if (st == 3) {
		float edge = (r - inner) * (0.6 + a.w * 1.4);
		ink = step(s, edge) * step(inner, r) * step(r, 0.95);
		ink = max(ink, step(r, inner + 0.05));
	} else if (st == 4) {
		ink = step(fract(ang * n / 6.28318 + r * 1.7), a.w * 0.55) * step(inner * 0.6, r) * step(r, 0.93);
	} else if (st == 5) {
		ink = step(1.0 - d, a.w * 0.22) * step(inner, r) * step(r, 0.93);
		ink = max(ink, step(abs(r - 0.62), 0.045));
	} else {
		float ring = step(abs(r - 0.55), 0.035);
		float tom = 0.0;
		for (int k = 0; k < 8; k++) {
			if (float(k) >= n) break;
			float aa = t * b.w + float(k) * 6.28318 / n;
			tom = max(tom, step(length(q - vec2(cos(aa), sin(aa)) * 0.55), 0.1 + a.w * 0.12));
		}
		ink = max(ring, tom);
	}
	if (b.y > 0.5) ink = max(ink, step(abs(r - 0.94), 0.035));
	ink = max(ink, step(r, inner * 0.45));  // göz bebeği
	return b.z > 0.5 ? 1.0 - ink : ink;
}
