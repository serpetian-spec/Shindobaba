// Karakter + bina toon shader'ı: 2 bantlı anime gölge, kenar ışığı, vertex renkleri
shader_type spatial;
render_mode cull_back, diffuse_toon, specular_toon;
#include "res://shaders/hair_mask.gdshaderinc"

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
uniform sampler2D leaf_tex : filter_linear_mipmap, repeat_enable;   // yaprak/iğne dokusu (yeşil köşeler)
uniform float leaf_tex_amt = 0.0;
uniform bool detail_brown_only = false;   // ağaçlar: doku yalnız kahverengi (gövde) köşelere, yapraklara değil
uniform float sway = 0.0;
uniform float trample = 0.0;   // >0: içinden geçen dövüşçüler (push0-3) bitkiyi dışa doğru yatırır (çiçek öbekleri)
global uniform vec4 push0;
global uniform vec4 push1;
global uniform vec4 push2;
global uniform vec4 push3;
uniform bool cloth_mode = false;
uniform bool hide_masked = false;  // vertex alfa=1 olan bölgeler çizilmez (kıyafet altı)   // doku (ten) + vertex rengi (kıyafet, alfa = maske)
uniform bool palette_mode = false;  // vertex COLOR.r = renk yuvası*0.1 (0 = ten dokusu)
uniform vec4 skin_tint = vec4(1.0, 1.0, 1.0, 0.0);   // Sekiz Kapı vb.: tenin (gövde, kol, el, ayak) geçici rengi, a = oran
uniform vec4 pal[12] : source_color;  // 0 ten 1 üst 2 vurgu 3 alt 4 sargı 5 yelek 6 sandalet 7 koyu 8 dış giysi 9 aksesuar 10 başlık 11 yüz
uniform vec4 rig_a = vec4(0.21, 0.46, 0.7, 1.52);   // üst kol x, dirsek x, el x, boyun y (dinlenme pozu)
uniform vec4 rig_b = vec4(0.95, 0.54, 0.09, 1.31);  // kalça y, diz y, ayak bileği y, üst göğüs y
uniform int top_style = 1;    // 0 tişört, 1 uzun kollu, 2 ceket, 3 yüksek yakalı, 4 kolsuz, 5 kimono, 6 gi, 7 uzun kollu yüksek yaka, 8 atlet, 9 tek kollu
uniform int pants_style = 0;  // 0 ninja pantolonu, 1 şort, 2 sivil uzun pantolon, 3 sargılı, 4 bol paça, 5 kapri, 6 kısa şort
uniform int layer = 0;        // 0 vücut, 1 kumaş kabuğu, 2 yelek
uniform vec4 inner_col = vec4(0.0);   // gi V yakasında iç giysi rengi (a=0 yok)
uniform bool leg_fishnet = false;   // baldırda file çorap (Rock Striker): dizden bileğe tende koyu ağ
uniform int pants_pattern = 0;  // 1 yan şerit 2 dizlik 3 kamuflaj 4 dama 5 ince çizgi 6 diz altı iki renk 7 paça bandı 8 yamalı 9 kargo cep 10 sarmal sargı 11 alev paça 12 puantiye
uniform vec4 pants_accent : source_color = vec4(0.1, 0.1, 0.12, 1.0);
uniform vec4 pants_pipe : source_color = vec4(0.0);   // a>0: kot paneli kenar biyesi (Matador altın)
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
uniform bool sleeve_roll = false;
uniform bool guard_net = false;
uniform bool vest_open = false;   // taktik yeleğin fermuarı açık (önde ortası boş)   // aksesuar halkaları file dirsek/dizlik (ten aradan görünür, uçlarda bant)   // kollar ön kol ortasına kadar kıvrık (köy üniforması tulumu)
uniform bool arm_wraps = false;
uniform float outer_top = 1.45;   // dış giysinin yaka dibi (boyun) y — desen yerleşimi
uniform float sleeve_end = 0.6;   // kol ağzı (bilek) |x| — çan kol astarı
uniform int outer_sleeves = 0; // 1: dış giysi kolları (palto/haori)
uniform bool foot_cover = false; // tabi: ayak tamamen kapalı
uniform float foot_toe_z = 0.1;  // shinobi sandaleti: bu z'den öndeki parmaklar açık
varying float slot_ov;
varying float lining;   // 1: giysinin iç yüzü (astar)
uniform vec4 face_a = vec4(0.0);   // çene genişliği, çene ucu, elmacık, burun (metre)
uniform vec4 face_b = vec4(0.0);   // kaş çıkıntısı, işaret türü (0 yok, 1 burun yarası, 2 yanak çizgisi, 3 çil, 4 kırışık), -, -
uniform vec4 face_ref = vec4(0.0, 1.7, 0.08, 0.0);
uniform float outer_gap = 0.075;  // önü açık dış giysinin açıklığının yarı genişliği (m): yelek yalnız bu kadar görünür
uniform int outer_cover = 0;  // yelek katmanı: 1 önü açık dış giysi altında (yalnız ön şerit görünür), 2 kapalı pelerin altında (gizli)
uniform vec4 scalp_cut = vec4(99.0, -99.0, 99.0, 0.0);  // x: bu yüksekliğin üstü, y/z: bu derinliğin arkasında z yüksekliğinin üstü  // saçlıyken gövdenin kafa derisi bu yüksekliğin üstünde çizilmez (saç arasından "kel" görünmesin)  // -, göz y, göz z
varying float v_nospec;   // kafa derisi (saç arası) parlamasın: gri leke
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
uniform int sage_marks = 0;   // sennin yüz izleri: 1 turuncu pigment, 2 mor yılan çizgileri, 3 yeşil çizgiler, 4 Byakugō mühür çizgileri (beden)
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

float hash(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }   // sinüssüz: büyük koordinatta bloklaşmaz
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void vertex() {
	hm_p = (hm_xf * vec4(VERTEX, 1.0)).xyz;
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
	if (trample > 0.0) {
		vec3 w2 = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		vec3 root2 = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
		float hy = clamp((w2.y - root2.y) / 0.6, 0.0, 1.0);   // dip sabit, uç yatar
		vec3 off = vec3(0.0);
		vec4 ps[4] = vec4[4](push0, push1, push2, push3);
		for (int i = 0; i < 4; i++) {
			vec2 dv = w2.xz - ps[i].xz;
			float dl = length(dv);
			float k = clamp(1.0 - dl / max(ps[i].w, 0.01), 0.0, 1.0) * step(abs(root2.y - ps[i].y), 2.5);
			k *= k;
			off.xz += (dl > 0.001 ? dv / dl : vec2(0.0)) * k * 0.55 * trample;
			off.y -= k * 0.35 * trample;
		}
		VERTEX += inverse(mat3(MODEL_MATRIX)) * (off * hy);
	}
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	rest = CUSTOM0.xyz;
	eye_side = VERTEX.x;
	slot_ov = CUSTOM0.w;
	// astar: yüzey normali gövde/kol ekseninden içe bakıyor (sarım yönünden bağımsız; iç kopya bazen dışa dönük çıkıyordu)
	bool arm_r = abs(rest.x) > 0.24 && rest.y > outer_top - 0.4;   // T-pozu kol: eksen x boyunca (omuz hizası)
	vec3 radial = arm_r ? vec3(0.0, rest.y - (outer_top - 0.08), rest.z) : vec3(rest.x, 0.0, rest.z);
	lining = dot(NORMAL, radial) < 0.0 ? 1.0 : 0.0;
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
	if (slot == 9) return 0.0;   // koruyucular (kaval/kolluk) sert malzeme: pantolon kıvrımı almaz
	if (slot == 6 && (foot_pattern == 11 || foot_pattern == 12)) return 0.0;   // ince çorap: deriye yapışık, pantolon kıvrımı almaz
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
		// Iwa yeleği artık kola uzanmıyor (rockset.png: sol kol tamamen kırmızı kol)
		float sleeve = rig_a.z - 0.035;
		if (top_style == 0 || top_style == 3) sleeve = mix(rig_a.x, rig_a.y, 0.5);
		if (sleeve_roll && (top_style == 1 || top_style == 7)) sleeve = mix(rig_a.y, rig_a.z, 0.42);
		else if (top_style == 4 || top_style == 8 || top_style == 10 || (top_style == 9 && p.x < 0.0)) sleeve = rig_a.x * 0.9;   // 10: üst yok
		else if (top_style == 6) sleeve = rig_a.y + 0.05;
		if ((top_style == 4 || top_style == 8) && p.y < rig_a.w - 0.1 && ax < rig_a.x * 1.08) return 1;   // kolsuzda koltuk altı göğüs yanı kumaş (kadın gövdesinde delik kalıyordu)
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
		if (top_pattern == 37 && p.z > 0.0 && p.y > rig_b.w - 0.12 && ax < (p.y - (rig_b.w - 0.12)) * 0.55) return 0;   // derin V yaka
		if (top_pattern == 40 && p.y < rig_b.w - 0.155) return 0;
		if (top_pattern == 43 && p.y < rig_b.w - 0.12) return 0;   // file sütyen: göğüs altı ten   // file bantlı kısa üst: bandın altı ten
		if ((top_pattern == 32 || top_pattern == 33) && p.y < rig_b.w - 0.15 - (top_pattern == 33 ? max(0.0, 0.06 - abs(p.x)) * 0.6 : 0.0)) return 0;   // kısa üst: göbek açık
		if (top_style == 2 && p.y > rig_a.w - 0.1) return 2;
		// kimono: çapraz (sol üstte) yaka bandı
		if ((top_style == 5 || top_style == 6) && p.z > -0.02 && p.y > rig_b.w - 0.22 && abs(p.x + (p.y - rig_a.w) * 0.55) < 0.022) return 2;
		// gi: göğüste derin V yaka (ten görünür)
		if (top_style == 6 && p.z > 0.0 && p.y > rig_b.w - 0.12 && ax < (p.y - (rig_b.w - 0.12)) * 0.5) return 0;
		// atlet: omuzlar açık, ince askı
		if (top_style == 8 && p.y > rig_b.w - 0.04 && (ax > rig_a.x * 0.62 || (ax < 0.07 && p.z > 0.0))) return 0;
		if (top_style == 10) return 0;   // üst yok (çıplak gövde)
		return 1;
	}
	if (foot_kind == 8 && p.y < rig_b.z + 0.07) return (p.z > foot_toe_z && p.y < rig_b.z - 0.035) ? 0 : 6;   // shinobi sandaleti
	if (p.y < rig_b.z + 0.03) return (foot_cover || foot_kind == 1 || foot_kind == 2 || (foot_kind >= 4 && foot_kind != 8 && foot_kind != 9)) ? 6 : 0;
	if (foot_kind == 2 && p.y < rig_b.z + 0.2) return 6;   // çizme konçu
	if (foot_kind == 4 && p.y < rig_b.z + 0.09) return 6;   // bilek botu
	if ((foot_kind == 5 || foot_kind == 7) && p.y < rig_b.y - 0.01) return 6;   // diz çizmesi / zırhlı tozluk
	if (foot_kind == 6 && p.y < rig_b.z + 0.12) return 6;   // sargılı bot: alt kısım deri
	float cut = pants_style == 0 ? rig_b.y - 0.17 : (pants_style == 1 ? rig_b.y - 0.05 : (pants_style == 3 ? rig_b.y + 0.1 : rig_b.z + 0.04));
	if (pants_style == 5) cut = mix(rig_b.y, rig_b.z, 0.45);
	if (pants_style == 6) cut = pants_pattern == 23 ? rig_b.x - 0.15 : rig_b.y + 0.12;   // pilili etek altında yalnız etek boyu iç şort
	if (p.y > cut) return 3;
	if (foot_kind == 9 || foot_pattern == 11 || foot_pattern == 12) return 0;   // parmak arası terlik / çoraplı ayakkabı: baldır sargısı yok
	float wrap_top = (pants_style == 0 || pants_style == 3) ? cut + 0.02 : rig_b.y - 0.16;
	if (pants_style == 5) wrap_top = rig_b.z + 0.06;
	if (foot_kind == 3 || foot_kind == 6) wrap_top = max(wrap_top, rig_b.y + 0.02);
	if (leg_fishnet) return 0;   // file çorap: baldır sargısız (ağ tende çizilir)
	return p.y < wrap_top ? 4 : 0;
}

void fragment() {
	v_nospec = 0.0;
	if (hm_cut(hm_p)) discard;
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
			if (vest_open && rest.z > 0.0 && abs(rest.x) < 0.045 && rest.y < rig_a.w + 0.02) discard;   // açık yelek
			if (vest_style == 12 && rest.y > rig_b.w + 0.035) discard;   // ANBU plakası: üstü açık (askılar OutfitParts loft katmanı)
			slot = 5;
		} else if (layer == 1 && slot == 0) discard;
		if (slot == 0 && sage_marks > 0 && rest.y > face_ref.y - 0.07 && rest.y < face_ref.y + 0.05 && rest.z > face_ref.z - 0.05) {
			float ax = abs(rest.x);
			vec2 e = vec2((ax - 0.034) / 0.034, (rest.y - (face_ref.y - 0.003)) / 0.024);
			if (sage_marks == 1 && length(e) < 1.0 && length(e) > 0.55) c.rgb = mix(c.rgb, vec3(0.95, 0.4, 0.08), 0.85);  // göz çevresi turuncu pigment
			if (sage_marks == 2 && ax > 0.045 && ax < 0.075 && abs(rest.y - (face_ref.y - 0.012) + (ax - 0.045) * 0.9) < 0.004) c.rgb = vec3(0.45, 0.15, 0.55);  // mor yılan izi
			if (sage_marks == 3 && ax > 0.03 && ax < 0.06 && rest.y < face_ref.y - 0.02 && abs(fract(ax * 90.0) - 0.5) < 0.12) c.rgb = mix(c.rgb, vec3(0.35, 0.75, 0.4), 0.8);  // yeşil çizgiler
		}
		if (slot == 0 && sage_marks == 5) {   // lanet mührü: boyundan yayılan kara alev dilleri (gürültü lekeleri, sivri uçlu)
			float jn = vnoise(vec2(rest.x * 38.0 + rest.z * 22.0, rest.y * 18.0)) + vnoise(vec2(rest.x * 90.0, rest.y * 60.0 + rest.z * 40.0)) * 0.35;
			if (jn > 0.78) c.rgb = vec3(0.04, 0.02, 0.05);
		}
		if (slot == 0 && sage_marks == 4) {   // Byakugō / Sōzō Saisei: alında mor elmas + tüm tene yayılan kara mühür çizgileri
			vec2 dd = vec2(rest.x, rest.y - (face_ref.y + 0.05));
			if (abs(dd.x) + abs(dd.y) < 0.014 && rest.z > face_ref.z - 0.02) c.rgb = vec3(0.55, 0.15, 0.7);
			else {
				float w = sin(rest.y * 120.0 + sin(rest.x * 70.0 + rest.z * 50.0) * 3.0);
				if (abs(w) < 0.2) c.rgb = mix(c.rgb, vec3(0.08, 0.04, 0.1), 0.92);
			}
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
		if (slot == 0 && skin_tint.a > 0.0) c.rgb = mix(c.rgb, c.rgb * skin_tint.rgb * 1.6, skin_tint.a);
		if (slot == 0 && inner_col.a > 0.5 && top_style == 6 && rest.z > 0.0 && rest.y > rig_b.w - 0.13 && rest.y < rig_a.w + 0.01 && abs(rest.x) < (rest.y - (rig_b.w - 0.12)) * 0.5 + 0.006) {
			// keiko-gi: V yakanın içi; dar iç V renkli iç giysi, kenarlar gi'nin beyaz yaka katı
			float vin = (rest.y - (rig_b.w + 0.045)) * 0.7;
			c.rgb = abs(rest.x) < vin ? inner_col.rgb : pal[1].rgb * 0.96;
			if (abs(abs(rest.x) - vin) < 0.003) c.rgb *= 0.6;
		}
		if (slot == 0 && leg_fishnet && rest.y < (pants_style == 6 ? rig_b.x - 0.1 : rig_b.y - 0.01) && rest.y > rig_b.z + 0.03 && abs(rest.x) > 0.03) {   // file çorap: çapraz ağ
			vec2 nq = vec2((abs(rest.x) + rest.z) * 70.0, rest.y * 70.0);
			if (abs(fract((nq.x + nq.y) * 0.5) - 0.5) < 0.12 || abs(fract((nq.x - nq.y) * 0.5) - 0.5) < 0.12) c.rgb = vec3(0.12, 0.12, 0.14);
		}
		if (slot > 0) {
			float n = vnoise(UV * 90.0) * 0.5 + vnoise(UV * 23.0) * 0.5;
			vec3 skin_c = c.rgb;
			c.rgb = pal[slot].rgb * (0.94 + n * 0.12);
			if (slot == 9 && guard_net) {
				vec2 q = vec2(rest.x + rest.z, rest.y) * 110.0;
				float net = max(step(0.8, fract(q.x + q.y)), step(0.8, fract(q.x - q.y)));
				c.rgb = mix(skin_c * 0.9, pal[9].rgb, net);
				bool armn = abs(rest.x) > rig_a.x * 0.9 && rest.y > rig_a.w - 0.32;
				float e = armn ? abs(abs(rest.x) - rig_a.y) : abs(rest.y - rig_b.y);
				if (e > 0.05) c.rgb = fract(e * 70.0) < 0.5 ? pal[9].rgb : pal[1].rgb;   // uçlarda gri-mor şeritli bant
			}
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
				if (top_pattern == 36 && rest.z > 0.02 && torso) {   // kolsuz üstte çapraz fermuar: yakadan sola kıvrılıp bele iner
					float zx = (rest.y > rig_b.w - 0.04) ? 0.0 : clamp((rig_b.w - 0.04 - rest.y) * 0.45, 0.0, 0.055);
					if (abs(rest.x - zx) < 0.0035) c.rgb = vec3(0.85, 0.85, 0.88);
				}
				if (top_pattern == 35 && rest.z > 0.02 && torso && abs(rest.x) < 0.004) c.rgb = pal[1].rgb * 0.45;   // önde fermuar
				if (top_pattern == 43) { vec2 q = vec2(rest.x + rest.z, rest.y) * 80.0; float net = max(step(0.78, fract(q.x + q.y)), step(0.78, fract(q.x - q.y))); c.rgb = mix(skin_c * 0.85, vec3(0.08, 0.08, 0.1), net); }   // file sütyen
				if (top_pattern == 40 && rest.y < rig_b.w - 0.095) { vec2 q = vec2(rest.x + rest.z, rest.y) * 90.0; float net = max(step(0.8, fract(q.x + q.y)), step(0.8, fract(q.x - q.y))); c.rgb = mix(skin_c * 0.85, vec3(0.1, 0.1, 0.12), net * 0.9 + 0.1); }   // file bant
				if (top_pattern == 41 && !torso && ax > mix(rig_a.x, rig_a.y, 0.38) && ax < mix(rig_a.x, rig_a.y, 0.5)) { vec2 q = vec2(rest.y, rest.z) * 120.0; float net = max(step(0.78, fract(q.x + q.y)), step(0.78, fract(q.x - q.y))); c.rgb = mix(skin_c * 0.85, vec3(0.75, 0.75, 0.78), net); }   // kol ağzında file bant
				if (top_pattern == 44 && !torso) { vec2 q = vec2(rest.y, rest.z) * 120.0; float net = max(step(0.78, fract(q.x + q.y)), step(0.78, fract(q.x - q.y))); c.rgb = mix(skin_c * 0.85, vec3(0.1, 0.1, 0.12), net); }   // gövde düz, kollar file
				if (top_pattern == 39) {   // ışıklı hat tulum (Custom Type Two): yakada çapraz, omuzda kısa çizgi, ön kolda koruyucu kenarı
					vec3 glow = vec3(1.0, 0.86, 0.95);
					if (torso && rest.z > 0.0 && ny > -0.08 && abs(abs(rest.x) - (ny + 0.08) * 0.9) < 0.004) c.rgb = glow;
					if (!torso && abs(ax - rig_a.x * 1.12) < 0.006 && rest.y > rig_a.w - 0.1) c.rgb = glow;
					if (!torso && ax > rig_a.y + 0.02 && ax < rig_a.z - 0.06 && abs(rest.z - 0.03) < 0.003) c.rgb = glow;
				}
				if (top_pattern == 34 && torso) {   // gövde file iç giysi (kollar düz: tek kırmızı kol)
					vec2 q = vec2(rest.x + rest.z, rest.y) * 90.0;
					float net = max(step(0.82, fract(q.x + q.y)), step(0.82, fract(q.x - q.y)));
					c.rgb = mix(skin_c * 0.85, vec3(0.12, 0.12, 0.14), net);
				}
				if (top_pattern == 30 && ny > -0.035 && rest.z > -0.06 && torso) c.rgb = pal[2].rgb;   // yaka ağzında koyu biye
				if (top_pattern == 31 && rest.z > 0.02 && torso) {   // göğüste daire içinde 食 (Shoku) amblemi
					vec2 q = vec2(rest.x, ny + 0.1);
					float r = length(q);
					float lw = 0.0042;
					bool ink = abs(r - 0.075) < lw;
					ink = ink || (abs(q.y - 0.045 + abs(q.x) * 0.9) < lw && abs(q.x) < 0.045);   // çatı
					ink = ink || (abs(q.x + 0.025) < lw && q.y < 0.02 && q.y > -0.045);   // sol dikme
					ink = ink || (abs(q.y - 0.02) < lw && q.x > -0.025 && q.x < 0.02) || (abs(q.y + 0.005) < lw && q.x > -0.025 && q.x < 0.02) || (abs(q.y + 0.03) < lw && q.x > -0.025 && q.x < 0.02);
					ink = ink || (abs(q.x - 0.02) < lw && q.y < 0.02 && q.y > -0.005);
					ink = ink || (abs(q.x - 0.0 - (q.y + 0.03) * -0.8) < lw && q.y < -0.03 && q.y > -0.055);   // alt sağa çapraz
					if (ink) c.rgb = pal[2].rgb;
				}
				if (top_pattern == 32 && rest.z > 0.02 && torso && abs(rest.x) < 0.006 && fract(ny * 22.0) < 0.35) c.rgb = pal[1].rgb * 0.5;   // düğme sırası
				if (top_pattern == 33 && rest.z > 0.02 && torso && ny > -0.05 && abs(rest.x) < (ny + 0.05) * 0.6) c.rgb = pal[1].rgb * 0.55;   // yarık dik yaka
				if (top_pattern == 28 && rest.z > 0.02 && torso && abs(ny + 0.05) < 0.03) {   // göğüste boncuk dizisi (Wonder)
					float bxq = rest.x * 15.0;
					vec2 f = vec2(fract(bxq) - 0.5, (ny + 0.05 + 0.008 * sin(floor(bxq) * 2.3)) * 15.0);
					float h = hash(vec2(floor(bxq), 3.0));
					if (length(f / vec2(0.42, 0.3 + 0.12 * h)) < 1.0) c.rgb = h < 0.33 ? vec3(0.08, 0.12, 0.3) : (h < 0.66 ? vec3(0.95, 0.97, 0.98) : vec3(0.25, 0.75, 0.85));
				}
				if (top_pattern == 29 && rest.z > 0.02 && torso) {   // göğüste iki çizgi yıldız + bağlayan çizgi (Wonder Star)
					for (int k = 0; k < 2; k++) {
						vec2 q = vec2(rest.x + 0.03 - float(k) * 0.03, ny + 0.02 + float(k) * 0.1);
						float a2 = atan(q.x, q.y); float rr = length(q);
						float st = 0.032 * (0.5 + 0.5 * pow(abs(cos(a2 * 2.5)), 2.0));
						if (abs(rr - st) < 0.004) c.rgb = pal[2].rgb;
					}
					float lx = rest.x + 0.03 + (ny + 0.02) / 0.1 * 0.03;
					if (abs(lx) < 0.003 && ny < -0.05 && ny > -0.07) c.rgb = pal[2].rgb;
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
				if (foot_pattern == 9 && fy > 0.04 && fract(fy * 6.5) > 0.8) c.rgb = acc2;   // seyrek kayışlar (kayışlı uzun çizme)
				if (foot_pattern == 5 && rest.z > 0.02 && fy > 0.06) c.rgb = mix(vec3(0.55, 0.57, 0.62), vec3(0.85, 0.87, 0.9), smoothstep(0.0, 0.03, rest.z - 0.02));   // metal kaval plakası
				if (foot_pattern == 6 && ((foot_kind == 5 || foot_kind == 7) ? rest.y > rig_b.y - 0.05 : fy > 0.06)) c.rgb = vec3(0.9, 0.88, 0.84) * (0.85 + 0.3 * hash(floor(rest.xz * 300.0)));   // kürk kenar
				if (foot_pattern == 12) {   // tabi + zōri (Training): tabi beyaz (ana renk), parmak arası altın kayış, renkli taban; çorap ağzında iki koyu çizgi
					if (rest.y < -5.0) c.rgb = vec3(0.92, 0.7, 0.25);   // bilek bağı: altın kordon
					else if (fy < -0.06) c.rgb = acc2;
					else if (rest.z > 0.02 && fy > -0.05 && fy < -0.02 && abs(abs(rest.x) - 0.1) < 0.03) c.rgb = vec3(0.92, 0.7, 0.25);
					float ty = rest.y - rig_b.y;
					if ((ty > 0.068 && ty < 0.076) || (ty > 0.083 && ty < 0.091)) c.rgb = vec3(0.25, 0.1, 0.14);
				}
				if (foot_pattern == 11) {   // ince çorap + açık burunlu ayakkabı (Adorable): bilekten yukarısı çorap rengi, parmak üstünde kayış, kontrast taban yok
					if (fy > 0.04) c.rgb = acc2;
					else if (rest.z > 0.035 && fy > -0.04 && fy < -0.005) c.rgb = acc2;
				}
				if (foot_pattern == 10) {   // açık burunlu bot (Wonder Star): parmak bandı beyaz + siyah yıldızlar, taban ikinci renk
					if (fy < -0.06) c.rgb = acc2;
					else if (rest.z > 0.03 && fy < 0.035) { c.rgb = vec3(0.94, 0.95, 0.96); if (length(fract(vec2(rest.x * 45.0, fy * 45.0)) - 0.5) < 0.2) c.rgb = vec3(0.08); }
				}
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
				if (pants_pattern == 13 && rest.z > 0.0) {   // ön uyluk kot paneli (Leaf Striker): kalçadan dize daralan açık panel
					float t = clamp((rig_b.x - 0.02 - rest.y) / max(rig_b.x - rig_b.y - 0.06, 0.05), 0.0, 1.0);
					float w = mix(0.085, 0.03, t);
					if (rest.y < rig_b.x - 0.01 && rest.y > rig_b.y + 0.04 && abs(lx - 0.095) < w) c.rgb = (pants_pipe.a > 0.5 && abs(lx - 0.095) > w - 0.007) ? pants_pipe.rgb : acc;
				}
				if (pants_pattern == 27 && rest.z > 0.0) {   // ışıklı hat pantolon: dizde V, incikte dikey çizgi
					vec3 glow = vec3(1.0, 0.86, 0.95);
					float lx2 = abs(rest.x) - 0.09;
					if (abs(rest.y - rig_b.y - abs(lx2) * 1.0) < 0.005 && abs(lx2) < 0.03) c.rgb = glow;
					if (abs(lx2) < 0.004 && rest.y < rig_b.y - 0.06 && rest.y > rig_b.z + 0.08) c.rgb = glow;
				}
				if (pants_pattern == 28 && abs(rest.z) < 0.012 && abs(rest.x) > 0.08 && fract(rest.y * 50.0) < 0.35) c.rgb = vec3(0.82, 0.82, 0.86);   // yan dikişte çivi sırası
				if (pants_pattern == 29 && fract((rest.x + rest.z) * 22.0) < 0.5) c.rgb = acc;   // dikey çizgili çorap-tayt
				if (pants_pattern == 30) {   // yeşil gezegen, yıldız ve hilal baskı
					vec2 pq = vec2(atan(rest.z, rest.x - sign(rest.x) * 0.09) * 0.065 + sign(rest.x) * 0.5, rest.y) * 9.0;
					vec2 cell = floor(pq); vec2 f = fract(pq) - 0.5;
					float h = hash(cell);
					float a2 = atan(f.x, f.y); float rr = length(f);
					if (h < 0.4) { if (rr < 0.26 * (0.45 + 0.55 * pow(abs(cos(a2 * 2.5)), 3.0))) c.rgb = acc; }
					else if (h < 0.7) { if (rr < 0.2 && length(f - vec2(0.08, 0.05)) > 0.17) c.rgb = acc; }
					else if (h < 0.85) { if (rr < 0.15 || (abs(f.y + f.x * 0.3) < 0.03 && abs(f.x) < 0.3)) c.rgb = acc; }
				}
				if (pants_pattern == 26 && rest.y < rig_b.z + 0.3) {   // eteğin altında gümüş bulut girdapları
					vec2 q = vec2((rest.x + rest.z) * 14.0, rest.y * 14.0);
					vec2 f = fract(q) - 0.5;
					float r = length(f);
					if (abs(r - 0.32) < 0.06 && atan(f.y, f.x) > -1.5) c.rgb = vec3(0.78, 0.8, 0.86);
				}
				if (pants_pattern == 25) { float ph = mix(rig_b.y, rig_b.z, 0.45); if (rest.y > ph + 0.01 && rest.y < ph + 0.075 && fract((rest.y - ph) * 30.0) < 0.42) c.rgb = acc; }   // paçada iki kırmızı bant
				if (pants_pattern == 24 && rest.z > 0.03 && rest.y > rig_b.x - 0.16 && abs(rest.x) < 0.035 - (rig_b.x - rest.y) * 0.08) c.rgb = acc;   // şortun önünde kahve kapak + püskül
				if (pants_pattern == 22 && rest.y < rig_b.z + 0.24 && rest.y > rig_b.z + 0.185) c.rgb = acc;   // hakama paçasında beyaz bant (Training)
				if (pants_pattern == 23 && rest.y < rig_b.x - 0.155 && rest.y > rig_b.x - 0.18) c.rgb = acc;   // pilili etek ucunda beyaz bant (WTNY)
				if (pants_pattern == 21) {   // yıldız baskı (Wonder Star)
					vec2 pq = vec2(atan(rest.z, rest.x - sign(rest.x) * 0.09) * 0.065 + sign(rest.x) * 0.5, rest.y) * 8.0;   // bacak çevresi yay uzunluğu: yanda yıldız uzamasın
					vec2 cell = floor(pq); vec2 f = fract(pq) - 0.5 + (vec2(hash(cell), hash(cell + 7.0)) - 0.5) * 0.12;
					float a2 = atan(f.x, f.y) + hash(cell + 3.0) * 1.2; float rr = length(f);
					float st = (0.24 + 0.1 * hash(cell + 1.0)) * (0.45 + 0.55 * pow(abs(cos(a2 * 2.5)), 3.0));
					if (rr < st) c.rgb = acc;
					else if (rr < st + 0.025) c.rgb = mix(c.rgb, vec3(0.1), 0.5);
				}
				if (pants_pattern == 20) {   // ekose
					vec2 pq = vec2((rest.x + rest.z) * 16.0, rest.y * 16.0);
					if (fract(pq.x) < 0.1 || fract(pq.y) < 0.1) c.rgb = mix(c.rgb, acc, 0.45);
					if (fract(pq.x * 0.5 + 0.25) < 0.03 || fract(pq.y * 0.5 + 0.25) < 0.03) c.rgb = mix(c.rgb, vec3(0.85, 0.85, 0.9), 0.25);
				}
				if (pants_pattern == 18 && rest.y > rig_b.y - 0.05) {   // baklava (argyle) iki sıra, ön yüz
					vec2 aq = vec2((rest.x + rest.z) * 14.0, rest.y * 14.0);
					vec2 f = fract(aq) - 0.5;
					if (abs(f.x) + abs(f.y) < 0.32 && rest.z > -0.02 && mod(floor(aq.x), 2.0) < 0.5) c.rgb = acc;
				}
				if (pants_pattern == 19) {   // kedi: üst gri bölüm dişli kenarla biter, dizde beyaz bıyıklı kedi yüzü
					float edge = rig_b.y + 0.12 + 0.02 * step(0.5, fract((rest.x + rest.z) * 18.0));
					if (rest.y > edge) c.rgb = acc;
					vec2 kp = vec2(abs(rest.x) - 0.1, rest.y - (rig_b.y + 0.04));
					if (rest.z > 0.0 && abs(kp.y) < 0.004 && abs(kp.x) < 0.04 && abs(kp.x) > 0.012) c.rgb = vec3(0.92, 0.92, 0.9);
					if (rest.z > 0.0 && length(kp - vec2(-0.01, 0.012)) < 0.004 || length(kp - vec2(0.01, 0.012)) < 0.004) c.rgb = vec3(0.92, 0.92, 0.9);
				}
				if (pants_pattern == 15) {   // hibiskus: beyaz zemin, pembe/mor çiçekler + yeşil yapraklar
					vec2 hq = vec2((rest.x + rest.z) * 7.0, rest.y * 7.0);
					vec2 cell = floor(hq); vec2 f = fract(hq) - 0.5;
					float an = atan(f.y, f.x); float r = length(f);
					if (hash(cell) > 0.35 && r < 0.2 + 0.12 * abs(sin(an * 2.5))) c.rgb = hash(cell + 2.0) > 0.5 ? vec3(0.85, 0.55, 0.9) : vec3(0.95, 0.45, 0.6);
					else if (hash(cell + 4.0) > 0.4 && length(f - vec2(0.3, -0.25)) < 0.18) c.rgb = vec3(0.2, 0.55, 0.25);
					if (r < 0.05 && hash(cell) > 0.35) c.rgb = vec3(0.98, 0.85, 0.2);
				}
				if (pants_pattern == 16 && fract((rest.x + rest.z) * 9.0) > 0.5) c.rgb = acc;   // geniş dikey şerit
				if (pants_pattern == 17) {   // gökyüzü + karpuz dilimleri
					c.rgb = mix(vec3(0.3, 0.6, 0.9), vec3(0.95, 0.97, 1.0), smoothstep(0.55, 0.75, vnoise(vec2(rest.x + rest.z, rest.y) * 9.0)));
					vec2 wq = vec2((rest.x + rest.z) * 9.0, rest.y * 9.0);
					vec2 cell = floor(wq); vec2 f = fract(wq);
					if (hash(cell) > 0.55 && f.y < 0.5 && abs(f.x - 0.5) < (0.5 - f.y) * 0.8) c.rgb = f.y < 0.08 ? vec3(0.2, 0.6, 0.3) : vec3(0.9, 0.2, 0.25);
				}
				if (pants_pattern == 14 && rest.y < rig_b.x - 0.15 && rest.y > rig_b.x - 0.27) {   // uyluk bandında balon sırası + zikzak ip (Sand Balloons)
					float bx = (rest.x + rest.z) * 22.0;
					float yy = (rest.y - (rig_b.x - 0.21)) * 22.0;
					float zz = abs(fract(bx * 0.5) - 0.5) * 2.0 - 0.5;
					if (abs(yy - zz * 0.8) < 0.12) c.rgb = vec3(0.92, 0.92, 0.9);
					vec2 bf = vec2(fract(bx) - 0.5, yy - 0.5);
					if (length(bf) < 0.3) c.rgb = acc;
				}
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
					// Akatsuki (ref akatsukiset.png): göğüs ortasında büyük kızıl bulut, eteğin iki yanında birer bulut, sırtta aynı düzen;
					// beyaz kalın kontur + sarmal; önde boydan boya kırmızı kapanış çizgisi; astar (iç yüz, kol ağzı, yaka içi) kırmızı
					// gövde çevresinde yay uzunluğu (ön/arka ortadan): yanlarda düz kesilmesin; bulutlar ön/arka sınırından uzak
					float ua = rest.z >= 0.0 ? atan(rest.x, rest.z) : atan(-rest.x, -rest.z);
					vec2 pf = vec2(ua * 0.17, rest.y);
					float cd = 9.0; float sw = 9.0;
					vec3 cl[3] = vec3[3](vec3(0.0, outer_top - 0.3, 0.17), vec3(-0.1, outer_hem + 0.3, 0.12), vec3(0.11, outer_hem + 0.48, 0.12));
					if (abs(rest.x) < sleeve_end - 0.12) {
						for (int ci = 0; ci < 3; ci++) {
							vec2 p = (pf - cl[ci].xy) / cl[ci].z;
							// üç tümsek + yanda küçük kıvrım, düz-dalgalı taban
							float d = length(p - vec2(-0.48, -0.08)) - 0.34;
							d = min(d, length(p - vec2(-0.05, 0.2)) - 0.42);
							d = min(d, length(p - vec2(0.42, 0.02)) - 0.34);
							d = min(d, length(p - vec2(0.78, -0.2)) - 0.2);
							d = min(d, length(p - vec2(-0.85, -0.25)) - 0.18);
							d = max(d, -(p.y + 0.42 + 0.05 * sin(p.x * 9.0)));
							cd = min(cd, d);
							// sarmal: büyük tümseğin içinde beyaz kıvrım
							vec2 sp = p - vec2(-0.05, 0.16);
							float sa = atan(sp.y, sp.x);
							float sr = length(sp);
							float spiral = abs(fract((sr - 0.06 * (sa + 3.1416)) / 0.19) - 0.5) * 0.19;
							if (sr < 0.3 && sr > 0.05 && sa > -1.2) sw = min(sw, spiral);
						}
					}
					float ow = 0.07;   // beyaz kontur (bulut biriminde)
					if (cd < 0.0) c.rgb = sw < 0.022 ? vec3(0.95, 0.94, 0.92) : outer_accent.rgb;
					else if (cd < ow) c.rgb = vec3(0.95, 0.94, 0.92);
					if (rest.z > 0.0 && abs(rest.x) < 0.007 && rest.y < outer_top + 0.2) c.rgb = outer_accent.rgb;   // ön kapanış çizgisi
					if (lining > 0.5) c.rgb = outer_accent.rgb * 0.85;   // astar + kol ağzı
				}
				if (outer_pattern == 7) {
					// yaprak dalı baskısı (Striker Leaf Striker): seyrek, eğik dallar; ortada sap, iki yanda karşılıklı 3 çift yaprak (gövde + kollar)
					vec2 q = vec2(rest.x + rest.z * 0.8, rest.y) * 9.0;
					vec2 cell = floor(q);
					vec2 f = fract(q) - 0.5;
					if (hash(cell) > 0.35) {
						float ang = 0.35 + (hash(cell + 7.3) - 0.5) * 0.9;
						f = mat2(vec2(cos(ang), sin(ang)), vec2(-sin(ang), cos(ang))) * f;
						bool on = abs(f.x) < 0.02 && f.y > -0.4 && f.y < 0.34;
						for (int k = 0; k < 3; k++) {
							float y0 = -0.24 + float(k) * 0.2;
							for (int sgn = -1; sgn <= 1; sgn += 2) {
								vec2 lp = f - vec2(float(sgn) * 0.11, y0 + 0.06);
								float la = float(sgn) * 0.75;
								lp = mat2(vec2(cos(la), sin(la)), vec2(-sin(la), cos(la))) * lp;
								if (length(lp / vec2(0.055, 0.13)) < 1.0) on = true;
							}
						}
						if (length((f - vec2(0.0, 0.4)) / vec2(0.06, 0.13)) < 1.0) on = true;   // uç yaprak
						if (on) c.rgb = outer_accent.rgb;
					}
				}
				if (outer_pattern == 41) {   // kutlama kimonosu: ön açıklık, etek ucu ve kol ağzında mavi kenar; altın-turuncu alev desenleri
					float t2 = clamp((outer_top - rest.y) / max(outer_top - outer_hem, 0.1), 0.0, 1.0);
					if (rest.y < outer_hem + 0.035) c.rgb = outer_accent.rgb;
					if (rest.z > 0.0 && abs(rest.x) < 0.035 + max(0.0, t2 - 0.4) * 0.14 && abs(rest.x) > 0.005 + max(0.0, t2 - 0.4) * 0.14 && t2 > 0.38) c.rgb = outer_accent.rgb;
					float fn = vnoise(vec2(rest.x * 9.0 + rest.z * 6.0, rest.y * 5.0 - rest.x * 3.0));
					float band = abs(fract(rest.y * 6.0 + fn * 1.5 + rest.x * 3.0) - 0.5);
					if (rest.y < rig_b.x - 0.05 && rest.x < -0.02 && band < 0.08) c.rgb = mix(vec3(1.0, 0.75, 0.2), vec3(0.95, 0.4, 0.1), band * 10.0);
					bool armr = abs(rest.x) > rig_a.x * 1.02 && rest.y > rig_a.w - 0.25;
					if (armr && abs(rest.x) > rig_a.z - 0.1) c.rgb = outer_accent.rgb;
				}
				if (outer_pattern == 42 && rest.z > 0.0 && rest.x > 0.015 && rest.x < 0.055) c.rgb = outer_accent.rgb;   // takım yeleği: solda dikey lila şerit
				if (outer_pattern == 39) {   // Rikudō cübbesi: göğüste iki yay halinde 6 tomoe, sırtta 9 tomoe halkası; yanlar lila gölge
					vec2 tq[6] = vec2[6](vec2(-0.11, -0.03), vec2(-0.075, -0.06), vec2(-0.045, -0.08), vec2(0.045, -0.08), vec2(0.075, -0.06), vec2(0.11, -0.03));
					float ny2 = rest.y - rig_b.w;
					if (rest.z > 0.02) {
						for (int k = 0; k < 6; k++) {
							vec2 d = vec2(rest.x, ny2) - tq[k];
							if (length(d) < 0.011) c.rgb = vec3(0.06);
							if (length(d - vec2(0.008, 0.009)) < 0.006 && length(d) < 0.02) c.rgb = vec3(0.06);
						}
					}
					if (rest.z < -0.02) {
						vec2 q = vec2(rest.x, ny2 + 0.08);
						float a2 = atan(q.y, q.x);
						float r = length(q);
						float sec = floor((a2 + 3.14159) / 6.28318 * 9.0);
						float ca = (sec + 0.5) / 9.0 * 6.28318 - 3.14159;
						vec2 cpos = vec2(cos(ca), sin(ca)) * 0.09;
						if (length(q - cpos) < 0.011) c.rgb = vec3(0.06);
						if (r < 0.035 && abs(r - 0.025) < 0.005) c.rgb = vec3(0.06);
					}
					if (abs(rest.x) > 0.13 && abs(rest.x) < rig_a.x * 1.02) c.rgb = mix(c.rgb, vec3(0.78, 0.74, 0.9), 0.35);
				}
				if (outer_pattern == 40) {   // yırtık eşofman: kolda üç kırmızı bant
					bool armr = abs(rest.x) > rig_a.x * 1.02 && rest.y > rig_a.w - 0.25;
					if (armr) { float u = (abs(rest.x) - rig_a.x) / max(rig_a.z - rig_a.x, 0.1); if (u > 0.22 && u < 0.42 && fract(u * 15.0) < 0.45) c.rgb = outer_accent.rgb; }
				}
				if (outer_pattern == 38) {   // güneş kimonosu: göğüste alevli güneş (beyaz disk + kızıl alev halesi), çapraz kenarda desenli şerit, etek ucunda bant
					vec2 q = vec2(rest.x - 0.03, rest.y - (rig_b.w - 0.1));
					float r = length(q);
					float fl = 0.055 + 0.025 * pow(abs(sin(atan(q.y, q.x) * 5.0 + r * 30.0)), 2.0);
					if (rest.z > 0.0 && r < fl) c.rgb = mix(vec3(0.9, 0.25, 0.1), vec3(1.0, 0.7, 0.2), smoothstep(fl, 0.03, r));
					if (rest.z > 0.0 && r < 0.03) c.rgb = vec3(0.98, 0.97, 0.94);
					float ex = -0.12 + (rig_a.w - rest.y) * 0.75;   // çapraz üst kenar (sağ omuzdan sol bele)
					if (rest.y > rig_b.x + 0.1 && abs(rest.x - ex) < 0.02) c.rgb = mix(outer_accent.rgb, c.rgb, step(0.5, fract(rest.y * 40.0)) * 0.4);
					if (rest.y < outer_hem + 0.03) c.rgb = outer_accent.rgb;
				}
				if (outer_pattern == 37 && rest.z > 0.0) {   // kısa kimono: sol omuzdan sağa inen kruvaze yaka çizgisi (kat kenarı)
					float lx = 0.07 - (rig_a.w - rest.y) * 0.55;
					if (abs(rest.x - lx) < 0.004 && rest.y > rig_b.x + 0.02) c.rgb *= 0.55;
				}
				if (outer_pattern == 36) {   // yırtmaçlı uzun üst: S kıvrımlı fermuar, etek kenarında beyaz biye, sırtta Uchiha yelpazesi
					float zx = (rest.y > rig_b.w - 0.06) ? 0.0 : clamp((rig_b.w - 0.06 - rest.y) * 0.5, 0.0, 0.05);
					if (rest.z > 0.0 && abs(rest.x - zx) < 0.004 && rest.y > rig_b.x - 0.05) c.rgb = vec3(0.85, 0.85, 0.88);
					if (rest.y < outer_hem + 0.015) c.rgb = vec3(0.95, 0.94, 0.92);
					if (rest.z < -0.02) {
						vec2 q = vec2(rest.x, rest.y - (rig_b.w - 0.06));
						float r = length(q * vec2(1.0, 1.08));
						if (r < 0.06) c.rgb = q.y > -0.003 ? vec3(0.82, 0.08, 0.08) : vec3(0.97, 0.96, 0.94);
						if (r > 0.06 && r < 0.066) c.rgb = vec3(0.05, 0.05, 0.06);
						if (abs(q.x) < 0.01 && q.y < -0.06 && q.y > -0.12) c.rgb = vec3(0.97, 0.96, 0.94);
					}
				}
				if (outer_pattern == 34) {   // iki tonlu kimono: sağ yarı (−x) ve sağ kol beyaz, sağ omuzdan sol bele inen beyaz yaka bandı
					bool armr = abs(rest.x) > rig_a.x * 1.02 && rest.y > rig_a.w - 0.25;
					float cx = 0.05 - (rig_a.w - rest.y) * 0.35;
					if (rest.x < (armr ? 0.0 : cx)) c.rgb = outer_accent.rgb;
					if (!armr && rest.z > 0.0 && abs(rest.x - cx) < 0.018 && rest.y > rig_b.x + 0.05) c.rgb = outer_accent.rgb * 1.05;
				}
				if (outer_pattern == 35) {   // kapalı eşofman: göğüs altından bele ön/yan turuncu, omuzlar/kollar/sırt üstü ikinci renk; sırtta girdap
					bool armr = abs(rest.x) > rig_a.x * 1.02 && rest.y > rig_a.w - 0.25;
					if (armr || rest.y > rig_b.w - 0.04) c.rgb = outer_accent.rgb;
					if (!armr && rest.z < -0.02) {
						vec2 q = vec2(rest.x, rest.y - (rig_b.w - 0.12));
						float r = length(q);
						float a2 = atan(q.y, q.x);
						if (r < 0.06 && step(0.6, fract(a2 / 6.28318 + r * 16.0)) > 0.5) c.rgb = vec3(0.78, 0.14, 0.12);
						if (r > 0.06 && r < 0.068) c.rgb = vec3(0.78, 0.14, 0.12);
					}
				}
				if (outer_pattern == 31) {   // kapüşonlu ceket: kollar + yaka beyaz (vurgu), bilekte ana renk kat
					bool armr = abs(rest.x) > rig_a.x * 1.02 && rest.y > rig_a.w - 0.25;   // gövde yanı kol sayılmasın
					if (armr) { if (abs(rest.x) < rig_a.z - 0.075) c.rgb = outer_accent.rgb; }
					else if (rest.y > rig_a.w - 0.06) c.rgb = outer_accent.rgb;
				}
				if (outer_pattern == 32 && rest.z > 0.0) {   // kısa kapüşonlu: sağ omuzdan inen kruvaze kat çizgisi + yan dikiş
					float lx = -0.06 + (rig_a.w - rest.y) * 0.25;
					if (abs(rest.x - lx) < 0.004 && rest.y < rig_a.w - 0.02) c.rgb *= 0.55;
				}
				if (outer_pattern == 33 && rest.z > 0.0) {   // uzun sargı etek: önde kruvaze kat (soldan sağa inen kenar) + kenar dikişi
					float lx = 0.05 + (rig_b.x - rest.y) * 0.06;
					if (abs(rest.x - lx) < 0.004) c.rgb *= 0.5;
				}
				if (outer_pattern == 30) {   // eşofman: kolun dış yüzünde boydan renkli şerit, sırtta girdap arması
					bool armr = abs(rest.x) > rig_a.x * 0.9 && rest.y > rig_a.w - 0.32;
					if (armr && abs(rest.z) < 0.011 && rest.y > outer_top - 0.08) c.rgb = outer_accent.rgb;
					if (!armr && rest.z < -0.02) {
						vec2 q = vec2(rest.x, rest.y - (rig_b.w - 0.07));
						float r = length(q);
						float a2 = atan(q.y, q.x);
						if (r < 0.06 && step(0.6, fract(a2 / 6.28318 + r * 16.0)) > 0.5) c.rgb = vec3(0.75, 0.12, 0.16);
						if (r > 0.06 && r < 0.068) c.rgb = vec3(0.75, 0.12, 0.16);
					}
				}
				if (outer_pattern == 28 || outer_pattern == 29) {
					// hemşire önlüğü: önde çift sıra panelin biye çizgisi (yakadan V, iki dikey hat), sol yanda astarlı yırtmaç,
					// sırtta baskı (28: kırmızı 医, 29: tavşan)
					float ny2 = rest.y - rig_b.w;
					float ax2 = abs(rest.x);
					float pw = 0.062;
					vec3 pipe = outer_accent.rgb;
					if (rest.z > 0.0) {
						float vy = rig_a.w - 0.03 - (ax2 / pw) * 0.07;
						bool vline = ax2 < pw && abs(rest.y - vy) < 0.0035;
						bool sline = abs(ax2 - pw) < 0.0035 && rest.y < rig_a.w - 0.1;
						if (vline || sline) c.rgb = pipe;
						if (rest.x > pw + 0.004 && rest.x < pw + 0.04 && rest.y < rig_b.x - 0.1 - (rest.x - pw) * 2.0) c.rgb = pipe;   // yırtmaç astarı
					}
					if (rest.z < -0.02 && ny2 < 0.0 && ny2 > -0.16) {
						vec2 q = vec2(rest.x, ny2 + 0.05);
						bool ink = false;
						if (outer_pattern == 28) {
							float lw = 0.0045;
							ink = ink || (abs(q.y - 0.04) < lw && q.x > -0.04 && q.x < 0.04);
							ink = ink || (abs(q.x + 0.04) < lw && abs(q.y) < 0.04);
							ink = ink || (abs(q.y + 0.04) < lw && q.x > -0.04 && q.x < 0.045);
							ink = ink || (abs(q.y - 0.02) < lw && q.x > -0.022 && q.x < 0.012);
							ink = ink || (abs(q.x + 0.016 + (q.y - 0.02) * 0.4) < lw && q.y > 0.02 && q.y < 0.032);
							ink = ink || (abs(q.y) < lw && q.x > -0.026 && q.x < 0.03);
							ink = ink || (abs(q.x) < lw && q.y > 0.0 && q.y < 0.032);
							ink = ink || (abs(q.x + q.y * 0.8) < lw && q.y < 0.0 && q.y > -0.032);
							ink = ink || (abs(q.x - q.y * -0.8) < lw && q.y < 0.0 && q.y > -0.032 && q.x > 0.0);
							if (ink) c.rgb = vec3(0.78, 0.1, 0.12);
						} else {
							ink = length(q / vec2(0.032, 0.026)) < 1.0;
							ink = ink || length((q - vec2(-0.014, 0.045)) / vec2(0.009, 0.026)) < 1.0;
							ink = ink || length((q - vec2(0.014, 0.045)) / vec2(0.009, 0.026)) < 1.0;
							if (ink) c.rgb = vec3(0.2, 0.62, 0.6);
							if (length(q - vec2(-0.011, 0.004)) < 0.004 || length(q - vec2(0.011, 0.004)) < 0.004) c.rgb = vec3(0.05);
							if (length(q - vec2(0.0, -0.006)) < 0.004) c.rgb = vec3(0.95, 0.5, 0.6);
						}
					}
				}
				if (outer_pattern >= 25 && outer_pattern <= 27) {
					// uzun ceket: göğüste V omuz dikişi (25 düz; 26 Air: üst bölüm ve kollar kahve, açılım kenarında sarı çimen işi;
					// 27 Springtime: kollar/omuz beyaz, eteğe yakın renkli toplar); açılımın kenarında astar rengi (vurgu)
					float vy = rig_b.w + 0.04 - abs(rest.x) * 0.45;
					bool yoke = rest.y > vy;
					if (abs(rest.y - vy) < 0.004) c.rgb *= 0.6;
					if (outer_pattern == 26 && yoke) c.rgb = vec3(0.62, 0.5, 0.42);
					if (outer_pattern == 27 && yoke) c.rgb = vec3(0.93, 0.95, 0.96);
					float tt = clamp((outer_top - rest.y) / max(outer_top - outer_hem, 0.1), 0.0, 1.0);
					if (rest.z > 0.0 && tt > 0.42) {
						float ga = abs(atan(rest.x, rest.z));
						float gw = (tt - 0.42) * 1.5;
						if (ga < gw + 0.3) c.rgb = outer_accent.rgb;   // astar kanadı
						if (outer_pattern == 26 && abs(ga - gw - 0.3) < 0.03 + 0.02 * sin(rest.y * 120.0)) c.rgb = vec3(0.95, 0.78, 0.2);
					}
					if (outer_pattern == 27 && dh > 0.15 && dh < 0.3) {
						vec2 bq = vec2(oa * 2.5, rest.y * 12.0);
						vec2 f = fract(bq) - 0.5;
						if (length(f) < 0.32 && mod(floor(bq.x), 2.0) < 0.5) c.rgb = hash(floor(bq)) > 0.5 ? vec3(0.95, 0.85, 0.3) : vec3(0.6, 0.85, 0.75);
					}
				}
				if (outer_pattern == 23 && rest.z > 0.0 && abs(rest.x) < 0.09 && abs(rest.x) < sleeve_end - 0.2) {   // Argyle: önde baklava paneli
					vec2 aq = vec2(rest.x * 16.0 + 0.5, rest.y * 11.0);
					vec2 f = fract(aq) - 0.5;
					float dd = abs(f.x) + abs(f.y);
					if (dd < 0.45) c.rgb = mod(floor(aq.x) + floor(aq.y), 2.0) < 0.5 ? vec3(0.95, 0.94, 0.92) : vec3(0.88, 0.62, 0.5);
					if (abs(abs(f.x) - abs(f.y)) < 0.04) c.rgb = vec3(0.98);
				}
				if (outer_pattern == 24) {   // örgü bantları: yatay örgü desen şeritleri
					float kb = fract(rest.y * 14.0);
					if (kb < 0.18) c.rgb *= 1.0 - 0.25 * step(0.5, fract((rest.x + rest.z) * 40.0 + rest.y * 10.0));
					if (abs(kb - 0.6) < 0.04) c.rgb = mix(c.rgb, vec3(0.75, 0.8, 0.95), 0.18);
				}
				if (outer_pattern == 20 || outer_pattern == 21 || outer_pattern == 22) {
					// 20 kutup ayısı: önde sağ altta ayı yüzü, solda pati; altta beyaz dalgalı etek. 21 kedi: göğüs altında sarı-siyah şerit +
					// beyaz fisto, altta iki pati. 22 ruh: sırtta ateş topu.
					bool front = rest.z > 0.0;
					if (outer_pattern == 20) {
						if (dh < 0.05 + 0.012 * sin(oa * 30.0)) c.rgb = vec3(0.95, 0.97, 1.0);
						vec2 fp = vec2(rest.x + 0.08, rest.y - (outer_hem + 0.13));
						if (front && length(fp) < 0.035) c.rgb = vec3(0.97, 0.98, 1.0);
						if (front && (length(fp - vec2(-0.028, 0.03)) < 0.013 || length(fp - vec2(0.028, 0.03)) < 0.013)) c.rgb = vec3(0.97, 0.98, 1.0);
						vec2 pp = vec2(rest.x - 0.09, rest.y - (outer_hem + 0.12));
						if (front && (length(pp) < 0.022 || length(pp - vec2(-0.022, 0.026)) < 0.008 || length(pp - vec2(0.0, 0.032)) < 0.008 || length(pp - vec2(0.022, 0.026)) < 0.008)) c.rgb = vec3(0.97, 0.98, 1.0);
					}
					if (outer_pattern == 21) {
						float hy = rest.y - (outer_hem + 0.17);
						if (abs(hy) < 0.012) c.rgb = vec3(0.95, 0.82, 0.2);
						else if (abs(hy - 0.02) < 0.008 || abs(hy + 0.02) < 0.008) c.rgb = vec3(0.08, 0.08, 0.1);
						if (hy < -0.028 && hy > -0.05 + 0.01 * sin(oa * 40.0)) c.rgb = vec3(0.96, 0.96, 0.95);
						for (int sx = -1; sx <= 1; sx += 2) {
							vec2 pp = vec2(rest.x - float(sx) * 0.09, rest.y - (outer_hem + 0.07));
							if (front && (length(pp) < 0.026 || length(pp - vec2(-0.025, 0.03)) < 0.009 || length(pp - vec2(0.0, 0.037)) < 0.009 || length(pp - vec2(0.025, 0.03)) < 0.009)) c.rgb = vec3(0.06, 0.06, 0.08);
						}
					}
					if (outer_pattern == 22 && !front) {
						vec2 fb = vec2(rest.x, rest.y - (outer_hem + 0.2));
						float r = length(fb * vec2(1.0, 0.8));
						float fl = 0.06 + 0.03 * sin(atan(fb.y, fb.x) * 7.0) * step(0.0, fb.y);
						if (r < fl) c.rgb = r < fl * 0.55 ? vec3(0.98, 0.85, 0.2) : vec3(0.92, 0.3, 0.12);
					}
				}
				if (outer_pattern == 19) {   // Flamingo: beyaz zemin, pembe flamingolar; fırfır katı koyu kırmızı-pembe bantlar
					if (rest.y < rig_b.x - 0.15) {
						float rb = fract((rig_b.x - 0.15 - rest.y) * 30.0);
						c.rgb = rb < 0.5 ? vec3(0.62, 0.12, 0.2) : vec3(0.95, 0.6, 0.7);
					} else {
						vec2 fq = vec2(oa * 1.5, rest.y * 6.0);
						vec2 cell = floor(fq); vec2 f = fract(fq) - 0.5;
						if (mod(cell.x + cell.y, 2.0) < 0.5) {
							bool fl = length((f - vec2(0.0, -0.02)) / vec2(0.3, 0.15)) < 1.0;                 // gövde
							fl = fl || (abs(f.x - 0.2 + (f.y - 0.1) * 0.25) < 0.035 && f.y > 0.0 && f.y < 0.36);                // boyun
							fl = fl || length(f - vec2(0.15, 0.38)) < 0.07;                                   // baş
							fl = fl || (abs(f.x + 0.02) < 0.02 && f.y < -0.12 && f.y > -0.48);               // bacak
							if (fl) c.rgb = vec3(0.9, 0.32, 0.48);
						}
					}
				}
				if (outer_pattern == 17) {   // Maritime: kırmızı-beyaz-mavi bantlar (omuz mavi, göğüs beyaz, ortada kırmızı bant)
					float hy = outer_top - rest.y;
					if (hy < 0.08) c.rgb = vec3(0.12, 0.25, 0.7); else if (abs(hy - 0.2) < 0.045) c.rgb = vec3(0.85, 0.15, 0.15);
				}
				if (outer_pattern == 18) {   // Sky Blue: üst yarı sarı, alt yarı beyaz
					if (rest.y > rig_b.w - 0.08) c.rgb = vec3(0.98, 0.82, 0.15); else c.rgb = vec3(0.96, 0.96, 0.95);
				}
				if (outer_pattern == 15) {
					// su balonu baskısı (Sand Balloons): renkli yuvarlak balonlar, parlama + bağ ipi, seyrek
					vec2 bq = vec2(oa * 1.6, rest.y * 7.0);
					vec2 cell = floor(bq);
					vec2 f = fract(bq) - vec2(0.5, 0.55);
					if (hash(cell) > 0.45) {
						vec3 bcol = hash(cell + 1.7) > 0.66 ? vec3(0.92, 0.25, 0.25) : (hash(cell + 1.7) > 0.33 ? vec3(0.95, 0.75, 0.2) : vec3(0.25, 0.75, 0.85));
						if (length(f) < 0.26) c.rgb = length(f - vec2(-0.08, 0.08)) < 0.06 ? vec3(0.98) : bcol;
						if (abs(f.x) < 0.012 && f.y > 0.26 && f.y < 0.5) c.rgb = vec3(0.95, 0.95, 0.95);
					}
				}
				if (outer_pattern == 16) {
					// Tribal: etek ucunda sarı üçgen dişli bant (uçları aşağı)
					if (dh < 0.06) {
						float tx = abs(fract(oa * 7.0) - 0.5);
						if (dh < 0.012 || dh < 0.06 - tx * 0.1) c.rgb = outer_accent.rgb;
					}
				}
				if (outer_pattern == 14) {
					// Kaya gi: önde çapraz bindirme (sağ kanat sola biner): bindirme çizgisi ve yaka kenarı beyaz biye; etek ucunda vurgu rengi bant
					if (dh < 0.022) c.rgb = outer_accent.rgb;
					else if (dh < 0.028) c.rgb = vec3(0.95, 0.95, 0.93);
					if (rest.z > 0.0) {
						float yy = (outer_top - rest.y);
						float lx = -0.03 + yy * 0.42;   // bindirme çizgisi: boyundan aşağı sağa iner
						if (rest.y > rig_b.x + 0.06 && abs(rest.x - min(lx, 0.11)) < 0.006) c.rgb = vec3(0.95, 0.95, 0.93);
						if (rest.y <= rig_b.x + 0.06 && abs(rest.x - 0.11) < 0.006) c.rgb = vec3(0.95, 0.95, 0.93);
						float lx2 = 0.03 - yy * 0.42;  // altta kalan kanadın yaka kenarı
						if (rest.y > rig_b.x + 0.12 && abs(rest.x - lx2) < 0.005 && lx2 > -0.1) c.rgb = vec3(0.95, 0.95, 0.93) * 0.9;
					}
				}
				if (outer_pattern == 11 || outer_pattern == 12 || outer_pattern == 13) {
					// Bulut sargı eteği: 11 beyaz biye (etek ucu + önde çapraz bindirme çizgisi + iç panel çizgisi); 12 takımyıldız baskısı (altta);
					// 13 etek ucunda zikzak bant (Earth)
					float tt = clamp((rest.y - outer_hem) / max(rig_b.x - outer_hem, 0.05), 0.0, 1.0);
					if (outer_pattern == 11) {
						if (dh < 0.016) c.rgb = outer_accent.rgb;
						if (rest.z > 0.0 && rest.y < rig_b.x) {
							if (abs(rest.x - mix(-0.12, 0.11, tt)) < 0.006) c.rgb = outer_accent.rgb;
							if (abs(rest.x - mix(0.02, 0.13, tt)) < 0.005 && tt < 0.55) c.rgb = outer_accent.rgb;
						}
					}
					if (outer_pattern == 12 && dh < 0.32) {
						vec2 sq = vec2(oa * 1.3, rest.y * 9.0);
						vec2 cell = floor(sq);
						vec2 f = fract(sq);
						vec2 p1 = vec2(hash(cell), hash(cell + 3.1)) * 0.7 + 0.15;
						vec2 p2 = vec2(hash(cell + 5.7), hash(cell + 9.3)) * 0.7 + 0.15;
						vec2 d = p2 - p1;
						float tl = clamp(dot(f - p1, d) / dot(d, d), 0.0, 1.0);
						if (length(f - (p1 + d * tl)) < 0.014) c.rgb = mix(c.rgb, outer_accent.rgb, 0.85);
						if (length(f - p1) < 0.045 || length(f - p2) < 0.04) c.rgb = outer_accent.rgb;
					}
					if (outer_pattern == 13 && dh < 0.07 && dh > 0.02) {
						float zz = abs(fract(oa * 6.0) - 0.5) * 0.06;
						if (abs(dh - 0.045 - zz + 0.015) < 0.006) c.rgb = outer_accent.rgb;
					}
				}
				if (outer_pattern == 9 || outer_pattern == 10) {
					// Kiri tuniği: boydan boya dikey dikiş çizgileri (her ~4 cm); 10: iki renkli (ön orta panel vurgu rengi, panel kenarında
					// sarı biye) + eteğin açık panellerinde satranç taşı kesikleri (Mist Striker Beyaz/Siyah)
					float ua2 = rest.z >= 0.0 ? atan(rest.x, rest.z) : atan(-rest.x, -rest.z);
					float arcx = ua2 * 0.16;
					if (abs(fract(arcx * 25.0) - 0.5) > 0.44) c.rgb *= 0.78;
					if (rest.y > outer_top - 0.085) c.rgb = (outer_pattern == 9 ? outer_accent.rgb : pal[8].rgb);   // atkı yaka
					if (outer_pattern == 10 && abs(rest.x) < sleeve_end - 0.12) {
						bool mid = abs(arcx) < 0.055;
						if (mid) c.rgb = outer_accent.rgb * (abs(fract(arcx * 25.0) - 0.5) > 0.44 ? 0.8 : 1.0);
						if (abs(abs(arcx) - 0.055) < 0.004) c.rgb = vec3(0.92, 0.78, 0.15);
						if (!mid && dh < 0.1 && dh > 0.015) {
							float cx2 = fract(arcx * 14.0) - 0.5;
							float py = (dh - 0.015) / 0.085;
							// satranç taşı silueti: yuvarlak baş + daralan gövde + geniş taban
							bool piece = (length(vec2(cx2, (py - 0.78) * 0.9)) < 0.13) || (py > 0.18 && py < 0.7 && abs(cx2) < 0.06 + 0.06 * (0.7 - py)) || (py < 0.18 && abs(cx2) < 0.17);
							if (piece) c.rgb = vec3(0.08, 0.08, 0.1);
						}
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
		float amt = detail_tex_amt;
		if (detail_brown_only) {
			vec3 vc = COLOR.rgb;
			amt *= smoothstep(0.02, 0.1, vc.r - vc.g) * smoothstep(0.0, 0.06, vc.g - vc.b) * smoothstep(0.62, 0.48, vc.r);   // koyu kahve: r > g > b (kızıl/sarı yapraklar parlak, hariç)
		}
		c.rgb *= 1.0 + (tv - 0.5) * 2.0 * amt;
		if (leaf_tex_amt > 0.0) {
			vec3 lc = COLOR.rgb;
			float green = smoothstep(0.02, 0.08, lc.g - max(lc.r, lc.b * 0.9));
			vec3 lp = wpos * 1.3;
			float lv = texture(leaf_tex, lp.zy).r * wn.x + texture(leaf_tex, lp.xz).r * wn.y + texture(leaf_tex, lp.xy).r * wn.z;
			c.rgb *= 1.0 + (lv - 0.5) * 2.0 * leaf_tex_amt * green;
		}
	}
	if (scalp && scalp_col.a >= 0.5) { c.rgb = scalp_col.rgb * 0.75; v_nospec = 1.0; }
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
		// yanık pencere işaretleri (MB._win_lit parça başına seçer: geniş cam yarım yanmaz)
		float win = step(distance(vc0, vec3(0.603, 0.757, 0.883)), 0.006) + step(distance(vc0, vec3(0.961, 0.903, 0.777)), 0.006);
		float lamp = step(distance(vc0, vec3(1.0, 0.85, 0.5)), 0.02) + step(distance(vc0, vec3(1.0, 0.85, 0.55)), 0.02);
		float red = step(distance(vc0, vec3(0.9, 0.2, 0.15)), 0.012);
		EMISSION += g_night * (win * vec3(1.0, 0.7, 0.32) * 1.5 + red * vec3(1.0, 0.28, 0.12) * 1.8);
	}
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float t = smoothstep(-0.03, 0.05, ndl) * 0.6 + smoothstep(0.42, 0.5, ndl) * 0.4;
	float lit = t * ATTENUATION;
	if (LIGHT_IS_DIRECTIONAL) {
		// anime gölgesi: tamamen kararmaz, hafif soğuk tonlu (yalnız güneş/ay)
		vec3 shade = mix(vec3(0.29, 0.31, 0.43), vec3(1.0), lit);   // koyu, belirgin anime gölgesi
		DIFFUSE_LIGHT += LIGHT_COLOR * shade / PI;
	} else {
		// fener/efekt ışıkları: sadece gerçekten aydınlattığı yerde, yumuşak
		DIFFUSE_LIGHT += LIGHT_COLOR * (0.35 + 0.65 * t) * ATTENUATION / PI;
	}
	if (spec_amount > 0.0 && v_nospec < 0.5) {
		vec3 h = normalize(LIGHT + VIEW);
		float s = smoothstep(0.93, 0.96, dot(NORMAL, h));
		SPECULAR_LIGHT += LIGHT_COLOR * s * spec_amount * ATTENUATION;
	}
}
