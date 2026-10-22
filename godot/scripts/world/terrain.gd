extends Node3D
## Geometri clipmap'i: kameranın etrafında iç içe halkalar. Yakında 2 m, uzakta 64 m çözünürlük.
## Yükseklik vertex shader'da dokudan okunur, böylece 7 km'lik dünya tek seferde çizilir.

const LEVELS := 6
const N := 128
const BASE := 2.0

var meshes: Array[MeshInstance3D] = []
var spacings: Array[float] = []


func _ready() -> void:
	var shader: Shader = load("res://shaders/terrain.gdshader")
	var biome = load("res://data/world/biome.png")
	for k in LEVELS:
		var s := BASE * pow(2.0, k)
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("heightmap", Game.height_tex)
		mat.set_shader_parameter("albedo_map", Game.albedo_tex)
		mat.set_shader_parameter("biome_map", biome)
		mat.set_shader_parameter("world_rect", Game.world_rect())
		mat.set_shader_parameter("level_eps", k * 0.12)
		mat.set_shader_parameter("texel", maxf(Game.res, s))
		var mi := MeshInstance3D.new()
		mi.mesh = _ring_mesh(s, k > 0)
		mi.material_override = mat
		mi.custom_aabb = AABB(Vector3(-1e5, -500, -1e5), Vector3(2e5, 1500, 2e5))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if k < 2 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		meshes.append(mi)
		spacings.append(s)


func _ring_mesh(s: float, hole: bool) -> ArrayMesh:
	var verts := PackedVector3Array()
	var idx := PackedInt32Array()
	var half := N / 2
	for z in N + 1:
		for x in N + 1:
			verts.append(Vector3((x - half) * s, 0.0, (z - half) * s))
	var h0 := N / 4 + 2
	var h1 := 3 * N / 4 - 2
	for z in N:
		for x in N:
			if hole and x >= h0 and x < h1 and z >= h0 and z < h1:
				continue
			var a := z * (N + 1) + x
			var b := a + 1
			var c := a + N + 1
			var d := c + 1
			idx.append_array([a, b, c, b, d, c])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_INDEX] = idx
	var normals := PackedVector3Array()
	normals.resize(verts.size())
	normals.fill(Vector3.UP)
	arr[Mesh.ARRAY_NORMAL] = normals
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m


func _process(_dt: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var c := cam.global_position
	for k in LEVELS:
		var snap := spacings[k] * 2.0
		meshes[k].global_position = Vector3(floor(c.x / snap) * snap, 0.0, floor(c.z / snap) * snap)
