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
var leg_len = 1.0       # çocuk: kısa bacaklar (model yere indirilir)
var foot_pitch = 0.0    # VRoid kadın ayağı (topuklu ayakkabı kalıbı): ayağı düzle (derece)
var toe_pitch = 0.0     # VRoid: içe aktarıcı ayak parmağı kemiğini yükseltiyor; parmakları yere indirir (derece)
## Jutsu atma koreografisi (CastAnim her kare doldurur):
## {"arms": [[kemik, model-uzayı yön], ...] (ebeveynden çocuğa sırayla), "fL"/"fR": [işaret, orta, yüzük, serçe, başparmak] kıvrım (rad),
##  "spine": derece, "neck": derece, "hips_yaw": derece}
var cast_pose := {}
const FINGERS := ["Index", "Middle", "Ring", "Little"]
const FINGER_SEG := ["Proximal", "Intermediate", "Distal"]
const THUMB_SEG := ["Metacarpal", "Proximal", "Distal"]
const STANCE := {
	"w_blade": [["RightUpperArm", Vector3(-0.3, -0.75, 0.55)], ["RightLowerArm", Vector3(0.25, 0.35, 0.9)], ["LeftUpperArm", Vector3(0.35, -0.8, 0.45)], ["LeftLowerArm", Vector3(-0.1, 0.2, 0.97)]],
	"w_sword": [["RightUpperArm", Vector3(-0.15, -0.8, 0.55)], ["RightLowerArm", Vector3(0.3, -0.2, 0.93)], ["LeftUpperArm", Vector3(0.2, -0.8, 0.55)], ["LeftLowerArm", Vector3(-0.45, -0.15, 0.88)]],
	"w_shoulder": [["RightUpperArm", Vector3(-0.75, -0.25, 0.6)], ["RightLowerArm", Vector3(0.15, 0.95, 0.2)]],
	"w_dual": [["LeftUpperArm", Vector3(0.4, -0.8, 0.45)], ["LeftLowerArm", Vector3(0.1, -0.35, 0.93)], ["RightUpperArm", Vector3(-0.4, -0.8, 0.45)], ["RightLowerArm", Vector3(-0.1, -0.35, 0.93)]],
	"w_fan": [["RightUpperArm", Vector3(-0.85, -0.45, 0.25)], ["RightLowerArm", Vector3(-0.5, 0.3, 0.8)]],
}


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
		"leap": {"_Leap": 1},
		"cast": {"_Cast": 1},
		# silah duruşları (bekleme/koşu): ters tutuş kunai, iki elle kılıç, omuzda ağır silah, çift bıçak alçak, yelpaze yanda
		"w_blade": {}, "w_sword": {}, "w_shoulder": {}, "w_dual": {}, "w_fan": {},
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
	var w_leap: float = weights.get("leap", 0.0)
	if w_leap > 0.0:
		# Striker sıçrayışı: gövde öne yatık, kollar arkaya savrulmuş, bacaklar geride süzülür
		_rot_model(sk, "LeftUpperArm", Vector3(-0.25, -0.35, -0.9), w_leap)
		_rot_model(sk, "RightUpperArm", Vector3(0.25, -0.35, -0.9), w_leap)
		_rot_model(sk, "LeftLowerArm", Vector3(-0.15, -0.2, -0.97), w_leap)
		_rot_model(sk, "RightLowerArm", Vector3(0.15, -0.2, -0.97), w_leap)
		_add_local(sk, "Spine", Vector3(deg_to_rad(28), 0, 0), w_leap)
		_add_local(sk, "Neck", Vector3(deg_to_rad(-25), 0, 0), w_leap)
		_rot_model(sk, "LeftUpperLeg", Vector3(0.05, -0.75, -0.65), w_leap)
		_rot_model(sk, "RightUpperLeg", Vector3(-0.05, -0.95, 0.3), w_leap)
		_rot_model(sk, "LeftLowerLeg", Vector3(0.0, -0.25, -0.97), w_leap)
		_rot_model(sk, "RightLowerLeg", Vector3(0.0, -0.8, -0.6), w_leap)
	# silah duruşları (mühür/blok/tekme sonra gelir ve bunları ezer)
	for st in STANCE:
		var ws: float = weights.get(st, 0.0)
		if ws > 0.0:
			for e in STANCE[st]:
				_rot_model(sk, e[0], e[1], ws)
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
	var w_cast: float = weights.get("cast", 0.0)
	if w_cast > 0.0 and not cast_pose.is_empty():
		_apply_cast(sk, w_cast)
	# yaş oranları (kemik ölçeği çocuk kemiklere de geçer: saç/bant kafayla büyür)
	if head_scale != 1.0:
		var hb = sk.find_bone("Head")
		if hb >= 0:
			sk.set_bone_pose_scale(hb, Vector3.ONE * head_scale / chest_scale)
	if foot_pitch != 0.0:
		for b in ["LeftFoot", "RightFoot"]:
			var fi = sk.find_bone(b)
			if fi >= 0:
				sk.set_bone_pose_rotation(fi, sk.get_bone_pose_rotation(fi) * Quaternion(Vector3.RIGHT, deg_to_rad(foot_pitch)))
	if toe_pitch != 0.0:
		for b in ["LeftToes", "RightToes"]:
			var ti = sk.find_bone(b)
			if ti >= 0:
				sk.set_bone_pose_rotation(ti, sk.get_bone_rest(ti).basis.get_rotation_quaternion() * Quaternion(Vector3.RIGHT, deg_to_rad(toe_pitch)))
	if limb_scale != 1.0 or leg_len != 1.0:
		for b in ["LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg"]:
			var li = sk.find_bone(b)
			if li >= 0:
				sk.set_bone_pose_scale(li, Vector3(limb_scale, leg_len if b.ends_with("Leg") else 1.0, limb_scale))
	if chest_scale != 1.0:
		var cb = sk.find_bone("UpperChest")
		if cb >= 0:
			sk.set_bone_pose_scale(cb, Vector3(chest_scale, 1.0, chest_scale))


## Jutsu pozu: gövde, kollar (sırayla), parmaklar
func _apply_cast(sk: Skeleton3D, w: float) -> void:
	var cp = cast_pose
	var cr: float = cp.get("crouch", 0.0) * w
	if cr > 0.0:
		# çömelme: kalça alçalır, uyluklar öne, baldırlar geriye (ayaklar yerde kalır)
		var hb = sk.find_bone("Hips")
		if hb >= 0:
			sk.set_bone_pose_position(hb, sk.get_bone_pose_position(hb) + Vector3(0, -0.32 * cr, 0.05 * cr))
		for side in [["Left", 1.0], ["Right", -1.0]]:
			_rot_model(sk, side[0] + "UpperLeg", Vector3(0.12 * side[1], -0.45, 0.88), cr)
			_rot_model(sk, side[0] + "LowerLeg", Vector3(0.0, -0.9, -0.42), cr)
			_rot_model(sk, side[0] + "Foot", Vector3(0.0, -0.45, 0.89), cr)
	if cp.get("hips_yaw", 0.0) != 0.0:
		_add_local(sk, "Hips", Vector3(0, deg_to_rad(cp["hips_yaw"]), 0), w)
	if cp.get("spine", 0.0) != 0.0:
		_add_local(sk, "Spine", Vector3(deg_to_rad(cp["spine"]) * 0.5, 0, 0), w)
		_add_local(sk, "Chest", Vector3(deg_to_rad(cp["spine"]) * 0.5, 0, 0), w)
	if cp.get("neck", 0.0) != 0.0:
		_add_local(sk, "Neck", Vector3(deg_to_rad(cp["neck"]), 0, 0), w)
	for a in cp.get("arms", []):
		_rot_model(sk, a[0], a[1], w)
	for side in ["L", "R"]:
		var f: Array = cp.get("f" + side, [])
		if f.size() < 5:
			continue
		var pre = "Left" if side == "L" else "Right"
		var sgn = 1.0 if side == "L" else -1.0
		for i in 4:
			for seg in FINGER_SEG:
				_add_local(sk, pre + FINGERS[i] + seg, Vector3(f[i] * 0.55 * sgn, 0, 0), w)
		# başparmak: avuca doğru katla
		for seg in THUMB_SEG:
			_add_local(sk, pre + "Thumb" + seg, Vector3(f[4] * 0.4 * sgn, 0, -f[4] * 0.3), w)


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
