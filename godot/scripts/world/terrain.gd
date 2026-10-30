extends Node3D
## Geometri clipmap'i: kameranın etrafında iç içe halkalar. Yakında 2 m, en uzakta 512 m aralık (~32 km görüş).
## Yükseklik vertex shader'da makro harita + ayrıntı gürültüsünden hesaplanır (Game.terrain_height ile aynı).

const LEVELS := 9
const N := 128
const BASE := 2.0

var meshes: Array[MeshInstance3D] = []
var spacings: Array[float] = []
var mats: Array[ShaderMaterial] = []
var _road_ver := -1


func _ready() -> void:
	var shader: Shader = load("res://shaders/terrain.gdshader")
	var vill := []
	for v in Game.world_info["villages"]:
		vill.append(Vector4(v["x"], -float(v["y"]), v["r"], v.get("ground", 11)))
	for k in LEVELS:
		var s := BASE * pow(2.0, k)
		var mat := ShaderMaterial.new()
		mat.shader = shader
		Game.setup_height_material(mat)
		mat.set_shader_parameter("albedo_map", Game.albedo_tex)
		mat.set_shader_parameter("villages", vill)
		mat.set_shader_parameter("village_count", vill.size())
		for v in Game.world_info["villages"]:
			var hr: Dictionary = v.get("hokage_rock", {})
			if not hr.is_empty():
				mat.set_shader_parameter("hokage_rock", Vector4(float(hr["x0"]), float(hr["x1"]), -float(hr["y"]), float(hr["top"])))
		mat.set_shader_parameter("level_eps", k * 0.12)
		mat.set_shader_parameter("tex_cobble", load("res://assets/tex/cobble.png"))
		mat.set_shader_parameter("tex_stone", load("res://assets/tex/stone.png"))
		for tn in ["rock", "sand", "forest", "dirt"]:
			mat.set_shader_parameter("tex_" + tn, load("res://assets/tex/%s.png" % tn))
		mat.set_shader_parameter("texel", s)
		mat.set_shader_parameter("road_rect", Vector4.ZERO)
		var mi := MeshInstance3D.new()
		mi.mesh = _ring_mesh(s, k > 0)
		mi.material_override = mat
		mi.custom_aabb = AABB(Vector3(-1e6, -500, -1e6), Vector3(2e6, 2500, 2e6))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if k < 3 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		meshes.append(mi)
		spacings.append(s)
		mats.append(mat)


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
	# yerel yol dokusu yenilenince materyallere ver
	var rm = Game.world.get("road_map") if Game.world else null
	if rm and rm.version != _road_ver:
		_road_ver = rm.version
		for m in mats:
			m.set_shader_parameter("road_tex", rm.texture)
			m.set_shader_parameter("road_rect", rm.rect)
