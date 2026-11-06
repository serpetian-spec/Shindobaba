extends RefCounted
## Dövüş tarzı — Yotsuki (Raiton nintaijutsu, Raikage A). YAKIN, ÇOK SERT, HIZLI ATILIŞ. Ref: refs/styles/yotsuki_*.png +
## text/yotsuki.txt (Raiton Chakra Modu: bedeni saran şimşek zırhı; Lariat, Raigyaku Suihei, Liger Bomb). Kombo boyunca şimşek zırhı.
## 1 Raiton Choku: şimşekli sağ düz yumruk, 2 Kata Tackle: omuzla dalış, 3 Lariat: sağ kol yana açık dev atılış,
## 4 Raigyaku Suihei: yatay şimşek el kılıcı (boyun), 5 Rairyū Renda: sol-sağ seri şimşek yumruklar,
## 6 Liger Bomb: rakibi kavrayıp havaya kaldırır, yere çakar (yer çatlar, şimşek patlar).

const S = preload("res://scripts/combat/samehada_anim.gd")
const F = preload("res://scripts/combat/style_legs.gd")

const R_GUARD := {"RightUpperArm": Vector3(-0.35, -0.75, 0.55), "RightLowerArm": Vector3(0.1, 0.7, 0.7)}
const L_GUARD := {"LeftUpperArm": Vector3(0.35, -0.75, 0.55), "LeftLowerArm": Vector3(-0.1, 0.7, 0.7)}
const R_CHAMBER := {"RightUpperArm": Vector3(-0.4, -0.65, -0.65), "RightLowerArm": Vector3(-0.1, 0.35, 0.93)}
const R_PUNCH := {"RightUpperArm": Vector3(-0.05, 0.05, 1), "RightLowerArm": Vector3(0.0, 0.05, 1)}
const L_PUNCH := {"LeftUpperArm": Vector3(0.05, 0.05, 1), "LeftLowerArm": Vector3(0.0, 0.05, 1)}
const L_CHAMBER := {"LeftUpperArm": Vector3(0.4, -0.65, -0.65), "LeftLowerArm": Vector3(0.1, 0.35, 0.93)}
const R_TUCK := {"RightUpperArm": Vector3(-0.2, -0.6, 0.78), "RightLowerArm": Vector3(0.6, 0.6, 0.5)}     # omuz dalışı: kol gövdeye
const L_TUCK := {"LeftUpperArm": Vector3(0.2, -0.6, 0.78), "LeftLowerArm": Vector3(-0.6, 0.6, 0.5)}
const R_LARIAT := {"RightUpperArm": Vector3(-0.95, 0.1, 0.3), "RightLowerArm": Vector3(-0.92, 0.1, 0.38)}   # kol yana dümdüz açık
const R_CHOP0 := {"RightUpperArm": Vector3(-0.9, 0.3, -0.3), "RightLowerArm": Vector3(-0.5, 0.4, 0.75)}
const R_CHOP1 := {"RightUpperArm": Vector3(0.3, 0.1, 0.95), "RightLowerArm": Vector3(0.85, 0.1, 0.5)}
const R_GRAB := {"RightUpperArm": Vector3(-0.15, 0.2, 0.97), "RightLowerArm": Vector3(0.2, 0.4, 0.9)}
const L_GRAB := {"LeftUpperArm": Vector3(0.15, 0.2, 0.97), "LeftLowerArm": Vector3(-0.2, 0.4, 0.9)}
const R_LIFT := {"RightUpperArm": Vector3(-0.2, 0.95, 0.2), "RightLowerArm": Vector3(0.1, 0.95, 0.3)}
const L_LIFT := {"LeftUpperArm": Vector3(0.2, 0.95, 0.2), "LeftLowerArm": Vector3(-0.1, 0.95, 0.3)}
const R_SLAM := {"RightUpperArm": Vector3(-0.1, -0.45, 0.89), "RightLowerArm": Vector3(0.0, -0.85, 0.52)}
const L_SLAM := {"LeftUpperArm": Vector3(0.1, -0.45, 0.89), "LeftLowerArm": Vector3(0.0, -0.85, 0.52)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.2, lean * 1.1, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = F.FIGHT
	var BK = F.SHIFT
	var PV = F.PIVOT
	var PL = F.PIVOT_L
	var L = S.LEG_LUNGE
	return [
		{"len": 0.42, "hit": 0.16, "keys": [
			_t(0.0, 0.45, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.07, 0.5, -20, 6, R_CHAMBER, L_GUARD, BK),
			_t(0.16, 0.48, 22, 22, R_PUNCH, L_GUARD, PV),
			_t(0.26, 0.46, 18, 18, R_PUNCH, L_GUARD, PV),
			_t(0.42, 0.45, 0, 10, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.55, "hit": 0.26, "keys": [
			_t(0.0, 0.45, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.12, 0.62, 30, 30, R_TUCK, L_TUCK, BK),
			_t(0.26, 0.55, 40, 34, R_TUCK, L_TUCK, L),   # omuz önde dalış
			_t(0.38, 0.52, 36, 30, R_TUCK, L_TUCK, L),
			_t(0.55, 0.45, 0, 10, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.65, "hit": 0.32, "keys": [
			_t(0.0, 0.45, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.16, 0.55, -30, 18, R_LARIAT, L_GUARD, F.STEPIN),
			_t(0.32, 0.5, 30, 24, R_LARIAT, L_GUARD, L),   # kol açık, gövde dönerek çarpar
			_t(0.44, 0.48, 44, 20, R_LARIAT, L_GUARD, L),
			_t(0.65, 0.45, 0, 10, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.5, "hit": 0.24, "keys": [
			_t(0.0, 0.45, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.12, 0.5, -34, 6, R_CHOP0, L_GUARD, BK),
			_t(0.24, 0.5, 34, 18, R_CHOP1, L_GUARD, PV),
			_t(0.34, 0.48, 38, 16, R_CHOP1, L_GUARD, PV),
			_t(0.5, 0.45, 0, 10, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.75, "hit": 0.12, "extra_hits": [0.22, 0.32, 0.42, 0.52], "extra_radius": 1.6, "keys": [
			_t(0.0, 0.45, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.06, 0.5, 14, 16, R_PUNCH, L_CHAMBER, PV),
			_t(0.12, 0.5, -14, 16, R_CHAMBER, L_PUNCH, PL),
			_t(0.22, 0.5, 14, 16, R_PUNCH, L_CHAMBER, PV),
			_t(0.32, 0.5, -14, 16, R_CHAMBER, L_PUNCH, PL),
			_t(0.42, 0.5, 14, 16, R_PUNCH, L_CHAMBER, PV),
			_t(0.52, 0.52, -14, 18, R_CHAMBER, L_PUNCH, PL),
			_t(0.75, 0.45, 0, 10, R_GUARD, L_GUARD, W),
		]},
		{"len": 1.0, "hit": 0.6, "keys": [
			_t(0.0, 0.45, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.16, 0.5, 0, 20, R_GRAB, L_GRAB, F.STEPIN),   # kavrar
			_t(0.34, 0.35, 0, -18, R_LIFT, L_LIFT, W),         # başının üstüne kaldırır
			_t(0.48, 0.35, 0, -20, R_LIFT, L_LIFT, W),
			_t(0.6, 0.85, 0, 40, R_SLAM, L_SLAM, L),           # yere çakar
			_t(0.78, 0.82, 0, 38, R_SLAM, L_SLAM, L),
			_t(1.0, 0.45, 0, 10, R_GUARD, L_GUARD, W),
		]},
	]
