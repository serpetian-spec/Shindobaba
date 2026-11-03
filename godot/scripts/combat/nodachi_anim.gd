extends RefCounted
## Nodachi — insan boyunda iki elli uzun kılıç: menzil ve geniş yaylar. Uzun kılıcın ağırlığı: geniş kurulum, gövdeyle savuruş,
## savuruştan sonra ağız taşar. Zıplama ve yere çakma YOK.
## 1 Battō: sağ omzun üstünden (sırttan çekiliyormuş gibi) çapraz iniş, 2 Nagi: bel hizasında çok geniş yatay biçme (uzun menzil),
## 3 Nagatsuki: uzun adımla iki elli saplama (çok uzun menzil), 4 Ashi Barai: çömelip ayak bileği hizasında yarım tur süpürme (düşürür),
## 5 Sakasa Kesa: alttan ters çapraz yükselen kesik (havaya kaldırır), 6 Zankū Sen (bitiriş): hassō duruşu — ağız sağ omuzda dik,
## uzun bekleme -> tek dev yatay kesik, ağızdan kopan hava kesiği öne 10 m ilerleyip yolundakileri biçer (KeyedCombos).

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_READY := {"RightUpperArm": Vector3(-0.2, -0.75, 0.6), "RightLowerArm": Vector3(0.3, 0.2, 0.93)}
const L_READY := {"LeftUpperArm": Vector3(0.35, -0.75, 0.55), "LeftLowerArm": Vector3(-0.3, 0.25, 0.92)}
const R_SHOULDER := {"RightUpperArm": Vector3(-0.5, 0.75, -0.42), "RightLowerArm": Vector3(-0.1, 0.9, 0.4)}
const L_SHOULDER := {"LeftUpperArm": Vector3(-0.1, 0.55, 0.82), "LeftLowerArm": Vector3(-0.6, 0.7, 0.4)}
const R_LOWEND := {"RightUpperArm": Vector3(0.25, -0.5, 0.82), "RightLowerArm": Vector3(0.85, -0.3, 0.4)}
const L_LOWEND := {"LeftUpperArm": Vector3(-0.15, -0.55, 0.82), "LeftLowerArm": Vector3(0.4, -0.4, 0.82)}
const R_BACK_R := {"RightUpperArm": Vector3(-0.95, 0.15, -0.25), "RightLowerArm": Vector3(-0.7, 0.3, -0.6)}
const L_BACK_R := {"LeftUpperArm": Vector3(-0.3, 0.1, 0.95), "LeftLowerArm": Vector3(-0.95, 0.2, 0.2)}
const R_ACROSS := {"RightUpperArm": Vector3(0.45, 0.1, 0.88), "RightLowerArm": Vector3(0.95, 0.15, 0.2)}
const L_ACROSS := {"LeftUpperArm": Vector3(0.75, 0.0, 0.65), "LeftLowerArm": Vector3(0.95, 0.1, -0.2)}
const R_CHAMBER := {"RightUpperArm": Vector3(-0.35, -0.55, -0.75), "RightLowerArm": Vector3(-0.05, -0.05, 1)}
const L_CHAMBER := {"LeftUpperArm": Vector3(0.1, -0.6, 0.78), "LeftLowerArm": Vector3(-0.3, -0.1, 0.95)}
const R_STAB := {"RightUpperArm": Vector3(-0.08, -0.05, 1), "RightLowerArm": Vector3(0.0, -0.03, 1)}
const L_STAB := {"LeftUpperArm": Vector3(-0.05, -0.05, 1), "LeftLowerArm": Vector3(-0.2, -0.03, 0.98)}
const R_LOW := {"RightUpperArm": Vector3(-0.8, -0.55, 0.2), "RightLowerArm": Vector3(-0.7, -0.6, 0.4)}
const L_LOW := {"LeftUpperArm": Vector3(-0.2, -0.7, 0.68), "LeftLowerArm": Vector3(-0.7, -0.5, 0.5)}
const R_LOW_IN := {"RightUpperArm": Vector3(0.4, -0.8, 0.45), "RightLowerArm": Vector3(0.8, -0.55, 0.25)}
const L_LOW_IN := {"LeftUpperArm": Vector3(0.7, -0.6, 0.38), "LeftLowerArm": Vector3(0.9, -0.4, -0.1)}
const R_RISE := {"RightUpperArm": Vector3(-0.55, 0.65, 0.5), "RightLowerArm": Vector3(-0.4, 0.85, 0.35)}
const L_RISE := {"LeftUpperArm": Vector3(-0.3, 0.6, 0.74), "LeftLowerArm": Vector3(-0.6, 0.7, 0.4)}
const R_HASSO := {"RightUpperArm": Vector3(-0.45, -0.3, 0.84), "RightLowerArm": Vector3(-0.15, 0.95, 0.25)}   # ağız sağ omuz yanında dik
const L_HASSO := {"LeftUpperArm": Vector3(-0.1, -0.35, 0.93), "LeftLowerArm": Vector3(-0.75, 0.55, 0.35)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.5, lean * 1.4, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	var RDY = Vector3(0.1, 0.35, 0.93)
	return [
		{"len": 1.0, "hit": 0.46, "two": true, "keys": [
			_t(0.0, 0.38, 0, 6, RDY, R_READY, L_READY, W),
			_t(0.2, 0.42, -18, -14, Vector3(-0.2, 0.8, -0.55), R_SHOULDER, L_SHOULDER, BK),
			_t(0.38, 0.44, -20, -16, Vector3(-0.2, 0.8, -0.55), R_SHOULDER, L_SHOULDER, BK),
			_t(0.46, 0.56, 22, 26, Vector3(0.6, -0.6, 0.5), R_LOWEND, L_LOWEND, L),
			_t(0.66, 0.56, 26, 22, Vector3(0.65, -0.65, 0.4), R_LOWEND, L_LOWEND, L),
			_t(1.0, 0.38, 0, 6, RDY, R_READY, L_READY, W),
		]},
		{"len": 1.05, "hit": 0.5, "two": true, "keys": [
			_t(0.0, 0.38, 0, 6, RDY, R_READY, L_READY, W),
			_t(0.22, 0.46, -50, -6, Vector3(-0.85, 0.2, -0.45), R_BACK_R, L_BACK_R, BK),
			_t(0.42, 0.48, -56, -8, Vector3(-0.85, 0.2, -0.45), R_BACK_R, L_BACK_R, BK),
			_t(0.5, 0.5, 8, 14, Vector3(-0.2, 0.1, 0.97), R_STAB, L_STAB, ST),
			_t(0.58, 0.52, 56, 18, Vector3(0.9, 0.1, 0.35), R_ACROSS, L_ACROSS, L),
			_t(0.8, 0.5, 64, 14, Vector3(0.9, 0.05, 0.3), R_ACROSS, L_ACROSS, L),
			_t(1.05, 0.38, 0, 6, RDY, R_READY, L_READY, W),
		]},
		{"len": 0.95, "hit": 0.46, "two": true, "keys": [
			_t(0.0, 0.38, 0, 6, RDY, R_READY, L_READY, W),
			_t(0.2, 0.5, -20, -8, Vector3(0, 0.05, 1), R_CHAMBER, L_CHAMBER, BK),
			_t(0.38, 0.52, -22, -10, Vector3(0, 0.05, 1), R_CHAMBER, L_CHAMBER, BK),
			_t(0.46, 0.64, 10, 32, Vector3(0, 0.0, 1), R_STAB, L_STAB, L),
			_t(0.68, 0.62, 8, 28, Vector3(0, 0.0, 1), R_STAB, L_STAB, L),
			_t(0.95, 0.38, 0, 6, RDY, R_READY, L_READY, W),
		]},
		{"len": 1.0, "hit": 0.48, "two": true, "keys": [
			_t(0.0, 0.38, 0, 6, RDY, R_READY, L_READY, W),
			_t(0.2, 0.84, -50, 30, Vector3(-0.9, -0.4, -0.1), R_LOW, L_LOW, W),
			_t(0.4, 0.86, -56, 32, Vector3(-0.9, -0.4, -0.1), R_LOW, L_LOW, W),
			_t(0.48, 0.86, 30, 32, Vector3(0.6, -0.5, 0.6), R_LOW_IN, L_LOW_IN, CR),
			_t(0.64, 0.84, 90, 30, Vector3(0.9, -0.4, 0.1), R_LOW_IN, L_LOW_IN, W),
			_t(1.0, 0.38, 0, 6, RDY, R_READY, L_READY, W),
		]},
		{"len": 0.95, "hit": 0.46, "two": true, "keys": [
			_t(0.0, 0.38, 0, 6, RDY, R_READY, L_READY, W),
			_t(0.22, 0.62, 30, 22, Vector3(0.6, -0.65, -0.4), R_LOWEND, L_LOWEND, CR),
			_t(0.4, 0.64, 34, 24, Vector3(0.6, -0.65, -0.4), R_LOWEND, L_LOWEND, CR),
			_t(0.46, 0.36, -24, -10, Vector3(-0.55, 0.75, 0.35), R_RISE, L_RISE, L),
			_t(0.66, 0.34, -28, -12, Vector3(-0.55, 0.8, 0.25), R_RISE, L_RISE, L),
			_t(0.95, 0.38, 0, 6, RDY, R_READY, L_READY, W),
		]},
		{"len": 1.6, "hit": 0.98, "two": true, "keys": [
			_t(0.0, 0.38, 0, 6, RDY, R_READY, L_READY, W),
			_t(0.3, 0.52, -10, 2, Vector3(0, 1, -0.1), R_HASSO, L_HASSO, BK),
			_t(0.82, 0.54, -12, 0, Vector3(0, 1, -0.1), R_HASSO, L_HASSO, BK),
			_t(0.9, 0.5, -54, -6, Vector3(-0.85, 0.2, -0.45), R_BACK_R, L_BACK_R, BK),
			_t(0.98, 0.56, 20, 22, Vector3(-0.1, 0.1, 0.99), R_STAB, L_STAB, L),
			_t(1.06, 0.58, 70, 24, Vector3(0.9, 0.1, 0.35), R_ACROSS, L_ACROSS, L),
			_t(1.3, 0.56, 76, 20, Vector3(0.9, 0.05, 0.3), R_ACROSS, L_ACROSS, L),
			_t(1.6, 0.38, 0, 6, RDY, R_READY, L_READY, W),
		]},
	]
