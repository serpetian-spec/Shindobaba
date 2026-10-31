class_name IceArt
extends RefCounted
## Hyōton buz kristalleri (anime referanslı): düzensiz altıgen gövdeli, eğik sivri uçlu, düz yüzeyli kristaller.
## Malzeme saydam camgöbeği + yüz yüz ton + beyaz parlama çizgileri (ice.gdshader) — opak beyaz koni / küre değil.

static var _mat: ShaderMaterial
static var _frost_mat: StandardMaterial3D


static func mat() -> ShaderMaterial:
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = load("res://shaders/ice.gdshader")
	return _mat


static func _frost() -> StandardMaterial3D:
	if _frost_mat == null:
		_frost_mat = StandardMaterial3D.new()
		_frost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_frost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_frost_mat.vertex_color_use_as_albedo = true
		_frost_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _frost_mat


## Düz gölgeli üçgen: normal, verilen dış yöne (out) bakacak şekilde sarılır
static func _tri(b: MB, p0: Vector3, p1: Vector3, p2: Vector3, out: Vector3, col: Color) -> void:
	var n = (p1 - p0).cross(p2 - p0)
	if n.dot(out) > 0.0:
		var tmp = p1
		p1 = p2
		p2 = tmp
		n = -n
	var nn = -n.normalized()
	var i0 = b.verts.size()
	for p in [p0, p1, p2]:
		b.verts.append(p)
		b.normals.append(nn)
		b.colors.append(col)
		b.uvs.append(Vector2.ZERO)
	b.idx.append_array([i0, i0 + 1, i0 + 2])


## Tek kristal: base noktasından dir yönünde h boyunda, r yarıçaplı; gövde %55-70'te daralıp eğik bir uca biter.
## cap: alt yüz kapatılır (havada uçan parçalar için)
static func shard(b: MB, base: Vector3, dir: Vector3, h: float, r: float, rng: RandomNumberGenerator, col := Color.WHITE, sides := 6, cap := false) -> void:
	var y = dir.normalized()
	var x = y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z = x.cross(y)
	var rot = rng.randf() * TAU
	var mid = rng.randf_range(0.55, 0.72)
	var r0 = []
	var r1 = []
	for k in sides:
		var a = rot + (k + rng.randf_range(-0.25, 0.25)) * TAU / sides
		var rr = r * rng.randf_range(0.75, 1.15)
		var off = x * cos(a) + z * sin(a)
		r0.append(base + off * rr - y * r * 0.3)
		r1.append(base + off * rr * rng.randf_range(0.82, 1.0) + y * h * mid)
	var apex = base + y * h + (x * rng.randf_range(-1, 1) + z * rng.randf_range(-1, 1)) * r * 0.3
	var axis_mid = base + y * h * 0.5
	var tip_col = col.lerp(Color(1.08, 1.08, 1.1, col.a), 0.25)
	for k in sides:
		var k2 = (k + 1) % sides
		var out = ((r0[k] + r0[k2]) * 0.5 - base).normalized()
		_tri(b, r0[k], r0[k2], r1[k2], out, col)
		_tri(b, r0[k], r1[k2], r1[k], out, col)
		var out2 = ((r1[k] + r1[k2] + apex) / 3.0 - axis_mid).normalized()
		_tri(b, r1[k], r1[k2], apex, out2, tip_col)
		if cap:
			_tri(b, r0[k], r0[k2], base - y * r * 0.3, -y, col)


static func _mi(b: MB) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(mat())
	mi.material_override = mat()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _rng(seed := -1) -> RandomNumberGenerator:
	var rng = RandomNumberGenerator.new()
	if seed >= 0:
		rng.seed = seed
	else:
		rng.randomize()
	return rng


## Tek buz sivrisi (eski _ice_spike yerine): taban orijinde, +Y
static func spike(h: float, r: float) -> MeshInstance3D:
	var b = MB.new()
	shard(b, Vector3.ZERO, Vector3.UP, h, r, _rng(), Color.WHITE, 6)
	return _mi(b)


## Tsurara: hedefin çevresinden yerden fışkıran, içe eğik büyük buz kristalleri + ortada hedefi saran buz kütlesi
static func encase(r := 1.6, h := 3.4) -> MeshInstance3D:
	var rng = _rng()
	var b = MB.new()
	# dış halka: içe eğik büyük kristaller, aralarında küçükler
	var n = 9
	for k in n:
		var a = k * TAU / n + rng.randf_range(-0.15, 0.15)
		var o = Vector3(cos(a), 0, sin(a))
		shard(b, o * r * rng.randf_range(0.9, 1.15), (Vector3.UP * 1.0 - o * rng.randf_range(0.25, 0.5)), h * rng.randf_range(0.8, 1.15), r * 0.36, rng)
		var a2 = a + PI / n
		var o2 = Vector3(cos(a2), 0, sin(a2))
		shard(b, o2 * r * 1.35, Vector3.UP * 1.0 + o2 * rng.randf_range(0.2, 0.6), h * rng.randf_range(0.35, 0.55), r * 0.2, rng)
	# orta kütle: hedefi saran kalın kristal öbeği
	for k in 5:
		var a = k * TAU / 5.0 + rng.randf()
		var o = Vector3(cos(a), 0, sin(a))
		shard(b, o * r * 0.35, Vector3.UP + o * 0.25, h * rng.randf_range(0.75, 0.95), r * 0.55, rng, Color(0.95, 0.98, 1.0))
	# dışa saçılan küçük yer kristalleri
	for k in 12:
		var a = rng.randf() * TAU
		var o = Vector3(cos(a), 0, sin(a))
		shard(b, o * r * rng.randf_range(1.6, 2.4), Vector3.UP + o * rng.randf_range(0.5, 1.2), h * rng.randf_range(0.12, 0.3), r * 0.1, rng)
	return _mi(b)


## Hyōgan Dōmu: üst üste binen, içe eğik kristal levhalardan örülü pürüzlü kubbe (pürüzsüz yarım küre değil)
static func dome(r := 2.4) -> MeshInstance3D:
	var rng = _rng()
	var b = MB.new()
	var rings = [[16, 1.0, 0.15, 0.9], [13, 0.88, 0.6, 0.8], [9, 0.62, 1.05, 0.7], [5, 0.33, 1.35, 0.55]]
	for ri in rings.size():
		var cnt: int = rings[ri][0]
		var rad: float = rings[ri][1] * r
		var y0: float = rings[ri][2] * r
		for k in cnt:
			var a = (k + (0.5 if ri % 2 == 1 else 0.0) + rng.randf_range(-0.2, 0.2)) * TAU / cnt
			var o = Vector3(cos(a), 0, sin(a))
			var lean = 0.25 + ri * 0.55
			var d = (Vector3.UP - o * lean).normalized()
			shard(b, o * rad + Vector3.UP * y0, d, r * rings[ri][3] * rng.randf_range(0.85, 1.2), r * (0.32 - ri * 0.04), rng, Color(1, 1, 1) if ri % 2 == 0 else Color(0.9, 0.96, 1.0))
	# tepe sivrisi ve dışarı taşan pürüzlü sivri uçlar
	shard(b, Vector3.UP * r * 1.25, Vector3.UP, r * 0.55, r * 0.22, rng)
	for k in 10:
		var a = rng.randf() * TAU
		var o = Vector3(cos(a), 0, sin(a))
		var yy = rng.randf_range(0.3, 1.1)
		shard(b, (o * cos(yy) + Vector3.UP * sin(yy)) * r * 0.95, o * 0.8 + Vector3.UP * 0.6, r * rng.randf_range(0.3, 0.55), r * 0.08, rng)
	# taban: yere yayılan küçük kristaller (dairesel çizgi yerine doğal etek)
	for k in 18:
		var a = rng.randf() * TAU
		var o = Vector3(cos(a), 0, sin(a))
		shard(b, o * r * rng.randf_range(1.05, 1.5), Vector3.UP + o * rng.randf_range(0.4, 1.0), r * rng.randf_range(0.15, 0.4), r * 0.09, rng)
	return _mi(b)


## Buz duvarı (Suishōheki): sık dizilmiş kalın kristal sütunlar, aralarında boşluk yok; w genişlik (yan ekseni X), h yükseklik
static func wall(w := 7.0, h := 4.0) -> MeshInstance3D:
	var rng = _rng()
	var b = MB.new()
	var n = int(w / 0.7)
	for k in n + 1:
		var x = -w * 0.5 + w * k / float(n)
		var hh = h * rng.randf_range(0.7, 1.15) * (1.0 - 0.35 * pow(absf(x) / (w * 0.5), 2.0))
		shard(b, Vector3(x, 0, rng.randf_range(-0.15, 0.15)), Vector3(rng.randf_range(-0.15, 0.15), 1, rng.randf_range(-0.12, 0.12)), hh, 0.55, rng)
	# önde ve arkada eğik destek kristalleri (kalın, sağlam duvar görünümü)
	for k in n:
		var x = -w * 0.5 + w * (k + 0.5) / float(n)
		for sz in [-1.0, 1.0]:
			shard(b, Vector3(x, 0, sz * 0.55), Vector3(rng.randf_range(-0.2, 0.2), 1, sz * rng.randf_range(0.3, 0.6)), h * rng.randf_range(0.3, 0.55), 0.35, rng, Color(0.92, 0.97, 1.0))
	return _mi(b)


## Yerde donmuş zemin: düzensiz kenarlı beyaz-mavi buz lekesi (kenarlara doğru saydamlaşır)
static func frost(r := 3.0) -> MeshInstance3D:
	var rng = _rng()
	var b = MB.new()
	var seg = 28
	var pts = []
	for k in seg:
		var a = k * TAU / seg
		pts.append(Vector3(cos(a), 0, sin(a)) * r * rng.randf_range(0.65, 1.1))
	var c_in = Color(0.85, 0.95, 1.0, 0.75)
	var c_out = Color(0.75, 0.9, 1.0, 0.0)
	for k in seg:
		var k2 = (k + 1) % seg
		_tri(b, Vector3.ZERO, pts[k], pts[k2], Vector3.UP, c_in)
		var i = b.colors.size()
		b.colors[i - 1] = c_out if b.verts[i - 1] != Vector3.ZERO else c_in
		b.colors[i - 2] = c_out if b.verts[i - 2] != Vector3.ZERO else c_in
		b.colors[i - 3] = c_out if b.verts[i - 3] != Vector3.ZERO else c_in
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(_frost())
	mi.material_override = _frost()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Kırılma: kristal parçaları yerçekimiyle saçılır, beyaz parıltı + soğuk buhar (küçülerek kaybolma yerine)
static func shatter(tree: SceneTree, pos: Vector3, s := 1.0, n := 14) -> void:
	var rng = _rng()
	var root = tree.current_scene
	for k in n:
		var b = MB.new()
		shard(b, Vector3.ZERO, Vector3(rng.randf_range(-1, 1), 1, rng.randf_range(-1, 1)), s * rng.randf_range(0.35, 0.8), s * rng.randf_range(0.08, 0.16), rng, Color.WHITE, 5, true)
		var mi = _mi(b)
		root.add_child(mi)
		var p0 = pos + Vector3(rng.randf_range(-1, 1), rng.randf_range(0, 1.5), rng.randf_range(-1, 1)) * s
		mi.global_position = p0
		var v = (p0 - pos + Vector3.UP * 0.5).normalized() * rng.randf_range(3.0, 7.0) * sqrt(s) + Vector3.UP * rng.randf_range(2.0, 5.0)
		var spin = Vector3(rng.randf_range(-9, 9), rng.randf_range(-9, 9), rng.randf_range(-9, 9))
		var life = rng.randf_range(0.7, 1.1)
		var tw = mi.create_tween()
		tw.tween_method(func(t: float):
			if is_instance_valid(mi):
				mi.global_position = p0 + v * t + Vector3.DOWN * 9.8 * 0.5 * t * t
				mi.rotation = spin * t
				mi.scale = Vector3.ONE * clampf((life - t) / 0.25, 0.0, 1.0), 0.0, life, life)
		tw.tween_callback(mi.queue_free)
	FX.burst(pos + Vector3.UP * s, {"amount": int(30 * s), "life": 0.6, "tex": FX.tex_spark, "add": true, "size": 0.25, "radius": s, "vmin": 3, "vmax": 8,
		"colors": [Color(1, 1, 1, 1), Color(0.75, 0.92, 1.0, 0.9), Color(0.7, 0.9, 1.0, 0.0)]})
	VFX.fog(pos + Vector3.UP * 0.6 * s, {"amount": int(10 * s) + 4, "life": 1.4, "size": 1.4 * s, "radius": s, "vmin": 0.3, "vmax": 1.2, "dir": Vector3.UP, "spread": 80.0,
		"colors": [Color(0.95, 0.98, 1.0, 0.0), Color(0.9, 0.96, 1.0, 0.55), Color(0.88, 0.95, 1.0, 0.0)]})
