extends RefCounted
## Jinchūriki tarzı — Saiken (Altı Kuyruk, Utakata). ORTA-UZAK. Görseller oyunun gerçek köpük/asit sistemi (BijuuArts._fukuso
## köpük-asit baloncukları, _acid_mist asit sisi, _slime sümük gölü, _corrode aşınma). Kanon: Utakata köpük baloncuklarıyla
## dövüşür — patlayan baloncuklar, hedefi içine hapseden baloncuk, Saiken'in aşındırıcı sümüğü.
## 1-2 köpük baloncukları (sağ/sol avuç), 3 asit sisi (küçük), 4 sümük gölü (saplar), 5 baloncuk hapsi (hedefi içine alır),
## 6 bitiriş: hedefin çevresinde baloncuk halkası art arda patlar (aşındırır).

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")


static func steps() -> Array:
	return [
		C.step(0.5, 0.24, C.R_MOUTH, C.L_GUARD, C.R_PALM, C.L_GUARD, F.SHIFT, F.FIGHT, -10.0, 10.0, 0.38, 4.0),
		C.step(0.5, 0.24, C.R_GUARD, C.L_GUARD, C.R_GUARD, C.L_PALM, F.FIGHT, F.FIGHT, 10.0, -10.0, 0.38, 4.0),
		C.step(0.6, 0.3, C.R_MOUTH, C.L_HIP, C.R_SPREAD, C.L_SPREAD, F.SHIFT, F.FIGHT, 0.0, 0.0, 0.4, 0.0),
		C.step(0.6, 0.3, C.R_SEAL, C.L_SEAL, C.R_GROUND, C.L_GROUND, F.FIGHT, F.LOW, 0.0, 0.0, 0.55, 22.0),
		C.step(0.65, 0.32, C.R_GUARD, C.L_GUARD, C.R_REACH, C.L_REACH, F.SHIFT, F.STEPIN, 0.0, 0.0, 0.4, 10.0),
		{"len": 1.1, "hit": 0.62, "keys": [
			C.t(0.0, 0.4, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.26, 0.42, 0, -6, C.R_MOUTH, C.L_SEAL, F.FIGHT),
			C.t(0.54, 0.42, 0, -8, C.R_MOUTH, C.L_SEAL, F.FIGHT),
			C.t(0.62, 0.42, 0, 8, C.R_SPREAD, C.L_SPREAD, F.STEPIN),
			C.t(0.9, 0.42, 0, 6, C.R_SPREAD, C.L_SPREAD, F.STEPIN),
			C.t(1.1, 0.4, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
