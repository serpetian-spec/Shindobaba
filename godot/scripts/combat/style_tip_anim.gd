extends RefCounted
## Yol tarzı — Şifacı (Tıbbi Ninja: Tsunade / Sakura / Kabuto). YAKIN. Görseller oyunun gerçek tıbbi sistemleri: Chakra Neşteri
## bıçağı (p_chakura_no_mesu ile aynı mavi bolt malzemesi), Ranshinshō yeşil şimşekli avuç, Dokugiri mor zehir akışı (stream_fx),
## Shōsen yeşil şifa avucu, Ōkashō zemin yarığı (VFX.cracks/debris). Kanon: tıbbi ninja kası/siniri keser (görünmez yara),
## sinir karıştırır, zehir sisi üfler; Tsunade/Sakura chakrayı yumrukta toplayıp yeri yarar.
## 1-2 Chakra Neşteri (sağ/sol kesik: kas kesilir, yavaşlar), 3 Ranshinshō (sinir karışır, sersem), 4 Dokugiri (zehir),
## 5 Shōsen emişi (avuç değer, rakipten chakra çekip seni onarır), 6 bitiriş Ōkashō: yere yumruk, yer yarılır.

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")


static func steps() -> Array:
	return [
		C.step(0.45, 0.22, C.R_SWEEP_OUT, C.L_GUARD, C.R_SWEEP_IN, C.L_GUARD, F.SHIFT, F.PIVOT, -26.0, 26.0, 0.4, 8.0),
		C.step(0.45, 0.22, C.R_GUARD, C.L_BACK, C.R_GUARD, C.L_PALM, F.FIGHT, F.PIVOT_L, 22.0, -22.0, 0.4, 8.0),
		C.step(0.55, 0.26, C.R_COCK, C.L_GUARD, C.R_PALM, C.L_GUARD, F.SHIFT, F.STEPIN, -18.0, 14.0, 0.42, 12.0),
		C.step(0.6, 0.3, C.R_MOUTH, C.L_HIP, C.R_MOUTH, C.L_HIP, F.SHIFT, F.FIGHT, 0.0, 0.0, 0.38, 6.0),
		C.step(0.6, 0.3, C.R_GUARD, C.L_GUARD, C.R_PALM, C.L_PALM, F.FIGHT, F.STEPIN, 0.0, 0.0, 0.42, 10.0),
		{"len": 1.1, "hit": 0.62, "keys": [
			C.t(0.0, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.22, 0.3, -24, -10, C.R_HIGH, C.L_GUARD, F.HOP),
			C.t(0.5, 0.36, -20, -14, C.R_HIGH, C.L_GUARD, F.HOP),
			C.t(0.62, 0.9, 10, 40, C.R_GROUND, C.L_BACK, F.LOW),
			C.t(0.88, 0.85, 8, 36, C.R_GROUND, C.L_BACK, F.LOW),
			C.t(1.1, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
