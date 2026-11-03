class_name BuildFeatures
extends RefCounted
## features.json'daki doğal yapılar ve yol kenarı süslerini (çarpışmalı) kurar.
## Her yapı kendi Builder'ında değil, 1 km'lik bölge builder'larında toplanır (az düğüm).

const REGION := 1024.0


static func build_all(parent: Node3D) -> void:
	var list = JSON.parse_string(FileAccess.get_file_as_string("res://data/world/features.json"))
	if list == null:
		return
	var builders = {}
	var rng = RandomNumberGenerator.new()
	rng.seed = 99
	for f in list:
		var key = Vector2i(int(floor(float(f["x"]) / REGION)), int(floor(float(f["y"]) / REGION)))
		if not builders.has(key):
			var b = Builder.new(parent, 0.0, 0.0, 0.0, "Yapilar_%d_%d" % [key.x, key.y])
			b.view_dist = 2200.0
			builders[key] = b
		_build(builders[key], f, rng)
	for k in builders:
		builders[k].finish()


static func _build(b: Builder, f: Dictionary, rng: RandomNumberGenerator) -> void:
	var x: float = f["x"]
	var n: float = f["y"]
	var g: float = f["g"]
	var yaw: float = f["yaw"]
	match f["t"]:
		"pillar":
			_pillar(b, x, n, g, f["h"], f["r"], rng, Color(0.58, 0.48, 0.38))
		"spire":
			_pillar(b, x, n, g, f["h"], f["r"], rng, Color(0.5, 0.52, 0.52), true)
		"mesa":
			_pillar(b, x, n, g, f["h"], f["r"], rng, Color(0.82, 0.62, 0.42))
		"arch":
			var r: float = f["r"]
			var h: float = f["h"]
			var c = Color(0.8, 0.58, 0.4)
			for sx in [-1.0, 1.0]:
				var o = Builder.rot(r * 0.5 * sx, 0, yaw)
				b.box(Vector3(x + o.x, g + h * 0.5 - 2, n + o.y), Vector3(7, h + 4, 8), c.darkened(rng.randf() * 0.1), yaw)
			b.box(Vector3(x, g + h + 1.5, n), Vector3(r + 7, 6, 8), c.lightened(0.05), yaw)
			b.box(Vector3(x, g + h + 4.8, n), Vector3(r * 0.7, 2.0, 7), c, yaw)
		"lantern":  # taş fener (tōrō)
			var c = Color(0.62, 0.6, 0.56)
			b.box(Vector3(x, g + 0.25, n), Vector3(0.9, 0.5, 0.9), c, yaw)
			b.cyl(Vector3(x, g + 1.0, n), 0.35, 1.1, c, false, 6)
			b.box(Vector3(x, g + 1.75, n), Vector3(0.75, 0.55, 0.75), c.lightened(0.05), yaw, false)
			b.box(Vector3(x, g + 1.75, n), Vector3(0.45, 0.35, 0.8), Color(0.25, 0.22, 0.2), yaw, false)
			b.cone(Vector3(x, g + 2.05, n), 1.4, 0.6, c, 4)
			b.sphere(Vector3(x, g + 2.45, n), Vector3(0.22, 0.22, 0.22), c, 6)
		"shrine":  # küçük yol tapınağı
			var wood = Color(0.55, 0.38, 0.24)
			b.box(Vector3(x, g + 0.4, n), Vector3(3.2, 0.8, 3.0), Color(0.6, 0.58, 0.54), yaw)
			b.box(Vector3(x, g + 1.6, n), Vector3(2.2, 1.6, 1.8), wood, yaw)
			b.roof(Vector3(x, g + 2.4, n), Vector3(3.0, 1.2, 2.6), Color(0.25, 0.25, 0.3), yaw)
			var fo = Builder.rot(0, -1.0, yaw)
			b.box(Vector3(x + fo.x, g + 1.5, n + fo.y), Vector3(0.8, 0.9, 0.05), Color(0.85, 0.15, 0.12), yaw, false)
			var t1 = Builder.rot(0, -3.0, yaw)
			_torii(b, x + t1.x, n + t1.y, g, yaw, 0.55)
		"torii":
			_torii(b, x, n, g, yaw, 1.0)
		"jizo":  # taş heykelcik + kırmızı önlük
			var c = Color(0.6, 0.58, 0.55)
			b.box(Vector3(x, g + 0.2, n), Vector3(1.0, 0.4, 1.0), c, yaw)
			b.cyl(Vector3(x, g + 0.85, n), 0.6, 0.9, c, false, 8)
			b.sphere(Vector3(x, g + 1.5, n), Vector3(0.5, 0.5, 0.5), c, 8)
			b.box(Vector3(x, g + 1.05, n), Vector3(0.65, 0.3, 0.65), Color(0.85, 0.15, 0.12), yaw, false)
		"sign":  # yön tabelası
			var wood = Color(0.55, 0.4, 0.26)
			b.box(Vector3(x, g + 1.4, n), Vector3(0.2, 2.8, 0.2), wood, yaw, false)
			b.box(Vector3(x, g + 2.4, n), Vector3(1.8, 0.4, 0.08), wood.lightened(0.1), yaw + 20, false)
			b.box(Vector3(x, g + 1.9, n), Vector3(1.6, 0.35, 0.08), wood.lightened(0.05), yaw - 30, false)
		"teahouse":  # çay evi / mola yeri
			var wood = Color(0.58, 0.42, 0.28)
			b.box(Vector3(x, g + 2.0, n), Vector3(9, 4, 7), Color(0.92, 0.88, 0.78), yaw)
			b.roof(Vector3(x, g + 4.0, n), Vector3(11, 3.0, 9), Color(0.3, 0.32, 0.38), yaw)
			var fo = Builder.rot(0, -4.6, yaw)
			b.box(Vector3(x + fo.x, g + 3.4, n + fo.y), Vector3(9.5, 0.2, 2.5), Color(0.8, 0.25, 0.2), yaw, false, Vector3(-15, 0, 0))
			for k in 3:
				var bo = Builder.rot(-3 + k * 3, -6.0, yaw)
				b.box(Vector3(x + bo.x, g + 0.5, n + bo.y), Vector3(2.0, 0.15, 0.7), Color(0.85, 0.2, 0.18), yaw)
				b.box(Vector3(x + bo.x, g + 0.25, n + bo.y), Vector3(0.15, 0.5, 0.15), wood, yaw, false)
			# kırmızı şemsiye (nodate gasa)
			var uo = Builder.rot(4.0, -6.5, yaw)
			b.cyl(Vector3(x + uo.x, g + 1.4, n + uo.y), 0.08, 2.8, wood, false, 4)
			b.cone(Vector3(x + uo.x, g + 2.9, n + uo.y), 3.4, 0.7, Color(0.85, 0.18, 0.15), 12)
			b.interact(Vector3(x + fo.x, g, n + fo.y), 5, "teahouse", "[F] Çay evi: mola ver (20 Ryō, can + chakra dolar)")
		"bridge":  # nehir üstü ahşap kemer köprü
			var wood = Color(0.55, 0.38, 0.24)
			var L = 46.0
			var water_y = 0.0
			for k in 12:
				var t = (k + 0.5) / 12.0
				var lift = sin(t * PI) * 2.2
				var o = Builder.rot(0, (t - 0.5) * L, yaw)
				b.box(Vector3(x + o.x, water_y + 1.6 + lift, n + o.y), Vector3(5.0, 0.35, L / 12.0 + 0.3), wood, yaw, true, Vector3(-cos(t * PI) * 10.0, 0, 0))
				for sx in [-1.0, 1.0]:
					var ro = Builder.rot(2.4 * sx, (t - 0.5) * L, yaw)
					b.box(Vector3(x + ro.x, water_y + 2.4 + lift, n + ro.y), Vector3(0.15, 1.2, 0.15), Color(0.8, 0.2, 0.15), yaw, false)
			for k in 4:
				var po = Builder.rot(0, (k / 3.0 - 0.5) * L * 0.8, yaw)
				b.box(Vector3(x + po.x, water_y - 2.0, n + po.y), Vector3(4.0, 7.0, 1.0), wood.darkened(0.2), yaw, false)
		"paddy":  # su dolu pirinç tarlası (basamak)
			var r: float = f["r"]
			b.box(Vector3(x, g + 0.3, n), Vector3(r, 0.6, r * 0.8), Color(0.45, 0.38, 0.26), yaw)
			b.box(Vector3(x, g + 0.62, n), Vector3(r - 1.6, 0.05, r * 0.8 - 1.6), Color(0.45, 0.62, 0.62), yaw, false)
			for k in int(r / 2.5):
				var o = Builder.rot(-r * 0.5 + 1.6 + k * 2.5, 0, yaw)
				b.box(Vector3(x + o.x, g + 0.9, n + o.y), Vector3(0.5, 0.6, r * 0.8 - 2.5), Color(0.5, 0.78, 0.32), yaw, false)


static func _pillar(b: Builder, x: float, n: float, g: float, h: float, r: float, rng: RandomNumberGenerator, c: Color, spire := false) -> void:
	## Katmanlı kaya sütunu: üst üste daralan halkalar (tabaka çizgileri), tepesi düz (üstünde durulur)
	var layers = 4 + int(h / 18.0)
	var y = g - 3.0
	for i in layers:
		var lh = (h + 3.0) / layers
		var k = 1.0 - float(i) / layers * (0.55 if spire else 0.25)
		var rr = r * k * rng.randf_range(0.92, 1.05)
		var cc = c.darkened(0.12 * float(i % 2)).lightened(rng.randf_range(-0.04, 0.04))
		b.cyl(Vector3(x + rng.randf_range(-0.4, 0.4), y + lh * 0.5, n + rng.randf_range(-0.4, 0.4)), rr * 2.0, lh, cc, true, 9)
		y += lh
	if spire:
		b.cone(Vector3(x, y + r * 0.6, n), r * 0.9, r * 1.6, c.lightened(0.05), 8)
	else:
		# tepede çimen örtüsü + bir iki ağaç
		b.cyl(Vector3(x, y + 0.2, n), r * 1.55, 0.6, Color(0.42, 0.6, 0.3), true, 9)
	# dipte döküntü kayalar
	for k in 3:
		var a = rng.randf() * TAU
		b.sphere(Vector3(x + cos(a) * r * 1.1, g + 0.6, n + sin(a) * r * 1.1), Vector3(3, 2, 2.5) * rng.randf_range(0.6, 1.4), c.darkened(0.15), 6)


static func _torii(b: Builder, x: float, n: float, g: float, yaw: float, s: float) -> void:
	# yolun üstündeyse yolu tam kaplasın: direkler yol kenarının dışında (dar torii yolun ortasında kalıyordu)
	var c0 = b.w(Vector3(x, 0, n))
	if Game.road_at(c0.x, c0.z) > 0.3:
		var ax = Builder.rot(1.0, 0.0, yaw)
		var axw = Vector3(ax.x, 0, -ax.y)
		var ext = [0.0, 0.0]
		for k in 2:
			var sg = 1.0 if k == 0 else -1.0
			var d = 0.0
			while d < 24.0 and Game.road_at(c0.x + axw.x * d * sg, c0.z + axw.z * d * sg) > 0.12:
				d += 0.5
			ext[k] = d
		var need = (ext[0] + ext[1] + 2.0) / 5.2
		if need > s and ext[0] < 24.0 and ext[1] < 24.0:   # 24 m'ye ulaştıysa torii yol boyunca duruyor: ölçekleme
			var mid = (ext[0] - ext[1]) * 0.5   # yolun ortasına kaydır
			x += ax.x * mid
			n += ax.y * mid
			s = need
	# hazır torii modeli (kırmızı, siyah üst kiriş)
	if b.prop("torii_red", Vector3(x, g - 0.1, n), yaw, 7.2 * s):
		for sx2 in [-1.0, 1.0]:
			var o2 = Builder.rot(2.6 * s * sx2, 0, yaw)
			b._collide_cyl(b.w(Vector3(x + o2.x, g + 3.0 * s, n + o2.y)), 0.35 * s, 6.0 * s)
		return
	var red = Color(0.85, 0.18, 0.12)
	for sx in [-1.0, 1.0]:
		var o = Builder.rot(2.4 * s * sx, 0, yaw)
		b.cyl(Vector3(x + o.x, g + 2.6 * s, n + o.y), 0.45 * s, 5.2 * s, red, true, 8)
	b.box(Vector3(x, g + 5.35 * s, n), Vector3(7.0 * s, 0.4 * s, 0.6 * s), Color(0.15, 0.12, 0.12), yaw, false)
	b.box(Vector3(x, g + 5.0 * s, n), Vector3(6.4 * s, 0.35 * s, 0.5 * s), red, yaw, false)
	b.box(Vector3(x, g + 4.2 * s, n), Vector3(5.6 * s, 0.3 * s, 0.4 * s), red, yaw, false)
