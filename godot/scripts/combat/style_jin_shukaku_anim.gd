extends RefCounted
## Jinchūriki tarzı — Shukaku (Bir Kuyruk). YAKIN-ORTA. Sabaku klan tarzından (uzaktan kum) farklı: canavarın kendisi —
## kısmi dönüşüm, rüzgâr ve kum. Görseller oyunun gerçek bijū sistemi (BijuuArts): Renkūdan hava mermisi, Sabaku Taisō kum
## dalgası, Suna no Tate kum kalkanı, kum tabutu; kendi kolu kumla kaplanıp büyür (SandCoat + PoseOverlay.grow).
## Kanon: Gaara'nın kısmi Shukaku dönüşümü — kumdan dev pençe kol, karından hava basıncı (Fūton: Renkūdan), kum dalgası.
## 1 kum pençe savuruşu (kol kaplanır/büyür), 2 pençe kavrama (kum tabutu), 3 Fūton: Renkūdan (küçük hava mermisi),
## 4 Sabaku Taisō (önden kum dalgası), 5 Suna no Tate (kalkan + sarsma), 6 bitiriş: kum pençe yere çarpar + büyük Renkūdan.

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")


static func steps() -> Array:
	return [
		C.step(0.6, 0.3, C.R_HIGH, C.L_GUARD, C.R_SWEEP_IN, C.L_GUARD, F.SHIFT, F.PIVOT, -40.0, 40.0, 0.45, 14.0),
		C.step(0.6, 0.3, C.R_BACK, C.L_GUARD, C.R_REACH, C.L_GUARD, F.SHIFT, F.STEPIN, -16.0, 10.0, 0.42, 16.0),
		C.step(0.6, 0.3, C.R_SEAL, C.L_SEAL, C.R_PALM, C.L_PALM, F.FIGHT, F.STEPIN, 0.0, 0.0, 0.42, -6.0),
		C.step(0.6, 0.3, C.R_HIGH, C.L_HIGH, C.R_GROUND, C.L_GROUND, F.FIGHT, F.LOW, 0.0, 0.0, 0.55, 26.0),
		C.step(0.6, 0.3, C.R_SEAL, C.L_SEAL, C.R_SPREAD, C.L_SPREAD, F.FIGHT, F.FIGHT, 0.0, 0.0, 0.4, 0.0),
		{"len": 1.2, "hit": 0.66, "keys": [
			C.t(0.0, 0.4, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.26, 0.3, -20, -12, C.R_SKY, C.L_GUARD, F.SHIFT),
			C.t(0.56, 0.32, -24, -14, C.R_SKY, C.L_GUARD, F.SHIFT),
			C.t(0.66, 0.85, 12, 40, C.R_GROUND, C.L_BACK, F.LOW),
			C.t(0.98, 0.8, 10, 36, C.R_GROUND, C.L_BACK, F.LOW),
			C.t(1.2, 0.4, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
