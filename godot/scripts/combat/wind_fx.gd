class_name WindFX
extends RefCounted
## Organik rüzgâr efektleri: görünür geometrik şekil YOK (koni / kubbe / kama / disk yapay duruyordu).
## Rüzgâr taşıdığı şeylerle görünür: kıvrılıp kopan ince akım çizgileri, yerden kalkan toz/kum, savrulan yaprak ve
## çakıl, hızla geçen ince hava lifleri, girdaplar. Vuruş alanları kodda kalır, oyuncu görmez.

const LINE := Color(1.0, 1.0, 1.0, 0.85)


static func _scene() -> Node:
	return VFX.scene()


## Zemin tozu rengi: çölde kum, karlıda kar, diğer yerlerde toprak
static func dust_col(pos: Vector3) -> Color:
	var b = Game.biome_at(pos.x, pos.z)   # 1 sahil, 3 çöl, 8 kar, 5/9 kaya-dağ
	if b in [1, 3]:
		return Color(0.93, 0.82, 0.6)
	if b == 8:
		return Color(0.95, 0.97, 1.0)
	if b in [5, 9]:
		return Color(0.72, 0.7, 0.66)
	return Color(0.8, 0.74, 0.62)


## Tek akım çizgisi: path(k: 0..1) -> dünya konumu boyunca ilerleyen ince, uçları sönen kurdele
static func streak(path: Callable, dur: float, width := 0.08, col := LINE, delay := 0.0, length := 16) -> void:
	var sc = _scene()
	if sc == null or VFX.busy():
		return
	var head = Node3D.new()
	sc.add_child(head)
	head.global_position = path.call(0.0)
	var start = func():
		if not is_instance_valid(head):
			return
		VFX.trail(head, width, Color(col.r, col.g, col.b, col.a), Color(col.r, col.g, col.b, col.a * 0.55), Color(col.r, col.g, col.b, 0.0), length, 0.25)
		var tw = head.create_tween()
		tw.tween_method(func(k: float):
			if is_instance_valid(head):
				head.global_position = path.call(k), 0.0, 1.0, dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(head.queue_free)
	if delay > 0.0:
		head.get_tree().create_timer(delay).timeout.connect(start)
	else:
		start.call()


## Ufka dik iki eksen (yan, yukarı) — d yönüne göre
static func _axes(d: Vector3) -> Array:
	var side = d.cross(Vector3.UP)
	if side.length() < 0.1:
		side = Vector3.RIGHT
	side = side.normalized()
	return [side, side.cross(d).normalized() * -1.0]


## Rüzgâr hamlesi: from'dan d yönüne length boyunca, uçta width genişliğe yayılan akım çizgileri + ince hava lifleri
## + yerde ilerleyen toz izi + savrulan yaprak/çakıl. opts: n, speed, dust (Color / false), leaves, lift, col, curl
static func gust(from: Vector3, d: Vector3, length: float, width: float, opts := {}) -> void:
	length *= VFX.epic
	width *= VFX.epic
	d = d.normalized()
	var ax = _axes(d)
	var side: Vector3 = ax[0]
	var up: Vector3 = ax[1]
	var n: int = opts.get("n", 14)
	var speed: float = opts.get("speed", 42.0)
	var col: Color = opts.get("col", LINE)
	var curl: float = opts.get("curl", 1.0)
	var lift: float = opts.get("lift", 0.0)
	var dur = clampf(length / speed, 0.25, 1.6)
	for i in n:
		var s0 = randf_range(-1.0, 1.0)
		var u0 = randf_range(-0.6, 1.0)
		var L = length * randf_range(0.65, 1.05)
		var wob = randf_range(0.15, 0.5) * width * 0.15
		var ph = randf() * TAU
		var cr = randf_range(0.6, 1.4) * curl
		var cs = 1.0 if randf() < 0.5 else -1.0
		var p0 = from + side * s0 * 0.35 + up * u0 * 0.3
		streak(func(k: float) -> Vector3:
			var spread = lerpf(0.15, 0.5, k) * width
			var p = p0 + d * L * k + side * (s0 * spread + sin(k * 9.0 + ph) * wob) + up * (u0 * spread * 0.45 + lift * k * k * L * 0.15)
			# uçta kıvrılıp kopar (rüzgâr girdabı)
			if k > 0.75:
				var q = (k - 0.75) / 0.25
				p += (side * cos(q * PI * cs) * 0.0 + up * sin(q * PI) * 0.6 + side * cs * (1.0 - cos(q * PI)) * 0.5) * cr
			return p, dur * randf_range(0.85, 1.2), randf_range(0.04, 0.12) * maxf(1.0, width * 0.12), col, randf() * 0.12, 18)
	# hızla geçen ince hava lifleri (kıvılcım dokusu yön boyunca hizalı)
	FX.burst(from + d * 0.8, {"amount": int(30 + width * 4), "life": dur * 0.9, "tex": FX.tex_spark, "size": 1.6 + width * 0.08, "vmin": speed * 0.7, "vmax": speed * 1.15,
		"dir": d, "spread": clampf(width * 2.2, 6.0, 35.0), "radius": 0.5, "damp": 1.0,
		"colors": [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.75), Color(1, 1, 1, 0.0)]})
	var dc = opts.get("dust", null)
	if not dc is bool or dc:
		var dcol: Color = dc if dc is Color else dust_col(from)
		wake(from, d, length, width, dcol, dur)
	if opts.get("leaves", true):
		debris_fly(from + d * 1.5, d, length, width)


## Yer boyunca ilerleyen toz/kum izi: yere yakın kısımlarda yol boyunca gecikmeli toz bulutları
static func wake(from: Vector3, d: Vector3, length: float, width: float, col: Color, dur: float) -> void:
	var sc = _scene()
	if sc == null:
		return
	var steps = clampi(int(length / 3.0), 3, 10)
	var dh = Vector3(d.x, 0, d.z).normalized()
	for k in steps:
		var t = float(k + 1) / steps
		var p = from + d * length * t
		var gy = Game.jutsu_floor(p.x, p.z)
		if p.y - gy > 4.0 + width * 0.3:
			continue
		var pp = Vector3(p.x, gy + 0.3, p.z)
		var w = lerpf(0.4, 1.0, t) * width
		var fire = func():
			FX.burst(pp, {"amount": int(6 + w * 1.5), "life": randf_range(0.9, 1.4), "tex": FX.tex_smoke, "add": false, "size": 1.4 + w * 0.22,
				"radius": w * 0.35, "vmin": 3.0, "vmax": 9.0 + w, "dir": (dh + Vector3.UP * 0.35).normalized(), "spread": 55.0, "damp": 2.5,
				"gravity": Vector3(0, -0.6, 0), "scale_curve": [[0.0, 0.35], [0.4, 1.0], [1.0, 1.25]], "outline_col": col.darkened(0.45),
				"colors": [Color(col.r, col.g, col.b, 0.95), Color(col.r, col.g, col.b, 0.6), Color(col.r, col.g, col.b, 0.0)]})
		sc.get_tree().create_timer(dur * t * 0.85).timeout.connect(fire)


## Savrulan yaprak ve çakıllar
static func debris_fly(from: Vector3, d: Vector3, length: float, width: float, n := 0) -> void:
	var cnt = n if n > 0 else int(10 + width * 2)
	FX.burst(from, {"amount": cnt, "life": 1.2, "tex": FX.tex_leaf, "size": 0.45, "vmin": length * 0.8, "vmax": length * 1.5, "dir": (d + Vector3.UP * 0.25).normalized(),
		"spread": clampf(width * 2.5, 10.0, 40.0), "radius": width * 0.2, "damp": 1.8, "spin": 12.0, "gravity": Vector3(0, -3.0, 0), "add": false,
		"colors": [Color(0.45, 0.62, 0.25, 1), Color(0.55, 0.45, 0.22, 1), Color(0.5, 0.4, 0.2, 0)]})


## Girdap: pos etrafında yükselerek dönen akım çizgileri + dönen toz. dur saniye boyunca dalgalar halinde
static func swirl(pos: Vector3, radius: float, height: float, dur := 1.0, n := 10, col := LINE, dust := true) -> void:
	radius *= VFX.epic
	height *= VFX.epic
	var sc = _scene()
	if sc == null:
		return
	var waves = maxi(1, int(dur / 0.35))
	for w in waves:
		for i in n:
			var a0 = randf() * TAU
			var turns = randf_range(0.8, 1.6) * (1.0 if randf() < 0.85 else -1.0)
			var r0 = radius * randf_range(0.5, 1.1)
			var h0 = randf_range(0.0, height * 0.3)
			var ht = height * randf_range(0.6, 1.0)
			streak(func(k: float) -> Vector3:
				var a = a0 + k * turns * TAU
				var r = r0 * lerpf(1.0, 0.7, k)
				return pos + Vector3(cos(a) * r, h0 + ht * k, sin(a) * r), randf_range(0.45, 0.7), randf_range(0.05, 0.12) * maxf(1.0, radius * 0.15), col, w * 0.35 + randf() * 0.15, 20)
		if dust:
			var dc = dust_col(pos)
			var gp = Vector3(pos.x, Game.jutsu_floor(pos.x, pos.z) + 0.3, pos.z)
			var f = func():
				FX.burst(gp, {"amount": int(8 + radius * 2), "life": 1.1, "tex": FX.tex_smoke, "add": false, "size": 1.2 + radius * 0.25, "radius": radius * 0.8,
					"vmin": 2.0, "vmax": 5.0, "dir": Vector3.UP, "spread": 30.0, "damp": 1.5, "tangent": 18.0 + radius * 2.0, "orbit": 0.6,
					"outline_col": dc.darkened(0.45), "scale_curve": [[0.0, 0.4], [0.5, 1.0], [1.0, 1.2]],
					"colors": [Color(dc.r, dc.g, dc.b, 0.9), Color(dc.r, dc.g, dc.b, 0.5), Color(dc.r, dc.g, dc.b, 0.0)]})
			sc.get_tree().create_timer(w * 0.35).timeout.connect(f)


## Patlama/basınç: merkezden her yöne kıvrılarak kaçan akım çizgileri + halka hâlinde kalkan toz + moloz (kubbe yerine)
static func blast(pos: Vector3, radius: float, n := 24, col := LINE, debris := true) -> void:
	radius *= VFX.epic
	var gy = Game.jutsu_floor(pos.x, pos.z)
	for i in n:
		var a = TAU * i / n + randf_range(-0.15, 0.15)
		var dir = Vector3(cos(a), randf_range(-0.05, 0.45), sin(a)).normalized()
		var L = radius * randf_range(0.7, 1.15)
		var ph = randf() * TAU
		var cs = 1.0 if randf() < 0.5 else -1.0
		var tng = Vector3(-dir.z, 0, dir.x) * cs
		var p0 = pos + dir * 0.4
		streak(func(k: float) -> Vector3:
			var p = p0 + dir * L * k + tng * sin(k * PI) * L * 0.18 + Vector3.UP * sin(k * 7.0 + ph) * 0.2
			if p.y < gy + 0.2:
				p.y = gy + 0.2
			return p, randf_range(0.35, 0.55), randf_range(0.06, 0.16) * maxf(1.0, radius * 0.1), col, randf() * 0.06, 16)
	var dc = dust_col(pos)
	var gp = Vector3(pos.x, gy + 0.3, pos.z)
	if pos.y - gy < radius:
		FX.burst(gp, {"amount": int(18 + radius * 2.5), "life": 1.4, "tex": FX.tex_smoke, "add": false, "size": 1.6 + radius * 0.2, "radius": radius * 0.2,
			"vmin": radius * 1.4, "vmax": radius * 2.4, "dir": Vector3.UP, "spread": 88.0, "damp": 3.0, "gravity": Vector3(0, -0.5, 0),
			"outline_col": dc.darkened(0.45), "scale_curve": [[0.0, 0.3], [0.35, 1.0], [1.0, 1.3]],
			"colors": [Color(dc.r, dc.g, dc.b, 0.95), Color(dc.r, dc.g, dc.b, 0.55), Color(dc.r, dc.g, dc.b, 0.0)]})
		if debris:
			VFX.debris(gp, dc.darkened(0.3), int(8 + radius), radius * 1.2, 0.35)
	FX.burst(pos, {"amount": int(30 + radius * 3), "life": 0.45, "tex": FX.tex_spark, "size": 2.0 + radius * 0.1, "vmin": radius * 3.0, "vmax": radius * 5.0,
		"spread": 180.0, "radius": 0.4, "damp": 2.0, "colors": [Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.0)]})


## Mermi görünümü (vakum mermisi / hava topu): merminin etrafında dönen ince akım çizgileri + soluk beyaz çekirdek.
## Küre/kabuk yok; parent mermidir, onunla birlikte ilerler. Parent henüz sahnede değilse sahneye girince kurulur.
static func bullet(parent: Node3D, size := 1.0, col := LINE) -> void:
	if parent.is_inside_tree():
		_bullet_build(parent, size, col)
	else:
		parent.tree_entered.connect(func(): _bullet_build(parent, size, col), CONNECT_ONE_SHOT)


static func _bullet_build(parent: Node3D, size: float, col: Color) -> void:
	var pivot = Node3D.new()
	parent.add_child(pivot)
	var arms = 3 if size < 1.2 else 4
	for i in arms:
		var h = Node3D.new()
		pivot.add_child(h)
		var a = TAU * i / arms
		h.position = Vector3(cos(a), sin(a), randf_range(-0.2, 0.2)) * size * 0.45
		var tr = VFX.trail(h, 0.07 * maxf(1.0, size), Color(col.r, col.g, col.b, col.a), Color(col.r, col.g, col.b, col.a * 0.45), Color(col.r, col.g, col.b, 0.0), 10, 0.25)
		tr.min_step = 0.12
	var tw = pivot.create_tween().set_loops()
	tw.tween_property(pivot, "rotation:z", TAU, 0.22).from(0.0)
	var tw2 = pivot.create_tween().set_loops()
	tw2.tween_property(pivot, "rotation:y", TAU, 0.9).from(0.0)
	# çekirdek: kameraya dönük çok soluk, yumuşak beyaz parıltı
	var core = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = Vector2.ONE * size * 1.1
	var m = StandardMaterial3D.new()
	m.albedo_texture = FX.tex_soft
	m.albedo_color = Color(1, 1, 1, 0.35)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	q.material = m
	core.mesh = q
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(core)
	# yolda saçılan ince hava lifleri
	FX.burst(Vector3.ZERO, {"parent": parent, "local": true, "amount": int(8 + size * 6), "life": 0.3, "tex": FX.tex_spark, "size": 0.8 + size * 0.4,
		"vmin": 4.0, "vmax": 9.0, "spread": 180.0, "radius": size * 0.3, "explosive": 0.0, "colors": [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.6), Color(1, 1, 1, 0.0)]})
