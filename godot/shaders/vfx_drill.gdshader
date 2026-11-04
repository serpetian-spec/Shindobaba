shader_type spatial;
// Gatsūga / Tsūga matkabı (referans: Fang Passing Fang kareleri): opak gri-lavanta tüp, üzerinde sıkça dizili kısa siyah
// tarama çizgileri spiral boyunca akar; cel iki ton gölge; fade ile oluşum anında saydamdan opağa.
render_mode cull_disabled, unshaded;

uniform vec4 body : source_color = vec4(0.74, 0.73, 0.82, 1.0);
uniform vec4 shade : source_color = vec4(0.5, 0.47, 0.62, 1.0);
uniform vec4 ink : source_color = vec4(0.1, 0.08, 0.14, 1.0);
uniform float speed = 9.0;
uniform float rings = 26.0;
uniform float fade : hint_range(0.0, 1.0) = 1.0;

float h21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	// UV.x: çevre (0..1), UV.y: boy (0 arka .. 1 ön). Dönüş: çevre zamanla kayar.
	float u = fract(UV.x + TIME * speed * 0.05);
	// kameraya göre cel gölge (anime: üst-sol açık, alt-sağ koyu lavanta); ortam ışığından bağımsız
	vec3 nv = normalize(NORMAL) * (FRONT_FACING ? 1.0 : -1.0);
	float lit = dot(nv, normalize(vec3(-0.45, 0.75, 0.5)));
	float shadow = 1.0 - smoothstep(-0.3, -0.18, lit);
	vec3 c = mix(body.rgb, shade.rgb, shadow);
	// tarama öbekleri: gölge tarafında ve gölge sınırında, boy boyunca bantlar halinde sık ince kısa çizgiler
	float band = UV.y * 5.0 + u * 1.0 - TIME * speed * 0.15;
	float bi = floor(band);
	float bf = fract(band);
	float inband = step(0.12, bf) * step(bf, 0.78);
	float hatch = fract((UV.y * 70.0) + u * 2.0);
	float edge = smoothstep(0.25, -0.3, lit + (h21(vec2(bi, 7.0)) - 0.5) * 0.3);
	float line = inband * step(0.5, edge) * step(hatch, 0.32) * (1.0 - smoothstep(0.86, 0.92, UV.y));
	c = mix(c, ink.rgb, line * 0.9);
	// arka uç rüzgârla dağılır: yırtık kenar
	float tail = smoothstep(0.0, 0.18, UV.y + (h21(vec2(floor(UV.x * 14.0), floor(TIME * 12.0))) - 0.5) * 0.14);   // tırtıklı, keskin kuyruk kenarı
	// oluşum: ekran-uzayı titreşimli (dither) belirme
	if (tail < 0.5 || fade < h21(floor(FRAGCOORD.xy))) {
		discard;
	}
	ALBEDO = c;
}
