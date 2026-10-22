// Mangekyō desen düzenleyici için 2B önizleme
shader_type canvas_item;
#include "res://shaders/mangekyo.gdshaderinc"
uniform vec4 ms_a = vec4(0.0, 3.0, 1.5, 0.5);
uniform vec4 ms_b = vec4(0.22, 0.0, 0.0, 0.6);
uniform vec4 col : source_color = vec4(0.9, 0.05, 0.06, 1.0);

void fragment() {
	vec2 q = (UV - vec2(0.5)) * 2.0;
	float r = length(q);
	vec3 sclera = vec3(0.97, 0.95, 0.93);
	vec3 c = sclera;
	vec2 iq = q / 0.82;
	float ir = length(iq);
	if (ir < 1.0) {
		c = mix(col.rgb, col.rgb * 0.55, smoothstep(0.55, 1.0, ir));
		if (ms_ink(iq, ms_a, ms_b, TIME) > 0.5) c = vec3(0.02);
		c = mix(c, vec3(0.05, 0.0, 0.0), smoothstep(0.95, 1.0, ir));
	}
	float a = 1.0 - smoothstep(0.97, 1.0, r);
	COLOR = vec4(c, a);
}
