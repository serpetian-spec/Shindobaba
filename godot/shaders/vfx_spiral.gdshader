// Rasengan / chakra küresi kabuğu: eksen etrafında dönen spiral çizgiler, sert parlak bantlar, fresnel kenar.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, shadows_disabled, blend_add;

uniform vec4 c_line : source_color = vec4(0.85, 0.95, 1.0, 1.0);
uniform vec4 c_body : source_color = vec4(0.2, 0.5, 1.0, 1.0);
uniform float arms = 5.0;
uniform float twist = 3.0;
uniform float speed = 6.0;
uniform float intensity = 1.6;
uniform vec3 axis = vec3(0.0, 1.0, 0.0);

varying vec3 lp;
void vertex() { lp = normalize(VERTEX); }

void fragment() {
	float fres = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	vec3 ax = normalize(axis);
	vec3 side = normalize(abs(ax.y) < 0.9 ? cross(ax, vec3(0, 1, 0)) : cross(ax, vec3(1, 0, 0)));
	vec3 up2 = cross(ax, side);
	float ang = atan(dot(lp, up2), dot(lp, side));
	float h = dot(lp, ax);
	float s = fract(ang / 6.2831 * arms + h * twist - TIME * speed);
	float line = 1.0 - smoothstep(0.08, 0.16, abs(s - 0.5));
	vec3 c = c_body.rgb * (0.25 + fres * 0.9) + c_line.rgb * line * (0.6 + fres);
	c += c_line.rgb * smoothstep(0.75, 0.95, fres) * 0.8;
	ALBEDO = c * intensity;
}
