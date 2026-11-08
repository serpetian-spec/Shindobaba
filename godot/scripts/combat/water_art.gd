class_name WaterArt
extends RefCounted
## Naruto Storm suyu (3B): düz sprite yerine gövdeli su kütleleri — kıvrık yapraklı su tacı, yay çizip düşen su damlaları.
## Malzeme vfx_water (soluk camgöbeği Storm paleti, akan köpük çizgileri).

static func mat() -> ShaderMaterial:
	return VFX.mat_water(Color(0.05, 0.28, 0.78), Color(0.2, 0.55, 0.98), Color(0.62, 0.88, 1.0), Vector3.UP, 0.92, 0.7, 0.08)


## Su tacı mesh'i: tabandan dışa ve yukarı kıvrılan kalın yapraklar (uçları dışa devrilir), ortada kabaran su
static func crown_mesh(n := 9, seed_ := 0) -> ArrayMesh:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_
	var b = MB.new()
	for k in n:
		var a = k * TAU / n + rng.randf_range(-0.2, 0.2)
		var o = Vector3(cos(a), 0, sin(a))
		var h = rng.randf_range(0.7, 1.2)
		var pts = [o * 0.25, o * 0.42 + Vector3.UP * h * 0.4, o * 0.55 + Vector3.UP * h * 0.8, o * 0.78 + Vector3.UP * h * 0.95, o * 0.95 + Vector3.UP * h * 0.8]
		var w = rng.randf_range(0.16, 0.24)
		Loft.tube(b, pts, [Vector2(w, w * 0.5), Vector2(w * 0.9, w * 0.42), Vector2(w * 0.7, w * 0.35), Vector2(w * 0.45, w * 0.25), Vector2(0.03, 0.03)], Color.WHITE, 8, 3, true, true, Callable(), o)
	# orta kabarma
	Loft.tube(b, [Vector3.ZERO, Vector3.UP * 0.35, Vector3.UP * 0.55], [Vector2(0.45, 0.45), Vector2(0.32, 0.32), Vector2(0.05, 0.05)], Color.WHITE, 12, 3)
	return b.build(null)


static var _crowns: Array = []


## Sıçrama — Naruto Storm 4 videosu (su duvarı 0:32, ejder 5:28): (1) yerde hızla yayılıp sönen düz su örtüsü (kenarı beyaz),
## (2) yukarı fırlayıp kendi ağırlığıyla çöken 2-4 iri su sütunu, (3) az sayıda 3B damla. Sivri yaprak / sprite / duman yok.
static func splash(pos: Vector3, s := 1.0) -> void:
	if VFX.busy():
		return
	var g = Game.jutsu_floor(pos.x, pos.z)
	var base = Vector3(pos.x, maxf(g, pos.y - s * 0.6), pos.z)
	if pos.y - g < 1.5 + s:
		sheet(Vector3(pos.x, g + 0.04, pos.z), s * 1.6, 1.1)
	for k in 2 + int(s > 1.4) + int(s > 2.4):
		var tilt = Vector3(randf_range(-0.35, 0.35), 0, randf_range(-0.35, 0.35))
		column(base + Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4)) * s, s * randf_range(0.9, 1.5), s * randf_range(0.28, 0.42), tilt, k * 0.04)
	spray(base + Vector3.UP * 0.4 * s, s * 0.55, Vector3.UP, 40.0, 0.9)


static var _disc: Mesh
## Yerde yayılan düz su örtüsü (Storm: kütlenin dibinde açılan açık camgöbeği tabaka): hızla genişler, kısa durur, söner
static func sheet(g: Vector3, r: float, dur := 1.0) -> void:
	if _disc == null:
		var b = MB.new()
		b.add("sphere", Vector3.ZERO, Vector3(2.0, 0.12, 2.0), Color.WHITE, Vector3.ZERO, 28)
		_disc = b.build(null)
	var mi = MeshInstance3D.new()
	mi.mesh = _disc
	var m: ShaderMaterial = sheet_mat().duplicate()
	m.set_shader_parameter("c_light", Color(0.55, 0.82, 0.95))   # camgöbeği örtü: yalnız kenarı beyaz (düz beyaz leke değil)
	m.set_shader_parameter("hi_amt", 0.1)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	VFX.scene().add_child(mi)
	mi.global_position = g
	mi.rotation.y = randf() * TAU
	r *= 0.7
	mi.scale = Vector3(r * 0.25, 1.0, r * 0.25)
	var tw = mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(r, 1.0, r), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(dur * 0.35)
	tw.tween_property(mi, "scale", Vector3(r * 1.25, 0.4, r * 1.25), dur * 0.65).set_ease(Tween.EASE_IN)
	tw.parallel().tween_method(func(a: float): m.set_shader_parameter("alpha", a), 0.88, 0.0, dur * 0.65)
	tw.tween_callback(mi.queue_free)


static var _col_mesh: Mesh
static var _col_mat: ShaderMaterial
## İri su sütunu: dipten fışkırır (dikine akan su), tepede kabarır, sonra kendi ağırlığıyla çöküp söner
static func column(at: Vector3, h: float, r: float, tilt := Vector3.ZERO, delay := 0.0) -> void:
	if _col_mesh == null:
		var b = MB.new()
		# yuvarlak, şişkin su sütunu: dipte geniş, gövdede hafif boğumlu, tepede yuvarlak kabarık baş (köşeli kalıp değil)
		Loft.tube(b, [Vector3.ZERO, Vector3.UP * 0.25, Vector3.UP * 0.5, Vector3.UP * 0.75, Vector3.UP * 0.9, Vector3.UP * 1.0], [0.6, 0.4, 0.46, 0.36, 0.3, 0.05], Color.WHITE, 20, 4, false, true)
		b.add("sphere", Vector3.UP * 0.86, Vector3(0.62, 0.42, 0.62), Color.WHITE, Vector3.ZERO, 16)
		_col_mesh = b.build(null)
		_col_mat = VFX.mat_water(Color(0.3, 0.62, 0.86), Color(0.52, 0.8, 0.95), Color(0.85, 0.96, 1.0), Vector3.UP, 0.88, 1.0, 0.1)
	var mi = MeshInstance3D.new()
	mi.mesh = _col_mesh
	var m: ShaderMaterial = _col_mat.duplicate()
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	VFX.scene().add_child(mi)
	mi.global_position = at
	mi.rotation = tilt
	mi.scale = Vector3(r * 0.6, 0.02, r * 0.6)
	mi.visible = delay <= 0.0
	var tw = mi.create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func(): mi.visible = true)
	tw.tween_property(mi, "scale", Vector3(r, h, r), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mi, "scale", Vector3(r * 1.35, h * 1.05, r * 1.35), 0.15)
	tw.tween_property(mi, "scale", Vector3(r * 1.6, h * 0.2, r * 1.6), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_method(func(a: float): m.set_shader_parameter("alpha", a), 0.88, 0.0, 0.45)
	tw.tween_callback(mi.queue_free)


## Soluk, yarı saydam su yüzeyi malzemesi (taç, halka): videodaki gibi mat çelik-camgöbeği, beyaz akış çizgili
static var _sheet: ShaderMaterial
static func sheet_mat() -> ShaderMaterial:
	if _sheet == null:
		_sheet = VFX.mat_water(Color(0.05, 0.28, 0.78), Color(0.2, 0.55, 0.98), Color(0.62, 0.88, 1.0), Vector3.UP, 0.62, 0.9, 0.08).duplicate()
	return _sheet


## Su spreyi (kullanıcı 2026-11-08: "png gibi damla, duman gibi bir şey — berbat"): sprite çizgi/nokta ve duman dokusu YOK.
## Gerçek 3B su damlaları: su malzemesinden küçük gövdeler, hız yönünde uzar (iz gibi), yerçekimiyle düşüp küçülür.
static var _drop_mesh: SphereMesh
static var _drop_mat: ShaderMaterial
static func spray(pos: Vector3, s := 1.0, dir := Vector3.UP, spread := 35.0, speed := 1.0, _mist := false) -> void:
	if VFX.busy():
		return
	if _drop_mesh == null:
		_drop_mesh = SphereMesh.new()
		_drop_mesh.radius = 0.5; _drop_mesh.height = 1.0; _drop_mesh.radial_segments = 8; _drop_mesh.rings = 4
		_drop_mat = VFX.mat_water(Color(0.12, 0.42, 0.85), Color(0.35, 0.7, 1.0), Color(0.85, 0.96, 1.0), Vector3.UP, 0.95, 0.4, 0.0)
		_drop_mesh.material = _drop_mat
	var v = (7.0 + s * 3.0) * speed
	for layer in 2:   # 0: iri damlalar, 1: ince sprey damlacıkları
		var p = GPUParticles3D.new()
		p.one_shot = true
		p.explosiveness = 0.85
		p.amount = int((10 + s * 8) if layer == 0 else (22 + s * 18))
		p.lifetime = 0.8 if layer == 0 else 0.6
		var pm = ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 0.3 * s
		pm.direction = dir.normalized()
		pm.spread = spread
		pm.initial_velocity_min = v * (0.55 if layer == 0 else 0.4)
		pm.initial_velocity_max = v * (1.0 if layer == 0 else 1.15)
		pm.gravity = Vector3(0, -20, 0)
		pm.damping_min = 0.3; pm.damping_max = 0.6
		pm.particle_flag_align_y = true   # damla hız yönünde uzar
		var sz = (0.13 + s * 0.04) if layer == 0 else (0.06 + s * 0.02)
		pm.scale_min = sz * 0.7; pm.scale_max = sz * 1.2
		pm.scale_curve = FX._curve([[0.0, 0.6], [0.2, 1.0], [1.0, 0.0]])
		p.process_material = pm
		var dm = _drop_mesh.duplicate()
		dm.height = 2.6   # dikine uzun damla
		dm.material = _drop_mat
		p.draw_pass_1 = dm
		p.visibility_aabb = AABB(Vector3(-12, -12, -12), Vector3(24, 24, 24))
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		VFX.scene().add_child(p)
		p.global_position = pos
		p.emitting = true
		p.finished.connect(p.queue_free)


## Yerde kısa süren yarı saydam su halkası (sıçrayan suyun yayılması); ~1 sn'de söner
static func ripple(g: Vector3, r := 1.5) -> void:
	var dc = Decal.new()
	dc.texture_albedo = FX._puddle(randi())
	dc.modulate = Color(0.62, 0.8, 0.9, 0.55)
	dc.size = Vector3(r * 2.0, 1.0, r * 2.0)
	dc.cull_mask = 1
	VFX.scene().add_child(dc)
	dc.global_position = g + Vector3.UP * 0.2
	dc.rotation.y = randf() * TAU
	dc.scale = Vector3.ONE * 0.4
	var tw = dc.create_tween()
	tw.tween_property(dc, "scale", Vector3.ONE, 0.35).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(dc, "modulate:a", 0.0, 1.0).set_delay(0.2)
	tw.tween_callback(dc.queue_free)


## Su damlaları/öbekleri (eski 3B damla çağrıları): ince sprey olarak çizilir (iri parçalar buz/duman gibi duruyordu)
static func drops(pos: Vector3, n := 8, s := 1.0, vmax := 7.0, dir := Vector3.ZERO, spread := 0.5) -> void:
	var d = dir if dir != Vector3.ZERO else Vector3.UP
	spray(pos, clampf(s * 0.6 + n * 0.04, 0.4, 3.0), d, rad_to_deg(spread) if dir != Vector3.ZERO else 45.0, clampf(vmax / 8.0, 0.6, 2.0))


## Dalga duvarı (kaynak: Kisame Storm dalgası): genişlik boyunca öne kıvrık, farklı boylarda tırtıklı tepeli kalın su dilleri
## + alçak taban. -Z ileri. w genişlik, h yükseklik
static func wave_mesh(w := 8.0, h := 2.5) -> ArrayMesh:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var b = MB.new()
	var n = int(w / 0.55) + 2
	for k in n:
		var x = -w * 0.5 + w * k / float(n - 1)
		var hh = h * rng.randf_range(0.55, 1.1) * (1.0 - 0.45 * pow(absf(x) / (w * 0.5), 2.0))
		var th = rng.randf_range(0.5, 0.75)
		var pts = [Vector3(x, 0, 0.3), Vector3(x, hh * 0.45, 0.05), Vector3(x + rng.randf_range(-0.1, 0.1), hh * 0.85, -0.25), Vector3(x, hh, -0.65), Vector3(x, hh * 0.85, -0.95)]
		Loft.tube(b, pts, [Vector2(th, 0.45), Vector2(th * 0.9, 0.38), Vector2(th * 0.7, 0.28), Vector2(th * 0.45, 0.16), Vector2(0.04, 0.04)], Color.WHITE, 8, 3, true, true, Callable(), Vector3.FORWARD)
	Loft.tube(b, [Vector3(-w * 0.55, 0.1, 0.6), Vector3(w * 0.55, 0.1, 0.6)], [Vector2(0.5, 0.25), Vector2(0.5, 0.25)], Color.WHITE, 8, 2)
	return b.build(null)


## Su kubbesi patlaması (kaynak: Samehada bitirişi, video 0:10): yerden hızla büyüyen yarı saydam soluk su yarım küresi,
## içinde köpüren beyaz sprey; sonra söner
static func dome(g: Vector3, r := 4.0) -> void:
	var mi = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 1.0; sm.height = 2.0; sm.is_hemisphere = true; sm.radial_segments = 32; sm.rings = 12
	mi.mesh = sm
	var m: ShaderMaterial = sheet_mat().duplicate()
	m.set_shader_parameter("alpha", 0.35)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	VFX.scene().add_child(mi)
	mi.global_position = g
	mi.scale = Vector3.ONE * 0.3
	var tw = mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE * r, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.25)
	tw.tween_method(func(a: float): m.set_shader_parameter("alpha", a), 0.35, 0.0, 0.35)
	tw.tween_callback(mi.queue_free)
	for k in 3:
		VFX.scene().get_tree().create_timer(k * 0.08).timeout.connect(func():
			spray(g + Vector3(randf_range(-1, 1), 0.3, randf_range(-1, 1)) * r * 0.4, 1.8, Vector3.UP, 45.0, 1.3, k == 0))
	ripple(g, r * 1.2)
