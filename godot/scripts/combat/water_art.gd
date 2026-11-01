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


## Sıçrama: su tacı hızla kabarır, yapraklar dışa devrilip çöker; damlalar yay çizip düşer. s: boyut (m)
static func splash(pos: Vector3, s := 1.0) -> void:
	if VFX.busy():
		return
	if _crowns.is_empty():
		for i in 3:
			_crowns.append(crown_mesh(9 + i, 77 + i))
	var sc = VFX.scene()
	var mi = MeshInstance3D.new()
	mi.mesh = _crowns[randi() % _crowns.size()]
	mi.material_override = mat()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sc.add_child(mi)
	var g = Game.jutsu_floor(pos.x, pos.z)
	mi.global_position = Vector3(pos.x, maxf(g, pos.y - s * 0.6), pos.z)
	mi.rotation.y = randf() * TAU
	mi.scale = Vector3(s * 0.6, 0.05, s * 0.6)
	var tw = mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(s * 1.1, s * 1.3, s * 1.1), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mi, "scale", Vector3(s * 1.6, s * 0.15, s * 1.6), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(mi.queue_free)
	drops(pos + Vector3.UP * s * 0.4, int(6 + s * 4), s)


## Su damlaları: iri, gövdeli damlalar yay çizip düşer, uçarken hıza göre uzar, yere değince yassılaşıp kaybolur
static func drops(pos: Vector3, n := 8, s := 1.0, vmax := 7.0, dir := Vector3.ZERO, spread := 0.5) -> void:
	if VFX.busy():
		return
	var sc = VFX.scene()
	var m = mat()
	for k in n:
		var mi = MeshInstance3D.new()
		mi.mesh = VFX._sphere(0.5, 10, 6)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sc.add_child(mi)
		var r = randf_range(0.1, 0.24) * sqrt(s)
		mi.global_position = pos
		var a = randf() * TAU
		var v = Vector3(cos(a), 0, sin(a)) * randf_range(1.0, vmax * 0.6) * sqrt(s) + Vector3.UP * randf_range(vmax * 0.5, vmax) * sqrt(s)
		if dir != Vector3.ZERO:   # yönlü akış (su seli/jet): ileri fırlayan su kütleleri
			v = (dir.normalized() + Vector3(randf_range(-spread, spread), randf_range(0.0, spread), randf_range(-spread, spread))).normalized() * randf_range(vmax * 0.7, vmax)
		var gy = Game.jutsu_floor(pos.x, pos.z)
		var st0 = {"landed": false}
		var tw = mi.create_tween()
		tw.tween_method(func(t: float):
			if not is_instance_valid(mi) or st0["landed"]:
				return
			var p = pos + v * t + Vector3.DOWN * 11.0 * t * t
			if p.y <= gy + 0.03 and t > 0.05:
				st0["landed"] = true
				mi.global_position = Vector3(p.x, gy + 0.03, p.z)
				var tl = mi.create_tween()
				tl.tween_property(mi, "scale", Vector3(r * 2.4, 0.01, r * 2.4), 0.25)
				tl.tween_callback(mi.queue_free)
				return
			mi.global_position = p
			var sp = v + Vector3.DOWN * 22.0 * t
			if sp.length() > 0.1:
				mi.look_at(p + sp, Vector3.UP if absf(sp.normalized().y) < 0.95 else Vector3.RIGHT)
			mi.scale = Vector3(r, r, r * (1.0 + clampf(sp.length() * 0.12, 0.0, 1.6))), 0.0, 1.6, 1.6)
		tw.tween_callback(func():
			if is_instance_valid(mi):
				mi.queue_free())
