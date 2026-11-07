extends RefCounted
## Yol tarzı — Şimşek Kılıcı (Sasuke, Chidori). YAKIN-ORTA. Görseller oyunun gerçek şimşek sistemi: elde şimşek küresi
## (KeyedCombos._rai_hand = VFX.lightning_ball), dallanan şimşek (VFX.bolt), şimşek mızrağı (mat_bolt), zemin yarığı (VFX.cracks).
## Kanon: Chidori elde bin kuş sesiyle toplanır; Nagashi bedenden her yöne akar; Senbon iğneler, Eisō uzayan mızrak;
## Sasuke koşarken Chidori'li elini yere sürter, toprağı yarar, sonra yukarı saplar.
## 1 Chidori darbesi (kısa sağ), 2 Chidori Senbon (sol elden iğne yelpazesi), 3 Chidori Eisō (uzayan mızrak),
## 4 Chidori Nagashi (bedenden her yöne akım, felç), 5 Chidori Tōshi (tek parmaktan ince şimşek iğnesi, uzak delme),
## 6 bitiriş: Chidori koşusu — el yere sürtülür, hendek açılır, hedefe yukarı saplanır.

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")
const R_CHIDORI := {"RightUpperArm": Vector3(-0.25, -0.75, -0.6), "RightLowerArm": Vector3(0.1, -0.2, 0.97)}   # el bel yanında, avuç aşağı (şimşek toplanır)
const L_GRIP := {"LeftUpperArm": Vector3(0.3, -0.75, 0.58), "LeftLowerArm": Vector3(-0.7, -0.1, 0.7)}       # sol el sağ bileği tutar (Sasuke)
const R_DRAG := {"RightUpperArm": Vector3(-0.2, -0.85, -0.45), "RightLowerArm": Vector3(0.0, -0.95, 0.3)}     # el geride yere sürtülür
const R_POINT := {"RightUpperArm": Vector3(-0.05, 0.05, 1), "RightLowerArm": Vector3(0.0, 0.02, 1)}


static func steps() -> Array:
	return [
		C.step(0.5, 0.24, R_CHIDORI, L_GRIP, C.R_PUNCH, C.L_GUARD, F.SHIFT, F.PIVOT, -20.0, 16.0, 0.4, 10.0),
		C.step(0.55, 0.26, C.R_GUARD, C.L_BACK, C.R_GUARD, C.L_REACH, F.FIGHT, F.PIVOT_L, 18.0, -14.0, 0.38, 6.0),
		C.step(0.7, 0.34, R_CHIDORI, L_GRIP, C.R_REACH, C.L_GUARD, F.SHIFT, F.STEPIN, -26.0, 10.0, 0.42, 14.0),
		C.step(0.65, 0.3, C.R_LOW, C.L_LOW, C.R_SPREAD, C.L_SPREAD, F.LOW, F.LOW, 0.0, 0.0, 0.6, 4.0),
		C.step(0.6, 0.3, C.R_BACK, C.L_GUARD, R_POINT, C.L_GUARD, F.SHIFT, F.STEPIN, -10.0, 4.0, 0.38, 6.0),
		{"len": 1.15, "hit": 0.7, "keys": [
			C.t(0.0, 0.38, 0, 6, R_CHIDORI, L_GRIP, F.SHIFT),
			C.t(0.24, 0.62, -10, 34, R_DRAG, C.L_BACK, F.STEPIN),
			C.t(0.56, 0.62, -10, 36, R_DRAG, C.L_BACK, F.STEPIN),
			C.t(0.7, 0.3, 10, -6, C.R_SKY, C.L_GUARD, F.STEPIN),
			C.t(0.94, 0.32, 6, -2, C.R_UPPER, C.L_GUARD, F.FIGHT),
			C.t(1.15, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
