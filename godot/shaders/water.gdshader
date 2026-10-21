shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_schlick_ggx, depth_draw_always;

uniform vec4 deep : source_color = vec4(0.07, 0.25, 0.42, 1.0);
uniform vec4 shallow : source_color = vec4(0.22, 0.62, 0.72, 1.0);
uniform sampler2D depth_tex : hint_depth_texture, filter_linear;
uniform float murk = 0.12;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME;
	VERTEX.y += sin(wpos.x * 0.08 + t * 1.2) * 0.12 + cos(wpos.z * 0.07 + t) * 0.12;
}

void fragment() {
	vec2 p = wpos.xz;
	float t = TIME;
	vec3 n = normalize(vec3(
		sin(p.x * 0.35 + t * 1.3) * 0.08 + sin(p.x * 1.1 - p.y * 0.7 + t * 2.1) * 0.05 + sin((p.x + p.y) * 2.3 + t * 3.0) * 0.025,
		1.0,
		cos(p.y * 0.31 + t * 1.1) * 0.08 + sin(p.y * 1.3 + p.x * 0.5 - t * 1.7) * 0.05 + cos((p.x - p.y) * 2.1 - t * 2.6) * 0.025));
	NORMAL = (VIEW_MATRIX * vec4(n, 0.0)).xyz;
	// derinliğe göre renk ve kıyıda köpük
	float d = texture(depth_tex, SCREEN_UV).r;
	vec4 v = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, d, 1.0);
	float scene_z = -v.z / v.w;
	float water_z = -VERTEX.z;
	float thick = clamp((scene_z - water_z) * murk, 0.0, 1.0);
	vec3 c = mix(shallow.rgb, deep.rgb, thick);
	float foam = 1.0 - smoothstep(0.0, 0.08, thick);
	foam *= 0.6 + 0.4 * sin(p.x * 3.0 + t * 4.0) * sin(p.y * 2.7 - t * 3.0);
	ALBEDO = c + foam * 0.7;
	ALPHA = mix(0.55, 0.92, thick) + foam * 0.3;
	ROUGHNESS = 0.06;
	METALLIC = 0.0;
	SPECULAR = 0.8;
}
