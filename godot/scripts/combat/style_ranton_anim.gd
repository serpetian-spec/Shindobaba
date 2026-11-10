extends RefCounted
## Kan soyu tarzı — Ranton (Fırtına Salınımı, Darui). ORTA-UZAK. Görseller oyunun gerçek Ranton sistemi: LightRibbon ışın şeridi
## (Reizā Sākasu'nun kıvrılan lazerleri, şimşek gibi dallanmaz), VFX.storm_orb (avuçta fırtına ışığı), RantonArt.hound/panther,
## VFX.black_bolt (Kuroi Kaminari'nin siyah-beyaz şimşeği). Kanon (Narutopedia "Darui"): Darui rakibe koşmaz; avucundan ışın
## atar, Kōga'yı zikzak koşturur, iki eli öne birleştirip kara şimşek salar, bitirişi Kuro Pansā (kara panter).
## 1 sağ avuçtan tek lazer, 2 sol avuçtan lazer, 3 Kōga: el aşağı süpürülür, yerde zikzak koşan ışık tazısı (sersem),
## 4 Kuroi Kaminari: avuçlar birleşip öne, düz kara şimşek hattı, 5 Reizā Sākasu: kollar açılıp öne kapanır — beş kıvrık ışın,
## 6 Kuro Pansā (bitiriş): sol el sağ bileği tutar, avuçtan kara şimşek panter fırlar, dişleri hedefe kapanır (felç).

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")

const L_BRACE := {"LeftUpperArm": Vector3(0.1, -0.4, 0.9), "LeftLowerArm": Vector3(-0.6, 0.3, 0.74)}   # sol el sağ bileği tutar


static func steps() -> Array:
	return [
		C.step(0.5, 0.24, C.R_COCK, C.L_GUARD, C.R_PALM, C.L_GUARD, F.SHIFT, F.PIVOT, -20.0, 14.0, 0.4, 8.0),
		C.step(0.5, 0.24, C.R_GUARD, C.L_COCK, C.R_GUARD, C.L_PALM, F.FIGHT, F.PIVOT_L, 20.0, -14.0, 0.4, 8.0),
		C.step(0.65, 0.32, C.R_BACK, C.L_GUARD, C.R_LOW, C.L_GUARD, F.SHIFT, F.LOW, -30.0, 10.0, 0.55, 18.0),
		C.step(0.8, 0.42, C.R_SEAL, C.L_SEAL, C.R_PALM, C.L_PALM, F.SHIFT, F.STEPIN, 0.0, 0.0, 0.42, 12.0),
		C.step(0.8, 0.4, C.R_SPREAD, C.L_SPREAD, C.R_REACH, C.L_REACH, F.FIGHT, F.STEPIN, 0.0, 0.0, 0.4, 6.0),
		{"len": 1.2, "hit": 0.62, "keys": [   # 6 Kuro Pansā: avuçlar göğüste chakra toplar -> sol el bileği tutar, sağ avuç öne
			C.t(0.0, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.22, 0.45, -12, -8, C.R_SEAL, C.L_SEAL, F.SHIFT),
			C.t(0.48, 0.48, -16, -10, C.R_COCK, C.L_SEAL, F.SHIFT),
			C.t(0.62, 0.42, 10, 16, C.R_PALM, L_BRACE, F.STEPIN),
			C.t(0.92, 0.42, 8, 14, C.R_PALM, L_BRACE, F.STEPIN),
			C.t(1.2, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
