shader_type spatial;
// Anime lavı (Mei'nin lav duvarı / Rōshi-Kurotsuchi lav kayaları): düz cel renk, kızıl taban üstünde akan parlak
// sarı-turuncu erimiş hücre lekeleri (molten) ya da turuncu üstünde koyu kabuk benekleri (rock); kenarda parlak sarı halka,
// ince koyu kızıl kontur bandı. Hücreler yavaşça akar.
render_mode unshaded, cull_back, depth_draw_opaque, shadows_disabled;

uniform vec4 base_col : source_color = vec4(0.82, 0.08, 0.07, 1.0);
uniform vec4 spot_col : source_color = vec4(1.0, 0.62, 0.12, 1.0);
uniform vec4 hot_col : source_color = vec4(1.0, 0.92, 0.45, 1.0);
uniform vec4 rim_col : source_color = vec4(1.0, 0.5, 0.15, 1.0);
uniform vec4 line_col : source_color = vec4(0.32, 0.02, 0.02, 1.0);
uniform float spot_thresh = 0.55;
uniform float crust_thresh = -1.0;   // >0: düşük gürültü bölgeleri koyu kırık kaya kabuğu (lavın içinde yüzen toprak parçaları)
uniform vec4 crust_col : source_color = vec4(0.2, 0.11, 0.07, 1.0);
uniform float cell_scale = 2.4;
uniform float flow = 0.35;
uniform bool world_space = false;

varying vec3 p3;

float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float vn(vec3 p) {
	vec3 i = floor(p), f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), u.x), mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), u.x), u.y),
	           mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), u.x), mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), u.x), u.y), u.z);
}

void vertex() {
	p3 = world_space ? (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz : VERTEX;
}

void fragment() {
	vec3 q = p3 * cell_scale + vec3(0.0, -TIME * flow, TIME * flow * 0.6);
	float n = vn(q) * 0.6 + vn(q * 2.1 + 3.7) * 0.4;
	vec3 col = base_col.rgb;
	if (n > spot_thresh) col = spot_col.rgb;
	if (n > spot_thresh + 0.13) col = hot_col.rgb;
	// kırık kaya kabuğu: köşeli koyu parçalar (ikinci gürültü katmanı keskin kenarlı)
	float cn = vn(q * 1.7 + vec3(9.1, 2.3, 5.7));
	if (crust_thresh > 0.0 && cn < crust_thresh) col = crust_col.rgb * (0.85 + 0.3 * vn(q * 6.0));
	float fres = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	col = mix(col, rim_col.rgb, step(0.62, fres) * 0.85);
	col = mix(col, line_col.rgb, step(0.88, fres));
	ALBEDO = col;
}
