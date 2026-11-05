shader_type spatial;
render_mode unshaded, blend_mix, cull_back, depth_draw_never, shadows_disabled;
// Chakra toplama aurası (Naruto Storm tarzı): bedenin her mesh'ine material_overlay — bedenden biraz dışarı şişen,
// yukarı doğru dalgalanıp alev dilleri gibi kopan mavi chakra katmanı; kenarda (fresnel) parlak, ortada saydam.
// Kart/parçacık değil: pozu ve animasyonu birebir izler.
uniform float t = 0.0;
uniform float k = 1.0;            // 0..1 açılma/sönme
uniform vec3 deep : source_color = vec3(0.12, 0.38, 1.0);
uniform vec3 light : source_color = vec3(0.7, 0.92, 1.0);
uniform float base_y = 0.0;       // ayak hizası (dünya y)
varying vec3 wp;
varying float rise;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float a = atan(wn.x, wn.z);
	// yukarı akan alev dalgası: yüksek yerlerde ve dalga tepelerinde daha çok şişer (dil dil kopar)
	float wave = vn(vec2(a * 2.2, w.y * 3.0 - t * 4.5)) ;
	float up = clamp(wn.y * 0.5 + 0.5, 0.0, 1.0);
	float swell = (0.025 + wave * 0.07 + up * wave * 0.08) * k;
	VERTEX += NORMAL * swell / max(length((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz), 0.001);
	// üste bakan yüzeylerde alev dilleri yukarı uzar (baş/omuz üstünde yalazlar)
	vec3 up_l = (inverse(MODEL_MATRIX) * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	VERTEX += up_l * pow(up, 2.0) * smoothstep(0.45, 0.9, wave) * 0.28 * k;
	wp = w;
	rise = wave;
}

void fragment() {
	float fres = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 1.6);
	float a = atan(wp.x - wp.z, 0.7);
	float flame = vn(vec2(wp.x * 4.0 + wp.z * 3.0, wp.y * 5.0 - t * 6.0)) * 0.6 + vn(vec2(wp.x * 11.0 - wp.z * 9.0, wp.y * 12.0 - t * 9.0)) * 0.4;
	float tongue = smoothstep(0.45, 0.8, flame + rise * 0.3);
	vec3 col = mix(deep, light, clamp(fres * 0.8 + tongue * 0.6, 0.0, 1.0));
	float alpha = (fres * 0.7 + tongue * 0.4 * (0.25 + 0.75 * fres)) * k;   // ortası saydam: beden görünür, kenar parlar
	alpha *= smoothstep(base_y - 0.05, base_y + 0.25, wp.y);   // ayak dibinde yere gömülmesin
	ALBEDO = col;
	ALPHA = clamp(alpha, 0.0, 0.85);
}
