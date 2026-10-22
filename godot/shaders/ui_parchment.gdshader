// Parşömen kâğıdı: lif dokusu, lekeler, koyulaşan kenarlar, isteğe bağlı yanık kenar
shader_type canvas_item;
uniform vec4 paper : source_color = vec4(0.93, 0.86, 0.7, 1.0);
uniform float edge = 0.12;
uniform float seed = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void fragment() {
	vec2 uv = UV;
	vec2 px = uv * vec2(1.0 / max(TEXTURE_PIXEL_SIZE.x, 0.0001), 1.0 / max(TEXTURE_PIXEL_SIZE.y, 0.0001));
	float n = vnoise(uv * 6.0 + seed) * 0.6 + vnoise(uv * 23.0 + seed * 3.0) * 0.3 + vnoise(vec2(uv.x * 2.0, uv.y * 140.0) + seed) * 0.1;
	vec3 c = paper.rgb * (0.9 + n * 0.16);
	float stain = smoothstep(0.62, 0.8, vnoise(uv * 3.5 + seed * 7.0));
	c = mix(c, c * vec3(0.86, 0.76, 0.6), stain * 0.35);
	vec2 d = min(uv, 1.0 - uv);
	float e = min(d.x, d.y);
	float ragged = edge * (0.7 + 0.6 * vnoise(uv * 30.0 + seed));
	c *= mix(0.68, 1.0, smoothstep(0.0, ragged, e));
	float alpha = smoothstep(0.0, 0.012, e - 0.004 * vnoise(uv * 60.0 + seed));
	COLOR = vec4(c, alpha * COLOR.a);
}
