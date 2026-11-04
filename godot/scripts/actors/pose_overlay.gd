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
var hide := {}          # kemik -> true: kemik (ve çocukları) görünmez küçülür (Shuradō: bilekten kopan el)
var bulk := {}          # kemik -> kalınlık (Gōsuiwan: kol kasları suyla şişer); el/ayak çocuğu orantılı kalır
var leg_len = 1.0       # çocuk: kısa bacaklar (model yere indirilir)
var foot_pitch = 0.0    # VRoid kadın ayağı (topuklu ayakkabı kalıbı): ayağı düzle (derece)
var toe_pitch = 0.0     # VRoid: içe aktarıcı ayak parmağı kemiğini yükseltiyor; parmakları yere indirir (derece)
## Jutsu atma koreografisi (CastAnim her kare doldurur):
## {"arms": [[kemik, model-uzayı yön], ...] (ebeveynden çocuğa sırayla), "fL"/"fR": [işaret, orta, yüzük, serçe, başparmak] kıvrım (rad),
##  "spine": derece, "neck": derece, "hips_yaw": derece}
var cast_pose := {}
var key_anim := {}       # anahtar karelerle el yapımı animasyon (SamehadaAnim adımı): {len, keys:[{t, crouch, hips_yaw, spine, neck, blade, b:{kemik:yön}}]}
var key_t := -1.0
var key_spd := 1.0
var time_comp := 1.0   # oyuncu: Sharingan algısında anahtar animasyon normal hızda
var key_blade := Vector3.ZERO
var key_roll := 0.0   # silahın sap ekseni etrafında dönüşü (derece; gunbai kalkan itişi)   # o anki silah ucu yönü (iskelet uzayı); CharacterModel silahı buna çevirir
var charge_k := 0.0     # süper zıplama şarjı 0..1: çömelme derinliği
var glide_land := 0.0   # süzülmeden inişe hazırlık 0..1 (dizler öne, kollar dengede)
var tuck := 0.0         # havada takla / kenara tırmanış: dizler göğse, kollar dizlere sarılı 0..1 (süzülmeyi ezer)
var _t := 0.0
# darbe tepkisi: gövde/kafa vuruş yönünde savrulur, yay gibi geri döner (her darbede; animasyon klibinin üstüne)
var hit_t := 9.0
var hit_dir := Vector3.ZERO   # model uzayında itiş yönü (+Z karakterin önü)
var hit_amp := 0.0
var hit_head := false
var hit_side := 1.0


var hit_up := 0.0      # havaya fırlatma: gövde geriye kavislenir, kollar savrulur
var hit_heavy := 0.0   # ağır darbe: dizler çöker, kalça düşer
var key_mass := 0.5    # silah ağırlığı (0 hafif .. 1 ağır): kol ve silah yaylanması (KeyedCombos.mass)
var root_vel := Vector3.ZERO   # adımla ilerleme: basan ayak yerinde kalsın diye gövdenin dünya hızı (anahtar animasyonda)
var foot_ik := true    # ayaklar zemine basar (eğim / basamak)
var grounded := true   # havadayken IK yok (sahip ayarlar)


func hit_react(dir_model: Vector3, amp: float, head := false, up := 0.0, heavy := 0.0) -> void:
	hit_up = clampf(up, 0.0, 1.0)
	hit_heavy = clampf(heavy, 0.0, 1.0)
	hit_t = 0.0
	hit_dir = Vector3(dir_model.x, 0.0, dir_model.z).normalized() if Vector2(dir_model.x, dir_model.z).length() > 0.05 else Vector3(0, 0, -1)
	hit_amp = clampf(amp, 0.0, 1.4)
	hit_head = head
	hit_side = 1.0 if randf() < 0.5 else -1.0
const FINGERS := ["Index", "Middle", "Ring", "Little"]
const FINGER_SEG := ["Proximal", "Intermediate", "Distal"]
const THUMB_SEG := ["Metacarpal", "Proximal", "Distal"]
static var STANCE := {
	"w_blade": [["RightUpperArm", Vector3(-0.22, -0.93, 0.28)], ["RightLowerArm", Vector3(-0.05, -0.35, 0.94)], ["LeftUpperArm", Vector3(0.22, -0.97, 0.06)], ["LeftLowerArm", Vector3(0.1, -0.9, 0.42)]],   # kunai: sağ el kalça önünde öne dönük, sol kol rahat aşağıda
	"w_sword": [["RightUpperArm", Vector3(-0.15, -0.8, 0.55)], ["RightLowerArm", Vector3(0.3, -0.2, 0.93)], ["LeftUpperArm", Vector3(0.2, -0.8, 0.55)], ["LeftLowerArm", Vector3(-0.45, -0.15, 0.88)]],
	"w_kubi": [["RightUpperArm", Vector3(-0.45, -0.6, 0.66)], ["RightLowerArm", Vector3(0.25, 0.75, 0.6)]],   # Zabuza: yumruk sağ omzun önünde, ağız omza yaslı geriye
	"w_shoulder": [["RightUpperArm", Vector3(-0.75, -0.25, 0.6)], ["RightLowerArm", Vector3(0.15, 0.95, 0.2)]],
	"w_dual": [["LeftUpperArm", Vector3(0.4, -0.8, 0.45)], ["LeftLowerArm", Vector3(0.1, -0.35, 0.93)], ["RightUpperArm", Vector3(-0.4, -0.8, 0.45)], ["RightLowerArm", Vector3(-0.1, -0.35, 0.93)]],
	"w_gunbai": [["RightUpperArm", Vector3(-0.5, -0.8, 0.3)], ["RightLowerArm", Vector3(0.2, 0.3, 0.93)], ["RightHand", Vector3(0.6, 0.55, 0.6)]],   # omuzda: ön izlemede beğenilen poz, biraz sağ omza çevrik (kafadan geçmez)
	"w_raijin": [["RightUpperArm", Vector3(0.0, -0.75, 0.66)], ["RightLowerArm", Vector3(0.45, 0.15, 0.88)], ["RightHand", Vector3(0.1, -0.75, 0.65)]],   # chūdan: eller göbek önünde ortada, ışın öne-yukarı (sol el IK ile kabzada)
	"w_samehada": [["RightUpperArm", Vector3(-0.5, -0.8, 0.3)], ["RightLowerArm", Vector3(0.2, 0.3, 0.93)], ["RightHand", Vector3(0.6, 0.55, 0.6)]],   # omuzda: ön izlemede beğenilen poz, biraz sağ omza çevrik (kafadan geçmez)
	"w_fan": [["RightUpperArm", Vector3(-0.85, -0.45, 0.25)], ["RightLowerArm", Vector3(-0.5, 0.3, 0.8)]],
	"w_shibuki": [["RightUpperArm", Vector3(-0.05, -0.8, 0.55)], ["RightLowerArm", Vector3(0.55, -0.1, 0.83)], ["RightHand", Vector3(0.053, -0.875, -0.48)]],   # Shibuki (ornek3): iki elle uzun saptan, sağ el karın önünde, rulo önde-solda hafif aşağıda, kâğıt yukarı
	"w_kusa": [["RightUpperArm", Vector3(-0.22, -0.88, 0.42)], ["RightLowerArm", Vector3(0.2, -0.35, 0.92)], ["RightHand", Vector3(0.1, -0.75, 0.65)]],   # Kusanagi: tek el, kılıç önde aşağı-ileri (Orochimaru gevşek duruş)
	"w_ruzgar": [["RightUpperArm", Vector3(-0.2, -0.8, 0.55)], ["RightLowerArm", Vector3(0.0, -0.1, 1.0)], ["RightHand", Vector3(-0.447, -0.894, 0.0)]],   # Rüzgar bıçağı: düz tutuş, bıçak ileri (ruzgarchakrabicagi.png)
	"w_kabuto": [["RightUpperArm", Vector3(-0.3, -0.9, 0.3)], ["RightLowerArm", Vector3(-0.05, -0.45, 0.9)], ["RightHand", Vector3(-0.333, -0.667, -0.667)], ["LeftUpperArm", Vector3(0.75, -0.25, 0.6)], ["LeftLowerArm", Vector3(-0.15, 0.95, 0.2)], ["LeftHand", Vector3(0.894, 0.0, -0.447)]],   # Kabutowari: balta sağda alçak-önde, çekiç sol omuzda (kabuto4)
	"w_kgama": [["RightUpperArm", Vector3(-0.25, -0.9, 0.35)], ["RightLowerArm", Vector3(0.15, -0.1, 0.98)], ["RightHand", Vector3(0.0, 0.0, 1.0)], ["LeftUpperArm", Vector3(0.25, -0.85, 0.45)], ["LeftLowerArm", Vector3(-0.3, -0.25, 0.92)]],   # Hanzō kusarigaması: tek el, sap önde yukarı, zincir dipten sarkar
	"w_tirpan": [["RightUpperArm", Vector3(-0.3, -0.85, 0.42)], ["RightLowerArm", Vector3(0.25, 0.55, 0.8)], ["RightHand", Vector3(0.98, 0.14, -0.14)]],   # tırpan omuzda: yumruk göğüs önünde, sap sağ omzun üstünden geriye, bıçaklar sırtın arkasında
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
		"charge": {"_Charge": 1},
		"plant": {"_Plant": 1},
		"cast": {"_Cast": 1},
		# silah duruşları (bekleme/koşu): ters tutuş kunai, iki elle kılıç, omuzda ağır silah, çift bıçak alçak, yelpaze yanda
		"w_blade": {}, "w_raijin": {}, "w_gunbai": {}, "w_sword": {}, "w_shoulder": {}, "w_kubi": {}, "w_samehada": {}, "w_dual": {}, "w_fan": {}, "w_tirpan": {}, "w_shibuki": {}, "w_kabuto": {}, "w_ruzgar": {}, "w_kusa": {}, "w_kgama": {},
	}


func set_pose(name: String, w: float) -> void:
	targets[name] = w


## Ağırlığı beklemeden ayarla (koşudan ani vuruşa geçerken kollar geride kalmasın)
func snap(name: String, w: float) -> void:
	targets[name] = w
	weights[name] = w


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
		# Naruto koşusu: omuzlar geriye çekilir, kollar dirsekten kırılmadan dümdüz geride, avuçlar açık;
		# kol gövdenin/kalçanın arkasında kaybolmasın diye neredeyse yatay tutulur (boyu tam görünür)
		_rot_model(sk, "LeftShoulder", Vector3(0.88, 0.08, -0.46), w_run)
		_rot_model(sk, "RightShoulder", Vector3(-0.88, 0.08, -0.46), w_run)
		_rot_model(sk, "LeftUpperArm", Vector3(0.2, -0.3, -0.93), w_run)
		_rot_model(sk, "RightUpperArm", Vector3(-0.2, -0.3, -0.93), w_run)
		_rot_model(sk, "LeftLowerArm", Vector3(0.2, -0.2, -0.96), w_run)
		_rot_model(sk, "RightLowerArm", Vector3(-0.2, -0.2, -0.96), w_run)
		_flat_hand(sk, "Left", Vector3(0.2, -0.16, -0.97), w_run)
		_flat_hand(sk, "Right", Vector3(-0.2, -0.16, -0.97), w_run)
		_add_local(sk, "Spine", Vector3(deg_to_rad(16), 0, 0), w_run)
		_add_local(sk, "Neck", Vector3(deg_to_rad(-14), 0, 0), w_run)
	_t += dt
	var w_charge: float = weights.get("charge", 0.0)
	if w_charge > 0.0:
		_charge_pose(sk, w_charge)
	var w_leap: float = weights.get("leap", 0.0)
	if w_leap > 0.0:
		_glide_pose(sk, w_leap)
	if tuck > 0.0:
		_tuck_pose(sk, tuck)
	var w_plant: float = weights.get("plant", 0.0)
	if w_plant > 0.0:
		_plant_pose(sk, w_plant)
	# silah duruşları (mühür/blok/tekme sonra gelir ve bunları ezer)
	for st in STANCE:
		var ws: float = weights.get(st, 0.0)
		if ws > 0.0:
			# nefes: silahın ağırlığıyla kollar hafifçe iner-kalkar, göğüs şişer (bekleme canlı dursun)
			var br = sin(_t * 2.1) * (0.035 + 0.035 * key_mass)
			for e in STANCE[st]:
				var d: Vector3 = e[1]
				if String(e[0]).ends_with("Arm"):
					d = Basis(Vector3.RIGHT, br) * d
				_rot_model(sk, e[0], d, ws)
			_add_local(sk, "Chest", Vector3(-br * 0.6, 0, 0), ws)
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
	if hit_t < 0.7:
		hit_t += dt
		_hit_pose(sk)
	# yaş oranları (kemik ölçeği çocuk kemiklere de geçer: saç/bant kafayla büyür)
	if head_scale != 1.0:
		var hb = sk.find_bone("Head")
		if hb >= 0:
			sk.set_bone_pose_scale(hb, Vector3.ONE * head_scale / chest_scale)
	if key_t >= 0.0 and not key_anim.is_empty():
		_apply_keys(sk, dt)
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
	for bb in bulk.keys():
		var bi2 = sk.find_bone(String(bb))
		var sv = float(bulk[bb])
		if bi2 >= 0 and absf(sv - 1.0) > 0.001:
			sk.set_bone_pose_scale(bi2, Vector3(sv, 1.0, sv))
			var hand_b = String(bb).replace("UpperArm", "Hand").replace("UpperLeg", "Foot")
			var hi2 = sk.find_bone(hand_b)
			if hi2 >= 0 and hand_b != String(bb):
				sk.set_bone_pose_scale(hi2, Vector3(1.0 / sv, 1.0, 1.0 / sv))   # el kaslı kolla şişmez
	for hb in hide.keys():
		var hi3 = sk.find_bone(String(hb))
		if hi3 >= 0:
			sk.set_bone_pose_scale(hi3, Vector3.ONE * 0.001)
	if chest_scale != 1.0:
		var cb = sk.find_bone("UpperChest")
		if cb >= 0:
			sk.set_bone_pose_scale(cb, Vector3(chest_scale, 1.0, chest_scale))
	_root_motion(sk, dt)
	_foot_ik(sk)


## Darbe pozu: hızlı savrulma (0.06 sn), ardından sönen yaylanma. Önden vuruşta gövde geriye, kafa daha çok;
## yandan vuruşta yana bükülür; kollar savrulur. hit_head: kafa ağırlıklı (yüze vuruş)
func _hit_pose(sk: Skeleton3D) -> void:
	var t = hit_t
	var e = (t / 0.06) if t < 0.06 else exp(-(t - 0.06) * 7.0) * cos((t - 0.06) * 13.0)
	e *= hit_amp
	if absf(e) < 0.002:
		return
	var pitch = hit_dir.z * e     # +: öne itildi (arkadan vuruş) -> öne eğil
	var roll = -hit_dir.x * e
	var hk = 1.6 if hit_head else 1.0
	_add_local(sk, "Spine", Vector3(pitch * 0.32, 0.0, roll * 0.28), 1.0)
	_add_local(sk, "Chest", Vector3(pitch * 0.26, hit_side * e * 0.12, roll * 0.22), 1.0)
	_add_local(sk, "Neck", Vector3(pitch * 0.3 * hk, 0.0, roll * 0.25 * hk), 1.0)
	_add_local(sk, "Head", Vector3(pitch * 0.35 * hk, hit_side * e * 0.18 * hk, roll * 0.3 * hk), 1.0)
	# kollar savrulur (gövdeden geride kalır)
	_add_local(sk, "LeftUpperArm", Vector3(-pitch * 0.5, 0.0, e * 0.35), 1.0)
	_add_local(sk, "RightUpperArm", Vector3(-pitch * 0.5, 0.0, -e * 0.35), 1.0)
	_add_local(sk, "LeftLowerArm", Vector3(0.0, 0.0, e * 0.3), 1.0)
	_add_local(sk, "RightLowerArm", Vector3(0.0, 0.0, -e * 0.3), 1.0)
	if hit_up > 0.0:   # havaya fırlatıldı: gövde geriye kavis, baş geri, kollar yukarı savrulur
		var u = e * hit_up
		_add_local(sk, "Spine", Vector3(-u * 0.35, 0, 0), 1.0)
		_add_local(sk, "Chest", Vector3(-u * 0.3, 0, 0), 1.0)
		_add_local(sk, "Head", Vector3(-u * 0.4, 0, 0), 1.0)
		_add_local(sk, "LeftUpperArm", Vector3(0, 0, u * 0.6), 1.0)
		_add_local(sk, "RightUpperArm", Vector3(0, 0, -u * 0.6), 1.0)
	if hit_heavy > 0.0:   # ağır darbe: dizler çöker, kalça düşer, gövde katlanır
		var hv = maxf(0.0, e) * hit_heavy
		var hb = sk.find_bone("Hips")
		if hb >= 0:
			sk.set_bone_pose_position(hb, sk.get_bone_pose_position(hb) + Vector3(0, -0.12 * hv, 0))
		for side in [["Left", 1.0], ["Right", -1.0]]:
			_rot_model(sk, side[0] + "UpperLeg", Vector3(0.12 * side[1], -0.6, 0.79), hv * 0.6)
			_rot_model(sk, side[0] + "LowerLeg", Vector3(0.0, -0.85, -0.52), hv * 0.6)
		_add_local(sk, "Spine", Vector3(hv * 0.3, 0, 0), 1.0)


## El ve parmaklar verilen yönde dümdüz (yumruk değil, açık avuç)
func _flat_hand(sk: Skeleton3D, side: String, dir: Vector3, w: float) -> void:
	_rot_model(sk, side + "Hand", dir, w)
	for f in FINGERS:
		for seg in FINGER_SEG:
			_rot_model(sk, side + f + seg, dir, w)


## Striker süper zıplama şarjı: geniş, derin çömelme; gövde öne, baş ileri bakar, kollar kalçanın arkasına savrulmuş.
## Şarj doldukça daha da alçalır ve hafifçe titrer (yay gibi gerilmiş).
func _charge_pose(sk: Skeleton3D, w: float) -> void:
	var k = clampf(charge_k, 0.0, 1.0)
	var d = (0.55 + 0.45 * k) * w
	var tremble = sin(_t * 55.0) * 0.012 * k * k * w
	var hb = sk.find_bone("Hips")
	if hb >= 0:
		sk.set_bone_pose_position(hb, sk.get_bone_pose_position(hb) + Vector3(tremble, -0.34 * d, -0.06 * d))
	_add_local(sk, "Hips", Vector3(deg_to_rad(12), 0, 0), d)
	for side in [["Left", 1.0], ["Right", -1.0]]:
		var sx: float = side[1]
		# sol ayak bir adım önde, sağ geride (koşucu çıkışı)
		var fwd = 0.95 if sx > 0.0 else 0.6
		_rot_model(sk, side[0] + "UpperLeg", Vector3(0.32 * sx, -0.42, fwd), d)
		_rot_model(sk, side[0] + "LowerLeg", Vector3(0.05 * sx, -0.92, -0.38 if sx > 0.0 else -0.62), d)
		_rot_model(sk, side[0] + "Foot", Vector3(0.0, -0.4, 0.92), d)
	_add_local(sk, "Spine", Vector3(deg_to_rad(28), 0, 0), d)
	_add_local(sk, "Chest", Vector3(deg_to_rad(16), 0, 0), d)
	_add_local(sk, "Neck", Vector3(deg_to_rad(-26), 0, 0), d)
	_add_local(sk, "Head", Vector3(deg_to_rad(-12), 0, 0), d)
	# kollar geride ve aşağıda, hafif dışa açık; dirsek hafif kırık
	_rot_model(sk, "LeftUpperArm", Vector3(0.35, -0.5, -0.79), d)
	_rot_model(sk, "RightUpperArm", Vector3(-0.35, -0.5, -0.79), d)
	_rot_model(sk, "LeftLowerArm", Vector3(0.3, -0.4, -0.87), d)
	_rot_model(sk, "RightLowerArm", Vector3(-0.3, -0.4, -0.87), d)
	_flat_hand(sk, "Left", Vector3(0.28, -0.4, -0.87), d)
	_flat_hand(sk, "Right", Vector3(-0.28, -0.4, -0.87), d)


## Süper zıplamada süzülme: gövde öne yatık, kollar yanlara açık ve hafif geride (kanat gibi), bacaklar geride
## süzülür; rüzgârda hafif dalgalanır. glide_land ile inişe hazırlanır (dizler öne, kollar öne-yana dengede).
func _glide_pose(sk: Skeleton3D, w: float) -> void:
	var l = clampf(glide_land, 0.0, 1.0)
	var g = w * (1.0 - l)
	var wob = sin(_t * 3.1) * 0.06
	var wob2 = sin(_t * 4.3 + 1.0) * 0.05
	if g > 0.0:
		_add_local(sk, "Spine", Vector3(deg_to_rad(18), 0, 0), g)
		_add_local(sk, "Chest", Vector3(deg_to_rad(8), 0, 0), g)
		_add_local(sk, "Neck", Vector3(deg_to_rad(-22), 0, 0), g)
		_rot_model(sk, "LeftUpperArm", Vector3(0.78, -0.15 + wob, -0.6), g)
		_rot_model(sk, "RightUpperArm", Vector3(-0.78, -0.15 - wob, -0.6), g)
		_rot_model(sk, "LeftLowerArm", Vector3(0.7, -0.25 + wob2, -0.67), g)
		_rot_model(sk, "RightLowerArm", Vector3(-0.7, -0.25 - wob2, -0.67), g)
		_flat_hand(sk, "Left", Vector3(0.62, -0.32, -0.72), g)
		_flat_hand(sk, "Right", Vector3(-0.62, -0.32, -0.72), g)
		_rot_model(sk, "LeftUpperLeg", Vector3(0.12, -0.8, -0.58 + wob), g)
		_rot_model(sk, "RightUpperLeg", Vector3(-0.1, -0.97, 0.12 - wob), g)
		_rot_model(sk, "LeftLowerLeg", Vector3(0.05, -0.72, -0.69), g)
		_rot_model(sk, "RightLowerLeg", Vector3(-0.03, -0.75, -0.66), g)
		_rot_model(sk, "LeftFoot", Vector3(0.0, -0.85, -0.5), g)
		_rot_model(sk, "RightFoot", Vector3(0.0, -0.8, -0.2), g)
	var lw = w * l
	if lw > 0.0:
		# iniş hazırlığı: dizler yukarı/öne, gövde dik, kollar yanlarda öne açık
		_add_local(sk, "Spine", Vector3(deg_to_rad(10), 0, 0), lw)
		_rot_model(sk, "LeftUpperArm", Vector3(0.75, -0.35, 0.55), lw)
		_rot_model(sk, "RightUpperArm", Vector3(-0.75, -0.35, 0.55), lw)
		_rot_model(sk, "LeftLowerArm", Vector3(0.55, -0.15, 0.82), lw)
		_rot_model(sk, "RightLowerArm", Vector3(-0.55, -0.15, 0.82), lw)
		_rot_model(sk, "LeftUpperLeg", Vector3(0.2, -0.55, 0.81), lw)
		_rot_model(sk, "RightUpperLeg", Vector3(-0.15, -0.8, 0.45), lw)
		_rot_model(sk, "LeftLowerLeg", Vector3(0.05, -0.98, -0.1), lw)
		_rot_model(sk, "RightLowerLeg", Vector3(-0.03, -0.95, -0.3), lw)
		_rot_model(sk, "LeftFoot", Vector3(0.0, -0.3, 0.95), lw)
		_rot_model(sk, "RightFoot", Vector3(0.0, -0.3, 0.95), lw)


## Takla: top gibi toplanma; dizler göğse çekilir, baldırlar katlanır, kollar dizleri sarar, baş öne eğik
func _tuck_pose(sk: Skeleton3D, w: float) -> void:
	_add_local(sk, "Spine", Vector3(deg_to_rad(28), 0, 0), w)
	_add_local(sk, "Chest", Vector3(deg_to_rad(16), 0, 0), w)
	_add_local(sk, "Neck", Vector3(deg_to_rad(18), 0, 0), w)
	for side in [["Left", 1.0], ["Right", -1.0]]:
		var sx: float = side[1]
		_rot_model(sk, side[0] + "UpperLeg", Vector3(0.16 * sx, 0.3, 0.94), w)
		_rot_model(sk, side[0] + "LowerLeg", Vector3(0.05 * sx, -0.96, -0.28), w)
		_rot_model(sk, side[0] + "Foot", Vector3(0.0, -0.55, -0.83), w)
		_rot_model(sk, side[0] + "UpperArm", Vector3(0.3 * sx, -0.55, 0.78), w)
		_rot_model(sk, side[0] + "LowerArm", Vector3(-0.3 * sx, -0.8, 0.52), w)


## Chakra doldurma duruşu: ayaklar omuz genişliğinden açık, dizler hafif kırık, kalça biraz alçak (eller mühürde)
func _plant_pose(sk: Skeleton3D, w: float) -> void:
	var hb = sk.find_bone("Hips")
	if hb >= 0:
		sk.set_bone_pose_position(hb, sk.get_bone_pose_position(hb) + Vector3(0, -0.09 * w, 0))
	for side in [["Left", 1.0], ["Right", -1.0]]:
		var sx: float = side[1]
		_rot_model(sk, side[0] + "UpperLeg", Vector3(0.3 * sx, -0.93, 0.2), w)
		_rot_model(sk, side[0] + "LowerLeg", Vector3(0.14 * sx, -0.97, -0.2), w)
		_rot_model(sk, side[0] + "Foot", Vector3(0.15 * sx, -0.3, 0.94), w)
	_add_local(sk, "Spine", Vector3(deg_to_rad(6), 0, 0), w)
	_add_local(sk, "Neck", Vector3(deg_to_rad(-6), 0, 0), w)


## Jutsu pozu: gövde, kollar (sırayla), parmaklar
func play_keys(step: Dictionary, spd := 1.0) -> void:
	_key_chain = key_t >= 0.0   # önceki vuruş sürerken geldiyse boş duruşa dönmeden akarak devam
	_key_out = 0.0
	key_anim = step
	key_t = 0.0
	key_spd = spd


## Kombo bitince çağrılır: son poz 0.18 sn'de yumuşakça alttaki animasyona bırakılır
func stop_keys() -> void:
	if key_t >= 0.0 and _key_out <= 0.0:
		_key_out = 0.18


func _end_keys() -> void:
	key_t = -1.0
	_key_out = 0.0
	key_blade = Vector3.ZERO
	_key_bv = Vector3.ZERO
	_key_prev = Vector3.ZERO
	_lsm.clear()


var _key_out := 0.0


var _key_chain := false
var key_weapon_cb: Callable   # CharacterModel._key_blade_sk: silah yönü iskelet güncellemesi içinde
var _key_hold := 0.0
var _lsm := {}   # boştaki kolun yumuşatılmış yönleri
var _key_bv := Vector3.ZERO      # kılıç ucunun yumuşatılmış açısal hızı (gövde tepkisi için)
var _key_prev := Vector3.ZERO


## Küre üzerinde yön geçişi (sabit açısal hız)
static func _sl(a: Vector3, b: Vector3, u: float) -> Vector3:
	var an = a.normalized()
	var bn = b.normalized()
	if an.dot(bn) < -0.995:
		bn = (bn + Vector3(0.0, 0.08, 0.0)).normalized()   # tam ters yönde belirsiz yay: üstten geç
	return an.slerp(bn, u)


static func _cr(a, b, c, d, u: float):
	# Catmull-Rom: anahtarların içinden kesintisiz hızla geçer (her anahtarda durup kalkmaz)
	return 0.5 * ((b * 2.0) + (c - a) * u + (a * 2.0 - b * 5.0 + c * 4.0 - d) * u * u + (b * 3.0 - a - c * 3.0 + d) * u * u * u)


## Anahtar karelerden akıcı animasyon + gövdenin kılıca tepkisi (burulma, öne yüklenme)
func _apply_keys(sk: Skeleton3D, dt: float) -> void:
	var ln: float = key_anim["len"]
	# son pozda bekler (sıradaki vuruş gelene ya da kombo bitene kadar); boş duruşa dönüp zıplamaz
	key_t = minf(key_t + dt * key_spd * time_comp, ln)
	_key_hold = _key_hold + dt if key_t >= ln else 0.0
	if _key_hold > 0.7 and _key_out <= 0.0:
		_key_out = 0.18   # güvenlik: kombo sistemi bırakmadıysa (vurulma vb.) kendiliğinden bırak
	var w_out = 1.0
	if _key_out > 0.0:
		_key_out -= dt
		if _key_out <= 0.0:
			_end_keys()
			return
		w_out = _key_out / 0.18
	var keys: Array = key_anim["keys"]
	var n = keys.size()
	var i = 0
	while i < n - 1 and keys[i + 1]["t"] <= key_t:
		i += 1
	var k0: Dictionary = keys[maxi(i - 1, 0)]
	var k1: Dictionary = keys[i]
	var k2: Dictionary = keys[mini(i + 1, n - 1)]
	var k3: Dictionary = keys[mini(i + 2, n - 1)]
	var u = 0.0 if k2["t"] <= k1["t"] else clampf((key_t - k1["t"]) / (k2["t"] - k1["t"]), 0.0, 1.0)
	var cp = {}
	for nm in ["crouch", "hips_yaw", "spine", "neck"]:
		cp[nm] = _cr(float(k0.get(nm, 0.0)), float(k1.get(nm, 0.0)), float(k2.get(nm, 0.0)), float(k3.get(nm, 0.0)), u)
	cp["crouch"] = clampf(cp["crouch"], 0.0, 1.0)
	var raw_yaw: float = cp["hips_yaw"]
	cp["hips_yaw"] = wrapf(raw_yaw, -180.0, 180.0)   # tam tur dönüş: sayısal yol dönüşü verir, uygulanan açı sarılır
	# dönüş (|yaw| > 60): kollar, bacaklar ve kılıç gövdeyle birlikte döner (yönler gövdeye göre tarif edildi)
	var spin = Basis(Vector3.UP, deg_to_rad(raw_yaw)) if absf(raw_yaw) > 60.0 else Basis.IDENTITY
	var blade: Vector3 = spin * _sl(k1["blade"], k2["blade"], u)
	# gövde tepkisi: kılıç ucunun hızına göre öne yüklenme / geriye esneme ve savuruş yönüne burulma
	if dt > 0.0 and _key_prev != Vector3.ZERO:
		_key_bv = _key_bv.lerp((blade - _key_prev) / dt, clampf(dt * 12.0, 0.0, 1.0))
	_key_prev = blade
	var lean_add = clampf(-_key_bv.y * 4.0, -10.0, 16.0)
	var twist = clampf(blade.x * 22.0 + _key_bv.x * 5.0, -35.0, 35.0)
	cp["twist"] = twist
	cp["spine"] = cp["spine"] + lean_add
	cp["neck"] = cp["neck"] - lean_add * 0.6
	cp["roll"] = clampf(-blade.x * 10.0 - _key_bv.x * 2.0, -14.0, 14.0)   # yana savuruşta gövde o yana yatar
	var lean_b = Basis.IDENTITY
	var arms = []
	var b0: Dictionary = k0["b"]
	var b1: Dictionary = k1["b"]
	var b2: Dictionary = k2["b"]
	var b3: Dictionary = k3["b"]
	for bone in b1:
		var d: Vector3 = spin * _sl(b1[bone], b2.get(bone, b1[bone]), u)
		if bone == "LeftUpperArm" or bone == "LeftLowerArm":
			# boştaki kol: yeni pozuna gecikmeli, yumuşak gider (her anahtarda sıçrayıp random görünmesin)
			if _lsm.has(bone) and _key_chain or (_lsm.has(bone) and key_t > 0.02):
				d = (_lsm[bone] as Vector3).slerp(d.normalized(), clampf(dt * 7.0, 0.0, 1.0))
			_lsm[bone] = d
		if bone == "Spine" or bone == "Chest":
			d = lean_b * d
		if bone.ends_with("UpperLeg") or bone.ends_with("LowerLeg"):
			# adım: bu iki anahtar arasında ayak yer değiştiriyorsa (üst bacak yönü çok değişiyor) ayak kaymaz —
			# diz kalkar, ayak havadan geçip basar (tüm silah animasyonları)
			var side_pre = "Left" if bone.begins_with("Left") else "Right"
			var ul = side_pre + "UpperLeg"
			var ua: Vector3 = b1.get(ul, Vector3.ZERO)
			var ue: Vector3 = b2.get(ul, Vector3.ZERO)
			if ua != Vector3.ZERO and ue != Vector3.ZERO:
				var move = ua.normalized().distance_to(ue.normalized())
				if move > 0.35:
					var lift = sin(u * PI) * clampf((move - 0.35) * 1.4, 0.0, 0.6)
					if bone.ends_with("UpperLeg"):
						d = (d.normalized() + Vector3(0, 0.55, 0.45) * lift).normalized()
					else:
						d = (d.normalized() + Vector3(0, 0.1, -0.75) * lift).normalized()
		arms.append([bone, d])
	# silah ağırlığı: kollar ve silah ucu yaylı izler — ağır silahta gecikip hedefi aşar, sonra oturur; hafifte keskin
	var om = lerpf(36.0, 13.0, key_mass)
	var ze = lerpf(0.95, 0.5, key_mass)
	if not _key_chain and key_t < 0.03:
		_spr.clear()
	for a in arms:
		if String(a[0]).ends_with("Arm") and dt > 0.0:
			a[1] = _spring(a[0], a[1], om, ze, dt)
	if dt > 0.0:
		blade = _spring("_blade", blade, om, ze, dt).normalized()
	cp["arms"] = arms
	key_blade = blade
	key_roll = _cr(float(k0.get("roll", 0.0)), float(k1.get("roll", 0.0)), float(k2.get("roll", 0.0)), float(k3.get("roll", 0.0)), u)
	var w_in = 1.0 if _key_chain else clampf(key_t / 0.08, 0.0, 1.0)
	var w = w_in * w_out
	_apply_cast(sk, w, cp)
	_key_feet(sk, w, cp, raw_yaw, dt)
	if key_weapon_cb.is_valid():
		key_weapon_cb.call(sk, blade)


var _spr := {}   # kemik -> [konum, hız] (yön yayı)
func _spring(key: String, target: Vector3, om: float, ze: float, dt: float) -> Vector3:
	if not _spr.has(key):
		_spr[key] = [target, Vector3.ZERO]
		return target
	var st: Array = _spr[key]
	var x: Vector3 = st[0]
	var v: Vector3 = st[1]
	var steps = maxi(1, int(ceil(dt / 0.008)))
	var h = dt / steps
	for i in steps:
		var acc = (target - x) * om * om - v * 2.0 * ze * om
		v += acc * h
		x += v * h
	st[0] = x
	st[1] = v
	return x if x.length() > 0.001 else target


## Ayaklar gövdeyi izler (tüm anahtar animasyonlar): gövde döndükçe ayaklar kısmen döner (topuk üstünde pivot), öne yüklenince
## arka topuk kalkar (ayak ucuna basar), geriye yaslanınca ön ayak ucu kalkar; vuruş anında (silah ucu hızlıyken) kalça çöker,
## sonra yaylanır — bacaklar kalas gibi sabit kalmasın
var _key_bob := 0.0
func _key_feet(sk: Skeleton3D, w: float, cp: Dictionary, yaw: float, dt: float) -> void:
	if w <= 0.0:
		return
	var lean: float = float(cp.get("spine", 0.0))
	var pivot = deg_to_rad(clampf(yaw, -70.0, 70.0)) * 0.35
	for side in ["Left", "Right"]:
		var fb = sk.find_bone(side + "Foot")
		var ub = sk.find_bone(side + "UpperLeg")
		if fb < 0 or ub < 0:
			continue
		var fdir: Vector3 = sk.get_bone_global_pose(fb).basis.y.normalized()
		# ayak ileri mi geride mi: kalçadan ayak bileğine yatay z
		var back = sk.get_bone_global_pose(fb).origin.z < sk.get_bone_global_pose(ub).origin.z - 0.05
		var d = Basis(Vector3.UP, pivot) * fdir
		if back and lean > 8.0:
			d = Basis(Vector3.RIGHT, deg_to_rad(clampf((lean - 8.0) * 1.1, 0.0, 34.0))) * d   # arka topuk kalkar
		elif not back and lean < -6.0:
			d = Basis(Vector3.RIGHT, -deg_to_rad(clampf((-lean - 6.0) * 0.9, 0.0, 22.0))) * d   # ön ayak ucu kalkar
		_rot_model(sk, side + "Foot", d, w)
	# vuruş çökmesi: silah ucu hızı yüksekken kalça kısa süre alçalır, sonra yaylanır
	var spd = _key_bv.length()
	_key_bob = lerpf(_key_bob, clampf((spd - 4.0) * 0.012, 0.0, 0.07), clampf(dt * (14.0 if spd > 4.0 else 5.0), 0.0, 1.0))
	if _key_bob > 0.001:
		var hb = sk.find_bone("Hips")
		if hb >= 0:
			sk.set_bone_pose_position(hb, sk.get_bone_pose_position(hb) + Vector3(0, -_key_bob * w, 0))


func _apply_cast(sk: Skeleton3D, w: float, cp_in := {}) -> void:
	var cp = cp_in if not cp_in.is_empty() else cast_pose
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
		var sp = deg_to_rad(cp["spine"])
		if cp.has("roll"):
			# anahtar animasyon: eğimin bir kısmı kalçadan (pelvis öne devrilir), kalanı bel/göğüs; yana yatma bel/göğüste
			var rl = deg_to_rad(cp["roll"])
			_add_local(sk, "Hips", Vector3(sp * 0.25, 0, 0), w)
			_add_local(sk, "Spine", Vector3(sp * 0.4, 0, rl * 0.5), w)
			_add_local(sk, "Chest", Vector3(sp * 0.35, 0, rl * 0.5), w)
		else:
			_add_local(sk, "Spine", Vector3(sp * 0.5, 0, 0), w)
			_add_local(sk, "Chest", Vector3(sp * 0.5, 0, 0), w)
	if cp.get("neck", 0.0) != 0.0:
		_add_local(sk, "Neck", Vector3(deg_to_rad(cp["neck"]), 0, 0), w)
	if cp.get("twist", 0.0) != 0.0:
		# omuzlar savuruş yönüne burulur (yön kemikleri bunu korur)
		_add_local(sk, "Spine", Vector3(0, deg_to_rad(cp["twist"]) * 0.4, 0), w)
		_add_local(sk, "Chest", Vector3(0, deg_to_rad(cp["twist"]) * 0.6, 0), w)
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


# ------------------------------------------------------------------ adımla ilerleme (root motion)
## Anahtar animasyonda yere basan ayak (alçaktaki, kalkık olmayan) yerinde kalsın: o ayağın model uzayındaki kayması kadar
## gövde ters yönde ilerler -> root_vel (dünya, yatay). Saldırı kodu bunu hıza ekler (ayak kayması biter, adımlar "basar").
var _rm_prev_l := Vector3.INF
var _rm_prev_r := Vector3.INF
func _root_motion(sk: Skeleton3D, dt: float) -> void:
	if key_t < 0.0 or key_anim.is_empty() or dt <= 0.0:
		root_vel = root_vel.lerp(Vector3.ZERO, clampf(dt * 10.0, 0.0, 1.0))
		_rm_prev_l = Vector3.INF
		return
	var lf = sk.find_bone("LeftFoot")
	var rf = sk.find_bone("RightFoot")
	if lf < 0 or rf < 0:
		return
	var pl = sk.get_bone_global_pose(lf).origin
	var pr = sk.get_bone_global_pose(rf).origin
	if _rm_prev_l != Vector3.INF:
		# yere basan ayak = gövdeye göre GERİYE kayan ayak (adım atan ayak öne gider); beden onun kaydığı kadar ileri gider.
		# Yalnız ileri: saldırırken rakipten asla uzaklaşmaz (havadaki ayağı basan sanıp geri itiyordu)
		var dl = pl - _rm_prev_l
		var dr = pr - _rm_prev_r
		var dm = dl if dl.z < dr.z else dr
		var vm = -dm / dt
		vm.y = 0
		vm.z = maxf(0.0, vm.z)
		vm.x *= 0.5
		var v = sk.global_transform.basis * vm
		v.y = 0
		if v.length() > 5.0:
			v = v.normalized() * 5.0
		root_vel = root_vel.lerp(v, clampf(dt * 18.0, 0.0, 1.0))
	_rm_prev_l = pl
	_rm_prev_r = pr


# ------------------------------------------------------------------ ayak yerleştirme (iki kemik IK)
## Her ayak altındaki zemine (arazi + çarpışma yüzeyi) basar: eğimde, basamakta ayaklar havada kalmaz / gömülmez; aşağıda kalan
## ayak için kalça alçalır. Animasyonun kaldırdığı ayak (adım) yüksekliğini korur. Ayak yönü korunur.
var _ankle_h := -1.0
func _foot_ik(sk: Skeleton3D) -> void:
	if not foot_ik:
		return
	var owner3d = sk.get_parent()
	while owner3d and not (owner3d is CharacterBody3D):
		owner3d = owner3d.get_parent()
	if owner3d == null:
		return
	var gr = owner3d.get("grounded")
	if not (bool(gr) if gr != null else (owner3d as CharacterBody3D).is_on_floor()):
		return   # havada / zıplarken yok (oyuncu/düşman kendi zemin bilgisini tutar)
	var cam = get_viewport().get_camera_3d() if get_viewport() else null
	if cam and cam.global_position.distance_to(owner3d.global_position) > 35.0:
		return   # uzaktakiler için atla (maliyet)
	var gt: Transform3D = sk.global_transform
	if _ankle_h < 0.0:
		var a = sk.find_bone("LeftFoot")
		if a < 0:
			return
		_ankle_h = (gt * sk.get_bone_global_rest(a).origin).y - owner3d.global_position.y
		if _ankle_h <= 0.0 or _ankle_h > 0.4:
			_ankle_h = 0.08
	var root_y: float = owner3d.global_position.y
	var space = owner3d.get_world_3d().direct_space_state
	var targets_ik = {}
	var drop = 0.0
	for side in ["Left", "Right"]:
		var fb = sk.find_bone(side + "Foot")
		if fb < 0:
			return
		var P: Vector3 = gt * sk.get_bone_global_pose(fb).origin
		var lift = maxf(0.0, (P.y - root_y) - _ankle_h)   # animasyonun kaldırdığı yükseklik
		var gy = Game.ground_height(P.x, P.z)
		var hit = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(P.x, root_y + 0.6, P.z), Vector3(P.x, root_y - 0.7, P.z), 1, [owner3d.get_rid()]))
		if not hit.is_empty():
			gy = maxf(gy, float(hit["position"].y)) if absf(float(hit["position"].y) - root_y) < 0.6 else gy
		var dy = clampf(gy - root_y, -0.45, 0.45)
		if absf(dy) < 0.015:
			continue
		targets_ik[side] = [fb, P + Vector3(0, dy + (0.0 if lift > 0.06 else 0.0), 0)]
		drop = minf(drop, dy)
	if targets_ik.is_empty():
		return
	if drop < -0.01:   # alçaktaki ayağa uzanabilmek için kalça iner
		var hb = sk.find_bone("Hips")
		if hb >= 0:
			sk.set_bone_pose_position(hb, sk.get_bone_pose_position(hb) + Vector3(0, drop / maxf(0.01, gt.basis.get_scale().y), 0))
	var inv = gt.affine_inverse()
	for side in targets_ik:
		var fb: int = targets_ik[side][0]
		var keep: Basis = sk.get_bone_global_pose(fb).basis
		_leg_ik(sk, side, inv * (targets_ik[side][1] as Vector3))
		var par = sk.get_bone_parent(fb)
		var pb: Basis = sk.get_bone_global_pose(par).basis if par >= 0 else Basis.IDENTITY
		sk.set_bone_pose_rotation(fb, (pb.inverse() * keep).get_rotation_quaternion())


func _leg_ik(sk: Skeleton3D, side: String, tgt: Vector3) -> void:
	var ub = sk.find_bone(side + "UpperLeg")
	var lb = sk.find_bone(side + "LowerLeg")
	var fb = sk.find_bone(side + "Foot")
	if ub < 0 or lb < 0 or fb < 0:
		return
	var S = sk.get_bone_global_pose(ub).origin
	var E = sk.get_bone_global_pose(lb).origin
	var H = sk.get_bone_global_pose(fb).origin
	var a = S.distance_to(E)
	var b = E.distance_to(H)
	var d = tgt - S
	var dist = clampf(d.length(), 0.05, a + b - 0.002)
	var dn = d.normalized()
	# diz hep öne (hafif dışa) bakar: düz bacakta mevcut diz yönü belirsiz kalıp diz yana açılıyordu
	var pole = Vector3(0.12 if side == "Left" else -0.12, 0.0, 1.0)
	var bent = (E - (S + (H - S) * 0.5))
	if bent.length() > 0.03 and bent.normalized().z > 0.3:
		pole = bent   # animasyon dizi zaten belirgin öne kırmışsa onu koru
	var perp = pole - dn * pole.dot(dn)
	if perp.length() < 0.001:
		perp = Vector3(0, 0, 1)
	perp = perp.normalized()
	var cos_a = clampf((a * a + dist * dist - b * b) / (2.0 * a * dist), -1.0, 1.0)
	var knee = S + (dn * cos_a + perp * sqrt(1.0 - cos_a * cos_a)) * a
	_rot_model(sk, side + "UpperLeg", knee - S, 1.0)
	var E2 = sk.get_bone_global_pose(lb).origin
	_rot_model(sk, side + "LowerLeg", (S + dn * dist) - E2, 1.0)
