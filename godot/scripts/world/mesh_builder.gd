class_name MB
extends RefCounted
## Hızlı statik mesh birleştirici: primitifleri dönüşüm + renkle tek ArrayMesh'e ekler.

var verts := PackedVector3Array()
var normals := PackedVector3Array()
var colors := PackedColorArray()
var uvs := PackedVector2Array()
var idx := PackedInt32Array()

static var _cache := {}


static func _prim_arrays(kind: String, seg: int = 8) -> Array:
	var key := "%s_%d" % [kind, seg]
	if _cache.has(key):
		return _cache[key]
	var m: PrimitiveMesh
	match kind:
		"box":
			m = BoxMesh.new()
		"cyl":
			var c := CylinderMesh.new(); c.height = 1.0; c.radial_segments = seg; c.rings = 1; m = c
		"cone":
			var c := CylinderMesh.new(); c.height = 1.0; c.top_radius = 0.0; c.radial_segments = seg; c.rings = 1; m = c
		"sphere":
			var s := SphereMesh.new(); s.radial_segments = seg; s.rings = maxi(3, seg / 2); s.radius = 0.5; s.height = 1.0; m = s
		"hemi":
			var s := SphereMesh.new(); s.radial_segments = seg; s.rings = maxi(3, seg / 2); s.radius = 0.5; s.height = 0.5; s.is_hemisphere = true; m = s
		"prism":
			m = PrismMesh.new()
		"halfcyl":
			_cache[key] = _halfcyl(seg)
			return _cache[key]
		"torus":
			var t := TorusMesh.new(); t.inner_radius = 0.42; t.outer_radius = 0.5; t.rings = seg; t.ring_segments = 6; m = t
		"frustum":  # alt yarıçap 0.5, üst 0.36 (kule gövdeleri)
			var c := CylinderMesh.new(); c.height = 1.0; c.top_radius = 0.36; c.radial_segments = seg; c.rings = 1; m = c
		"crag", "boulder":  # pürüzlü kaya sütunu / kaya (seg = varyant tohumu)
			_cache[key] = _rocky(kind, seg)
			return _cache[key]
	var a := m.get_mesh_arrays()
	_cache[key] = a
	return a


## Pürüzlü kaya: "crag" = taban r 0.5, tepe daralan, katmanlı (strata) ve eğik sütun (y 0..1 ölçeğinde -0.5..0.5);
## "boulder" = düzensiz yuvarlak kaya. Yassı gölgeli (faceted) kenarlar kaya hissi verir.
static func _rocky(kind: String, variant: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * variant + (1 if kind == "crag" else 2)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 8
	var rings := 9 if kind == "crag" else 6
	var pts := []
	var lean := Vector2(rng.randf_range(-0.08, 0.08), rng.randf_range(-0.08, 0.08))
	for r in rings + 1:
		var t := float(r) / rings
		var row := []
		var rr: float
		var y: float
		if kind == "crag":
			y = t - 0.5
			var top_r := 0.36 if variant >= 100 else 0.2  # 100+: mesa (geniş düz tepe)
			rr = lerpf(0.5, top_r, pow(t, 1.3)) * (1.0 + (0.12 if r % 2 == 1 else -0.04))  # strata çıkıntıları
		else:
			var ang := lerpf(-PI * 0.5, PI * 0.5, t)
			y = sin(ang) * 0.5
			rr = cos(ang) * 0.5
		var c := lean * t * t if kind == "crag" else Vector2.ZERO
		for k in sides:
			var a := TAU * (float(k) + rng.randf_range(-0.12, 0.12)) / sides + float(r) * 0.06
			var j := rng.randf_range(0.78, 1.12)
			row.append(Vector3(c.x + cos(a) * rr * j, y + rng.randf_range(-0.012, 0.012), c.y + sin(a) * rr * j))
		pts.append(row)
	for r in rings:
		for k in sides:
			var a0: Vector3 = pts[r][k]; var a1: Vector3 = pts[r][(k + 1) % sides]
			var b0: Vector3 = pts[r + 1][k]; var b1: Vector3 = pts[r + 1][(k + 1) % sides]
			for v in [a0, b0, a1, a1, b0, b1]:
				st.add_vertex(v)
	# tepe kapağı
	var top: Array = pts[rings]
	var tc := Vector3.ZERO
	for v in top:
		tc += v
	tc /= sides
	tc.y += 0.03 if kind == "crag" else 0.0
	for k in sides:
		st.add_vertex(tc); st.add_vertex(top[(k + 1) % sides]); st.add_vertex(top[k])
	st.generate_normals()
	var arr := st.commit_to_arrays()
	if arr[Mesh.ARRAY_INDEX] == null:
		var ii := PackedInt32Array()
		for i in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size():
			ii.append(i)
		arr[Mesh.ARRAY_INDEX] = ii
	return arr


## Yarım silindir (tonoz çatı): ekseni X, kesit YZ'de üst yarım daire. x -0.5..0.5, y 0..0.5, z -0.5..0.5, uç kapaklı
static func _halfcyl(seg: int) -> Array:
	var v = PackedVector3Array()
	var n = PackedVector3Array()
	var ii = PackedInt32Array()
	for k in seg + 1:  # kavisli yüzey (yumuşak normaller)
		var t = PI * float(k) / seg
		var dir = Vector3(0, sin(t), cos(t))
		v.append(Vector3(-0.5, 0, 0) + dir * 0.5)
		v.append(Vector3(0.5, 0, 0) + dir * 0.5)
		n.append(dir); n.append(dir)
		if k > 0:
			var a = (k - 1) * 2
			ii.append_array([a, a + 2, a + 1, a + 1, a + 2, a + 3])
	for sx in [-1.0, 1.0]:  # uç kapakları (yarım disk)
		var c = v.size()
		v.append(Vector3(0.5 * sx, 0, 0)); n.append(Vector3(sx, 0, 0))
		for k in seg + 1:
			var t = PI * float(k) / seg
			v.append(Vector3(0.5 * sx, sin(t) * 0.5, cos(t) * 0.5)); n.append(Vector3(sx, 0, 0))
			if k > 0:
				if sx > 0:
					ii.append_array([c, c + k, c + k + 1])
				else:
					ii.append_array([c, c + k + 1, c + k])
	var a = []
	a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX] = v
	a[Mesh.ARRAY_NORMAL] = n
	a[Mesh.ARRAY_INDEX] = ii
	return a


## Primitif ekler. pos merkez, size ölçek (box: kenarlar, cyl/cone/sphere: çap x yükseklik x çap), rot derece (x,y,z)
func add(kind: String, pos: Vector3, size: Vector3, col: Color, rot := Vector3.ZERO, seg := 8) -> void:
	var a := _prim_arrays(kind, seg)
	var b := Basis.from_euler(Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z)))
	var xf := Transform3D(b * Basis.from_scale(size), pos)  # ölçek yerel eksenlerde (dönmüş kutular çarpılmasın)
	add_arrays(a, xf, col)


## Dikey renk geçişli primitif (yaprak kümeleri: altı koyu, tepesi açık)
func add_grad(kind: String, pos: Vector3, size: Vector3, top: Color, bottom: Color, rot := Vector3.ZERO, seg := 8) -> void:
	var a := _prim_arrays(kind, seg)
	var b := Basis.from_euler(Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z)))
	var xf := Transform3D(b * Basis.from_scale(size), pos)  # ölçek yerel eksenlerde (dönmüş kutular çarpılmasın)
	var base := verts.size()
	var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var nb := xf.basis.inverse().transposed()
	for i in v.size():
		verts.append(xf * v[i])
		normals.append((nb * n[i]).normalized())
		var k := clampf(v[i].y + 0.5, 0.0, 1.0)
		colors.append(bottom.lerp(top, k * k))
		uvs.append(Vector2.ZERO)
	var ii: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	for i in ii:
		idx.append(base + i)


## Ağaç kökü: gövdeden çıkıp yana kıvrılarak (hafif sarmal) yere yatan, toprağa gömülerek sivrilen yassı tüp.
## base: gövde merkezi (yer seviyesi), dir: dışa yön, trunk_r: gövde yarıçapı, L: yatay uzunluk, r0: kök kalınlığı
func add_root(base: Vector3, dir: Vector3, trunk_r: float, L: float, r0: float, col: Color, curl := 0.3, h0 := -1.0, rings := 9, sides := 7) -> void:
	dir = Vector3(dir.x, 0, dir.z).normalized()
	var side_v := dir.cross(Vector3.UP).normalized()
	if h0 < 0.0:
		h0 = r0 * 2.6
	var pts := PackedVector3Array()
	var rad := PackedFloat32Array()
	for i in rings + 1:
		var t := float(i) / rings
		var r := r0 * (pow(1.0 - t, 0.9) * 0.85 + 0.15)
		# gövdede yüksekten başlar, hızla yere iner, sonra toprağa yapışık sürünür; uçta toprağa dalar
		var y := h0 * pow(1.0 - t, 2.4) + r * 0.3 - smoothstep(0.7, 1.0, t) * r * 1.2
		var out := trunk_r * (0.35 + 0.65 * smoothstep(0.0, 0.35, t)) + L * t
		var sway := sin(t * PI * 1.3) * L * curl * 0.35   # yana kıvrılma (sarmal his)
		pts.append(base + dir * out + side_v * sway + Vector3.UP * y)
		rad.append(r)
	var base_i := verts.size()
	for i in pts.size():
		var tng: Vector3 = (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var sd := tng.cross(Vector3.UP).normalized()
		if sd.length() < 0.1:
			sd = side_v
		var up := sd.cross(tng).normalized()
		var t := float(i) / rings
		var c := col.darkened(0.12 * t)
		for k in sides + 1:
			var a := TAU * k / sides
			# köküler yassı: dikey yarıçap daha kısa, alt yüz yere oturur
			var nrm := (sd * cos(a) + up * sin(a)).normalized()
			verts.append(pts[i] + sd * cos(a) * rad[i] * (1.0 + 0.25 * t) + up * sin(a) * rad[i] * lerpf(1.0, 0.55, t))
			normals.append(nrm)
			colors.append(c)
			uvs.append(Vector2(float(k) / sides, t))
	for i in pts.size() - 1:
		for k in sides:
			var a0 := base_i + i * (sides + 1) + k
			var b0 := a0 + sides + 1
			idx.append_array([a0, b0, a0 + 1, a0 + 1, b0, b0 + 1])


func add_xf(kind: String, xf: Transform3D, col: Color, seg := 8) -> void:
	add_arrays(_prim_arrays(kind, seg), xf, col)


func add_arrays(a: Array, xf: Transform3D, col: Color) -> void:
	var base := verts.size()
	var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var uv = a[Mesh.ARRAY_TEX_UV]
	var nb := xf.basis.inverse().transposed()
	for i in v.size():
		verts.append(xf * v[i])
		normals.append((nb * n[i]).normalized())
		colors.append(col)
		uvs.append(uv[i] if uv != null else Vector2.ZERO)
	var ii: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	for i in ii:
		idx.append(base + i)


func add_mesh(other: MB, xf := Transform3D.IDENTITY) -> void:
	var base := verts.size()
	var nb := xf.basis.inverse().transposed()
	for i in other.verts.size():
		verts.append(xf * other.verts[i])
		normals.append((nb * other.normals[i]).normalized())
	colors.append_array(other.colors)
	uvs.append_array(other.uvs)
	for i in other.idx:
		idx.append(base + i)


## Yassı profil (kılıç ağzı, balta, yaprak): (y, z) düzlemindeki dış hattı X ekseninde kalınlıkla çıkarır.
## thick_fn(p: Vector2) -> float verilirse kalınlık noktaya göre değişir (ör. keskin ağız ince, sırt kalın).
## Delik için hattı önce hole() ile köprüleyin.
func add_slab(outline: PackedVector2Array, thick: float, col: Color, xf := Transform3D.IDENTITY, thick_fn := Callable(), side_col = null) -> void:
	var pts := outline.duplicate()
	var area := 0.0
	for i in pts.size():
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		area += a.x * b.y - b.x * a.y
	if area < 0.0:
		pts.reverse()
	var tri := Geometry2D.triangulate_polygon(pts)
	if tri.is_empty():
		return
	var n := pts.size()
	var th := PackedFloat32Array()
	for p in pts:
		th.append(float(thick_fn.call(p)) if thick_fn.is_valid() else thick)
	var nb := xf.basis.inverse().transposed()
	# ön (+X) ve arka (-X) yüzler — profil (y,z) → yerel (x, y, z)
	for sgn in [1.0, -1.0]:
		var base := verts.size()
		for i in n:
			verts.append(xf * Vector3(sgn * th[i] * 0.5, pts[i].x, pts[i].y))
			normals.append((nb * Vector3(sgn, 0, 0)).normalized())
			colors.append(col)
			uvs.append(pts[i])
		for k in range(0, tri.size(), 3):
			if sgn > 0.0:
				idx.append_array([base + tri[k], base + tri[k + 2], base + tri[k + 1]])
			else:
				idx.append_array([base + tri[k], base + tri[k + 1], base + tri[k + 2]])
	# yan duvar (kenar şeridi)
	var sc: Color = side_col if side_col != null else col
	for i in n:
		var j := (i + 1) % n
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[j]
		var e := b - a
		if e.length() < 0.00001:
			continue
		var nrm := (nb * Vector3(0, e.y, -e.x)).normalized()
		var base := verts.size()
		for q in [[a, th[i], 1.0], [b, th[j], 1.0], [b, th[j], -1.0], [a, th[i], -1.0]]:
			verts.append(xf * Vector3(q[2] * q[1] * 0.5, q[0].x, q[0].y))
			normals.append(nrm)
			colors.append(sc)
			uvs.append(q[0])
		idx.append_array([base, base + 2, base + 1, base, base + 3, base + 2])


## Hatta yuvarlak delik açar: en yakın köşeden ince bir köprüyle deliğin çevresini ters yönde dolanır
static func hole(outline: PackedVector2Array, c: Vector2, r: float, seg := 16) -> PackedVector2Array:
	var best := 0
	var bd := INF
	for i in outline.size():
		var d = outline[i].distance_to(c)
		if d < bd:
			bd = d
			best = i
	var p0: Vector2 = outline[best]
	var a0 := (p0 - c).angle()
	var area := 0.0
	for i in outline.size():
		var q: Vector2 = outline[i]
		var w: Vector2 = outline[(i + 1) % outline.size()]
		area += q.x * w.y - w.x * q.y
	var dirn := -1.0 if area > 0.0 else 1.0   # delik dış hattın tersi yönde dolanmalı
	var out := PackedVector2Array()
	for i in best + 1:
		out.append(outline[i])
	for k in seg + 1:
		var a = a0 + dirn * TAU * k / float(seg)
		out.append(c + Vector2(cos(a), sin(a)) * r)
	out.append(p0 + (c - p0).normalized().orthogonal() * 0.0005)
	for i in range(best + 1, outline.size()):
		out.append(outline[i])
	return out



func is_empty() -> bool:
	return verts.is_empty()


func build(material: Material = null) -> ArrayMesh:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_COLOR] = colors
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	if verts.is_empty():
		return m
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	if material:
		m.surface_set_material(0, material)
	return m
