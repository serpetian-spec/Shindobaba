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
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # gür çimende gölge pahalı; dipteki koyulaşma oturtuyor
	custom_aabb = AABB(Vector3(-RADIUS - 5, -500, -RADIUS - 5), Vector3(RADIUS * 2 + 10, 1500, RADIUS * 2 + 10))


func _tuft_mesh() -> ArrayMesh:
	## Gür anime çimen tutamı (ref grass*.png): 7 geniş, kavisli, sivri yaprak; farklı boy ve eğim (halı gibi kesintisiz)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng = RandomNumberGenerator.new()
	rng.seed = 11
	for k in 7:
		var a = k * TAU / 7.0 + rng.randf_range(-0.4, 0.4)
		var d = Vector3(cos(a), 0, sin(a))          # yaprağın yüzü
		var side = Vector3(-d.z, 0, d.x)            # yaprağın eni
		var o = d * rng.randf_range(0.0, 0.2) + side * rng.randf_range(-0.12, 0.12)
		var h = rng.randf_range(0.45, 0.75)
		var w = rng.randf_range(0.09, 0.13)
		var lean = d * rng.randf_range(0.08, 0.22)   # dışa doğru kavis
		var p0 = o
		var p1 = o + Vector3(0, h * 0.55, 0) + lean * 0.4
		var p2 = o + Vector3(0, h, 0) + lean
		var q = [[p0 - side * w * 0.5, Vector2(0, 1.0)], [p0 + side * w * 0.5, Vector2(1, 1.0)],
			[p1 + side * w * 0.36, Vector2(1, 0.45)], [p1 - side * w * 0.36, Vector2(0, 0.45)], [p2, Vector2(0.5, 0.0)]]
		for tri in [[0, 1, 2], [0, 2, 3], [3, 2, 4]]:
			for vi in tri:
				st.set_normal(Vector3.UP)
				st.set_uv(q[vi][1])   # UV.x: yaprak enine (orta damar 0.5)
				st.add_vertex(q[vi][0])
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
