class_name PoseOverlay
extends SkeletonModifier3D
## Animasyonun üstüne prosedürel pozlar: Naruto koşusu (kollar geride), mühür yapma, tekme, duvar eğilmesi.
## Her poz: {kemik: Quaternion (kemiğin animasyonlu pozuna göre ek dönüş, kemiğin yerel uzayında)}

var weights = {}      # poz adı -> mevcut ağırlık
var targets = {}      # poz adı -> hedef ağırlık
var speed = 10.0
var poses = {}
var head_scale = 1.0   # çocuk/genç oranları: büyük kafa
var chest_scale = 1.0
var limb_scale = 1.0    # çocuk: ince kol ve bacaklar


func _ready() -> void:
	var e = func(x: float, y: float, z: float) -> Quaternion:
		return Quaternion.from_euler(Vector3(deg_to_rad(x), deg_to_rad(y), deg_to_rad(z)))
	poses = {
		"ninja_run": {
			"LeftUpperArm": e.call(0, 0, 0), "RightUpperArm": e.call(0, 0, 0),
			"_LeftArmBack": 1, "Chest": e.call(18, 0, 0), "Neck": e.call(-15, 0, 0),
		},
		"seal": {"_Seal": 1},
		"kick": {"_Kick": 1},
		"guard": {"_Guard": 1},
	}


func set_pose(name: String, w: float) -> void:
	targets[name] = w


func _process_modification() -> void:
	var sk = get_skeleton()
	if sk == null:
		return
	var dt = get_process_delta_time()
	for k in targets:
		weights[k] = move_toward(weights.get(k, 0.0), targets[k], dt * speed)
	var w_run: float = weights.get("ninja_run", 0.0)
	var w_seal: float = weights.get("seal", 0.0)
	var w_kick: float = weights.get("kick", 0.0)
	var w_guard: float = weights.get("guard", 0.0)
	if w_run > 0.0:
		_rot_model(sk, "LeftUpperArm", Vector3(-0.15, -0.55, -0.82), w_run)
		_rot_model(sk, "RightUpperArm", Vector3(0.15, -0.55, -0.82), w_run)
		_rot_model(sk, "LeftLowerArm", Vector3(-0.1, -0.3, -0.95), w_run)
		_rot_model(sk, "RightLowerArm", Vector3(0.1, -0.3, -0.95), w_run)
		_add_local(sk, "Spine", Vector3(deg_to_rad(16), 0, 0), w_run)
		_add_local(sk, "Neck", Vector3(deg_to_rad(-14), 0, 0), w_run)
	if w_seal > 0.0:
		# eller göğüs önünde birleşir
		_rot_model(sk, "LeftUpperArm", Vector3(0.45, -0.75, 0.48), w_seal)
		_rot_model(sk, "RightUpperArm", Vector3(-0.45, -0.75, 0.48), w_seal)
		_rot_model(sk, "LeftLowerArm", Vector3(-0.85, 0.35, 0.4), w_seal)
		_rot_model(sk, "RightLowerArm", Vector3(0.85, 0.35, 0.4), w_seal)
		_rot_model(sk, "LeftHand", Vector3(-0.3, 0.9, 0.3), w_seal)
		_rot_model(sk, "RightHand", Vector3(0.3, 0.9, 0.3), w_seal)
	if w_guard > 0.0:
		_rot_model(sk, "LeftUpperArm", Vector3(0.55, -0.4, 0.73), w_guard)
		_rot_model(sk, "RightUpperArm", Vector3(-0.55, -0.4, 0.73), w_guard)
		_rot_model(sk, "LeftLowerArm", Vector3(-0.6, 0.75, 0.25), w_guard)
		_rot_model(sk, "RightLowerArm", Vector3(0.6, 0.75, 0.25), w_guard)
	if w_kick > 0.0:
		_rot_model(sk, "RightUpperLeg", Vector3(0.05, 0.25, 0.97), w_kick)
		_rot_model(sk, "RightLowerLeg", Vector3(0.05, 0.3, 0.95), w_kick)
		_add_local(sk, "Spine", Vector3(deg_to_rad(-14), 0, 0), w_kick)
	# yaş oranları (kemik ölçeği çocuk kemiklere de geçer: saç/bant kafayla büyür)
	if head_scale != 1.0:
		var hb = sk.find_bone("Head")
		if hb >= 0:
			sk.set_bone_pose_scale(hb, Vector3.ONE * head_scale / chest_scale)
	if limb_scale != 1.0:
		for b in ["LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg"]:
			var li = sk.find_bone(b)
			if li >= 0:
				sk.set_bone_pose_scale(li, Vector3(limb_scale, 1.0, limb_scale))
	if chest_scale != 1.0:
		var cb = sk.find_bone("UpperChest")
		if cb >= 0:
			sk.set_bone_pose_scale(cb, Vector3(chest_scale, 1.0, chest_scale))


## Kemiği, model uzayında verilen yöne (kemik +Y ekseni = kemik doğrultusu) döndürür.
func _rot_model(sk: Skeleton3D, bone: String, dir_model: Vector3, w: float) -> void:
	var bi = sk.find_bone(bone)
	if bi < 0:
		return
	var gp = sk.get_bone_global_pose(bi)
	var cur_dir = gp.basis.y.normalized()
	var want = dir_model.normalized()
	# model ileri -Z: modelimiz 180° döndürülmüş olduğundan +Z = karakterin önü
	var q = Quaternion(cur_dir, want)
	var parent = sk.get_bone_parent(bi)
	var parent_basis = sk.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	var new_global = Basis(q) * gp.basis
	var local = (parent_basis.inverse() * new_global).get_rotation_quaternion()
	var cur = sk.get_bone_pose_rotation(bi)
	sk.set_bone_pose_rotation(bi, cur.slerp(local, clampf(w, 0, 1)))


func _add_local(sk: Skeleton3D, bone: String, euler: Vector3, w: float) -> void:
	var bi = sk.find_bone(bone)
	if bi < 0:
		return
	var cur = sk.get_bone_pose_rotation(bi)
	sk.set_bone_pose_rotation(bi, cur * Quaternion.from_euler(euler * w))
