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


## Anime lav malzemesi: "molten" = kızıl taban + akan sarı-turuncu erimiş hücreler (lav seli/duvarı),
## "rock" = turuncu erimiş kaya + koyu kabuk benekleri, kızıl kenar (lav kayaları/mermileri). world: tüp gövdeler için dünya uzayı
## Lav kayası: pürüzlü erimiş kaya topu (turuncu üstüne koyu kabuk benekleri, kızıl kenar) — ateş topu değil
## Kara şimşek (Kuroi Kaminari): eklemeli değil — opak siyah zikzak bant + içinde ince beyaz çekirdek,
## yanlarda beyaz çatırtı dalları (siyah, eklemeli bolt'ta görünmüyor, koyu mavi kalıyordu)
static func black_bolt(from: Vector3, to: Vector3, width := 0.3, dur := 0.4, branches := 3) -> void:
	var sc = scene()
	if sc == null:
		return
	var pts = [from]
	var n = 8
	var d = to - from
	var side = d.cross(Vector3.UP).normalized()
	if side.length() < 0.1:
		side = Vector3.RIGHT
	var up2 = side.cross(d.normalized())
	for k in range(1, n):
		var t = float(k) / n
		pts.append(from + d * t + (side * randf_range(-1, 1) + up2 * randf_range(-1, 1)) * d.length() * 0.05)
	pts.append(to)
	var bm = StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.albedo_color = Color(0.02, 0.02, 0.03)
	var wm = StandardMaterial3D.new()
	wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wm.albedo_color = Color(1, 1, 1)
	wm.cull_mode = BaseMaterial3D.CULL_FRONT   # ters kabuk: siyah bandın çevresinde beyaz kontur (anime kara şimşek)
	var root = Node3D.new()
	sc.add_child(root)
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		for layer in [[width * 0.6, bm], [width * 0.6 + 0.07, wm]]:
			var mi = MeshInstance3D.new()
			var cm = CylinderMesh.new()
			cm.top_radius = layer[0] * 0.5
			cm.bottom_radius = layer[0] * 0.5
			cm.height = a.distance_to(b) + layer[0] * 0.4
			cm.radial_segments = 5
			cm.rings = 1
			mi.mesh = cm
			mi.material_override = layer[1]
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(mi)
			var dd = (b - a).normalized()
			var bas = Basis(Quaternion(Vector3.UP, dd)) if absf(dd.dot(Vector3.UP)) < 0.999 else Basis()
			mi.global_transform = Transform3D(bas, (a + b) * 0.5)
	for k in branches:
		var p: Vector3 = pts[randi_range(1, pts.size() - 2)]
		bolt(p, p + (side * randf_range(-1, 1) + up2 * randf_range(-0.5, 1)).normalized() * randf_range(0.8, 2.0) * maxf(1.0, width * 3.0), Color(1, 1, 1), width * 0.18, dur * 0.6, 1)
	var tw = root.create_tween()
	tw.tween_interval(dur * 0.7)
	tw.tween_property(root, "scale", Vector3(0.2, 1, 0.2), dur * 0.3)
	tw.tween_callback(root.queue_free)


static func lava_ball(size := 1.0) -> Node3D:
	var root = Node3D.new()
	var b = MB.new()
	b.add("boulder", Vector3.ZERO, Vector3.ONE * size, Color.WHITE, Vector3.ZERO, randi() % 6)
	var mi = _mi(b.build(null), lava_mat("rock"))
	root.add_child(mi)
	var tw = root.create_tween().set_loops()
	tw.tween_property(mi, "rotation", Vector3(TAU, TAU * 0.5, 0), 1.6).from(Vector3.ZERO)
	return root


static func lava_mat(kind := "molten", world := false) -> ShaderMaterial:
	var key = "lava_%s_%s" % [kind, world]
	if _cache.has(key):
		return _cache[key]
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/lava.gdshader")
	if kind == "mei":   # Mei'nin aşındırıcı lav çamuru: bej, parlak, yapışkan sıvı
		m.set_shader_parameter("base_col", Color(0.84, 0.72, 0.46))
		m.set_shader_parameter("spot_col", Color(0.94, 0.86, 0.62))
		m.set_shader_parameter("hot_col", Color(1.0, 0.97, 0.86))
		m.set_shader_parameter("rim_col", Color(0.98, 0.92, 0.74))
		m.set_shader_parameter("line_col", Color(0.42, 0.3, 0.15))
		m.set_shader_parameter("spot_thresh", 0.6)
		m.set_shader_parameter("flow", 0.6)
	elif kind == "oil":   # kurbağa yağı: koyu amber yapışkan
		m.set_shader_parameter("base_col", Color(0.74, 0.5, 0.12))
		m.set_shader_parameter("spot_col", Color(0.9, 0.7, 0.28))
		m.set_shader_parameter("hot_col", Color(1.0, 0.9, 0.6))
		m.set_shader_parameter("rim_col", Color(1.0, 0.84, 0.48))
		m.set_shader_parameter("line_col", Color(0.32, 0.18, 0.04))
		m.set_shader_parameter("spot_thresh", 0.6)
		m.set_shader_parameter("flow", 0.6)
	elif kind == "rock":
		m.set_shader_parameter("base_col", Color(1.0, 0.58, 0.14))
		m.set_shader_parameter("spot_col", Color(0.42, 0.12, 0.04))
		m.set_shader_parameter("hot_col", Color(0.25, 0.06, 0.03))
		m.set_shader_parameter("rim_col", Color(0.95, 0.15, 0.08))
		m.set_shader_parameter("spot_thresh", 0.58)
		m.set_shader_parameter("cell_scale", 3.2)
		m.set_shader_parameter("flow", 0.1)
	if kind == "molten":
		# kullanıcı tarifi + anime lav: sarımsı-turuncu parlayan yapışkan akış, içinde koyu kırık toprak/kaya parçaları
		m.set_shader_parameter("base_col", Color(1.0, 0.45, 0.06))
		m.set_shader_parameter("spot_col", Color(1.0, 0.72, 0.18))
		m.set_shader_parameter("hot_col", Color(1.0, 0.93, 0.55))
		m.set_shader_parameter("rim_col", Color(1.0, 0.82, 0.35))
		m.set_shader_parameter("line_col", Color(0.4, 0.08, 0.02))
		m.set_shader_parameter("crust_thresh", 0.3)
		m.set_shader_parameter("cell_scale", 2.0)
	m.set_shader_parameter("world_space", world)
	_cache[key] = m
	return m


static func mat_water(deep := Color(0.05, 0.28, 0.78), mid := Color(0.2, 0.55, 0.98), light := Color(0.62, 0.88, 1.0), flow := Vector3(0, 0, 1), alpha := 0.88, foam := 0.5, wobble := 0.06) -> ShaderMaterial:
	var key = "water_%s_%s_%s_%s_%.2f_%.2f_%.2f" % [deep, mid, light, flow, alpha, foam, wobble]
	if _cache.has(key):
		return _cache[key]
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/vfx_water.gdshader")
	# Naruto Storm su paleti: mavi su ise doygun koyu mavi yerine soluk camgöbeği (lav/yağ/çamur renklerine dokunma)
	if mid.b > mid.r + 0.2:
		deep = deep.lerp(Color(0.36, 0.62, 0.84), 0.75)
		mid = mid.lerp(Color(0.55, 0.8, 0.95), 0.75)
		light = light.lerp(Color(0.84, 0.95, 1.0), 0.75)
	m.set_shader_parameter("c_deep", deep)
	m.set_shader_parameter("c_mid", mid)
	m.set_shader_parameter("c_light", light)
	m.set_shader_parameter("flow", flow)
	m.set_shader_parameter("alpha", alpha)
	m.set_shader_parameter("foam", foam)
	m.set_shader_parameter("wobble", wobble)
	_cache[key] = m
	return m


## Hyōton buzu (anime Haku): akışkan değil — keskin yüzeyli, soluk mavi-beyaz, yarı saydam kristal, beyaz kenar parıltısı
static func mat_ice() -> Material:
	if _cache.has("mat_ice"):
		return _cache["mat_ice"]
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(0.82, 0.93, 1.0, 0.72)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic = 0.3
	m.roughness = 0.04
	m.emission_enabled = true
	m.emission = Color(0.55, 0.75, 0.95) * 0.35
	m.rim_enabled = true
	m.rim = 1.0
	m.rim_tint = 0.2
	_cache["mat_ice"] = m
	return m


## Futton (Mei'nin asidi / Han'ın buharı): yoğun beyaz-gri buhar, hafif mor asit tonu; su değil
static func mat_steam(acid := false) -> Material:
	var key = "mat_steam_%s" % acid
	if _cache.has(key):
		return _cache[key]
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.82, 0.76, 0.88, 0.5) if acid else Color(0.95, 0.95, 0.96, 0.5)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cache[key] = m
	return m


## Jinton: yarı saydam beyaz ışık geometrisi (küp/koni/silindir), içi parlak
static func mat_dust() -> Material:
	if _cache.has("mat_dust"):
		return _cache["mat_dust"]
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(0.9, 0.95, 1.0, 0.4)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cache["mat_dust"] = m
	return m


## Ranton: beyaz-sıcak çekirdekli, mavi kenarlı lazer ışığı (şimşek dalı yok)
static func mat_storm() -> Material:
	if _cache.has("mat_storm"):
		return _cache["mat_storm"]
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.92, 0.97, 1.0)
	m.emission_enabled = true
	m.emission = Color(0.55, 0.8, 1.0)
	m.rim_enabled = true
	m.rim = 1.0
	_cache["mat_storm"] = m
	return m


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
		"katon":
			return mat_fire("fire", 2.6, 2.4, 0.38, 1.35, 0.1, Vector3(0, 0, 1))
		"shakuton":   # her doğa kendi görünümünde: yumuşak pembe-beyaz kavurucu ışık
			var sm = StandardMaterial3D.new()
			sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			sm.albedo_color = Color(1.0, 0.7, 0.72, 0.8)
			return sm
		"yoton":
			return lava_mat("molten")
		"bakuton":
			return Props.toon_color(Color(0.95, 0.94, 0.9))   # beyaz patlayıcı kil
		"suiton":
			return mat_water()
		"futton":
			return mat_steam(true)
		"hyoton":
			return mat_ice()
		"fuuton":
			return mat_wind(Color(0.8, 1.0, 0.92), 7.0, 6.0, Vector3(0, 0, 1))
		"jinton":
			return mat_dust()
		"raiton":
			return mat_spiral(Color(1, 1, 1), col, 7.0, 6.0, 9.0, 2.0, Vector3(0, 0, 1))
		"ranton":
			return mat_storm()
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


## Blender'da modellenmiş efekt meshi (godot/assets/vfx/<ad>.glb): ilk meshi önbellekten
static func asset(name: String) -> Mesh:
	var key = "asset_" + name
	if _cache.has(key):
		return _cache[key]
	var m: Mesh = null
	var path = "res://assets/vfx/%s.glb" % name
	if ResourceLoader.exists(path):
		var n: Node = (load(path) as PackedScene).instantiate()
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			m = (mi as MeshInstance3D).mesh
			break
		n.free()
	_cache[key] = m
	return m


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
	# saydam küre kabuk yapay duruyordu: dönen akım çizgileri + soluk çekirdek (WindFX)
	var root = Node3D.new()
	WindFX.bullet(root, size)
	return root


## Rasengan tipi küre: parlak çekirdek + iki eksende dönen spiral kabuk + rüzgar halkaları
static func rasengan(size := 1.0, body := Color(0.15, 0.45, 1.0), line := Color(0.85, 0.95, 1.0)) -> Node3D:
	size *= epic
	var root = Node3D.new()
	var core = Projectile.energy_mesh(Color(0.9, 0.97, 1.0), line, size * 0.24, 14.0, 0.0, 1.2)   # küçük parlak göbek (tüm küreyi beyaza boğmasın)
	root.add_child(core)
	var s1 = _mi(_sphere(0.5, 28, 14), mat_spiral(line, body, 6.0, 3.0, 7.0, 1.15, Vector3.UP))
	s1.scale = Vector3.ONE * size
	root.add_child(s1)
	var s2 = _mi(_sphere(0.5, 24, 12), mat_spiral(line, body * 0.6, 4.0, -2.0, -9.0, 0.9, Vector3(1, 0, 0)))
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
	# Blender girdabı: kürenin çevresinde hızla dönen üç kollu chakra sarmalı (anime Rasengan'ın dış rüzgârı)
	var vm = asset("vortex")
	if vm:
		for k in 2:
			var vx = _mi(vm, mat_spiral(line, body.lightened(0.2), 3.0, 2.0, 9.0, 1.3, Vector3.UP))
			vx.scale = Vector3.ONE * size * (0.75 + k * 0.12)
			vx.position = Vector3(0, -size * 0.38, 0)
			vx.rotation = Vector3(k * 1.2, 0, k * 0.6)
			root.add_child(vx)
			var vt = root.create_tween().set_loops()
			vt.tween_property(vx, "rotation:y", TAU * (1 if k == 0 else -1), 0.22 + k * 0.08).as_relative()
	return root


## Şimşek topu (Chidori): parlak çekirdek + kalın titreyen arklar
static func lightning_ball(size := 1.0, col := Color(0.45, 0.7, 1.0)) -> Node3D:
	size *= epic
	# anime şimşeği: içi dolu küre yok — titreyen beyaz parıltı çekirdeği + mavi hale + çatırdayan dallı arklar + cıvıldayan kıvılcımlar
	var root = Node3D.new()
	for k in 2:
		var g = MeshInstance3D.new()
		var q = QuadMesh.new()
		q.size = Vector2.ONE * size * (0.9 if k == 0 else 2.6)
		var m = StandardMaterial3D.new()
		m.albedo_texture = FX.tex_soft
		m.albedo_color = Color(1, 1, 1, 0.95) if k == 0 else Color(col.r, col.g, col.b, 0.55)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		q.material = m
		g.mesh = q
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(g)
		var fl = g.create_tween().set_loops()
		fl.tween_property(g, "scale", Vector3.ONE * (1.25 if k == 0 else 1.12), 0.05)
		fl.tween_property(g, "scale", Vector3.ONE * (0.8 if k == 0 else 0.92), 0.04)
	var sp = FX.burst(Vector3.ZERO, {"parent": root, "local": true, "amount": int(10 + size * 8), "life": 0.22, "tex": FX.tex_spark, "size": 0.5 + size * 0.25,
		"vmin": 3.0 * size, "vmax": 7.0 * size, "spread": 180.0, "radius": size * 0.3, "explosive": 0.0, "damp": 3.0,
		"colors": [Color(1, 1, 1, 1), col.lightened(0.4), Color(col.r, col.g, col.b, 0)]})
	if sp:
		sp.one_shot = false
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
		"shakuton":
			return scorch_orb(size)
		"katon":
			return fireball(size, fire_preset_for(col))
		"yoton":
			return lava_ball(size)
		"bakuton":
			return clay_orb(size)
		"suiton":
			return water_ball(size)
		"futton":
			return steam_orb(size)
		"hyoton":
			return ice_orb(size)
		"fuuton":
			return wind_ball(size)
		"jinton":
			return dust_cube(size)
		"raiton":
			return lightning_ball(size * 0.8, col)
		"ranton":
			return storm_orb(size)
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
	# Blender şok halkası: yerden kalkan kıvrık kenarlı 3B dalga (düz kartın üstünde hacim)
	var rm = asset("shock_ring")
	if rm and flat and size > 2.0:
		var ring = _mi(rm, mat_wind(col.lightened(0.3), 4.0, 4.0, Vector3.UP, 0.85))
		scene().add_child(ring)
		_track(ring)
		ring.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, normal.normalized())), pos)
		ring.scale = Vector3(size * 0.15, size * 0.12, size * 0.15)
		var rt = ring.create_tween().set_parallel(true)
		rt.tween_property(ring, "scale", Vector3(size * 0.55, size * 0.02, size * 0.55), dur * 1.1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		rt.chain().tween_callback(ring.queue_free)


## Zemin çatlağı / yanık izi
static func cracks(pos: Vector3, size := 4.0, col := Color(0.12, 0.09, 0.07, 0.9), dur := 6.0, zone := true) -> void:
	size *= epic
	if zone and size >= 1.5:   # yarık zemin: üstünden geçen yavaşlar (3-5 sn)
		GroundFX.add(pos, "cracked", size * 0.6, clampf(dur, 3.0, 5.0))
	if busy():
		return
	var mi = _card(2, col, col, float(randi_range(6, 9)), false)
	scene().add_child(mi)
	_track(mi)
	var g = Game.jutsu_floor(pos.x, pos.z) + 0.06 + size * 0.04   # büyük izi engebeli zemin kesmesin
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
	if cfg.get("water", false):
		return water_chunks(pos, cfg)
	cfg["cel"] = true
	return FX.burst(pos, cfg)


## Storm su parçaları: tırtıklı soluk camgöbeği su dokusu (FX.tex_water), kontur yok; renk rampası yalnız alfa/parlaklık taşır
static func water_chunks(pos: Vector3, cfg: Dictionary) -> GPUParticles3D:
	# 3B su kütleleri (düz sprite karton gibi duruyordu): gövdeli su damlaları/öbekleri yay çizip düşer
	var n = clampi(int(ceil(float(cfg.get("amount", 4)) * 0.35)), 1, 6)
	var sz = float(cfg.get("size", 1.0))
	var d: Vector3 = cfg.get("dir", Vector3.UP)
	var spr = deg_to_rad(float(cfg.get("spread", 45.0))) * 0.6
	var vm = float(cfg.get("vmax", 6.0))
	WaterArt.drops(pos, n * 2, clampf(sz * 1.6, 0.4, 6.0), clampf(vm, 3.0, 30.0), d if d.y < 0.95 else Vector3.ZERO, clampf(spr, 0.1, 0.9))
	return null


static func _water_chunks_sprite(pos: Vector3, cfg: Dictionary) -> GPUParticles3D:
	cfg = cfg.duplicate()
	cfg["tex"] = FX.tex_water
	cfg["cel"] = false
	cfg["add"] = false
	cfg["size"] = float(cfg.get("size", 1.0)) * 1.8
	cfg["amount"] = maxi(1, int(ceil(float(cfg.get("amount", 8)) * 0.5)))   # az ama iri, birbirine kaynayan su kütleleri
	# su ağırdır: fışkırır ve yay çizip düşer (yükselip süzülen parçalar alev gibi okunuyordu)
	var g: Vector3 = cfg.get("gravity", Vector3.ZERO)
	if g.y > -14.0:
		cfg["gravity"] = Vector3(g.x, -18.0, g.z)
	cfg["damp"] = minf(float(cfg.get("damp", 1.0)), 1.0)
	var cols: Array = cfg.get("colors", [Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var out = []
	for k in cols.size():
		var c: Color = cols[k]
		var foam = c.r > 0.85   # köpük tonları beyazımsı kalsın
		out.append(Color(1.0, 1.0, 1.0, c.a) if foam else Color(0.95, 0.98, 1.0, c.a))
	cfg["colors"] = out
	cfg["spin"] = 25.0
	cfg["scale_curve"] = [[0.0, 0.5], [0.2, 1.0], [1.0, 0.75]]
	return FX.burst(pos, cfg)


## Sis / buhar / asit bulutu: kenarsız, yumuşak, yarı saydam (cel topak değil — siyah çizgili pamuk olmasın)
static func fog(pos: Vector3, cfg: Dictionary) -> GPUParticles3D:
	cfg = cfg.duplicate()
	if epic != 1.0:
		cfg["size"] = float(cfg.get("size", 1.0)) * sqrt(epic)
		cfg["radius"] = float(cfg.get("radius", 0.0)) * epic
	cfg["cel"] = false
	cfg["add"] = false
	if not cfg.has("tex"):
		cfg["tex"] = FX.tex_soft
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
	# Naruto Storm su sıçraması: 3B kıvrık yapraklı su tacı + yay çizip düşen gövdeli damlalar + ince su sisi
	if busy():
		return
	WaterArt.splash(pos, size * 0.8)
	var g = Game.jutsu_floor(pos.x, pos.z)
	FX.burst(Vector3(pos.x, maxf(g, pos.y - size), pos.z) + Vector3.UP * 0.4, {"amount": int(3 * size) + 2, "life": 0.9, "tex": FX.tex_smoke, "add": false, "cel": false, "size": 1.2 * size, "radius": size * 0.5,
		"vmin": 0.8, "vmax": 2.2, "dir": Vector3.UP, "spread": 80.0, "damp": 2.0,
		"colors": [Color(0.85, 0.94, 1.0, 0.0), Color(0.85, 0.94, 1.0, 0.35), Color(0.85, 0.94, 1.0, 0.0)]})


## Yapışkan damla / parça (lav, Mei çamuru, kurbağa yağı): malzemeli ağır topaklar yay çizip düşer, yere değince yassılaşıp
## yapışır, sonra küçülüp kaybolur. Ateş/duman partikülü değil — sıvının kendisi. kind: lava_mat türü
static func goo_drops(pos: Vector3, kind := "molten", n := 8, s := 1.0, vmax := 6.0) -> void:
	if busy():
		return
	var m = lava_mat(kind)
	var sc = scene()
	for k in n:
		var mi = MeshInstance3D.new()
		mi.mesh = _sphere(0.5, 10, 6)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sc.add_child(mi)
		var r = randf_range(0.18, 0.42) * s
		mi.global_position = pos
		mi.scale = Vector3(r, r * 1.3, r)
		var a = randf() * TAU
		var v = Vector3(cos(a), 0, sin(a)) * randf_range(1.0, vmax * 0.6) + Vector3.UP * randf_range(vmax * 0.5, vmax)
		var gy = Game.jutsu_floor(pos.x + v.x * 0.5, pos.z + v.z * 0.5)
		var st0 = {"t": 0.0, "landed": false}
		var tw = mi.create_tween()
		tw.tween_method(func(t: float):
			if not is_instance_valid(mi) or st0["landed"]:
				return
			var p = pos + v * t + Vector3.DOWN * 9.8 * t * t
			if p.y <= gy + 0.05 and t > 0.05:
				st0["landed"] = true
				mi.global_position = Vector3(p.x, gy + 0.04, p.z)
				mi.scale = Vector3(r * 2.2, r * 0.35, r * 2.2)   # yere yapışır, yassılaşır
			else:
				mi.global_position = p
				var sp = v + Vector3.DOWN * 19.6 * t
				mi.scale = Vector3(r, r * (1.0 + clampf(sp.length() * 0.08, 0.0, 1.0)), r), 0.0, 1.4, 1.4)
		tw.tween_interval(randf_range(0.8, 1.6))
		tw.tween_property(mi, "scale", Vector3(r * 2.2, 0.01, r * 2.2), 0.6)
		tw.tween_callback(mi.queue_free)


## Lav sıçraması (Yōton, anime lav duvarı/lav kayaları): ATEŞ DEĞİL — kızıl, sarı erimiş hücreli ağır lav parçaları yay çizip
## düşer ve yere yapışır, tabanda beyaz buhar tüter, zemin kızıl çatlaklarla kızarır
static func lava_splash(pos: Vector3, s := 1.0, kind := "molten") -> void:
	if busy():
		return
	goo_drops(pos, kind, int(8 * s) + 4, 1.0 + s * 0.3, 5.0 + s * 2.0)
	if kind == "molten":
		debris(pos, Color(0.22, 0.12, 0.08), int(5 * s) + 3, 7.0, minf(0.3, 0.12 * s + 0.08))   # lavın içindeki kırık kaya parçaları (küçük)
	FX.burst(pos + Vector3.UP * 0.3, {"amount": int(6 * s) + 3, "life": 1.4, "tex": FX.tex_smoke, "add": false, "cel": false, "size": 1.3 * s, "radius": 0.8 * s, "vmin": 0.8, "vmax": 2.0,
		"dir": Vector3.UP, "spread": 40.0, "colors": [Color(0.92, 0.9, 0.9, 0.0), Color(0.88, 0.86, 0.86, 0.5), Color(0.82, 0.8, 0.8, 0.0)]})
	if kind == "molten":
		FX.light(pos, Color(1.0, 0.35, 0.15), 3.0 * s, 7.0 * s, 0.8)
		cracks(Vector3(pos.x, Game.jutsu_floor(pos.x, pos.z) + 0.05, pos.z), 2.0 * s, Color(0.55, 0.06, 0.03, 0.9), 4.0)


## Cel duman halkası (patlamanın etrafında yayılan)
static func _smoke_ring(pos: Vector3, size := 3.0, col := Color(0.3, 0.27, 0.25)) -> void:
	# anime toz halkası: yumuşak, açık konturlu, daha az ve küçük topak
	var p = puffs(pos, {"amount": int(9 + size * 2.5), "life": 1.2, "size": 1.0 + size * 0.25, "radius": size * 0.3, "vmin": size * 2.0, "vmax": size * 3.2,
		"dir": Vector3.UP, "spread": 90.0, "damp": 3.0, "gravity": Vector3(0, 1.0, 0), "spin": 30.0, "outline_col": col.darkened(0.25),
		"rough": 0.15, "shade": 0.18, "outline": 0.03,
		"colors": [Color(col.lightened(0.2).r, col.lightened(0.2).g, col.lightened(0.2).b, 0.85), Color(col.r, col.g, col.b, 0.6), Color(col.r, col.g, col.b, 0)], "scale_curve": [[0.0, 0.4], [0.3, 1.0], [1.0, 1.2]]})
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
		"katon":
			return trail(target, width, Color(1, 0.85, 0.3), Color(1, 0.45, 0.06), Color(0.75, 0.12, 0.03), 16, 0.3)
		"yoton":   # lav kayası izi: kızıl erimiş çizgi koyu dumana döner (ateş sarısı değil)
			return trail(target, width * 0.8, Color(1.0, 0.35, 0.12), Color(0.7, 0.07, 0.04), Color(0.25, 0.2, 0.2), 16, 0.0)
		"shakuton":
			return trail(target, width, Color(1, 0.98, 0.96), Color(1.0, 0.55, 0.58), Color(1.0, 0.32, 0.38), 16, 0.0)
		"bakuton":
			return trail(target, width * 0.8, Color(1, 1, 0.97), Color(0.95, 0.93, 0.88), Color(0.85, 0.83, 0.8), 14, 0.0)
		"suiton":
			return trail(target, width, Color(0.95, 0.99, 1), Color(0.45, 0.75, 1.0), Color(0.12, 0.38, 0.9), 18, 0.1)
		"futton":
			return trail(target, width, Color(1, 1, 1), Color(0.9, 0.87, 0.93), Color(0.78, 0.74, 0.82), 16, 0.0)
		"hyoton":
			return trail(target, width * 0.7, Color(1, 1, 1), Color(0.82, 0.94, 1.0), Color(0.6, 0.82, 1.0), 12, 0.0)
		"fuuton":
			return trail(target, width * 0.7, Color(1, 1, 1), Color(0.85, 1.0, 0.92), Color(0.6, 0.95, 0.8), 14, 0.0)
		"jinton":
			return trail(target, width * 0.6, Color(1, 1, 1), Color(0.95, 0.97, 1.0), Color(0.88, 0.92, 1.0), 12, 0.0)
		"raiton":
			return trail(target, width * 0.6, Color(1, 1, 1), col.lightened(0.4), col, 12, 0.8)
		"ranton":
			return trail(target, width * 0.8, Color(1, 1, 1), Color(0.75, 0.9, 1.0), Color(0.45, 0.7, 1.0), 14, 0.0)
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
	# anime patlaması: büyüyen küre kabuğu / yıldız / halka YOK — fışkıran alev dilleri, kor, ardından yumuşak duman
	var preset = fire_preset_for(col)
	var pr: Array = FIRE_PRESETS.get(preset, FIRE_PRESETS["fire"])
	# alev dilleri: sarı çekirdek → turuncu → kırmızı; ince, kendi renginde kontur (siyah değil)
	puffs(pos, {"amount": int(14 * s) + 6, "life": 0.6, "size": 1.5 * s, "radius": 0.8 * s, "vmin": 5, "vmax": 11 * s,
		"damp": 6.0, "gravity": Vector3(0, 6, 0), "spin": 70.0, "glow": 1.15, "hot": 0.45, "outline_col": pr[3], "outline": 0.03, "rough": 0.2,
		"colors": [pr[0], pr[1], pr[2], Color(pr[3].r, pr[3].g, pr[3].b, 0)], "scale_curve": [[0.0, 0.4], [0.2, 1.0], [1.0, 0.55]]})
	# yukarı yalayan alev dilleri (sivri, hızlı)
	FX.burst(pos, {"amount": int(10 * s) + 4, "life": 0.45, "tex": FX.tex_spark, "size": 2.2 * s, "vmin": 6.0 * s, "vmax": 12.0 * s, "dir": Vector3.UP, "spread": 70.0,
		"damp": 3.0, "colors": [Color(1, 0.95, 0.6, 1), pr[1], Color(pr[2].r, pr[2].g, pr[2].b, 0)]})
	# duman: alev sönerken, yumuşak ve açık konturlu
	var smoke_at = pos + Vector3.UP * s * 1.4
	scene().get_tree().create_timer(0.3).timeout.connect(func():
		puffs(smoke_at, {"amount": int(5 * s) + 3, "life": 1.4, "size": 1.5 * s, "radius": 1.0 * s, "vmin": 1.0, "vmax": 3 * s,
			"damp": 2.0, "gravity": Vector3(0, 3.0, 0), "spin": 20.0, "outline_col": Color(0.3, 0.26, 0.23), "shade": 0.25, "glow": 1.0, "outline": 0.03, "rough": 0.16,
			"colors": [Color(0.34, 0.29, 0.26, 0.0), Color(0.36, 0.31, 0.28, 0.75), Color(0.42, 0.38, 0.35, 0.5), Color(0.45, 0.41, 0.38, 0)]}))
	embers(pos, pr[2], int(22 * s), 18.0 * s, 1.0)
	var g = Vector3(pos.x, Game.jutsu_floor(pos.x, pos.z) + 0.12, pos.z)
	if pos.y - g.y < 3.0 * s:
		cracks(g, 3.5 * s, Color(0.1, 0.06, 0.04, 0.85), 6.0, false)
		if preset != "black":
			GroundFX.add(g, "burning", 1.2 * s + 0.8, 4.0)   # yanan zemin: içindekiler tutuşur
	FX.light(pos, pr[1], 10.0 * s, 22.0 * s, 0.45)
	if Game.world:
		Game.world.env.add_shake(0.7 * s)
		Game.world.env.screen_flash(0.04 * s)
	if s >= 1.4:
		screen_lines(0.3, minf(1.0, 0.4 * s))
	Sfx.play("boom", pos)


## Amaterasu kara alevi: hedefi saran, yukarı yalayan sivri alev dilleri (iç siyah, kenar koyu mor)
static func black_flames(size := 1.0) -> Node3D:
	# Amaterasu: küre kabuk yok (sıvı gibi duruyordu) — yukarı yalayan sivri kara alev dilleri, mor-koyu kenarlı iç diller, kara duman
	var root = Node3D.new()
	_black_fire_particles(root, size, 0.45 * size, 1.0)
	return root


## Kara alev parçacıkları (kalıcı): parent'a bağlı, yerinde yanar. r: yayılım yarıçapı, k: yoğunluk
static func _black_fire_particles(parent: Node3D, size: float, r: float, k: float) -> void:
	var layers = [
		# [miktar, ömür, boy, renkler] — dış kara diller, iç mor-koyu diller
		[int(26 * k), 0.55, 3.2 * size, [Color(0.02, 0.0, 0.03, 0.0), Color(0.03, 0.0, 0.05, 1.0), Color(0.06, 0.01, 0.09, 0.95), Color(0.02, 0.0, 0.03, 0.0)]],
		[int(16 * k), 0.4, 2.2 * size, [Color(0.25, 0.05, 0.32, 0.0), Color(0.3, 0.06, 0.38, 0.95), Color(0.1, 0.02, 0.14, 0.9), Color(0.05, 0.0, 0.08, 0.0)]],
	]
	for L in layers:
		var p = FX.burst(Vector3.ZERO, {"parent": parent, "local": true, "amount": L[0], "life": L[1], "tex": FX.tex_spark, "add": false, "size": L[2],
			"radius": r, "vmin": 1.2, "vmax": 3.2, "dir": Vector3.UP, "spread": 14.0, "gravity": Vector3(0, 2.5, 0), "damp": 1.0, "explosive": 0.0,
			"scale_curve": [[0.0, 0.5], [0.35, 1.0], [1.0, 0.3]], "colors": L[3]})
		if p:
			p.one_shot = false
	# kara duman: yavaşça yükselen yumuşak koyu tüller
	var sm = FX.burst(Vector3.UP * 0.8 * size, {"parent": parent, "local": true, "amount": int(8 * k), "life": 1.3, "tex": FX.tex_smoke, "add": false, "cel": false,
		"size": 1.4 * size, "radius": r, "vmin": 0.6, "vmax": 1.6, "dir": Vector3.UP, "spread": 25.0, "gravity": Vector3(0, 1.0, 0), "explosive": 0.0,
		"colors": [Color(0.05, 0.03, 0.06, 0.0), Color(0.06, 0.04, 0.08, 0.55), Color(0.1, 0.08, 0.12, 0.0)]})
	if sm:
		sm.one_shot = false


## Yerde için için yanan kara alev lekesi
static func _black_smolder(pos: Vector3, size := 2.0, dur := 6.0) -> void:
	var root = Node3D.new()
	scene().add_child(root)
	root.global_position = Vector3(pos.x, Game.jutsu_floor(pos.x, pos.z) + 0.05, pos.z)
	_black_fire_particles(root, size * 0.45, size * 0.9, 1.4)
	cracks(pos, size * 2.2, Color(0.04, 0.0, 0.05, 0.95), dur + 2.0)
	scene().get_tree().create_timer(dur).timeout.connect(func():
		if is_instance_valid(root):
			for ch in root.get_children():
				if ch is GPUParticles3D:
					ch.emitting = false
			root.get_tree().create_timer(1.4).timeout.connect(root.queue_free))


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
	var feet = Vector3(c.global_position.x, Game.jutsu_floor(c.global_position.x, c.global_position.z) + 0.08, c.global_position.z)
	# halka/yıldız şekli yok (yapay duruyordu): çıkış noktasında kısa ışık çakması + ince kıvılcım, ayakta az yumuşak toz
	FX.light(origin, col.lightened(0.35), 2.0 + 1.5 * g, 6.0 + 3.0 * g, 0.15)
	FX.burst(origin, {"amount": int(8 + 6 * g), "life": 0.25, "tex": FX.tex_spark, "size": 0.8 + 0.4 * g, "vmin": 4.0, "vmax": 9.0 + 4.0 * g, "spread": 180.0, "damp": 3.0,
		"colors": [Color(1, 1, 1, 0.9), col.lightened(0.4), Color(col.r, col.g, col.b, 0)]})
	if tier >= 3:
		FX.dust(feet, 0.5 + 0.25 * g)
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
	# yıldız kartı kaldırıldı (kameranın önünde dev sarı kama gibi duruyordu): toplanan kıvılcımlar + küçük ışık
	FX.light(pos, col.lightened(0.3), 2.0 + g, 4.0 + 2.0 * g, 0.25)
	FX.burst(pos, {"amount": int(10 + 6 * g), "life": 0.3, "tex": FX.tex_spark, "add": true, "size": 0.35 * g, "radius": 1.4 * g, "vmin": 0.5, "vmax": 2.0,
		"gravity": Vector3.ZERO, "colors": [Color(1, 1, 1, 1), col, Color(col.r, col.g, col.b, 0)]})


## Çarpma sonrası kalıcı iz (rütbe ölçekli): yerde alev dilleri, su birikintisi, buz kristali, moloz, artık şimşek
const LINGER_ON := false


static func linger(pos: Vector3, el: String, col: Color, g: float, dur := 3.0) -> void:
	# kullanıcı isteği (2026-11-01): jutsu sonrası yerde kalan birikinti/alev/buz/kaya izleri tamamen kapalı
	if not LINGER_ON or busy() or g < 1.1:
		return
	var gp = Vector3(pos.x, Game.jutsu_floor(pos.x, pos.z), pos.z)
	if pos.y - gp.y > 4.0:
		return
	var root = Node3D.new()
	scene().add_child(root)
	_track(root)
	root.global_position = gp
	var n = 2 + int(g * 1.5)
	match el:
		"yoton":
			# lav: alev dili değil, yerde parlayan akışkan lav birikintisi + kararan kabuk + yavaş kabarcıklar
			var lava = mat_water(Color(0.35, 0.06, 0.02), Color(1.0, 0.42, 0.08), Color(1.0, 0.85, 0.4), Vector3.UP, 0.6, 0.7, 0.05)
			var pool = _mi(_sphere(0.5, 20, 6), lava)
			pool.scale = Vector3(2.6 * g, 0.12, 2.6 * g)
			root.add_child(pool)
			for k in n:
				var bub = _mi(_sphere(0.5, 8, 6), lava)
				var a = randf() * TAU
				bub.position = Vector3(cos(a), 0.05, sin(a)) * randf_range(0.2, 1.0) * g
				bub.scale = Vector3.ONE * 0.05
				root.add_child(bub)
				var tb = bub.create_tween().set_loops(int(dur / 0.9) + 1)
				tb.tween_interval(randf() * 0.6)
				tb.tween_property(bub, "scale", Vector3.ONE * randf_range(0.25, 0.45) * g, 0.4)
				tb.tween_property(bub, "scale", Vector3.ONE * 0.05, 0.15)
			var tw = pool.create_tween()
			tw.tween_interval(dur * 0.7)
			tw.tween_property(pool, "scale", Vector3(2.6 * g, 0.04, 2.6 * g), dur * 0.3)
			cracks(gp, 2.2 * g, Color(0.08, 0.04, 0.02, 0.9), dur + 3.0)
		"shakuton":   # kavrulan zemin: alev değil, yerden tüten beyaz buhar ve kuru çatlaklar
			for k in n:
				var a = randf() * TAU
				puffs(gp + Vector3(cos(a), 0.2, sin(a)) * randf_range(0.2, 1.4) * g, {"amount": 6, "life": 1.6, "size": 0.7 * g, "radius": 0.3, "vmin": 0.4, "vmax": 1.2, "dir": Vector3.UP, "spread": 25.0, "add": false,
					"colors": [Color(1, 1, 1, 0.8), Color(1, 0.95, 0.95, 0)]})
			cracks(gp, 1.8 * g, Color(0.35, 0.25, 0.2, 0.7), dur + 2.0)
		"bakuton":    # patlama izi: kararan zemin ve ince duman
			cracks(gp, 2.6 * g, Color(0.12, 0.1, 0.08, 0.9), dur + 3.0)
			puffs(gp + Vector3.UP * 0.3, {"amount": 10, "life": 1.8, "size": 0.9 * g, "radius": 0.8 * g, "vmin": 0.3, "vmax": 1.0, "dir": Vector3.UP, "spread": 30.0, "add": false,
				"colors": [Color(0.45, 0.43, 0.42, 0.6), Color(0.4, 0.38, 0.37, 0)]})
		"katon":
			# yanan zemin: koni biçimli alev meshleri yerine yerden sürekli yükselen küçük cel alev dilleri + kor (organik)
			var pr: Array = FIRE_PRESETS[fire_preset_for(col)]
			var spots = []
			for k in n:
				var a = randf() * TAU
				spots.append(Vector3(cos(a), 0.0, sin(a)) * randf_range(0.2, 1.6) * g)
			var tm = Timer.new()
			tm.wait_time = 0.12
			root.add_child(tm)
			var st0 = {"t": 0.0}
			tm.timeout.connect(func():
				st0["t"] += 0.12
				if st0["t"] > dur or busy():
					return
				var fade = clampf((dur - st0["t"]) / 0.8, 0.2, 1.0)
				for sp in spots:
					if randf() < 0.6:
						puffs(gp + sp + Vector3.UP * 0.15, {"amount": 2, "life": 0.55, "size": 1.0 * g * fade, "radius": 0.25 * g, "vmin": 1.2, "vmax": 2.6, "dir": Vector3.UP, "spread": 12.0,
							"damp": 1.0, "gravity": Vector3(0, 2.0, 0), "spin": 40.0, "glow": 1.15, "hot": 0.6, "outline_col": pr[4], "outline": 0.03, "rough": 0.2,
							"colors": [pr[1], pr[2], Color(pr[3].r, pr[3].g, pr[3].b, 0.8), Color(pr[4].r, pr[4].g, pr[4].b, 0.0)], "scale_curve": [[0.0, 0.5], [0.3, 1.0], [1.0, 0.2]]})
				if randf() < 0.3:
					embers(gp + Vector3.UP * 0.5, col, 3, 1.5 * g, 0.6))
			tm.autostart = true
			cracks(gp, 2.2 * g, Color(0.08, 0.04, 0.02, 0.9), dur + 3.0)
		"futton":     # yere çöken asit sisi / buhar
			puffs(gp + Vector3.UP * 0.4, {"amount": 18, "life": 2.4, "size": 1.6 * g, "radius": 1.2 * g, "vmin": 0.1, "vmax": 0.5, "dir": Vector3.UP, "spread": 60.0, "add": false,
				"colors": [Color(0.95, 0.93, 0.97, 0.7), Color(0.85, 0.8, 0.9, 0.4), Color(0.8, 0.75, 0.85, 0)]})
		"suiton":
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


## Shakuton küresi (anime Pakura): katı top değil, IŞIK — kameraya dönük yumuşak parıltı:
## geniş beyaz çekirdek, etrafında yumuşakça sönen pembe-kızıl hâle, hareket edince arkasında kıvrılan pembe kuyruk.
## Sert kenar, çizgi, desen yok (kenar çizgisi geçişine de girmesin diye derinlik yazmayan saydam düzlemler).
static func scorch_orb(size := 1.0) -> Node3D:
	size *= epic
	var root = Node3D.new()
	var r = 0.5 * size * 1.5   # animede küreler kol boyunda: büyük
	# dış hâle: geniş, soluk pembe-kızıl
	var glow = MeshInstance3D.new()
	var gq = QuadMesh.new()
	gq.size = Vector2(r * 4.2, r * 4.2)
	glow.mesh = gq
	glow.material_override = _glow_sprite_mat(_radial_tex(Color(1.0, 0.45, 0.48, 0.8), Color(1.0, 0.35, 0.4, 0.0)))
	root.add_child(glow)
	# çekirdek: geniş katı beyaz, kenarda pembe-kızıla yumuşak geçiş
	var core = MeshInstance3D.new()
	var cq = QuadMesh.new()
	cq.size = Vector2(r * 2.6, r * 2.6)
	core.mesh = cq
	core.material_override = _glow_sprite_mat(_orb_tex())
	core.sorting_offset = 3.0   # beyaz çekirdek her zaman kuyruk ve hâlenin önünde
	root.add_child(core)
	# kuyruk: hareket edince geride kalan pembe-kızıl yumuşak parıltılar (kuyruklu yıldız)
	var e = GPUParticles3D.new()
	e.amount = 34
	e.lifetime = 0.55
	e.local_coords = false
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = r * 0.5
	pm.direction = Vector3(0, 0.35, -1)
	pm.spread = 25.0
	pm.initial_velocity_min = r * 3.0
	pm.initial_velocity_max = r * 4.5
	pm.gravity = Vector3(0, 0.8, 0)
	pm.scale_min = r * 1.6
	pm.scale_max = r * 2.4
	pm.scale_curve = _curve_tex([[0.0, 1.0], [1.0, 0.25]])
	pm.color_ramp = FX._gradient([Color(1.0, 0.6, 0.55, 1.0), Color(1.0, 0.5, 0.48, 0.9), Color(1.0, 0.45, 0.45, 0.0)])
	e.process_material = pm
	var tq = QuadMesh.new()
	tq.material = _glow_sprite_mat(_radial_tex(Color(1, 1, 1, 1), Color(1, 1, 1, 0)), true)   # yumuşak, sivrilerek incelen ışık kuyruğu
	e.draw_pass_1 = tq
	e.sorting_offset = -2.0
	e.position = Vector3(0, 0, -r * 0.5)   # kuyruk kürenin arkasından çıkar (-Z: kürenin baktığı dış-geri yön)
	root.add_child(e)
	var tw = root.create_tween().set_loops()
	tw.tween_property(glow, "scale", Vector3.ONE * 1.08, 0.2)
	tw.tween_property(glow, "scale", Vector3.ONE * 0.95, 0.2)
	return root


## Kameraya dönük, derinlik yazmayan yumuşak parıltı malzemesi (particles=true: parçacık rengini kullanır)
static func _glow_sprite_mat(tex: Texture2D, particles := false) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES if particles else BaseMaterial3D.BILLBOARD_ENABLED
	m.vertex_color_use_as_albedo = particles
	m.albedo_texture = tex
	return m


## Shakuton çekirdeği: merkezden %60'a kadar katı beyaz, sonra pembe-kızıla ve saydama yumuşak geçiş
static func _orb_tex() -> Texture2D:
	if _radial_cache.has("orb"):
		return _radial_cache["orb"]
	var g = Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.add_point(0.68, Color(1, 1, 1, 1))
	g.add_point(0.76, Color(1.0, 0.7, 0.7, 1.0))
	g.add_point(0.88, Color(1.0, 0.42, 0.45, 0.7))
	g.set_color(g.get_point_count() - 1, Color(1.0, 0.35, 0.4, 0.0))
	var t = GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	_radial_cache["orb"] = t
	return t


static func _curve_tex(pts: Array) -> CurveTexture:
	var c = Curve.new()
	for p in pts:
		c.add_point(Vector2(p[0], p[1]))
	var ct = CurveTexture.new()
	ct.curve = c
	return ct


## Merkezi opak, kenara saydamlaşan dairesel doku (tek sefer üretilir)
static var _radial_cache := {}
static func _radial_tex(inner: Color, outer: Color) -> Texture2D:
	var key = str(inner) + str(outer)
	if _radial_cache.has(key):
		return _radial_cache[key]
	var g = Gradient.new()
	g.set_color(0, inner)
	g.add_point(0.45, inner.lerp(outer, 0.25))
	g.set_color(g.get_point_count() - 1, outer)
	var t = GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	_radial_cache[key] = t
	return t


# ================================================================== doğaya özgü mermi gövdeleri (her biri kendi anime görünümünde)
## Futton: kaynayan buhar küresi — sürekli dönüp kabaran beyaz-gri buhar, hafif mor asit tonu
static func steam_orb(size := 1.0) -> Node3D:
	size *= epic
	var root = Node3D.new()
	var core = _mi(_sphere(0.42 * size, 16, 10), mat_steam(true))
	root.add_child(core)
	var e = GPUParticles3D.new()
	e.amount = 24
	e.lifetime = 0.7
	e.local_coords = true
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.35 * size
	pm.direction = Vector3.UP
	pm.spread = 180.0
	pm.initial_velocity_min = 0.3
	pm.initial_velocity_max = 0.9
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.6 * size
	pm.scale_max = 1.1 * size
	pm.color_ramp = FX._gradient([Color(1, 1, 1, 0.0), Color(0.96, 0.95, 0.97, 0.85), Color(0.85, 0.8, 0.9, 0.5), Color(0.8, 0.75, 0.85, 0.0)])
	e.process_material = pm
	var q = QuadMesh.new()
	q.material = FX._draw_mat(FX.tex_smoke, false)
	e.draw_pass_1 = q
	root.add_child(e)
	return root


## Hyōton: keskin buz kristali kümesi (sekiz yüzlü sivri parçalar), soğuk beyaz parıltı
static func ice_orb(size := 1.0) -> Node3D:
	size *= epic
	var root = Node3D.new()
	for k in 7:
		var sh = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 0.16 * size
		cm.height = (0.7 if k == 0 else randf_range(0.35, 0.55)) * size
		cm.radial_segments = 4
		cm.rings = 1
		sh.mesh = cm
		sh.material_override = mat_ice()
		var a = k * TAU / 6.0
		sh.rotation = Vector3(PI * 0.5, 0, 0) if k == 0 else Vector3(PI * 0.5 + randf_range(-0.9, 0.9), a, randf_range(-0.5, 0.5))
		root.add_child(sh)
	return root


## Jinton: yarı saydam beyaz ışık küpü — içinde parlak çekirdek, döner
static func dust_cube(size := 1.0) -> Node3D:
	size *= epic
	var root = Node3D.new()
	var outer = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3.ONE * 0.8 * size
	outer.mesh = bm
	outer.material_override = mat_dust()
	root.add_child(outer)
	var inner = MeshInstance3D.new()
	var bi = BoxMesh.new()
	bi.size = Vector3.ONE * 0.3 * size
	inner.mesh = bi
	var im = StandardMaterial3D.new()
	im.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	im.albedo_color = Color(1, 1, 1)
	inner.material_override = im
	root.add_child(inner)
	var tw = root.create_tween().set_loops()
	tw.tween_property(root, "rotation", Vector3(TAU, TAU, 0), 2.0).from(Vector3.ZERO)
	return root


## Bakuton: beyaz patlayıcı kil topu — kilin içinden sızan küçük kıvılcımlar
static func clay_orb(size := 1.0) -> Node3D:
	size *= epic
	var root = Node3D.new()
	var body = _mi(_sphere(0.45 * size, 14, 10), Props.toon_color(Color(0.95, 0.94, 0.9)))
	root.add_child(body)
	var e = GPUParticles3D.new()
	e.amount = 10
	e.lifetime = 0.35
	e.local_coords = false
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.4 * size
	pm.spread = 180.0
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 1.5
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.08
	pm.scale_max = 0.16
	pm.color_ramp = FX._gradient([Color(1, 1, 0.9, 1), Color(1, 0.85, 0.5, 0.0)])
	e.process_material = pm
	var q = QuadMesh.new()
	q.material = FX._draw_mat(FX.tex_spark, true)
	e.draw_pass_1 = q
	root.add_child(e)
	return root


## Ranton: lazer başı — beyaz-sıcak uzun çekirdek, mavi hale; şimşek dalı yok
static func storm_orb(size := 1.0) -> Node3D:
	# Ranton ışık başı: kameraya dönük yumuşak parıltı — beyaz-sıcak merkez, mavi hâle (kapsül/hap mesh değil)
	size *= epic
	var root = Node3D.new()
	var r = 0.45 * size
	var glow = MeshInstance3D.new()
	var gq = QuadMesh.new()
	gq.size = Vector2(r * 5.0, r * 5.0)
	glow.mesh = gq
	glow.material_override = _glow_sprite_mat(_radial_tex(Color(0.45, 0.72, 1.0, 0.75), Color(0.35, 0.6, 1.0, 0.0)))
	root.add_child(glow)
	var core = MeshInstance3D.new()
	var cq = QuadMesh.new()
	cq.size = Vector2(r * 2.2, r * 2.2)
	core.mesh = cq
	core.material_override = _glow_sprite_mat(_radial_tex(Color(1, 1, 1, 1), Color(0.6, 0.85, 1.0, 0.0)))
	core.sorting_offset = 3.0
	root.add_child(core)
	return root


## Bakuton patlaması (anime Deidara C1/C3/mayın): kısa beyaz parlama → ortada turuncu-sarı ateş kubbesi (cel, koyu turuncu benekli)
## → dışa ve yukarı açılan gri karnabahar duman halkası → uçuşan toprak/kaya → yere yakınsa yarık, kararmış iz ve yerde toz halkası.
## Ortamı tutuşturmaz (kil patlaması: yanan zemin bırakmaz).
static func clay_blast(pos: Vector3, s := 1.0) -> void:
	var ep = epic
	epic = 1.0
	s *= ep
	# büyük patlamada topak sayısı ve yayılım büyür, topak boyu yavaş büyür (ekranı kaplayan dev kaya gibi topaklar olmasın)
	var z = sqrt(s)
	var n = minf(s, 4.0)
	star(pos, Color(1, 1, 0.95), 3.5 * s, 0.16)
	FX.light(pos, Color(1.0, 0.8, 0.45), 9.0 * s, 18.0 * s, 0.45)
	FX.burst(pos, {"amount": int(6 * s) + 3, "life": 0.16, "size": 3.0 * s, "radius": 0.2 * s, "vmin": 0.5, "vmax": 2.0, "dir": Vector3.UP, "spread": 180.0, "add": true, "cel": false,
		"tex": FX.tex_soft, "colors": [Color(1, 1, 0.96, 1), Color(1.0, 0.95, 0.8, 0.5), Color(1.0, 0.9, 0.7, 0)]})
	# ateş kubbesi: sarı merkezli turuncu cel topaklar, yavaş açılır (sprey değil kubbe)
	puffs(pos, {"amount": int(20 * n) + 10, "life": 0.7 + 0.1 * z, "size": 1.6 * pow(s, 0.7), "radius": 0.9 * s, "vmin": 1.5, "vmax": 4.5 * z, "spread": 180.0,
		"damp": 5.0, "gravity": Vector3(0, 2.0, 0), "spin": 40.0, "glow": 1.15, "hot": 0.6, "outline_col": Color(0.75, 0.3, 0.05), "outline": 0.03, "rough": 0.18,
		"colors": [Color(1.0, 0.92, 0.45, 1), Color(1.0, 0.62, 0.12, 1), Color(0.95, 0.42, 0.08, 0.9), Color(0.6, 0.3, 0.1, 0)], "scale_curve": [[0.0, 0.35], [0.25, 1.0], [1.0, 0.7]]})
	# gri duman: ateşin çevresinden dışa ve yukarı taşan karnabahar bulut (ateş söndükçe görünür)
	var at = pos
	scene().get_tree().create_timer(0.12).timeout.connect(func():
		puffs(at, {"amount": int(30 * n) + 10, "life": 2.0 + 0.3 * z, "size": 1.65 * pow(s, 0.75), "radius": 1.1 * s, "vmin": 2.5 * z, "vmax": 6.0 * z, "dir": Vector3.UP, "spread": 110.0, "damp": 3.0,
			"gravity": Vector3(0, 0.8, 0), "spin": 15.0, "rough": 0.22, "outline": 0.035, "outline_col": Color(0.28, 0.27, 0.29), "shade": 0.3,
			"colors": [Color(0.58, 0.57, 0.58, 0.0), Color(0.58, 0.57, 0.58, 1), Color(0.48, 0.47, 0.49, 0.95), Color(0.38, 0.37, 0.39, 0.0)]}))
	embers(pos, Color(1.0, 0.6, 0.15), int(18 * n), 16.0 * z, 0.7)
	var g = Vector3(pos.x, Game.jutsu_floor(pos.x, pos.z) + 0.1, pos.z)
	var near = pos.y - g.y < 3.5 * s
	# uçuşan toprak (yerdeyse kahverengi) ve gri kaya/kil parçaları
	debris(pos, Color(0.42, 0.33, 0.24) if near else Color(0.55, 0.53, 0.5), int(14 * n) + 4, 13.0 * z, 0.3 * z + 0.1)
	if near:
		cracks(g, 4.5 * s, Color(0.08, 0.06, 0.05, 0.92), 8.0)
		FX.dust(g, 1.6 * z)
		puffs(g + Vector3.UP * 0.3, {"amount": int(14 * n) + 6, "life": 1.4, "size": 1.3 * z, "radius": 0.6 * s, "vmin": 6.0 * z, "vmax": 10.0 * z, "dir": Vector3.UP, "spread": 88.0, "damp": 4.0,
			"gravity": Vector3(0, -1.0, 0), "rough": 0.22, "outline": 0.035, "outline_col": Color(0.32, 0.27, 0.22),
			"colors": [Color(0.55, 0.47, 0.38, 0.0), Color(0.55, 0.47, 0.38, 0.9), Color(0.5, 0.43, 0.35, 0.0)]})
	if Game.world:
		Game.world.env.add_shake(0.6 * s)
		Game.world.env.screen_flash(0.035 * s)
	Sfx.play("boom", pos)
	epic = ep


## Sabun köpüğü (utakatababa2.png): içi şeffaf, kenarda bakış açısıyla değişen gökkuşağı zar, beyaz parlama. size: çap (m)
static var _bubble_mats := {}
static func soap_bubble(size: float, tint := Color(0.85, 0.92, 1.0)) -> MeshInstance3D:
	var key = "%s|%d" % [tint.to_html(false), randi() % 6]
	if not _bubble_mats.has(key):
		var m = ShaderMaterial.new()
		m.shader = load("res://shaders/soap_bubble.gdshader")
		m.set_shader_parameter("tint", tint)
		m.set_shader_parameter("seed", float(_bubble_mats.size()) * 1.7)
		_bubble_mats[key] = m
	var mi = MeshInstance3D.new()
	mi.mesh = _sphere(0.5, 24, 14)
	mi.material_override = _bubble_mats[key]
	mi.scale = Vector3.ONE * size
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
