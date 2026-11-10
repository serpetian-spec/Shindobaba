extends RefCounted
## Kan soyu tarzı — Shōton (Kristal Salınımı, Guren). YAKIN-ORTA. Görseller oyunun gerçek Shōton sistemi: PathJutsu._crystal_cluster
## / _crystal_mat (pembe yarı saydam yüzlü kristal), _grow_crystal (yerden fışkıran küme), _crystal_shatter (kıymık), _crystal_prison
## (Gokakuro beşgen hapsi). Kanon (Narutopedia "Guren"): kolunu kristal kılıca/zırha çevirip keser, altıgen kristal shuriken atar,
## yerden kristal dikenler sürer, rakibi kristale hapsedip kristalle birlikte parçalar.
## 1-2 ön koldan büyüyen kristal kılıçla sağ/sol kesik (kanatır), 3 Kesshō Rokkaku Shuriken (üç altıgen kristal),
## 4 avuç yere: hedefe uzanan kristal diken sırası, 5 Suishō Hari: iki avuçtan kristal iğne yelpazesi,
## 6 bitiriş: Kesshō Gokakuro — hedef beşgen kristale hapsolur, kristal yumrukla hapis ve içindeki birlikte kırılır.

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")

const L_SWEEP_IN := {"LeftUpperArm": Vector3(-0.6, 0.1, 0.78), "LeftLowerArm": Vector3(-0.95, 0.15, 0.2)}
const L_SWEEP_OUT := {"LeftUpperArm": Vector3(0.95, 0.1, 0.3), "LeftLowerArm": Vector3(0.9, 0.15, 0.35)}


static func steps() -> Array:
	return [
		C.step(0.5, 0.24, C.R_SWEEP_OUT, C.L_GUARD, C.R_SWEEP_IN, C.L_GUARD, F.SHIFT, F.PIVOT, -30.0, 26.0, 0.42, 12.0),
		C.step(0.5, 0.24, C.R_GUARD, L_SWEEP_OUT, C.R_GUARD, L_SWEEP_IN, F.FIGHT, F.PIVOT_L, 30.0, -26.0, 0.42, 12.0),
		C.step(0.6, 0.3, C.R_THROW_BACK, C.L_GUARD, C.R_THROW, C.L_GUARD, F.SHIFT, F.PIVOT, -24.0, 16.0, 0.4, 10.0),
		C.step(0.7, 0.34, C.R_HIGH, C.L_GUARD, C.R_GROUND, C.L_GROUND, F.SHIFT, F.LOW, 0.0, 0.0, 0.6, 28.0),
		C.step(0.65, 0.32, C.R_SEAL, C.L_SEAL, C.R_PALM, C.L_PALM, F.FIGHT, F.STEPIN, 0.0, 0.0, 0.42, 12.0),
		{"len": 1.35, "hit": 0.5, "keys": [   # 6 mühür -> avuç öne (hapis 0.5) -> kristal yumrukla kırış (0.9)
			C.t(0.0, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.24, 0.42, 0, -6, C.R_SEAL, C.L_SEAL, F.SHIFT),
			C.t(0.5, 0.42, 6, 12, C.R_PALM, C.L_SEAL, F.STEPIN),
			C.t(0.72, 0.5, -26, -6, C.R_COCK, C.L_GUARD, F.SHIFT),
			C.t(0.9, 0.48, 24, 24, C.R_PUNCH, C.L_BACK, F.STEPIN),
			C.t(1.12, 0.46, 20, 20, C.R_PUNCH, C.L_BACK, F.PIVOT),
			C.t(1.35, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
