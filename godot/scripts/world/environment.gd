extends Node3D
## Gökyüzü, güneş/ay, gece-gündüz döngüsü, bölgesel hava durumu, sis, bloom ve anime çizgi post-efekti.

const DAY_LENGTH := 1200.0  # saniye (20 dk = 1 gün)

var time_of_day = 0.35  # 0=gece yarısı, .25 şafak, .5 öğle, .75 gün batımı
var env: Environment
var sun: DirectionalLight3D
var sky_mat: ShaderMaterial
var post: MeshInstance3D
var post_mat: ShaderMaterial
var rain: GPUParticles3D
var weather = "açık"
var weather_t = 0.0
var region_weather = "açık"
var overcast = 0.0
var shake = 0.0
var flash = 0.0
var tint = Color(0, 0, 0, 0)
var tint_target = Color(0, 0, 0, 0)

const PAL := {
	# zaman: [zenith, horizon, sun color, sun energy, ambient]
	"night": [Color(0.02, 0.04, 0.12), Color(0.08, 0.12, 0.22), Color(0.55, 0.65, 0.95), 0.25, Color(0.18, 0.22, 0.38)],
	"dawn": [Color(0.25, 0.32, 0.6), Color(0.98, 0.62, 0.42), Color(1.0, 0.62, 0.4), 0.9, Color(0.55, 0.45, 0.5)],
	"day": [Color(0.22, 0.5, 0.92), Color(0.72, 0.86, 0.98), Color(1.0, 0.96, 0.88), 1.6, Color(0.6, 0.68, 0.82)],
	"dusk": [Color(0.18, 0.2, 0.48), Color(1.0, 0.5, 0.3), Color(1.0, 0.5, 0.28), 0.8, Color(0.5, 0.38, 0.45)],
}


func _ready() -> void:
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = load("res://shaders/sky.gdshader")
	var sky = Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_energy = 0.3
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_strength = 1.1
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 1.25
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.set_glow_level(2, 1.0)
	env.set_glow_level(3, 0.8)
	env.set_glow_level(4, 0.5)
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_density = 0.0009
	env.fog_sky_affect = 0.15
	env.fog_height = 60.0
	env.fog_height_density = 0.004
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.6
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.18
	env.adjustment_contrast = 1.06
	var we = WorldEnvironment.new()
	we.environment = env
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.shadow_enabled = Game.settings["shadows"]
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 220.0
	sun.shadow_blur = 1.5
	sun.light_angular_distance = 0.5
	add_child(sun)

	# anime çizgi + renk post-efekti (kameraya yapışık tam ekran quad)
	post_mat = ShaderMaterial.new()
	post_mat.shader = load("res://shaders/outline_post.gdshader")
	post_mat.render_priority = 120
	post = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = Vector2(2, 2)
	q.flip_faces = true
	post.mesh = q
	post.material_override = post_mat
	post.extra_cull_margin = 16384
	post.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_make_rain()


func _make_rain() -> void:
	rain = GPUParticles3D.new()
	rain.amount = 5000
	rain.lifetime = 1.2
	rain.visibility_aabb = AABB(Vector3(-40, -30, -40), Vector3(80, 60, 80))
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(35, 1, 35)
	pm.direction = Vector3(0.1, -1, 0)
	pm.spread = 3.0
	pm.initial_velocity_min = 38.0
	pm.initial_velocity_max = 48.0
	pm.gravity = Vector3(0, -20, 0)
	rain.process_material = pm
	var m = QuadMesh.new()
	m.size = Vector2(0.03, 0.9)
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.75, 0.85, 1.0, 0.35)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.material = mat
	rain.draw_pass_1 = m
	rain.emitting = false
	add_child(rain)


func attach_post(cam: Camera3D) -> void:
	if post.get_parent():
		post.get_parent().remove_child(post)
	cam.add_child(post)
	post.position = Vector3(0, 0, -0.5)
	post.visible = Game.settings["outline"]


func get_time_of_day() -> float:
	return time_of_day


func _pal(t: float) -> Array:
	# 4 anahtar arasında yumuşak geçiş
	var keys = [[0.0, "night"], [0.2, "night"], [0.27, "dawn"], [0.36, "day"], [0.66, "day"], [0.74, "dusk"], [0.8, "night"], [1.0, "night"]]
	for i in keys.size() - 1:
		var a = keys[i]; var b = keys[i + 1]
		if t >= a[0] and t <= b[0]:
			var k = (t - a[0]) / maxf(0.0001, b[0] - a[0])
			k = k * k * (3.0 - 2.0 * k)
			var A: Array = PAL[a[1]]; var B: Array = PAL[b[1]]
			return [A[0].lerp(B[0], k), A[1].lerp(B[1], k), A[2].lerp(B[2], k), lerpf(A[3], B[3], k), A[4].lerp(B[4], k)]
	return PAL["day"]


func _process(dt: float) -> void:
	if not Game.paused:
		time_of_day = fmod(time_of_day + dt / DAY_LENGTH, 1.0)
	var p = _pal(time_of_day)
	var night = 1.0 - smoothstep(0.2, 0.3, time_of_day) + smoothstep(0.72, 0.82, time_of_day)
	night = clampf(night, 0.0, 1.0)
	# güneş yayı (geceleyin ay ışığı = ters yön)
	var ang = (time_of_day - 0.25) * TAU
	var sun_dir = Vector3(cos(ang) * 0.75, sin(ang), 0.35).normalized()
	if sun_dir.y < 0.05:
		sun_dir = -sun_dir
		sun_dir.y = maxf(sun_dir.y, 0.25)
	sun.look_at_from_position(Vector3.ZERO, -sun_dir, Vector3.UP if absf(sun_dir.y) < 0.99 else Vector3.FORWARD)

	# bölgesel hava durumu
	_update_weather(dt)
	var zen: Color = p[0].lerp(Color(0.4, 0.42, 0.48), overcast * 0.7)
	var hor: Color = p[1].lerp(Color(0.55, 0.57, 0.62), overcast * 0.7)
	sun.light_color = p[2]
	sun.light_energy = p[3] * (1.0 - overcast * 0.55)
	env.ambient_light_color = p[4].lerp(Color(0.5, 0.52, 0.58), overcast * 0.5)
	env.fog_light_color = hor
	var fog_base = 0.0007 / maxf(0.4, float(Game.settings["view"]))
	env.fog_density = lerpf(fog_base, 0.006, overcast * (1.0 if weather in ["sis", "kum fırtınası"] else 0.25))
	sky_mat.set_shader_parameter("zenith", zen)
	sky_mat.set_shader_parameter("horizon", hor)
	sky_mat.set_shader_parameter("sun_tint", p[2])
	sky_mat.set_shader_parameter("night", night)
	sky_mat.set_shader_parameter("overcast", overcast)

	# efekt uniform'ları
	flash = maxf(0.0, flash - dt * 3.0)
	tint = tint.lerp(tint_target, minf(1.0, dt * 5.0))
	post_mat.set_shader_parameter("flash", flash)
	post_mat.set_shader_parameter("tint", tint)
	var cam = get_viewport().get_camera_3d()
	if cam:
		rain.global_position = cam.global_position + Vector3(0, 18, 0)


func _update_weather(dt: float) -> void:
	# bölgeye göre baskın hava: Yağmur Ülkesi hep yağmurlu, Su Ülkesi sisli, Rüzgar çölü kum fırtınası
	var reg = "açık"
	if Game.player:
		var m = Game.to_map(Game.player.global_position)
		for c in Game.world_info["countries"]:
			if m.distance_to(Vector2(c["x"], c["y"])) < float(c["r"]) * 0.8:
				match c["id"]:
					"rain": reg = "yağmur"
					"water": reg = "sis"
					"wind": reg = "kum fırtınası" if fmod(time_of_day * 3.0, 1.0) < 0.3 else "açık"
					"iron", "frost": reg = "kar"
	weather_t -= dt
	if weather_t <= 0.0:
		weather_t = randf_range(120, 300)
		region_weather = ["açık", "açık", "açık", "bulutlu", "yağmur"].pick_random()
	weather = reg if reg != "açık" else region_weather
	var target_overcast = {"açık": 0.0, "bulutlu": 0.5, "yağmur": 0.85, "sis": 0.7, "kum fırtınası": 0.8, "kar": 0.6}.get(weather, 0.0)
	overcast = move_toward(overcast, target_overcast, dt * 0.08)
	rain.emitting = weather in ["yağmur", "kar"] and overcast > 0.4
	var pm: ParticleProcessMaterial = rain.process_material
	if weather == "kar":
		pm.initial_velocity_min = 2.0; pm.initial_velocity_max = 4.0; pm.gravity = Vector3(0.5, -2, 0)
		rain.lifetime = 8.0
	else:
		pm.initial_velocity_min = 38.0; pm.initial_velocity_max = 48.0; pm.gravity = Vector3(0, -20, 0)
		rain.lifetime = 1.2


## Kamera sarsıntısı / ekran efektleri (dövüş için)
func add_shake(a: float) -> void:
	shake = maxf(shake, a)


func screen_flash(a: float) -> void:
	flash = maxf(flash, a)


func set_tint(c: Color) -> void:
	tint_target = c
