extends RefCounted
## Jinchūriki tarzı — Gyūki (Sekiz Kuyruk, Killer B'nin canavar örtüsü). YAKIN-ORTA. Hachibi YOL tarzından (yedi kılıç, Lariat)
## farklı: canavarın kendi chakrası — mor örtüden uzanan chakra kolları (BijuuArts._chakra_kaina mor), Takoashi Ude dokunaçları,
## Tako Bunshin (mürekkep bulutu + ahtapot klonları), küçük Bijūdama (BijuuArts._bijudama_rasengan mor).
## 1-2 örtüden chakra kolu darbesi, 3 iki dokunaç kavrayıp çarpar, 4 mürekkep bulutuyla Tako Bunshin (geri kaçış + klonlar),
## 5 dokunaç süpürmesi (çevre), 6 bitiriş: küçük Bijūdama.

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")


static func steps() -> Array:
	return [
		C.step(0.55, 0.26, C.R_COCK, C.L_GUARD, C.R_PUNCH, C.L_GUARD, F.SHIFT, F.PIVOT, -24.0, 20.0, 0.42, 12.0),
		C.step(0.55, 0.26, C.R_GUARD, C.L_COCK, C.R_GUARD, C.L_PUNCH, F.FIGHT, F.PIVOT_L, 22.0, -20.0, 0.42, 12.0),
		C.step(0.65, 0.32, C.R_HIGH, C.L_HIGH, C.R_GROUND, C.L_GROUND, F.FIGHT, F.LOW, 0.0, 0.0, 0.55, 26.0),
		C.step(0.6, 0.3, C.R_SEAL, C.L_SEAL, C.R_SEAL, C.L_SEAL, F.FIGHT, F.HOP, 0.0, 0.0, 0.4, -6.0),
		C.step(0.65, 0.3, C.R_SWEEP_OUT, C.L_SPREAD, C.R_SWEEP_IN, C.L_SPREAD, F.LOW, F.LOW, -60.0, 90.0, 0.6, 10.0),
		{"len": 1.2, "hit": 0.7, "keys": [
			C.t(0.0, 0.4, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.3, 0.46, 0, -8, C.R_MOUTH, C.L_SEAL, F.LOW),
			C.t(0.6, 0.48, 0, -10, C.R_MOUTH, C.L_SEAL, F.LOW),
			C.t(0.7, 0.42, 0, 20, C.R_PALM, C.L_PALM, F.STEPIN),
			C.t(0.98, 0.4, 0, 16, C.R_PALM, C.L_PALM, F.STEPIN),
			C.t(1.2, 0.4, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
