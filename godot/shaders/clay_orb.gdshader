shader_type spatial;
// Anime C3 patlaması: düz turuncu küre üstünde koyu turuncu benek lekeleri (cel, iki ton), kenarda sarı parlama,
// ekvatorda ince beyaz şok halkası çizgisi. Lekeler yavaşça kayar.
render_mode unshaded, blend_mix, depth_draw_opaque, cull_back;

uniform vec4 base_col : source_color = vec4(1.0, 0.66, 0.12, 1.0);
uniform vec4 spot_col : source_color = vec4(0.93, 0.42, 0.04, 1.0);
uniform vec4 rim_col : source_color = vec4(1.0, 0.92, 0.55, 1.0);
uniform float alpha = 1.0;

varying vec3 lp;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	lp = normalize(VERTEX);
}

void fragment() {
	vec3 q = lp * 3.2 + vec3(0.0, TIME * 0.25, 0.0);
	float n = noise(q) * 0.65 + noise(q * 2.3) * 0.35;
	vec3 col = n > 0.56 ? spot_col.rgb : base_col.rgb;
	float fres = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	col = mix(col, rim_col.rgb, step(0.82, fres) * 0.8);
	float ring = 1.0 - smoothstep(0.0, 0.025, abs(lp.y + 0.05));
	col = mix(col, vec3(1.0), ring * 0.9);
	ALBEDO = col;
	ALPHA = alpha;
}
