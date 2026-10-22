// Karakter + bina toon shader'ı: 2 bantlı anime gölge, kenar ışığı, vertex renkleri
shader_type spatial;
render_mode cull_back, diffuse_toon, specular_toon;

uniform vec4 tint : source_color = vec4(1.0);
uniform bool use_vertex_color = true;
uniform sampler2D tex : source_color, filter_linear_mipmap, hint_default_white;
uniform float rim_amount = 0.35;
uniform float spec_amount = 0.0;
uniform vec4 emission_color : source_color = vec4(0.0);
uniform float hit_flash = 0.0;
uniform float detail_noise = 0.0;
uniform float sway = 0.0;
uniform bool cloth_mode = false;
uniform bool hide_masked = false;  // vertex alfa=1 olan bölgeler çizilmez (kıyafet altı)   // doku (ten) + vertex rengi (kıyafet, alfa = maske)
uniform bool palette_mode = false;  // vertex COLOR.r = renk yuvası*0.1 (0 = ten dokusu)
uniform vec4 pal[8] : source_color;
uniform vec4 rig_a = vec4(0.21, 0.46, 0.7, 1.52);   // üst kol x, dirsek x, el x, boyun y (dinlenme pozu)
uniform vec4 rig_b = vec4(0.95, 0.54, 0.09, 1.31);  // kalça y, diz y, ayak bileği y, üst göğüs y
uniform int top_style = 1;    // 0 tişört, 1 uzun kollu, 2 ceket, 3 yüksek yakalı
uniform int pants_style = 0;  // 0 ninja pantolonu, 1 şort, 2 sivil uzun pantolon
uniform int layer = 0;        // 0 vücut, 1 kumaş kabuğu, 2 yelek
uniform vec4 face_a = vec4(0.0);   // çene genişliği, çene ucu, elmacık, burun (metre)
uniform vec4 face_b = vec4(0.0);   // kaş çıkıntısı, işaret türü (0 yok, 1 burun yarası, 2 yanak çizgisi, 3 çil, 4 kırışık), -, -
uniform vec4 face_ref = vec4(0.0, 1.7, 0.08, 0.0);  // -, göz y, göz z
uniform float fold_amount = 0.0032;
varying vec3 rest;
uniform bool luma_tint = false;    // saç: doku parlaklığı x tint
uniform bool eye_mode = false;     // göz: iris tint, beyaz korunur
uniform vec4 eye_color : source_color = vec4(0.3, 0.5, 0.9, 1.0);

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
		float s = sin(TIME * 1.6 + w.x * 0.13 + w.z * 0.09) * sway * k * 0.02;
		VERTEX.x += s;
		VERTEX.z += s * 0.7;
	}
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	rest = CUSTOM0.xyz;
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
	float ax = abs(p.x);
	bool arm = ax > rig_a.x * 0.9 && p.y > rig_a.w - 0.32;
	if (arm) {
		if (ax > rig_a.z - 0.035) return 0;
		float sleeve = top_style == 0 || top_style == 3 ? mix(rig_a.x, rig_a.y, 0.5) : rig_a.z - 0.035;
		if (ax < sleeve) return (top_style == 2 && ax < rig_a.x + 0.07) ? 2 : 1;
		if (top_style == 3 && ax > rig_a.y - 0.02) return 4;
		return 0;
	}
	if (p.y > rig_a.w) {
		bool collar = (top_style == 2 || top_style == 3) && p.y < rig_a.w + 0.075;
		return collar ? (top_style == 2 ? 2 : 1) : 0;
	}
	float waist = rig_b.x + 0.035;
	if (p.y > waist) {
		if (top_style == 2 && p.y > rig_a.w - 0.1) return 2;
		return 1;
	}
	if (p.y < rig_b.z + 0.03) return 0;
	float cut = pants_style == 0 ? rig_b.y - 0.17 : (pants_style == 1 ? rig_b.y - 0.05 : rig_b.z + 0.04);
	if (p.y > cut) return 3;
	float wrap_top = pants_style == 0 ? cut + 0.02 : rig_b.y - 0.16;
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
	}
	if (hide_masked && COLOR.a > 0.5) discard;
	if (palette_mode) {
		int slot = cloth_slot(rest);
		if (layer == 2) {
			if (rest.y < rig_b.x + 0.03 || rest.y > rig_a.w - 0.01 || abs(rest.x) > rig_a.x * 1.08) discard;
			slot = 5;
		} else if (layer == 1 && slot == 0) discard;
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
			c.rgb = pal[slot].rgb * (0.94 + n * 0.12);
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
	ALBEDO = mix(c.rgb, vec3(1.0), hit_flash);
	ROUGHNESS = 0.8;
	EMISSION = emission_color.rgb * emission_color.a + vec3(hit_flash) * 0.6;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION += rim * rim_amount * 0.35 * ALBEDO;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float t = smoothstep(-0.03, 0.05, ndl) * 0.6 + smoothstep(0.42, 0.5, ndl) * 0.4;
	float lit = t * ATTENUATION;
	// anime gölgesi: tamamen kararmaz, hafif soğuk tonlu
	vec3 shade = mix(vec3(0.42, 0.44, 0.55), vec3(1.0), lit);
	DIFFUSE_LIGHT += LIGHT_COLOR * shade / PI;
	if (spec_amount > 0.0) {
		vec3 h = normalize(LIGHT + VIEW);
		float s = smoothstep(0.93, 0.96, dot(NORMAL, h));
		SPECULAR_LIGHT += LIGHT_COLOR * s * spec_amount * ATTENUATION;
	}
}
