extends RefCounted
## Jinchūriki tarzı — Isobu (Üç Kuyruk, Yagura). ORTA. Görseller oyunun gerçek bijū sistemi (BijuuArts): yerden fışkıran mercan
## (_coral: çarpışan dikenli mercan), mercan tarlası (_sango: bağlar), dikenli kabuk yuvarlanışı (_shell_roll), yanılsama sisi
## (_kiri_genjutsu), su sıçraması (VFX.splash). Kanon: Isobu mercanla hapseder, kabuğuna çekilip yuvarlanır, sisle yanılsama yapar.
## 1 mercan diken (hedefin altından), 2 su avucu itişi (sıçrama), 3 mercan tarlası (küçük, bağlar), 4 kabuk yuvarlanışı,
## 5 yanılsama sisi (küçük), 6 bitiriş: hedefi çevreleyen mercan halkası kapanır + su patlaması.

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")


static func steps() -> Array:
	return [
		C.step(0.55, 0.26, C.R_GUARD, C.L_GUARD, C.R_GROUND, C.L_GUARD, F.SHIFT, F.LOW, 0.0, 0.0, 0.5, 20.0),
		C.step(0.5, 0.24, C.R_COCK, C.L_GUARD, C.R_PALM, C.L_GUARD, F.SHIFT, F.STEPIN, -14.0, 10.0, 0.42, 10.0),
		C.step(0.65, 0.32, C.R_SEAL, C.L_SEAL, C.R_GROUND, C.L_GROUND, F.FIGHT, F.LOW, 0.0, 0.0, 0.6, 24.0),
		C.step(0.95, 0.2, C.R_LOW, C.L_LOW, C.R_LOW, C.L_LOW, F.LOW, F.LOW, 0.0, 0.0, 0.9, 40.0),
		C.step(0.6, 0.3, C.R_SEAL, C.L_SEAL, C.R_SPREAD, C.L_SPREAD, F.FIGHT, F.FIGHT, 0.0, 0.0, 0.4, 0.0),
		{"len": 1.15, "hit": 0.66, "keys": [
			C.t(0.0, 0.4, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.26, 0.5, 0, 12, C.R_SEAL, C.L_SEAL, F.LOW),
			C.t(0.56, 0.62, 0, 26, C.R_GROUND, C.L_GROUND, F.LOW),
			C.t(0.66, 0.4, 0, -6, C.R_SPREAD, C.L_SPREAD, F.FIGHT),
			C.t(0.95, 0.4, 0, -4, C.R_SPREAD, C.L_SPREAD, F.FIGHT),
			C.t(1.15, 0.4, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
