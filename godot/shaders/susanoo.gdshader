// Susanoo: yarı saydam, kenarları parlayan, içinde alev gibi akan chakra
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;   // yarı saydam karışım: parlak gökyüzünde de rengi okunur (toplamalı karışım beyaza doyuyordu)

uniform vec4 col : source_color = vec4(0.55, 0.35, 1.0, 1.0);
uniform vec4 rim_col : source_color = vec4(0.55, 0.35, 1.0, 1.0);   // kenar rengi (iki tonlu Susanoo)
uniform float density = 1.0;     // iç dolgu yoğunluğu (0.3 hayalet .. 2 dolu)
uniform float glow = 1.0;        // kenar parlaklığı
uniform float flow_speed = 1.0;  // içindeki chakra alevinin akış hızı
uniform float ground_y = -100000.0;   // yere gömülü kademeler: zemin altı (bacaklar, ayaklar) çizilmez
uniform float cut_y = 0.0;   // >0: dinlenme pozunda bu yüksekliğin altı çizilmez (üst gövde kademesi)

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

varying vec3 wp;
varying vec3 rest;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	rest = CUSTOM0.xyz;
}

void fragment() {
	if (cut_y > 0.0 && rest.y > 0.0001 && rest.y < cut_y) discard;
	if (wp.y < ground_y) discard;
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.2);
	float tt = TIME * flow_speed;
	float flow = vnoise(wp.xz * 0.6 + vec2(0.0, -tt * 1.4) + wp.y * 0.4) * 0.6 + vnoise(wp.xy * 1.7 - vec2(tt * 0.8, tt * 2.0)) * 0.4;
	// iç çizgiler: akan gürültünün eş-yükselti eğrileri (animedeki Susanoo çizgi işçiliği)
	float n2 = vnoise(wp.xy * 0.9 + vec2(wp.z * 0.7, -tt * 0.6)) * 0.6 + vnoise(wp.zy * 1.9 + vec2(tt * 0.3, -tt * 1.1)) * 0.4;
	float lines = 1.0 - smoothstep(0.0, 0.07, abs(fract(n2 * 6.0) - 0.5) * 2.0 - 0.86);
	lines = clamp(1.0 - smoothstep(0.02, 0.09, abs(fract(n2 * 6.0) - 0.5)), 0.0, 1.0);
	float flick = 0.85 + 0.15 * sin(tt * 9.0 + wp.y * 2.0);
	// katmanlar (gövde + zırh kabukları) toplamalı karışımda beyaza doymasın: iç dolgu düşük, kontur ve çizgiler belirgin
	float a = (0.05 + flow * 0.08) * density + rim * 0.42 * glow + lines * 0.22 * glow;
	vec3 base = mix(col.rgb, rim_col.rgb, clamp(rim * 1.3 + lines * 0.5, 0.0, 1.0));
	ALBEDO = base * (0.75 + rim * 0.9 * glow + flow * 0.25 + lines * 0.55) * flick;
	ALPHA = clamp(a * 1.5, 0.0, 0.8);
}
