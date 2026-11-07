extends RefCounted
## Yol tarzı — Sekiz Kapı (Gōken, Gai/Lee). YAKIN. Görseller oyunun gerçek Sekiz Kapı teknikleri: Asakujaku alev yumrukları
## (VFX.fireball), Hirudora kaplan başı (PathJutsu._tiger_head), kapı açılınca yeşil buhar aurası. Ref: refs/kapi/*.png
## 1 Konoha Senpū (döner yüksek tekme), 2 Konoha Reppū (alçak süpürme), 3 Konoha Shōfū (dikey tekme: rakibi havaya kaldırır),
## 4 Kage Buyō + topuk inişi (peşinden sıçrar), 5 kapılar açılır — Asakujaku: alevli yumruk yağmuru, 6 Hirudora: avuçtan
## kaplan başı hava basıncı (bitiriş).

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")


static func steps() -> Array:
	return [
		C.step(0.55, 0.26, C.R_SPREAD, C.L_GUARD, C.R_SPREAD, C.L_SPREAD, F.PIVOT, C.KICK_HIGH_R, 40.0, -80.0, 0.32, -10.0),   # 1 Senpū
		C.step(0.55, 0.26, C.R_LOW, C.L_LOW, C.R_LOW, C.L_LOW, F.LOW, C.KICK_LOW_L, -40.0, 70.0, 0.72, 20.0),                # 2 Reppū
		C.step(0.6, 0.3, C.R_GUARD, C.L_GUARD, C.R_SPREAD, C.L_SPREAD, F.SHIFT, C.KICK_UP_R, 0.0, 0.0, 0.3, -18.0),         # 3 Shōfū
		{"len": 0.85, "hit": 0.55, "keys": [   # 4 Kage Buyō: sıçrar, havada toplanır -> topuk iner
			C.t(0.0, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.2, 0.3, 0, -10, C.R_HIGH, C.L_HIGH, F.HOP),
			C.t(0.45, 0.28, 0, -14, C.R_HIGH, C.L_HIGH, C.KICK_UP_R),
			C.t(0.55, 0.5, 0, 24, C.R_GUARD, C.L_GUARD, C.KICK_FRONT_R),
			C.t(0.85, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
		{"len": 0.95, "hit": 0.4, "keys": [   # 5 Asakujaku: yumruklar ardı ardına (iki kol sırayla)
			C.t(0.0, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.16, 0.45, -10, -6, C.R_COCK, C.L_COCK, F.SHIFT),
			C.t(0.3, 0.42, 14, 14, C.R_PUNCH, C.L_COCK, F.STEPIN),
			C.t(0.42, 0.42, -14, 14, C.R_COCK, C.L_PUNCH, F.STEPIN),
			C.t(0.54, 0.42, 14, 14, C.R_PUNCH, C.L_COCK, F.STEPIN),
			C.t(0.66, 0.42, -14, 14, C.R_COCK, C.L_PUNCH, F.STEPIN),
			C.t(0.95, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
		{"len": 1.15, "hit": 0.62, "keys": [   # 6 Hirudora: sırtını dönüp eller birleşir (kaplan ağzı) -> avuçlar öne patlar
			C.t(0.0, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.24, 0.5, 60, -6, C.R_SEAL, C.L_SEAL, F.LOW),
			C.t(0.52, 0.52, 70, -8, C.R_SEAL, C.L_SEAL, F.LOW),
			C.t(0.62, 0.44, 0, 22, C.R_PALM, C.L_PALM, F.STEPIN),
			C.t(0.92, 0.42, 0, 18, C.R_PALM, C.L_PALM, F.STEPIN),
			C.t(1.15, 0.35, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
