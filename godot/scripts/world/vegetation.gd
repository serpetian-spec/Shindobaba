extends Node3D
## Bitki örtüsü: ~64 bin ağaç/kaya/çalı. 384 m'lik parçalarda MultiMesh, yakın/uzak LOD.
## Oyuncunun çevresindeki ağaçlara gerçek çarpışma: gövde + (Konoha orman ağaçlarında) dallar -> dallarda koşulur.

const CHUNK := 384.0
const NEAR_FULL := 280.0      # bu mesafeye kadar detaylı model
const FAR_LOD := 1300.0       # uzak model görünürlüğü
const SMALL := [8, 10, 12]    # küçük bitkiler: sadece yakında

var data: PackedFloat32Array
var count = 0
var meshes = {}
var lods = {}
## görünen gövde yarıçapları (çarpışma görselle birebir olsun: ayak havada kalmasın)
var radii = {0: 0.38, 1: 0.36, 2: 0.3, 3: 0.36, 4: 1.0, 5: 3.2, 6: 0.0, 7: 0.25, 8: 0.0, 9: Props.FOREST_TRUNK_R, 10: 0.0, 11: 1.0, 12: 0.0}
const CONVEX := [4, 11]
var convex = {}
var cell = {}
var bodies: Array[StaticBody3D] = []
var last_cell = Vector2i(999999, 999999)


func _ready() -> void:
	data = FileAccess.get_file_as_bytes("res://data/world/veg.bin").to_float32_array()
	count = data.size() / 6
	for t in 13:
		meshes[t] = Props.vegetation_mesh(t)
		lods[t] = Props.vegetation_lod(t)
	for t in CONVEX:
		convex[t] = meshes[t].create_convex_shape(true, true)
	var chunks = {}
	for i in count:
		var x = data[i * 6]; var y = data[i * 6 + 2]
		var t = int(data[i * 6 + 5])
		var key = Vector3i(int(floor(x / CHUNK)), int(floor(y / CHUNK)), t)
		if not chunks.has(key):
			chunks[key] = []
		chunks[key].append(i)
		var ck = Vector2i(int(floor(x / 16.0)), int(floor(y / 16.0)))
		if not cell.has(ck):
			cell[ck] = []
		cell[ck].append(i)
	var view = float(Game.settings["view"])
	for key in chunks:
		var ids: Array = chunks[key]
		var t: int = key.z
		var center = Vector3((key.x + 0.5) * CHUNK, 0, -(key.y + 0.5) * CHUNK)
		var xforms = []
		var cols = []
		for j in ids.size():
			var i: int = ids[j]
			var s = data[i * 6 + 3]
			var basis = Basis(Vector3.UP, data[i * 6 + 4]).scaled(Vector3(s, s, s))
			xforms.append(Transform3D(basis, Vector3(data[i * 6], data[i * 6 + 1] - 0.3, -data[i * 6 + 2]) - center))
			var v = randf_range(-0.1, 0.1)
			cols.append(Color(1.0 + v, 1.0 + v * 0.6, 1.0 - v * 0.4))
		var near_end = (NEAR_FULL if not t in SMALL else 120.0) * view
		if t in [5, 11, 4]:
			near_end = 700.0 * view
		var a = _mmi(meshes[t], xforms, cols, center, 0.0, near_end if lods[t] != null else (near_end if t in SMALL else FAR_LOD * view))
		a.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if not t in SMALL else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if lods[t] != null:
			var b = _mmi(lods[t], xforms, cols, center, near_end, FAR_LOD * view)
			b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# yakın ağaç çarpışma havuzu: her gövde 1 silindir + 6 dal kutusu
	for k in 70:
		var sb = StaticBody3D.new()
		sb.collision_layer = 1
		var cs = CollisionShape3D.new()
		cs.shape = CylinderShape3D.new()
		cs.set_meta("cyl", cs.shape)
		sb.add_child(cs)
		for br in Props.FOREST_BRANCHES:
			var bc = CollisionShape3D.new()
			bc.shape = BoxShape3D.new()
			sb.add_child(bc)
		sb.position = Vector3(0, -2000, 0)
		add_child(sb)
		bodies.append(sb)


func _mmi(mesh: Mesh, xforms: Array, cols: Array, center: Vector3, begin: float, end: float) -> MultiMeshInstance3D:
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for j in xforms.size():
		mm.set_instance_transform(j, xforms[j])
		mm.set_instance_color(j, cols[j])
	var mmi = MultiMeshInstance3D.new()
	mmi.layers = 2
	mmi.multimesh = mm
	mmi.position = center
	mmi.visibility_range_begin = begin
	mmi.visibility_range_begin_margin = 25.0 if begin > 0.0 else 0.0
	mmi.visibility_range_end = end
	mmi.visibility_range_end_margin = 30.0
	mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(mmi)
	return mmi


func _physics_process(_dt: float) -> void:
	if Game.player == null:
		return
	var p = Game.player.global_position
	var c = Vector2i(int(floor(p.x / 16.0)), int(floor(-p.z / 16.0)))
	if c == last_cell:
		return
	last_cell = c
	var near: Array = []
	for dz in range(-4, 5):
		for dx in range(-4, 5):
			var ids = cell.get(c + Vector2i(dx, dz))
			if ids == null:
				continue
			for i in ids:
				var t = int(data[i * 6 + 5])
				if radii[t] <= 0.0:
					continue
				var d2 = Vector2(data[i * 6] - p.x, -data[i * 6 + 2] - p.z).length_squared()
				near.append([d2, i])
	near.sort_custom(func(a, b): return a[0] < b[0])
	for k in bodies.size():
		var sb = bodies[k]
		if k >= near.size():
			sb.position = Vector3(0, -2000, 0)
			continue
		var i: int = near[k][1]
		var t = int(data[i * 6 + 5])
		var s = data[i * 6 + 3]
		var yaw = data[i * 6 + 4]
		sb.global_transform = Transform3D(Basis(Vector3.UP, yaw), Vector3(data[i * 6], data[i * 6 + 1] - 0.3, -data[i * 6 + 2]))
		var trunk: CollisionShape3D = sb.get_child(0)
		if t in CONVEX:
			trunk.shape = convex[t]
			trunk.scale = Vector3.ONE * s
			trunk.position = Vector3(0, 0.3, 0)
			for b in Props.FOREST_BRANCHES.size():
				(sb.get_child(b + 1) as CollisionShape3D).disabled = true
			continue
		trunk.shape = trunk.get_meta("cyl")
		trunk.scale = Vector3.ONE
		var sh: CylinderShape3D = trunk.shape
		var h = 10.0 * s
		match t:
			9: h = Props.FOREST_TRUNK_H * s
			5: h = 60.0 * s
			4: h = 2.2 * s
			11: h = 4.5 * s
			1: h = 9.0 * s
			0: h = 6.5 * s
		sh.radius = radii[t] * s
		sh.height = h
		trunk.position = Vector3(0, h * 0.5, 0)
		for b in Props.FOREST_BRANCHES.size():
			var bc: CollisionShape3D = sb.get_child(b + 1)
			bc.disabled = t != 9
			if t == 9:
				var br: Array = Props.FOREST_BRANCHES[b]
				var a = deg_to_rad(br[1])
				var L: float = br[2]
				var d = Vector3(sin(a), 0, cos(a))
				(bc.shape as BoxShape3D).size = Vector3(1.4, 0.8, L) * s
				bc.transform = Transform3D(Basis(Vector3.UP, a), (d * (Props.FOREST_TRUNK_R + L * 0.5) + Vector3(0, br[0], 0)) * s)
