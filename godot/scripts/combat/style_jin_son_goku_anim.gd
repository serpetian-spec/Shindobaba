extends RefCounted
## Jinchūriki tarzı — Son Gokū (Dört Kuyruk, Rōshi). YAKIN. Görseller oyunun gerçek lav sistemi (VFX.lava_mat / lava_splash /
## goo_drops "molten" / lava_ball, BijuuArts._kakogan / _funkatsu / _lava_pool). Kanon: Rōshi Yōton'u yumruklarına sarar,
## lav kayaları fırlatır, yerden lav fışkırtır; lav ateş değildir — yapışkan, yavaş, altında kırık kaya.
## 1-2 lav yumruğu (sağ/sol: lav sıçrar, yakar), 3 Yōton: Kakōgan (küçük lav kayaları), 4 Funkatsu (hedefin altından lav),
## 5 lav kabuğu sarsıntısı (çevre), 6 bitiriş: lav yumruğu yere — erimiş yarık + lav gölü.

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")


static func steps() -> Array:
	return [
		C.step(0.5, 0.24, C.R_COCK, C.L_GUARD, C.R_PUNCH, C.L_GUARD, F.SHIFT, F.PIVOT, -26.0, 20.0, 0.45, 12.0),
		C.step(0.5, 0.24, C.R_GUARD, C.L_COCK, C.R_GUARD, C.L_PUNCH, F.FIGHT, F.PIVOT_L, 22.0, -20.0, 0.45, 12.0),
		C.step(0.6, 0.3, C.R_LOW, C.L_GUARD, C.R_UPPER, C.L_GUARD, F.LOW, F.STEPIN, -10.0, 10.0, 0.55, 16.0),
		C.step(0.65, 0.32, C.R_HIGH, C.L_HIGH, C.R_GROUND, C.L_GROUND, F.FIGHT, F.LOW, 0.0, 0.0, 0.55, 26.0),
		C.step(0.6, 0.3, C.R_SEAL, C.L_SEAL, C.R_SPREAD, C.L_SPREAD, F.FIGHT, F.LOW, 0.0, 0.0, 0.5, 0.0),
		{"len": 1.15, "hit": 0.64, "keys": [
			C.t(0.0, 0.42, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.26, 0.3, -24, -12, C.R_SKY, C.L_GUARD, F.HOP),
			C.t(0.54, 0.34, -26, -14, C.R_SKY, C.L_GUARD, F.HOP),
			C.t(0.64, 0.9, 12, 40, C.R_GROUND, C.L_BACK, F.LOW),
			C.t(0.94, 0.85, 10, 36, C.R_GROUND, C.L_BACK, F.LOW),
			C.t(1.15, 0.42, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
