extends RefCounted
## Yol tarzı — Kâğıt (Konan, Shikigami no Mai). ORTA. Görseller oyunun gerçek kâğıt sistemi: kâğıt shuriken (_paper_star),
## kâğıt kelebekler (_paper_butterfly), kâğıt mızraklar (_paper_spear). Kanon: beden kâğıda dağılır, kâğıt bıçak gibi keser,
## kelebek sürüleri kör eder, yerden kâğıt mızraklar fırlar, patlayıcı kâğıtlar dalga dalga patlar.
## 1-2 kâğıt shuriken (sağ/sol), 3 kelebek sürüsü (kör eder, yavaşlatır), 4 Kami Yari: hedefin altından kâğıt mızraklar,
## 5 kâğıt kanat çırpışı (kesici kâğıt fırtınası), 6 Shikigami no Mai: hedefin çevresinde patlayıcı kâğıt halkası (bitiriş).

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")


static func steps() -> Array:
	return [
		C.step(0.5, 0.22, C.R_BACK, C.L_GUARD, C.R_THROW, C.L_GUARD, F.SHIFT, F.PIVOT, -24.0, 20.0, 0.36, 10.0),
		C.step(0.5, 0.22, C.R_GUARD, C.L_BACK, C.R_GUARD, C.L_PUNCH, F.SHIFT, F.PIVOT_L, 24.0, -20.0, 0.36, 10.0),
		C.step(0.7, 0.32, C.R_SEAL, C.L_SEAL, C.R_PALM, C.L_PALM, F.FIGHT, F.STEPIN, 0.0, 0.0, 0.36, 10.0),
		C.step(0.7, 0.34, C.R_GUARD, C.L_GUARD, C.R_GROUND, C.L_GROUND, F.FIGHT, F.LOW, 0.0, 0.0, 0.6, 24.0),
		C.step(0.75, 0.36, C.R_SPREAD, C.L_SPREAD, C.R_PALM, C.L_PALM, F.SHIFT, F.STEPIN, 0.0, 0.0, 0.34, 8.0),
		{"len": 1.1, "hit": 0.6, "keys": [
			C.t(0.0, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.24, 0.38, 0, -6, C.R_SEAL, C.L_SEAL, F.FIGHT),
			C.t(0.55, 0.4, 0, -8, C.R_SEAL, C.L_SEAL, F.FIGHT),
			C.t(0.66, 0.38, 0, -4, C.R_SPREAD, C.L_SPREAD, F.FIGHT),
			C.t(0.9, 0.38, 0, -4, C.R_SPREAD, C.L_SPREAD, F.FIGHT),
			C.t(1.1, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
