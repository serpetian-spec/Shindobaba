shader_type spatial;
// Samehada Yūgō köpekbalığı derisi (referans: gri-mavi ten, sırttan yanlara inen koyu çizgiler). Giysinin üstüne katman;
// yalnız bel üstü (model uzayında waist_y'den yukarısı) — pantolon değişmez.
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 skin : source_color = vec4(0.58, 0.64, 0.74, 1.0);
uniform vec4 stripe : source_color = vec4(0.28, 0.33, 0.43, 1.0);
uniform float waist_y = 0.95;
uniform float grow = 1.0;

varying vec3 mp;

void vertex() {
	mp = VERTEX;
}

void fragment() {
	float above = smoothstep(waist_y - 0.02, waist_y + 0.02, mp.y);
	// çizgiler: yanlara doğru aşağı inen V biçimli koyu şeritler
	float band = fract(mp.y * 11.0 + abs(mp.x) * 7.0);
	float s = smoothstep(0.62, 0.7, band) * (1.0 - smoothstep(0.85, 0.93, band));
	ALBEDO = mix(skin.rgb, stripe.rgb, s);
	ROUGHNESS = 0.6;
	ALPHA = above * grow;
}
