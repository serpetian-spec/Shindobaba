extends RefCounted
## Ō-Kama (ref orak.png): uzun saplı hilal orak, İKİ ELLE. Biçme ritmi: orak geriye kurulur -> uzun bekleme -> kalçadan açılan geniş
## biçme, hilal bıçak rakibi kancalayıp çeker; kızıl iz (KeyedCombos). 1 yatay biçme, 2 kancalayıp çekme, 3 ters biçme,
## 4 alttan yukarı kaldırma, 5 iki tur dönen ölüm çemberi, 6 Shinigami Otoshi (bitiriş): baş üstünden yere saplama, taşlar fırlar.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_READY := {"RightUpperArm": Vector3(-0.3, -0.85, 0.42), "RightLowerArm": Vector3(0.25, 0.55, 0.8)}
const R_BACK := {"RightUpperArm": Vector3(-0.95, 0.2, -0.25), "RightLowerArm": Vector3(-0.7, 0.4, -0.55)}
const R_ACROSS := {"RightUpperArm": Vector3(0.45, 0.15, 0.88), "RightLowerArm": Vector3(0.95, 0.2, 0.2)}
const R_BACK_L := {"RightUpperArm": Vector3(0.4, 0.2, 0.9), "RightLowerArm": Vector3(0.9, 0.4, -0.2)}
const R_SWEEP_R := {"RightUpperArm": Vector3(-0.95, 0.0, 0.3), "RightLowerArm": Vector3(-0.9, 0.1, 0.4)}
const R_PULL := {"RightUpperArm": Vector3(-0.35, -0.75, -0.55), "RightLowerArm": Vector3(-0.05, 0.1, 1)}
const R_REACH := {"RightUpperArm": Vector3(-0.1, 0.35, 0.93), "RightLowerArm": Vector3(0.0, 0.3, 0.95)}
const R_LOWBACK := {"RightUpperArm": Vector3(-0.35, -0.9, -0.25), "RightLowerArm": Vector3(-0.15, -0.75, 0.6)}
const R_UP := {"RightUpperArm": Vector3(-0.1, 0.75, 0.65), "RightLowerArm": Vector3(0.0, 0.95, 0.3)}
const R_WIDE := {"RightUpperArm": Vector3(-0.98, 0.0, 0.15), "RightLowerArm": Vector3(-0.95, 0.05, 0.3)}
const R_HIGH := {"RightUpperArm": Vector3(-0.45, 0.85, -0.3), "RightLowerArm": Vector3(-0.15, 0.9, -0.4)}
const R_DOWN := {"RightUpperArm": Vector3(-0.1, -0.35, 0.93), "RightLowerArm": Vector3(0.0, -0.6, 0.8)}
const L_ANY := {"LeftUpperArm": Vector3(0.3, -0.8, 0.45), "LeftLowerArm": Vector3(-0.1, -0.2, 0.97)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.5, lean * 1.4, blade.normalized(), S._a(r, L_ANY), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	var RDY = Vector3(0.4, 0.8, 0.45)
	return [
		{"len": 1.05, "hit": 0.52, "two": true, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, W),
			_t(0.2, 0.44, -48, -8, Vector3(-0.8, 0.3, -0.5), R_BACK, BK),
			_t(0.46, 0.46, -54, -10, Vector3(-0.75, 0.35, -0.55), R_BACK, BK),
			_t(0.52, 0.5, 6, 14, Vector3(-0.2, 0.2, 0.96), R_WIDE, ST),
			_t(0.6, 0.54, 46, 20, Vector3(0.9, 0.2, 0.35), R_ACROSS, L),
			_t(0.8, 0.52, 54, 16, Vector3(0.9, 0.1, 0.3), R_ACROSS, L),
			_t(1.05, 0.36, 0, 4, RDY, R_READY, W),
		]},
		{"len": 1.0, "hit": 0.4, "two": true, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, W),
			_t(0.18, 0.4, -20, -10, Vector3(0, 0.8, -0.5), R_HIGH, BK),
			_t(0.34, 0.42, -22, -12, Vector3(0, 0.8, -0.5), R_HIGH, BK),
			_t(0.4, 0.5, 12, 22, Vector3(0, 0.3, 0.95), R_REACH, L),
			_t(0.6, 0.48, -10, -14, Vector3(0, 0.3, 0.95), R_PULL, BK),
			_t(0.8, 0.46, -14, -16, Vector3(0, 0.3, 0.95), R_PULL, BK),
			_t(1.0, 0.36, 0, 4, RDY, R_READY, W),
		]},
		{"len": 1.0, "hit": 0.5, "two": true, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, W),
			_t(0.2, 0.44, 46, -8, Vector3(0.8, 0.4, 0.3), R_BACK_L, CR),
			_t(0.44, 0.46, 52, -10, Vector3(0.75, 0.45, 0.4), R_BACK_L, CR),
			_t(0.5, 0.48, -36, 18, Vector3(-0.9, 0.2, 0.4), R_SWEEP_R, L),
			_t(0.7, 0.46, -44, 14, Vector3(-0.95, 0.1, 0.3), R_SWEEP_R, L),
			_t(1.0, 0.36, 0, 4, RDY, R_READY, W),
		]},
		{"len": 1.0, "hit": 0.5, "two": true, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, W),
			_t(0.18, 0.72, -32, 24, Vector3(0, -0.7, -0.7), R_LOWBACK, BK),
			_t(0.44, 0.74, -36, 26, Vector3(0, -0.65, -0.75), R_LOWBACK, BK),
			_t(0.5, 0.24, 10, -16, Vector3(0, 0.9, 0.4), R_UP, L),
			_t(0.7, 0.22, 8, -18, Vector3(0, 0.95, 0.25), R_UP, L),
			_t(1.0, 0.36, 0, 4, RDY, R_READY, W),
		]},
		{"len": 1.3, "hit": 0.4, "two": true, "extra": [0.66, 0.92], "extra_r": 3.2, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, W),
			_t(0.18, 0.48, -30, 4, Vector3(-0.9, 0.1, 0.3), R_WIDE, BK),
			_t(0.42, 0.5, 70, 8, Vector3(-0.9, 0.1, 0.3), R_WIDE, CR),
			_t(0.66, 0.5, 180, 8, Vector3(-0.9, 0.1, 0.3), R_WIDE, W),
			_t(0.9, 0.5, 290, 8, Vector3(-0.9, 0.1, 0.3), R_WIDE, CR),
			_t(1.3, 0.36, 0, 4, RDY, R_READY, W),
		]},
		{"len": 1.5, "hit": 0.78, "two": true, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, W),
			_t(0.16, 0.72, 0, 14, RDY, R_READY, W),
			_t(0.4, 0.14, -8, -26, Vector3(0, 0.7, -0.7), R_HIGH, ST),
			_t(0.7, 0.16, -10, -30, Vector3(0, 0.65, -0.75), R_HIGH, ST),
			_t(0.78, 0.7, 10, 38, Vector3(0, -0.8, 0.6), R_DOWN, L),
			_t(1.1, 0.72, 8, 32, Vector3(0, -0.85, 0.5), R_DOWN, L),
			_t(1.5, 0.36, 0, 4, RDY, R_READY, W),
		]},
	]
