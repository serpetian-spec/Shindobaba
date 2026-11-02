shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, blend_mix;
// Sabun köpüğü (utakatababa2.png): içi neredeyse şeffaf; kenara doğru bakış açısıyla artan ince zar (Fresnel), zarda bakış
// açısı + zamanla kayan gökkuşağı (ince film girişimi: mor-mavi-yeşil-pembe), yukarı-solda beyaz parlama lekesi, altta zayıf
// ikinci parlama; zar yüzeyinde yavaş akan renk dalgaları.
uniform vec4 tint : source_color = vec4(0.85, 0.92, 1.0, 1.0);
uniform float rim_alpha = 0.55;
uniform float body_alpha = 0.05;
uniform float seed = 0.0;

vec3 film(float t) {
	// ince film renk döngüsü (mor -> mavi -> camgöbeği -> yeşil -> sarı -> pembe)
	return 0.5 + 0.5 * cos(6.2832 * (vec3(1.0, 1.0, 1.0) * t + vec3(0.0, 0.33, 0.67)));
}

void fragment() {
	vec3 n = normalize(NORMAL);
	vec3 v = normalize(VIEW);
	float ndv = clamp(dot(n, v), 0.0, 1.0);
	float fres = pow(1.0 - ndv, 2.2);
	float swirl = sin(n.x * 5.0 + n.y * 3.0 + TIME * 0.7 + seed) * 0.12 + sin(n.y * 7.0 - TIME * 0.5 + seed * 2.0) * 0.08;
	vec3 irid = film(ndv * 1.6 + swirl + seed * 0.13);
	vec3 col = mix(vec3(0.92, 0.95, 1.0), irid, 0.38 + 0.25 * (1.0 - ndv));   // beyazımsı zar, kenarda hafif gökkuşağı
	float a = body_alpha + fres * rim_alpha * 0.9;
	// parlama lekesi (görüş uzayında sabit yön: yukarı-sol), küçük ikinci parlama alt-sağda
	vec3 L = normalize(vec3(-0.45, 0.55, 0.7));
	float hl = smoothstep(0.86, 0.97, dot(n, L)) * 0.85;   // büyük yumuşak beyaz parlama
	vec3 L2 = normalize(vec3(0.5, -0.45, 0.75));
	float hl2 = pow(clamp(dot(n, L2), 0.0, 1.0), 140.0) * 0.6;
	col = mix(col, vec3(1.0), clamp(hl + hl2, 0.0, 1.0));
	a = max(a, (hl + hl2) * 0.95);
	// en dış kenar ince koyu-parlak çizgi (animedeki kontur)
	float edge = smoothstep(0.08, 0.0, ndv);
	col = mix(col, tint.rgb * 0.7 + irid * 0.3, edge * 0.5);
	a = max(a, edge * 0.7);
	ALBEDO = col;
	ALPHA = clamp(a, 0.0, 0.95);
}
