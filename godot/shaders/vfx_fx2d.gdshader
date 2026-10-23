// Kameraya dönük düz efekt kartları: 0 çarpma yıldızı, 1 şok dalgası halkası, 2 yerdeki çatlak/yanık.
// Sert kenarlı anime çizimi; "t" 0→1 animasyon ilerlemesi.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, blend_mix;

uniform int kind = 0;
uniform vec4 col : source_color = vec4(1.0, 0.8, 0.3, 1.0);
uniform vec4 core : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float t = 0.0;
uniform float spikes = 8.0;
uniform float seed = 0.0;
uniform bool billboard = true;

float hash(float x) { return fract(sin(x * 127.1 + seed * 31.7) * 43758.5453); }
float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1, 0)), u.x), mix(hash2(i + vec2(0, 1)), hash2(i + vec2(1, 1)), u.x), u.y);
}

void vertex() {
	if (billboard) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0, 0, 0), vec4(0, length(MODEL_MATRIX[1].xyz), 0, 0),
			vec4(0, 0, length(MODEL_MATRIX[2].xyz), 0), vec4(0, 0, 0, 1));
	}
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	vec3 c = col.rgb;
	float al = 0.0;
	if (kind == 0) {
		// çarpma yıldızı: düzensiz sivri ışınlar + beyaz çekirdek
		float k = a / 6.2831 * spikes;
		float i = floor(k);
		float f = fract(k);
		float len = 0.55 + 0.45 * hash(i);
		float spike = (1.0 - abs(f - 0.5) * 2.0);
		float edge = mix(0.22, len, pow(spike, 3.0));
		float sz = 1.0 - t * 0.35;
		if (r < edge * sz) { al = 1.0; c = col.rgb; }
		if (r < edge * sz * 0.55) c = core.rgb;
		al *= 1.0 - smoothstep(0.55, 1.0, t);
	} else if (kind == 1) {
		// şok dalgası: dışa giden sert halka, iç kenarı gürültüyle kırık
		float rad = t;
		float w = 0.06 + 0.1 * (1.0 - t);
		float n = vn(vec2(a * 3.0, t * 4.0)) * 0.08;
		float band = step(rad - w + n, r) * step(r, rad);
		al = band * (1.0 - t);
		c = mix(core.rgb, col.rgb, smoothstep(rad - w, rad, r));
	} else {
		// zemin çatlağı / yanık: merkezden dallanan çizgiler + koyu leke
		float n = vn(p * 3.0) * 0.5 + vn(p * 7.0) * 0.5;
		float k = a / 6.2831 * spikes + n * 0.8;
		float crack = 1.0 - smoothstep(0.02, 0.06, abs(fract(k) - 0.5) * (0.4 + r));
		float blot = step(r, 0.35 + n * 0.25);
		al = max(crack * step(r, 0.9 - n * 0.2), blot * 0.6) * (1.0 - smoothstep(0.7, 1.0, t));
		c = col.rgb;
	}
	if (al < 0.02) discard;
	ALBEDO = c;
	ALPHA = clamp(al, 0.0, 1.0);
}
