extends MultiMeshInstance3D
## Oyuncuyu takip eden çimen halısı. Izgara oyuncuya kenetlenir, her tutam kendi kök konumundan araziyi okur.

const SPACING := 0.6
const RADIUS := 58.0

var mat: ShaderMaterial
var snap := SPACING * 4.0
var _road_ver := -1


func _ready() -> void:
	var n = int(RADIUS * 2.0 / SPACING)
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _tuft_mesh()
	var xf: Array = []
	var rng = RandomNumberGenerator.new()
	rng.seed = 7
	# düz ızgara: kayma/dönüş/boy gölgelendiricide DÜNYA konumundan gelir (ızgara oyuncuyla kayınca tutamlar zıplamasın)
	var h = n / 2
	for z in n:
		for x in n:
			var p = Vector3((x - h) * SPACING, 0, (z - h) * SPACING)
			if Vector2(p.x, p.z).length() > RADIUS:
				continue
			xf.append(Transform3D(Basis.IDENTITY, p))
	mm.instance_count = xf.size()
	for i in xf.size():
		mm.set_instance_transform(i, xf[i])
	multimesh = mm
	mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/grass.gdshader")
	Game.setup_height_material(mat)
	mat.set_shader_parameter("albedo_map", Game.albedo_tex)
	var vill := []
	for v in Game.world_info["villages"]:
		vill.append(Vector4(v["x"], -float(v["y"]), v["r"], v.get("ground", 11)))
	mat.set_shader_parameter("villages", vill)
	mat.set_shader_parameter("village_count", vill.size())
	mat.set_shader_parameter("radius", RADIUS)
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	custom_aabb = AABB(Vector3(-RADIUS - 5, -500, -RADIUS - 5), Vector3(RADIUS * 2 + 10, 1500, RADIUS * 2 + 10))


func _tuft_mesh() -> ArrayMesh:
	## 3 çapraz yaprak demeti (her biri sivri üçgenler)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 3:
		var a = k * PI / 3.0
		var d = Vector3(cos(a), 0, sin(a))
		for b in 3:
			var o = d * (b - 1) * 0.12
			var h = 0.32 + 0.14 * float(b == 1)
			var lean = Vector3(-d.z, 0, d.x) * 0.12 * (b - 1)
			st.set_normal(Vector3.UP)
			st.add_vertex(o - d * 0.035)
			st.set_normal(Vector3.UP)
			st.add_vertex(o + d * 0.035)
			st.set_normal(Vector3.UP)
			st.add_vertex(o + Vector3(0, h, 0) + lean)
	return st.commit()


func _process(_dt: float) -> void:
	if Game.player == null:
		visible = false
		return
	visible = true
	var p = Game.player.global_position
	global_position = Vector3(floor(p.x / snap) * snap, 0, floor(p.z / snap) * snap)
	mat.set_shader_parameter("player_pos", p)
	var rm = Game.world.get("road_map") if Game.world else null
	if rm and rm.version != _road_ver:
		_road_ver = rm.version
		mat.set_shader_parameter("road_tex", rm.texture)
		mat.set_shader_parameter("road_rect", rm.rect)
