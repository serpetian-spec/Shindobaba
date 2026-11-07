extends RefCounted
## Jinchūriki tarzı — Chōmei (Yedi Kuyruk, Fū). ORTA. Görseller oyunun gerçek sistemi (BijuuArts._rinpun pul tozu parlaması,
## _mushi_swarm chakra emen böcekler, Chōmei'nin şeffaf böcek kanadı malzemesi). Kanon: Fū sırtından böcek kanatları açıp uçar,
## pul tozuyla kör eder (Rinpungakure), böcek sürüsü salar, havadan dalar.
## 1-2 kanat çırpışı rüzgâr bıçakları (sağ/sol), 3 böcek sürüsü (chakra emer), 4 pul tozu parlaması (kör eder),
## 5 kanatla sıçrayış — havadan dalış tekmesi, 6 bitiriş: kanatlar açılır, pul tozu + rüzgâr fırtınası.

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")


static func steps() -> Array:
	return [
		C.step(0.5, 0.24, C.R_SPREAD, C.L_GUARD, C.R_SWEEP_IN, C.L_GUARD, F.SHIFT, F.PIVOT, -30.0, 30.0, 0.38, 6.0),
		C.step(0.5, 0.24, C.R_GUARD, C.L_SPREAD, C.R_GUARD, C.L_REACH, F.FIGHT, F.PIVOT_L, 30.0, -30.0, 0.38, 6.0),
		C.step(0.6, 0.3, C.R_SEAL, C.L_SEAL, C.R_PALM, C.L_PALM, F.FIGHT, F.STEPIN, 0.0, 0.0, 0.4, 6.0),
		C.step(0.6, 0.3, C.R_MOUTH, C.L_HIP, C.R_SPREAD, C.L_SPREAD, F.SHIFT, F.FIGHT, 0.0, 0.0, 0.4, -6.0),
		{"len": 0.85, "hit": 0.5, "keys": [
			C.t(0.0, 0.4, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.2, 0.3, 0, -10, C.R_SPREAD, C.L_SPREAD, F.HOP),
			C.t(0.42, 0.3, 0, 20, C.R_BACK, C.L_BACK, C.KICK_FRONT_R),
			C.t(0.6, 0.38, 0, 14, C.R_BACK, C.L_BACK, C.KICK_FRONT_R),
			C.t(0.85, 0.4, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
		{"len": 1.1, "hit": 0.62, "keys": [
			C.t(0.0, 0.4, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.26, 0.36, 0, -12, C.R_SKY, C.L_SKY, F.FIGHT),
			C.t(0.54, 0.36, 0, -14, C.R_SKY, C.L_SKY, F.FIGHT),
			C.t(0.62, 0.42, 0, 8, C.R_SPREAD, C.L_SPREAD, F.STEPIN),
			C.t(0.9, 0.42, 0, 6, C.R_SPREAD, C.L_SPREAD, F.STEPIN),
			C.t(1.1, 0.4, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
