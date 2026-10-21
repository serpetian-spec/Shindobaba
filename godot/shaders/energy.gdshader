// Enerji küresi/kütlesi: Fresnel parlama + dönen gürültü + HDR (bloom'u tetikler)
shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never;

uniform vec4 core : source_color = vec4(0.8, 0.95, 1.0, 1.0);
uniform vec4 edge : source_color = vec4(0.2, 0.55, 1.0, 1.0);
uniform float intensity = 2.5;
uniform float swirl = 3.0;
uniform float noise_scale = 4.0;
uniform float alpha = 1.0;
uniform float flow = 0.0;  // >0: akış yönünde kayan gürültü (ateş, su)

float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float vn(vec3 p) {
	vec3 i = floor(p), f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), u.x), mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), u.x), u.y),
	           mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), u.x), mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), u.x), u.y), u.z);
}

varying vec3 lpos;
void vertex() { lpos = VERTEX; }

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	vec3 p = lpos * noise_scale;
	float a = TIME * swirl;
	p.xz = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * p.xz;
	p.y -= TIME * flow;
	float n = vn(p) * 0.6 + vn(p * 2.3 + TIME) * 0.4;
	float streak = smoothstep(0.55, 0.9, n);
	vec3 c = mix(core.rgb, edge.rgb, fres) * (0.6 + streak * 0.9);
	c += edge.rgb * fres * 1.5;
	ALBEDO = c * intensity * alpha;
}
