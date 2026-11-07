extends RefCounted
## Yol tarzı — Yılan (Orochimaru, Sen'eijashu). ORTA. Görseller oyunun gerçek yılan sistemi: yenden çıkan yılanlar
## (SleeveSnake / PathJutsu.sleeve_snake), Kusanagi (silah modeli), yılan çağrısı (SummonModels "snake_swarm"). Kanon: yılanlar
## kolun yeninden fırlar, sarar ve zehirler; Kusanagi ağızdan uzar; beden uzayıp atılır.
## 1-2 Sen'ei Jashu (sağ/sol yen: iki yılan ısırır, zehir), 3 Sen'ei Tajashu (dört yılan sarar, bağlar), 4 Kusanagi: ağızdan
## kılıç uzayıp saplanır, 5 yılan atılışı (beden esneyip ısırır), 6 Mandara: yerden yılan sürüsü fışkırıp hedefi yutar (bitiriş).

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")


static func steps() -> Array:
	return [
		C.step(0.55, 0.26, C.R_BACK, C.L_GUARD, C.R_REACH, C.L_GUARD, F.SHIFT, F.STEPIN, -16.0, 12.0, 0.38, 10.0),
		C.step(0.55, 0.26, C.R_GUARD, C.L_BACK, C.R_GUARD, C.L_REACH, F.SHIFT, F.STEPIN, 16.0, -12.0, 0.38, 10.0),
		C.step(0.75, 0.34, C.R_SEAL, C.L_SEAL, C.R_REACH, C.L_REACH, F.FIGHT, F.STEPIN, 0.0, 0.0, 0.4, 12.0),
		C.step(0.65, 0.3, C.R_GUARD, C.L_GUARD, C.R_LOW, C.L_LOW, F.SHIFT, F.STEPIN, 0.0, 0.0, 0.42, 24.0),
		C.step(0.65, 0.3, C.R_LOW, C.L_LOW, C.R_REACH, C.L_GUARD, F.LOW, F.STEPIN, 0.0, 0.0, 0.5, 30.0),
		{"len": 1.1, "hit": 0.6, "keys": [
			C.t(0.0, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.24, 0.5, 0, 14, C.R_SEAL, C.L_SEAL, F.LOW),
			C.t(0.54, 0.62, 0, 26, C.R_GROUND, C.L_GROUND, F.LOW),
			C.t(0.9, 0.58, 0, 22, C.R_GROUND, C.L_GROUND, F.LOW),
			C.t(1.1, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
