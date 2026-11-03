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
var left_holder := Basis.IDENTITY   # sol el tutuş çerçevesi (el kemiği uzayında)
var left_roll := 0.0
var mirror_axis := 0
static var left_single_sign := -1.0   # tek elli sol tutuş: +1 parmakları geriye büküyordu (yakın çekimle doğrulandı)
var left_curl_sign := -1.0   # ön izlemede onaylanan (alt sıra)   # sol elin kabza ekseni etrafında dönüşü (derece)   # sol el sağ elle aynı yönde kabzayı sarar (test: öndeki yumruk kabzanın etrafında)
var left_grip_pos := Vector3.ZERO   # sol el tutuş noktası (el kemiği uzayında)
var reach_open := false       # true: kol uzanırken el açık kalır (Rasengan / Chidori avucu), yumruk yapmaz
static var AX := Vector3(-1, 0, 0)   # VRoid parmak kıvrım ekseni (kemik yerel -X)


## Ön kol kilidi (tonfa): taraf -> [mesh'in el kemiğine göre basis'i, mesh uzayında dirseğe giden gövde ekseni].
## Her karede el kemiği döndürülür ki gövde ön kol boyunca dirseğe uzansın (bilek bükülse de tonfa koldan ayrılmaz).
var forearm_lock := {}


func _forearm_lock(sk: Skeleton3D) -> void:
	for side in forearm_lock:
		if float(hold.get(side, 0.0)) <= 0.0:
			continue
		var hb = sk.find_bone(side + "Hand")
		var lb = sk.find_bone(side + "LowerArm")
		if hb < 0 or lb < 0:
			continue
		var hp: Transform3D = sk.get_bone_global_pose(hb)
		var to_elbow: Vector3 = sk.get_bone_global_pose(lb).origin - hp.origin
		if to_elbow.length() < 0.01:
			continue
		var e: Array = forearm_lock[side]
		var axis: Vector3 = (hp.basis * (e[0] as Basis) * (e[1] as Vector3)).normalized()
		var want = to_elbow.normalized()
		if axis.dot(want) > 0.9999:
			continue
		var q = Quaternion(axis, want)
		var par = sk.get_bone_parent(hb)
		var parb: Basis = sk.get_bone_global_pose(par).basis if par >= 0 else Basis.IDENTITY
		sk.set_bone_pose_rotation(hb, (parb.inverse() * (Basis(q) * hp.basis)).get_rotation_quaternion())


func _process_modification() -> void:
	var sk = get_skeleton()
	if sk == null:
		return
	var dt = get_process_delta_time()
	if not forearm_lock.is_empty():
		_forearm_lock(sk)
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
			if relax_free:
				_relax_hand(sk, side)
			continue
		var sgn = 1.0 if side == "Left" else -1.0
		if side == "Left" and two_hand_w > 0.0:
			sgn *= left_curl_sign   # iki elle tutuşta sol el aynalandığı için kıvrım yönü
		elif side == "Left":
			sgn *= left_single_sign   # tek elle sol tutuş (çift silahın sol eli)
		for f in FINGERS:
			for i in 3:
				_curl(sk, side + f + FINGER_SEG[i], Quaternion(AX, CURL[i] * sgn), w)
		# başparmak kabzanın üstüne kapanır
		# başparmak kabzayı sarar, parmakların üstüne kapanır (eskiden kabza boyunca dik havada duruyordu)
		var th = Vector3(0.3 * sgn, 0.6 * sgn, 0.6 * sgn)
		var tds = sgn
		if side == "Left" and two_hand_w > 0.0:
			# iki elli tutuşta SOL BAŞPARMAK (kullanıcı istedi): aynalanmış elde dört parmağın işaret çevirmesi başparmağı
			# dışarı kaldırıyordu -> başparmak sol elin kendi sarma yönüyle kabzaya kapanır
			th = LEFT_TWO_THUMB[left_thumb_mode]
			tds = 1.0 if left_thumb_mode != 0 else sgn
		_curl(sk, side + "ThumbProximal", Quaternion.from_euler(th), w)
		_curl(sk, side + "ThumbDistal", Quaternion.from_euler(Vector3(0.5 * tds, 0, 0)), w)


static var LEFT_TWO_THUMB := [Vector3(-0.3, -0.6, -0.6), Vector3(0.3, 0.6, 0.6), Vector3(-0.3, 0.6, 0.6), Vector3(0.3, -0.6, -0.6)]
static var left_thumb_mode := 1
var relax_meta := Vector3(0.6, -0.3, 0.0)   # boş el başparmağı içe kıvrık (dışa kanca gibi çıkmaz)
var relax_dist := 0.4
var relax_meta_r := Vector3(-0.6, -0.3, 0.0)   # sağ (silah) eli boşken başparmak içe kıvrık
var relax_thumb := Vector3.ZERO
var relax_free := true   # boştaki el: animasyonun zikzak başparmağı yerine rahat, hafif kıvrık el


## Boştaki el rahat duruş: parmaklar hafif kıvrık, başparmak işaret parmağının yanında düz-hafif kıvrık (zikzak yok)
func _relax_hand(sk: Skeleton3D, side: String) -> void:
	# boştaki el animasyonun orijinal hâlinde kalır; YALNIZ zikzak başparmak düzeltilir (işaret parmağının yanına yatık)
	var sgn = 1.0 if side == "Left" else -1.0
	var rm = relax_meta if side == "Left" else relax_meta_r
	if rm != Vector3.ZERO:
		_curl(sk, side + "ThumbMetacarpal", Quaternion.from_euler(Vector3(rm.x * sgn, rm.y * sgn, rm.z * sgn)), 1.0)
	_curl(sk, side + "ThumbProximal", Quaternion.from_euler(Vector3(relax_thumb.x * sgn, relax_thumb.y * sgn, relax_thumb.z * sgn)), 1.0)
	_curl(sk, side + "ThumbDistal", Quaternion.from_euler(Vector3(relax_dist * sgn, 0, 0)), 1.0)


## İki kemikli IK: sol omuz-dirsek-el zinciri, silah sapındaki hedefe uzanır (dirsek aşağı-dışa)
func _two_hand_ik(sk: Skeleton3D, w: float) -> void:
	# sol el = sağ elin kabza düzlemine göre AYNA kopyası (aynı şekil, kabzanın karşı tarafından sarar), kabza boyunca biraz aşağıda.
	# Parmaklar sağ eldekiyle aynı kıvrımda (hold Left); kol IK ile bileği oraya taşır.
	var ua = sk.find_bone("LeftUpperArm")
	var la = sk.find_bone("LeftLowerArm")
	var hb = sk.find_bone("LeftHand")
	var rb = sk.find_bone("RightHand")
	if ua < 0 or la < 0 or hb < 0 or rb < 0:
		return
	var inv = sk.global_transform.affine_inverse()
	var wx: Transform3D = two_hand_node.global_transform
	var axis: Vector3 = (sk.global_transform.basis.orthonormalized().inverse() * wx.basis.z).normalized()
	var p0: Vector3 = inv * wx.origin
	var rp: Transform3D = sk.get_bone_global_pose(rb)
	var nx = Vector3.RIGHT - axis * axis.dot(Vector3.RIGHT)
	if nx.length() < 0.05:
		nx = Vector3.FORWARD
	nx = nx.normalized()
	var R = Basis(Vector3.RIGHT - 2.0 * nx * nx.x, Vector3.UP - 2.0 * nx * nx.y, Vector3.BACK - 2.0 * nx * nx.z)
	var D = [Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)), Basis(Vector3(1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, 1)), Basis(Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1))][mirror_axis]
	var want_hand: Basis = (R * rp.basis.orthonormalized() * D).orthonormalized()
	var tgt: Vector3 = p0 + R * (rp.origin - p0) + axis * two_hand_off
	# yinelemeli IK: kemik eksen sapmaları yüzünden el hedefin ~6 cm yanına düşüyordu -> hatayı hedefe ekleyip 4 kez düzelt
	var aim = tgt
	for it in 4:
		_arm_ik(sk, ua, la, aim, w)
		var err = tgt - sk.get_bone_global_pose(hb).origin
		if err.length() < 0.004:
			break
		aim += err
	var par = sk.get_bone_parent(hb)
	var pbas: Basis = sk.get_bone_global_pose(par).basis.orthonormalized() if par >= 0 else Basis.IDENTITY
	sk.set_bone_pose_rotation(hb, sk.get_bone_pose_rotation(hb).slerp((pbas.inverse() * want_hand).get_rotation_quaternion(), clampf(w, 0.0, 1.0)))


func _arm_ik(sk: Skeleton3D, ua: int, la: int, tgt: Vector3, w: float) -> void:
	var S = sk.get_bone_global_pose(ua).origin
	var E = sk.get_bone_global_pose(la).origin
	var hb = sk.find_bone("LeftHand")
	var H = sk.get_bone_global_pose(hb).origin
	var a = S.distance_to(E)
	var b = E.distance_to(H)
	var d = tgt - S
	var dist = clampf(d.length(), 0.05, a + b - 0.002)
	var dn = d.normalized()
	var pole = Vector3(0.4, -1.0, -0.3).normalized()
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
