extends RefCounted
## Dövüş tarzı — Sabaku (Gaara: kum). UZAK MENZİL, KIPIRDAMAZ. Ref: refs/styles/sabaku_*.png (kum tabutu, kum shurikeni, kum şelalesi,
## kum kalkanı). Gaara kollarını kavuşturup durur; kum dövüşür. El hareketleri küçük ve kontrollü, gövde neredeyse sabit.
## 1 Suna no Te: sağ el ileri — yerden kum yumruğu hedefe, 2 Suna Shuriken: sol el savrulur, kum shurikenleri,
## 3 Suna Tsunami: iki el aşağıdan yukarı, kum dalgası ileri, 4 Sabaku Kyū: avuç açılır — kum hedefi sarar (bağlar),
## 5 Suna Shigure: kol yukarı, hedefin üstüne kum yağmuru, 6 Sabaku Sōsō: açık avuç yumruğa kapanır — sarılı kum sıkıştırır.

const S = preload("res://scripts/combat/samehada_anim.gd")
const F = preload("res://scripts/combat/style_legs.gd")

const R_FOLD := {"RightUpperArm": Vector3(-0.2, -0.75, 0.6), "RightLowerArm": Vector3(0.9, 0.2, 0.35)}    # kollar göğüste kavuşuk
const L_FOLD := {"LeftUpperArm": Vector3(0.2, -0.75, 0.6), "LeftLowerArm": Vector3(-0.9, 0.25, 0.32)}
const R_REACH := {"RightUpperArm": Vector3(-0.1, 0.05, 1), "RightLowerArm": Vector3(0.0, 0.1, 1)}
const L_SWEEP0 := {"LeftUpperArm": Vector3(-0.3, -0.4, 0.85), "LeftLowerArm": Vector3(-0.7, 0.2, 0.68)}
const L_SWEEP1 := {"LeftUpperArm": Vector3(0.9, -0.05, 0.4), "LeftLowerArm": Vector3(0.85, 0.0, 0.5)}
const R_LOW := {"RightUpperArm": Vector3(-0.2, -0.95, 0.2), "RightLowerArm": Vector3(0.0, -0.8, 0.6)}
const L_LOW := {"LeftUpperArm": Vector3(0.2, -0.95, 0.2), "LeftLowerArm": Vector3(0.0, -0.8, 0.6)}
const R_LIFT := {"RightUpperArm": Vector3(-0.15, 0.4, 0.9), "RightLowerArm": Vector3(0.0, 0.6, 0.8)}
const L_LIFT := {"LeftUpperArm": Vector3(0.15, 0.4, 0.9), "LeftLowerArm": Vector3(0.0, 0.6, 0.8)}
const R_UP := {"RightUpperArm": Vector3(-0.2, 0.97, 0.1), "RightLowerArm": Vector3(0.0, 1, 0.05)}


static func _t(t: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw, lean, Vector3(0, 0, 1), S._a(r, l), legs)


static func steps() -> Array:
	var W = F.FIGHT
	var BK = F.SHIFT
	return [
		{"len": 0.55, "hit": 0.26, "keys": [
			_t(0.0, 0.2, 0, 0, R_FOLD, L_FOLD, W),
			_t(0.14, 0.22, -8, 2, R_FOLD, L_FOLD, W),
			_t(0.26, 0.24, 10, 6, R_REACH, L_FOLD, W),
			_t(0.38, 0.24, 8, 4, R_REACH, L_FOLD, W),
			_t(0.55, 0.2, 0, 0, R_FOLD, L_FOLD, W),
		]},
		{"len": 0.55, "hit": 0.24, "keys": [
			_t(0.0, 0.2, 0, 0, R_FOLD, L_FOLD, W),
			_t(0.12, 0.24, 18, 2, R_FOLD, L_SWEEP0, W),
			_t(0.24, 0.24, -16, 4, R_FOLD, L_SWEEP1, W),
			_t(0.36, 0.22, -14, 2, R_FOLD, L_SWEEP1, W),
			_t(0.55, 0.2, 0, 0, R_FOLD, L_FOLD, W),
		]},
		{"len": 0.65, "hit": 0.32, "keys": [
			_t(0.0, 0.2, 0, 0, R_FOLD, L_FOLD, W),
			_t(0.16, 0.34, 0, 8, R_LOW, L_LOW, BK),
			_t(0.32, 0.22, 0, -4, R_LIFT, L_LIFT, W),
			_t(0.46, 0.2, 0, -4, R_LIFT, L_LIFT, W),
			_t(0.65, 0.2, 0, 0, R_FOLD, L_FOLD, W),
		]},
		{"len": 0.6, "hit": 0.3, "keys": [
			_t(0.0, 0.2, 0, 0, R_FOLD, L_FOLD, W),
			_t(0.14, 0.24, 0, 2, R_REACH, L_FOLD, W),
			_t(0.3, 0.24, 0, 4, R_REACH, L_FOLD, W),   # açık avuç: kum sarar
			_t(0.44, 0.22, 0, 2, R_REACH, L_FOLD, W),
			_t(0.6, 0.2, 0, 0, R_FOLD, L_FOLD, W),
		]},
		{"len": 0.7, "hit": 0.36, "keys": [
			_t(0.0, 0.2, 0, 0, R_FOLD, L_FOLD, W),
			_t(0.18, 0.2, 0, -6, R_UP, L_FOLD, W),
			_t(0.36, 0.2, 0, -6, R_UP, L_FOLD, W),
			_t(0.5, 0.24, 0, 4, R_REACH, L_FOLD, W),
			_t(0.7, 0.2, 0, 0, R_FOLD, L_FOLD, W),
		]},
		{"len": 0.85, "hit": 0.5, "keys": [
			_t(0.0, 0.2, 0, 0, R_FOLD, L_FOLD, W),
			_t(0.2, 0.24, 0, 2, R_REACH, L_FOLD, W),
			_t(0.42, 0.24, 0, 2, R_REACH, L_FOLD, W),   # avuç açık bekler...
			_t(0.5, 0.26, 4, 6, R_REACH, L_FOLD, W),     # ...ve yumruğa kapanır (KeyedCombos: fist)
			_t(0.66, 0.26, 4, 6, R_REACH, L_FOLD, W),
			_t(0.85, 0.2, 0, 0, R_FOLD, L_FOLD, W),
		]},
	]
