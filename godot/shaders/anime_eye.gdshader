// Çizilmiş anime gözü: göz deliği deriyle kapatılır, bu katman üstüne gözü ÇİZER (göz biçimi, kirpik çizgisi, iris, bebek, parlama).
// Her göz tasarımı ayrı eğrilerle tanımlı (çekiştirilmiş tek göz değil). Dōjutsu desenleri vroid_eye ile aynı (iris uzayı iq).
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;
#include "res://shaders/mangekyo.gdshaderinc"

uniform vec4 eye_color : source_color = vec4(0.3, 0.5, 0.9, 1.0);
uniform int dojutsu = 0;
uniform int sage_eyes = 0;
uniform int tomoe = 3;
uniform int dojutsu_l = 0;
uniform int tomoe_l = 3;
uniform vec4 ms_r_a = vec4(0.0, 3.0, 1.5, 0.5);
uniform vec4 ms_r_b = vec4(0.22, 0.0, 0.0, 0.6);
uniform vec4 ms_l_a = vec4(0.0, 3.0, 1.5, 0.5);
uniform vec4 ms_l_b = vec4(0.22, 0.0, 0.0, 0.6);
uniform vec4 ms_col_r : source_color = vec4(0.9, 0.05, 0.06, 1.0);
uniform vec4 ms_col_l : source_color = vec4(0.9, 0.05, 0.06, 1.0);
uniform float hit_flash = 0.0;
uniform float simple_hl = 0.0;
uniform vec3 eye_c_r = vec3(-0.032, 1.62, 0.08);
uniform vec3 eye_c_l = vec3(0.032, 1.62, 0.08);
uniform float iris_r3 = 0.011;
uniform vec2 iris_r2 = vec2(0.0);
// göz akı (eski vroid_sclera ile aynı adlar: Rinnegan / Ketsuryūgan tüm gözü boyar)
uniform vec4 tint_r : source_color = vec4(1.0);
uniform vec4 tint_l : source_color = vec4(1.0);
uniform float rings_r = 0.0;
uniform float rings_l = 0.0;
// tasarım (hepsi göz arası mesafe biriminde)
uniform float eye_d = 0.08;
uniform vec4 sh_a = vec4(-0.22, 0.26, 0.0, 0.01);   // iç köşe x, dış köşe x, iç köşe y, dış köşe y
uniform vec4 sh_b = vec4(0.16, 0.45, 0.8, 0.0);     // üst kapak: yükseklik, tepe yeri, yuvarlaklık üssü
uniform vec4 sh_c = vec4(0.10, 0.5, 0.9, 0.0);      // alt kapak: derinlik, dip yeri, yuvarlaklık üssü
uniform vec4 lash_a = vec4(0.028, 0.012, 0.03, 0.3);  // üst çizgi kalınlığı, dışa doğru ek, kuyruk boyu, kuyruk yönü (yukarı +)
uniform vec4 lash_b = vec4(0.008, 0.45, 0.0, 0.0);    // alt çizgi kalınlığı, alt çizgi payı (dıştan), çift kapak çizgisi aralığı, göz çevresi koyu halka
uniform vec4 iris_p = vec4(0.10, 0.0, 0.32, 0.0);     // iris yarıçapı, iris dikey kayma, bebek oranı (0 = bebeksiz), 1 = düz koyu nokta göz
uniform vec4 line_col : source_color = vec4(0.07, 0.05, 0.06, 1.0);
varying vec3 lp;

void vertex() {
	lp = VERTEX;
}

vec3 rinne_col(vec3 p, vec3 c, float ir) {
	float d = length((p - c).xy);
	float sp = ir * 0.26;
	vec3 col = mix(vec3(0.76, 0.68, 0.92), vec3(0.62, 0.52, 0.84), clamp(d / (ir * 3.0), 0.0, 1.0));
	float f = fract(d / sp);
	float w = fwidth(d / sp) * 0.7 + 0.03;
	float line = 1.0 - smoothstep(w * 0.5, w, min(f, 1.0 - f));
	col = mix(col, vec3(0.2, 0.13, 0.3), line);
	if (d < ir * 0.14) col = vec3(0.05, 0.03, 0.08);
	return col;
}

float arc(float t, float peak, float k) {
	float w = t < peak ? 0.5 * t / max(peak, 0.001) : 0.5 + 0.5 * (t - peak) / max(1.0 - peak, 0.001);
	return pow(max(sin(3.14159 * clamp(w, 0.0, 1.0)), 0.0), k);
}

void fragment() {
	bool left = lp.x > 0.0;
	float eye_side = left ? 1.0 : -1.0;
	vec3 ec = left ? eye_c_l : eye_c_r;
	// göz uzayı: +x dışa (şakağa), +y yukarı; birim = göz arası
	vec2 p = vec2((lp.x - ec.x) * eye_side, lp.y - ec.y) / eye_d;
	float aa = fwidth(p.x) * 1.2 + 0.0015;
	float t = (p.x - sh_a.x) / (sh_a.y - sh_a.x);
	float tc = clamp(t, 0.0, 1.0);
	float yb = mix(sh_a.z, sh_a.w, tc);
	float yu = yb + sh_b.x * arc(tc, sh_b.y, sh_b.z);
	float yl = yb - sh_c.x * arc(tc, sh_c.y, sh_c.z);
	float in_x = smoothstep(0.0, aa * 2.0, t) * (1.0 - smoothstep(1.0 - aa * 2.0, 1.0, t));
	float inside = smoothstep(yl - aa, yl + aa, p.y) * (1.0 - smoothstep(yu - aa, yu + aa, p.y)) * in_x;
	// üst kirpik çizgisi: içte ince, dışa doğru kalınlaşır
	float th = (lash_a.x + lash_a.y * pow(tc, 1.5)) * smoothstep(-0.02, 0.14, t);
	float up = smoothstep(yu - aa, yu + aa, p.y) * (1.0 - smoothstep(yu + th - aa, yu + th + aa, p.y)) * smoothstep(-0.03, 0.0, t) * (1.0 - smoothstep(1.0, 1.0 + aa * 3.0, t));
	// kuyruk: dış köşeden öteye uzayıp incelen çizgi
	float wing = 0.0;
	if (lash_a.z > 0.001) {
		vec2 oc = vec2(sh_a.y, sh_a.w);
		vec2 wd = normalize(vec2(1.0, lash_a.w));
		vec2 wq = p - oc;
		float wl = dot(wq, wd);
		float wk = clamp(wl / lash_a.z, 0.0, 1.0);
		float half_w = (lash_a.x + lash_a.y) * 0.55 * (1.0 - wk);
		float wn = abs(dot(wq, vec2(-wd.y, wd.x)) - half_w);
		wing = (1.0 - smoothstep(half_w - aa, half_w + aa, wn)) * step(-0.01, wl) * (1.0 - smoothstep(lash_a.z - aa, lash_a.z, wl));
	}
	// alt çizgi: dış köşeden içe doğru bir pay
	float lt = lash_b.x * smoothstep(1.0 - lash_b.y - 0.08, 1.0 - lash_b.y + 0.08, t);
	float lo = (1.0 - smoothstep(yl - aa, yl + aa, p.y)) * smoothstep(yl - lt - aa, yl - lt + aa, p.y) * in_x * step(0.0005, lt);
	// çift kapak çizgisi
	float cr = 0.0;
	if (lash_b.z > 0.001) {
		float yc = yu + th + lash_b.z * (0.6 + 0.4 * arc(tc, 0.5, 1.0));
		cr = (1.0 - smoothstep(0.004, 0.004 + aa, abs(p.y - yc))) * smoothstep(0.12, 0.25, t) * (1.0 - smoothstep(0.8, 0.95, t));
	}
	// göz çevresi koyu halka (uykusuz / sürmeli göz)
	float ring = 0.0;
	if (lash_b.w > 0.001) {
		float ro = max(yl - p.y, p.y - yu);
		ring = (1.0 - smoothstep(lash_b.w - aa, lash_b.w + aa, ro)) * smoothstep(-0.05, 0.02, t) * (1.0 - smoothstep(0.98, 1.06, t)) * (1.0 - inside);
	}
	float line = clamp(max(max(up, wing), max(lo, ring)), 0.0, 1.0);
	float a_all = max(inside, max(line, cr));
	if (a_all < 0.5) discard;
	// göz akı + üst kapak gölgesi
	vec3 wt = (left ? tint_l : tint_r).rgb;
	vec3 col = vec3(0.97, 0.97, 0.98) * wt;
	col *= mix(0.80, 1.0, smoothstep(0.0, 0.05, yu - p.y));
	if ((left ? rings_l : rings_r) > 0.5) col = rinne_col(lp, ec, iris_r3);
	// iris
	float ir = iris_p.x * 1.12;
	// dōjutsu: desen okunabilsin diye iris daha iri (dar gözde kapaklar yine keser)
	if ((left ? dojutsu_l : dojutsu) > 0 || sage_eyes > 0) ir = max(ir * 1.22, 0.105);
	vec2 iq = vec2(p.x * eye_side, -(p.y - iris_p.y)) / ir;   // desen uzayı: vroid_eye ile aynı (x model yönü, y aşağı)
	float rr = length(iq);
	if (rr < 1.0 + aa / ir) {
		float l = mix(0.20, 0.42, smoothstep(-0.9, 0.9, iq.y));   // üstte koyu, altta açık (anime iris)
		l = mix(l, 0.08, smoothstep(0.80, 0.98, rr));             // koyu dış halka
		vec4 tx = vec4(vec3(l), 1.0);
		vec4 c = vec4(eye_color.rgb * (0.35 + l * 1.5), 1.0);
		if (iris_p.w > 0.5) c.rgb = line_col.rgb;
		int dk = eye_side > 0.0 ? dojutsu_l : dojutsu;
		if (sage_eyes > 0 && dk == 0) {
			vec2 sq = iq;
			float sr = length(sq);
			if (sr < 1.0) {
				vec3 scol = sage_eyes == 2 ? vec3(0.95, 0.8, 0.15) : (sage_eyes == 3 ? vec3(0.75, 0.95, 0.55) : vec3(1.0, 0.78, 0.15));
				scol = mix(scol, scol * 0.6, smoothstep(0.55, 1.0, sr));
				bool pupil = sage_eyes == 1 ? (abs(sq.y) < 0.16 && abs(sq.x) < 0.62) : (sage_eyes == 2 ? (abs(sq.x) < 0.12 && abs(sq.y) < 0.75) : sr < 0.22);
				if (pupil) scol = vec3(0.03);
				c = vec4(mix(scol, c.rgb, smoothstep(0.92, 1.0, sr) * 0.5), 1.0);
			}
		}
		int tm = eye_side > 0.0 ? tomoe_l : tomoe;
		if (dk == 6) {
			// rinnegan: tüm iris yüzeyi lila, eşmerkezli halkalar (dokudaki asıl iris/bebek görünmez), küçük bebek
			c = vec4(rinne_col(lp, lp.x > 0.0 ? eye_c_l : eye_c_r, iris_r3), tx.a);
		} else if (dk > 0) {
			vec2 q = iq;
			float r = length(q);
			if (dk != 2 && dk != 7 && dk != 8) {
				// sharingan ailesi: desenin arkasında kalan asıl göz rengi görünmesin (iris dokusu koyu kırmızıya boyanır)
				float l2 = dot(tx.rgb, vec3(0.3, 0.59, 0.11));
				c.rgb = mix(vec3(0.5, 0.0, 0.02) * (0.35 + l2 * 1.5), tx.rgb, smoothstep(0.75, 0.95, l2));
			}
			if (r < 1.0) {
				float ang = atan(q.y, q.x);
				vec3 col;
				if (dk == 6) {
					// rinnegan: lila iris, eşmerkezli halkalar
					col = vec3(0.72, 0.62, 0.9);
					if (abs(fract(r * 3.2) - 0.5) < 0.1) col = vec3(0.2, 0.12, 0.28);
				} else if (dk == 7) {
					// tenseigan: mavi, çiçek desenli parlak iris
					col = mix(vec3(0.55, 0.85, 1.0), vec3(0.15, 0.45, 0.95), r);
					if (abs(sin(atan(q.y, q.x) * 6.0)) * r > 0.7) col *= 1.3;
				} else if (dk == 8) {
					// jōgan: mavi-beyaz, ince damarlı
					col = vec3(0.75, 0.88, 1.0) * (0.9 + 0.1 * sin(atan(q.y, q.x) * 24.0));
				} else if (dk == 3) {
					// ketsuryūgan (Kan Ejderi Gözü): göz akı dahil tüm göz kan kırmızısı, ortada dikey ince yarık bebek;
					// Sharingan gibi siyah dış halka / tomoe / desen YOK — yalnız ince kan damarı çizgileri
					float ang3 = atan(q.y, q.x);
					col = mix(vec3(0.85, 0.05, 0.06), vec3(0.42, 0.0, 0.02), smoothstep(0.15, 1.0, r));
					float vein = abs(sin(ang3 * 9.0 + sin(r * 7.0) * 0.6));
					col *= 0.88 + 0.12 * smoothstep(0.85, 1.0, vein) * r;
					col += vec3(0.25, 0.02, 0.0) * (1.0 - smoothstep(0.0, 0.45, r)) * (0.75 + 0.25 * sin(TIME * 3.0));
					if (abs(q.x) < 0.07 * (1.0 - q.y * q.y * 0.6) && abs(q.y) < 0.78) col = vec3(0.04, 0.0, 0.0);
				} else if (dk == 2) {
					// byakugan: göz bebeği yok, soluk lila halkalar
					col = mix(vec3(0.93, 0.92, 1.0), vec3(0.78, 0.76, 0.9), smoothstep(0.6, 1.0, r));
					col *= 0.95 + 0.05 * sin(r * 40.0);
				} else {
					col = mix(vec3(0.95, 0.06, 0.06), vec3(0.55, 0.0, 0.02), smoothstep(0.55, 1.0, r));
					if (r > 0.9) col = vec3(0.05, 0.0, 0.0);
					if (r < 0.2) col = vec3(0.02);
					float spin = TIME * 0.6;
					if (dk == 1) {
						if (abs(r - 0.55) < 0.03) col = vec3(0.08, 0.0, 0.0);
						for (int k = 0; k < 3; k++) {
							if (k >= tm) break;
							float a = spin + float(k) * 6.2831 / 3.0;
							vec2 cpos = vec2(cos(a), sin(a)) * 0.55;
							vec2 tail = vec2(cos(a - 0.45), sin(a - 0.45)) * 0.6;
							if (length(q - cpos) < 0.15 || (length(q - tail) < 0.08 && length(q - cpos) < 0.32)) col = vec3(0.02);
						}
					} else if (dk == 5 || dk == 4) {
						// özelleştirilebilir Mangekyō / Ebedi Mangekyō
						vec4 ma = eye_side > 0.0 ? ms_l_a : ms_r_a;
						vec4 mb = eye_side > 0.0 ? ms_l_b : ms_r_b;
						vec3 base = (eye_side > 0.0 ? ms_col_l : ms_col_r).rgb;
						col = mix(base, base * 0.55, smoothstep(0.55, 1.0, r));
						if (ms_ink(q, ma, mb, TIME) > 0.5) col = vec3(0.02);
					}
				}
				c = vec4(mix(col, c.rgb, smoothstep(0.92, 1.0, r) * 0.5), 1.0);
			}
		}
		if (((left ? dojutsu_l : dojutsu) == 0) && sage_eyes == 0 && iris_p.w < 0.5) {
			if (iris_p.z > 0.001 && rr < iris_p.z) c.rgb = vec3(0.03, 0.02, 0.03);   // bebek
			float hd = length(iq - vec2(-0.36, -0.38));
			c.rgb = mix(c.rgb, vec3(1.0), 1.0 - smoothstep(0.16, 0.22, hd));
		}
		col = mix(col, c.rgb, 1.0 - smoothstep(1.0 - aa / ir, 1.0 + aa / ir, rr));
	}
	col = mix(col, line_col.rgb, max(line, cr * (1.0 - inside)));
	ALBEDO = mix(col, vec3(1.0), hit_flash);
}
