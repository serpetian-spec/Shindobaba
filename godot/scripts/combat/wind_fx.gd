class_name WindFX
extends RefCounted
## Anime rüzgârı: sert kenarlı geometrik kabuk YOK (koni / kubbe / kama / disk yapay duruyordu).
## Rüzgâr animedeki gibi görünür: yumuşak kenarlı, yarı saydam, beyaz-mavimsi akan perdeler (içinde boyuna akım
## çizgileri), üstünde birkaç parlak ince akım çizgisi, altında az ve yumuşak toz, birkaç savrulan yaprak.
## Vuruş alanları kodda kalır, oyuncu görmez.

const LINE := Color(1.0, 1.0, 1.0, 0.9)
const SHEET := Color(0.86, 0.95, 1.0, 1.0)
static var _sheet_mats := {}


static func _scene() -> Node:
	return VFX.scene()


## Zemin tozu rengi: çölde kum, karlıda kar, kayalıkta gri, diğer yerlerde açık toprak
static func dust_col(pos: Vector3) -> Color:
	var b = Game.biome_at(pos.x, pos.z)   # 1 sahil, 3 çöl, 8 kar, 5/9 kaya-dağ
	if b in [1, 3]:
		return Color(0.95, 0.86, 0.68)
	if b == 8:
		return Color(0.96, 0.98, 1.0)
	if b in [5, 9]:
		return Color(0.8, 0.78, 0.74)
	return Color(0.86, 0.8, 0.7)


static func sheet_mat(tint: Color, opacity := 0.55) -> ShaderMaterial:
	var key = "%s|%.2f" % [tint, opacity]
	if not _sheet_mats.has(key):
		var m = ShaderMaterial.new()
		m.shader = load("res://shaders/vfx_wind_sheet.gdshader")
		m.set_shader_parameter("tint", tint)
		m.set_shader_parameter("opacity", opacity)
		_sheet_mats[key] = m
	return _sheet_mats[key]


## Bir yol boyunca ilerleyen kurdele: path(k: 0..1) -> dünya konumu. mat verilirse perde (geniş), yoksa ince akım çizgisi
static func streak(path: Callable, dur: float, width := 0.08, col := LINE, delay := 0.0, length := 16, mat: Material = null) -> void:
	var sc = _scene()
	if sc == null or VFX.busy():
		return
	if mat == null:
		# Fūton (ref fuuton*.png): rüzgâr bıçağı çizgileri belirgin beyaz, kalın ve biraz daha uzun ömürlü (ince soluk çizgi kayboluyordu)
		width *= 1.6
		col = Color(col.r, col.g, col.b, col.a).lerp(Color(1, 1, 1, col.a), 0.45)
		col.a = minf(1.0, col.a * 1.3)
		dur *= 1.2
		length = int(length * 1.4)
	var head = Node3D.new()
	sc.add_child(head)
	head.global_position = path.call(0.0)
	var start = func():
		if not is_instance_valid(head):
			return
		var tr = VFX.trail(head, width, Color(col.r, col.g, col.b, col.a), Color(col.r, col.g, col.b, col.a * 0.55), Color(col.r, col.g, col.b, 0.0), length, 0.25)
		if mat != null:
			tr.material_override = mat
			tr.min_step = 0.25
		var tw = head.create_tween()
		tw.tween_method(func(k: float):
			if is_instance_valid(head):
				head.global_position = path.call(k), 0.0, 1.0, dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(head.queue_free)
	if delay > 0.0:
		head.get_tree().create_timer(delay).timeout.connect(start)
	else:
		start.call()


## Geniş rüzgâr perdesi (anime): yumuşak kenarlı, yarı saydam akış
static func sheet(path: Callable, dur: float, width: float, tint := SHEET, delay := 0.0, opacity := 0.55) -> void:
	streak(path, dur, width, Color(1, 1, 1, 1), delay, 22, sheet_mat(tint, opacity))


## Ufka dik iki eksen (yan, yukarı) — d yönüne göre
static func _axes(d: Vector3) -> Array:
	var side = d.cross(Vector3.UP)
	if side.length() < 0.1:
		side = Vector3.RIGHT
	side = side.normalized()
	return [side, side.cross(d).normalized() * -1.0]


## Rüzgâr hamlesi: from'dan d yönüne length boyunca, uçta width genişliğe yayılan perdeler + parlak akım çizgileri
## + az yumuşak toz + birkaç yaprak. opts: n (çizgi), sheets, speed, dust (Color / false), leaves, lift, col, tint, curl
static func gust(from: Vector3, d: Vector3, length: float, width: float, opts := {}) -> void:
	length *= VFX.epic
	width *= VFX.epic
	d = d.normalized()
	Dangle.gust(from + d * length * 0.5, d * 28.0, maxf(length * 0.6, width), 0.7)   # yoldaki saç/kumaş savrulur
	var ax = _axes(d)
	var side: Vector3 = ax[0]
	var up: Vector3 = ax[1]
	var n: int = int(opts.get("n", 14) * 0.6)
	var speed: float = opts.get("speed", 42.0)
	var col: Color = opts.get("col", LINE)
	var tint: Color = opts.get("tint", SHEET if col == LINE else Color(col.r, col.g, col.b, 1.0))
	var curl: float = opts.get("curl", 1.0)
	var lift: float = opts.get("lift", 0.0)
	var dur = clampf(length / speed, 0.25, 1.6)
	# perdeler: merkezde geniş, yanlarda dar; hafif kıvrılarak ilerler
	var ns: int = opts.get("sheets", clampi(int(2 + width * 0.45), 3, 8))
	for i in ns:
		var s0 = lerpf(-1.0, 1.0, (i + 0.5) / ns) + randf_range(-0.15, 0.15)
		var u0 = randf_range(-0.3, 0.6)
		var L = length * randf_range(0.85, 1.05)
		var ph = randf() * TAU
		var bend = randf_range(-0.12, 0.12) * width
		var w = width * randf_range(0.28, 0.42) * (1.0 - absf(s0) * 0.35)
		var p0 = from + side * s0 * 0.3 + up * u0 * 0.25
		sheet(func(k: float) -> Vector3:
			var spread = lerpf(0.12, 0.42, k) * width
			return p0 + d * L * k + side * (s0 * spread + sin(k * PI) * bend + sin(k * 6.0 + ph) * 0.15) + up * (u0 * spread * 0.4 + lift * k * k * L * 0.15),
			dur * randf_range(0.95, 1.15), w, tint, randf() * 0.06, opts.get("opacity", 0.62))
	# parlak ince akım çizgileri, uçta kıvrılıp kopar
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
			if k > 0.75:
				var q = (k - 0.75) / 0.25
				p += (up * sin(q * PI) * 0.6 + side * cs * (1.0 - cos(q * PI)) * 0.5) * cr
			return p, dur * randf_range(0.85, 1.2), randf_range(0.05, 0.1) * maxf(1.0, width * 0.1), col, randf() * 0.12, 18)
	# hızla geçen ince hava lifleri
	FX.burst(from + d * 0.8, {"amount": int(16 + width * 2), "life": dur * 0.9, "tex": FX.tex_spark, "size": 1.4 + width * 0.06, "vmin": speed * 0.7, "vmax": speed * 1.15,
		"dir": d, "spread": clampf(width * 2.0, 6.0, 30.0), "radius": 0.5, "damp": 1.0,
		"colors": [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0.0)]})
	var dc = opts.get("dust", null)
	if not dc is bool or dc:
		var dcol: Color = dc if dc is Color else dust_col(from)
		wake(from, d, length, width, dcol, dur)
	if opts.get("leaves", true):
		debris_fly(from + d * 1.5, d, length, width)


## Yumuşak toz bulutu (anime): açık ton, ince ve açık kontur, pürüzsüz kenar — kaba siyah konturlu topak değil
static func soft_dust(pos: Vector3, cfg: Dictionary, col: Color) -> void:
	var c = {"tex": FX.tex_smoke, "add": false, "cel": true, "rough": 0.14, "shade": 0.18, "outline": 0.025, "outline_col": col.darkened(0.22),
		"glow": 1.0, "damp": 2.5, "scale_curve": [[0.0, 0.35], [0.4, 1.0], [1.0, 1.2]],
		"colors": [Color(col.r, col.g, col.b, 0.8), Color(col.r, col.g, col.b, 0.45), Color(col.r, col.g, col.b, 0.0)]}
	c.merge(cfg, true)
	FX.burst(pos, c)


## Yer boyunca ilerleyen toz izi: yere yakın kısımlarda yol boyunca gecikmeli, küçük yumuşak toz
static func wake(from: Vector3, d: Vector3, length: float, width: float, col: Color, dur: float) -> void:
	var sc = _scene()
	if sc == null:
		return
	var steps = clampi(int(length / 5.0), 2, 5)
	var dh = Vector3(d.x, 0, d.z).normalized()
	for k in steps:
		var t = float(k + 1) / steps
		var p = from + d * length * t
		var gy = Game.jutsu_floor(p.x, p.z)
		if p.y - gy > 3.5 + width * 0.25:
			continue
		var pp = Vector3(p.x, gy + 0.2, p.z)
		var w = lerpf(0.4, 1.0, t) * width
		var fire = func():
			soft_dust(pp, {"amount": int(3 + w * 0.6), "life": randf_range(0.8, 1.2), "size": 0.8 + w * 0.1, "radius": w * 0.3,
				"vmin": 2.0, "vmax": 6.0 + w * 0.5, "dir": (dh + Vector3.UP * 0.25).normalized(), "spread": 50.0, "gravity": Vector3(0, -0.4, 0)}, col)
		sc.get_tree().create_timer(dur * t * 0.85).timeout.connect(fire)


## Savrulan yaprak ve çakıllar (az)
static func debris_fly(from: Vector3, d: Vector3, length: float, width: float, n := 0) -> void:
	var cnt = n if n > 0 else int(5 + width)
	FX.burst(from, {"amount": cnt, "life": 1.2, "tex": FX.tex_leaf, "size": 0.4, "vmin": length * 0.8, "vmax": length * 1.5, "dir": (d + Vector3.UP * 0.25).normalized(),
		"spread": clampf(width * 2.5, 10.0, 40.0), "radius": width * 0.2, "damp": 1.8, "spin": 12.0, "gravity": Vector3(0, -3.0, 0), "add": false,
		"colors": [Color(0.45, 0.62, 0.25, 1), Color(0.55, 0.45, 0.22, 1), Color(0.5, 0.4, 0.2, 0)]})


## Girdap: pos etrafında yükselerek dönen perdeler + çizgiler + az toz. dur saniye boyunca dalgalar halinde
static func swirl(pos: Vector3, radius: float, height: float, dur := 1.0, n := 10, col := LINE, dust := true) -> void:
	radius *= VFX.epic
	height *= VFX.epic
	var sc = _scene()
	if sc == null:
		return
	var tint = SHEET if col == LINE else Color(col.r, col.g, col.b, 1.0)
	var waves = maxi(1, int(dur / 0.35))
	for w in waves:
		var ns = maxi(2, n / 3)
		for i in n:
			var a0 = randf() * TAU
			var turns = randf_range(0.8, 1.4) * (1.0 if randf() < 0.85 else -1.0)
			var r0 = radius * randf_range(0.6, 1.1)
			var h0 = randf_range(0.0, height * 0.3)
			var ht = height * randf_range(0.6, 1.0)
			var pth = func(k: float) -> Vector3:
				var a = a0 + k * turns * TAU
				var r = r0 * lerpf(1.0, 0.75, k)
				return pos + Vector3(cos(a) * r, h0 + ht * k, sin(a) * r)
			if i < ns:
				sheet(pth, randf_range(0.5, 0.75), radius * randf_range(0.45, 0.7), tint, w * 0.35 + randf() * 0.1, 0.5)
			else:
				streak(pth, randf_range(0.45, 0.7), randf_range(0.05, 0.1) * maxf(1.0, radius * 0.12), col, w * 0.35 + randf() * 0.15, 20)
		if dust and w % 2 == 0:
			var dc = dust_col(pos)
			var gp = Vector3(pos.x, Game.jutsu_floor(pos.x, pos.z) + 0.2, pos.z)
			var f = func():
				soft_dust(gp, {"amount": int(4 + radius), "life": 1.0, "size": 0.8 + radius * 0.12, "radius": radius * 0.8,
					"vmin": 1.5, "vmax": 4.0, "dir": Vector3.UP, "spread": 30.0, "damp": 1.5, "tangent": 18.0 + radius * 2.0, "orbit": 0.6}, dc)
			sc.get_tree().create_timer(w * 0.35).timeout.connect(f)


## Patlama/basınç: merkezden her yöne kıvrılarak kaçan perdeler ve çizgiler + yerde yumuşak toz halkası (kubbe yerine)
static func blast(pos: Vector3, radius: float, n := 24, col := LINE, debris := true) -> void:
	radius *= VFX.epic
	var gy = Game.jutsu_floor(pos.x, pos.z)
	var tint = SHEET if col == LINE else Color(col.r, col.g, col.b, 1.0)
	var ns = clampi(n / 3, 4, 12)
	for i in n:
		var a = TAU * i / n + randf_range(-0.15, 0.15)
		var dir = Vector3(cos(a), randf_range(-0.05, 0.45), sin(a)).normalized()
		var L = radius * randf_range(0.7, 1.15)
		var ph = randf() * TAU
		var cs = 1.0 if randf() < 0.5 else -1.0
		var tng = Vector3(-dir.z, 0, dir.x) * cs
		var p0 = pos + dir * 0.4
		var pth = func(k: float) -> Vector3:
			var p = p0 + dir * L * k + tng * sin(k * PI) * L * 0.18 + Vector3.UP * sin(k * 7.0 + ph) * 0.2
			if p.y < gy + 0.2:
				p.y = gy + 0.2
			return p
		if i % maxi(1, n / ns) == 0:
			sheet(pth, randf_range(0.4, 0.6), radius * randf_range(0.3, 0.45), tint, randf() * 0.05, 0.5)
		else:
			streak(pth, randf_range(0.35, 0.55), randf_range(0.06, 0.12) * maxf(1.0, radius * 0.08), col, randf() * 0.06, 16)
	GroundFX.wind(pos, radius)   # rüzgâr yanan zemini büyütür
	var dc = dust_col(pos)
	var gp = Vector3(pos.x, gy + 0.2, pos.z)
	if pos.y - gy < radius:
		soft_dust(gp, {"amount": int(8 + radius), "life": 1.2, "size": 1.0 + radius * 0.1, "radius": radius * 0.2,
			"vmin": radius * 1.2, "vmax": radius * 2.0, "dir": Vector3.UP, "spread": 88.0, "damp": 3.0, "gravity": Vector3(0, -0.4, 0)}, dc)
		if debris:
			VFX.debris(gp, dc.darkened(0.3), int(4 + radius * 0.5), radius, 0.25)
	FX.burst(pos, {"amount": int(20 + radius * 2), "life": 0.4, "tex": FX.tex_spark, "size": 1.8 + radius * 0.08, "vmin": radius * 3.0, "vmax": radius * 5.0,
		"spread": 180.0, "radius": 0.4, "damp": 2.0, "colors": [Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.0)]})


## Mermi görünümü (vakum mermisi / hava topu): merminin etrafında dönen akım çizgileri + yumuşak beyaz-mavi çekirdek.
## Sert küre/kabuk yok; parent mermidir. Parent henüz sahnede değilse sahneye girince kurulur.
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
		var tr = VFX.trail(h, 0.25 * size, Color.WHITE, Color.WHITE, Color.WHITE, 12, 0.0)
		tr.material_override = sheet_mat(SHEET, 0.6)
		tr.min_step = 0.1
	var tw = pivot.create_tween().set_loops()
	tw.tween_property(pivot, "rotation:z", TAU, 0.22).from(0.0)
	var tw2 = pivot.create_tween().set_loops()
	tw2.tween_property(pivot, "rotation:y", TAU, 0.9).from(0.0)
	# çekirdek: kameraya dönük yumuşak beyaz-mavi parıltı (sıkışmış hava)
	for k in 2:
		var core = MeshInstance3D.new()
		var q = QuadMesh.new()
		q.size = Vector2.ONE * size * (0.9 if k == 0 else 0.45)
		var m = StandardMaterial3D.new()
		m.albedo_texture = FX.tex_soft
		m.albedo_color = Color(0.85, 0.95, 1.0, 0.12) if k == 0 else Color(1, 1, 1, 0.2)   # soluk: beyaz top duman gibi duruyordu
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		q.material = m
		core.mesh = q
		core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(core)
	FX.burst(Vector3.ZERO, {"parent": parent, "local": true, "amount": int(8 + size * 6), "life": 0.3, "tex": FX.tex_spark, "size": 0.8 + size * 0.4,
		"vmin": 4.0, "vmax": 9.0, "spread": 180.0, "radius": size * 0.3, "explosive": 0.0, "colors": [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.6), Color(1, 1, 1, 0.0)]})
