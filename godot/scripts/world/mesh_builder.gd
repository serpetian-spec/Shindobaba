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
			var c := CylinderMesh.new(); c.radial_segments = seg; c.rings = 1; m = c
		"cone":
			var c := CylinderMesh.new(); c.top_radius = 0.0; c.radial_segments = seg; c.rings = 1; m = c
		"sphere":
			var s := SphereMesh.new(); s.radial_segments = seg; s.rings = maxi(3, seg / 2); s.radius = 0.5; s.height = 1.0; m = s
		"hemi":
			var s := SphereMesh.new(); s.radial_segments = seg; s.rings = maxi(3, seg / 2); s.radius = 0.5; s.height = 0.5; s.is_hemisphere = true; m = s
		"prism":
			m = PrismMesh.new()
		"torus":
			var t := TorusMesh.new(); t.inner_radius = 0.42; t.outer_radius = 0.5; t.rings = seg; t.ring_segments = 6; m = t
	var a := m.get_mesh_arrays()
	_cache[key] = a
	return a


## Primitif ekler. pos merkez, size ölçek (box: kenarlar, cyl/cone/sphere: çap x yükseklik x çap), rot derece (x,y,z)
func add(kind: String, pos: Vector3, size: Vector3, col: Color, rot := Vector3.ZERO, seg := 8) -> void:
	var a := _prim_arrays(kind, seg)
	var b := Basis.from_euler(Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z)))
	var xf := Transform3D(b.scaled(size), pos)
	add_arrays(a, xf, col)


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
