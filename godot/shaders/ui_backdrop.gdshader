// Menü arka planı: oyun ekranını bulanıklaştırır, koyulaştırır, kenarlarda vinyet + çok hafif mürekkep dokusu
shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
uniform float blur = 3.0;
uniform float dim = 0.55;
uniform vec4 tint : source_color = vec4(0.03, 0.035, 0.05, 1.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec3 c = textureLod(screen, SCREEN_UV, blur).rgb * 0.5;
	c += textureLod(screen, SCREEN_UV + vec2(0.004, 0.0), blur).rgb * 0.125;
	c += textureLod(screen, SCREEN_UV - vec2(0.004, 0.0), blur).rgb * 0.125;
	c += textureLod(screen, SCREEN_UV + vec2(0.0, 0.006), blur).rgb * 0.125;
	c += textureLod(screen, SCREEN_UV - vec2(0.0, 0.006), blur).rgb * 0.125;
	float gray = dot(c, vec3(0.3, 0.59, 0.11));
	c = mix(c, vec3(gray), 0.35);
	c = mix(c, tint.rgb, dim);
	vec2 q = UV - 0.5;
	float vig = smoothstep(0.35, 0.85, length(q * vec2(1.2, 1.0)));
	c *= 1.0 - vig * 0.55;
	c += (hash(floor(FRAGCOORD.xy * 0.5)) - 0.5) * 0.012;
	COLOR = vec4(c, 1.0);
}
