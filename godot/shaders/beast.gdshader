// Kuyruklu canavar / dev çağrı: sert 3 bantlı anime gölgesi, koyu soğuk gölge rengi, ince kenar ışığı,
// yüzey dokusu (kürk fırça izleri / pul / sümük parlaklığı). Peluş yumuşaklığını önler.
shader_type spatial;
render_mode cull_back, diffuse_toon, specular_toon;

uniform int surface = 0;          // 0 kürk, 1 deri/pul, 2 kabuk/zırh, 3 sümük (parlak)
uniform float stroke = 0.35;      // fırça izi gücü
uniform vec4 shadow_tint : source_color = vec4(0.32, 0.26, 0.42, 1.0);
uniform float hit_flash = 0.0;
uniform bool use_tint = false;   // hazır modeller: vertex rengi yerine malzeme rengi
uniform vec4 tint : source_color = vec4(1.0);
uniform bool tex_luma = false;   // dokunun sadece parlaklığı (yeniden renklendirme)
uniform bool use_tex = false;    // hazır modelin kendi dokusu (tint ile çarpılır)
uniform sampler2D tex : source_color, filter_linear_mipmap, hint_default_white;

varying vec3 lp;
varying vec3 ln;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void vertex() {
	lp = VERTEX;
	ln = NORMAL;
}

void fragment() {
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
