shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;
// Bijūdama (ref refs/bijudama): koyu mor-siyah küre, içinde dönen menekşe girdaplar (pozitif/negatif chakra karışımı),
// kenarda ince parlak mor-beyaz hale (fresnel). light_mode: patlama kubbesi için açık tonlar + saydamlık.
uniform vec4 deep : source_color = vec4(0.02, 0.0, 0.05, 1.0);
uniform vec4 swirl_col : source_color = vec4(0.36, 0.14, 0.58, 1.0);
uniform vec4 rim_col : source_color = vec4(0.88, 0.72, 1.0, 1.0);
uniform float speed = 1.6;
uniform float rim_pow = 2.6;
uniform float alpha = 1.0;

float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float noise(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x), mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x), mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	float t = TIME * speed;
	// dönen girdap: yerel konumu dikey eksen etrafında yüksekliğe göre büküp gürültüyle örnekle
	vec3 p = normalize(lp) * 2.2;
	float a = t + p.y * 2.4;
	mat2 r = mat2(vec2(cos(a), -sin(a)), vec2(sin(a), cos(a)));
	p.xz = r * p.xz;
	float n = noise(p * 1.7 + vec3(0.0, t * 0.4, 0.0)) * 0.6 + noise(p * 3.9 - vec3(t * 0.3)) * 0.4;
	float bands = smoothstep(0.48, 0.72, n);
	vec3 c = mix(deep.rgb, swirl_col.rgb, bands);
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_pow);
	c = mix(c, rim_col.rgb, clamp(fr * 1.4, 0.0, 1.0));
	ALBEDO = c;
	ALPHA = alpha * mix(1.0, 0.65 + 0.35 * fr, step(alpha, 0.999));
}
