// 3B alev / duman topağı (Storm ateşi): parçacık rengi (COLOR) üzerinden; merkez parlak (beyaz-sarı), kenara doğru renk koyulaşır ve
// yumuşakça saydamlaşır — düz daire / balon değil, hacimli ışıyan alev. Kenarda hafif gürültü: alev dili gibi titrer.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, shadows_disabled, blend_mix;
uniform float hot = 1.0;     // 1: ateş (merkez beyaza döner), 0: duman (yumuşak gri)
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
	float w = vn(VERTEX * 3.0 + vec3(0.0, TIME * 2.5, float(INSTANCE_ID) * 3.1)) - 0.5;
	VERTEX += NORMAL * w * 0.18;   // kabaran, titreyen yüzey
}
void fragment() {
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float core = smoothstep(0.35, 1.0, ndv);   // merkez
	vec3 c = COLOR.rgb;
	vec3 hotc = mix(c, vec3(1.0, 0.97, 0.8), core * 0.75 * hot);
	vec3 col = mix(c * mix(0.75, 1.0, 1.0 - hot), hotc, core);
	float n = vn(lp * 5.0 + vec3(0.0, -TIME * 3.0, 0.0));
	float edge = smoothstep(0.05, 0.45 + n * 0.2, ndv);   // yumuşak, tırtıklı kenar
	ALBEDO = col * (1.0 + core * 0.35 * hot);
	ALPHA = COLOR.a * edge;
}
