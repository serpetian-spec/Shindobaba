// Karakter + bina toon shader'ı: 2 bantlı anime gölge, kenar ışığı, vertex renkleri
shader_type spatial;
render_mode cull_back, diffuse_toon, specular_toon;

uniform vec4 tint : source_color = vec4(1.0);
uniform bool use_vertex_color = true;
uniform sampler2D tex : source_color, filter_linear_mipmap, hint_default_white;
uniform float rim_amount = 0.35;
uniform float spec_amount = 0.0;
uniform vec4 emission_color : source_color = vec4(0.0);
global uniform float g_night;   // gece parlaması (Environment ayarlar; pişirilmiş köylerde ve kiremit çatıda da çalışır)
uniform bool roof_tiles = false;   // çatı: dünya uzayında kiremit sıraları   // gece: pencereler / fenerler / kâğıt lambalar yanar (Environment her kare ayarlar)
uniform float hit_flash = 0.0;
uniform float detail_noise = 0.0;
uniform sampler2D detail_tex : filter_linear_mipmap, repeat_enable;   // gri detay dokusu (ortalama 0.5): sıva / kiremit (dünya uzayı, üç yönlü)
uniform float detail_tex_amt = 0.0;
uniform float detail_tex_scale = 0.4;   // m başına tekrar
uniform float sway = 0.0;
uniform bool cloth_mode = false;
uniform bool hide_masked = false;  // vertex alfa=1 olan bölgeler çizilmez (kıyafet altı)   // doku (ten) + vertex rengi (kıyafet, alfa = maske)
uniform bool palette_mode = false;  // vertex COLOR.r = renk yuvası*0.1 (0 = ten dokusu)
uniform vec4 pal[12] : source_color;  // 0 ten 1 üst 2 vurgu 3 alt 4 sargı 5 yelek 6 sandalet 7 koyu 8 dış giysi 9 aksesuar 10 başlık 11 yüz
uniform vec4 rig_a = vec4(0.21, 0.46, 0.7, 1.52);   // üst kol x, dirsek x, el x, boyun y (dinlenme pozu)
uniform vec4 rig_b = vec4(0.95, 0.54, 0.09, 1.31);  // kalça y, diz y, ayak bileği y, üst göğüs y
uniform int top_style = 1;    // 0 tişört, 1 uzun kollu, 2 ceket, 3 yüksek yakalı, 4 kolsuz, 5 kimono, 6 gi, 7 uzun kollu yüksek yaka, 8 atlet, 9 tek kollu
uniform int pants_style = 0;  // 0 ninja pantolonu, 1 şort, 2 sivil uzun pantolon, 3 sargılı, 4 bol paça, 5 kapri, 6 kısa şort
uniform int layer = 0;        // 0 vücut, 1 kumaş kabuğu, 2 yelek
uniform int pants_pattern = 0;  // 1 yan şerit 2 dizlik 3 kamuflaj 4 dama 5 ince çizgi 6 diz altı iki renk 7 paça bandı 8 yamalı 9 kargo cep 10 sarmal sargı 11 alev paça 12 puantiye
uniform vec4 pants_accent : source_color = vec4(0.1, 0.1, 0.12, 1.0);
uniform int top_pattern = 0;  // 1 zincir örgü/ağ, 2 yatay çizgili, 3 yan panelli, 4 yamalı/eskimiş, 5 sırtta arma, 6 kenar biyeli, 7 Uchiha yelpazesi, 8..27 (bkz. Gear üst desenleri)
uniform int vest_style = 0;   // 0 Konoha, 1 Suna, 2 Kiri (yatay dikiş), 3 Kumo (tek askı), 4 Iwa (tek kol), 5 ANBU plaka, 6 samuray lamel,
                              // 7 Kök (dikey dikiş), 8 zincir yelek, 9 kayış koşum, 10 deri pullu zırh, 11 göğüs plakası
uniform float wear = 0.0;      // kir/yıpranma (haydut, kaçak ninja)
uniform int foot_kind = 0;     // 0 sandalet, 1 tabi, 2 çizme (baldıra kadar), 3 dize kadar sargılı sandalet, 4 bilek botu, 5 diz çizmesi, 6 sargılı bot, 7 zırhlı tozluk
uniform int foot_pattern = 0;  // 1 burun kapağı 2 çapraz bağcık 3 konç bandı 4 yatay şerit 5 metal kaval plakası 6 kürk kenar 7 kontrast taban 8 shuriken perçin
uniform int outer_pattern = 0; // dış giysi: 1 etek bandı, 2 alev etek, 3 hilal motifi, 4 hasır lifleri, 5 yırtık/kirli, 6 kızıl bulut
uniform vec4 outer_accent : source_color = vec4(0.75, 0.12, 0.12, 1.0);
uniform float outer_hem = 0.5;  // dış giysinin etek ucu (dinlenme pozu y)
uniform bool gloves = false;
uniform bool arm_wraps = false;
uniform int outer_sleeves = 0; // 1: dış giysi kolları (palto/haori)
uniform bool foot_cover = false; // tabi: ayak tamamen kapalı
varying float slot_ov;
uniform vec4 face_a = vec4(0.0);   // çene genişliği, çene ucu, elmacık, burun (metre)
uniform vec4 face_b = vec4(0.0);   // kaş çıkıntısı, işaret türü (0 yok, 1 burun yarası, 2 yanak çizgisi, 3 çil, 4 kırışık), -, -
uniform vec4 face_ref = vec4(0.0, 1.7, 0.08, 0.0);
uniform float outer_gap = 0.075;  // önü açık dış giysinin açıklığının yarı genişliği (m): yelek yalnız bu kadar görünür
uniform int outer_cover = 0;  // yelek katmanı: 1 önü açık dış giysi altında (yalnız ön şerit görünür), 2 kapalı pelerin altında (gizli)
uniform vec4 scalp_cut = vec4(99.0, -99.0, 99.0, 0.0);  // x: bu yüksekliğin üstü, y/z: bu derinliğin arkasında z yüksekliğinin üstü  // saçlıyken gövdenin kafa derisi bu yüksekliğin üstünde çizilmez (saç arasından "kel" görünmesin)  // -, göz y, göz z
uniform vec4 scalp_col = vec4(0.0);   // a>0: kesim bölgesi atılmaz, saç rengine boyanır (ensede delik / saç arasında kel yok)
uniform float fold_amount = 0.0032;
varying vec3 rest;
#include "res://shaders/mangekyo.gdshaderinc"
varying float eye_side;
uniform bool luma_tint = false;    // saç: doku parlaklığı x tint
uniform bool eye_mode = false;     // göz: iris tint, beyaz korunur
uniform vec4 eye_color : source_color = vec4(0.3, 0.5, 0.9, 1.0);
uniform int dojutsu = 0;      // 0 yok, 1 sharingan, 2 byakugan, 3 ketsuryugan, 4 mangekyo
uniform int sage_eyes = 0;    // sennin modu gözü: 1 kurbağa (yatay göz bebeği), 2 yılan (dikey yarık), 3 sümüklü
uniform int sage_marks = 0;   // sennin yüz izleri: 1 turuncu pigment, 2 mor yılan çizgileri, 3 yeşil çizgiler
uniform int tomoe = 3;
uniform int dojutsu_l = 0;    // sol göz (model +X)
uniform int tomoe_l = 3;
uniform vec4 ms_r_a = vec4(0.0, 3.0, 1.5, 0.5);
uniform vec4 ms_r_b = vec4(0.22, 0.0, 0.0, 0.6);
uniform vec4 ms_l_a = vec4(0.0, 3.0, 1.5, 0.5);
uniform vec4 ms_l_b = vec4(0.22, 0.0, 0.0, 0.6);
uniform vec4 ms_col_r : source_color = vec4(0.9, 0.05, 0.06, 1.0);
uniform vec4 ms_col_l : source_color = vec4(0.9, 0.05, 0.06, 1.0);
uniform float iris_r = 0.105;   // göz dokusunda iris yarıçapı (UV)
uniform float byakugan_veins = 0.0;  // yüzde şakak damarları

varying vec3 wpos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void vertex() {
	if (sway > 0.0) {
		vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float k = max(VERTEX.y - 1.5, 0.0);
		float ph = w.x * 0.13 + w.z * 0.09;
		// gövde: yavaş ana salınım + ara sıra esinti; yaprak: küçük hızlı titreşim (sakin, abartısız)
		float gust = 0.6 + 0.4 * sin(TIME * 0.35 + ph * 0.5);
		float s = (sin(TIME * 1.3 + ph) * 0.7 + sin(TIME * 2.9 + ph * 1.7) * 0.3) * sway * k * 0.026 * gust;
		float fl = sin(TIME * 7.0 + w.x * 1.9 + w.y * 2.3 + w.z * 1.3) * sway * 0.035 * smoothstep(2.5, 5.0, k);
		VERTEX.x += s + fl;
		VERTEX.z += s * 0.7 - fl * 0.6;
		VERTEX.y += fl * 0.5;
	}
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	rest = CUSTOM0.xyz;
	eye_side = VERTEX.x;
	slot_ov = CUSTOM0.w;
	if (palette_mode && layer == 0 && rest.y > face_ref.y - 0.2) {
		vec3 p = rest;
		float ey = face_ref.y; float ez = face_ref.z;
		float ax = abs(p.x);
		float jaw = exp(-(pow((ax - 0.055) / 0.03, 2.0) + pow((p.y - (ey - 0.1)) / 0.035, 2.0) + pow((p.z - (ez - 0.05)) / 0.06, 2.0)));
		float chin = exp(-(pow(p.x / 0.03, 2.0) + pow((p.y - (ey - 0.135)) / 0.025, 2.0) + pow((p.z - (ez + 0.0)) / 0.05, 2.0)));
		float cheek = exp(-(pow((ax - 0.05) / 0.025, 2.0) + pow((p.y - (ey - 0.04)) / 0.025, 2.0) + pow((p.z - ez) / 0.04, 2.0)));
		float nose = exp(-(pow(p.x / 0.012, 2.0) + pow((p.y - (ey - 0.04)) / 0.02, 2.0) + pow((p.z - (ez + 0.035)) / 0.025, 2.0)));
		float brow = exp(-(pow((ax - 0.03) / 0.03, 2.0) + pow((p.y - (ey + 0.025)) / 0.012, 2.0) + pow((p.z - (ez + 0.01)) / 0.03, 2.0)));
		VERTEX += NORMAL * (jaw * face_a.x + chin * face_a.y + cheek * face_a.z + nose * face_a.w + brow * face_b.x);
	}
}

// kumaş kıvrımı yükseklik alanı (dinlenme pozu konumu)
float fold_h(vec3 p, int slot) {
	float ax = abs(p.x);
	float n = vnoise(p.xz * 40.0 + p.y * 13.0);
	if (slot == 4) return 0.5 + 0.5 * sin(p.y * 260.0 + p.x * 40.0 + p.z * 25.0);
	bool arm = ax > rig_a.x * 0.9 && p.y > rig_a.w - 0.32;
	if (arm) {
		float e = exp(-pow((ax - rig_a.y) / 0.06, 2.0));
		return sin(ax * 150.0 + n * 4.0 + p.z * 30.0) * (0.25 + e);
	}
	if (p.y < rig_b.x + 0.035) {
		float k = exp(-pow((p.y - rig_b.y) / 0.08, 2.0)) + 0.8 * exp(-pow((p.y - (rig_b.y - 0.15)) / 0.07, 2.0));
		return sin(p.y * 130.0 + n * 5.0 + p.x * 25.0) * (0.25 + k) + sin(p.x * 70.0 + p.z * 50.0) * 0.2;
	}
	float below = clamp((rig_b.w - p.y) / 0.25, 0.0, 1.0);
	return sin(p.x * 65.0 + n * 3.0) * 0.7 * below + sin(p.y * 90.0 + n * 4.0) * 0.12;
}

// dinlenme pozundaki konuma göre renk yuvası: 0 ten, 1 üst, 2 vurgu, 3 alt, 4 sargı, 5 yelek
int cloth_slot(vec3 p) {
	if (p.y < -15.0) return 7;  // sandalet tabanı
	if (p.y < -5.0) return 6;   // sandalet kayışı
	float ax = abs(p.x);
	bool arm = ax > rig_a.x * 0.9 && p.y > rig_a.w - 0.32;
	if (arm) {
		if (ax > rig_a.z - 0.035) return (gloves && ax < rig_a.z + 0.075) ? 9 : 0;
		if (outer_sleeves == 1) return 8;
		if (vest_style == 4 && layer != 0 && p.x > 0.0 && ax < rig_a.y + 0.02) return 5;
		float sleeve = rig_a.z - 0.035;
		if (top_style == 0 || top_style == 3) sleeve = mix(rig_a.x, rig_a.y, 0.5);
		else if (top_style == 4 || top_style == 8 || (top_style == 9 && p.x > 0.0)) sleeve = rig_a.x * 0.9;
		else if (top_style == 6) sleeve = rig_a.y + 0.05;
		if (ax < sleeve) return (top_style == 2 && ax < rig_a.x + 0.07) ? 2 : 1;
		if ((top_style == 3 || arm_wraps) && ax > rig_a.y - 0.02) return 4;
		return 0;
	}
	if (p.y > rig_a.w) {
		bool collar = (top_style == 2 || top_style == 3 || top_style == 4 || top_style == 7) && p.y < rig_a.w + 0.075;
		return collar ? (top_style == 2 ? 2 : 1) : 0;
	}
	float waist = rig_b.x + 0.035;
	if (p.y > waist) {
		if (top_style == 2 && p.y > rig_a.w - 0.1) return 2;
		// kimono: çapraz (sol üstte) yaka bandı
		if ((top_style == 5 || top_style == 6) && p.z > -0.02 && p.y > rig_b.w - 0.22 && abs(p.x + (p.y - rig_a.w) * 0.55) < 0.022) return 2;
		// gi: göğüste derin V yaka (ten görünür)
		if (top_style == 6 && p.z > 0.0 && p.y > rig_b.w - 0.12 && ax < (p.y - (rig_b.w - 0.12)) * 0.5) return 0;
		// atlet: omuzlar açık, ince askı
		if (top_style == 8 && p.y > rig_b.w - 0.04 && (ax > rig_a.x * 0.62 || (ax < 0.07 && p.z > 0.0))) return 0;
		return 1;
	}
	if (p.y < rig_b.z + 0.03) return (foot_cover || foot_kind == 1 || foot_kind == 2 || foot_kind >= 4) ? 6 : 0;
	if (foot_kind == 2 && p.y < rig_b.z + 0.2) return 6;   // çizme konçu
	if (foot_kind == 4 && p.y < rig_b.z + 0.09) return 6;   // bilek botu
	if ((foot_kind == 5 || foot_kind == 7) && p.y < rig_b.y - 0.01) return 6;   // diz çizmesi / zırhlı tozluk
	if (foot_kind == 6 && p.y < rig_b.z + 0.12) return 6;   // sargılı bot: alt kısım deri
	float cut = pants_style == 0 ? rig_b.y - 0.17 : (pants_style == 1 ? rig_b.y - 0.05 : (pants_style == 3 ? rig_b.y + 0.1 : rig_b.z + 0.04));
	if (pants_style == 5) cut = mix(rig_b.y, rig_b.z, 0.45);
	if (pants_style == 6) cut = rig_b.y + 0.12;
	if (p.y > cut) return 3;
	float wrap_top = (pants_style == 0 || pants_style == 3) ? cut + 0.02 : rig_b.y - 0.16;
	if (pants_style == 5) wrap_top = rig_b.z + 0.06;
	if (foot_kind == 3 || foot_kind == 6) wrap_top = max(wrap_top, rig_b.y + 0.02);
	return p.y < wrap_top ? 4 : 0;
}

void fragment() {
	vec4 tx = texture(tex, UV);
	vec4 c = tint * tx;
	if (luma_tint) {
		float l = dot(tx.rgb, vec3(0.3, 0.59, 0.11));
		c = vec4(tint.rgb * (0.35 + l * 1.3), tx.a);
	}
	if (eye_mode) {
		float l = dot(tx.rgb, vec3(0.3, 0.59, 0.11));
		float sclera = smoothstep(0.55, 0.75, l);
		c = vec4(mix(eye_color.rgb * (0.5 + l * 1.2), tx.rgb, sclera), 1.0);
		int dk = eye_side > 0.0 ? dojutsu_l : dojutsu;
		if (sage_eyes > 0 && dk == 0) {
			vec2 sq = (UV - vec2(0.5)) / iris_r;
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
		if (dk > 0) {
			vec2 q = (UV - vec2(0.5)) / iris_r;
			float r = length(q);
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
					} else if (dk == 3) {
						// ketsuryugan: kırmızı iris, siyah haç-yıldız deseni
						float star = abs(sin(ang * 2.0 + spin * 0.3));
						if (star < 0.18 && r > 0.25 && r < 0.85) col = vec3(0.03);
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
	}
	if (hide_masked && COLOR.a > 0.5) discard;
	if (layer == 2 && outer_cover == 2) discard;
	if (layer == 2 && outer_cover == 1 && !(rest.z > 0.0 && abs(rest.x) < outer_gap)) discard;   // dış giysinin altından taşmasın
	bool scalp = layer == 0 && (rest.y > scalp_cut.x || (rest.z < scalp_cut.y && rest.y > scalp_cut.z));
	if (scalp && scalp_col.a < 0.5) discard;
	if (palette_mode) {
		int slot = slot_ov > 0.5 ? int(slot_ov + 0.5) : cloth_slot(rest);
		if (layer == 2) {
			if (rest.y < rig_b.x + 0.03 || rest.y > rig_a.w - 0.01 || abs(rest.x) > rig_a.x * 1.08) discard;
			// Kumo: sağ omuz açık (tek askı)
			if (vest_style == 3 && rest.x < -0.05 && rest.y > rig_b.w - 0.04) discard;
			// koşum: yalnızca çapraz kayışlar + bel kayışı
			if (vest_style == 9) {
				float my = rig_b.w - 0.12;
				bool s1 = abs(rest.x - (rest.y - my) * 0.62) < 0.028;
				bool s2 = abs(rest.x + (rest.y - my) * 0.62) < 0.028;
				if (!(s1 || s2 || rest.y < rig_b.x + 0.1)) discard;
			}
			if (vest_style == 11 && rest.y < rig_b.w - 0.24) discard;
			slot = 5;
		} else if (layer == 1 && slot == 0) discard;
		if (slot == 0 && sage_marks > 0 && rest.y > face_ref.y - 0.07 && rest.y < face_ref.y + 0.05 && rest.z > face_ref.z - 0.05) {
			float ax = abs(rest.x);
			vec2 e = vec2((ax - 0.034) / 0.034, (rest.y - (face_ref.y - 0.003)) / 0.024);
			if (sage_marks == 1 && length(e) < 1.0 && length(e) > 0.55) c.rgb = mix(c.rgb, vec3(0.95, 0.4, 0.08), 0.85);  // göz çevresi turuncu pigment
			if (sage_marks == 2 && ax > 0.045 && ax < 0.075 && abs(rest.y - (face_ref.y - 0.012) + (ax - 0.045) * 0.9) < 0.004) c.rgb = vec3(0.45, 0.15, 0.55);  // mor yılan izi
			if (sage_marks == 3 && ax > 0.03 && ax < 0.06 && rest.y < face_ref.y - 0.02 && abs(fract(ax * 90.0) - 0.5) < 0.12) c.rgb = mix(c.rgb, vec3(0.35, 0.75, 0.4), 0.8);  // yeşil çizgiler
		}
		if (slot == 0 && byakugan_veins > 0.0 && rest.y > face_ref.y - 0.05 && rest.y < face_ref.y + 0.06) {
			float ax = abs(rest.x);
			float v = abs(sin((rest.y - face_ref.y) * 180.0 + ax * 90.0));
			if (ax > 0.035 && ax < 0.08 && rest.z > face_ref.z - 0.05 && v < 0.12) c.rgb = mix(c.rgb, c.rgb * vec3(0.7, 0.62, 0.75), byakugan_veins);
		}
		if (slot == 0 && face_b.y > 0.5 && rest.y > face_ref.y - 0.2) {
			vec3 p = rest; float ey = face_ref.y; float ez = face_ref.z; float ax = abs(p.x);
			int mk = int(face_b.y + 0.5);
			if (mk == 1 && abs(p.y - (ey - 0.03) - p.x * 0.15) < 0.005 && ax < 0.06 && p.z > ez) c.rgb *= vec3(0.75, 0.55, 0.5);
			if (mk == 2 && ax > 0.035 && ax < 0.07 && abs(p.y - (ey - 0.05) + (ax - 0.035) * 0.6) < 0.006 && p.z > ez - 0.03) c.rgb = vec3(0.7, 0.12, 0.12);
			if (mk == 3 && ax > 0.02 && ax < 0.06 && abs(p.y - (ey - 0.035)) < 0.015 && p.z > ez - 0.01 && hash(floor(p.xy * 400.0)) > 0.8) c.rgb *= 0.78;
			if (mk == 4 && p.y > ey + 0.035 && p.y < ey + 0.075 && fract(p.y * 110.0) < 0.12 && ax < 0.05 && p.z > ez - 0.02) c.rgb *= 0.82;
		}
		if (slot > 0) {
			float n = vnoise(UV * 90.0) * 0.5 + vnoise(UV * 23.0) * 0.5;
			vec3 skin_c = c.rgb;
			c.rgb = pal[slot].rgb * (0.94 + n * 0.12);
			// ağ/zincir örgü: ten aradan görünür
			if (slot == 1 && top_pattern == 1 && slot_ov < 0.5) {
				vec2 q = vec2(rest.x + rest.z, rest.y) * 90.0;
				float net = max(step(0.82, fract(q.x + q.y)), step(0.82, fract(q.x - q.y)));
				c.rgb = mix(skin_c * 0.85, pal[1].rgb * 1.2, net);
			}
			if (slot == 1 && slot_ov < 0.5 && top_pattern >= 2) {
				float ax = abs(rest.x);
				if (top_pattern == 2) c.rgb = mix(c.rgb, pal[2].rgb, step(0.62, fract(rest.y * 13.0)));
				if (top_pattern == 3 && ((ax > rig_a.x * 0.62 && ax < rig_a.x * 0.9) || (ax > rig_a.x * 0.9 && abs(rest.z) < 0.018))) c.rgb = pal[2].rgb;
				if (top_pattern == 4) {
					vec2 q = vec2(rest.x * 9.0 + rest.z * 6.0, rest.y * 7.0);
					float hh = hash(floor(q));
					vec2 f = fract(q);
					if (hh > 0.8) {
						c.rgb *= hh > 0.9 ? 0.7 : 1.2;
						if (min(min(f.x, f.y), min(1.0 - f.x, 1.0 - f.y)) < 0.07 && fract((f.x + f.y) * 12.0) < 0.5) c.rgb *= 0.5;  // dikiş
					}
				}
				if (top_pattern == 5 && rest.z < -0.02) {
					float r = length(vec2(rest.x, rest.y - (rig_b.w - 0.1)));
					if (r < 0.075 && (r > 0.058 || r < 0.03)) c.rgb = pal[2].rgb;
				}
				// 7: Uchiha yelpazesi (uchiwa) sırtta: üst yarı kırmızı, alt yarı beyaz, altta sap
				if (top_pattern == 7 && rest.z < -0.02) {
					vec2 q = vec2(rest.x, rest.y - (rig_b.w - 0.035));
					float r = length(q * vec2(1.0, 1.08));
					if (r < 0.078) c.rgb = q.y > -0.004 ? vec3(0.82, 0.08, 0.08) : vec3(0.97, 0.96, 0.94);
					if (r > 0.078 && r < 0.086) c.rgb = vec3(0.05, 0.05, 0.06);
					if (abs(q.x) < 0.012 && q.y < -0.08 && q.y > -0.15) c.rgb = vec3(0.97, 0.96, 0.94);
				}
				// 8..27: yeni desenler (ön: rest.z>0, sırt: rest.z<0, gövde: ax < rig_a.x*0.9, kol: ax > rig_a.x*0.9)
				bool torso = ax < rig_a.x * 0.9;
				float ny = rest.y - rig_b.w;   // boyundan aşağı mesafe (negatif)
				if (top_pattern == 8 && torso && abs(rest.y - (rig_b.w - 0.06) - rest.x * 0.9) < 0.035) c.rgb = pal[2].rgb;   // çapraz kuşak şerit
				if (top_pattern == 9 && step(0.78, fract(rest.x * 26.0 + rest.z * 26.0)) > 0.5) c.rgb = mix(c.rgb, pal[2].rgb, 0.85);   // dikey ince çizgi
				if (top_pattern == 10) { vec2 g = floor(vec2(rest.x + rest.z, rest.y) * 14.0); if (mod(g.x + g.y, 2.0) > 0.5) c.rgb = pal[2].rgb; }   // dama
				if (top_pattern == 11 && rest.x > 0.0) c.rgb = pal[2].rgb;   // iki renk dikey bölünmüş
				if (top_pattern == 12 && torso && ny < 0.0 && ny > -0.07) c.rgb = pal[2].rgb;   // göğüs bandı
				if (top_pattern == 13) { vec2 g = fract(vec2(rest.x + rest.z, rest.y) * 16.0) - 0.5; if (length(g) < 0.18) c.rgb = pal[2].rgb; }   // puantiye
				if (top_pattern == 14 && rest.y < rig_b.x + 0.06 + 0.03 * abs(fract((rest.x + rest.z) * 14.0) - 0.5) * 2.0) c.rgb = pal[2].rgb;   // zikzak etek
				if (top_pattern == 15) { float fh = rig_b.x + 0.05 + 0.08 * pow(abs(sin((rest.x + rest.z) * 22.0)), 3.0) + 0.04 * sin((rest.x - rest.z) * 41.0); if (rest.y < fh) c.rgb = mix(vec3(1.0, 0.35, 0.05), vec3(1.0, 0.8, 0.2), clamp((fh - rest.y) * 12.0, 0.0, 1.0)); }   // alev etek
				if (top_pattern == 16) {   // bulutlar (kontur + dolgu)
					vec2 q = vec2(rest.x * 7.0 + rest.z * 5.0, rest.y * 6.0);
					vec2 cell = floor(q); vec2 f = fract(q) - 0.5;
					if (hash(cell) > 0.6) {
						float b = min(length(f - vec2(-0.12, 0.0)), min(length(f - vec2(0.13, 0.02)), length(f - vec2(0.0, 0.1))));
						if (b < 0.16) c.rgb = pal[2].rgb;
						if (b > 0.16 && b < 0.2) c.rgb = vec3(0.95, 0.95, 0.95);
					}
				}
				if (top_pattern == 17 && rest.z > 0.02 && torso) {   // göğüste daire içinde sembol
					vec2 q = vec2(rest.x - 0.06, ny + 0.03);
					float r = length(q);
					if (r < 0.045 && r > 0.036) c.rgb = pal[2].rgb;
					if (abs(q.x) < 0.006 && abs(q.y) < 0.028) c.rgb = pal[2].rgb;
					if (abs(q.y) < 0.006 && abs(q.x) < 0.022) c.rgb = pal[2].rgb;
				}
				if (top_pattern == 18 && rest.z < -0.02) {   // sırtta girdap
					vec2 q = vec2(rest.x, ny + 0.03);
					float r = length(q);
					float a2 = atan(q.y, q.x);
					if (r < 0.085 && step(0.55, fract(a2 / 6.28318 * 1.0 + r * 18.0)) > 0.5) c.rgb = pal[2].rgb;
					if (r > 0.085 && r < 0.093) c.rgb = pal[2].rgb;
				}
				if (top_pattern == 19) {   // kamuflaj
					float cn = vnoise(vec2(rest.x + rest.z, rest.y) * 9.0);
					c.rgb = cn > 0.62 ? pal[2].rgb : (cn < 0.38 ? c.rgb * 0.65 : c.rgb);
				}
				if (top_pattern == 20) {   // baklava (argyle)
					vec2 q = vec2(rest.x + rest.z, rest.y) * 9.0;
					vec2 f = abs(fract(q) - 0.5);
					if (f.x + f.y < 0.28) c.rgb = pal[2].rgb;
					if (abs(f.x - f.y) < 0.03) c.rgb = c.rgb * 0.6;
				}
				if (top_pattern == 21 && (ny > -0.05 || (!torso && ax < rig_a.x * 1.15))) c.rgb = pal[2].rgb;   // kontrast yaka + omuzluk
				if (top_pattern == 22) c.rgb = mix(c.rgb, pal[2].rgb, clamp((rig_b.w - rest.y) / max(0.01, rig_b.w - rig_b.x), 0.0, 1.0));   // renk geçişi
				if (top_pattern == 23 && torso && (abs(rest.x - (ny + 0.08) * 0.8) < 0.018 || abs(rest.x + (ny + 0.08) * 0.8) < 0.018)) c.rgb = pal[2].rgb;   // göğüste X kayışlar
				if (top_pattern == 24 && !torso && (abs(ax - rig_a.x * 1.15) < 0.015 || abs(ax - rig_a.x * 1.3) < 0.015)) c.rgb = pal[2].rgb;   // kollarda çift şerit
				if (top_pattern == 25 && rest.z < -0.02) {   // sırtta shuriken
					vec2 q = vec2(rest.x, ny + 0.03);
					float a2 = atan(q.y, q.x);
					float rr = length(q);
					float star = 0.03 + 0.06 * pow(abs(cos(a2 * 2.0)), 6.0);
					if (rr < star) c.rgb = pal[2].rgb;
					if (rr < 0.012) c.rgb = c.rgb * 0.3 + pal[1].rgb * 0.7;
				}
				if (top_pattern == 26 && rest.z < -0.02) {   // sırtta yaprak arması
					vec2 q = vec2(rest.x, ny + 0.03);
					float leaf = length(vec2(q.x * 1.6, q.y)) ;
					if (leaf < 0.075 && abs(q.x) > 0.004) c.rgb = pal[2].rgb;
					if (abs(q.x) < 0.004 && q.y > -0.1 && q.y < 0.07) c.rgb = c.rgb * 0.5;
				}
				if (top_pattern == 27) {   // dalga (seigaiha)
					vec2 q = vec2(rest.x + rest.z, rest.y) * 12.0;
					vec2 cell = floor(q);
					vec2 f = fract(q) - vec2(0.5, 0.0);
					float rr = length(f);
					if (mod(rr * 5.0, 1.0) < 0.35 && rr < 0.9) c.rgb = pal[2].rgb;
				}
				if (top_pattern == 6 && (rest.y < rig_b.x + 0.09 || (ax > rig_a.x * 0.9 && ax > rig_a.z - 0.075))) c.rgb = pal[2].rgb;
			}
			// alt kıyafet desenleri (1..12): rig_b.x kalça, rig_b.y diz, rig_b.z ayak bileği
			// ayakkabı desenleri: slot 6 (pal[6] ana renk, pal[4] ikinci renk)
			if (slot == 6 && foot_pattern > 0) {
				float fy = rest.y - rig_b.z;
				vec3 acc2 = pal[4].rgb;
				if (foot_pattern == 1 && rest.z > 0.06 && fy < 0.05) c.rgb = acc2;   // burun kapağı
				if (foot_pattern == 2 && rest.z > 0.0 && fy > 0.02 && abs(fract(fy * 22.0 + abs(rest.x - sign(rest.x) * 0.1) * 30.0) - 0.5) < 0.12) c.rgb = acc2;   // çapraz bağcık
				if (foot_pattern == 3 && (fy > 0.0) && (foot_kind == 5 || foot_kind == 7 ? rest.y > rig_b.y - 0.06 : (foot_kind == 2 ? fy > 0.15 : fy > 0.05))) c.rgb = acc2;   // konç bandı
				if (foot_pattern == 4 && fract(fy * 14.0) > 0.75) c.rgb = acc2;   // yatay şerit
				if (foot_pattern == 5 && rest.z > 0.02 && fy > 0.06) c.rgb = mix(vec3(0.55, 0.57, 0.62), vec3(0.85, 0.87, 0.9), smoothstep(0.0, 0.03, rest.z - 0.02));   // metal kaval plakası
				if (foot_pattern == 6 && ((foot_kind == 5 || foot_kind == 7) ? rest.y > rig_b.y - 0.05 : fy > 0.06)) c.rgb = vec3(0.9, 0.88, 0.84) * (0.85 + 0.3 * hash(floor(rest.xz * 300.0)));   // kürk kenar
				if (foot_pattern == 7 && fy < -0.065) c.rgb = acc2;   // kontrast taban
				if (foot_pattern == 8 && rest.z > 0.02 && fy > 0.04 && length(fract(vec2(rest.x * 40.0, fy * 22.0)) - 0.5) < 0.18) c.rgb = vec3(0.7, 0.72, 0.76);   // perçinler
			}
			if (slot == 3 && pants_pattern > 0) {
				float lx = abs(rest.x);
				vec3 acc = pants_accent.rgb;
				if (pants_pattern == 1 && abs(rest.z) < 0.02 && lx > 0.07) c.rgb = acc;   // yan şerit
				if (pants_pattern == 2 && rest.z > 0.02 && abs(rest.y - rig_b.y) < 0.055) c.rgb = acc;   // dizlik
				if (pants_pattern == 3) { float cn = vnoise(vec2(rest.x + rest.z, rest.y) * 9.0); c.rgb = cn > 0.62 ? acc : (cn < 0.38 ? c.rgb * 0.65 : c.rgb); }   // kamuflaj
				if (pants_pattern == 4) { vec2 g = floor(vec2(rest.x + rest.z, rest.y) * 13.0); if (mod(g.x + g.y, 2.0) > 0.5) c.rgb = acc; }   // dama
				if (pants_pattern == 5 && fract((rest.x + rest.z) * 28.0) > 0.8) c.rgb = mix(c.rgb, acc, 0.85);   // ince dikey çizgi
				if (pants_pattern == 6 && rest.y < rig_b.y) c.rgb = acc;   // dizden aşağısı iki renk
				if (pants_pattern == 7 && rest.y < rig_b.z + 0.14 && rest.y > rig_b.z + 0.04) c.rgb = acc;   // paça bandı
				if (pants_pattern == 8) {   // yamalı
					vec2 q = vec2(rest.x * 9.0 + rest.z * 6.0, rest.y * 7.0);
					float hh = hash(floor(q));
					if (hh > 0.82) c.rgb = hh > 0.91 ? acc : c.rgb * 1.2;
				}
				if (pants_pattern == 9 && lx > 0.1 && abs(rest.z) < 0.05 && rest.y < rig_b.x - 0.1 && rest.y > rig_b.x - 0.25) c.rgb = mix(c.rgb, acc, 0.9);   // kargo cep
				if (pants_pattern == 10 && fract(rest.y * 18.0 + atan(rest.z, rest.x - sign(rest.x) * 0.1) * 0.6) < 0.35 && rest.y < rig_b.y + 0.05) c.rgb = acc;   // sarmal sargı
				if (pants_pattern == 11) { float fh = rig_b.z + 0.1 + 0.12 * pow(abs(sin((rest.x + rest.z) * 25.0)), 3.0); if (rest.y < fh) c.rgb = mix(vec3(1.0, 0.35, 0.05), vec3(1.0, 0.8, 0.2), clamp((fh - rest.y) * 10.0, 0.0, 1.0)); }   // alev paça
				if (pants_pattern == 12) { vec2 g = fract(vec2(rest.x + rest.z, rest.y) * 15.0) - 0.5; if (length(g) < 0.18) c.rgb = acc; }   // puantiye
			}
			if (slot == 8 && outer_pattern > 0) {
				float dh = rest.y - outer_hem;
				float oa = atan(rest.z, rest.x);
				if (outer_pattern == 1 && dh < 0.07) c.rgb = outer_accent.rgb;
				if (outer_pattern == 2 && dh < 0.09 + 0.08 * abs(sin(oa * 7.0)) + 0.04 * sin(oa * 17.0)) c.rgb = outer_accent.rgb;
				if (outer_pattern == 3) {
					vec2 q = vec2(oa * 2.6, rest.y * 4.2);
					vec2 cell = floor(q);
					vec2 f = fract(q) - 0.5;
					if (mod(cell.x + cell.y, 2.0) < 0.5 && hash(cell) > 0.35 && length(f) < 0.3 && length(f - vec2(0.12, 0.08)) > 0.27) c.rgb = outer_accent.rgb;  // hilal
					if (dh < 0.04) c.rgb = outer_accent.rgb * 0.8;
				}
				if (outer_pattern == 6) {
					// beyaz kenarlı kızıl bulutlar
					vec2 q = vec2(oa * 0.95, rest.y * 2.3);
					vec2 cell = floor(q);
					vec2 f = (fract(q) - 0.5) * vec2(1.0, 1.25);
					if (mod(cell.x + cell.y, 2.0) < 0.5 && hash(cell) > 0.2) {
						// üç tümsekli bulut + düz taban, kalın beyaz kontur
						float d = min(min(length(f - vec2(-0.2, -0.02)) - 0.13, length(f - vec2(0.0, 0.07)) - 0.17), length(f - vec2(0.2, 0.0)) - 0.12);
						d = min(d, max(abs(f.y + 0.06) - 0.08, abs(f.x) - 0.3));
						d = max(d, -(f.y + 0.15));
						if (d < 0.0) c.rgb = outer_accent.rgb; else if (d < 0.045) c.rgb = vec3(0.95, 0.94, 0.92);
					}
				}
				if (outer_pattern == 4) c.rgb *= 0.8 + 0.32 * step(0.45, fract(oa * 22.0 + vnoise(rest.xy * 30.0) * 0.6));
				if (outer_pattern == 5) c.rgb *= 1.0 - 0.35 * smoothstep(0.25, 0.0, dh) * vnoise(rest.xz * 40.0) - 0.15 * smoothstep(0.55, 0.8, vnoise(rest.xy * 9.0));
			}
			if (slot == 5 && layer == 2) {
				if (vest_style == 2) c.rgb *= 0.9 + 0.1 * step(0.5, fract(rest.y * 28.0));
				if (vest_style == 5) c.rgb *= 0.85 + 0.15 * step(0.08, fract(rest.y * 9.0)) * step(0.06, fract(rest.x * 7.0 + 0.5));
				if (vest_style == 6) c.rgb *= 0.78 + 0.22 * smoothstep(0.0, 0.7, fract(rest.y * 24.0));
				if (vest_style == 7) c.rgb *= 0.82 + 0.18 * step(0.5, fract(rest.x * 14.0));
				if (vest_style == 8) {
					vec2 q = vec2((rest.x + rest.z) * 70.0, rest.y * 80.0);
					q.x += step(0.5, fract(q.y * 0.5)) * 0.5;
					float d = length(fract(q) - 0.5);
					c.rgb *= mix(0.55, 1.2, smoothstep(0.18, 0.28, d) * (1.0 - smoothstep(0.38, 0.48, d)));
				}
				if (vest_style == 10) {
					float row = floor(rest.y * 22.0);
					float sc = fract(rest.x * 11.0 + rest.z * 6.0 + mod(row, 2.0) * 0.5);
					c.rgb *= (0.72 + 0.34 * smoothstep(0.0, 0.8, fract(rest.y * 22.0))) * (0.85 + 0.3 * abs(sc - 0.5));
				}
				if (vest_style == 11) c.rgb *= 0.86 + 0.14 * step(0.1, fract(rest.y * 7.0));
			}
			// kir/yıpranma: lekeler + paçalarda çamur
			if (wear > 0.0) {
				float st = smoothstep(0.5, 0.85, vnoise(rest.xy * 13.0 + rest.z * 7.0));
				float mud = smoothstep(rig_b.y, rig_b.z, rest.y);
				c.rgb *= 1.0 - wear * (0.28 * st + 0.3 * mud);
				c.rgb = mix(c.rgb, c.rgb * vec3(0.95, 0.85, 0.72), wear * 0.35);
			}
			// 3B kumaş: kıvrımlardan normal sapması (bump) + kıvrım içi gölgesi
			float h = fold_h(rest, slot) * fold_amount;
			vec3 dpdx = dFdx(VERTEX); vec3 dpdy = dFdy(VERTEX);
			float dhx = dFdx(h); float dhy = dFdy(h);
			vec3 r1 = cross(dpdy, NORMAL); vec3 r2 = cross(NORMAL, dpdx);
			float det = dot(dpdx, r1);
			vec3 grad = sign(det) * (dhx * r1 + dhy * r2);
			vec3 nb = normalize(abs(det) * NORMAL - grad);
			// normal tamponunu bozmadan (anime çizgisi titremesin) üstten ışıklı kabartma
			float emb = dot(nb - NORMAL, normalize(vec3(0.3, 0.85, 0.45)));
			c.rgb *= clamp(1.0 + emb * 1.4, 0.75, 1.2) * (0.92 + 0.08 * clamp(h / fold_amount * 0.5 + 0.5, 0.0, 1.0));
			if (slot == 4) c.rgb *= 0.86 + 0.14 * smoothstep(0.1, 0.25, fract(rest.y * 55.0 + rest.x * 8.0));  // sargı bezi katları
		}
	} else if (cloth_mode) {
		float sl = dot(tx.rgb, vec3(0.3, 0.59, 0.11));
		c.rgb = tint.rgb * (0.55 + sl * 1.5);
		vec3 vc = COLOR.rgb;
		vc = mix(vc / 12.92, pow((vc + 0.055) / 1.055, vec3(2.4)), step(0.04045, vc));
		c.rgb = mix(c.rgb, vc, COLOR.a);
	} else if (use_vertex_color) {
		vec3 vc = COLOR.rgb;
		vc = mix(vc / 12.92, pow((vc + 0.055) / 1.055, vec3(2.4)), step(0.04045, vc));  // sRGB -> lineer
		c *= vec4(vc, COLOR.a);
	}
	if (detail_noise > 0.0) {
		float n = vnoise(wpos.xz * 0.9 + wpos.y * 0.7) * 0.6 + vnoise(wpos.xy * 3.1) * 0.4;
		c.rgb *= 1.0 + (n - 0.5) * detail_noise;
	}
	if (detail_tex_amt > 0.0) {
		// üç yönlü (triplanar) doku: UV gerektirmez, her yüzeye dünya konumundan oturur
		vec3 wn = abs((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
		wn = pow(wn, vec3(4.0));
		wn /= (wn.x + wn.y + wn.z + 1e-4);
		vec3 sp = wpos * detail_tex_scale;
		float tv = texture(detail_tex, sp.zy).r * wn.x + texture(detail_tex, sp.xz).r * wn.y + texture(detail_tex, sp.xy).r * wn.z;
		c.rgb *= 1.0 + (tv - 0.5) * 2.0 * detail_tex_amt;
	}
	if (scalp && scalp_col.a >= 0.5) c.rgb = scalp_col.rgb * 0.75;
	if (roof_tiles) {
		// kiremit: eğim yönünde 0.45 m sıralar, her sıranın alt kenarı koyu gölge (tırtıklı kenar), sıralar arası şaşırtmalı derz
		float row = wpos.y / 0.32;
		float fr = fract(row);
		vec2 hz = wpos.xz;
		float col_ = (hz.x + hz.y) / 0.42 + step(0.5, fract(row * 0.5)) * 0.5;
		float scallop = 0.5 + 0.5 * cos(fract(col_) * 6.2832);   // yuvarlak kiremit ucu
		float edge = smoothstep(0.0, 0.18 + scallop * 0.12, fr);
		float seam = smoothstep(0.04, 0.0, abs(fract(col_) - 0.5) - 0.46);
		c.rgb *= mix(0.45, 1.0, edge) * (1.0 - seam * 0.35) * (0.88 + 0.18 * hash(floor(vec2(col_, row))));
	}
	ALBEDO = mix(c.rgb, vec3(1.0), hit_flash);
	ROUGHNESS = 0.8;
	EMISSION = emission_color.rgb * emission_color.a + vec3(hit_flash) * 0.6;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION += rim * rim_amount * 0.35 * ALBEDO;
	if (use_vertex_color) {
		// taş fener / kâğıt fener ateş odası: alacakaranlıkta da yanar, sıcak güçlü sarı (muhafız feneri gibi)
		vec3 vl = COLOR.rgb;
		float lamp0 = step(distance(vl, vec3(1.0, 0.85, 0.5)), 0.02) + step(distance(vl, vec3(1.0, 0.85, 0.55)), 0.02);
		EMISSION += lamp0 * vec3(1.0, 0.55, 0.12) * (2.0 + g_night * 5.0);
		ALBEDO = mix(ALBEDO, vec3(1.0, 0.72, 0.25), lamp0 * 0.85);
	}
	if (g_night > 0.0 && use_vertex_color) {
		// renk işaretleri: cam / shoji pencere, fener ışığı, kırmızı kâğıt fener (HouseKit, DoorKit, Builder.lantern)
		vec3 vc0 = COLOR.rgb;
		float win = step(distance(vc0, vec3(0.55, 0.72, 0.85)), 0.012) + step(distance(vc0, vec3(0.95, 0.92, 0.82)), 0.012);
		float lamp = step(distance(vc0, vec3(1.0, 0.85, 0.5)), 0.02) + step(distance(vc0, vec3(1.0, 0.85, 0.55)), 0.02);
		float red = step(distance(vc0, vec3(0.9, 0.2, 0.15)), 0.012);
		float on = step(0.72, hash(floor(wpos.xz * 0.55) + floor(wpos.y * 0.33) * 7.1));   // pencerelerin ~%28 i yanık (hepsi yanınca yapay duruyordu)
		EMISSION += g_night * (win * on * vec3(1.0, 0.7, 0.32) * 1.5 + red * vec3(1.0, 0.28, 0.12) * 1.8);
	}
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float t = smoothstep(-0.03, 0.05, ndl) * 0.6 + smoothstep(0.42, 0.5, ndl) * 0.4;
	float lit = t * ATTENUATION;
	if (LIGHT_IS_DIRECTIONAL) {
		// anime gölgesi: tamamen kararmaz, hafif soğuk tonlu (yalnız güneş/ay)
		vec3 shade = mix(vec3(0.42, 0.44, 0.55), vec3(1.0), lit);
		DIFFUSE_LIGHT += LIGHT_COLOR * shade / PI;
	} else {
		// fener/efekt ışıkları: sadece gerçekten aydınlattığı yerde, yumuşak
		DIFFUSE_LIGHT += LIGHT_COLOR * (0.35 + 0.65 * t) * ATTENUATION / PI;
	}
	if (spec_amount > 0.0) {
		vec3 h = normalize(LIGHT + VIEW);
		float s = smoothstep(0.93, 0.96, dot(NORMAL, h));
		SPECULAR_LIGHT += LIGHT_COLOR * s * spec_amount * ATTENUATION;
	}
}
