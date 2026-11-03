extends RefCounted
## Pençe (ref claw.png) — İKİ EL: vahşi, hızlı yırtma kombosu; her vuruşta bıçaklara chakra akar (KeyedCombos: üç paralel parlayan
## pençe izi). 1 sağ çapraz yırtık, 2 sol ters yırtık, 3 çift X yırtık, 4 çömelip yukarı çift pençe (kaldırır), 5 sıçrayıp üstten
## pençe dalışı, 6 Chakra Sōga (bitiriş): iki pençe tam chakra yüklü, ileri atılıp dev X kesik.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_GUARD := {"RightUpperArm": Vector3(-0.3, -0.6, 0.72), "RightLowerArm": Vector3(0.3, 0.55, 0.78)}
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.6, 0.72), "LeftLowerArm": Vector3(-0.3, 0.55, 0.78)}
const R_HIGH := {"RightUpperArm": Vector3(-0.6, 0.7, -0.2), "RightLowerArm": Vector3(-0.2, 0.9, 0.3)}
const L_HIGH := {"LeftUpperArm": Vector3(0.6, 0.7, -0.2), "LeftLowerArm": Vector3(0.2, 0.9, 0.3)}
const R_RAKE := {"RightUpperArm": Vector3(0.35, -0.4, 0.86), "RightLowerArm": Vector3(0.8, -0.4, 0.45)}        # sol kalçaya yırtmış
const L_RAKE := {"LeftUpperArm": Vector3(-0.35, -0.4, 0.86), "LeftLowerArm": Vector3(-0.8, -0.4, 0.45)}
const R_LOW := {"RightUpperArm": Vector3(-0.35, -0.9, 0.2), "RightLowerArm": Vector3(-0.1, -0.6, 0.8)}
const L_LOW := {"LeftUpperArm": Vector3(0.35, -0.9, 0.2), "LeftLowerArm": Vector3(0.1, -0.6, 0.8)}
const R_UP := {"RightUpperArm": Vector3(-0.15, 0.8, 0.6), "RightLowerArm": Vector3(0.0, 0.95, 0.3)}
const L_UP := {"LeftUpperArm": Vector3(0.15, 0.8, 0.6), "LeftLowerArm": Vector3(0.0, 0.95, 0.3)}
const R_FWD := {"RightUpperArm": Vector3(-0.1, 0.05, 1), "RightLowerArm": Vector3(0.0, 0.05, 1)}
const L_FWD := {"LeftUpperArm": Vector3(0.1, 0.05, 1), "LeftLowerArm": Vector3(0.0, 0.05, 1)}
const R_BACK := {"RightUpperArm": Vector3(-0.65, -0.5, -0.57), "RightLowerArm": Vector3(-0.15, 0.45, 0.88)}
const L_BACK := {"LeftUpperArm": Vector3(0.65, -0.5, -0.57), "LeftLowerArm": Vector3(0.15, 0.45, 0.88)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	return [
		{"len": 0.55, "hit": 0.26, "keys": [
			_t(0.0, 0.48, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.12, 0.5, -24, 0, R_HIGH, L_GUARD, BK),
			_t(0.26, 0.58, 20, 22, R_RAKE, L_GUARD, L),
			_t(0.36, 0.56, 22, 20, R_RAKE, L_GUARD, L),
			_t(0.55, 0.48, 0, 10, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.55, "hit": 0.24, "keys": [
			_t(0.0, 0.48, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.12, 0.5, 24, 0, R_GUARD, L_HIGH, BK),
			_t(0.24, 0.58, -20, 22, R_GUARD, L_RAKE, LL),
			_t(0.34, 0.56, -22, 20, R_GUARD, L_RAKE, LL),
			_t(0.55, 0.48, 0, 10, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.75, "hit": 0.36, "keys": [
			_t(0.0, 0.48, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.18, 0.46, 0, -10, R_HIGH, L_HIGH, BK),
			_t(0.3, 0.46, 0, -12, R_HIGH, L_HIGH, BK),
			_t(0.36, 0.6, 0, 26, R_RAKE, L_RAKE, L),
			_t(0.5, 0.58, 0, 22, R_RAKE, L_RAKE, L),
			_t(0.75, 0.48, 0, 10, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.75, "hit": 0.38, "keys": [
			_t(0.0, 0.48, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.16, 0.78, 0, 30, R_LOW, L_LOW, W),
			_t(0.3, 0.8, 0, 32, R_LOW, L_LOW, W),
			_t(0.38, 0.22, 0, -14, R_UP, L_UP, ST),
			_t(0.52, 0.2, 0, -16, R_UP, L_UP, L),
			_t(0.75, 0.48, 0, 10, R_GUARD, L_GUARD, W),
		]},
		{"len": 0.9, "hit": 0.48, "jump": 7.0, "keys": [
			_t(0.0, 0.48, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.12, 0.7, 0, 16, R_BACK, L_BACK, W),
			_t(0.3, 0.2, 0, -20, R_HIGH, L_HIGH, ST),
			_t(0.48, 0.3, 0, 36, R_RAKE, L_RAKE, ST),
			_t(0.66, 0.6, 0, 24, R_RAKE, L_RAKE, W),
			_t(0.9, 0.48, 0, 10, R_GUARD, L_GUARD, W),
		]},
		{"len": 1.1, "hit": 0.56, "keys": [
			_t(0.0, 0.48, 0, 10, R_GUARD, L_GUARD, W),
			_t(0.2, 0.6, 0, 4, R_BACK, L_BACK, BK),
			_t(0.48, 0.62, 0, 2, R_BACK, L_BACK, BK),
			_t(0.52, 0.56, 0, 22, R_HIGH, L_HIGH, L),
			_t(0.6, 0.62, 0, 30, R_RAKE, L_RAKE, L),
			_t(0.8, 0.6, 0, 26, R_RAKE, L_RAKE, L),
			_t(1.1, 0.48, 0, 10, R_GUARD, L_GUARD, W),
		]},
	]
