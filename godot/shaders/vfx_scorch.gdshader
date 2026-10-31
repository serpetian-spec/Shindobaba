shader_type spatial;
render_mode unshaded, cull_back;
// Shakuton küresi (anime Pakura): kameraya bakan merkez beyaz-sıcak, kenara doğru kızıl,
// üst-sol yarıda çapraz kalın beyaz parıltı şeritleri; yumuşak dönen titreme.
uniform vec4 core_col : source_color = vec4(1.0, 0.98, 0.95, 1.0);
uniform vec4 mid_col : source_color = vec4(0.98, 0.32, 0.34, 1.0);
uniform vec4 rim_col : source_color = vec4(0.92, 0.16, 0.2, 1.0);
uniform float core_size = 0.2;
uniform float streaks = 1.0;

void fragment() {
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	vec3 c = mix(rim_col.rgb, mid_col.rgb, smoothstep(0.15, 0.6, ndv));
	c = mix(c, core_col.rgb, smoothstep(1.0 - core_size, 1.0 - core_size * 0.45, ndv));
	// çapraz şeritler: görüş uzayında NORMAL.xy üzerinden (küre döndükçe kaymaz, anime ışığı gibi sabit)
	vec2 n = NORMAL.xy;
	// eskiz gibi düzensiz şeritler: iki frekans + kalınlık değişimi
	float d = n.x * 0.85 - n.y;                       // çapraz eksen
	float band = sin(d * 5.0 + TIME * 1.0);            // geniş çapraz kesikler
	float wob = 0.35 * sin(n.y * 9.0 + n.x * 4.0 + TIME * 0.6);   // kenarları eskiz gibi dalgalı
	float zone = smoothstep(0.08, 0.3, ndv);
	float st = smoothstep(0.35, 0.6, band + wob) * zone * streaks;
	c = mix(c, vec3(1.0), st * 0.9);
	ALBEDO = c;
}
