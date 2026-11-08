extends RefCounted
## Göz tarzı — Rinnegan (Altı Yol / Pain–Nagato). YAKIN-ORTA. Görseller oyunun gerçek sistemleri: kara chakra alıcısı
## (PathJutsu._receiver_rod / _receiver_pierce), Shinra Tensei çekirdeği (Jutsu.shinra_core), Banshō çekim çizgileri (WindFX.streak).
## Kanon: Tendō çubuğu yenden çıkarıp saplar, Banshō Ten'in ile rakibi çubuğa çeker; Asura Yolu ön kolunu roket gibi fırlatır;
## Shinra Tensei ile çevreyi iter; Gakidō avuçla chakrayı emer.
## 1 yenden çıkan kara alıcıyla saplama, 2 Banshō Ten'in: çek + çubuğa sapla, 3 Asura: ön kol roketi, 4 kısa Shinra Tensei,
## 5 Gakidō: avuçla kavrayıp chakra emme, 6 bitiriş: büyük Shinra Tensei.

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")


static func steps() -> Array:
	return [
		C.step(0.5, 0.22, C.R_COCK, C.L_GUARD, C.R_PUNCH, C.L_GUARD, F.SHIFT, F.STEPIN, -20.0, 14.0, 0.38, 8.0),
		C.step(0.6, 0.26, C.R_REACH, C.L_GUARD, C.R_COCK, C.L_GUARD, F.FIGHT, F.SHIFT, 0.0, -10.0, 0.4, 4.0),
		C.step(0.6, 0.28, C.R_THROW_BACK, C.L_GUARD, C.R_PUNCH, C.L_BACK, F.SHIFT, F.STEPIN, -30.0, 20.0, 0.42, 10.0),
		C.step(0.6, 0.26, C.R_SPREAD, C.L_SPREAD, C.R_PALM, C.L_PALM, F.FIGHT, F.LOW, 0.0, 0.0, 0.45, 6.0),
		C.step(0.65, 0.28, C.R_COCK, C.L_GUARD, C.R_REACH, C.L_GUARD, F.SHIFT, F.STEPIN, -14.0, 10.0, 0.4, 8.0),
		{"len": 1.1, "hit": 0.62, "keys": [
			C.t(0.0, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.3, 0.44, 0, -4, C.R_SKY, C.L_SKY, F.LOW),
			C.t(0.55, 0.46, 0, 6, C.R_SPREAD, C.L_SPREAD, F.LOW),
			C.t(0.62, 0.42, 0, 10, C.R_PALM, C.L_PALM, F.FIGHT),
			C.t(0.9, 0.4, 0, 6, C.R_PALM, C.L_PALM, F.FIGHT),
			C.t(1.1, 0.38, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
