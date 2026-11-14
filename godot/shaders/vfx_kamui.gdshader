// Kamui girdabı (anime: Obito / Kakashi): uzay bükülür — arkadaki dünya merkeze doğru dönerek burkulur (ekran dokusu
// girdap bükülmesi), ortası koyu boşluğa iner, üstünde ince koyu spiral çizgiler; kenarda bükülme yumuşakça söner.
// Kameraya bakan dörtgen üzerinde (UV merkezli).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled, shadows_disabled, blend_mix;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float strength = 1.0;    // 0..1 açılış/kapanış
uniform float twist = 7.0;       // merkezde dönüş miktarı (radyan)
uniform float spin = 3.0;        // zamanla dönme hızı
uniform float core = 0.22;       // koyu merkez yarıçapı (UV)
uniform vec4 tint : source_color = vec4(0.22, 0.16, 0.3, 1.0);

void fragment() {
	vec2 c = UV - 0.5;
	float r = length(c) * 2.0;           // 0 merkez .. 1 kenar
	if (r > 1.0) discard;
	float fall = pow(max(1.0 - r, 0.0), 2.2) * strength;
	float a = atan(c.y, c.x);
	// burkulma: merkeze yakın daha çok döner, zamanla akar
	float ang = fall * twist + TIME * spin * fall;
	vec2 rc = vec2(cos(ang), sin(ang));
	vec2 tw = vec2(c.x * rc.x - c.y * rc.y, c.x * rc.y + c.y * rc.x);
	// ekran uzayında bükülme: dörtgenin ekrandaki boyutuna göre ölçek (UV farkı ~ SCREEN_UV farkı)
	vec2 off = (tw - c) * 0.18 * strength;
	vec3 bg = textureLod(screen_tex, SCREEN_UV + off, 1.0).rgb;
	// spiral çizgiler: logaritmik spiral, merkeze akar
	float sp = sin(a * 3.0 + log(max(r, 0.02)) * 9.0 + TIME * spin * 2.0);
	float lines = smoothstep(0.82, 0.97, sp) * (1.0 - smoothstep(0.55, 1.0, r)) * strength;
	vec3 col = mix(bg, bg * (1.0 - 0.35 * fall) + tint.rgb * 0.15 * fall, 0.85);
	col = mix(col, tint.rgb * 0.45, lines * 0.8);
	// koyu boşluk: merkez Kamui boyutuna açılır
	float hole = 1.0 - smoothstep(core * 0.6, core, r / max(strength, 0.01) * 0.5 + r * 0.5);
	col = mix(col, vec3(0.02, 0.01, 0.03), hole * strength);
	ALBEDO = col;
	ALPHA = clamp(smoothstep(1.0, 0.75, r) * (0.35 + strength * 0.65), 0.0, 1.0);
}
