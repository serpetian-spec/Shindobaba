class_name GroundMarks
extends RefCounted
## Zemin izleri: kumda/karda ayak izi (bir süre kalır, solar), su üstünde yürürken halka dalga + damla.
## Ayak sesiyle aynı anda çağrılır (Player._footstep / Enemy._footsteps): basan ayak = o an daha alçaktaki ayak.

const MAX_PRINTS := 80
const PRINT_LIFE := 14.0
const SAND := [1, 3]     # 1 sahil, 3 çöl
const SNOW := [8]
static var _prints: Array = []
static var _mesh: ArrayMesh
static var _mat: StandardMaterial3D


static func _foot(model: Node3D) -> Dictionary:
	var sk: Skeleton3D = model.get("skel")
	if sk == null:
		return {}
	var out = {}
	for side in ["Left", "Right"]:
		var bi = sk.find_bone(side + "Foot")
		if bi < 0:
			continue
		var p: Vector3 = sk.global_transform * sk.get_bone_global_pose(bi).origin
		if out.is_empty() or p.y < (out["pos"] as Vector3).y:
			out = {"pos": p, "side": side}
	return out


## Adım anında: zemine göre iz/halka
static func step(who: Node3D, on_water: bool, water_y := 0.0) -> void:
	if who == null or not is_instance_valid(who) or who.get("model") == null:
		return
	if Interiors.inst and Interiors.inst.inside != "":
		return
	var f = _foot(who.model)
	if f.is_empty():
		return
	var p: Vector3 = f["pos"]
	if on_water:
		ripple(Vector3(p.x, water_y + 0.03, p.z), 1.0)
		return
	var b = Game.biome_at(p.x, p.z)
	if b in SAND or b in SNOW:
		var yaw: float = who.model.global_rotation.y
		_print(Vector3(p.x, Game.ground_height(p.x, p.z) + 0.025, p.z), yaw, f["side"] == "Left", Color(0.55, 0.4, 0.2, 0.75) if b in SAND else Color(0.5, 0.58, 0.72, 0.7))


## Su halkası: ince açık mavi-beyaz halka genişleyip söner + birkaç küçük damla
static func ripple(at: Vector3, s := 1.0) -> void:
	FX.ring(at, Color(0.85, 0.95, 1.0, 0.55), 1.3 * s, 0.7)
	FX.burst(at, {"amount": 5, "life": 0.35, "tex": FX.tex_soft, "size": 0.08 * s, "radius": 0.15, "vmin": 1.0, "vmax": 2.2,
		"dir": Vector3.UP, "spread": 35.0, "gravity": Vector3(0, -9.0, 0), "colors": [Color(0.9, 0.97, 1.0, 0.85), Color(0.8, 0.92, 1.0, 0.0)]})


static func _print(at: Vector3, yaw: float, left: bool, col: Color) -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	if _mesh == null:
		# basit ayak izi: topuk + taban (iki yassı oval), üstten görünür
		var b = MB.new()
		b.add("sphere", Vector3(0, 0, -0.06), Vector3(0.13, 0.01, 0.2), Color.WHITE, Vector3.ZERO, 10)   # taban (önde)
		b.add("sphere", Vector3(0, 0, 0.1), Vector3(0.1, 0.01, 0.13), Color.WHITE, Vector3.ZERO, 10)    # topuk
		_mat = StandardMaterial3D.new()
		_mat.vertex_color_use_as_albedo = false
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat.albedo_color = Color.WHITE
		_mesh = b.build(_mat)
	var mi = MeshInstance3D.new()
	mi.mesh = _mesh
	var m: StandardMaterial3D = _mat.duplicate()
	m.albedo_color = col
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tree.current_scene.add_child(mi)
	var side = Vector3(cos(yaw), 0, -sin(yaw)) * (0.09 if left else -0.09)
	mi.global_position = at + side
	mi.rotation.y = yaw
	_prints.append(mi)
	while _prints.size() > MAX_PRINTS:
		var old = _prints.pop_front()
		if is_instance_valid(old):
			old.queue_free()
	var tw = mi.create_tween()
	tw.tween_interval(PRINT_LIFE * 0.6)
	tw.tween_property(m, "albedo_color:a", 0.0, PRINT_LIFE * 0.4)
	tw.tween_callback(mi.queue_free)
