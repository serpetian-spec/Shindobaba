// Küçük harita zemini: arazi rengi + yükseklik gölgesi + su (RoadMap'in tepeden kamerası bunu çizer)
shader_type spatial;
render_mode unshaded, cull_disabled;

#include "res://shaders/world_height.gdshaderinc"

uniform sampler2D albedo_map : source_color, filter_linear, repeat_disable;
uniform vec2 center;

void fragment() {
	vec3 w = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 xz = w.xz;
	vec2 uv = (xz - world_rect.xy) / world_rect.zw;
	vec3 c = texture(albedo_map, uv).rgb;
	float h = world_height(xz);
	float hx = world_height(xz + vec2(6.0, 0.0)) - h;
	float hz = world_height(xz + vec2(0.0, 6.0)) - h;
	float shade = clamp(1.0 + (hz - hx) * 0.12, 0.6, 1.35);
	c *= shade;
	if (h < 0.0) c = mix(vec3(0.35, 0.62, 0.85), vec3(0.15, 0.35, 0.6), clamp(-h / 40.0, 0.0, 1.0));
	// kağıt tonu
	c = mix(c, vec3(0.94, 0.9, 0.8), 0.12);
	ALBEDO = c;
}
