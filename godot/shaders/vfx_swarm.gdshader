shader_type spatial;
// Aburame böcek kütlesi (referans: Insect Sphere / Insect Wall / Insect Tornado kareleri): pürüzsüz kabuk DEĞİL —
// kumlu, kaynayan kara kütle; kenarı tırtıklı ve titrek (silüet böceklerden oluşur), içinde gri kanat parıltıları.
render_mode unshaded, cull_back, depth_draw_opaque;

uniform vec4 col : source_color = vec4(0.07, 0.07, 0.06, 1.0);
uniform vec4 fleck : source_color = vec4(0.32, 0.32, 0.3, 1.0);
uniform float grain = 160.0;     // böcek yoğunluğu (UV başına)
uniform float crawl = 1.5;      // kaynama hızı
uniform float edge = 0.62;      // silüet tırtığının başladığı fresnel
uniform float fade : hint_range(0.0, 1.0) = 1.0;
uniform float spin = 0.0;       // hortum/kubbe: yatay akış
uniform float cover = 1.0;      // bedene kaplama: kapladığı oran (Kikaichū yapışması 0.4 benek, Mushidama 1.0 tam silüet)
uniform float grow = 0.0;       // bedene kaplama: kütle kalınlığı (normal boyunca şişirme, metre)

float h21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	// yüzey kaynar: normal boyunca küçük titreşim (kütle canlı görünsün)
	float n = h21(floor(UV * 18.0 + floor(TIME * 8.0)));
	VERTEX += NORMAL * ((n - 0.5) * 0.06 + grow);
}

void fragment() {
	// taneler ekran ölçeğinde (her uzaklıkta ince kum gibi; yakında kare blok olmaz) + yüzeye bağlı yavaş kaynama
	vec2 px = floor(FRAGCOORD.xy / 2.0);
	float g = h21(px + floor(TIME * 24.0) * 0.37);
	float g2 = h21(floor(FRAGCOORD.xy / 5.0) + floor(TIME * 10.0) * 1.7);
	vec2 uv = UV + vec2(TIME * spin, 0.0);
	float band = 0.5 + 0.5 * sin(uv.x * 40.0 + uv.y * 9.0 + TIME * 3.0);   // dönen kütlede koyu/açık akış izleri
	// silüet: kenara yaklaştıkça tane tane delinir (tırtıklı, böcek böcek)
	float fr = 1.0 - abs(dot(normalize(NORMAL), normalize(VIEW)));
	if (fr > edge + (g - 0.5) * 0.3 + (g2 - 0.5) * 0.25) {
		discard;
	}
	vec2 cell = floor(UV * grain + vec2(TIME * crawl * 3.0, TIME * crawl));
	if (h21(cell + 7.3) > cover) {
		discard;   // kısmi kaplama: yalnız böceklerin olduğu hücreler
	}
	if (fade < g) {
		discard;
	}
	vec3 c = col.rgb * (0.7 + g * 0.45 + band * 0.25 * step(0.001, spin));
	c = mix(c, fleck.rgb, step(0.985, g2) * 0.6);   // tek tük kanat parıltısı
	ALBEDO = c;
}
