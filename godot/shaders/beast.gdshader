// Kuyruklu canavar / dev çağrı: sert 3 bantlı anime gölgesi, koyu soğuk gölge rengi, ince kenar ışığı,
// yüzey dokusu (kürk fırça izleri / pul / sümük parlaklığı). Peluş yumuşaklığını önler.
shader_type spatial;
render_mode cull_back, diffuse_toon, specular_toon;

uniform int surface = 0;          // 0 kürk, 1 deri/pul, 2 kabuk/zırh, 3 sümük (parlak)
uniform float stroke = 0.35;      // fırça izi gücü
uniform vec4 shadow_tint : source_color = vec4(0.32, 0.26, 0.42, 1.0);
uniform float hit_flash = 0.0;
uniform float near_fade = 0.0;     // >0: kameraya bu mesafeden yakın yüzeyler noktalı şeffaflaşır (oyuncunun kendi dev formu kamerayı kapatmasın)
uniform bool use_tint = false;   // hazır modeller: vertex rengi yerine malzeme rengi
uniform vec4 tint : source_color = vec4(1.0);
uniform bool tex_luma = false;   // dokunun sadece parlaklığı (yeniden renklendirme)
uniform bool use_tex = false;    // hazır modelin kendi dokusu (tint ile çarpılır)
uniform sampler2D tex : source_color, filter_linear_mipmap, hint_default_white;

// --- hazır (iskeletsiz) hayran modelleri için bölgesel prosedürel deformasyon (SFBeastAnim her kare doldurur)
// Canavar-yerel uzay: taban y=0, ön -Z; bölgeler normalize boy/uzunluğa göre maskelenir.
uniform bool deform = false;
uniform mat4 to_beast = mat4(1.0);     // dünya -> canavar-yerel
uniform mat4 from_beast = mat4(1.0);   // canavar-yerel -> dünya
uniform vec4 dims = vec4(10.0, -5.0, 5.0, 3.0);   // boy H, ön z, arka z, yarı genişlik
uniform vec4 regions = vec4(0.62, 0.28, 0.3, 0.55); // kuyruk başlangıcı (z0..1), ayak boyu (y0..1), baş bitişi (z0..1), baş alt sınırı (y0..1)
uniform float anim_t = 0.0;
uniform float walk = 0.0;            // 0..1 yürüyüş
uniform float coil = 0.0;            // 0..1 sürünen yılan: dururken boyun arkası yere sarmal çöreklenir
uniform float gait = 0.0;            // yürüyüş evresi (radyan)
uniform float tail_amp = 0.06;       // kuyruk dalga genliği (H oranı)
uniform float tail_sweep = 0.0;      // kuyruk süpürmesi (-1..1)
uniform vec2 head_rot = vec2(0.0);   // baş: x eğim, y sapma (radyan)
uniform float roar = 0.0;            // kükreme titremesi 0..1
uniform float breath = 0.0;          // nefes (göğüs şişmesi)
uniform vec2 swipe = vec2(0.0);      // pençe: (taraf -1/1, miktar 0..1)
// yılanlar: 0 canavar, 1 çöreklenmiş dev yılan (boyun/baş salınır, halkalar dalgalanır), 2 sürünen yılan (yanal sinüs dalgası)
uniform int deform_mode = 0;
uniform vec3 pivot = vec3(0.0);      // çöreklenmiş yılan: boyun dönme noktası (canavar-yerel)
uniform float strike = 0.0;          // ısırma atılışı 0..1
uniform float wave_speed = 1.5;

varying vec3 lp;
varying vec3 ln;

vec3 rot_y(vec3 v, float a) { float c = cos(a), s = sin(a); return vec3(c * v.x + s * v.z, v.y, -s * v.x + c * v.z); }
vec3 rot_x(vec3 v, float a) { float c = cos(a), s = sin(a); return vec3(v.x, c * v.y - s * v.z, s * v.y + c * v.z); }

vec3 deform_pt(vec3 b) {
	float H = dims.x;
	float zn = clamp((b.z - dims.y) / max(0.001, dims.z - dims.y), 0.0, 1.0);   // 0 ön, 1 arka
	float yn = b.y / H;
	float xn = b.x / max(0.001, dims.w);
	// kuyruklar: gövdeden uzaklaştıkça artan, her kuyruğa ayrı evreli dalga
	float tm = smoothstep(regions.x, regions.x + 0.12, zn);
	float d = clamp((zn - regions.x) / max(0.001, 1.0 - regions.x), 0.0, 1.0);
	float ang = atan(b.x, b.y - H * 0.35);
	float dd = d * d;
	b.x += (sin(anim_t * 1.7 - d * 3.2 + ang * 3.0) * tail_amp + tail_sweep * 0.45 * d) * H * dd * tm;
	b.y += cos(anim_t * 1.25 - d * 2.6 + ang * 2.2) * tail_amp * 0.65 * H * dd * tm;
	// göğüs nefesi
	float cm = (1.0 - tm) * smoothstep(0.2, 0.4, yn) * (1.0 - smoothstep(0.7, 0.9, yn)) * (1.0 - smoothstep(0.35, 0.55, zn));
	b.xz *= 1.0 + breath * cm;
	// bacaklar: alt bölge, taraf ve ön/arka evre farkıyla adım
	float lm = (1.0 - smoothstep(regions.y * 0.55, regions.y, yn)) * (1.0 - tm);
	float side = xn >= 0.0 ? 0.0 : 3.14159;
	float fb = zn < 0.5 ? 3.14159 : 0.0;
	float ph = gait + side + fb;
	float lift = (1.0 - yn / max(0.001, regions.y));
	b.z += sin(ph) * 0.07 * H * walk * lm * lift;
	b.y += max(0.0, cos(ph)) * 0.05 * H * walk * lm * lift;
	// kollar / pençe savurma: yan-ön-orta bölge
	float am = smoothstep(0.35, 0.6, abs(xn)) * smoothstep(0.3, 0.45, yn) * (1.0 - smoothstep(0.7, 0.85, yn)) * (1.0 - smoothstep(0.35, 0.6, zn)) * (1.0 - tm);
	float sw = swipe.y * step(0.0, swipe.x * xn);
	b.z -= sw * 0.18 * H * am;
	b.y += sw * 0.08 * H * am;
	b.x -= sign(xn) * sw * 0.08 * H * am;
	// baş: boyun pivotu etrafında eğim/sapma + kükreme titremesi
	float hm = (1.0 - smoothstep(regions.z - 0.08, regions.z + 0.08, zn)) * smoothstep(regions.w - 0.1, regions.w + 0.05, yn) * (1.0 - tm);
	vec3 piv = vec3(0.0, H * regions.w, dims.y + (dims.z - dims.y) * (regions.z + 0.05));
	vec3 r = rot_x(rot_y(b - piv, head_rot.y), head_rot.x) + piv;
	b = mix(b, r, hm);
	b += vec3(sin(anim_t * 47.0), cos(anim_t * 39.0), sin(anim_t * 53.0)) * roar * 0.004 * H * hm;
	return b;
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

vec3 deform_coil(vec3 b) {
	float H = dims.x;
	float yn = b.y / H;
	float hm = smoothstep(0.32, 0.62, yn);              // yükselen boyun + baş
	float ang = atan(b.x, b.z);
	float act = 1.0 + walk * 2.5;
	b.y += sin(anim_t * 2.2 * act + ang * 3.0) * 0.014 * H * (1.0 - hm);   // halkalarda dalga
	b.xz *= 1.0 + sin(anim_t * 1.6 + ang * 2.0) * 0.012 * (1.0 - hm);
	vec3 r = b - pivot;
	r = rot_y(r, head_rot.y * hm);
	r = rot_x(r, (head_rot.x - strike * 0.55) * hm);
	b = pivot + r;
	b.z -= strike * 0.22 * H * hm * hm;
	b.x += sin(anim_t * 1.1) * 0.03 * H * hm * hm;     // baş sallanması
	return b;
}

vec3 deform_slither(vec3 b) {
	float H = dims.x;
	float L = max(0.001, dims.z - dims.y);
	float zn = clamp((b.z - dims.y) / L, 0.0, 1.0);
	float body = smoothstep(0.06, 0.3, zn);
	b.x += sin(anim_t * wave_speed - zn * 9.0) * tail_amp * L * (0.25 + zn) * body;
	b.x += (sin(anim_t * 1.3) * 0.05 * L + head_rot.y * 0.25 * L) * (1.0 - body);
	b.z -= strike * 0.22 * L * (1.0 - body);
	b.y += (strike * 0.08 * L + sin(anim_t * 1.7) * 0.02 * L) * (1.0 - body);
	if (coil > 0.001) {
		// çörek: boyundan sonraki gövde, boynun arkasında yere sarmal halinde dolanır (yarıçap içe daralır, halkalar üst üste biner)
		float s = clamp((zn - 0.2) / 0.8, 0.0, 1.0);
		float R0 = L * 0.12;
		float arc = s * L * 0.8;
		float R = R0 * (1.0 - 0.5 * s);
		float th = arc / max(R0 * (1.0 - 0.25 * s), 0.001);
		vec3 c = vec3(0.0, 0.0, dims.y + 0.2 * L + R0);
		vec3 radial = vec3(sin(th), 0.0, -cos(th));
		vec3 cp = c + radial * (R + b.x) + vec3(0.0, b.y + s * H * 0.7 + sin(anim_t * 0.8 + th) * 0.01 * L, 0.0);
		b = mix(b, cp, coil * smoothstep(0.16, 0.26, zn));
	}
	return b;
}

void vertex() {
	lp = VERTEX;
	ln = NORMAL;
	if (deform) {
		vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		vec3 b = (to_beast * vec4(w, 1.0)).xyz;
		vec3 b2 = deform_mode == 1 ? deform_coil(b) : (deform_mode == 2 ? deform_slither(b) : deform_pt(b));
		vec3 w2 = (from_beast * vec4(b2, 1.0)).xyz;
		VERTEX = (inverse(MODEL_MATRIX) * vec4(w2, 1.0)).xyz;
	}
}

void fragment() {
	if (near_fade > 0.0) {
		float dv = length(VERTEX);
		float k = smoothstep(near_fade * 0.55, near_fade, dv);   // 0 yakın .. 1 uzak
		float dith = fract(dot(FRAGCOORD.xy, vec2(0.0671, 0.00583)) * 52.98);
		if (k < 0.85 && dith > k * 0.9 + 0.1) { discard; }
	}
	vec3 c = COLOR.rgb;
	c = mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));  // sRGB -> lineer
	if (use_tint) c = tint.rgb;
	if (use_tex) { vec3 tx = texture(tex, UV).rgb; c = tex_luma ? tint.rgb * (0.55 + 0.6 * dot(tx, vec3(0.3, 0.59, 0.11))) : tx * tint.rgb; }
	vec3 an = abs(normalize(ln));
	if (surface == 0) {
		// kürk: normal yönüne göre uzayan fırça çizgileri (keskin, koyu)
		vec2 uv = an.x > an.z ? lp.zy : lp.xy;
		float s = vnoise(vec2(uv.x * 6.0, uv.y * 1.2)) * 0.6 + vnoise(vec2(uv.x * 14.0, uv.y * 2.5)) * 0.4;
		c *= 1.0 - stroke * 0.55 * smoothstep(0.55, 0.8, s);
	} else if (surface == 1) {
		float s = vnoise(lp.xz * 4.0 + lp.y * 2.0);
		c *= 1.0 - stroke * 0.35 * smoothstep(0.5, 0.75, s);
	} else if (surface == 2) {
		float cr = vnoise(lp.xz * 2.2 + lp.y * 1.5);
		c *= 1.0 - stroke * 0.5 * smoothstep(0.62, 0.66, cr);
	}
	ALBEDO = mix(c, vec3(1.0), hit_flash);
	ROUGHNESS = surface == 3 ? 0.25 : 0.9;
	EMISSION = vec3(hit_flash) * 0.6;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	// sert 3 bant: tam ışık / orta / koyu gölge
	float b1 = step(0.0, ndl);
	float b2 = step(0.45, ndl);
	float lit = (0.0 + b1 * 0.55 + b2 * 0.45) * ATTENUATION;
	vec3 shade = mix(shadow_tint.rgb * 0.75, vec3(1.0), lit);
	if (LIGHT_IS_DIRECTIONAL) {
		DIFFUSE_LIGHT += LIGHT_COLOR * shade / PI;
		// ince, keskin kenar ışığı (siluet)
		float rim = step(0.78, 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0)) * step(0.0, ndl);
		DIFFUSE_LIGHT += LIGHT_COLOR * rim * 0.35 / PI;
		if (surface == 3 || surface == 2) {
			vec3 h = normalize(LIGHT + VIEW);
			float sp = step(surface == 3 ? 0.975 : 0.997, dot(NORMAL, h));
			SPECULAR_LIGHT += LIGHT_COLOR * sp * (surface == 3 ? 0.5 : 0.15);
		}
	} else {
		DIFFUSE_LIGHT += LIGHT_COLOR * lit * 0.5 / PI;
	}
}
