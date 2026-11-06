extends RefCounted
## Bō (düz uzun sopa): İKİ ELLE ortadan; iki uç da vurur. Hızlı ve akıcı: uç değiştiren darbeler, çevirme, süpürme, sırıkla atlama.
## 1 üst uçla tepe darbesi, 2 alt uçla yan darbe (uç değiştirme), 3 ileri dürtme, 4 alçak bacak süpürmesi, 5 çark çevirme (çoklu),
## 6 Bōjutsu Ranbu (bitiriş): sopayı yere dayayıp atlar, inerken iki uçla art arda ezer.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_READY := {"RightUpperArm": Vector3(-0.3, -0.8, 0.5), "RightLowerArm": Vector3(0.35, -0.1, 0.93)}
const R_HIGH := {"RightUpperArm": Vector3(-0.45, 0.85, -0.3), "RightLowerArm": Vector3(-0.15, 0.9, -0.4)}
const R_DOWN := {"RightUpperArm": Vector3(-0.1, -0.35, 0.93), "RightLowerArm": Vector3(0.0, -0.6, 0.8)}
const R_SIDE := {"RightUpperArm": Vector3(0.4, 0.15, 0.9), "RightLowerArm": Vector3(0.9, 0.2, 0.3)}
const R_WIDE := {"RightUpperArm": Vector3(-0.98, 0.0, 0.15), "RightLowerArm": Vector3(-0.95, 0.05, 0.3)}
const R_DRAW := {"RightUpperArm": Vector3(-0.45, -0.5, -0.75), "RightLowerArm": Vector3(0.1, 0.25, 0.97)}
const R_THRUST := {"RightUpperArm": Vector3(-0.05, 0.05, 1), "RightLowerArm": Vector3(0.0, 0.0, 1)}
const R_LOW := {"RightUpperArm": Vector3(-0.35, -0.9, 0.2), "RightLowerArm": Vector3(-0.1, -0.7, 0.7)}
const R_TWIRL := {"RightUpperArm": Vector3(-0.4, -0.2, 0.9), "RightLowerArm": Vector3(0.4, 0.5, 0.75)}
const R_PLANT := {"RightUpperArm": Vector3(-0.15, -0.6, 0.78), "RightLowerArm": Vector3(0.0, -0.9, 0.4)}
const L_ANY := {"LeftUpperArm": Vector3(0.3, -0.8, 0.45), "LeftLowerArm": Vector3(-0.1, -0.2, 0.97)}
const KICK := {"RightUpperLeg": Vector3(-0.1, 0.1, 0.99), "RightLowerLeg": Vector3(-0.05, 0.05, 1), "RightFoot": Vector3(0, 0.6, 0.8)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, blade.normalized(), S._a(r, L_ANY), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	var RDY = Vector3(0.35, 0.3, 0.88)
	return [
		{"len": 0.65, "hit": 0.3, "two": true, "keys": [
			_t(0.0, 0.36, -4, 4, RDY, R_READY, W),
			_t(0.14, 0.4, -10, -14, Vector3(0, 0.7, -0.7), R_HIGH, BK),
			_t(0.3, 0.56, 6, 24, Vector3(0, -0.75, 0.66), R_DOWN, L),
			_t(0.42, 0.54, 4, 20, Vector3(0, -0.8, 0.6), R_DOWN, L),
			_t(0.65, 0.36, -4, 4, RDY, R_READY, W),
		]},
		{"len": 0.6, "hit": 0.26, "two": true, "keys": [
			_t(0.0, 0.36, -4, 4, RDY, R_READY, W),
			_t(0.12, 0.4, -30, -4, Vector3(-0.9, 0.1, 0.3), R_WIDE, BK),
			_t(0.26, 0.46, 30, 14, Vector3(0.9, 0.1, 0.35), R_SIDE, LL),
			_t(0.38, 0.44, 34, 12, Vector3(0.9, 0.1, 0.3), R_SIDE, LL),
			_t(0.6, 0.36, -4, 4, RDY, R_READY, W),
		]},
		{"len": 0.6, "hit": 0.26, "two": true, "keys": [
			_t(0.0, 0.36, -4, 4, RDY, R_READY, W),
			_t(0.12, 0.42, -16, -6, Vector3(0, 0, 1), R_DRAW, BK),
			_t(0.26, 0.5, 10, 20, Vector3(0, 0, 1), R_THRUST, L),
			_t(0.38, 0.48, 8, 16, Vector3(0, 0, 1), R_THRUST, L),
			_t(0.6, 0.36, -4, 4, RDY, R_READY, W),
		]},
		{"len": 0.7, "hit": 0.32, "two": true, "keys": [
			_t(0.0, 0.36, -4, 4, RDY, R_READY, W),
			_t(0.14, 0.7, -26, 18, Vector3(-0.8, -0.5, 0.3), R_LOW, BK),
			_t(0.32, 0.72, 34, 20, Vector3(0.8, -0.5, 0.3), R_LOW, CR),
			_t(0.44, 0.7, 40, 18, Vector3(0.8, -0.5, 0.3), R_LOW, CR),
			_t(0.7, 0.36, -4, 4, RDY, R_READY, W),
		]},
		{"len": 1.0, "hit": 0.22, "two": true, "extra_hits": [0.4, 0.58, 0.76], "extra_radius": 2.0, "keys": [
			_t(0.0, 0.36, -4, 4, RDY, R_READY, W),
			_t(0.16, 0.4, 0, 8, Vector3(0, 1, 0.1), R_TWIRL, ST),
			_t(0.34, 0.4, 6, 8, Vector3(0, -0.1, 1), R_TWIRL, W),
			_t(0.52, 0.42, -6, 10, Vector3(0, -1, 0.1), R_TWIRL, ST),
			_t(0.7, 0.42, 6, 10, Vector3(0, 0.1, -1), R_TWIRL, W),
			_t(1.0, 0.36, -4, 4, RDY, R_READY, W),
		]},
		{"len": 1.3, "hit": 0.66, "keys": [
			_t(0.0, 0.36, -4, 4, RDY, R_READY, W),
			_t(0.2, 0.52, 0, 22, Vector3(0, -0.95, 0.3), R_PLANT, L),
			_t(0.36, 0.26, 0, -12, Vector3(0, -0.95, 0.3), R_PLANT, W),
			_t(0.52, 0.18, 0, -28, Vector3(0, -0.95, 0.3), R_PLANT, KICK),
			_t(0.66, 0.5, 6, 26, Vector3(0, -0.75, 0.66), R_DOWN, L),
			_t(0.86, 0.46, -24, 14, Vector3(-0.9, 0.1, 0.3), R_WIDE, LL),
			_t(1.3, 0.36, -4, 4, RDY, R_READY, W),
		]},
	]
