// Tsukuyomi dünyası (anime): renkler tersine döner — gökyüzü kan kızılı, gölgeler ve figürler kapkara ya da beyaz kontur;
// ortada kara ay. Ekranın tamamına binen CanvasLayer dikdörtgeni (amount 0..1 geçiş).
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float amount = 1.0;
uniform vec4 red : source_color = vec4(0.62, 0.02, 0.04, 1.0);
uniform vec2 moon = vec2(0.5, 0.26);
uniform float moon_r = 0.11;

void fragment() {
	vec3 src = texture(screen_tex, SCREEN_UV).rgb;
	float lum = dot(src, vec3(0.299, 0.587, 0.114));
	// negatif: aydınlık yerler kızıla, karanlık yerler karaya; kenarlar (parlaklık değişimi) beyaz çizgi
	float inv = 1.0 - lum;
	vec3 col = mix(vec3(0.0), red.rgb, smoothstep(0.15, 0.85, lum));
	col = mix(col, vec3(0.0), smoothstep(0.55, 0.95, inv) * 0.85);
	vec2 px = vec2(1.5) / vec2(textureSize(screen_tex, 0));
	float e = abs(dot(texture(screen_tex, SCREEN_UV + vec2(px.x, 0.0)).rgb - src, vec3(0.333))) + abs(dot(texture(screen_tex, SCREEN_UV + vec2(0.0, px.y)).rgb - src, vec3(0.333)));
	col = mix(col, vec3(0.95, 0.9, 0.9), smoothstep(0.08, 0.25, e) * 0.7);
	// kara ay: ince kızıl hale
	vec2 asp = vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	float d = length((SCREEN_UV - moon) * asp);
	col = mix(col, vec3(0.0), 1.0 - smoothstep(moon_r - 0.004, moon_r, d));
	col += red.rgb * 0.6 * (1.0 - smoothstep(moon_r, moon_r + 0.03, d)) * step(moon_r, d);
	// köşeler kararır
	float vig = smoothstep(0.95, 0.35, length(SCREEN_UV - 0.5) * 1.3);
	col *= mix(0.55, 1.0, vig);
	COLOR = vec4(col, amount);
}
