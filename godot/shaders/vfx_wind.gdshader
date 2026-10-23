// Rüzgar kütlesi: arkasını kıran saydam hava (ekran dokusu kırılması) + dönen beyaz hız çizgileri + açık yeşil-beyaz kenar.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, blend_mix;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(0.78, 1.0, 0.9, 1.0);
uniform float speed = 6.0;
uniform float lines = 6.0;
uniform float refract = 0.03;
uniform float alpha = 0.85;
uniform vec3 axis = vec3(0.0, 1.0, 0.0);  // dönme ekseni (nesne uzayı)

varying vec3 lp;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void vertex() { lp = VERTEX; }

void fragment() {
	float fres = 1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0);
	vec3 ax = normalize(axis);
	vec3 side = normalize(abs(ax.y) < 0.9 ? cross(ax, vec3(0, 1, 0)) : cross(ax, vec3(1, 0, 0)));
	vec3 up2 = cross(ax, side);
	float ang = atan(dot(lp, up2), dot(lp, side));
	float h = dot(lp, ax);
	float s = fract(ang / 6.2831 * lines + h * 1.5 - TIME * speed * 0.25);
	float n = vn(vec2(ang * 3.0, h * 4.0 - TIME * speed));
	float streak = step(0.9 - n * 0.1, s) * step(0.35, n);
	vec2 off = vec2(sin(ang * 4.0 + TIME * speed), cos(h * 6.0 - TIME * speed)) * refract * (0.4 + fres);
	vec3 bg = texture(screen_tex, SCREEN_UV + off).rgb;
	vec3 col = mix(bg, bg * 0.85 + tint.rgb * 0.25, 0.6);
	col = mix(col, tint.rgb * 1.25, smoothstep(0.55, 0.9, fres) * 0.6);
	col = mix(col, vec3(1.0), streak * 0.9);
	ALBEDO = col;
	ALPHA = alpha * clamp(0.45 + fres * 0.6 + streak, 0.0, 1.0);
}
