// Anime gökyüzü: degrade, güneş/ay, yıldızlar, katmanlı bulutlar
shader_type sky;

uniform vec3 zenith : source_color = vec3(0.24, 0.52, 0.92);
uniform vec3 horizon : source_color = vec3(0.70, 0.84, 0.97);
uniform vec3 sun_tint : source_color = vec3(1.0, 0.95, 0.85);
uniform float night = 0.0;
uniform float clouds = 0.55;
uniform float overcast = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
// gradyan gürültü (değer gürültüsü bulutlarda köşeli kenar yapıyordu)
vec2 grad2(vec2 p) { float a = hash(p) * 6.2831853; return vec2(cos(a), sin(a)); }
float gnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	float a = dot(grad2(i), f), b = dot(grad2(i + vec2(1, 0)), f - vec2(1, 0));
	float c = dot(grad2(i + vec2(0, 1)), f - vec2(0, 1)), d = dot(grad2(i + vec2(1, 1)), f - vec2(1, 1));
	return 0.5 + 0.7 * mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
float fbm(vec2 p) {
	float s = 0.0, a = 0.5;
	mat2 r = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));  // her oktavda döndür: ızgara izi kalmasın
	for (int i = 0; i < 6; i++) { s += gnoise(p) * a; p = r * p * 2.03 + vec2(1.7, 9.2); a *= 0.5; }
	return s;
}

void sky() {
	vec3 d = EYEDIR;
	float y = max(d.y, -0.1);
	vec3 col = mix(horizon, zenith, pow(clamp(y, 0.0, 1.0), 0.5));
	col = mix(col, horizon * 0.85, smoothstep(0.0, -0.1, d.y));
	vec3 sd = LIGHT0_DIRECTION;
	float s = max(dot(d, sd), 0.0);
	col += sun_tint * (pow(s, 1200.0) * 8.0 + pow(s, 14.0) * 0.28) * (1.0 - night);
	float m = max(dot(d, -sd), 0.0);
	col += vec3(0.9, 0.95, 1.0) * (pow(m, 2500.0) * 6.0 + pow(m, 30.0) * 0.12) * night;
	if (night > 0.01 && d.y > 0.0) {
		vec2 sp = d.xz / (d.y + 0.25) * 260.0;
		float st = step(0.996, hash(floor(sp)));
		col += st * night * (0.55 + 0.45 * sin(TIME * 2.5 + hash(floor(sp)) * 30.0)) * smoothstep(0.0, 0.2, d.y);
	}
	if (d.y > 0.0) {
		vec2 cp = d.xz / (d.y + 0.12) * 0.9 + vec2(TIME * 0.008, TIME * 0.003);
		vec2 warp = vec2(fbm(cp * 0.7 + 3.1), fbm(cp * 0.7 - 5.3)) - 0.5;
		float c = fbm(cp + warp * 1.2);
		float cov = clamp(clouds + overcast * 0.5, 0.0, 1.0);
		c = smoothstep(0.55 - cov * 0.3, 0.78 - cov * 0.15, c);  // yumuşak, kabarık kenar
		float edge = smoothstep(0.0, 0.5, c) - smoothstep(0.5, 1.0, c) * 0.3;
		vec3 cc = mix(vec3(1.0), horizon, 0.25) * (0.35 + 0.65 * (1.0 - night)) * (1.0 - overcast * 0.4);
		cc += sun_tint * pow(s, 6.0) * 0.4 * (1.0 - night);
		col = mix(col, cc, c * smoothstep(0.0, 0.12, d.y) * 0.95);
		col = mix(col, vec3(dot(col, vec3(0.33))) * 0.8, overcast * 0.6);
	}
	COLOR = col;
}
