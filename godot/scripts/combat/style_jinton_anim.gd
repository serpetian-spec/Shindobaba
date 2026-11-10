extends RefCounted
## Kan soyu tarzı — Jinton (Toz Salınımı, kekkei tōta; Ōnoki / Mū). UZAK, ağır ve yavaş. Görseller oyunun gerçek Jinton
## sistemi: VFX.dust_cube (iki el arasında beyaz çekirdekli saydam küp), VFX.mat_dust, beyaz parlama + ince beyaz toza ayrışma
## (ClanJutsu._atomize'deki parçacık). Kanon (Narutopedia "Ōnoki"): avuçları arasında küp/koni kurar, hedefte genişleyip
## içindekini atomlarına ayırır; Keijūgan ile hafifleyip süzülür, Kajūgan ile dokunduğunu ağırlaştırır; teknik çok chakra yer.
## 1 küçük toz küpü, 2 Keijūgan: hafifleyip geri süzülür (vuruş yok), 3 Jinton Ensui: ince toz konisi hattı deler,
## 4 Kajūgan: avuç aşağı — hedef ağırlaşır, yere çakılır, 5 büyük küp, 6 bitiriş Genkai Hakuri: uzun kurulum, hedefte dev küp.

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")

const L_BRACE := {"LeftUpperArm": Vector3(0.1, -0.4, 0.9), "LeftLowerArm": Vector3(-0.6, 0.3, 0.74)}
const R_FRAME := {"RightUpperArm": Vector3(-0.3, -0.55, 0.78), "RightLowerArm": Vector3(0.55, 0.35, 0.76)}   # avuçlar karşılıklı: küp çerçevesi
const L_FRAME := {"LeftUpperArm": Vector3(0.3, -0.55, 0.78), "LeftLowerArm": Vector3(-0.55, 0.35, 0.76)}


static func steps() -> Array:
	return [
		C.step(0.8, 0.44, R_FRAME, L_FRAME, C.R_REACH, L_FRAME, F.FIGHT, F.SHIFT, 0.0, -6.0, 0.38, 4.0),
		C.step(0.55, 0.22, C.R_GUARD, C.L_GUARD, C.R_LOW, C.L_LOW, F.FIGHT, F.HOP, 0.0, 0.0, 0.3, -6.0),
		C.step(0.9, 0.48, R_FRAME, L_FRAME, C.R_REACH, L_BRACE, F.SHIFT, F.STEPIN, 0.0, 0.0, 0.4, 8.0),
		C.step(0.75, 0.38, C.R_HIGH, C.L_GUARD, C.R_DOWN, C.L_GUARD, F.FIGHT, F.LOW, 0.0, 0.0, 0.5, 18.0),
		C.step(0.95, 0.5, R_FRAME, L_FRAME, C.R_REACH, C.L_REACH, F.SHIFT, F.STEPIN, 0.0, 0.0, 0.4, 8.0),
		{"len": 1.6, "hit": 0.92, "keys": [   # 6 Genkai Hakuri: avuçlar uzun süre küpü kurar -> iki kol öne açılır
			C.t(0.0, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.3, 0.42, 0, -6, R_FRAME, L_FRAME, F.SHIFT),
			C.t(0.78, 0.44, 0, -8, R_FRAME, L_FRAME, F.SHIFT),
			C.t(0.92, 0.4, 0, 12, C.R_REACH, C.L_REACH, F.STEPIN),
			C.t(1.3, 0.4, 0, 10, C.R_REACH, C.L_REACH, F.STEPIN),
			C.t(1.6, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
