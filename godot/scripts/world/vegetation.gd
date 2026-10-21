extends Node3D
## Bitki örtüsü: 40 bin ağaç/kaya/çalı, 512 m'lik parçalarda MultiMesh, görünürlük mesafesiyle.
## Oyuncunun çevresindeki ağaç gövdelerine gerçek çarpışma eklenir (havuzlu).

const CHUNK := 384.0
const NEAR_COLLIDE := 45.0

var data: PackedFloat32Array
var count = 0
var meshes = {}  # tip -> Mesh
var radii = {0: 0.55, 1: 0.45, 2: 0.4, 3: 0.35, 4: 1.4, 5: 3.2, 6: 0.15, 7: 0.35, 8: 0.0}
var cell = {}  # (ix,iz) -> [instance indices]  çarpışma araması için
var colliders: Array[StaticBody3D] = []
var last_cell = Vector2i(999999, 999999)


func _ready() -> void:
	data = FileAccess.get_file_as_bytes("res://data/world/veg.bin").to_float32_array()
	count = data.size() / 6
	for t in 9:
		meshes[t] = Props.vegetation_mesh(t)
	# parçalara böl
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
	for key in chunks:
		var ids: Array = chunks[key]
		var t: int = key.z
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = meshes[t]
		mm.instance_count = ids.size()
		var center = Vector3((key.x + 0.5) * CHUNK, 0, -(key.y + 0.5) * CHUNK)
		for j in ids.size():
			var i: int = ids[j]
			var s = data[i * 6 + 3]
			var basis = Basis(Vector3.UP, data[i * 6 + 4]).scaled(Vector3(s, s * randf_range(0.9, 1.15), s))
			var p = Vector3(data[i * 6], data[i * 6 + 1] - 0.2, -data[i * 6 + 2]) - center
			mm.set_instance_transform(j, Transform3D(basis, p))
			var v = randf_range(-0.12, 0.12)
			mm.set_instance_color(j, Color(1.0 + v, 1.0 + v * 0.5, 1.0 - v * 0.3))
		var mmi = MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.position = center
		var far = 900.0 if t in [5, 4] else 650.0
		if t == 8:
			far = 220.0
		mmi.visibility_range_end = far * float(Game.settings["view"])
		mmi.visibility_range_end_margin = 40.0
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if t != 8 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
	for k in 64:
		var sb = StaticBody3D.new()
		var cs = CollisionShape3D.new()
		var sh = CylinderShape3D.new()
		sh.height = 14.0
		cs.shape = sh
		sb.add_child(cs)
		sb.collision_layer = 1
		sb.position = Vector3(0, -1000, 0)
		add_child(sb)
		colliders.append(sb)


func _physics_process(_dt: float) -> void:
	if Game.player == null:
		return
	var p = Game.player.global_position
	var c = Vector2i(int(floor(p.x / 16.0)), int(floor(-p.z / 16.0)))
	if c == last_cell:
		return
	last_cell = c
	var used = 0
	for dz in range(-3, 4):
		for dx in range(-3, 4):
			var ids = cell.get(c + Vector2i(dx, dz))
			if ids == null:
				continue
			for i in ids:
				var t = int(data[i * 6 + 5])
				var r: float = radii[t] * data[i * 6 + 3]
				if r <= 0.0 or used >= colliders.size():
					continue
				var sb = colliders[used]
				used += 1
				var sh: CylinderShape3D = sb.get_child(0).shape
				var h = 14.0 * data[i * 6 + 3] if t != 4 else 2.2 * data[i * 6 + 3]
				if t == 5:
					h = 60.0
				sh.radius = r
				sh.height = h
				sb.global_position = Vector3(data[i * 6], data[i * 6 + 1] + h * 0.5 - 0.3, -data[i * 6 + 2])
	for k in range(used, colliders.size()):
		colliders[k].global_position = Vector3(0, -1000, 0)
