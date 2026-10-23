// Cel duman/alev topağı (parçacık): gürültüyle aşınmış sert kenarlı disk, 2 bantlı gölge, ince kontur.
// Renk ve "yaşam" parçacık COLOR'dan gelir: COLOR.a düştükçe topak dışarıdan içe doğru erir (yumuşak bulanıklık yok).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, shadows_disabled;

uniform float glow = 1.0;          // >1: alev (parlak), 1: duman
uniform float outline = 0.07;      // kontur kalınlığı (aşınma birimi)
uniform vec4 outline_col : source_color = vec4(0.18, 0.12, 0.12, 1.0);
uniform float shade = 0.3;         // alt bant karartma
uniform float rough = 0.32;        // kenar pürüzü
uniform float hot_core = 0.0;      // >0: merkezde beyaz-sarı çekirdek bandı (alev)
uniform float stretch = 1.0;       // >1: hız yönünde uzayan dil

varying float seed;
varying float life;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void vertex() {
	mat4 mw = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
	float a = INSTANCE_CUSTOM.x;
	mw = mw * mat4(vec4(cos(a), -sin(a), 0.0, 0.0), vec4(sin(a), cos(a), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * mw;
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz) * stretch, 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	seed = fract(float(INSTANCE_ID) * 0.6180339) * 37.0;
	life = INSTANCE_CUSTOM.y;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float n = vn(p * 2.3 + vec2(seed, seed * 0.7) + vec2(0.0, life * 1.6)) * 0.62 + vn(p * 5.1 - vec2(seed * 1.3, life * 2.5)) * 0.38;
	// alt kısım dolgun, üst tarafta "kıvrık" topaklar
	float shape = 1.0 - r + (n - 0.5) * rough * 2.0 + 0.08 * (-p.y);
	float thr = (1.0 - COLOR.a) * 0.92;
	float d = shape - thr - 0.06;
	if (d < 0.0) discard;
	vec3 nrm = normalize(vec3(p.x, -p.y, sqrt(max(0.0, 1.0 - min(r * r, 1.0)))));
	float l = dot(nrm, normalize(vec3(-0.45, 0.75, 0.55))) + (n - 0.5) * 0.5;
	vec3 c = COLOR.rgb;
	c *= (l > 0.08) ? 1.0 : (1.0 - shade);
	if (l > 0.72 && hot_core <= 0.0) c = mix(c, vec3(1.0), 0.12);
	if (hot_core > 0.0) {
		// küçük sarı-turuncu çekirdek (topağın yalnızca merkezi)
		if (d > 0.62 - 0.25 * hot_core) c = mix(c, vec3(1.0, 0.86, 0.3), 0.75);
	}
	c *= glow;
	float mx = max(c.r, max(c.g, c.b));
	if (mx > 1.0) c = c / mx * (1.0 + (mx - 1.0) * 0.2);   // tonu koru: doygun kalsın, beyaza kırpılmasın
	if (d < outline) c = mix(c, outline_col.rgb, outline_col.a);
	ALBEDO = c;
}
