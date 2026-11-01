class_name SamehadaAnim
## Kisame Samehada kombosu (kaynak: _tmp/ref_water/kisame.mp4 0:00-0:04, 10 fps kare kare).
## Her adım: süre, vuruş anı ve poz anahtarları. Yönler iskelet uzayında: +Z karakterin önü, +X karakterin solu, +Y yukarı.
## "blade": Samehada'nın uç yönü (silah bu yöne çevrilir); "b": kemik -> yön; crouch/yaw/spine/neck: gövde.

const LEG_WIDE := {"LeftUpperLeg": Vector3(0.22, -1, 0.05), "LeftLowerLeg": Vector3(0.05, -1, 0.0), "LeftFoot": Vector3(0.05, -0.45, 0.9),
	"RightUpperLeg": Vector3(-0.22, -1, 0.05), "RightLowerLeg": Vector3(-0.05, -1, 0.0), "RightFoot": Vector3(-0.05, -0.45, 0.9)}
# sağ ayak önde derin hamle (videoda itiş/vuruş anları)
const LEG_LUNGE := {"RightUpperLeg": Vector3(-0.2, -0.35, 0.92), "RightLowerLeg": Vector3(-0.05, -1, -0.05), "RightFoot": Vector3(-0.05, -0.4, 0.92),
	"LeftUpperLeg": Vector3(0.22, -0.6, -0.77), "LeftLowerLeg": Vector3(0.1, -0.75, -0.65), "LeftFoot": Vector3(0.1, -0.9, 0.4)}


static func _k(t: float, crouch: float, yaw: float, spine: float, blade: Vector3, arms: Dictionary, legs: Dictionary) -> Dictionary:
	# gövde eğimi kemik yönüyle (öne eğilme açısı): bel < göğüs, kafa ileri bakar
	var lean = deg_to_rad(spine)
	var b = {}   # sıra önemli: önce gövde, sonra kollar/bacaklar (gövde dönünce kol yönleri bozulmasın)
	b["Spine"] = Vector3(0, cos(lean * 0.6), sin(lean * 0.6))
	b["Chest"] = Vector3(0, cos(lean), sin(lean))
	b["Neck"] = Vector3(0, cos(lean * 0.5), sin(lean * 0.5))
	b["Head"] = Vector3(0, 1, 0.05)
	b.merge(arms)
	b.merge(legs)
	return {"t": t, "crouch": crouch, "hips_yaw": yaw, "spine": 0.0, "neck": 0.0, "blade": blade, "b": b}


# Pozlar _tmp/ed/kisame_desc.md tarifinden birebir (her tarif karesi bir anahtar; zamanlar video saniyesi).
# Sağ kol: yumruk SAPIN EN UCUNDA (CharacterModel silahı sap boyunca kaydırır). Sol el kılıca hiç dokunmaz.
# Sağ el konumları (sağ omuza göre)
const H_HANG := {"RightUpperArm": Vector3(-0.3, -0.85, -0.45), "RightLowerArm": Vector3(-0.2, -0.75, -0.6)}      # aşağı-geride sarkık
const H_HIP_FRONT := {"RightUpperArm": Vector3(-0.1, -0.95, 0.3), "RightLowerArm": Vector3(0.2, -0.4, 0.9)}     # sağ kalça önü
const H_SHOULDER := {"RightUpperArm": Vector3(-0.15, -0.85, 0.5), "RightLowerArm": Vector3(0.1, 0.75, 0.65)}    # mızrak gibi sağ omuz önü
const H_FWD := {"RightUpperArm": Vector3(-0.05, 0.0, 1), "RightLowerArm": Vector3(0.0, 0.0, 1)}                 # kol ileri uzanmış
const H_SH_BACK := {"RightUpperArm": Vector3(-0.5, -0.8, 0.1), "RightLowerArm": Vector3(-0.1, 0.95, -0.2)}      # sağ omzun sağ-arkası
const H_EAR_BACK := {"RightUpperArm": Vector3(-0.8, 0.3, -0.45), "RightLowerArm": Vector3(0.3, 0.95, 0.1)}      # başın sağ-arkası, kulak hizası
const H_BEHIND := {"RightUpperArm": Vector3(-0.6, -0.3, -0.7), "RightLowerArm": Vector3(0.1, 0.8, -0.55)}       # sağ omzun arkası
const H_BLADE := {"RightUpperArm": Vector3(-0.5, -0.6, -0.6), "RightLowerArm": Vector3(0.2, 0.3, -0.9)}         # kürek kemiği hizası arkada
const H_HIP_SIDE := {"RightUpperArm": Vector3(-0.4, -0.9, -0.1), "RightLowerArm": Vector3(-0.1, -0.95, 0.2)}    # sağ kalça yanı
const H_BELLY := {"RightUpperArm": Vector3(-0.1, -0.85, 0.5), "RightLowerArm": Vector3(0.6, -0.2, 0.75)}        # karın önü
const H_LCHEST := {"RightUpperArm": Vector3(0.2, -0.6, 0.75), "RightLowerArm": Vector3(0.85, 0.4, 0.2)}         # sol göğüs önü
const H_LSHOULDER := {"RightUpperArm": Vector3(0.2, -0.3, 0.93), "RightLowerArm": Vector3(0.9, 0.4, -0.1)}      # sol omuz önü / çene yanı
const H_KNEE := {"RightUpperArm": Vector3(-0.05, -0.85, 0.5), "RightLowerArm": Vector3(0.0, -0.6, 0.8)}         # sağ diz önü
const H_LHIP := {"RightUpperArm": Vector3(0.3, -0.9, 0.3), "RightLowerArm": Vector3(0.8, -0.5, 0.3)}            # sol kalça önü
const H_CHEST := {"RightUpperArm": Vector3(-0.2, -0.4, 0.9), "RightLowerArm": Vector3(0.2, 0.1, 1)}             # göğüs önü, kol yarı açık
const H_ABOVE := {"RightUpperArm": Vector3(-0.4, 0.9, 0.1), "RightLowerArm": Vector3(0.1, 1, 0.05)}             # başın sağ üstü
const H_COCK := {"RightUpperArm": Vector3(-0.8, 0.55, 0.1), "RightLowerArm": Vector3(0.45, 0.85, -0.2)}         # başın arkasına kurulu, dirsek yukarı-yanda
const H_FOREHEAD := {"RightUpperArm": Vector3(-0.05, 0.25, 1), "RightLowerArm": Vector3(0.1, 0.2, 1)}           # alnın önünde, kol öne
const H_SH_UP := {"RightUpperArm": Vector3(-0.6, 0.6, 0.5), "RightLowerArm": Vector3(-0.2, 0.9, 0.4)}           # sağ omuz üstü
const H_SIDE := {"RightUpperArm": Vector3(-1, 0.05, 0.1), "RightLowerArm": Vector3(-0.95, 0.0, 0.3)}            # sağa uzanmış
const H_HIP_LOW := {"RightUpperArm": Vector3(-0.5, -0.85, -0.1), "RightLowerArm": Vector3(-0.2, -0.9, 0.3)}     # sağ kalça alçak
const H_LOW_FRONT := {"RightUpperArm": Vector3(-0.1, -0.8, 0.6), "RightLowerArm": Vector3(0.1, -0.7, 0.7)}      # önde diz hizası
const H_UP := {"RightUpperArm": Vector3(-0.2, 0.98, 0.1), "RightLowerArm": Vector3(-0.05, 1, 0.05)}             # başın üstünde kol dik
# sol kol
const L_FWD := {"LeftUpperArm": Vector3(0.2, 0.0, 1), "LeftLowerArm": Vector3(0.05, 0.0, 1)}          # dümdüz ileri, rakibi gösterir
const L_BENT := {"LeftUpperArm": Vector3(0.35, -0.8, 0.45), "LeftLowerArm": Vector3(-0.1, -0.2, 1)}   # önde dirsek bükük
const L_DOWN := {"LeftUpperArm": Vector3(0.3, -0.9, 0.3), "LeftLowerArm": Vector3(0.1, -0.8, 0.6)}    # gövde önünde aşağı
const L_OVER := {"LeftUpperArm": Vector3(0.05, 0.1, 1), "LeftLowerArm": Vector3(-0.2, -0.1, 1)}       # rakibin üstünden ileri
const L_SIDE := {"LeftUpperArm": Vector3(0.9, -0.35, 0.2), "LeftLowerArm": Vector3(0.8, -0.4, 0.4)}   # sol yana-aşağı açık
const L_BACK := {"LeftUpperArm": Vector3(0.55, -0.55, -0.6), "LeftLowerArm": Vector3(0.3, -0.6, -0.75)}
const L_UP := {"LeftUpperArm": Vector3(0.75, 0.6, 0.25), "LeftLowerArm": Vector3(0.5, 0.8, 0.3)}      # yukarı-sola açık
const L_ACROSS := {"LeftUpperArm": Vector3(-0.2, 0.0, 1), "LeftLowerArm": Vector3(-0.5, 0.0, 0.85)}   # sağa-öne (rakibe) uzanmış


static func _a(r: Dictionary, l: Dictionary) -> Dictionary:
	var d = r.duplicate()
	d.merge(l)
	return d


## vt: video saniyesi, st: adımın video başlangıcı
static func _v(st: float, vt: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return _k(vt - st, crouch, yaw, lean, blade, _a(r, l), legs)


static func steps() -> Array:
	var W = LEG_WIDE
	var L = LEG_LUNGE
	var s1 = 0.55
	var s2 = 1.45
	var s3 = 2.10
	var s4 = 2.45
	var s5 = 2.90
	return [
		# Vuruş 1: atılış, kılıç omuz hizasında yatay ileri saplanır, gövde yere paralel yüklenir (matkap), doğrulur
		{"len": 0.9, "hit": 0.15, "keys": [
			_v(s1, 0.55, 0.45, -10, 35, Vector3(-0.2, -0.35, -0.9), H_HANG, L_BENT, L),
			_v(s1, 0.65, 0.6, 0, 35, Vector3(0.0, -0.35, 0.94), H_HIP_FRONT, L_DOWN, L),
			_v(s1, 0.70, 0.65, 10, 35, Vector3(0.0, 0.0, 1), H_SHOULDER, L_DOWN, L),
			_v(s1, 0.85, 0.7, 10, 40, Vector3(0.0, 0.0, 1), H_SHOULDER, L_DOWN, L),
			_v(s1, 0.90, 0.75, 10, 50, Vector3(0.0, 0.02, 1), H_SHOULDER, L_DOWN, L),
			_v(s1, 1.00, 0.8, 15, 60, Vector3(0.0, 0.0, 1), H_FWD, L_OVER, L),
			_v(s1, 1.30, 0.8, 15, 60, Vector3(0.0, 0.02, 1), H_FWD, L_OVER, L),
			_v(s1, 1.35, 0.7, 10, 40, Vector3(0.0, 0.0, 1), H_SHOULDER, L_DOWN, L),
			_v(s1, 1.45, 0.6, 0, 25, Vector3(0.0, 0.03, 1), H_SH_BACK, L_DOWN, L),
		]},
		# Vuruş 2: dik kaldır (sol kol ileri), arkaya yatır, arkadan kalça hizasında büyük yatay savuruş önden alçak geçer, sol omza çıkar, orada bekler
		{"len": 0.65, "hit": 0.30, "keys": [
			_v(s2, 1.45, 0.6, 0, 25, Vector3(0.0, 0.03, 1), H_SH_BACK, L_DOWN, L),
			_v(s2, 1.50, 0.45, -5, 10, Vector3(0.0, 0.7, 0.7), H_EAR_BACK, L_BENT, L),
			_v(s2, 1.55, 0.4, -5, -5, Vector3(0.0, 1.0, 0.0), H_EAR_BACK, L_FWD, L),
			_v(s2, 1.60, 0.4, -10, 0, Vector3(0.0, 0.9, -0.42), H_BEHIND, L_FWD, L),
			_v(s2, 1.65, 0.45, -20, 8, Vector3(0.0, 0.64, -0.77), H_BLADE, L_FWD, L),
			_v(s2, 1.70, 0.5, -40, 10, Vector3(-0.15, 0.0, -1), H_HIP_SIDE, L_SIDE, L),
			_v(s2, 1.75, 0.6, 0, 20, Vector3(-0.45, -0.35, 0.82), H_BELLY, L_BACK, L),
			_v(s2, 1.80, 0.45, 35, 5, Vector3(0.6, 0.6, -0.5), H_LCHEST, L_SIDE, W),
			_v(s2, 1.85, 0.35, 35, 0, Vector3(0.2, 0.95, -0.25), H_LSHOULDER, L_SIDE, W),
			_v(s2, 1.92, 0.35, 30, 0, Vector3(0.55, 0.1, -0.83), H_LSHOULDER, L_SIDE, W),
			_v(s2, 2.10, 0.35, 30, 0, Vector3(0.55, 0.12, -0.83), H_LSHOULDER, L_SIDE, W),
		]},
		# Vuruş 3: sol omuzdan başın üstünden öne-aşağı, alçaktan sol-arkaya, arkada omuz hizası (sol kol rakibe), göğüs hizasında öne
		{"len": 0.35, "hit": 0.30, "keys": [
			_v(s3, 2.10, 0.35, 30, 0, Vector3(0.55, 0.12, -0.83), H_LSHOULDER, L_SIDE, W),
			_v(s3, 2.15, 0.5, 10, 25, Vector3(0.2, 0.9, 0.4), H_ABOVE, L_SIDE, L),
			_v(s3, 2.20, 0.8, 0, 50, Vector3(0.0, -0.5, 0.87), H_KNEE, L_BACK, L),
			_v(s3, 2.25, 0.75, 30, 40, Vector3(0.6, -0.45, -0.65), H_LHIP, L_UP, L),
			_v(s3, 2.30, 0.7, 25, 30, Vector3(0.15, 0.05, -1), H_LCHEST, L_ACROSS, L),
			_v(s3, 2.35, 0.7, 25, 30, Vector3(0.15, 0.05, -1), H_LCHEST, L_ACROSS, L),
			_v(s3, 2.40, 0.65, 0, 35, Vector3(-0.3, 0.0, 0.95), H_CHEST, L_BACK, L),
			_v(s3, 2.45, 0.45, 0, 15, Vector3(-0.2, 0.64, 0.75), H_SH_UP, L_BENT, L),
		]},
		# Vuruş 4: dik kaldır, başın arkasına yatay kur (sol kol dümdüz ileri), patlayarak baş hizasında öne vur
		{"len": 0.45, "hit": 0.30, "keys": [
			_v(s4, 2.45, 0.45, 0, 15, Vector3(-0.2, 0.64, 0.75), H_SH_UP, L_BENT, L),
			_v(s4, 2.50, 0.3, -10, 0, Vector3(0.0, 1.0, 0.0), H_ABOVE, L_BENT, W),
			_v(s4, 2.55, 0.3, -10, 0, Vector3(0.0, 1.0, 0.0), H_ABOVE, L_FWD, W),
			_v(s4, 2.60, 0.3, -15, -8, Vector3(0.0, 0.2, -0.98), H_COCK, L_FWD, W),
			_v(s4, 2.70, 0.3, -15, -8, Vector3(0.0, 0.22, -0.97), H_COCK, L_FWD, W),
			_v(s4, 2.75, 0.7, 10, 35, Vector3(0.0, 0.05, 1), H_FOREHEAD, L_BACK, L),
			_v(s4, 2.85, 0.75, 10, 40, Vector3(0.0, -0.12, 1), H_FWD, L_BACK, L),
			_v(s4, 2.90, 0.5, 5, 20, Vector3(0.0, 0.4, 0.9), H_SH_UP, L_UP, L),
		]},
		# Vuruş 5: sağ-ön-yukarı, sağa açılıp tam tur dönüş (kılıç sağda, sonra alçakta geride), yerden önden süpür, aşağıdan yukarı fırlat
		{"len": 0.8, "hit": 0.70, "keys": [
			_v(s5, 2.90, 0.5, 5, 20, Vector3(0.0, 0.4, 0.9), H_SH_UP, L_UP, L),
			_v(s5, 2.95, 0.3, 0, 0, Vector3(-0.4, 0.75, 0.5), H_SH_UP, L_UP, W),
			_v(s5, 3.00, 0.3, -30, 0, Vector3(-0.85, 0.1, 0.5), H_SIDE, L_UP, W),
			_v(s5, 3.08, 0.35, -110, 5, Vector3(-1.0, 0.0, 0.1), H_SIDE, L_SIDE, W),
			_v(s5, 3.15, 0.45, -180, 20, Vector3(-0.85, -0.08, -0.5), H_HIP_LOW, L_SIDE, L),
			_v(s5, 3.25, 0.55, -270, 30, Vector3(-0.72, -0.1, -0.68), H_HIP_LOW, L_SIDE, L),
			_v(s5, 3.35, 0.65, -360, 35, Vector3(0.65, -0.15, -0.74), H_LHIP, L_UP, L),
			_v(s5, 3.40, 0.75, -360, 40, Vector3(0.8, -0.2, -0.55), H_LHIP, L_UP, L),
			_v(s5, 3.47, 0.8, -360, 45, Vector3(0.0, -0.6, 0.8), H_LOW_FRONT, L_BACK, L),
			_v(s5, 3.55, 0.75, -360, 40, Vector3(0.0, -0.4, 0.92), H_LOW_FRONT, L_BACK, L),
			_v(s5, 3.60, 0.5, -360, 15, Vector3(0.0, 0.7, 0.7), H_CHEST, L_BACK, L),
			_v(s5, 3.67, 0.3, -360, -5, Vector3(0.0, 1.0, 0.1), H_UP, L_BACK, W),
			_v(s5, 3.70, 0.3, -360, -5, Vector3(0.0, 1.0, 0.1), H_UP, L_BACK, W),
		]},
	]
