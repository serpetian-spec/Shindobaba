// Kuchiyose çağırma çemberi: merkezden yayılan mürekkep çizgileri, halkalar ve yazı benzeri işaretler
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

uniform vec4 col : source_color = vec4(0.05, 0.04, 0.06, 1.0);
uniform vec4 glow : source_color = vec4(1.0, 0.6, 0.2, 1.0);
uniform float grow = 1.0;
uniform float fade = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 q = (UV - 0.5) * 2.0;
	float r = length(q);
	float a = atan(q.y, q.x);
	if (r > grow) discard;
	float ink = 0.0;
	// iki eş merkezli halka
	ink = max(ink, step(abs(r - 0.92), 0.025));
	ink = max(ink, step(abs(r - 0.62), 0.018));
	// avuçtan yayılan 5 ana çizgi + uçlarında yazı blokları
	for (int i = 0; i < 5; i++) {
		float aa = float(i) * 1.2566 + 0.3;
		vec2 d = vec2(cos(aa), sin(aa));
		float along = dot(q, d);
		float across = abs(dot(q, vec2(-d.y, d.x)));
		if (along > 0.05 && along < 0.95 && across < 0.018 + 0.01 * sin(along * 30.0)) ink = 1.0;
		// çizgi ucunda yazı (rastgele küçük bloklar)
		vec2 cell = floor(vec2(along * 22.0, dot(q, vec2(-d.y, d.x)) * 22.0));
		if (along > 0.66 && along < 0.9 && across < 0.08 && hash(cell + float(i)) > 0.55) ink = 1.0;
	}
	// halkalar arasında yazı şeridi
	float band = step(0.68, r) * step(r, 0.86);
	vec2 cell2 = floor(vec2(a * 14.0, r * 30.0));
	if (band > 0.5 && hash(cell2) > 0.62) ink = 1.0;
	// merkez
	ink = max(ink, step(r, 0.08));
	if (ink < 0.5) discard;
	float edge = smoothstep(grow - 0.1, grow, r);
	ALBEDO = mix(col.rgb, glow.rgb * 1.6, edge);
	ALPHA = (1.0 - fade) * 0.95;
}
