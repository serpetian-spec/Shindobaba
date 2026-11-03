extends RefCounted
## Senbon (iki elde parmak aralarında iğneler) — UZUN MENZİL atış kombosu (Haku tarzı). Kol bilekten çırpılarak atar; iğneler
## KeyedCombos._senbon_volley ile (oyuncu + düşman aynı). 1 sağ el üç iğne, 2 sol el üç iğne, 3 iki elden yelpaze (çift sıra),
## 4 geri sıçrayıp havadan aşağı iğne yağmuru, 5 dönüp çevreye iğne halkası, 6 Sensatsu Suishō (bitiriş): hedefin çevresinde
## yüzlerce iğne belirip içeri saplanır.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_READY := {"RightUpperArm": Vector3(-0.3, -0.6, 0.7), "RightLowerArm": Vector3(0.35, 0.5, 0.8)}
const L_READY := {"LeftUpperArm": Vector3(0.3, -0.6, 0.7), "LeftLowerArm": Vector3(-0.35, 0.5, 0.8)}
const R_COCK := {"RightUpperArm": Vector3(-0.6, 0.4, -0.65), "RightLowerArm": Vector3(-0.2, 0.7, 0.6)}
const L_COCK := {"LeftUpperArm": Vector3(0.6, 0.4, -0.65), "LeftLowerArm": Vector3(0.2, 0.7, 0.6)}
const R_THROW := {"RightUpperArm": Vector3(-0.1, 0.15, 0.98), "RightLowerArm": Vector3(0.05, 0.0, 1)}
const L_THROW := {"LeftUpperArm": Vector3(0.1, 0.15, 0.98), "LeftLowerArm": Vector3(-0.05, 0.0, 1)}
const R_CROSS := {"RightUpperArm": Vector3(0.3, -0.1, 0.95), "RightLowerArm": Vector3(0.85, 0.3, 0.4)}
const L_CROSS := {"LeftUpperArm": Vector3(-0.3, -0.1, 0.95), "LeftLowerArm": Vector3(-0.85, 0.3, 0.4)}
const R_OPEN := {"RightUpperArm": Vector3(-0.95, 0.05, 0.3), "RightLowerArm": Vector3(-0.85, 0.0, 0.5)}
const L_OPEN := {"LeftUpperArm": Vector3(0.95, 0.05, 0.3), "LeftLowerArm": Vector3(0.85, 0.0, 0.5)}
const R_DOWN := {"RightUpperArm": Vector3(-0.15, -0.3, 0.94), "RightLowerArm": Vector3(0.0, -0.6, 0.8)}
const L_DOWN := {"LeftUpperArm": Vector3(0.15, -0.3, 0.94), "LeftLowerArm": Vector3(0.0, -0.6, 0.8)}
const R_SEAL := {"RightUpperArm": Vector3(-0.2, -0.3, 0.93), "RightLowerArm": Vector3(0.6, 0.45, 0.66)}
const L_SEAL := {"LeftUpperArm": Vector3(0.2, -0.3, 0.93), "LeftLowerArm": Vector3(-0.6, 0.45, 0.66)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.3, lean * 1.2, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	return [
		{"len": 0.5, "hit": 0.24, "keys": [
			_t(0.0, 0.36, 0, 4, R_READY, L_READY, W),
			_t(0.14, 0.4, -22, -6, R_COCK, L_READY, BK),
			_t(0.24, 0.42, 16, 12, R_THROW, L_READY, L),
			_t(0.5, 0.36, 0, 4, R_READY, L_READY, W),
		]},
		{"len": 0.5, "hit": 0.24, "keys": [
			_t(0.0, 0.36, 0, 4, R_READY, L_READY, W),
			_t(0.14, 0.4, 22, -6, R_READY, L_COCK, BK),
			_t(0.24, 0.42, -16, 12, R_READY, L_THROW, LL),
			_t(0.5, 0.36, 0, 4, R_READY, L_READY, W),
		]},
		{"len": 0.7, "hit": 0.34, "keys": [
			_t(0.0, 0.36, 0, 4, R_READY, L_READY, W),
			_t(0.16, 0.42, 0, -4, R_CROSS, L_CROSS, BK),
			_t(0.28, 0.44, 0, -6, R_CROSS, L_CROSS, BK),
			_t(0.34, 0.42, 0, 12, R_OPEN, L_OPEN, ST),
			_t(0.7, 0.36, 0, 4, R_READY, L_READY, W),
		]},
		{"len": 0.95, "hit": 0.46, "jump": 7.5, "keys": [
			_t(0.0, 0.36, 0, 4, R_READY, L_READY, W),
			_t(0.12, 0.66, 0, 14, R_READY, L_READY, W),
			_t(0.3, 0.16, 0, -18, R_COCK, L_COCK, ST),
			_t(0.46, 0.2, 0, 26, R_DOWN, L_DOWN, ST),
			_t(0.95, 0.36, 0, 4, R_READY, L_READY, W),
		]},
		{"len": 0.95, "hit": 0.48, "keys": [
			_t(0.0, 0.36, 0, 4, R_READY, L_READY, W),
			_t(0.18, 0.44, 40, 4, R_CROSS, L_CROSS, CR),
			_t(0.36, 0.46, 150, 6, R_OPEN, L_OPEN, W),
			_t(0.5, 0.46, 260, 6, R_OPEN, L_OPEN, CR),
			_t(0.95, 0.36, 0, 4, R_READY, L_READY, W),
		]},
		{"len": 1.4, "hit": 0.6, "keys": [
			_t(0.0, 0.36, 0, 4, R_READY, L_READY, W),
			_t(0.2, 0.4, 0, -2, R_SEAL, L_SEAL, W),
			_t(0.5, 0.42, 0, -4, R_SEAL, L_SEAL, W),
			_t(0.6, 0.42, 0, 10, R_OPEN, L_OPEN, ST),
			_t(1.0, 0.4, 0, 8, R_OPEN, L_OPEN, ST),
			_t(1.4, 0.36, 0, 4, R_READY, L_READY, W),
		]},
	]
