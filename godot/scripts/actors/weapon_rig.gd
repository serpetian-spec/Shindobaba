class_name WeaponRig
extends SkeletonModifier3D
## Silah eli: silah tutan elin parmaklarını kabzanın etrafında yumruk yapar; kın çekme/sokma hareketinde kolu kına uzatır.
## PoseOverlay'den SONRA çalışır (açık avuç pozları silahlı elde yumruğa döner).

const FINGERS := ["Index", "Middle", "Ring", "Little"]
const FINGER_SEG := ["Proximal", "Intermediate", "Distal"]
const CURL := [1.25, 1.45, 0.9]   # parmak bölümü başına kıvrım (rad): tam kavrayış

var hold := {"Left": 0.0, "Right": 0.0}       # hedef: o elde silah var mı (0/1)
var _hold_w := {"Left": 0.0, "Right": 0.0}
var reach_side := "Right"
var reach_arms: Array = []    # [[kemik, model-uzayı yön], ...] kına uzanma pozu
var reach_w := 0.0            # 0..1 (CharacterModel kın animasyonunda sürer)
var two_hand_node: Node3D = null   # iki elle tutuş: sol el bu silahın sapına (kabzadan two_hand_off m ileride) uzanır
var two_hand_off := 0.32
var two_hand_w := 0.0
var reach_open := false       # true: kol uzanırken el açık kalır (Rasengan / Chidori avucu), yumruk yapmaz
static var AX := Vector3(-1, 0, 0)   # VRoid parmak kıvrım ekseni (kemik yerel -X)


func _process_modification() -> void:
	var sk = get_skeleton()
	if sk == null:
		return
	var dt = get_process_delta_time()
	if reach_w > 0.0:
		for a in reach_arms:
			_rot_model(sk, a[0], a[1], reach_w)
	if two_hand_w > 0.0 and two_hand_node and is_instance_valid(two_hand_node):
		_two_hand_ik(sk, two_hand_w)
	for side in hold:
		var tgt: float = hold[side]
		if side == "Left" and two_hand_w > 0.0:
			tgt = maxf(tgt, two_hand_w)
		if reach_w > 0.0 and side == reach_side and not reach_open:
			tgt = maxf(tgt, reach_w)
		_hold_w[side] = move_toward(_hold_w[side], tgt, dt * 8.0)
		var w: float = _hold_w[side]
		if w <= 0.0:
			continue
		var sgn = 1.0 if side == "Left" else -1.0
		for f in FINGERS:
			for i in 3:
				_curl(sk, side + f + FINGER_SEG[i], Quaternion(AX, CURL[i] * sgn), w)
		# başparmak kabzanın üstüne kapanır
		_curl(sk, side + "ThumbProximal", Quaternion.from_euler(Vector3(0.35 * sgn, 0, -0.35 * sgn)), w)
		_curl(sk, side + "ThumbDistal", Quaternion.from_euler(Vector3(0.5 * sgn, 0, 0)), w)


## İki kemikli IK: sol omuz-dirsek-el zinciri, silah sapındaki hedefe uzanır (dirsek aşağı-dışa)
func _two_hand_ik(sk: Skeleton3D, w: float) -> void:
	var ua = sk.find_bone("LeftUpperArm")
	var la = sk.find_bone("LeftLowerArm")
	var hb = sk.find_bone("LeftHand")
	if ua < 0 or la < 0 or hb < 0:
		return
	var inv = sk.global_transform.affine_inverse()
	var wx: Transform3D = two_hand_node.global_transform
	var tgt: Vector3 = inv * (wx.origin + wx.basis.z.normalized() * two_hand_off)
	var S = sk.get_bone_global_pose(ua).origin
	var E = sk.get_bone_global_pose(la).origin
	var H = sk.get_bone_global_pose(hb).origin
	var a = S.distance_to(E)
	var b = E.distance_to(H)
	var d = tgt - S
	var dist = clampf(d.length(), 0.05, a + b - 0.002)
	var dn = d.normalized()
	var pole = Vector3(0.4, -1.0, -0.3).normalized()   # dirsek aşağı ve dışa (model sol tarafı +X)
	var perp = (pole - dn * pole.dot(dn))
	if perp.length() < 0.01:
		perp = Vector3.DOWN
	perp = perp.normalized()
	var cos_a = clampf((a * a + dist * dist - b * b) / (2.0 * a * dist), -1.0, 1.0)
	var elbow = S + (dn * cos_a + perp * sqrt(1.0 - cos_a * cos_a)) * a
	_rot_model(sk, "LeftUpperArm", elbow - S, w)
	var E2 = sk.get_bone_global_pose(la).origin
	_rot_model(sk, "LeftLowerArm", (S + dn * dist) - E2, w)


## Parmağı dinlenme pozuna göre verilen kıvrıma (mutlak) yaklaştır: animasyondaki açık el ne olursa olsun kapanır
func _curl(sk: Skeleton3D, bone: String, q: Quaternion, w: float) -> void:
	var bi = sk.find_bone(bone)
	if bi < 0:
		return
	var target = sk.get_bone_rest(bi).basis.get_rotation_quaternion() * q
	sk.set_bone_pose_rotation(bi, sk.get_bone_pose_rotation(bi).slerp(target, clampf(w, 0.0, 1.0)))


## Kemiği model uzayında verilen yöne çevir (PoseOverlay._rot_model ile aynı)
func _rot_model(sk: Skeleton3D, bone: String, dir_model: Vector3, w: float) -> void:
	var bi = sk.find_bone(bone)
	if bi < 0:
		return
	var gp = sk.get_bone_global_pose(bi)
	var q = Quaternion(gp.basis.y.normalized(), dir_model.normalized())
	var parent = sk.get_bone_parent(bi)
	var parent_basis = sk.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	var local = (parent_basis.inverse() * (Basis(q) * gp.basis)).get_rotation_quaternion()
	sk.set_bone_pose_rotation(bi, sk.get_bone_pose_rotation(bi).slerp(local, clampf(w, 0.0, 1.0)))
