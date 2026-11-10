extends RefCounted
## Kan soyu tarzı — Shakuton (Kavurucu Salınım, Pakura). ORTA. Görseller oyunun gerçek Shakuton sistemi: VFX.scorch_orb
## (kızıl-beyaz kavurucu küre), PathJutsu._scorch_trail (küre izi), _scorch_hit (alev YOK: kızıl parlama + bedenden fışkıran
## beyaz buhar — beden suyu buharlaşır). Kanon (Narutopedia "Pakura"): küreler bedeninin çevresinde süzülür, hedefe yapışıp
## içindeki suyu buharlaştırır (Kajōsatsu: kurutup öldürür); yakın dövüşçü değil.
## 1-2 sağ/sol elden süzülen küre, 3 küreler bedenin çevresinde döner (yaklaşanı kavurur), 4 iki küre iki yandan kapanır,
## 5 küre hedefe yapışıp suyunu çeker (uzun yavaşlama), 6 bitiriş Kajōsatsu: hedefin çevresine dizilen beş küre kapanır.

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")

const L_THROW_BACK := {"LeftUpperArm": Vector3(0.6, 0.55, -0.55), "LeftLowerArm": Vector3(0.2, 0.8, 0.5)}
const L_THROW := {"LeftUpperArm": Vector3(0.1, 0.15, 0.98), "LeftLowerArm": Vector3(-0.05, 0.05, 1)}


static func steps() -> Array:
	return [
		C.step(0.5, 0.24, C.R_THROW_BACK, C.L_GUARD, C.R_THROW, C.L_GUARD, F.SHIFT, F.PIVOT, -20.0, 12.0, 0.4, 8.0),
		C.step(0.5, 0.24, C.R_GUARD, L_THROW_BACK, C.R_GUARD, L_THROW, F.FIGHT, F.PIVOT_L, 20.0, -12.0, 0.4, 8.0),
		C.step(0.7, 0.34, C.R_SEAL, C.L_SEAL, C.R_SPREAD, C.L_SPREAD, F.FIGHT, F.LOW, -20.0, 30.0, 0.5, 0.0),
		C.step(0.7, 0.34, C.R_SPREAD, C.L_SPREAD, C.R_REACH, C.L_REACH, F.SHIFT, F.STEPIN, 0.0, 0.0, 0.42, 10.0),
		C.step(0.75, 0.38, C.R_HIGH, C.L_GUARD, C.R_PALM, C.L_GUARD, F.SHIFT, F.PIVOT, -10.0, 10.0, 0.4, 10.0),
		{"len": 1.2, "hit": 0.66, "keys": [   # 6 Kajōsatsu: iki el göğe (küreler toplanır) -> avuçlar öne kapanır
			C.t(0.0, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.26, 0.3, 0, -14, C.R_SKY, C.L_SKY, F.FIGHT),
			C.t(0.52, 0.3, 0, -16, C.R_SKY, C.L_SKY, F.FIGHT),
			C.t(0.66, 0.42, 0, 12, C.R_REACH, C.L_REACH, F.STEPIN),
			C.t(0.95, 0.42, 0, 10, C.R_REACH, C.L_REACH, F.STEPIN),
			C.t(1.2, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
