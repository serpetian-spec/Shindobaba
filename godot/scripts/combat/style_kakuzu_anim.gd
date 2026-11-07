extends RefCounted
## Yol tarzı — Toprak Kini (Kakuzu, Jiongu). YAKIN-ORTA. Görseller oyunun gerçek sistemleri: kara iplikler (PathJutsu.wavy_tether),
## taş ten (PathJutsu._stone_skin = Domu), maskeli canavarlar (PathJutsu._mask_beast / KakuzuArt), alev seli (fire_stream),
## rüzgâr akışı (stream_fx + mat_wind). Kanon: Kakuzu kolunu ipliklerle fırlatıp yakalar, iplik demetiyle kırbaçlar, Domu ile
## taşlaşıp ezer, sırtındaki maskeler canavar olup elementel saldırır; Fūton Atsugai ile Katon Zukokku birleşip alev fırtınası olur.
## 1 iplik kırbacı, 2 uçan kol (kol ipliklerle fırlar, yakalar, çeker), 3 Domu yumruğu (taş ten, kalkan), 4 Katon maskesi (Zukokku),
## 5 Fūton maskesi (Atsugai), 6 bitiriş: iki maske birden — rüzgâr alevi büyütür (birleşik alev fırtınası).

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")


static func steps() -> Array:
	return [
		C.step(0.55, 0.26, C.R_BACK, C.L_GUARD, C.R_SWEEP_OUT, C.L_GUARD, F.SHIFT, F.PIVOT, -30.0, 30.0, 0.38, 6.0),
		C.step(0.65, 0.3, C.R_COCK, C.L_GUARD, C.R_REACH, C.L_GUARD, F.SHIFT, F.STEPIN, -20.0, 12.0, 0.4, 12.0),
		C.step(0.7, 0.34, C.R_COCK, C.L_GUARD, C.R_PUNCH, C.L_GUARD, F.SHIFT, F.STEPIN, -24.0, 16.0, 0.5, 16.0),
		C.step(0.6, 0.3, C.R_GUARD, C.L_GUARD, C.R_SEAL, C.L_SEAL, F.FIGHT, F.FIGHT, 0.0, 0.0, 0.42, -6.0),
		C.step(0.6, 0.3, C.R_GUARD, C.L_GUARD, C.R_SEAL, C.L_SEAL, F.FIGHT, F.LOW, 0.0, 0.0, 0.5, -4.0),
		{"len": 1.2, "hit": 0.66, "keys": [
			C.t(0.0, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.25, 0.46, 0, -10, C.R_SEAL, C.L_SEAL, F.LOW),
			C.t(0.56, 0.48, 0, -12, C.R_SEAL, C.L_SEAL, F.LOW),
			C.t(0.66, 0.42, 0, 10, C.R_SPREAD, C.L_SPREAD, F.STEPIN),
			C.t(0.98, 0.42, 0, 8, C.R_SPREAD, C.L_SPREAD, F.STEPIN),
			C.t(1.2, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
