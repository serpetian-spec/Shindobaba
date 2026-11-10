extends RefCounted
## Kan soyu tarzı — Yōton (Lav Salınımı, Kurotsuchi / Rōshi). YAKIN-ORTA. Lav ateş değildir: oyunun gerçek lav sistemi
## (VFX.lava_mat "molten" yumruk kabuğu, lava_splash / goo_drops yapışkan sarı-turuncu damla + koyu kaya parçası) ve
## Kurotsuchi'nin kireci (Sekkaigyō: ağızdan gri-beyaz yapışkan kireç akışı, VfxSerpent goo + lava_mat "lime"; değdiği yer sertleşip bağlar).
## Kanon (Narutopedia "Kurotsuchi"): kireci ağızdan püskürtür, sertleşen kireç rakibi hapseder; Rōshi Yōton'u yumruğuna sarar.
## 1 lav sarılı sağ yumruk, 2 sol kroşe (lav sıçrar), 3 Sekkaigyō: ağızdan kireç (yavaşlatır, hedef kireçlenir),
## 4 avuç darbesi: kireçlenmiş hedefte kireç taşa döner (bağlar), 5 Shakugaryūgan: ağızdan üç erimiş kaya,
## 6 bitiriş: kireç ile hedef hapsedilir -> atılıp Shakugaikoken lav yumruğu kabuğu kırar.

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")

const L_HOOK := {"LeftUpperArm": Vector3(0.45, 0.15, 0.88), "LeftLowerArm": Vector3(-0.85, 0.1, 0.5)}


static func steps() -> Array:
	return [
		C.step(0.5, 0.24, C.R_COCK, C.L_GUARD, C.R_PUNCH, C.L_GUARD, F.SHIFT, F.PIVOT, -26.0, 20.0, 0.45, 12.0),
		C.step(0.55, 0.26, C.R_GUARD, C.L_COCK, C.R_GUARD, L_HOOK, F.FIGHT, F.PIVOT_L, 30.0, -34.0, 0.42, 12.0),
		C.step(0.7, 0.36, C.R_MOUTH, C.L_GUARD, C.R_MOUTH, C.L_HIP, F.SHIFT, F.STEPIN, -8.0, 4.0, 0.4, 18.0),
		C.step(0.55, 0.26, C.R_COCK, C.L_GUARD, C.R_PALM, C.L_GUARD, F.SHIFT, F.STEPIN, -20.0, 14.0, 0.45, 14.0),
		C.step(0.7, 0.34, C.R_SEAL, C.L_SEAL, C.R_MOUTH, C.L_SEAL, F.FIGHT, F.SHIFT, 0.0, -6.0, 0.42, -6.0),
		{"len": 1.25, "hit": 0.36, "keys": [   # 6 kireç püskürt (0.36) -> kol geri, atılıp lav yumruğu (0.72)
			C.t(0.0, 0.42, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.2, 0.45, -6, -6, C.R_MOUTH, C.L_GUARD, F.SHIFT),
			C.t(0.36, 0.42, -4, 16, C.R_MOUTH, C.L_HIP, F.STEPIN),
			C.t(0.54, 0.5, -28, -6, C.R_COCK, C.L_GUARD, F.SHIFT),
			C.t(0.72, 0.5, 24, 24, C.R_PUNCH, C.L_BACK, F.STEPIN),
			C.t(0.98, 0.48, 20, 20, C.R_PUNCH, C.L_BACK, F.PIVOT),
			C.t(1.25, 0.42, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
