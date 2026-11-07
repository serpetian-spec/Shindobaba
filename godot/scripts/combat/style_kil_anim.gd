extends RefCounted
## Yol tarzı — Patlayıcı Kil (Deidara). ORTA-UZAK. Görseller oyunun gerçek kil sistemi: ClayArt kuş/örümcek/bebek figürleri,
## VFX.clay_blast patlaması. Kanon: avuçlardaki ağızlar kili chakrayla yoğurur, figür canlanır, "Katsu!" mühürüyle patlar.
## 1-2 avuç ağzından kil örümcekler fırlatılır (sağ/sol), hedefe yapışıp patlar, 3 kil kuş süzülüp dalar, 4 Jirai: hedefin
## altına gömülen kil mayın patlar, 5 kuş dalgası (üç kuş), 6 Katsu! (bitiriş): tek mühür, dev kil bebek hedefe düşer, büyük patlama.

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")
const R_TIGER := {"RightUpperArm": Vector3(-0.2, -0.55, 0.81), "RightLowerArm": Vector3(0.45, 0.75, 0.48)}   # tek el mühürü (iki parmak yüz önünde)


static func steps() -> Array:
	return [
		C.step(0.5, 0.22, C.R_BACK, C.L_GUARD, C.R_THROW, C.L_GUARD, F.SHIFT, F.PIVOT, -24.0, 20.0, 0.38, 10.0),   # 1 örümcek (sağ)
		C.step(0.5, 0.22, C.R_GUARD, C.L_BACK, C.R_GUARD, C.L_PUNCH, F.SHIFT, F.PIVOT_L, 24.0, -20.0, 0.38, 10.0), # 2 örümcek (sol)
		C.step(0.65, 0.32, C.R_THROW_BACK, C.L_GUARD, C.R_SKY, C.L_GUARD, F.SHIFT, F.FIGHT, -10.0, 4.0, 0.32, -12.0), # 3 kuş yukarı salınır
		C.step(0.7, 0.34, C.R_GUARD, C.L_GUARD, C.R_GROUND, C.L_GUARD, F.FIGHT, F.LOW, 0.0, 0.0, 0.62, 26.0),       # 4 mayın: avuç yere
		C.step(0.75, 0.36, C.R_SPREAD, C.L_SPREAD, C.R_SKY, C.L_SKY, F.SHIFT, F.FIGHT, 0.0, 0.0, 0.3, -14.0),       # 5 kuş dalgası
		{"len": 1.1, "hit": 0.6, "keys": [   # 6 Katsu!: tek el mühürü uzun tutulur -> patlama
			C.t(0.0, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.24, 0.38, -6, -4, R_TIGER, C.L_HIP, F.FIGHT),
			C.t(0.6, 0.38, -6, -6, R_TIGER, C.L_HIP, F.FIGHT),
			C.t(0.75, 0.4, 0, 8, R_TIGER, C.L_HIP, F.SHIFT),
			C.t(1.1, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
