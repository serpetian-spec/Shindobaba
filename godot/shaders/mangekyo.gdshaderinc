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
	} else if (st == 18) {   // Madara: halka + dışa bakan üç yuvarlak taç yaprak
		float pr = length(vec2((r - 0.62) / (0.22 + a.w * 0.1), (1.0 - d) * 1.6));
		ink = max(step(pr, 1.0), step(abs(r - 0.6), 0.04));
		ink = max(ink, step(r, inner + 0.04));
	} else if (st == 19) {   // Sasuke: içbükey kenarlı üç uçlu yıldız + iç halka
		float spike = pow(1.0 - d, 2.5 - a.w * 1.5);
		ink = step(r, inner + 0.15 + 0.8 * spike) * step(inner * 0.5, r);
		ink = max(ink - step(abs(r - (inner + 0.12)), 0.025), 0.0);
	} else if (st == 20) {   // Shisui: dört kalın kıvrık kanatlı fırıldak
		float sc = fract(ang * n / 6.28318 + r * 0.6);
		ink = step(sc, a.w * 0.7 * (1.1 - r * 0.6)) * step(inner, r) * step(r, 0.93);
		ink = max(ink, step(abs(r - 0.93), 0.03));
	} else if (st == 21) {   // Kakashi/Obito: içten dışa ince orak kollar
		float sc = fract(ang * n / 6.28318 - r * 1.3);
		ink = step(abs(sc - 0.5), a.w * 0.1 + 0.03) * step(inner, r) * step(r, 0.95);
		ink = max(ink, step(r, inner + 0.08));
	} else if (st == 22) {   // Izuna: uçta geriye kıvrılan kanca bıçaklar
		float blade = step(s, a.w * 0.45) * step(inner, r) * step(r, 0.8);
		float hook = step(abs(s - a.w * 0.45 - (r - 0.8) * 1.2), 0.06) * step(0.75, r) * step(r, 0.95);
		ink = max(blade, hook);
	} else if (st == 23) {   // Indra: üç düz çizgi, uçlarında hilal
		float line = step(1.0 - d, 0.07) * step(inner, r) * step(r, 0.7);
		float cres = step(abs(r - 0.78), 0.06 + a.w * 0.04) * step(1.0 - d, 0.45);
		ink = max(line, cres);
	} else if (st == 24) {   // Ebedi Sasuke: yıldız + üç bıçak + dış halka
		float spike = pow(1.0 - d, 2.0);
		float star = step(r, inner + 0.1 + 0.55 * spike);
		float sc = fract(ang * n / 6.28318 + 0.5 + r * 0.5);
		float bl = step(sc, a.w * 0.25) * step(0.5, r) * step(r, 0.93);
		ink = max(max(star, bl), step(abs(r - 0.93), 0.03));
	} else if (st == 25) {   // Ebedi Madara: taç yapraklar + aralarında düz ışınlar
		float pr = length(vec2((r - 0.62) / 0.24, (1.0 - d) * 1.6));
		float spoke = step(d, 0.06) * step(inner, r) * step(r, 0.95);
		ink = max(max(step(pr, 1.0), spoke), step(abs(r - 0.6), 0.04));
	} else if (st == 26) {   // halka boyunca dizili küçük daireler
		float m2 = fract(ang * n * 2.0 / 6.28318);
		vec2 lc = vec2((m2 - 0.5) * 6.28318 * r / (n * 2.0), r - 0.65);
		ink = max(step(length(lc), 0.12 + a.w * 0.06), step(r, inner + 0.03));
	} else if (st == 27) {   // haç biçimli halka taç yaprakları
		float pr = length(vec2((r - 0.55) / 0.35, (1.0 - d) * 2.2));
		ink = max(step(pr, 1.0) - step(pr, 0.5), step(r, inner + 0.06));
	} else if (st == 28) {   // gül: iç içe sarmal yapraklar
		float sp = fract(ang / 6.28318 * n + r * 3.0);
		ink = step(abs(sp - 0.5), 0.12 + a.w * 0.1) * step(inner, r) * step(r, 0.92);
	} else if (st == 29) {   // kum saati: iki büyük karşıt lob
		float lob = pow(abs(cos(ang)), 1.5);
		ink = step(r, 0.25 + 0.7 * lob * (0.6 + a.w * 0.5)) * step(inner * 0.6, r);
	} else if (st == 30) {   // güneş: çok sayıda ince ışın + dolu merkez
		float fs = fract(ang * n * 3.0 / 6.28318);
		ink = step(abs(fs - 0.5), 0.1 + a.w * 0.08) * step(0.35, r) * step(r, 0.92);
		ink = max(ink, step(r, 0.33));
	} else if (st == 31) {   // dişli çark: halka + dışa dişler
		float tooth = step(fract(ang * n * 2.0 / 6.28318), 0.5) * step(0.72, r) * step(r, 0.88);
		ink = max(max(tooth, step(abs(r - 0.68), 0.06)), step(r, inner + 0.03));
	} else if (st == 32) {   // üç kıvrımlı virgül (triskel)
		float sp = fract(ang * n / 6.28318 + r * r * 1.4);
		ink = step(sp, a.w * 0.35 * (1.3 - r)) * step(inner * 0.8, r) * step(r, 0.9);
		ink = max(ink, step(r, inner * 0.8 + 0.03));
	} else if (st == 33) {   // hilaller: halkaya oturan ay biçimleri
		float ka = floor(ang * n / 6.28318 + 0.5) * 6.28318 / n;
		vec2 c1 = vec2(cos(ka), sin(ka)) * 0.62;
		float big = step(length(q - c1), 0.24 + a.w * 0.06);
		float cut = step(length(q - c1 * 1.15), 0.2);
		ink = max(big - cut, step(r, inner + 0.03));
	} else if (st == 34) {   // göz içinde göz: iç ve dış halka + küçük tomoe
		float ring3 = step(abs(r - 0.42), 0.03) + step(abs(r - 0.82), 0.03);
		float tm2 = step(length(vec2(r - 0.62, (1.0 - d) * 0.6)), 0.1 + a.w * 0.05);
		ink = clamp(ring3 + tm2, 0.0, 1.0);
	} else if (st == 35) {   // nilüfer: iki kat taç yaprak
		float p1 = length(vec2((r - 0.45) / 0.2, (1.0 - d) * 1.8));
		float s2 = fract(ang * n / 6.28318 + 0.5);
		float d2 = abs(s2 - 0.5) * 2.0;
		float p2 = length(vec2((r - 0.75) / 0.18, (1.0 - d2) * 1.8));
		ink = max(step(p1, 1.0), step(p2, 1.0));
	} else if (st == 36) {   // dalga halkası: sinüs biçimli kalın halka
		float wv = 0.6 + 0.12 * sin(ang * n);
		ink = max(step(abs(r - wv), 0.06 + a.w * 0.05), step(r, inner + 0.04));
	} else if (st == 37) {   // diken halkası: içe dönük sivri dikenler
		float spk = step(r, 0.92) * step(0.92 - (1.0 - d) * (0.35 + a.w * 0.3), r);
		ink = max(spk, step(abs(r - 0.93), 0.03));
		ink = max(ink, step(r, inner + 0.03));
	} else if (st == 38) {   // pusula: dört uzun + dört kısa uç
		float d8 = abs(fract(ang * 8.0 / 6.28318) - 0.5) * 2.0;
		float d4 = abs(fract(ang * 4.0 / 6.28318) - 0.5) * 2.0;
		float longp = step(r, 0.2 + 0.75 * pow(1.0 - d4, 3.0));
		float shortp = step(r, 0.2 + 0.4 * pow(1.0 - d8, 3.0));
		ink = max(longp, shortp) * step(inner * 0.5, r);
	} else if (st == 39) {   // dişler: dış halkadan içe üçgen dişler
		float tooth = step(r, 0.92) * step(0.92 - (1.0 - d) * 0.5, r);
		ink = max(max(tooth, step(abs(r - 0.93), 0.035)), step(r, inner + 0.08));
	} else if (st == 40) {   // girdap: iki kalın kollu sarmal
		float sp = fract(ang * 2.0 / 6.28318 + r * 1.2);
		ink = step(sp, 0.25 + a.w * 0.2) * step(inner, r) * step(r, 0.93);
	} else if (st == 41) {   // dönmüş kare + köşe ışınları
		vec2 rq = vec2(q.x * 0.7071 - q.y * 0.7071, q.x * 0.7071 + q.y * 0.7071);
		float sq = max(abs(rq.x), abs(rq.y));
		ink = max(step(abs(sq - 0.45), 0.05), step(1.0 - d, 0.05) * step(0.45, r) * step(r, 0.9));
		ink = max(ink, step(r, inner + 0.03));
	} else if (st == 42) {   // altıgen + ışınlar
		float hx = cos(3.14159 / 6.0) / cos(mod(atan(q.y, q.x), 6.28318 / 6.0) - 3.14159 / 6.0);
		ink = max(step(abs(r - 0.6 * hx), 0.05), step(1.0 - d, 0.05) * step(inner, r) * step(r, 0.6));
	} else if (st == 43) {   // alev lobları: dalgalı kenarlı kanatlar
		float fl = 0.55 + 0.35 * pow(1.0 - d, 2.0) + 0.06 * sin(r * 30.0 + ang * 3.0);
		ink = step(r, fl * (0.7 + a.w * 0.4)) * step(inner, r);
	} else if (st == 44) {   // tüy: saçaklı bıçaklar
		float spine = step(abs(s - 0.5), 0.04) * step(inner, r) * step(r, 0.92);
		float fringe = step(abs(fract(r * 10.0) - 0.5), 0.2) * step(abs(s - 0.5), 0.2 + a.w * 0.1) * step(0.35, r) * step(r, 0.9);
		ink = max(spine, fringe);
	} else if (st == 45) {   // taç: dışta sivri tepe halkası
		float crown = step(r, 0.72 + 0.22 * pow(1.0 - d, 4.0)) * step(0.62, r);
		ink = max(crown, step(r, inner + 0.06));
	} else if (st == 46) {   // iki sıra nokta
		float m1 = fract(ang * n / 6.28318);
		float m3 = fract(ang * n / 6.28318 + 0.5);
		float dot1 = step(length(vec2((m1 - 0.5) * 2.4, (r - 0.45) * 5.0)), 0.6 + a.w * 0.3);
		float dot2 = step(length(vec2((m3 - 0.5) * 2.4, (r - 0.78) * 5.0)), 0.6 + a.w * 0.3);
		ink = max(max(dot1, dot2), step(r, inner + 0.03));
	} else if (st == 47) {   // gül eğrisi düğüm
		float rose = abs(cos(ang * n * 0.5));
		ink = step(abs(r - rose * 0.9), 0.05 + a.w * 0.05) * step(inner * 0.5, r);
		ink = max(ink, step(abs(r - 0.94), 0.03));
	} else if (st == 48) {   // Rinne-Sharingan halkası: eşmerkezli halkalar + halka üstünde tomoe
		float rings = step(abs(fract(r * 3.0) - 0.5), 0.07) * step(inner, r) * step(r, 0.95);
		float ka = floor(ang * n / 6.28318 + 0.5) * 6.28318 / n;
		float tom = 0.0;
		for (int k = 0; k < 3; k++) {
			float rr = 0.33 + float(k) * 0.33;
			tom = max(tom, step(length(q - vec2(cos(ka + float(k) * 0.4), sin(ka + float(k) * 0.4)) * rr), 0.06 + a.w * 0.04));
		}
		ink = max(rings, tom);
	} else if (st == 49) {   // Sharingan kılıcı: merkezden çıkan uzun keskin kılıç bıçakları + kabza halkası
		float blade = step(r, 0.95) * step(inner + 0.05, r) * step(1.0 - d, (0.12 + a.w * 0.1) * (1.0 - r * 0.85));
		float guard = step(abs(r - (inner + 0.08)), 0.03);
		ink = max(max(blade, guard), step(r, inner));
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
