class_name Props
extends RefCounted
## Paylaşılan materyaller + bitki örtüsü meshleri.

static var _toon: ShaderMaterial
static var _foliage: ShaderMaterial
static var _stone: ShaderMaterial


static func toon() -> ShaderMaterial:
	if _toon == null:
		_toon = ShaderMaterial.new()
		_toon.shader = load("res://shaders/toon.gdshader")
		_toon.set_shader_parameter("rim_amount", 0.15)
		_toon.set_shader_parameter("detail_noise", 0.18)
	return _toon


static func foliage() -> ShaderMaterial:
	if _foliage == null:
		_foliage = ShaderMaterial.new()
		_foliage.shader = load("res://shaders/toon.gdshader")
		_foliage.set_shader_parameter("rim_amount", 0.3)
		_foliage.set_shader_parameter("sway", 1.0)
		_foliage.set_shader_parameter("detail_noise", 0.25)
	return _foliage


static func toon_color(c: Color, rim := 0.3) -> ShaderMaterial:
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/toon.gdshader")
	m.set_shader_parameter("tint", c)
	m.set_shader_parameter("use_vertex_color", false)
	m.set_shader_parameter("rim_amount", rim)
	return m


static func vegetation_mesh(t: int) -> ArrayMesh:
	var b = MB.new()
	var bark = Color(0.42, 0.29, 0.18)
	match t:
		0:  # geniş yapraklı anime ağacı
			b.add("cyl", Vector3(0, 2.6, 0), Vector3(0.7, 5.2, 0.7), bark, Vector3.ZERO, 7)
			b.add("cyl", Vector3(0.6, 4.6, 0), Vector3(0.25, 2.0, 0.25), bark, Vector3(0, 0, -40), 5)
			var g = [Color(0.27, 0.55, 0.2), Color(0.32, 0.62, 0.24), Color(0.22, 0.48, 0.18)]
			b.add("sphere", Vector3(0, 6.6, 0), Vector3(5.2, 4.0, 5.2), g[0], Vector3.ZERO, 9)
			b.add("sphere", Vector3(1.6, 6.0, 0.6), Vector3(3.4, 2.8, 3.4), g[1], Vector3.ZERO, 8)
			b.add("sphere", Vector3(-1.3, 6.3, -0.9), Vector3(3.6, 3.0, 3.6), g[2], Vector3.ZERO, 8)
			b.add("sphere", Vector3(0.2, 8.2, 0.3), Vector3(3.4, 2.6, 3.4), g[1], Vector3.ZERO, 8)
		1:  # çam
			b.add("cyl", Vector3(0, 3, 0), Vector3(0.6, 6, 0.6), bark, Vector3.ZERO, 6)
			for i in 4:
				var s = 4.6 - i * 1.0
				b.add("cone", Vector3(0, 3.2 + i * 1.7, 0), Vector3(s, 3.0, s), Color(0.16, 0.36, 0.24).lightened(i * 0.04), Vector3.ZERO, 8)
		2:  # kuru ağaç
			b.add("cyl", Vector3(0, 3, 0), Vector3(0.55, 6, 0.55), Color(0.35, 0.31, 0.28), Vector3.ZERO, 6)
			for i in 4:
				b.add("cyl", Vector3(0, 4.0 + i * 0.6, 0), Vector3(0.18, 2.6, 0.18), Color(0.35, 0.31, 0.28), Vector3(0, i * 95, 45), 5)
		3:  # kaktüs
			var c = Color(0.36, 0.55, 0.3)
			b.add("cyl", Vector3(0, 1.6, 0), Vector3(0.6, 3.2, 0.6), c, Vector3.ZERO, 8)
			b.add("sphere", Vector3(0, 3.2, 0), Vector3(0.6, 0.5, 0.6), c, Vector3.ZERO, 8)
			b.add("cyl", Vector3(0.55, 1.8, 0), Vector3(0.35, 1.2, 0.35), c, Vector3(0, 0, 90), 6)
			b.add("cyl", Vector3(0.8, 2.4, 0), Vector3(0.35, 1.2, 0.35), c, Vector3.ZERO, 6)
		4:  # kaya
			var r = Color(0.52, 0.49, 0.45)
			b.add("sphere", Vector3(0, 0.5, 0), Vector3(3.0, 2.0, 2.4), r, Vector3(8, 20, 5), 6)
			b.add("sphere", Vector3(0.9, 0.3, 0.6), Vector3(1.6, 1.2, 1.4), r.darkened(0.1), Vector3(0, 50, 0), 5)
		5:  # Ölüm Ormanı dev ağacı
			var bk = Color(0.32, 0.22, 0.15)
			b.add("cyl", Vector3(0, 28, 0), Vector3(6.4, 56, 6.4), bk, Vector3.ZERO, 10)
			for i in 6:
				b.add("cyl", Vector3(0, 1.5, 0), Vector3(1.8, 9.0, 1.8), bk, Vector3(70, i * 60, 0), 6)
			for i in 5:
				var a = i * 72.0 + 20.0
				var y = 14.0 + i * 6.5
				var d = Vector3(sin(deg_to_rad(a)), 0, cos(deg_to_rad(a)))
				b.add("box", d * 8.0 + Vector3(0, y, 0), Vector3(2.4, 1.6, 14.0), bk, Vector3(0, a, 0))
			var g = Color(0.12, 0.3, 0.13)
			b.add("sphere", Vector3(0, 58, 0), Vector3(30, 14, 30), g, Vector3.ZERO, 10)
			b.add("sphere", Vector3(8, 52, 5), Vector3(18, 10, 18), g.lightened(0.05), Vector3.ZERO, 8)
			b.add("sphere", Vector3(-8, 54, -6), Vector3(18, 10, 18), g.darkened(0.1), Vector3.ZERO, 8)
		6:  # bambu
			for i in 5:
				var p = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
				var h = randf_range(7, 10)
				b.add("cyl", p + Vector3(0, h / 2, 0), Vector3(0.18, h, 0.18), Color(0.45, 0.62, 0.3), Vector3(randf_range(-4, 4), 0, randf_range(-4, 4)), 5)
				b.add("sphere", p + Vector3(0, h, 0), Vector3(1.6, 1.0, 1.6), Color(0.35, 0.6, 0.25), Vector3.ZERO, 6)
		7:  # palmiye
			for i in 5:
				b.add("cyl", Vector3(i * 0.25, 0.9 + i * 1.6, 0), Vector3(0.5, 1.8, 0.5), Color(0.55, 0.42, 0.3), Vector3(0, 0, -6), 6)
			for i in 7:
				b.add("box", Vector3(1.25, 8.3, 0), Vector3(0.6, 0.08, 3.6), Color(0.28, 0.55, 0.22), Vector3(-25, i * 51, 0))
		8:  # çalı
			var g = Color(0.3, 0.55, 0.22)
			b.add("sphere", Vector3(0, 0.5, 0), Vector3(1.8, 1.2, 1.8), g, Vector3.ZERO, 6)
			b.add("sphere", Vector3(0.6, 0.4, 0.4), Vector3(1.2, 0.9, 1.2), g.lightened(0.08), Vector3.ZERO, 6)
	return b.build(foliage() if t in [0, 1, 5, 6, 7, 8] else toon())
