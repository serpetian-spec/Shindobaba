// Ahşap pano: yatay tahtalar, damar, derz çizgileri
shader_type canvas_item;
uniform vec4 wood : source_color = vec4(0.36, 0.23, 0.14, 1.0);
uniform float planks = 7.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void fragment() {
	float row = floor(UV.y * planks);
	float fy = fract(UV.y * planks);
	float grain = vnoise(vec2(UV.x * 3.0 + row * 13.0, fy * 18.0 + row)) * 0.5 + vnoise(vec2(UV.x * 40.0 + row * 7.0, fy * 2.0)) * 0.5;
	vec3 c = wood.rgb * (0.78 + grain * 0.38) * (0.92 + hash(vec2(row, 3.0)) * 0.16);
	c *= mix(0.55, 1.0, smoothstep(0.0, 0.06, fy) * smoothstep(1.0, 0.94, fy));
	vec2 q = UV - 0.5;
	c *= 1.0 - smoothstep(0.3, 0.75, length(q)) * 0.45;
	COLOR = vec4(c, 1.0);
}
