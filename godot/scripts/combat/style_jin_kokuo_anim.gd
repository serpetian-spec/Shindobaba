extends RefCounted
## Jinchūriki tarzı — Kokuō (Beş Kuyruk, Han). YAKIN (tekmeci). Görseller oyunun gerçek buhar sistemi (BijuuArts._steam_cloud /
## _steam_burst / _futton_boil / _horn_ram). Kanon: Han buhar zırhıyla dövüşür — sırtındaki kazandan fışkıran buharla tekmelerini
## hızlandırır (Futton: Kōjōki), Kokuō gibi boynuz atılışı, haşlayan buhar.
## 1 buharlı yüksek tekme, 2 buharlı süpürme tekmesi, 3 boynuz atılışı (kısa hücum), 4 haşlama buharı (hedefin üstünde),
## 5 buhar patlaması (çevre), 6 bitiriş: Kōjōki — sırttan buhar fışkırır, roket gibi uçan tekme.

const C = preload("res://scripts/combat/style_common.gd")
const F = preload("res://scripts/combat/style_legs.gd")


static func steps() -> Array:
	return [
		C.step(0.5, 0.24, C.R_GUARD, C.L_GUARD, C.R_BACK, C.L_GUARD, F.SHIFT, C.KICK_HIGH_R, 10.0, -30.0, 0.35, -12.0),
		C.step(0.5, 0.24, C.R_GUARD, C.L_GUARD, C.R_SPREAD, C.L_GUARD, F.LOW, C.KICK_LOW_L, -20.0, 60.0, 0.75, 10.0),
		C.step(0.75, 0.2, C.R_LOW, C.L_LOW, C.R_LOW, C.L_LOW, F.LOW, F.STEPIN, 0.0, 0.0, 0.7, 40.0),
		C.step(0.6, 0.3, C.R_SEAL, C.L_SEAL, C.R_PALM, C.L_PALM, F.FIGHT, F.STEPIN, 0.0, 0.0, 0.42, 6.0),
		C.step(0.6, 0.3, C.R_LOW, C.L_LOW, C.R_SPREAD, C.L_SPREAD, F.LOW, F.FIGHT, 0.0, 0.0, 0.5, -6.0),
		{"len": 1.1, "hit": 0.6, "keys": [
			C.t(0.0, 0.4, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
			C.t(0.24, 0.7, 0, 30, C.R_LOW, C.L_LOW, F.LOW),
			C.t(0.5, 0.72, 0, 32, C.R_LOW, C.L_LOW, F.LOW),
			C.t(0.6, 0.3, -30, -18, C.R_BACK, C.L_BACK, C.KICK_FRONT_R),
			C.t(0.88, 0.3, -24, -14, C.R_BACK, C.L_BACK, C.KICK_FRONT_R),
			C.t(1.1, 0.4, 0, 4, C.R_GUARD, C.L_GUARD, F.FIGHT),
		]},
	]
