extends Node
## Görsel efektler (autoload "FX"): GPU parçacıkları, şok dalgaları, ışık çakmaları, iz efektleri.

var tex_soft: ImageTexture
var tex_spark: ImageTexture
var tex_smoke: ImageTexture
var tex_ring: ImageTexture
var tex_leaf: ImageTexture
var _mats = {}


func _ready() -> void:
	tex_soft = _radial(64, 2.2)
	tex_spark = _spark()
	tex_smoke = _smoke()
	tex_ring = _ring()
	tex_leaf = _leaf()


# ------------------------------------------------------------------ dokular
func _radial(s: int, p: float) -> ImageTexture:
	var img = Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var d = Vector2(x - s * 0.5 + 0.5, y - s * 0.5 + 0.5).length() / (s * 0.5)
			var a = pow(clampf(1.0 - d, 0, 1), p)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _spark() -> ImageTexture:
	var w = 16; var h = 64
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var u = absf(x - w * 0.5 + 0.5) / (w * 0.5); var v = absf(y - h * 0.5 + 0.5) / (h * 0.5)
			img.set_pixel(x, y, Color(1, 1, 1, pow(clampf(1.0 - u, 0, 1), 2.0) * pow(clampf(1.0 - v, 0, 1), 0.8)))
	return ImageTexture.create_from_image(img)


func _smoke() -> ImageTexture:
	var s = 64
	var img = Image.create(s, s, false, Image.FORMAT_RGBA8)
	var n = FastNoiseLite.new()
	n.frequency = 0.08
	for y in s:
		for x in s:
			var d = Vector2(x - s * 0.5, y - s * 0.5).length() / (s * 0.5)
			var a = clampf(1.0 - d, 0, 1)
			a = pow(a, 1.3) * (0.65 + 0.35 * n.get_noise_2d(x, y))
			img.set_pixel(x, y, Color(1, 1, 1, clampf(a * 1.4, 0, 1)))
	return ImageTexture.create_from_image(img)


func _ring() -> ImageTexture:
	var s = 128
	var img = Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var d = Vector2(x - s * 0.5, y - s * 0.5).length() / (s * 0.5)
			var a = exp(-pow((d - 0.85) * 9.0, 2.0))
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _leaf() -> ImageTexture:
	var s = 32
	var img = Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var u = (x - s * 0.5) / (s * 0.5); var v = (y - s * 0.5) / (s * 0.5)
			var on = u * u * 4.0 + v * v < 1.0
			img.set_pixel(x, y, Color(1, 1, 1, 1.0 if on else 0.0))
	return ImageTexture.create_from_image(img)


func _draw_mat(tex: Texture2D, additive: bool, billboard := BaseMaterial3D.BILLBOARD_PARTICLES) -> StandardMaterial3D:
	var key = "%s_%s_%d" % [tex.get_instance_id(), additive, billboard]
	if _mats.has(key):
		return _mats[key]
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = tex
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = billboard
	m.billboard_keep_scale = true
	m.disable_receive_shadows = true
	m.no_depth_test = false
	_mats[key] = m
	return m


func _gradient(cols: Array) -> GradientTexture1D:
	var g = Gradient.new()
	var offs = PackedFloat32Array()
	var cc = PackedColorArray()
	for i in cols.size():
		offs.append(float(i) / maxf(1.0, cols.size() - 1))
		cc.append(cols[i])
	g.offsets = offs
	g.colors = cc
	var t = GradientTexture1D.new()
	t.gradient = g
	return t


func _curve(points: Array) -> CurveTexture:
	var c = Curve.new()
	for p in points:
		c.add_point(Vector2(p[0], p[1]))
	var t = CurveTexture.new()
	t.curve = c
	return t


## Genel amaçlı tek seferlik parçacık patlaması
func burst(pos: Vector3, cfg: Dictionary) -> GPUParticles3D:
	var p = GPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = cfg.get("explosive", 0.95)
	p.amount = cfg.get("amount", 24)
	p.lifetime = cfg.get("life", 0.6)
	p.fixed_fps = 60
	p.local_coords = cfg.get("local", false)
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = cfg.get("radius", 0.2)
	pm.direction = cfg.get("dir", Vector3.UP)
	pm.spread = cfg.get("spread", 180.0)
	pm.initial_velocity_min = cfg.get("vmin", 2.0)
	pm.initial_velocity_max = cfg.get("vmax", 6.0)
	pm.gravity = cfg.get("gravity", Vector3.ZERO)
	pm.damping_min = cfg.get("damp", 2.0)
	pm.damping_max = cfg.get("damp", 2.0) * 1.5
	pm.scale_min = cfg.get("smin", 0.5)
	pm.scale_max = cfg.get("smax", 1.0)
	pm.angle_min = 0; pm.angle_max = 360
	pm.angular_velocity_min = cfg.get("spin", 0.0) * -1.0
	pm.angular_velocity_max = cfg.get("spin", 0.0)
	pm.color_ramp = _gradient(cfg.get("colors", [Color(1, 1, 1, 1), Color(1, 1, 1, 0)]))
	pm.scale_curve = _curve(cfg.get("scale_curve", [[0.0, 0.6], [0.3, 1.0], [1.0, 0.8]]))
	if cfg.has("orbit"):
		pm.orbit_velocity_min = cfg["orbit"]; pm.orbit_velocity_max = cfg["orbit"] * 1.4
	if cfg.has("tangent"):
		pm.tangential_accel_min = cfg["tangent"]; pm.tangential_accel_max = cfg["tangent"]
	p.process_material = pm
	var q = QuadMesh.new()
	q.size = Vector2.ONE * cfg.get("size", 1.0)
	var tex: Texture2D = cfg.get("tex", tex_soft)
	var bb: int = cfg.get("billboard", BaseMaterial3D.BILLBOARD_PARTICLES)
	if tex == tex_spark:
		q.size = Vector2(0.12, 0.6) * cfg.get("size", 1.0)
		pm.particle_flag_align_y = true
		bb = BaseMaterial3D.BILLBOARD_FIXED_Y
		bb = BaseMaterial3D.BILLBOARD_DISABLED
	q.material = _draw_mat(tex, cfg.get("add", true), bb)
	p.draw_pass_1 = q
	p.visibility_aabb = AABB(Vector3(-20, -20, -20), Vector3(40, 40, 40))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var parent: Node = cfg.get("parent", get_tree().current_scene)
	parent.add_child(p)
	if p.local_coords and parent != get_tree().current_scene:
		p.position = pos
	else:
		p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


## Genişleyen parlak halka (yere paralel ya da kameraya dönük)
func ring(pos: Vector3, col: Color, size := 4.0, dur := 0.35, flat := true, normal := Vector3.UP) -> void:
	var mi = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = Vector2.ONE
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = tex_ring
	m.albedo_color = col
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if not flat:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	q.material = m
	mi.mesh = q
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(mi)
	mi.global_position = pos
	if flat:
		mi.look_at(pos + normal, Vector3.FORWARD if absf(normal.y) < 0.99 else Vector3.RIGHT)
	mi.scale = Vector3.ONE * size * 0.2
	var tw = mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * size, dur).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "albedo_color:a", 0.0, dur)
	tw.chain().tween_callback(mi.queue_free)


## Anlık parlak küre (çarpma flaşı / patlama çekirdeği)
func flash_sphere(pos: Vector3, col: Color, size := 2.0, dur := 0.25) -> void:
	var mi = MeshInstance3D.new()
	var s = SphereMesh.new()
	s.radius = 0.5; s.height = 1.0; s.radial_segments = 16; s.rings = 8
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 3.0
	s.material = m
	mi.mesh = s
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(mi)
	mi.global_position = pos
	mi.scale = Vector3.ONE * size * 0.3
	var tw = mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * size, dur).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "albedo_color:a", 0.0, dur)
	tw.chain().tween_callback(mi.queue_free)


## Geçici nokta ışık (patlamalar, jutsu parıltısı)
func light(pos: Vector3, col: Color, energy := 4.0, rng := 10.0, dur := 0.3) -> void:
	var l = OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	l.shadow_enabled = false
	get_tree().current_scene.add_child(l)
	l.global_position = pos
	var tw = l.create_tween()
	tw.tween_property(l, "light_energy", 0.0, dur)
	tw.tween_callback(l.queue_free)


# ------------------------------------------------------------------ hazır efektler
func dust(pos: Vector3, s := 1.0) -> void:
	burst(pos + Vector3.UP * 0.1, {"amount": int(10 * s) + 4, "life": 0.7, "tex": tex_smoke, "add": false, "size": 1.2 * s,
		"vmin": 1.5, "vmax": 4.0 * s, "dir": Vector3.UP, "spread": 80.0, "damp": 4.0, "gravity": Vector3(0, -1, 0),
		"colors": [Color(0.75, 0.68, 0.55, 0.55), Color(0.7, 0.65, 0.55, 0.0)]})


func smoke_puff(pos: Vector3, s := 1.0, n := 14) -> void:
	burst(pos, {"amount": n, "life": 0.9, "tex": tex_smoke, "add": false, "size": 1.8 * s, "radius": 0.5 * s,
		"vmin": 1.0, "vmax": 3.5 * s, "damp": 3.0, "gravity": Vector3(0, 1.2, 0), "spin": 90.0,
		"colors": [Color(1, 1, 1, 0.95), Color(0.92, 0.92, 0.95, 0.7), Color(0.9, 0.9, 0.92, 0.0)],
		"scale_curve": [[0.0, 0.4], [0.25, 1.0], [1.0, 1.3]]})
	Sfx.play("poof", pos)


func speed_lines(pos: Vector3, dir: Vector3) -> void:
	burst(pos, {"amount": 14, "life": 0.25, "tex": tex_spark, "size": 2.2, "vmin": 10, "vmax": 18, "dir": -dir,
		"spread": 12.0, "radius": 0.8, "damp": 1.0, "colors": [Color(1, 1, 1, 0.8), Color(0.8, 0.9, 1, 0)]})


func hit_spark(pos: Vector3, col := Color(1.0, 0.85, 0.4), s := 1.0) -> void:
	burst(pos, {"amount": int(16 * s), "life": 0.32, "tex": tex_spark, "size": 1.4 * s, "vmin": 6, "vmax": 14 * s,
		"damp": 6.0, "colors": [Color(1, 1, 1, 1), col, Color(col.r, col.g, col.b, 0)]})
	flash_sphere(pos, col.lightened(0.3), 0.9 * s, 0.12)
	ring(pos, col, 2.2 * s, 0.22, false)


func impact(pos: Vector3, col: Color, s := 1.0) -> void:
	hit_spark(pos, col, s * 1.3)
	ring(Vector3(pos.x, Game.ground_height(pos.x, pos.z) + 0.1, pos.z), col, 7.0 * s, 0.45)
	dust(Vector3(pos.x, Game.ground_height(pos.x, pos.z), pos.z), 1.4 * s)
	light(pos, col, 6.0 * s, 10.0 * s, 0.25)


func explosion(pos: Vector3, s := 1.0, col := Color(1.0, 0.55, 0.15)) -> void:
	# anime patlama: cel çekirdek küre + doygun alev topakları + koyu duman + kıvılcım + şok dalgası
	var core = Projectile.energy_mesh(Color(1, 1, 0.75), col, 1.0, 6.0, 2.0, 3.0)
	get_tree().current_scene.add_child(core)
	core.global_position = pos
	var tw = core.create_tween()
	tw.tween_property(core, "scale", Vector3.ONE * 3.8 * s, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(core, "scale", Vector3.ONE * 0.1, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(core.queue_free)
	burst(pos, {"amount": int(36 * s), "life": 0.85, "tex": tex_smoke, "add": false, "size": 3.0 * s, "radius": 1.2 * s, "vmin": 5, "vmax": 13 * s,
		"damp": 5.0, "gravity": Vector3(0, 4, 0), "spin": 120.0,
		"colors": [Color(1, 0.95, 0.55, 1), Color(1, 0.55, 0.1, 1), Color(0.85, 0.2, 0.05, 0.9), Color(0.25, 0.12, 0.1, 0)],
		"scale_curve": [[0.0, 0.5], [0.25, 1.1], [1.0, 0.7]]})
	burst(pos, {"amount": int(20 * s), "life": 2.0, "tex": tex_smoke, "add": false, "size": 4.0 * s, "radius": 1.5 * s,
		"vmin": 1, "vmax": 5, "damp": 2.0, "gravity": Vector3(0, 2.5, 0), "spin": 40.0,
		"colors": [Color(0.25, 0.22, 0.2, 0.0), Color(0.22, 0.2, 0.19, 0.75), Color(0.35, 0.33, 0.32, 0.0)]})
	burst(pos, {"amount": int(30 * s), "life": 0.8, "tex": tex_spark, "size": 1.6, "vmin": 12, "vmax": 28 * s, "damp": 2.0,
		"gravity": Vector3(0, -12, 0), "colors": [Color(1, 1, 0.8, 1), col, Color(col.r, col.g, col.b, 0)]})
	ring(Vector3(pos.x, Game.ground_height(pos.x, pos.z) + 0.15, pos.z), col, 15.0 * s, 0.5)
	light(pos, col, 12.0 * s, 25.0 * s, 0.5)
	if Game.world:
		Game.world.env.add_shake(0.8 * s)
		Game.world.env.screen_flash(0.06 * s)
	Sfx.play("boom", pos)


## Döngüsel emitter: chakra aurası, jutsu çekirdekleri vb.
## dur > 0: o kadar saniye sonra kendiliğinden söner (iyileşme/seviye atlama gibi tek seferlik parıltılar).
## dur <= 0: kalıcı; çağıran durdurmalı (emitting = false + queue_free).
func aura(parent: Node3D, col: Color, s := 1.0, offset := Vector3(0, 0.9, 0), dur := 1.6) -> GPUParticles3D:
	var p = GPUParticles3D.new()
	p.amount = int(60 * s)
	p.lifetime = 0.8
	p.local_coords = false
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.7 * s
	pm.direction = Vector3.UP
	pm.spread = 20.0
	pm.initial_velocity_min = 1.5
	pm.initial_velocity_max = 4.0
	pm.gravity = Vector3(0, 2.0, 0)
	pm.scale_min = 0.4; pm.scale_max = 1.0
	pm.color_ramp = _gradient([Color(col.r, col.g, col.b, 0), Color(col.r, col.g, col.b, 0.8), Color(1, 1, 1, 0)])
	pm.scale_curve = _curve([[0.0, 0.3], [0.4, 1.0], [1.0, 0.2]])
	p.process_material = pm
	var q = QuadMesh.new()
	q.size = Vector2(0.5, 0.9) * s
	q.material = _draw_mat(tex_soft, true)
	p.draw_pass_1 = q
	parent.add_child(p)
	p.position = offset
	p.emitting = true
	if dur > 0.0:
		get_tree().create_timer(dur).timeout.connect(func():
			if is_instance_valid(p):
				p.emitting = false
				get_tree().create_timer(p.lifetime + 0.1).timeout.connect(func():
					if is_instance_valid(p):
						p.queue_free()))
	return p
