extends RefCounted
## Yol tarzı — Sumi (Sai, Chōjū Giga). ORTA-UZAK. Görseller oyunun gerçek mürekkep sistemi: fırçayla çizilen mürekkep canavarları
## (_ink_beast "tiger"/"dragon"), mürekkep sıçraması (_ink_splash). Kanon: parşömene fırçayla çizilen canavarlar sayfadan
## fırlayıp canlanır, vurunca mürekkebe dağılır; aslanlar saldırır, yılan/ejder bağlar, kuşlar uçar.
## 1-2 fırça darbesi: mürekkep aslan fırlar (sağ/sol), 3 mürekkep ejder (yılan) dolanıp bağlar, 4 üç aslan sürüsü,
## 5 mürekkep sisi (görüşü kapar, yavaşlatır), 6 Chōjū Giga (bitiriş): parşömen açılır, dev mürekkep kaplan + ejder birden.

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")
const R_BRUSH := {"RightUpperArm": Vector3(-0.2, -0.3, 0.93), "RightLowerArm": Vector3(0.6, 0.15, 0.78)}      # fırça göğüs önünde
const R_STROKE := {"RightUpperArm": Vector3(-0.85, -0.1, 0.5), "RightLowerArm": Vector3(-0.85, -0.05, 0.5)}   # fırça sağa çekilmiş
const L_SCROLL := {"LeftUpperArm": Vector3(0.2, -0.6, 0.77), "LeftLowerArm": Vector3(-0.7, 0.1, 0.71)}       # sol el parşömeni tutar


static func steps() -> Array:
	return [
		C.step(0.5, 0.24, R_BRUSH, L_SCROLL, R_STROKE, L_SCROLL, F.FIGHT, F.PIVOT, -10.0, 20.0, 0.38, 6.0),
		C.step(0.5, 0.24, R_STROKE, L_SCROLL, R_BRUSH, L_SCROLL, F.FIGHT, F.PIVOT_L, 20.0, -14.0, 0.38, 6.0),
		C.step(0.7, 0.32, R_BRUSH, L_SCROLL, R_STROKE, L_SCROLL, F.FIGHT, F.FIGHT, -20.0, 30.0, 0.4, 4.0),
		C.step(0.7, 0.32, R_BRUSH, L_SCROLL, C.R_REACH, L_SCROLL, F.SHIFT, F.STEPIN, 0.0, 10.0, 0.38, 10.0),
		C.step(0.7, 0.32, R_BRUSH, L_SCROLL, C.R_SPREAD, C.L_SPREAD, F.FIGHT, F.FIGHT, 0.0, 0.0, 0.38, 0.0),
		{"len": 1.15, "hit": 0.62, "keys": [
			C.t(0.0, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.24, 0.5, 0, 14, R_BRUSH, L_SCROLL, F.LOW),
			C.t(0.5, 0.52, -30, 16, R_STROKE, L_SCROLL, F.LOW),
			C.t(0.62, 0.42, 20, 8, R_BRUSH, L_SCROLL, F.FIGHT),
			C.t(0.9, 0.4, 10, 6, R_STROKE, L_SCROLL, F.FIGHT),
			C.t(1.15, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
