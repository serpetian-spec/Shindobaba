// Özelleştirilebilir Mangekyō / Ebedi Mangekyō deseni (3B göz ve 2B önizleme ortak)
// a: x stil (0 çark, 1 yıldız, 2 taç yaprak, 3 shuriken, 4 sarmal, 5 haç, 6 tomoe halkası, 7 orak, 8 pervane, 9 çiçek, 10 elmas,
//    11 halkalar, 12 kanca, 13 dört bıçak, 14 altı köşeli yıldız, 15 kelebek, 16 kar tanesi, 17 kalkan), y kanat sayısı, z kıvrım, w kalınlık
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
	} else if (st == 7) {   // orak: ince, uca doğru sivrilen kavisli hilal bıçaklar
		float sc = fract(ang * n / 6.28318 + r * 0.9);
		ink = step(abs(sc - 0.5 + (r - 0.6) * 0.6), a.w * 0.12 * (1.2 - r)) * step(inner, r) * step(r, 0.95);
	} else if (st == 8) {   // pervane: geniş bıçaklar, uçta çentik, ortada delik halka
		float bl = step(s, a.w * 0.8) * step(inner, r) * step(r, 0.92);
		float notch = step(abs(s - a.w * 0.6), 0.06) * step(0.7, r);
		ink = max(bl - notch, step(abs(r - inner - 0.06), 0.03));
	} else if (st == 9) {   // çiçek: halka çevresinde yuvarlak taç yapraklar
		float pr = length(vec2((r - 0.68) / 0.22, (1.0 - d) * 1.2 / (0.4 + a.w * 0.6)));
		ink = max(step(pr, 1.0) - step(pr, 0.55), step(abs(r - 0.42), 0.04));
	} else if (st == 10) {   // elmas: keskin baklava uçlar
		ink = step(r, inner + 0.08 + 0.85 * pow(max(0.0, 1.0 - d * (1.6 - a.w)), 2.0)) * step(inner * 0.8, r);
		ink = max(ink, step(r, inner + 0.03));
	} else if (st == 11) {   // iç içe halkalar + ışınlar
		ink = step(abs(fract(r * (2.0 + a.w * 3.0)) - 0.5), 0.08) * step(inner, r) * step(r, 0.93);
		ink = max(ink, step(1.0 - d, 0.06) * step(inner, r) * step(r, 0.93));
	} else if (st == 12) {   // kanca: halkadan dışa kıvrılan virgül kancalar
		float ring2 = step(abs(r - 0.48), 0.03);
		float hk = step(abs(s - (r - 0.48) * (1.5 + a.z * 0.3)), 0.05 + a.w * 0.08) * step(0.48, r) * step(r, 0.9);
		ink = max(ring2, hk);
	} else if (st == 13) {   // dört kavisli bıçak dış halkaya bağlanır
		ink = step(abs(s - 0.5), a.w * 0.16) * step(inner, r) * step(r, 0.95);
		ink = max(ink, step(abs(r - 0.92), 0.04));
	} else if (st == 14) {   // altı köşeli yıldız (iç içe iki üçgen)
		float aa = atan(q.y, q.x) + t * b.w;
		float k3 = 3.0;
		float tri1 = cos(3.14159 / k3) / cos(mod(aa, 6.28318 / k3) - 3.14159 / k3);
		float tri2 = cos(3.14159 / k3) / cos(mod(aa + 3.14159 / k3, 6.28318 / k3) - 3.14159 / k3);
		float rr = 0.55 + a.w * 0.3;
		ink = max(step(abs(r - rr * tri1), 0.05), step(abs(r - rr * tri2), 0.05));
		ink = max(ink, step(r, inner));
	} else if (st == 15) {   // kelebek: iki büyük kanat lobu
		float lob = abs(sin(ang * max(1.0, floor(n * 0.5))));
		ink = step(r, 0.3 + 0.65 * lob * (0.5 + a.w * 0.6)) * step(inner, r);
		ink = max(ink, step(r, inner + 0.03));
	} else if (st == 16) {   // kar tanesi: ışınlar ve dallar
		float spoke = step(1.0 - d, 0.05 + a.w * 0.04);
		float br = step(abs(fract(r * 4.0) - 0.5), 0.12) * step(1.0 - d, 0.25) * step(0.3, r);
		ink = max(spoke, br) * step(inner, r) * step(r, 0.93);
		ink = max(ink, step(r, inner + 0.02));
	} else if (st == 17) {   // kalkan: dolu disk, içinde boşluk bıçaklar (ters çark)
		ink = (1.0 - step(s, a.w * 0.5) * step(inner + 0.1, r)) * step(r, 0.8);
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
