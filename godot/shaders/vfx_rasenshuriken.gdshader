shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, blend_mix;
// Fūton: Rasenshuriken (anime ref refs/rasenshuriken): mavi Rasengan çekirdeğin çevresinde dört geniş, kıvrık,
// kenarları dumanımsı söken BEYAZ rüzgâr bıçağı (fırıldak). Düz disk (PlaneMesh, XZ); bıçaklar çekirdekten dışa
// doğru geriye kıvrılır, uçlara doğru incelip saçaklanır. İnce dönen halka çizgileri + yarı saydam sis.
uniform float spin = 0.0;       // dönüş açısı (radyan, betikten artar)
uniform float grow = 1.0;       // 0..1 oluşum (bıçaklar çekirdekten dışa uzar)
uniform float alpha = 1.0;
uniform vec3 white : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 tint : source_color = vec3(0.78, 0.9, 1.0);
varying vec3 lp;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void vertex() { lp = VERTEX; }

void fragment() {
	vec2 q = lp.xz * 2.0;            // PlaneMesh 1x1 -> yarıçap 1
	float r = length(q);
	float a = atan(q.y, q.x);
	float rr = r / max(grow, 0.01);
	// dört kollu fırıldak: açı yarıçapla geriye kıvrılır (bıçaklar dönüş yönünün tersine süpürülür)
	float sweep = a - spin + rr * 1.9;
	float arm = 0.5 + 0.5 * cos(sweep * 4.0);   // 4 kol
	// kol kalınlığı uca doğru incelir; dumanımsı kenar
	float wisp = vn(vec2(sweep * 3.0, rr * 6.0 - spin * 0.6)) * 0.35 + vn(vec2(sweep * 9.0, rr * 14.0)) * 0.15;
	float width = mix(0.8, 0.32, smoothstep(0.15, 1.0, rr));
	float blade = smoothstep(1.0 - width - 0.15, 1.0 - width + 0.1, arm + wisp - 0.1);
	// uçlar saçaklanır, dış sınır dağınık
	float outer = 1.0 - smoothstep(0.8, 1.05, rr + (vn(vec2(a * 4.0 + spin, 3.1)) - 0.5) * 0.25);
	float inner = smoothstep(0.06, 0.2, rr);
	blade *= outer * inner;
	// bıçak içinde akış çizgileri (rüzgâr yalazları)
	float streak = smoothstep(0.55, 0.95, vn(vec2(sweep * 14.0, rr * 2.0 - spin * 2.0)));
	// ince dönen halkalar (animedeki çekirdek çevresi çizgileri)
	float ring = 0.0;
	for (int k = 0; k < 3; k++) {
		float rk = 0.3 + float(k) * 0.17;
		ring += (1.0 - smoothstep(0.0, 0.012, abs(rr - rk))) * step(0.4, fract((a + spin * (1.3 + float(k) * 0.4)) / 6.2831 * 3.0));
	}
	ring *= outer;
	// çekirdek çevresi hafif sis (diski bir arada tutar)
	float haze = (1.0 - smoothstep(0.0, 0.85, rr)) * 0.22;
	vec3 col = mix(tint, white, clamp(blade * 0.8 + streak * 0.4, 0.0, 1.0));
	ALBEDO = col;
	ALPHA = clamp((blade * 0.97 + streak * blade * 0.12 + ring * 0.7 + haze) * alpha, 0.0, 0.95);
}
