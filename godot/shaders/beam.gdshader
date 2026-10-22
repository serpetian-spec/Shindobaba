// Görev hedefi ışık sütunu: yumuşak kenarlı, yukarı doğru sönen, toplamalı
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 col : source_color = vec4(1.0, 0.72, 0.18, 1.0);
uniform float fade = 1.0;
varying float t;

void vertex() {
	t = VERTEX.y / 260.0 + 0.5;  // 0 taban, 1 tepe
}

void fragment() {
	float edge = pow(clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.0);
	float vert = (1.0 - t) * (1.0 - t) * smoothstep(0.0, 0.01, t);
	float pulse = 0.85 + 0.15 * sin(TIME * 2.5 - t * 40.0);
	ALBEDO = col.rgb * edge * vert * pulse * 0.9 * fade;
}
