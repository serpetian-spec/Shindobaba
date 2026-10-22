// Ekran-uzayı anime mürekkep çizgileri (derinlik + normal farkı) + vinyet/flaş/ton.
// Ekran kopyası KULLANMAZ: yalnızca saydam bir katman çizer, böylece parçacık/enerji efektleri örtülmez.
shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, blend_mix;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform sampler2D normal_tex : hint_normal_roughness_texture, filter_nearest;
uniform float thickness = 1.3;
uniform float strength = 0.85;
uniform vec4 line_color : source_color = vec4(0.06, 0.04, 0.05, 1.0);
uniform float max_dist = 380.0;
uniform vec4 tint : source_color = vec4(0.0);
uniform float vignette = 0.55;
uniform float flash = 0.0;

void vertex() {
	POSITION = vec4(VERTEX.xy * 2.0, 1.0, 1.0);
}

float lin_depth(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_tex, uv).r;
	vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, d, 1.0);
	return -v.z / v.w;
}

void fragment() {
	vec2 px = thickness / VIEWPORT_SIZE;
	vec2 uv = SCREEN_UV;
	float d0 = lin_depth(uv, INV_PROJECTION_MATRIX);
	float dl = lin_depth(uv - vec2(px.x, 0.0), INV_PROJECTION_MATRIX);
	float dr = lin_depth(uv + vec2(px.x, 0.0), INV_PROJECTION_MATRIX);
	float du = lin_depth(uv + vec2(0.0, px.y), INV_PROJECTION_MATRIX);
	float dd = lin_depth(uv - vec2(0.0, px.y), INV_PROJECTION_MATRIX);
	float de = (abs(dl - d0) + abs(dr - d0) + abs(du - d0) + abs(dd - d0)) / max(d0, 0.3);
	vec3 n0 = texture(normal_tex, uv).xyz * 2.0 - 1.0;
	vec3 nl = texture(normal_tex, uv - vec2(px.x, 0.0)).xyz * 2.0 - 1.0;
	vec3 nr = texture(normal_tex, uv + vec2(px.x, 0.0)).xyz * 2.0 - 1.0;
	vec3 nu = texture(normal_tex, uv + vec2(0.0, px.y)).xyz * 2.0 - 1.0;
	vec3 nd = texture(normal_tex, uv - vec2(0.0, px.y)).xyz * 2.0 - 1.0;
	float ne = (1.0 - dot(n0, nl)) + (1.0 - dot(n0, nr)) + (1.0 - dot(n0, nu)) + (1.0 - dot(n0, nd));
	float edge = max(smoothstep(0.10, 0.28, de), smoothstep(0.55, 1.1, ne) * (1.0 - smoothstep(30.0, 90.0, d0)));
	edge *= 1.0 - smoothstep(max_dist * 0.4, max_dist, d0);
	// çimen gibi ince bitkiler (roughness ~0.02 ile işaretli) çizgi almasın
	float r0 = texture(normal_tex, uv).a;
	edge *= mix(0.12, 1.0, step(0.06, r0));
	edge *= strength;
	vec2 q = uv - 0.5;
	float vig = clamp(dot(q, q) * vignette, 0.0, 1.0);
	// katmanları üst üste bindir (öncelik: çizgi > flaş > ton > vinyet)
	vec3 col = vec3(0.0);
	float a = vig;
	col = mix(col, tint.rgb, tint.a);
	a = max(a, tint.a);
	col = mix(col, vec3(1.0), clamp(flash, 0.0, 1.0));
	a = max(a, clamp(flash, 0.0, 1.0));
	col = mix(col, line_color.rgb, edge);
	a = max(a, edge);
	ALBEDO = col;
	ALPHA = a;
}
