// Saç maskesi: başlık (alın koruyucu, şapka, sarık...) bölgesinde saç başlığın dışına taşmasın.
// hm_xf: mesh yerel -> karakter model uzayı (Y yukarı, +Z yüz). Dilimler: y0..y1 arasında elips (merkez cx,cz; yarıçap rx,rz) dışı atılır.
// Düzlemler: dot(n, p) > d olan saç atılır (şapka/kapüşon içinde kalan saç zaten görünmez, dışarı taşan kesilir).
uniform bool hm_on = false;
uniform mat4 hm_xf = mat4(1.0);
uniform vec4 hm_slab0 = vec4(9.0, -9.0, 1.0, 1.0);   // y0, y1, rx, rz
uniform vec2 hm_c0 = vec2(0.0);
uniform vec4 hm_slab1 = vec4(9.0, -9.0, 1.0, 1.0);
uniform vec2 hm_c1 = vec2(0.0);
uniform vec4 hm_plane0 = vec4(0.0, 1.0, 0.0, 99.0);
uniform vec4 hm_plane1 = vec4(0.0, 1.0, 0.0, 99.0);
varying vec3 hm_p;

bool hm_out_slab(vec3 p, vec4 s, vec2 c) {
	if (p.y < s.x || p.y > s.y) return false;
	vec2 q = (p.xz - c) / s.zw;
	return dot(q, q) > 1.0;
}

bool hm_cut(vec3 p) {
	if (!hm_on) return false;
	return hm_out_slab(p, hm_slab0, hm_c0) || hm_out_slab(p, hm_slab1, hm_c1)
		|| dot(hm_plane0.xyz, p) > hm_plane0.w || dot(hm_plane1.xyz, p) > hm_plane1.w;
}
