extends RefCounted
## Dövüş tarzı — Inuzuka (Shikyaku no Jutsu, dört ayak). Ref: refs/styles/inuzuka_*.png (Kiba: yere eğik dört ayak duruşu, Gatsūga).
## Duruş: derin çömelik, gövde öne eğik, kollar sarkık pençe (parmaklar yarı kıvrık). Hızlı, vahşi.
## 1 Migi Tsume: sağ pençe çaprazdan tırmık, 2 Hidari Tsume: sol pençe, 3 Tobikakari: dört ayaktan atılıp iki pençeyle sıçrama,
## 4 Ryōtsume Oroshi: iki pençe yukarıdan aşağı yırtar, 5 Kaiten Tsume: yerinde dönerek pençe (iki tur, ek vuruşlar),
## 6 Gatsūga: kendi ekseninde matkap gibi dönerek hedefe atılış (KeyedCombos.on_start hız + girdap).

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_PAW := {"RightUpperArm": Vector3(-0.2, -0.95, 0.25), "RightLowerArm": Vector3(0.0, -0.95, 0.3)}   # eller yere: dört ayak
const L_PAW := {"LeftUpperArm": Vector3(0.2, -0.95, 0.25), "LeftLowerArm": Vector3(0.0, -0.95, 0.3)}
const R_RAISE := {"RightUpperArm": Vector3(-0.8, 0.4, -0.3), "RightLowerArm": Vector3(-0.3, 0.85, 0.4)}
const L_RAISE := {"LeftUpperArm": Vector3(0.8, 0.4, -0.3), "LeftLowerArm": Vector3(0.3, 0.85, 0.4)}
const R_RAKE := {"RightUpperArm": Vector3(0.4, -0.3, 0.85), "RightLowerArm": Vector3(0.8, -0.45, 0.4)}
const L_RAKE := {"LeftUpperArm": Vector3(-0.4, -0.3, 0.85), "LeftLowerArm": Vector3(-0.8, -0.45, 0.4)}
const R_FWD := {"RightUpperArm": Vector3(-0.15, 0.2, 0.97), "RightLowerArm": Vector3(0.0, 0.1, 1)}
const L_FWD := {"LeftUpperArm": Vector3(0.15, 0.2, 0.97), "LeftLowerArm": Vector3(0.0, 0.1, 1)}
const R_HIGH := {"RightUpperArm": Vector3(-0.3, 0.9, 0.3), "RightLowerArm": Vector3(-0.1, 0.8, 0.6)}
const L_HIGH := {"LeftUpperArm": Vector3(0.3, 0.9, 0.3), "LeftLowerArm": Vector3(0.1, 0.8, 0.6)}
const R_LOWR := {"RightUpperArm": Vector3(-0.15, -0.6, 0.78), "RightLowerArm": Vector3(0.0, -0.85, 0.5)}
const L_LOWR := {"LeftUpperArm": Vector3(0.15, -0.6, 0.78), "LeftLowerArm": Vector3(0.0, -0.85, 0.5)}
const R_OUT := {"RightUpperArm": Vector3(-1, -0.1, 0.1), "RightLowerArm": Vector3(-0.9, -0.2, 0.35)}
const L_OUT := {"LeftUpperArm": Vector3(1, -0.1, 0.1), "LeftLowerArm": Vector3(0.9, -0.2, 0.35)}
const R_TUCK := {"RightUpperArm": Vector3(-0.2, -0.5, 0.85), "RightLowerArm": Vector3(0.4, 0.4, 0.8)}
const L_TUCK := {"LeftUpperArm": Vector3(0.2, -0.5, 0.85), "LeftLowerArm": Vector3(-0.4, 0.4, 0.8)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	var k = S._k(t, crouch, yaw, lean, Vector3(0, 0, 1), S._a(r, l), legs)
	k["roll"] = 0.0   # eğim kalçadan da: pelvis öne devrilir (dört ayak duruşu yalnız belden olmuyordu)
	k["neck"] = -lean * 0.85   # baş öne-yukarı, rakibe bakar
	return k


## dört ayak çömelişi: uyluklar öne-yana, baldırlar geriye (dizler derin bükük), ayak tabanı yerde
const LEG_SQUAT := {"LeftUpperLeg": Vector3(0.3, -0.4, 0.87), "LeftLowerLeg": Vector3(0.05, -0.88, -0.47), "LeftFoot": Vector3(0.05, -0.4, 0.92),
	"RightUpperLeg": Vector3(-0.3, -0.4, 0.87), "RightLowerLeg": Vector3(-0.05, -0.88, -0.47), "RightFoot": Vector3(-0.05, -0.4, 0.92)}
const LEG_POUNCE := {"RightUpperLeg": Vector3(-0.2, -0.55, 0.81), "RightLowerLeg": Vector3(-0.05, -0.75, -0.66), "RightFoot": Vector3(-0.05, -0.4, 0.92),
	"LeftUpperLeg": Vector3(0.22, -0.7, -0.68), "LeftLowerLeg": Vector3(0.1, -0.5, -0.86), "LeftFoot": Vector3(0.1, -0.95, 0.3)}


static func steps() -> Array:
	var W = LEG_SQUAT
	var L = LEG_POUNCE
	var LL = S.mirror(LEG_POUNCE)
	var BK = LEG_SQUAT
	var ST = S.LEG_STEP
	return [
		{"len": 0.4, "hit": 0.16, "keys": [
			_t(0.0, 1.0, 0, 88, R_PAW, L_PAW, W),
			_t(0.07, 1.0, -26, 60, R_RAISE, L_PAW, BK),
			_t(0.16, 1.0, 24, 66, R_RAKE, L_PAW, L),
			_t(0.25, 1.0, 28, 64, R_RAKE, L_PAW, L),
			_t(0.4, 1.0, 0, 88, R_PAW, L_PAW, W),
		]},
		{"len": 0.4, "hit": 0.16, "keys": [
			_t(0.0, 1.0, 0, 88, R_PAW, L_PAW, W),
			_t(0.07, 1.0, 26, 60, R_PAW, L_RAISE, BK),
			_t(0.16, 1.0, -24, 66, R_PAW, L_RAKE, LL),
			_t(0.25, 1.0, -28, 64, R_PAW, L_RAKE, LL),
			_t(0.4, 1.0, 0, 88, R_PAW, L_PAW, W),
		]},
		{"len": 0.6, "hit": 0.3, "keys": [
			_t(0.0, 1.0, 0, 88, R_PAW, L_PAW, W),
			_t(0.16, 1.05, 0, 55, R_LOWR, L_LOWR, BK),   # yere yapışır, sıçramaya kurulur
			_t(0.3, 0.6, 0, 30, R_FWD, L_FWD, L),
			_t(0.42, 0.62, 0, 32, R_FWD, L_FWD, L),
			_t(0.6, 1.0, 0, 88, R_PAW, L_PAW, W),
		]},
		{"len": 0.55, "hit": 0.27, "keys": [
			_t(0.0, 1.0, 0, 88, R_PAW, L_PAW, W),
			_t(0.14, 0.7, 0, 10, R_HIGH, L_HIGH, ST),
			_t(0.27, 1.0, 0, 78, R_LOWR, L_LOWR, L),
			_t(0.38, 1.0, 0, 76, R_LOWR, L_LOWR, L),
			_t(0.55, 1.0, 0, 88, R_PAW, L_PAW, W),
		]},
		{"len": 0.7, "hit": 0.18, "extra_hits": [0.36, 0.52], "extra_radius": 1.9, "keys": [
			_t(0.0, 1.0, 0, 88, R_PAW, L_PAW, W),
			_t(0.1, 1.0, -60, 55, R_OUT, L_OUT, W),
			_t(0.2, 1.0, 60, 55, R_OUT, L_OUT, W),
			_t(0.3, 1.0, 170, 55, R_OUT, L_OUT, W),
			_t(0.42, 1.0, -170, 55, R_OUT, L_OUT, W),
			_t(0.54, 1.0, -40, 55, R_OUT, L_OUT, W),
			_t(0.7, 1.0, 0, 88, R_PAW, L_PAW, W),
		]},
		{"len": 0.9, "hit": 0.42, "extra_hits": [0.52, 0.62, 0.72], "extra_radius": 1.8, "keys": [
			_t(0.0, 1.0, 0, 88, R_PAW, L_PAW, W),
			_t(0.16, 1.05, 0, 56, R_LOWR, L_LOWR, BK),
			_t(0.3, 0.7, 120, 60, R_TUCK, L_TUCK, ST),
			_t(0.4, 0.7, -120, 60, R_TUCK, L_TUCK, ST),
			_t(0.5, 0.7, 120, 60, R_TUCK, L_TUCK, ST),
			_t(0.6, 0.7, -120, 60, R_TUCK, L_TUCK, ST),
			_t(0.72, 0.72, 0, 58, R_TUCK, L_TUCK, ST),
			_t(0.9, 1.0, 0, 88, R_PAW, L_PAW, W),
		]},
	]
