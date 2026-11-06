// VRoid parçaları (yüz derisi, saç): anime cel gölge, doku x renk ya da parlaklık x renk (saç boyama), alfa kesme
shader_type spatial;
render_mode cull_back, diffuse_toon, specular_disabled;
#include "res://shaders/hair_mask.gdshaderinc"

uniform sampler2D tex : source_color, filter_linear_mipmap, hint_default_white;
uniform vec4 tint : source_color = vec4(1.0);
uniform int mode = 0;            // 0 doku x tint, 1 parlaklık x tint (saç), 2 düz doku (yüz çizgileri)
uniform float alpha_cut = 0.5;
uniform bool use_alpha = false;  // gerçek saydamlık yerine kesme
uniform float rim_amount = 0.35;
uniform float hit_flash = 0.0;
uniform float shade_floor = 0.5;   // karakter gölgesi (dünyadan biraz açık: yüz kararmasın)
// Byakugan: gözlerin çevresinde, şakaklara uzanan kabarık damarlar (yüz derisi)
uniform float byakugan_veins = 0.0;
uniform float seal_marks = 0.0;
uniform float juin_marks = 0.0;   // lanet mührü: yüze yayılan kara alev lekeleri   // Byakugō / Sōzō Saisei: alında elmas + yanaklarda kara mühür çizgileri
uniform vec3 eye_c_r = vec3(-0.032, 1.62, 0.08);
uniform vec3 eye_c_l = vec3(0.032, 1.62, 0.08);
uniform float iris_r3 = 0.011;
varying vec3 lp;

void vertex() {
	lp = VERTEX;
	hm_p = (hm_xf * vec4(VERTEX, 1.0)).xyz;
}

float vein_mask(vec3 p, vec3 c, float ir, float side) {
	vec2 q = (p - c).xy;
	q.x *= side;   // dış taraf (şakak) +x
	float d = length(q) / ir;
	if (d < 1.5 || d > 4.2) return 0.0;
	float a = atan(q.y, q.x);
	// dış köşeden ve göz altından/üstünden dallanan damarlar
	float lines = abs(sin(a * 6.0 + d * 1.7 + sin(d * 2.3) * 0.6));
	float w = 0.22 * (1.0 - (d - 1.5) / 3.0);
	float m = 1.0 - smoothstep(w * 0.5, w, lines);
	float side_k = smoothstep(-0.6, 0.3, cos(a));   // burun tarafında yok
	return m * side_k * smoothstep(4.2, 3.2, d);
}

void fragment() {
	vec4 tx = texture(tex, UV);
	if (hm_cut(hm_p)) discard;
	vec3 c = tx.rgb * tint.rgb;
	if (mode == 1) {
		float l = dot(tx.rgb, vec3(0.3, 0.59, 0.11));
		// saç: dokunun ışık/gölge detayı korunur, renk oyuncunun saç rengi
		c = tint.rgb * (0.45 + l * 1.15);
	} else if (mode == 2) {
		c = tx.rgb;
	}
	if (use_alpha && tx.a < alpha_cut) discard;
	if (byakugan_veins > 0.0) {
		float vm = max(vein_mask(lp, eye_c_r, iris_r3, -1.0), vein_mask(lp, eye_c_l, iris_r3, 1.0));
		c = mix(c, c * vec3(0.55, 0.38, 0.48), vm * byakugan_veins);
	}
	if (juin_marks > 0.0) {
		vec3 ec2 = (eye_c_r + eye_c_l) * 0.5;
		float j = fract(sin(dot(floor(lp.xy * 70.0), vec2(12.9898, 78.233))) * 43758.5453);
		float band = sin(lp.x * 120.0 + lp.y * 40.0) * 0.5 + 0.5;
		if (lp.y < ec2.y + 0.02 && abs(lp.x - ec2.x) > 0.02 && band > 0.55 && j > 0.25 && lp.z > ec2.z - 0.06) c = mix(c, vec3(0.04, 0.02, 0.05), juin_marks);
	}
	if (seal_marks > 0.0) {
		vec3 ec = (eye_c_r + eye_c_l) * 0.5;
		vec2 dd = vec2(lp.x - ec.x, lp.y - (ec.y + 0.055));
		float ax = abs(lp.x - ec.x);
		float yy = lp.y - ec.y;
		if (abs(dd.x) + abs(dd.y) < 0.011 && lp.z > ec.z - 0.03) c = vec3(0.55, 0.15, 0.7);
		else if (ax > 0.012 && ax < 0.065 && yy < -0.014 && yy > -0.075 && lp.z > ec.z - 0.045) {
			float w = sin((yy + ax * 0.9) * 240.0);
			if (abs(w) < 0.28) c = mix(c, vec3(0.08, 0.04, 0.1), 0.9 * seal_marks);
		} else if (ax < 0.07 && yy > 0.02 && yy < 0.09 && lp.z > ec.z - 0.03) {
			float w2 = sin(ax * 260.0 + yy * 120.0);
			if (abs(w2) < 0.2) c = mix(c, vec3(0.08, 0.04, 0.1), 0.85 * seal_marks);
		}
	}
	ALBEDO = mix(c, vec3(1.0), hit_flash);
	ROUGHNESS = 1.0;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = rim * rim_amount * 0.3 * ALBEDO + vec3(hit_flash) * 0.6;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float t = smoothstep(-0.02, 0.06, ndl);
	if (LIGHT_IS_DIRECTIONAL) {
		vec3 shade = mix(vec3(shade_floor, shade_floor * 1.02, shade_floor * 1.18), vec3(1.0), t * ATTENUATION);
		DIFFUSE_LIGHT += LIGHT_COLOR * shade / PI;
	} else {
		DIFFUSE_LIGHT += LIGHT_COLOR * (0.35 + 0.65 * t) * ATTENUATION / PI;
	}
}
