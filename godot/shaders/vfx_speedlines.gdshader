// Ekran kenarlarından merkeze akan anime hız çizgileri (ağır vuruş / atılma anı)
shader_type canvas_item;

uniform float strength = 0.0;
uniform vec4 col : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float density = 90.0;

float hash(float x) { return fract(sin(x * 91.3) * 47453.5453); }

void fragment() {
	vec2 p = (UV - 0.5) * vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	float r = length(p);
	float a = atan(p.y, p.x) / 6.2831 + 0.5;
	float k = floor(a * density);
	float fr = fract(a * density);
	float on = step(0.55, hash(k + floor(TIME * 24.0) * 7.0));
	float w = 0.18 + 0.3 * hash(k * 3.1);
	float line = on * step(abs(fr - 0.5), w * 0.5);
	float inner = 0.28 + 0.12 * hash(k + 11.0) - strength * 0.1;
	float m = line * smoothstep(inner, inner + 0.12, r);
	COLOR = vec4(col.rgb, m * strength * 0.85);
}
