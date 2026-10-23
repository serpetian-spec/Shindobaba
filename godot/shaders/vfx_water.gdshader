// Anime su kütlesi (ejderha, köpekbalığı, dalga, kalkan): koyu→açık mavi bantlar, akış çizgileri,
// köpük tepeleri, fresnel parıltısı, sert parlama şeridi. Yarı saydam.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque, shadows_disabled, blend_mix;

uniform vec4 c_deep : source_color = vec4(0.05, 0.28, 0.78, 1.0);
uniform vec4 c_mid : source_color = vec4(0.2, 0.55, 0.98, 1.0);
uniform vec4 c_light : source_color = vec4(0.62, 0.88, 1.0, 1.0);
uniform vec4 c_foam : source_color = vec4(0.97, 0.99, 1.0, 1.0);
uniform float speed = 2.5;
uniform float scale = 2.0;
uniform vec3 flow = vec3(0.0, 0.0, 1.0);
uniform float alpha = 0.88;
uniform float foam = 0.5;
uniform float wobble = 0.06;

varying vec3 lp;

float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float vn(vec3 p) {
	vec3 i = floor(p), f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), u.x), mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), u.x), u.y),
	           mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), u.x), mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), u.x), u.y), u.z);
}

void vertex() {
	lp = VERTEX;
	VERTEX += NORMAL * (vn(VERTEX * 2.7 + flow * TIME * speed) - 0.5) * wobble * 2.0;
}

void fragment() {
	float fres = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	vec3 p = lp * scale + flow * TIME * speed;
	float n = vn(p) * 0.6 + vn(p * 2.6) * 0.4;
	// akış çizgileri: akış yönüne dik bantlar, gürültüyle kırılmış
	float streak = sin(dot(lp, flow) * 9.0 * scale + TIME * speed * 6.0 + n * 6.0);
	float v = fres * 0.8 + (n - 0.5) * 0.7;
	vec3 col = c_deep.rgb;
	if (v > 0.25) col = c_mid.rgb;
	if (v > 0.55) col = c_light.rgb;
	if (streak > 0.86 && fres < 0.7) col = mix(col, c_light.rgb, 0.8);
	float fm = smoothstep(0.62, 0.7, n + fres * 0.35 * foam);
	if (fm > 0.5 && foam > 0.0) col = c_foam.rgb;
	// sert parlama şeridi (üst-sol)
	vec3 h = normalize(vec3(-0.4, 0.8, 0.45));
	if (dot(NORMAL, (VIEW_MATRIX * vec4(h, 0.0)).xyz) > 0.86) col = c_foam.rgb;
	ALBEDO = col * 1.1;
	ALPHA = clamp(alpha + fres * 0.15 + fm * 0.3, 0.0, 1.0);
}
