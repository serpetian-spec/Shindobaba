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


## Sıçrama (kaynak: Kisame Storm videosu): yoğun beyaz-soluk camgöbeği SPREY — yukarı fışkırıp düşen ince su çizgileri
## ve minik damlalar; altta yarı saydam soluk su tacı; yerde kısa süren yarı saydam su halkası. Kalın topak/parça yok.
static func splash(pos: Vector3, s := 1.0) -> void:
	if VFX.busy():
		return
	var g = Game.jutsu_floor(pos.x, pos.z)
	var base = Vector3(pos.x, maxf(g, pos.y - s * 0.6), pos.z)
	spray(base + Vector3.UP * 0.2, s, Vector3.UP, 35.0, 1.0, true)
	if _crowns.is_empty():
		for i in 3:
			_crowns.append(crown_mesh(9 + i, 77 + i))
	var mi = MeshInstance3D.new()
	mi.mesh = _crowns[randi() % _crowns.size()]
	mi.material_override = sheet_mat()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	VFX.scene().add_child(mi)
	mi.global_position = base
	mi.rotation.y = randf() * TAU
	mi.scale = Vector3(s * 0.5, 0.05, s * 0.5)
	var tw = mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(s * 0.85, s * 0.9, s * 0.85), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mi, "scale", Vector3(s * 1.3, s * 0.1, s * 1.3), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(mi.queue_free)
	if pos.y - g < 1.5 + s:
		ripple(Vector3(pos.x, g, pos.z), s * 1.4)


## Soluk, yarı saydam su yüzeyi malzemesi (taç, halka): videodaki gibi mat çelik-camgöbeği, beyaz akış çizgili
static var _sheet: ShaderMaterial
static func sheet_mat() -> ShaderMaterial:
	if _sheet == null:
		_sheet = VFX.mat_water(Color(0.05, 0.28, 0.78), Color(0.2, 0.55, 0.98), Color(0.62, 0.88, 1.0), Vector3.UP, 0.62, 0.9, 0.08).duplicate()
	return _sheet


## İnce su spreyi: hızla fışkırıp yerçekimiyle düşen beyaz/camgöbeği su çizgileri + minik damla noktaları + hafif su sisi
static func spray(pos: Vector3, s := 1.0, dir := Vector3.UP, spread := 35.0, speed := 1.0, mist := false) -> void:
	if VFX.busy():
		return
	var v = (7.0 + s * 3.0) * speed
	FX.burst(pos, {"amount": int(26 + s * 22), "life": 0.75, "tex": FX.tex_spark, "add": false, "cel": false, "size": 0.55 + s * 0.12, "radius": 0.25 * s,
		"vmin": v * 0.5, "vmax": v, "dir": dir, "spread": spread, "gravity": Vector3(0, -20, 0), "damp": 0.4,
		"colors": [Color(1, 1, 1, 1), Color(0.86, 0.95, 1.0, 0.95), Color(0.7, 0.87, 0.97, 0.0)]})
	FX.burst(pos, {"amount": int(30 + s * 30), "life": 0.85, "tex": FX.tex_soft, "add": false, "cel": false, "size": 0.09 + s * 0.02, "radius": 0.35 * s,
		"vmin": v * 0.35, "vmax": v * 1.1, "dir": dir, "spread": spread + 15.0, "gravity": Vector3(0, -20, 0), "damp": 0.3, "smin": 0.4, "smax": 1.0,
		"colors": [Color(1, 1, 1, 1), Color(0.9, 0.97, 1.0, 1), Color(0.75, 0.9, 1.0, 0.0)]})
	if not mist:
		return
	FX.burst(pos + Vector3.UP * 0.3 * s, {"amount": int(3 + s * 2), "life": 0.8, "tex": FX.tex_smoke, "add": false, "cel": false, "size": 1.0 * s + 0.5, "radius": 0.4 * s,
		"vmin": 0.8, "vmax": 2.0, "dir": dir, "spread": 60.0, "damp": 2.0, "colors": [Color(0.92, 0.97, 1.0, 0.0), Color(0.9, 0.96, 1.0, 0.35), Color(0.9, 0.96, 1.0, 0.0)]})


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
