// VRoid iris: göz rengi + dōjutsu desenleri (iki göz aynı dokuda: sol yarı / sağ yarı)
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;
// iris göz beyazının hemen önünde: hafif öne çekilerek sıralama sorunsuz
#include "res://shaders/mangekyo.gdshaderinc"

uniform sampler2D tex : source_color, filter_linear_mipmap, hint_default_white;
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
uniform vec2 iris_c_r = vec2(0.255, 0.52);   // dokuda sağ göz irisi merkezi
uniform vec2 iris_c_l = vec2(0.745, 0.52);
uniform vec2 iris_rad = vec2(0.085, 0.2);     // iris yarıçapı (u, v)
uniform float hit_flash = 0.0;
uniform vec3 eye_c_r = vec3(-0.032, 1.62, 0.08);
uniform vec3 eye_c_l = vec3(0.032, 1.62, 0.08);
uniform float iris_r3 = 0.011;
uniform vec2 iris_r2 = vec2(0.0);   // iris yarı en/boy (model uzayı); >0 ise desen gerçek iris geometrisine oturur
varying vec3 lp;

void vertex() {
	lp = VERTEX;
}

// Rinnegan: model uzayında göz merkezinden ince, eşit aralıklı halkalar — iris ve göz akı kesintisiz (referans: Sasuke/Nagato)
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

void fragment() {
	vec4 tx = texture(tex, UV);
	vec4 c = tx;
	float eye_side = UV.x > 0.5 ? 1.0 : -1.0;
	vec2 iq = (UV - (UV.x > 0.5 ? iris_c_l : iris_c_r)) / iris_rad;
	{
		float l = dot(tx.rgb, vec3(0.3, 0.59, 0.11));
		// VRoid iris: kahverengi doku -> oyuncunun göz rengi (parlak vurgu korunur)
		float hl = smoothstep(0.75, 0.95, l);
		c = vec4(mix(eye_color.rgb * (0.35 + l * 1.5), tx.rgb, hl), tx.a);
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
			// desen irisin doku (UV) alanına oturur: göz bakınca irisle birlikte kayar; ölçülen UV sınırlarıyla kenar r=1.
			// irisin üstü kapak altında kaldığından görünen merkez biraz aşağıda
			vec2 q = (iq - vec2(0.0, 0.1)) / 0.64;
			q.x *= eye_side;
			float r = length(q);
			bool fill = dk != 2 && dk != 7 && dk != 8;   // sharingan ailesi: irisin tamamı desen rengi (asıl göz/bebek görünmez)
			if (r < 1.0 || fill) {
				r = min(r, 0.999);
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
				c = vec4(fill ? col : mix(col, c.rgb, smoothstep(0.92, 1.0, r) * 0.5), 1.0);
				// dokudaki parlak ışık noktası korunur (canlı göz)
				c.rgb = mix(c.rgb, tx.rgb, smoothstep(0.82, 0.97, dot(tx.rgb, vec3(0.3, 0.59, 0.11))) * 0.8);
			}
		}
	}
	if (tx.a < 0.4) discard;
	ALBEDO = mix(c.rgb, vec3(1.0), hit_flash);
}
