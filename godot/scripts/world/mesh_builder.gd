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
	var a := m.get_mesh_arrays()
	_cache[key] = a
	return a


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
