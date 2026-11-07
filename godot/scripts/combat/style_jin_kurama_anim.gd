extends RefCounted
## Jinchūriki tarzı — Kurama (Dokuz Kuyruk). YAKIN-ORTA. Görseller oyunun gerçek sistemi (BijuuArts._chakra_kaina turuncu
## chakra kolu, _biju_hoko kükreme şok dalgası, _bijudama_rasengan, Kurama pençe izi = BijuuArts._claw_marks "fire").
## Kanon: Kurama örtüsündeki jinchūriki pençeyle savaşır, örtüden uzanan chakra kollarıyla yakalayıp çarpar, kükremeyle iter,
## Bijūdama ile Rasengan'ı birleştirir.
## 1-2 chakra pençesi (sağ/sol, turuncu tilki ateşi izleri), 3 chakra kolu kavrayıp yere çarpar, 4 Bijū Hōkō (kükreme dalgası),
## 5 iki chakra kolu birden (çapraz), 6 bitiriş: küçük Bijūdama Rasengan.

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")
const R_CLAW := {"RightUpperArm": Vector3(-0.5, 0.45, 0.74), "RightLowerArm": Vector3(-0.2, 0.3, 0.93)}
const L_CLAW := {"LeftUpperArm": Vector3(0.5, 0.45, 0.74), "LeftLowerArm": Vector3(0.2, 0.3, 0.93)}


static func steps() -> Array:
	return [
		C.step(0.45, 0.22, R_CLAW, C.L_GUARD, C.R_DOWN, C.L_GUARD, F.SHIFT, F.PIVOT, -24.0, 24.0, 0.5, 18.0),
		C.step(0.45, 0.22, C.R_GUARD, L_CLAW, C.R_GUARD, C.L_LOW, F.FIGHT, F.PIVOT_L, 24.0, -24.0, 0.5, 18.0),
		C.step(0.65, 0.32, C.R_BACK, C.L_GUARD, C.R_REACH, C.L_GUARD, F.SHIFT, F.STEPIN, -14.0, 10.0, 0.45, 14.0),
		C.step(0.6, 0.3, C.R_LOW, C.L_LOW, C.R_SPREAD, C.L_SPREAD, F.LOW, F.LOW, 0.0, 0.0, 0.6, -14.0),
		C.step(0.65, 0.32, C.R_BACK, C.L_BACK, C.R_REACH, C.L_REACH, F.SHIFT, F.STEPIN, 0.0, 0.0, 0.45, 14.0),
		{"len": 1.2, "hit": 0.7, "keys": [
			C.t(0.0, 0.4, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.3, 0.44, -18, 8, C.R_PALM, C.L_SEAL, F.SHIFT),
			C.t(0.6, 0.44, -22, 10, C.R_PALM, C.L_SEAL, F.SHIFT),
			C.t(0.7, 0.42, 16, 22, C.R_PALM, C.L_GUARD, F.STEPIN),
			C.t(0.98, 0.4, 12, 18, C.R_PALM, C.L_GUARD, F.STEPIN),
			C.t(1.2, 0.4, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
