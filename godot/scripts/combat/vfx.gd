class_name VFX
extends RefCounted
## Anime (Storm tarzı) efekt araç kutusu: cel alev/su/rüzgar/şimşek malzemeleri, ateş topu, rasengan, çarpma yıldızı,
## şok dalgası, zemin çatlağı, moloz, sıçrama tacı, kurdele iz, ekran hız çizgileri. Tüm jutsular bunları kullanır.

static var _cache := {}
static var _speed_layer: CanvasLayer
static var _speed_rect: ColorRect
static var _active := 0
## Destan ölçeği: yayın sırasında jutsunun rütbe/ustalık büyüklüğü (E 0.7 … S 2.2+). Kurucular ve tek seferlik efektler bununla büyür.
static var epic := 1.0
const MAX_ACTIVE := 90   # aynı anda canlı ağır efekt sınırı (performans)

const FIRE_PRESETS := {
	"fire": [Color(1.0, 0.92, 0.42), Color(1.0, 0.72, 0.1), Color(1.0, 0.4, 0.04), Color(0.8, 0.12, 0.03), Color(0.3, 0.04, 0.02)],
	"blue": [Color(0.92, 1.0, 1.0), Color(0.5, 0.85, 1.0), Color(0.15, 0.45, 1.0), Color(0.08, 0.18, 0.7), Color(0.02, 0.05, 0.25)],
	"black": [Color(0.02, 0.0, 0.03), Color(0.05, 0.01, 0.07), Color(0.1, 0.02, 0.14), Color(0.3, 0.05, 0.38), Color(0.55, 0.12, 0.62)],
	"lava": [Color(1.0, 0.9, 0.45), Color(1.0, 0.55, 0.1), Color(0.85, 0.25, 0.05), Color(0.45, 0.1, 0.04), Color(0.15, 0.04, 0.03)],
	"green": [Color(0.9, 1.0, 0.85), Color(0.55, 1.0, 0.45), Color(0.15, 0.8, 0.3), Color(0.05, 0.45, 0.2), Color(0.02, 0.18, 0.08)],
	"purple": [Color(1.0, 0.9, 1.0), Color(0.85, 0.55, 1.0), Color(0.55, 0.25, 0.95), Color(0.3, 0.1, 0.6), Color(0.12, 0.03, 0.25)],
}


static func scene() -> Node:
	return (Engine.get_main_loop() as SceneTree).current_scene


static func tree() -> SceneTree:
	return Engine.get_main_loop()


static func busy() -> bool:
	return _active >= MAX_ACTIVE


static func _track(n: Node) -> void:
	_active += 1
	n.tree_exited.connect(func(): _active = maxi(0, _active - 1))


# ================================================================== malzemeler
static func mat_fire(preset := "fire", speed := 2.2, scale_ := 2.4, erode := 0.42, glow := 1.35, wobble := 0.12, flow := Vector3.UP, unique := false) -> ShaderMaterial:
	var key = "fire_%s_%.2f_%.2f_%.2f_%.2f_%.2f_%s" % [preset, speed, scale_, erode, glow, wobble, flow]
	if not unique and _cache.has(key):
		return _cache[key]
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/vfx_fire.gdshader")
	var p: Array = FIRE_PRESETS.get(preset, FIRE_PRESETS["fire"])
	for i in 5:
		m.set_shader_parameter(["c_core", "c_hot", "c_mid", "c_edge", "c_line"][i], p[i])
	m.set_shader_parameter("speed", speed)
	m.set_shader_parameter("scale", scale_)
	m.set_shader_parameter("erode", erode)
	m.set_shader_parameter("glow", glow)
	m.set_shader_parameter("wobble", wobble)
	m.set_shader_parameter("flow", flow)
	if not unique:
		_cache[key] = m
	return m


static func mat_water(deep := Color(0.05, 0.28, 0.78), mid := Color(0.2, 0.55, 0.98), light := Color(0.62, 0.88, 1.0), flow := Vector3(0, 0, 1), alpha := 0.88, foam := 0.5, wobble := 0.06) -> ShaderMaterial:
	var key = "water_%s_%s_%s_%s_%.2f_%.2f_%.2f" % [deep, mid, light, flow, alpha, foam, wobble]
	if _cache.has(key):
		return _cache[key]
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/vfx_water.gdshader")
	m.set_shader_parameter("c_deep", deep)
	m.set_shader_parameter("c_mid", mid)
	m.set_shader_parameter("c_light", light)
	m.set_shader_parameter("flow", flow)
	m.set_shader_parameter("alpha", alpha)
	m.set_shader_parameter("foam", foam)
	m.set_shader_parameter("wobble", wobble)
	_cache[key] = m
	return m


static func mat_ice() -> ShaderMaterial:
	return mat_water(Color(0.35, 0.65, 0.9), Color(0.6, 0.85, 1.0), Color(0.9, 0.98, 1.0), Vector3(0, 1, 0), 0.82, 0.15, 0.0)


static func mat_wind(tint := Color(0.78, 1.0, 0.9), speed := 6.0, lines := 6.0, axis := Vector3.UP, alpha := 0.85) -> ShaderMaterial:
	var key = "wind_%s_%.2f_%.2f_%s_%.2f" % [tint, speed, lines, axis, alpha]
	if _cache.has(key):
		return _cache[key]
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/vfx_wind.gdshader")
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("speed", speed)
	m.set_shader_parameter("lines", lines)
	m.set_shader_parameter("axis", axis)
	m.set_shader_parameter("alpha", alpha)
	_cache[key] = m
	return m


static func mat_spiral(line := Color(0.85, 0.95, 1.0), body := Color(0.2, 0.5, 1.0), arms := 5.0, twist := 3.0, speed := 6.0, intensity := 1.6, axis := Vector3.UP) -> ShaderMaterial:
	var key = "spiral_%s_%s_%.2f_%.2f_%.2f_%.2f_%s" % [line, body, arms, twist, speed, intensity, axis]
	if _cache.has(key):
		return _cache[key]
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/vfx_spiral.gdshader")
	m.set_shader_parameter("c_line", line)
	m.set_shader_parameter("c_body", body)
	m.set_shader_parameter("arms", arms)
	m.set_shader_parameter("twist", twist)
	m.set_shader_parameter("speed", speed)
	m.set_shader_parameter("intensity", intensity)
	m.set_shader_parameter("axis", axis)
	_cache[key] = m
	return m


static func mat_bolt(col: Color, intensity := 2.2) -> ShaderMaterial:
	var key = "bolt_%s_%.2f" % [col, intensity]
	if _cache.has(key):
		return _cache[key]
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/vfx_bolt.gdshader")
	m.set_shader_parameter("col", col)
	m.set_shader_parameter("intensity", intensity)
	_cache[key] = m
	return m


static func mat_trail(head: Color, mid: Color, tail: Color, additive := 0.0) -> ShaderMaterial:
	var key = "trail_%s_%s_%s_%.1f" % [head, mid, tail, additive]
	if _cache.has(key):
		return _cache[key]
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/vfx_trail.gdshader")
	m.set_shader_parameter("c_head", head)
	m.set_shader_parameter("c_mid", mid)
	m.set_shader_parameter("c_tail", tail)
	m.set_shader_parameter("additive", additive)
	_cache[key] = m
	return m


## Parçacık topağı malzemesi (cel duman/alev)
static func mat_puff(glow := 1.0, hot := 0.0, outline_col := Color(0.18, 0.12, 0.12), rough := 0.32, shade := 0.3, stretch := 1.0, outline := 0.07) -> ShaderMaterial:
	var key = "puff_%.2f_%.2f_%s_%.2f_%.2f_%.2f_%.2f" % [glow, hot, outline_col, rough, shade, stretch, outline]
	if _cache.has(key):
		return _cache[key]
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/vfx_puff.gdshader")
	m.set_shader_parameter("glow", glow)
	m.set_shader_parameter("hot_core", hot)
	m.set_shader_parameter("outline_col", outline_col)
	m.set_shader_parameter("rough", rough)
	m.set_shader_parameter("shade", shade)
	m.set_shader_parameter("stretch", stretch)
	m.set_shader_parameter("outline", outline)
	_cache[key] = m
	return m


## Elemente göre gövde malzemesi (mermi/ejderha/dalga/duvar gövdeleri)
static func element_mat(el: String, col: Color) -> Material:
	match el:
		"katon", "shakuton":
			return mat_fire("fire", 2.6, 2.4, 0.38, 1.35, 0.1, Vector3(0, 0, 1))
		"yoton", "bakuton":
			return mat_fire("lava", 1.6, 2.0, 0.3, 1.25, 0.08, Vector3(0, 0, 1))
		"suiton", "futton":
			return mat_water()
		"hyoton":
			return mat_ice()
		"fuuton", "jinton":
			return mat_wind(Color(0.8, 1.0, 0.92), 7.0, 6.0, Vector3(0, 0, 1))
		"raiton", "ranton":
			return mat_spiral(Color(1, 1, 1), col, 7.0, 6.0, 9.0, 2.0, Vector3(0, 0, 1))
		"doton", "mokuton", "jiton", "shoton":
			return Props.toon_color(col.darkened(0.05))
	var m = mat_spiral(col.lightened(0.5), col, 4.0, 2.0, 4.0, 1.4)
	return m


static func fire_preset_for(col: Color) -> String:
	if col.b > col.r and col.b > 0.5:
		return "blue"
	if col.v < 0.25:
		return "black"
	if col.g > col.r and col.g > 0.6:
		return "green"
	if col.b > 0.6 and col.r > 0.5 and col.g < 0.5:
		return "purple"
	return "fire"


# ================================================================== çekirdek kütleler
static func _sphere(r := 0.5, seg := 24, rings := 12) -> SphereMesh:
	var key = "sph_%.2f_%d" % [r, seg]
	if _cache.has(key):
		return _cache[key]
	var s = SphereMesh.new()
	s.radius = r; s.height = r * 2.0; s.radial_segments = seg; s.rings = rings
	_cache[key] = s
	return s


static func _mi(mesh: Mesh, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Katmanlı dönen ateş topu (Gōkakyū): sıcak çekirdek + iki türbülanslı alev kabuğu + kıvılcım
static func fireball(size := 1.0, preset := "fire") -> Node3D:
	size *= epic
	var root = Node3D.new()
	var outer = _mi(_sphere(0.5, 28, 14), mat_fire(preset, 2.6, 2.2, 0.5, 1.3, 0.16, Vector3(0, 0.4, 1)))
	outer.scale = Vector3.ONE * size * 1.15
	root.add_child(outer)
	var mid = _mi(_sphere(0.5, 24, 12), mat_fire(preset, -1.8, 3.0, 0.3, 1.45, 0.1, Vector3(0, -0.3, 1)))
	mid.scale = Vector3.ONE * size * 0.9
	root.add_child(mid)
	var core = _mi(_sphere(0.5, 16, 8), mat_fire(preset, 3.5, 1.4, 0.05, 1.7, 0.04))
	core.scale = Vector3.ONE * size * 0.55
	root.add_child(core)
	var tw = root.create_tween().set_loops()
	tw.tween_property(outer, "rotation:z", TAU, 1.6).from(0.0)
	var tw2 = root.create_tween().set_loops()
	tw2.tween_property(mid, "rotation:x", -TAU, 1.1).from(0.0)
	return root


## Su küresi (Suikōdan çekirdeği vb.)
static func water_ball(size := 1.0) -> Node3D:
	size *= epic
	var root = Node3D.new()
	var body = _mi(_sphere(0.5, 24, 12), mat_water(Color(0.05, 0.28, 0.78), Color(0.2, 0.55, 0.98), Color(0.62, 0.88, 1.0), Vector3(0, 0, 1), 0.9, 0.6, 0.1))
	body.scale = Vector3.ONE * size
	root.add_child(body)
	return root


## Rüzgar küresi: kırılan hava kabuğu + iç beyaz spiral
static func wind_ball(size := 1.0) -> Node3D:
	size *= epic
	var root = Node3D.new()
	var shell = _mi(_sphere(0.5, 24, 12), mat_wind(Color(0.8, 1.0, 0.92), 8.0, 5.0, Vector3(0, 0, 1)))
	shell.scale = Vector3.ONE * size
	root.add_child(shell)
	var sp = _mi(_sphere(0.5, 20, 10), mat_spiral(Color(1, 1, 1), Color(0.5, 0.9, 0.75), 4.0, 2.5, 8.0, 1.3, Vector3(0, 0, 1)))
	sp.scale = Vector3.ONE * size * 0.7
	root.add_child(sp)
	return root


## Rasengan tipi küre: parlak çekirdek + iki eksende dönen spiral kabuk + rüzgar halkaları
static func rasengan(size := 1.0, body := Color(0.15, 0.45, 1.0), line := Color(0.85, 0.95, 1.0)) -> Node3D:
	size *= epic
	var root = Node3D.new()
	var core = Projectile.energy_mesh(Color(1, 1, 1), line, size * 0.5, 14.0, 0.0, 2.0)
	root.add_child(core)
	var s1 = _mi(_sphere(0.5, 28, 14), mat_spiral(line, body, 6.0, 3.0, 7.0, 1.7, Vector3.UP))
	s1.scale = Vector3.ONE * size
	root.add_child(s1)
	var s2 = _mi(_sphere(0.5, 24, 12), mat_spiral(line, body * 0.6, 4.0, -2.0, -9.0, 1.2, Vector3(1, 0, 0)))
	s2.scale = Vector3.ONE * size * 1.12
	root.add_child(s2)
	if not _cache.has("ras_torus"):
		var tor = TorusMesh.new()
		tor.inner_radius = 0.46; tor.outer_radius = 0.5; tor.rings = 24; tor.ring_segments = 4
		_cache["ras_torus"] = tor
	for k in 3:
		var ring = _mi(_cache["ras_torus"], mat_bolt(body.lightened(0.3), 1.2))
		ring.scale = Vector3.ONE * size * (1.15 + k * 0.08)
		ring.rotation = Vector3(randf() * TAU, randf() * TAU, 0)
		root.add_child(ring)
		var tw = root.create_tween().set_loops()
		tw.tween_property(ring, "rotation:y", ring.rotation.y + TAU * (1 if k % 2 == 0 else -1), 0.35 + k * 0.1)
	return root


## Şimşek topu (Chidori): parlak çekirdek + kalın titreyen arklar
static func lightning_ball(size := 1.0, col := Color(0.45, 0.7, 1.0)) -> Node3D:
	size *= epic
	var root = Node3D.new()
	root.add_child(Projectile.energy_mesh(Color(1, 1, 1), col, size * 0.6, 16.0, 0.0, 2.2))
	var arcs = Arcs.new()
	arcs.color = col
	arcs.radius = size * 1.3
	arcs.count = 8
	arcs.width = 0.06 * maxf(1.0, size)
	root.add_child(arcs)
	return root


## Elemente göre mermi çekirdeği
static func element_core(el: String, col: Color, size: float) -> Node3D:
	match el:
		"katon", "shakuton":
			return fireball(size, fire_preset_for(col))
		"yoton", "bakuton":
			return fireball(size, "lava")
		"suiton", "futton", "hyoton":
			return water_ball(size)
		"fuuton", "jinton":
			return wind_ball(size)
		"raiton", "ranton":
			return lightning_ball(size * 0.8, col)
	var root = Node3D.new()
	root.add_child(Projectile.energy_mesh(col.lightened(0.5), col, size * epic, 4.0, 2.0, 2.2))
	return root


# ================================================================== tek seferlik efektler
static func _card(kind: int, col: Color, core := Color.WHITE, spikes := 8.0, billboard := true) -> MeshInstance3D:
	var q = QuadMesh.new()
	q.size = Vector2.ONE
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/vfx_fx2d.gdshader")
	m.set_shader_parameter("kind", kind)
	m.set_shader_parameter("col", col)
	m.set_shader_parameter("core", core)
	m.set_shader_parameter("spikes", spikes)
	m.set_shader_parameter("seed", randf() * 100.0)
	m.set_shader_parameter("billboard", billboard)
	var mi = MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Çarpma yıldızı: düzensiz sivri ışınlı anime flaş
static func star(pos: Vector3, col: Color, size := 2.0, dur := 0.18) -> void:
	size *= sqrt(epic)   # flaş kartı kamerayı kaplamasın
	if busy():
		return
	var mi = _card(0, col, Color(1, 1, 0.95), float(randi_range(7, 11)))
	scene().add_child(mi)
	_track(mi)
	mi.global_position = pos
	mi.scale = Vector3.ONE * size * 0.6
	var m: ShaderMaterial = mi.material_override
	var tw = mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * size, dur * 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(x: float): m.set_shader_parameter("t", x), 0.0, 1.0, dur)
	tw.chain().tween_callback(mi.queue_free)


## Şok dalgası halkası (yere paralel ya da kameraya dönük)
static func shockwave(pos: Vector3, col: Color, size := 6.0, dur := 0.4, flat := true, normal := Vector3.UP) -> void:
	size *= epic if flat else sqrt(epic)
	if busy():
		return
	var mi = _card(1, col, col.lightened(0.6), 8.0, not flat)
	scene().add_child(mi)
	_track(mi)
	mi.global_position = pos
	if flat:
		var n = normal.normalized()
		mi.global_transform = Transform3D(Basis(Quaternion(Vector3.BACK, n)), pos)
	mi.scale = Vector3.ONE * size
	var m: ShaderMaterial = mi.material_override
	var tw = mi.create_tween()
	tw.tween_method(func(x: float): m.set_shader_parameter("t", x), 0.05, 1.0, dur).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_callback(mi.queue_free)


## Zemin çatlağı / yanık izi
static func cracks(pos: Vector3, size := 4.0, col := Color(0.12, 0.09, 0.07, 0.9), dur := 6.0) -> void:
	size *= epic
	if busy():
		return
	var mi = _card(2, col, col, float(randi_range(6, 9)), false)
	scene().add_child(mi)
	_track(mi)
	var g = Game.ground_height(pos.x, pos.z) + 0.06
	mi.global_transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5).rotated(Vector3.UP, randf() * TAU), Vector3(pos.x, g, pos.z))
	mi.scale = Vector3.ONE * size
	var m: ShaderMaterial = mi.material_override
	m.set_shader_parameter("t", 0.0)
	var tw = mi.create_tween()
	tw.tween_interval(dur * 0.7)
	tw.tween_method(func(x: float): m.set_shader_parameter("t", x), 0.0, 1.0, dur * 0.3)
	tw.tween_callback(mi.queue_free)


## Cel parçacık topakları (alev/duman/toz/su) — FX.burst sarmalayıcısı
static func puffs(pos: Vector3, cfg: Dictionary) -> GPUParticles3D:
	if epic != 1.0:
		cfg = cfg.duplicate()
		var e = sqrt(epic)   # büyük ama kamerayı kaplamadan / aşırı örtüşmesiz (overdraw)
		cfg["size"] = float(cfg.get("size", 1.0)) * e
		cfg["radius"] = float(cfg.get("radius", 0.0)) * epic
		cfg["vmax"] = float(cfg.get("vmax", 3.0)) * sqrt(epic)
	cfg["cel"] = true
	return FX.burst(pos, cfg)


## Uçuşan kaya molozu (toprak duvarı, kırılma, ağır iniş)
static func debris(pos: Vector3, col := Color(0.5, 0.42, 0.32), n := 14, speed := 10.0, size := 0.5) -> void:
	size *= sqrt(epic)
	speed *= sqrt(epic)
	if busy():
		return
	var p = GPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = n
	p.lifetime = 1.3
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.6
	pm.direction = Vector3.UP
	pm.spread = 55.0
	pm.initial_velocity_min = speed * 0.5
	pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, -28, 0)
	pm.angular_velocity_min = -360; pm.angular_velocity_max = 360
	pm.scale_min = 0.5; pm.scale_max = 1.4
	pm.scale_curve = FX._curve([[0.0, 1.0], [0.8, 1.0], [1.0, 0.0]])
	p.process_material = pm
	var key = "rock_%s" % col
	if not _cache.has(key):
		var b = MB.new()
		b.add("sphere", Vector3.ZERO, Vector3(1.0, 0.7, 0.85), col, Vector3.ZERO, 5)
		_cache[key] = b.build(Props.toon())
	p.draw_pass_1 = _cache[key]
	p.transform = p.transform.scaled(Vector3.ONE * size)
	p.visibility_aabb = AABB(Vector3(-20, -20, -20), Vector3(40, 40, 40))
	scene().add_child(p)
	_track(p)
	p.global_position = pos
	p.scale = Vector3.ONE * size
	p.emitting = true
	p.finished.connect(p.queue_free)


## Kıvılcım / kor (ateş, patlama)
static func embers(pos: Vector3, col := Color(1.0, 0.6, 0.15), n := 24, speed := 10.0, life := 0.9) -> void:
	speed *= epic
	FX.burst(pos, {"amount": n, "life": life, "tex": FX.tex_spark, "size": 0.7, "vmin": speed * 0.4, "vmax": speed, "damp": 1.5,
		"gravity": Vector3(0, -6, 0), "colors": [Color(1, 1, 0.85, 1), col, Color(col.r, col.g * 0.5, 0.0, 0)]})


## Sıçrama tacı (su çarpması): yükselip dağılan su tacı + damlalar + köpük halkası
static func _splash(pos: Vector3, size := 2.0) -> void:
	if busy():
		return
	var g = Game.ground_height(pos.x, pos.z)
	var base = Vector3(pos.x, maxf(g, pos.y - size), pos.z)
	var cm = CylinderMesh.new()
	cm.top_radius = 1.0; cm.bottom_radius = 0.55; cm.height = 1.0; cm.radial_segments = 20; cm.rings = 1
	cm.cap_top = false; cm.cap_bottom = false
	var crown = _mi(cm, mat_water(Color(0.12, 0.4, 0.9), Color(0.35, 0.68, 1.0), Color(0.8, 0.95, 1.0), Vector3.UP, 0.85, 0.9, 0.12))
	scene().add_child(crown)
	_track(crown)
	crown.global_position = base + Vector3.UP * 0.4
	crown.scale = Vector3(size * 0.4, 0.2, size * 0.4)
	var tw = crown.create_tween()
	tw.tween_property(crown, "scale", Vector3(size * 1.3, size * 1.1, size * 1.3), 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(crown, "scale", Vector3(size * 1.6, 0.05, size * 1.6), 0.35).set_ease(Tween.EASE_IN)
	tw.tween_callback(crown.queue_free)
	puffs(base + Vector3.UP * size * 0.5, {"amount": int(18 * size), "life": 0.9, "size": 0.9 * size, "radius": size * 0.6, "vmin": 5, "vmax": 12 + size * 2,
		"dir": Vector3.UP, "spread": 55.0, "damp": 1.0, "gravity": Vector3(0, -22, 0), "glow": 1.05, "outline_col": Color(0.08, 0.2, 0.5),
		"colors": [Color(0.95, 0.99, 1, 1), Color(0.55, 0.82, 1, 1), Color(0.25, 0.55, 1, 0)]})
	shockwave(base + Vector3.UP * 0.1, Color(0.85, 0.95, 1.0), size * 4.0, 0.45)


## Cel duman halkası (patlamanın etrafında yayılan)
static func _smoke_ring(pos: Vector3, size := 3.0, col := Color(0.3, 0.27, 0.25)) -> void:
	var p = puffs(pos, {"amount": int(14 + size * 4), "life": 1.4, "size": 1.6 + size * 0.4, "radius": size * 0.3, "vmin": size * 2.0, "vmax": size * 3.2,
		"dir": Vector3.UP, "spread": 90.0, "damp": 3.0, "gravity": Vector3(0, 1.0, 0), "spin": 40.0, "outline_col": col.darkened(0.6),
		"colors": [col.lightened(0.2), col, Color(col.r, col.g, col.b, 0)], "scale_curve": [[0.0, 0.4], [0.3, 1.0], [1.0, 1.25]]})
	if p:
		var pm: ParticleProcessMaterial = p.process_material
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
		pm.emission_ring_axis = Vector3.UP
		pm.emission_ring_radius = size * 0.4
		pm.emission_ring_inner_radius = size * 0.3
		pm.emission_ring_height = 0.2
		pm.direction = Vector3(1, 0.15, 0)
		pm.spread = 180.0
		pm.flatness = 0.85


## Kalın şimşek: from→to dallanan, titreyen şerit (gökten düşen yıldırım, ışın)
static func bolt(from: Vector3, to: Vector3, col := Color(0.5, 0.75, 1.0), width := 0.25, dur := 0.25, branches := 3) -> Arcs:
	width *= epic
	var a = Arcs.new()
	a.color = col
	a.to_point = to - from
	a.count = branches
	a.width = width
	a.segs = maxi(6, int(from.distance_to(to) / 1.5))
	a.top_level = true
	scene().add_child(a)
	a.global_position = from
	if dur > 0.0:
		tree().create_timer(dur).timeout.connect(func():
			if is_instance_valid(a):
				a.queue_free())
	return a


## Kurdele iz: hedefi takip eder, hedef ölünce kuyruğu toplanıp kaybolur
static func trail(target: Node3D, width: float, head: Color, mid: Color, tail: Color, length := 18, additive := 0.0) -> VfxTrail:
	width *= epic
	var t = VfxTrail.new()
	t.target = target
	t.width = width
	t.max_pts = length
	t.material_override = mat_trail(head, mid, tail, additive)
	scene().add_child(t)
	return t


## Element imzalı iz
static func element_trail(target: Node3D, el: String, col: Color, width: float) -> VfxTrail:
	match el:
		"katon", "shakuton", "yoton", "bakuton":
			return trail(target, width, Color(1, 0.85, 0.3), Color(1, 0.45, 0.06), Color(0.75, 0.12, 0.03), 16, 0.3)
		"suiton", "futton", "hyoton":
			return trail(target, width, Color(0.95, 0.99, 1), Color(0.45, 0.75, 1.0), Color(0.12, 0.38, 0.9), 18, 0.1)
		"fuuton", "jinton":
			return trail(target, width * 0.7, Color(1, 1, 1), Color(0.85, 1.0, 0.92), Color(0.6, 0.95, 0.8), 14, 0.0)
		"raiton", "ranton":
			return trail(target, width * 0.6, Color(1, 1, 1), col.lightened(0.4), col, 12, 0.8)
	return trail(target, width, col.lightened(0.6), col, col.darkened(0.3), 14, 0.2)


## Ekran kenarından hız çizgileri (ağır vuruş, atılma)
static func screen_lines(dur := 0.35, strength := 1.0, col := Color(1, 1, 1)) -> void:
	if _speed_layer == null or not is_instance_valid(_speed_layer):
		_speed_layer = CanvasLayer.new()
		_speed_layer.layer = 5
		_speed_rect = ColorRect.new()
		_speed_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_speed_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m = ShaderMaterial.new()
		m.shader = load("res://shaders/vfx_speedlines.gdshader")
		_speed_rect.material = m
		_speed_layer.add_child(_speed_rect)
		scene().add_child(_speed_layer)
	var m: ShaderMaterial = _speed_rect.material
	m.set_shader_parameter("col", col)
	var tw = _speed_rect.create_tween()
	tw.tween_method(func(x: float): m.set_shader_parameter("strength", x), strength, 0.0, dur).set_ease(Tween.EASE_IN)


## Büyük anime patlaması: genişleyip aşınan alev kütlesi + cel alev topakları + koyu duman + kıvılcım + şok dalgaları
static func _explosion(pos: Vector3, s := 1.0, col := Color(1.0, 0.55, 0.15)) -> void:
	var preset = fire_preset_for(col)
	if not busy():
		var core = Node3D.new()
		var m = mat_fire(preset, 3.0, 2.0, 0.5, 1.45, 0.18, Vector3.UP, true)
		var sph = _mi(_sphere(0.5, 28, 14), m)
		core.add_child(sph)
		var inner = _mi(_sphere(0.5, 20, 10), mat_fire(preset, 4.0, 1.3, 0.05, 1.8, 0.05))
		inner.scale = Vector3.ONE * 0.6
		core.add_child(inner)
		scene().add_child(core)
		_track(core)
		core.global_position = pos
		core.scale = Vector3.ONE * 0.5 * s
		var tw = core.create_tween()
		tw.tween_property(core, "scale", Vector3.ONE * 5.5 * s, 0.18).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(inner, "scale", Vector3.ONE * 0.3, 0.45)
		tw.tween_property(core, "scale", Vector3.ONE * 6.3 * s, 0.25)   # ateş topu bir an asılı kalır
		tw.tween_method(func(x: float): m.set_shader_parameter("alpha_cut", x), 0.0, 1.1, 0.4)
		tw.parallel().tween_property(core, "scale", Vector3.ONE * 6.8 * s, 0.4)
		tw.parallel().tween_property(core, "global_position:y", pos.y + 1.5 * s, 0.4)
		tw.tween_callback(core.queue_free)
	var pr: Array = FIRE_PRESETS.get(preset, FIRE_PRESETS["fire"])
	# alev dilleri: sarı→turuncu→kırmızı bantlar (beyaz yok)
	puffs(pos, {"amount": int(18 * s) + 6, "life": 0.7, "size": 1.9 * s, "radius": 1.0 * s, "vmin": 6, "vmax": 13 * s,
		"damp": 6.0, "gravity": Vector3(0, 5, 0), "spin": 90.0, "glow": 1.1, "hot": 0.3, "outline_col": pr[4],
		"colors": [pr[1], pr[2], pr[3], Color(pr[4].r, pr[4].g, pr[4].b, 0)], "scale_curve": [[0.0, 0.5], [0.25, 1.1], [1.0, 0.7]]})
	# duman: daha küçük, koyu gri-kahve ve ateş sönerken gelir
	var smoke_at = pos + Vector3.UP * s * 1.6
	scene().get_tree().create_timer(0.3).timeout.connect(func():
		puffs(smoke_at, {"amount": int(8 * s) + 3, "life": 1.5, "size": 2.0 * s, "radius": 1.3 * s, "vmin": 1.5, "vmax": 4 * s,
			"damp": 2.0, "gravity": Vector3(0, 3.0, 0), "spin": 30.0, "outline_col": Color(0.06, 0.05, 0.04), "shade": 0.35, "glow": 1.0,
			"colors": [Color(0.26, 0.21, 0.18, 0.0), Color(0.24, 0.2, 0.17, 0.95), Color(0.32, 0.28, 0.25, 0.7), Color(0.35, 0.31, 0.28, 0)]}))
	embers(pos, pr[2], int(28 * s), 22.0 * s, 1.0)
	star(pos, pr[1], 4.5 * s, 0.2)
	var g = Vector3(pos.x, Game.ground_height(pos.x, pos.z) + 0.12, pos.z)
	if pos.y - g.y < 3.0 * s:
		shockwave(g, pr[2].lightened(0.2), 14.0 * s, 0.5)
		smoke_ring(g + Vector3.UP * 0.3, 2.5 * s, Color(0.36, 0.32, 0.3))
		cracks(g, 3.5 * s, Color(0.1, 0.06, 0.04, 0.85))
	shockwave(pos, Color(1, 0.95, 0.8), 8.0 * s, 0.25, false)
	FX.light(pos, pr[1], 12.0 * s, 25.0 * s, 0.45)
	if Game.world:
		Game.world.env.add_shake(0.8 * s)
		Game.world.env.screen_flash(0.05 * s)
	if s >= 1.2:
		screen_lines(0.35, minf(1.0, 0.5 * s))
	Sfx.play("boom", pos)


## Amaterasu kara alevi: hedefi saran, yukarı yalayan sivri alev dilleri (iç siyah, kenar koyu mor)
static func black_flames(size := 1.0) -> Node3D:
	size *= epic
	var root = Node3D.new()
	var n = 7
	for i in n:
		var m = mat_fire("black", 2.6 + randf() * 1.2, 2.6, 0.55, 1.0, 0.2, Vector3.UP, true)
		m.set_shader_parameter("tongue", 0.45 + randf() * 0.35)
		var t = _mi(_sphere(0.5, 16, 10), m)
		var a = TAU * i / n + randf() * 0.4
		var r = 0.0 if i == 0 else 0.45
		t.position = Vector3(cos(a) * r, 0.2 + randf() * 0.4, sin(a) * r) * size
		t.scale = Vector3(1.0, 1.4 + randf() * 0.7, 1.0) * size * (1.1 if i == 0 else 0.75)
		root.add_child(t)
		var tw = t.create_tween().set_loops()
		var s0 = t.scale
		tw.tween_property(t, "scale", s0 * Vector3(0.9, 1.15, 0.9), 0.22 + randf() * 0.15)
		tw.tween_property(t, "scale", s0, 0.22 + randf() * 0.15)
	return root


## Yerde için için yanan kara alev lekesi
static func _black_smolder(pos: Vector3, size := 2.0, dur := 6.0) -> void:
	var m = mat_fire("black", 1.6, 3.0, 0.6, 1.0, 0.1, Vector3.UP, true)
	m.set_shader_parameter("tongue", 0.6)
	var mi = _mi(_sphere(0.5, 20, 8), m)
	scene().add_child(mi)
	mi.global_position = Vector3(pos.x, Game.ground_height(pos.x, pos.z), pos.z)
	mi.scale = Vector3(size * 2.0, size * 0.5, size * 2.0)
	cracks(pos, size * 2.2, Color(0.04, 0.0, 0.05, 0.95), dur + 2.0)
	var tw = mi.create_tween()
	tw.tween_interval(dur)
	tw.tween_method(func(x: float): m.set_shader_parameter("alpha_cut", x), 0.0, 1.1, 0.8)
	tw.tween_callback(mi.queue_free)


## Yükleme ekranında tüm VFX shader/parçacık türlerini bir kez ekran dışı çizdirir (ilk yayında takılma olmasın).
## Ana dünyayı paylaşan küçük SubViewport'un kamerası, dünyanın uzak bir köşesinde oluşturulan efektleri görür.
static func warmup() -> void:
	var host = scene()
	var W = Vector3(0, 2600, 0)
	var sv = SubViewport.new()
	sv.size = Vector2i(320, 180)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.world_3d = host.get_viewport().world_3d
	host.add_child(sv)
	var cam = Camera3D.new()
	sv.add_child(cam)
	cam.global_position = W + Vector3(0, 2, 16)
	cam.look_at(W)
	cam.current = true
	var sl = ColorRect.new()   # 2B hız çizgisi shader'ı
	sl.size = Vector2(320, 180)
	var slm = ShaderMaterial.new()
	slm.shader = load("res://shaders/vfx_speedlines.gdshader")
	slm.set_shader_parameter("strength", 0.5)
	sl.material = slm
	sv.add_child(sl)
	var anchor = Node3D.new()
	host.add_child(anchor)
	anchor.global_position = W
	var x = -8.0
	var put = func(n: Node3D) -> void:
		anchor.add_child(n)
		n.position = Vector3(x, 0, 0)
		x += 1.6
	for p in FIRE_PRESETS:
		put.call(fireball(1.0, p))
	put.call(black_flames(0.6))
	put.call(water_ball(1.0))
	put.call(wind_ball(1.0))
	put.call(rasengan(1.0))
	put.call(lightning_ball(1.0))
	for el in ["hyoton", "doton", "mokuton", "fuuton", "suiton", "raiton", ""]:
		put.call(element_core(el, Color(0.5, 0.7, 1.0), 0.8))
	for v in ["dragon", "shark", "bird", "beast", "needles", "disc", ""]:
		put.call(JutsuEngine.shape_mesh(v, Color(1, 0.5, 0.1), 0.6, "katon"))
	put.call(VfxSerpent.dragon_head(mat_water(), 0.6))
	put.call(Projectile.energy_mesh(Color.WHITE, Color(0.3, 0.6, 1.0), 0.8))
	for k in 3:
		var cd = _card(k, Color(1, 0.6, 0.2), Color.WHITE, 8.0, k != 2)
		put.call(cd)
	var mover = Node3D.new()
	put.call(mover)
	trail(mover, 0.8, Color.WHITE, Color(1, 0.5, 0.1), Color(1, 0.2, 0, 0), 10, 0.0)
	trail(mover, 0.8, Color.WHITE, Color(0.5, 0.8, 1.0), Color(0, 0.3, 1, 0), 10, 1.0)
	var ar = Arcs.new()
	ar.color = Color(0.6, 0.8, 1.0)
	put.call(ar)
	bolt(W, W + Vector3(2, 3, 0), Color(0.6, 0.8, 1.0), 0.2, 0.3, 2)
	# parçacık süreç malzemesi türleri
	FX.burst(W, {"amount": 4, "life": 0.4})
	FX.burst(W, {"amount": 4, "life": 0.4, "tex": FX.tex_spark, "add": true})
	puffs(W, {"amount": 4, "life": 0.4, "glow": 1.1, "hot": 0.3, "colors": [Color(1, 0.7, 0.1), Color(1, 0.3, 0, 0)]})
	FX.smoke_puff(W, 0.5, 4)
	FX.dust(W, 0.5)
	FX.aura(anchor, Color(0.5, 0.8, 1.0), 0.6, Vector3.ZERO, 0.5)
	debris(W, Color(0.5, 0.4, 0.3), 4, 4.0, 0.3)
	embers(W, Color(1, 0.6, 0.2), 4, 4.0, 0.4)
	splash(W, 0.6)
	smoke_ring(W, 1.0)
	explosion(W + Vector3(4, 0, 0), 0.6)
	black_smolder(W + Vector3(-4, 0, 0), 0.6, 0.3)
	for i in 8:
		mover.position.y = i * 0.3
		await tree().process_frame
	anchor.queue_free()
	sv.queue_free()


static func splash(pos: Vector3, size := 2.0) -> void:
	var ep = epic
	epic = 1.0
	_splash(pos, size * sqrt(ep))
	epic = ep


static func smoke_ring(pos: Vector3, size := 3.0, col := Color(0.3, 0.27, 0.25)) -> void:
	var ep = epic
	epic = 1.0
	_smoke_ring(pos, size * sqrt(ep), col)
	epic = ep


static func explosion(pos: Vector3, s := 1.0, col := Color(1.0, 0.55, 0.15)) -> void:
	var ep = epic
	epic = 1.0
	_explosion(pos, s * ep, col)
	epic = ep


static func black_smolder(pos: Vector3, size := 2.0, dur := 6.0) -> void:
	var ep = epic
	epic = 1.0
	_black_smolder(pos, size * ep, dur)
	epic = ep


# ================================================================== destan anları (rütbe ölçekli)
## Bırakış anı (her jutsu): el/ağızda flaş, ayakta şok halkası ve toz; B+ oyuncu yayınında yavaş çekim, hız çizgileri, kamera geri çekilmesi
static func release(c: Node3D, origin: Vector3, col: Color, g: float, tier: int, big := true) -> void:
	var ep = epic
	epic = 1.0
	var feet = Vector3(c.global_position.x, Game.ground_height(c.global_position.x, c.global_position.z) + 0.08, c.global_position.z)
	star(origin, col.lightened(0.35), 1.2 + 1.1 * g, 0.14)
	shockwave(feet, col.lightened(0.2), 3.0 + 3.5 * g, 0.35)
	if tier >= 4:
		smoke_ring(feet, 0.5 + 0.2 * g, Color(0.74, 0.68, 0.6))
	if tier >= 3:
		shockwave(origin, Color(1, 1, 1), 2.0 + 2.0 * g, 0.2, false)
	var is_pl = c is Player
	if Game.world:
		Game.world.env.add_shake((0.08 + 0.1 * tier) * (1.0 if is_pl else 0.5))
		if tier >= 4 and is_pl:
			Game.world.env.screen_flash(0.05 * tier)
	if is_pl and big and tier >= 3:
		screen_lines(0.25 + 0.08 * tier, 0.35 + 0.12 * tier, col.lightened(0.6))
		slowmo(0.35, 0.08 + 0.03 * tier)
		cinematic(c, 1.2 + tier * 0.8, 0.3 + 0.1 * tier)
	epic = ep


## Kısa yavaş çekim (gerçek zamanla ölçülür; Sharingan vb. başka yavaşlatma varsa dokunmaz)
static func slowmo(scale_: float, real_dur: float) -> void:
	if Combat.base_time_scale < 0.99:
		return
	Combat.base_time_scale = scale_
	Engine.time_scale = scale_
	tree().create_timer(real_dur, true, false, true).timeout.connect(func():
		if absf(Combat.base_time_scale - scale_) < 0.001:
			Combat.base_time_scale = 1.0)


## Sinematik an: oyuncu kamerası kısa süre geri çekilir (rahatsız etmez, kendiliğinden döner)
static func cinematic(c: Node3D, extra: float, hold: float) -> void:
	if not "cam_dist" in c or c.has_meta("cine"):
		return
	var base: float = c.cam_dist
	c.set_meta("cine", true)
	var tw = c.create_tween().set_ignore_time_scale(true)
	tw.tween_property(c, "cam_dist", base + extra, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold)
	tw.tween_property(c, "cam_dist", base, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func(): c.remove_meta("cine"))


## Hazırlık (mühürler biterken): içe çöken halka + toplanan kıvılcımlar + ayakta yükselen chakra
static func gather(pos: Vector3, col: Color, g: float) -> void:
	if busy():
		return
	var mi = _card(1, col, col.lightened(0.6), 8.0, true)
	scene().add_child(mi)
	_track(mi)
	mi.global_position = pos
	mi.scale = Vector3.ONE * 3.2 * g
	var m: ShaderMaterial = mi.material_override
	var tw = mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE * 0.3, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.parallel().tween_method(func(x: float): m.set_shader_parameter("t", x), 0.6, 0.15, 0.25)
	tw.tween_callback(mi.queue_free)
	FX.burst(pos, {"amount": int(10 + 6 * g), "life": 0.3, "tex": FX.tex_spark, "add": true, "size": 0.35 * g, "radius": 1.4 * g, "vmin": 0.5, "vmax": 2.0,
		"gravity": Vector3.ZERO, "colors": [Color(1, 1, 1, 1), col, Color(col.r, col.g, col.b, 0)]})


## Çarpma sonrası kalıcı iz (rütbe ölçekli): yerde alev dilleri, su birikintisi, buz kristali, moloz, artık şimşek
static func linger(pos: Vector3, el: String, col: Color, g: float, dur := 3.0) -> void:
	if busy() or g < 1.1:
		return
	var gp = Vector3(pos.x, Game.ground_height(pos.x, pos.z), pos.z)
	if pos.y - gp.y > 4.0:
		return
	var root = Node3D.new()
	scene().add_child(root)
	_track(root)
	root.global_position = gp
	var n = 2 + int(g * 1.5)
	match el:
		"katon", "yoton", "shakuton", "bakuton":
			var pr = "lava" if el == "yoton" else fire_preset_for(col)
			for k in n:
				var m = mat_fire(pr, 2.6, 2.4, 0.5, 1.15, 0.15, Vector3.UP, true)
				m.set_shader_parameter("tongue", 0.7)
				var t = _mi(_sphere(0.5, 14, 8), m)
				var a = randf() * TAU
				t.position = Vector3(cos(a), 0.1, sin(a)) * randf_range(0.3, 1.6) * g
				t.scale = Vector3(1.0, 1.7, 1.0) * randf_range(0.7, 1.2) * g * 0.7
				root.add_child(t)
				var tw = t.create_tween()
				tw.tween_interval(dur * randf_range(0.6, 1.0))
				tw.tween_method(func(x: float): m.set_shader_parameter("alpha_cut", x), 0.0, 1.1, 0.6)
			cracks(gp, 2.2 * g, Color(0.08, 0.04, 0.02, 0.9), dur + 3.0)
		"suiton", "futton":
			var pd = _mi(_sphere(0.5, 20, 6), mat_water(Color(0.05, 0.28, 0.78), Color(0.2, 0.55, 0.98), Color(0.7, 0.92, 1.0), Vector3.UP, 0.75, 0.6, 0.02))
			pd.scale = Vector3(3.0 * g, 0.08, 3.0 * g)
			root.add_child(pd)
		"hyoton":
			for k in n:
				var sh = _mi(_sphere(0.5, 6, 4), mat_ice())
				var a = randf() * TAU
				sh.position = Vector3(cos(a), 0.3, sin(a)) * randf_range(0.4, 1.5) * g
				sh.scale = Vector3(0.35, randf_range(1.0, 1.8), 0.35) * g
				sh.rotation = Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4))
				root.add_child(sh)
		"doton", "mokuton", "jiton", "shoton":
			var rm = Props.toon_color(col.darkened(0.25) if el != "shoton" else col)
			for k in n:
				var rk = _mi(_sphere(0.5, 7, 5), rm)
				var a = randf() * TAU
				rk.position = Vector3(cos(a), 0.15, sin(a)) * randf_range(0.5, 1.8) * g
				rk.scale = Vector3(randf_range(0.6, 1.1), randf_range(0.4, 0.8), randf_range(0.6, 1.0)) * g * 0.8
				rk.rotation = Vector3(randf(), randf(), randf())
				root.add_child(rk)
			cracks(gp, 2.6 * g, Color(0.12, 0.09, 0.07, 0.9), dur + 3.0)
		"raiton", "ranton":
			var ar = Arcs.new()
			ar.color = col
			ar.radius = 1.4 * g
			ar.count = 4
			ar.width = 0.05 * g
			ar.position = Vector3.UP * 0.3
			root.add_child(ar)
			dur = 1.2
			cracks(gp, 2.0 * g, Color(0.08, 0.08, 0.12, 0.9), 4.0)
		_:
			cracks(gp, 2.0 * g, Color(0.12, 0.09, 0.07, 0.85), dur + 2.0)
	var tw2 = root.create_tween()
	tw2.tween_interval(dur + 0.6)
	tw2.tween_property(root, "scale", Vector3(1, 0.05, 1), 0.4)
	tw2.tween_callback(root.queue_free)
