// Anime (cel) enerji kütlesi: kademeli renk bantları, dönen akış gürültüsü, yumuşak kenar.
// Storm tarzı jutsu çekirdekleri: ateş topu, su ejderhası, rasengan, chidori...
shader_type spatial;
render_mode unshaded, blend_mix, cull_back, depth_draw_opaque, shadows_disabled;

uniform vec4 core : source_color = vec4(1.0, 0.95, 0.6, 1.0);
uniform vec4 mid : source_color = vec4(1.0, 0.55, 0.1, 1.0);
uniform vec4 edge : source_color = vec4(0.8, 0.15, 0.05, 1.0);
uniform float swirl = 3.0;
uniform float noise_scale = 3.0;
uniform float flow = 0.0;
uniform float bright = 1.6;
uniform float alpha = 1.0;

float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float vn(vec3 p) {
	vec3 i = floor(p), f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), u.x), mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), u.x), u.y),
	           mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), u.x), mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), u.x), u.y), u.z);
}

varying vec3 lpos;
void vertex() {
	lpos = VERTEX;
	// hafif dalgalanma
	float w = sin(TIME * 9.0 + VERTEX.y * 12.0 + VERTEX.x * 7.0) * 0.03;
	VERTEX += NORMAL * w;
}

void fragment() {
	float fres = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	vec3 p = lpos * noise_scale;
	float a = TIME * swirl;
	p.xz = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * p.xz;
	p.y -= TIME * flow;
	float n = vn(p) * 0.65 + vn(p * 2.7 + TIME * 1.3) * 0.35;
	float v = fres * 0.85 + (n - 0.5) * 0.6;
	vec3 col;
	if (v < 0.35) col = core.rgb;
	else if (v < 0.62) col = mid.rgb;
	else col = edge.rgb;
	ALBEDO = col * bright;
	ALPHA = alpha * (1.0 - smoothstep(0.8, 1.0, fres + (n - 0.5) * 0.3));
}
