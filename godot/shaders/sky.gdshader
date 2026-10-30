// Anime gökyüzü: degrade, güneş/ay, yıldızlar, katmanlı bulutlar
shader_type sky;

uniform vec3 zenith : source_color = vec3(0.24, 0.52, 0.92);
uniform vec3 horizon : source_color = vec3(0.70, 0.84, 0.97);
uniform vec3 sun_tint : source_color = vec3(1.0, 0.95, 0.85);
uniform float night = 0.0;
uniform float clouds = 0.55;
uniform float overcast = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float hash3(vec3 p) { p = fract(p * 0.3183099 + 0.1); p *= 17.0; return fract(p.x * p.y * p.z * (p.x + p.y + p.z)); }
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
	if (night > 0.01 && d.y > -0.02) {
		// yıldızlar: 3B hücrelerde rastgele konumlu noktalar (düzlem ızgarası sıra sıra diziyordu)
		float stars = 0.0;
		for (int L = 0; L < 2; L++) {
			float sc = L == 0 ? 160.0 : 70.0;
			vec3 p = d * sc;
			vec3 cell = floor(p);
			float h = hash3(cell);
			float on = step(L == 0 ? 0.86 : 0.93, h);
			vec3 sp = cell + 0.2 + 0.6 * vec3(hash3(cell + 11.1), hash3(cell + 23.7), hash3(cell + 37.3));
			float r = length(p - sp);
			float size = L == 0 ? 0.09 : 0.13 + hash3(cell + 5.0) * 0.08;
			float tw = 0.6 + 0.4 * sin(TIME * (1.5 + h * 3.0) + h * 40.0);
			stars += on * (1.0 - smoothstep(size * 0.3, size, r)) * tw * (L == 0 ? 0.55 : 1.0);
		}
		// samanyolu: hafif, eğik bir ışık kuşağı
		float band = exp(-pow(dot(d, normalize(vec3(0.5, 0.3, 0.8))) / 0.22, 2.0)) * (0.5 + 0.5 * fbm(d.xz * 6.0 / (abs(d.y) + 0.3)));
		col += (vec3(0.85, 0.9, 1.0) * stars + vec3(0.25, 0.28, 0.4) * band * 0.35) * night * smoothstep(-0.02, 0.18, d.y) * (1.0 - overcast);
	}
	if (d.y > 0.0) {
		vec2 cp = d.xz / (d.y + 0.12) * 0.9 + vec2(TIME * 0.008, TIME * 0.003);
		float cov = clamp(clouds + overcast * 0.5, 0.0, 1.0);
		// yüksek ince bulut tülü (cirrus): uzun çekilmiş, saydam
		vec2 hp = d.xz / (d.y + 0.05) * vec2(0.35, 1.2) + vec2(TIME * 0.004, 0.0);
		float ci = smoothstep(0.55, 0.85, fbm(hp)) * 0.35 * (1.0 - overcast);
		col = mix(col, mix(vec3(1.0), sun_tint, 0.3) * (0.4 + 0.6 * (1.0 - night)), ci * smoothstep(0.05, 0.3, d.y));
		// kabarık kümülüs: yoğunluk + güneşe doğru kaydırılmış örnekle cel gölge (üst aydınlık, alt koyu, kenarda parlak hat)
		vec2 warp = vec2(fbm(cp * 0.7 + 3.1), fbm(cp * 0.7 - 5.3)) - 0.5;
		vec2 q = cp + warp * 1.2;
		float c = fbm(q);
		vec2 toward = normalize(sd.xz + vec2(0.0001)) * 0.06;
		float c2 = fbm(q + toward);
		float dens = smoothstep(0.55 - cov * 0.3, 0.74 - cov * 0.15, c);
		float lit = clamp(0.5 + (c - c2) * 9.0, 0.0, 1.0);
		lit = smoothstep(0.3, 0.42, lit) * 0.55 + smoothstep(0.6, 0.72, lit) * 0.45;   // anime: üç ton
		vec3 shade = mix(vec3(0.62, 0.68, 0.84), horizon, 0.35);
		vec3 bright = mix(vec3(1.0), sun_tint, 0.25);
		vec3 cc = mix(shade, bright, lit);
		float rim = smoothstep(0.0, 0.25, dens) - smoothstep(0.25, 0.6, dens);
		cc += sun_tint * (pow(s, 5.0) * 0.5 + rim * pow(s, 2.0) * 0.35) * (1.0 - night);
		cc *= (0.3 + 0.7 * (1.0 - night)) * (1.0 - overcast * 0.4);
		col = mix(col, cc, dens * smoothstep(0.0, 0.12, d.y) * 0.97 * (1.0 - night * 0.75 * (1.0 - overcast)));   // gece bulut saydam: yıldızlar görünsün
		col = mix(col, vec3(dot(col, vec3(0.33))) * 0.8, overcast * 0.6);
	}
	COLOR = col;
}
